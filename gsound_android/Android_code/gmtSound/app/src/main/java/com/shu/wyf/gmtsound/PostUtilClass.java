package com.shu.wyf.gmtsound;
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
    private static String jsondata = null;

    public String doPost(final String data,final OkHttpClient okHttpClient) {
        new Thread(new Runnable() {
            @Override
            public void run() {
//                final String postUrl = "http://123.206.206.42:8090/ShuVoice/index.php/Home/GetValue/index?key="+data;
                final String postUrl = "http://123.206.206.42:8090/ShuVoice/GMT.php";
                final FormBody formBody = new FormBody.Builder()
                        .add("key", data)
                        .build();
                Request request = new Request.Builder().url(postUrl).build();
//                Request request = new Request.Builder().url(postUrl).post(formBody).build();
                Log.d("test", postUrl);
                Log.d("test", data);
                try {
                    okHttpClient.newCall(request).enqueue(new Callback() {

                        @Override
                        public void onResponse(Call call, Response response) throws IOException {
                            jsondata = response.body().string();
                            Log.d("test", "jsondata"+jsondata);
                        }

                        @Override
                        public void onFailure(Call call, IOException e) {
                            Log.d("test", "fail1" + postUrl);
                            Log.e("err", "onFailure: ", e);
                        }
                    });
                } catch (Exception e) {
                    Log.d("test", "fail2" + postUrl);
                }
            }

        }).start();

        return jsondata;
    }
}
