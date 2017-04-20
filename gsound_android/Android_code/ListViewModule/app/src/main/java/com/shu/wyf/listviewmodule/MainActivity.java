package com.shu.wyf.listviewmodule;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    List<ItemInfo> datalist;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        ListView listView = (ListView) findViewById(R.id.listview_1);

        datalist = new ArrayList<>();
        for (int i = 0; i <50; i++) {
            ItemInfo itemInfo = new ItemInfo();
            itemInfo.name =  "松涛路563号A座"+i+"室";
            itemInfo.age = "上海"+i+"数字技术有限公司";
            itemInfo.count = i;
            itemInfo.telnumber = "021-58326420";
            itemInfo.url = "www."+i+"baidu.com";
            datalist.add(itemInfo );
        }
        InfoListAdapter infoListAdapter = new InfoListAdapter();
        listView.setAdapter(infoListAdapter);


    }
    class InfoListAdapter extends BaseAdapter{

        @Override
        public int getCount() {
            return datalist.size();
        }

        @Override
        public Object getItem(int i) {
            return datalist.get(i);
        }

        @Override
        public long getItemId(int i) {
            return i;
        }

        @Override
        public View getView(int i, View view, ViewGroup viewGroup) {
            View itemRootView = LayoutInflater.from(viewGroup.getContext()).inflate(R.layout.item_info,null);

            TextView tvName = (TextView) itemRootView.findViewById(R.id.tv_name);
            tvName.setText(datalist.get(i).name);

            TextView tvAge = (TextView) itemRootView.findViewById(R.id.tv_age);
            tvAge.setText(datalist.get(i).age);

            TextView tvTelnumber = (TextView) itemRootView.findViewById(R.id.tv_telnumber);
            tvTelnumber.setText(datalist.get(i).telnumber);

            TextView tvUrl = (TextView) itemRootView.findViewById(R.id.tv_url);
            tvUrl.setText(datalist.get(i).url);

            ImageView imageViewCompany = (ImageView) itemRootView.findViewById(R.id.iv_item);
            if(datalist.get(i).count%4==0){
                imageViewCompany.setBackgroundResource(R.drawable.gmt);
            }else if(datalist.get(i).count%4==1){
                imageViewCompany.setBackgroundResource(R.drawable.anewpharm);
            }else if(datalist.get(i).count%4==2){
                imageViewCompany.setBackgroundResource(R.drawable.baibei);
            }else if(datalist.get(i).count%4==3){
                imageViewCompany.setBackgroundResource(R.drawable.cloud);
            }


            return itemRootView;
        }
    }

    class ItemInfo{
        String name;
        String age;
        int count;
        String telnumber;
        String url;
    }
}
