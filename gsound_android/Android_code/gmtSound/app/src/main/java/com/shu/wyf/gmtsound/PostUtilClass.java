package com.shu.wyf.gmtsound;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

/**
 * Created by info_kerwin on 2017/4/23.
 */

public class PostUtilClass {

    private String jsondata = null;
    private Handler handler;
    public PostUtilClass(Handler handler) {
        this.handler = handler;
    }
    public String getJsonString() {
        return jsondata;
    }
    public void clrJsonString() {
        jsondata = null;
    }

    public void doPost(final String data,final OkHttpClient okHttpClient) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final String postUrl = "http://cv15425558.imwork.net:2501/gsound/buildinfo?id="+data;
                final FormBody formBody = new FormBody.Builder()
                        //// TODO: 2017/5/5  add the user check
                        .add("mac", "abcdefg")
                        .build();
                Request request = new Request.Builder().url(postUrl).build();
//                Request request = new Request.sBuilder().url(postUrl).post(formBody).build();
                Log.d("test", postUrl);
                try {
                    okHttpClient.newCall(request).enqueue(new Callback() {

                        @Override
                        public void onResponse(Call call, Response response) throws IOException {
                            jsondata = response.body().string();
                            Log.d("test", "jsondata"+jsondata);
                            Message message=new Message();
                            message.what=0x0001;
                            handler.sendMessage(message);
                        }

                        @Override
                        public void onFailure(Call call, IOException e) {
                            Message message=new Message();
                            message.what=0x0002;
                            handler.sendMessage(message);
                        }
                    });
                } catch (Exception e) {
                    Log.d("test", "fail2" + postUrl);
                }
            }

        }).start();
    }
}
