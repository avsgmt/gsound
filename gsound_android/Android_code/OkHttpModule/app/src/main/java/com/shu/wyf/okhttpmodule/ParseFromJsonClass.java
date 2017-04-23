package com.shu.wyf.okhttpmodule;

import android.util.Log;

import com.google.gson.Gson;

/**
 * Created by info_kerwin on 2017/4/23.
 */

public class ParseFromJsonClass {
    private static String web_url=null;

    public String parseFromJson(String jsonData) {
        Log.d("test", "1");
        try {
            Gson gson = new Gson();
            Member member = gson.fromJson(jsonData, Member.class);
            System.out.println("2--->" + member.getUrl());
            web_url=member.getUrl();

            return web_url;
           // tv_data.setText(member.getUrl()==null?"fail":member.getUrl());
        } catch (Exception e) {
            Log.d("test", "Gson无法解析");
            return null;
        }
    }
}
