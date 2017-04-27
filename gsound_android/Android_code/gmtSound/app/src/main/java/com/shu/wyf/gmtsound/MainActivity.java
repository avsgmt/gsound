package com.shu.wyf.gmtsound;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.ListView;

import com.facebook.drawee.backends.pipeline.Fresco;

import okhttp3.OkHttpClient;

public class MainActivity extends Activity {
    private static final OkHttpClient okHttpClient =new OkHttpClient();
    ListView listView;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Fresco.initialize(this);
        setContentView(R.layout.activity_main);

        listView = (ListView) findViewById(R.id.listview_1);
    }

    /*
    *   网络访问信息应在onResume里面加载
    * */
    @Override
    protected void onResume(){
        super.onResume();
        Log.d("wyf", "onResume: test");
        try {
            doShowListView(listView);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void doShowListView(ListView lv) {
        PostUtilClass postUtilClass = new PostUtilClass();
        String jsondata=postUtilClass.doPost("12345",okHttpClient);
        if (jsondata != null) {
            ListViewModule listViewModule = new ListViewModule();
            listViewModule.showListView(lv,jsondata);
        }
    }
}
