package com.shu.wyf.gmtsound;

import android.net.Uri;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;
import android.content.Context;
import com.facebook.drawee.view.SimpleDraweeView;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;
import java.util.ArrayList;

/**
 * Created by info_kerwin on 2017/4/24.
 */

public class ListViewModule extends BaseAdapter {

        private ArrayList<ItemInfo> items;
        private Context ctx;

        public ListViewModule(ArrayList<ItemInfo> items, Context ctx){
            this.items = items;
            this.ctx = ctx;
        }
        @Override
        public int getCount() {
            return items.size();
        }

        @Override
        public Object getItem(int i) {
            return items.get(i);
        }

        @Override
        public long getItemId(int i) {
            return i;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {

            ViewHolder viewHolder = null;
            if (convertView == null){
                convertView = LayoutInflater.from(ctx).inflate(R.layout.item_info, parent, false);
                viewHolder = new ViewHolder();
                //viewHolder.imageView = (ImageView) convertView.findViewById(R.id.itemIcon);
                viewHolder.tvName = (TextView) convertView.findViewById(R.id.tv_CompanyName);
                viewHolder.tvAge = (TextView) convertView.findViewById(R.id.tv_CompanyLocation);
                viewHolder.tvTelnumber = (TextView) convertView.findViewById(R.id.tv_CompanyTel);
                viewHolder.tvUrl = (TextView) convertView.findViewById(R.id.tv_CompanyUrl);
                viewHolder.imageViewCompany = (SimpleDraweeView)convertView.findViewById(R.id.iv_item);
                convertView.setTag(viewHolder);
            }else {
                viewHolder = (ViewHolder) convertView.getTag();
            }

            viewHolder.tvName.setText(items.get(position).name);
            viewHolder.tvAge.setText(items.get(position).address);
            viewHolder.tvTelnumber.setText(items.get(position).tel);
            viewHolder.tvUrl.setText(items.get(position).webset);
            Uri imageUrl = Uri.parse(items.get(position).logo);
            viewHolder.imageViewCompany.setImageURI(imageUrl);

            return convertView;
        }
        private class ViewHolder{

            TextView tvName;
            TextView tvAge;
            TextView tvTelnumber;
            TextView tvUrl;
            SimpleDraweeView imageViewCompany;

        }
        public void add(ItemInfo item)
        {
            if(items == null)
            {
                items = new ArrayList<ItemInfo>();
            }
            items.add(item);
            this.notifyDataSetChanged();
        }
       public void update(String jsondata){
           try {

               items.clear();
               JsonParser jsonParser = new JsonParser();
               JsonObject object = (JsonObject) jsonParser.parse(jsondata);
               Log.d("Gson", object.get("status").getAsString());
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

                   add(itemInfo);
               }

           } catch (JsonSyntaxException e) {
               e.printStackTrace();
           }

       }

}
