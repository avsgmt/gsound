package com.shu.wyf.okhttpmodule;

import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by info_kerwin on 2017/4/23.
 */

public class ParseFromJsonClass {
    private static String web_url=null;

/*    public String parseFromJson(String jsonData) {
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
*/

    public String parseItemInfo(String jsonData) {
        try {
            JsonParser jsonParser = new JsonParser();
            JsonObject object = (JsonObject) jsonParser.parse(jsonData);
        Log.d("Gson", object.get("result").getAsString());
        Log.d("Gson", object.get("msg").getAsString());
            JsonArray array = object.get("itemInfo").getAsJsonArray();
            for (int i = 0; i < array.size(); i++) {
                Log.d("Gson", "-----------------------");
                JsonObject subObject = array.get(i).getAsJsonObject();
                web_url = subObject.get("ID").getAsString();
                Log.d("Gson", subObject.get("ID").getAsString());
                Log.d("Gson", subObject.get("LogoUrl").getAsString());
                Log.d("Gson", subObject.get("CompanyLocation").getAsString());
                Log.d("Gson", subObject.get("CompanyName").getAsString());
                Log.d("Gson", subObject.get("CompanyTel").getAsString());
                Log.d("Gson", subObject.get("CompanyUrl").getAsString());
            }
//            JsonObject subObject = object.get("itemInfo").getAsJsonObject();
//            web_url = subObject.get("city").getAsString();
//            Log.d("Gson", subObject.get("city").getAsString());
//            Log.d("Gson", subObject.get("cityid").getAsString());
//            Log.d("Gson", subObject.get("temp").getAsString());
        } catch (JsonSyntaxException e) {
            e.printStackTrace();
        }
        return web_url;
    }
}
