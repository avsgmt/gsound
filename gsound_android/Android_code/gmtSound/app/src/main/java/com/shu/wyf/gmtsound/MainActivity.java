package com.shu.wyf.gmtsound;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.ListView;
import com.facebook.drawee.backends.pipeline.Fresco;
import java.util.ArrayList;
import okhttp3.OkHttpClient;
import android.os.Handler;
import android.os.Message;

public class MainActivity extends Activity {
    private static final OkHttpClient okHttpClient =new OkHttpClient();
    ListView listView = null;
    private ArrayList<ItemInfo> items = null;
    private ListViewModule madapter = null;
    private PostUtilClass postUtilClass = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Fresco.initialize(this);
        setContentView(R.layout.activity_main);

        listView = (ListView) findViewById(R.id.listview_1);
        items = new ArrayList<ItemInfo>();
        madapter = new ListViewModule(items,MainActivity.this);
        listView.setAdapter(madapter);
    }

    /*
    *   网络访问信息应在onResume里面加载
    * */
    @Override
    protected void onResume(){
        super.onResume();
        Log.d("wyf", "onResume: start");
        try {
            doShowListView();
        } catch (Exception e) {
            e.printStackTrace();
        }
        Log.d("wyf", "onResume: finish");
    }

    private void doShowListView() {
        postUtilClass = new PostUtilClass(handler);
        postUtilClass.doPost("12345",okHttpClient);

    }
    private Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case 0x0001:
                    Log.d("wyf", "loading data form server finished!");
                    madapter.update(postUtilClass.getJsonString());
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
