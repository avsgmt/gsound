package com.shu.wyf.gmtsigdev;

import android.content.Context;
import android.util.Log;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

/**
 * Created by info_kerwin on 2017/4/23.
 */

public class ParseFromJsonClass {
    private Context ctx;
    private String soundData;
    public String getSoundData(){
        return soundData;
    }
    public ParseFromJsonClass(Context ctx){
        this.ctx = ctx;
    }
   public void parseFromJson(String jsonData) {
        Log.d("test", "1");
        try {
            JsonParser jsonParser = new JsonParser();
            JsonObject object = (JsonObject) jsonParser.parse(jsonData);
            soundData = object.get("isakey").getAsString();
        } catch (JsonSyntaxException e) {
            Log.d("test", "Gson无法解析");
        }
    }
}