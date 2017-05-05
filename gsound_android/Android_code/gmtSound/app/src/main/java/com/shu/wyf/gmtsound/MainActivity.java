package com.shu.wyf.gmtsound;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
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
import android.widget.Toast;

public class MainActivity extends AppCompatActivity implements SinVoiceRecognition.Listener{
    private final static String TAG = "MainActivityxx";
    private boolean flag_setview=false;//judge whether setview
    private boolean flag_dopost = false;//judge whether do post which requesting for network
    private ArrayList<ItemInfo> items = null;//items is an arrayList which store the information parsing from the json
    private ListViewModule madapter = null;//madapter is a instance of ListViewModule
    private PostUtilClass postUtilClass = null;//postUtilClass is a instance of PostUtilClass
    private CustomProgressDialog dialog=null;   //dialog is a instance of CustomProgressDialog
    ListView listView = null;           //display the company information
    TextView toolbar_title = null;      //toolbar which display the location
    TextView tv_count = null;           //tv_count which display the amount of the company

    private final static int MSG_SET_RECG_TEXT = 1;//the state of the Handler
    private final static int MSG_RECG_START = 2;
    private final static int MSG_RECG_END = 3;
    private final static int MSG_PLAY_TEXT = 4;
    private final static int[] TOKENS = { 32, 32, 32, 32, 32, 32 };
    private final static int TOKEN_LEN = TOKENS.length;
    private static final int REQUEST_STORAGE_PERMISSION=10;

    private static final OkHttpClient okHttpClient =new OkHttpClient();//okHttpClient is a instance of OkHttpClient
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
        //Facebook's Fresco which using download image from url
        Fresco.initialize(this);
        setContentView(R.layout.activity_main);

        //ToolBar which display the location in the middle of the bar
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        toolbar.setTitle("");
        toolbar_title = (TextView) findViewById(R.id.toolbar_title);
        toolbar_title.setText("声讯");
        setSupportActionBar(toolbar);

        requestPermission();
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
        if(ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED){

        }
        try {
            /******************************************************/
            //this method is the start of Recognition,which is called when onResume
            mRecognition.start(TOKEN_LEN, mIsReadFromFile);
            /******************************************************/
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        // try catch capture the exception of onPause,such as dialog and mWakeLock
        try {
            if(dialog!=null)
                dialog.dismiss();
            if (mWakeLock.isHeld())
                mWakeLock.release();
        } catch (Exception e) {
            e.printStackTrace();
        }
        /******************************************************/
        //when onPause ,the Recognition should stop,this is the method of stopping the recognition process
        mRecognition.stop();
        /******************************************************/
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mRecognition.uninit();
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
                                    Log.d(TAG, strReg);
                                    str= strProcess(strReg);
                                    Log.d(TAG, str+"*<-*");
                                    //if the correct building information has been parsed,do post process
                                    if(str!=null)
                                        flag_dopost = true;
                                    Log.d(TAG, flag_dopost+"");
                                    // do post process is the AsyncTask
                                    if(flag_dopost) {
                                        new Task().execute();
                                    }
                                }
                            } else {
                                Log.d(TAG, "reg error!!!!!!!!!!!!!");
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
    //string process which handle the string
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
        Log.d(TAG, "postUtilClass created");
        if(str!=null){
            Log.d(TAG, "do post start");
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
