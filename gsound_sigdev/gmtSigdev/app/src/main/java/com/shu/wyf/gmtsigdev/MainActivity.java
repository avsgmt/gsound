package com.shu.wyf.gmtsigdev;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.libra.sinvoice.Common;
import com.libra.sinvoice.LogHelper;
import com.libra.sinvoice.SinVoicePlayer;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;

import okhttp3.OkHttpClient;

public class MainActivity extends AppCompatActivity implements SinVoicePlayer.Listener {

    private static final OkHttpClient okHttpClient =new OkHttpClient();
    private PostUtilClass postUtilClass = null;
    private ParseFromJsonClass parseFromJsonClass = null;
    private final static String TAG = "MainActivityxx";

    private final static int[] TOKENS = { 32, 32, 32, 32, 32, 32 };
    private final static int TOKEN_LEN = TOKENS.length;
    private static final int REQUEST_STORAGE_PERMISSION=10;

    private SinVoicePlayer mSinVoicePlayer;
    private PowerManager.WakeLock mWakeLock;
    private EditText mPlayTextView;

    static {
        System.loadLibrary("sinvoice");
        LogHelper.d(TAG, "sinvoice jnicall loadlibrary");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, TAG);

        requestPermission();
        mSinVoicePlayer = new SinVoicePlayer();
        mSinVoicePlayer.init(this);
        mSinVoicePlayer.setListener(this);

        mPlayTextView = (EditText) findViewById(R.id.playtext);
        mPlayTextView.setMovementMethod(ScrollingMovementMethod.getInstance());

        Button playStart = (Button) findViewById(R.id.start_play);
        playStart.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /**********************************************************************************/
                //      for (int j = 0; j <10; j++) {
                try {
                    byte[] strs = mPlayTextView.getText().toString().getBytes("UTF8");
                    if ( null != strs ) {
                        int len = strs.length;
                        int []tokens = new int[len];
                        int maxEncoderIndex = mSinVoicePlayer.getMaxEncoderIndex();
                        LogHelper.d(TAG, "maxEncoderIndex:" + maxEncoderIndex);
                        String encoderText = mPlayTextView.getText().toString();
                        for ( int i = 0; i < len; ++i ) {
                            if ( maxEncoderIndex < 255 ) {
                                tokens[i] = Common.DEFAULT_CODE_BOOK.indexOf(encoderText.charAt(i));
                            } else {
                                tokens[i] = strs[i];
                            }
                        }
                        mSinVoicePlayer.play(tokens, len, true, 2000);
                    } else {
                        mSinVoicePlayer.play(TOKENS, TOKEN_LEN, false, 2000);
                    }
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                //         }
                /**********************************************************************************/
            }
        });

        Button playStop = (Button) findViewById(R.id.stop_play);
        playStop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /**********************************************************************************/
                mSinVoicePlayer.stop();
                /**********************************************************************************/
            }
        });

        parseFromJsonClass = new ParseFromJsonClass(MainActivity.this);
    }

    /*******************************************************************************/
    @Override
    public void onResume() {
        super.onResume();
        mWakeLock.acquire();
        doPost();
    }

    @Override
    public void onPause() {
        super.onPause();
        mWakeLock.release();
        mSinVoicePlayer.stop();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mSinVoicePlayer.uninit();
    }

    private void requestPermission(){
        //判断系统版本
        if (Build.VERSION.SDK_INT >= 23) {
            //检测当前app是否拥有某个权限
            int checkPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);
            //判断这个权限是否已经授权过
            if(checkPermission != PackageManager.PERMISSION_GRANTED){
                //判断是否需要 向用户解释，为什么要申请该权限
                if(ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.WRITE_EXTERNAL_STORAGE))
                    Toast.makeText(this,"Need Storage permission.",Toast.LENGTH_SHORT).show();
                ActivityCompat.requestPermissions(this ,new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE,Manifest.permission.RECORD_AUDIO},REQUEST_STORAGE_PERMISSION);
                return;
            }else{
            }
        } else {
        }
    }
    @Override
    public void onSinVoicePlayStart() {
        LogHelper.d(TAG, "start play");
    }

    @Override
    public void onSinVoicePlayEnd() {
        LogHelper.d(TAG, "stop play");
    }

    @Override
    public void onSinToken(int[] tokens) {}
    /*******************************************************************************/
    private void doPost() {
        postUtilClass = new PostUtilClass(handler);
        postUtilClass.doPost(okHttpClient);
    }
    private Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case 0x0001:
                    Log.d("wyf", "loading data form server finished!");
                    parseFromJsonClass.parseFromJson(postUtilClass.getJsonString());
                    mPlayTextView.setText(parseFromJsonClass.getSoundData());
                    postUtilClass.clrJsonString();
                    break;
                case 0x0002:
                    Log.d("wyf", "loading data form server failed!");
                    // update ui
                    break;
                default: {
                    break;
                }
            }
        }
    };
}
