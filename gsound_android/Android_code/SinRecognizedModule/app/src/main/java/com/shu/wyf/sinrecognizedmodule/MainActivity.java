package com.shu.wyf.sinrecognizedmodule;

import android.content.Context;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.libra.sinvoice.LogHelper;
import com.libra.sinvoice.SinVoiceRecognition;

import java.io.UnsupportedEncodingException;

public class MainActivity extends AppCompatActivity implements
        SinVoiceRecognition.Listener{
    private final static String TAG = "MainActivityxx";

    private final static int MSG_SET_RECG_TEXT = 1;
    private final static int MSG_RECG_START = 2;
    private final static int MSG_RECG_END = 3;
    private final static int MSG_PLAY_TEXT = 4;
    private final static int[] TOKENS = { 32, 32, 32, 32, 32, 32 };
    private final static int TOKEN_LEN = TOKENS.length;

    private Handler mHanlder;
    private SinVoiceRecognition mRecognition;
    private boolean mIsReadFromFile;
    private PowerManager.WakeLock mWakeLock;
    private TextView mRecognisedTextView;
    static TextView tv_data;
    private char mRecgs[] = new char[100];
    private int mRecgCount;
    private static String strReg = "";

    static {
        System.loadLibrary("sinvoice");
        LogHelper.d(TAG, "sinvoice jnicall loadlibrary");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mIsReadFromFile = false;

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, TAG);

        mRecognition = new SinVoiceRecognition();
        mRecognition.init(this);
        mRecognition.setListener(this);

        mRecognisedTextView = (TextView) findViewById(R.id.regtext);
        mHanlder = new RegHandler(this);

        tv_data=(TextView) findViewById(R.id.tv_data);

        Button recognitionStart = (Button) findViewById(R.id.start_reg);
        recognitionStart.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /******************************************************/
                mRecognition.start(TOKEN_LEN, mIsReadFromFile);
                /******************************************************/
            }
        });

        Button recognitionStop = (Button) findViewById(R.id.stop_reg);
        recognitionStop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /******************************************************/
                mRecognition.stop();
                /******************************************************/
            }
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        mWakeLock.acquire();
    }

    @Override
    public void onPause() {
        super.onPause();
        mWakeLock.release();
        mRecognition.stop();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mRecognition.uninit();
    }

    private static class RegHandler extends Handler {
        private MainActivity mAct;

        public RegHandler(MainActivity act) {
            mAct = act;
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_SET_RECG_TEXT:
                    char ch = (char) msg.arg1;
                    mAct.mRecgs[mAct.mRecgCount++] = ch;
                    break;

                case MSG_RECG_START:
                    mAct.mRecgCount = 0;
                    break;

                case MSG_RECG_END:
                    LogHelper.d(TAG, "recognition end gIsError:" + msg.arg1);
                    if ( mAct.mRecgCount > 0 ) {
                        byte[] strs = new byte[mAct.mRecgCount];
                        for ( int i = 0; i < mAct.mRecgCount; ++i ) {
                            strs[i] = (byte)mAct.mRecgs[i];
                        }
                        try {
                            strReg = new String(strs, "UTF8");
                            if (msg.arg1 < 0) {
                                Log.d(TAG, "reg ok!!!!!!!!!!!!");
                                if (null != mAct) {
                                    mAct.mRecognisedTextView.setText(strReg);
                                    Log.d(TAG, strProcess(strReg));
                                    // mAct.mRegState.setText("reg ok(" + msg.arg1 + ")");
                                }
                            } else {
                                Log.d(TAG, "reg error!!!!!!!!!!!!!");
                            //    mAct.mRecognisedTextView.setText(strReg);
                            }
                        } catch (UnsupportedEncodingException e) {
                            e.printStackTrace();
                        }
                    }
                    break;

                case MSG_PLAY_TEXT:
                    break;
            }
            super.handleMessage(msg);
        }
    }

    private static String strProcess(String strReg) {
        if(strReg.substring(0,2).equals("ab")&&strReg.substring(18,20).equals("ea")){
            String buildinfo =strReg.substring(2,10);
            String idStr =strReg.substring(10,18);
            int id =Integer.parseInt(idStr, 16);
            return id+"";
        }else
            return "wyf error";
    }
    @Override
    public void onSinVoiceRecognitionStart() {
        mHanlder.sendEmptyMessage(MSG_RECG_START);
    }

    @Override
    public void onSinVoiceRecognition(char ch) {
        mHanlder.sendMessage(mHanlder.obtainMessage(MSG_SET_RECG_TEXT, ch, 0));
    }
    @Override
    public void onSinVoiceRecognitionEnd(int result) {
        mHanlder.sendMessage(mHanlder.obtainMessage(MSG_RECG_END, result, 0));
    }
}
