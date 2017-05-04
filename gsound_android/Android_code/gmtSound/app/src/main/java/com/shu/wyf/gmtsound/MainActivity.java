package com.shu.wyf.gmtsound;

import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.widget.ListView;
import com.facebook.drawee.backends.pipeline.Fresco;
import com.libra.sinvoice.LogHelper;
import com.libra.sinvoice.SinVoiceRecognition;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import okhttp3.OkHttpClient;
import android.os.Handler;
import android.os.Message;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity implements SinVoiceRecognition.Listener{
    private boolean flag_setview=false;
    private boolean flag_dopost = false;
    private static final OkHttpClient okHttpClient =new OkHttpClient();
    ListView listView = null;
    TextView toolbar_title = null;
    TextView tv_count = null;
    private ArrayList<ItemInfo> items = null;
    private ListViewModule madapter = null;
    private PostUtilClass postUtilClass = null;
    CustomProgressDialog dialog;

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
    private char mRecgs[] = new char[100];
    private int mRecgCount;
    private String str = null;

    static {
        System.loadLibrary("sinvoice");
        LogHelper.d(TAG, "sinvoice jnicall loadlibrary");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Fresco.initialize(this);
        setContentView(R.layout.activity_main);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        toolbar.setTitle("");
        toolbar_title = (TextView) findViewById(R.id.toolbar_title);
        toolbar_title.setText("声讯");
        setSupportActionBar(toolbar);

        tv_count = (TextView) findViewById(R.id.tv_count);
        listView = (ListView) findViewById(R.id.listview_1);
        items = new ArrayList<ItemInfo>();
        madapter = new ListViewModule(items,MainActivity.this);
        listView.setAdapter(madapter);

        mIsReadFromFile = false;

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, TAG);

        mRecognition = new SinVoiceRecognition();
        mRecognition.init(this);
        mRecognition.setListener(this);

        mHanlder = new RegHandler(this);
    }

    /*
    *   网络访问信息应在onResume里面加载
    * */
    @Override
    protected void onResume(){
        super.onResume();
        Log.d("wyf", "onResume: start");
        try {
            /******************************************************/
            mRecognition.start(TOKEN_LEN, mIsReadFromFile);
            /******************************************************/
        } catch (Exception e) {
            e.printStackTrace();
        }
        Log.d("wyf", "onResume: finish");
    }

    @Override
    public void onPause() {
        super.onPause();
        dialog.dismiss();
        mWakeLock.release();
        mRecognition.stop();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mRecognition.uninit();
    }

    private class RegHandler extends Handler {
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
                    LogHelper.d(TAG, "recognition end gIsOk:" + msg.arg1);
                    if ( mAct.mRecgCount > 0 ) {
                        byte[] strs = new byte[mAct.mRecgCount];
                        for ( int i = 0; i < mAct.mRecgCount; ++i ) {
                            strs[i] = (byte)mAct.mRecgs[i];
                        }
                        try {
                            String strReg = new String(strs, "UTF8");
                            if (msg.arg1 < 0) {
                                Log.d(TAG, "reg ok!!!!!!!!!!!!");
                                if (null != mAct) {
//                                    mAct.mRecognisedTextView.setText(strReg);
                                    Log.d(TAG, strReg);
                                    str= strProcess(strReg);
                                    Log.d(TAG, str+"**");
                                    if(str!=null)
                                        flag_dopost = true;
                                    Log.d(TAG, flag_dopost+"");
                                    if(flag_dopost) {
                                        new Task().execute();
                                    }
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
    private String strProcess(String strReg) {
        if (strReg.length()==20){
            if(strReg.substring(0,2).equals("ab")&&strReg.substring(18,20).equals("ea")){
                String buildinfo =strReg.substring(2,10);
                String idStr =strReg.substring(10,18);
                int id = 0;
                try {
                    id = Integer.parseInt(idStr, 16);
                    return id+"";
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
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

    private void doShowListView() {
        postUtilClass = new PostUtilClass(handler);
        Log.d(TAG, "postUtilClass start");
        if(str!=null){
            Log.d(TAG, "postUtilClass start");
            postUtilClass.doPost(str,okHttpClient);
        }
    }
    private Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case 0x0001:
                    Log.d("wyf", "loading data form server finished!");
                    madapter.update(postUtilClass.getJsonString());
                    toolbar_title.setText(madapter.getToolBarTitle());
                    tv_count.setText("共计"+madapter.getTvCount()+"家企业");
                    Log.d("wyf", "count: "+madapter.getTvCount());
                    postUtilClass.clrJsonString();
                    flag_setview = true;
                    Log.d(TAG, "doShowListView finish");
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
    class Task extends AsyncTask<Void,Void,Void> {
        @Override
        protected void onPreExecute() {
            dialog =new CustomProgressDialog(MainActivity.this, "正在加载中",R.drawable.frame);
            dialog.show();
        }

        @Override
        protected Void doInBackground(Void... params) {
            try {
                Log.d(TAG, "doShowListView start");
                doShowListView();
                /******************************************************/
                mRecognition.stop();
                /******************************************************/

                Thread.sleep(500);
            } catch (InterruptedException e) {
                e.printStackTrace();
                return null;
            }
            return null;
        }

        @Override
        protected void onProgressUpdate(Void... values) {
            Log.d(TAG, "flag_dopost:"+flag_dopost);
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            if(flag_setview){
                dialog.dismiss();
                flag_setview=false;
            }
        }
    }
}
