package com.shu.wyf.gmtsound;

import android.util.Log;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by info_kerwin on 2017/4/23.
 */

public class ParseFromJsonClass {
    private String toolBarTitle=null;

    public String getToolBarTitle(){
        return toolBarTitle;
    }
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
    ArrayList<ItemInfo> datalist = null;
    public ArrayList<ItemInfo> parseItemInfo(String jsonData) {
        datalist = new ArrayList<>();
        try {
            JsonParser jsonParser = new JsonParser();
            JsonObject object = (JsonObject) jsonParser.parse(jsonData);
            toolBarTitle =object.get("title").getAsString();
            Log.d("Gson", object.get("status").getAsString());
            Log.d("Gson", object.get("title").getAsString());
            JsonArray array = object.get("data").getAsJsonArray();
            for (int i = 0; i < array.size(); i++) {
                Log.d("Gson", "-----------------------");
                JsonObject subObject = array.get(i).getAsJsonObject();
                ItemInfo itemInfo = new ItemInfo();
                itemInfo.logo = subObject.get("logo").getAsString();
                itemInfo.address = subObject.get("address").getAsString();
                itemInfo.name = subObject.get("name").getAsString();
                itemInfo.tel = subObject.get("tel").getAsString();
                itemInfo.webset = subObject.get("webset").getAsString();
             //   datalist.add(itemInfo);
                Log.d("Gson", subObject.get("logo").getAsString());
                Log.d("Gson", subObject.get("address").getAsString());
                Log.d("Gson", subObject.get("name").getAsString());
                Log.d("Gson", subObject.get("tel").getAsString());
                Log.d("Gson", subObject.get("webset").getAsString());
            }
    //            JsonObject subObject = object.get("itemInfo").getAsJsonObject();
    //            web_url = subObject.get("city").getAsString();
    //            Log.d("Gson", subObject.get("city").getAsString());
    //            Log.d("Gson", subObject.get("cityid").getAsString());
    //            Log.d("Gson", subObject.get("temp").getAsString());
        } catch (JsonSyntaxException e) {
            e.printStackTrace();
        }
        return datalist;
    }


}