package com.shu.wyf.listviewmoudoule;

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
            itemInfo.name =  "张三"+i;
            itemInfo.age = 10+i;
            itemInfo.sex = i%2==0?"男":"女";
            itemInfo.url = "www."+i+".com";
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
            tvAge.setText(datalist.get(i).age+"");

            TextView tvSex = (TextView) itemRootView.findViewById(R.id.tv_sex);
            tvSex.setText(datalist.get(i).sex);

            TextView tvUrl = (TextView) itemRootView.findViewById(R.id.tv_url);
            tvUrl.setText(datalist.get(i).url);

            ImageView imageViewCompany = (ImageView) itemRootView.findViewById(R.id.iv_item);
            if(datalist.get(i).sex.equals("男")){
                imageViewCompany.setBackgroundResource(R.drawable.a);
            }else if(datalist.get(i).sex.equals("女")){
                imageViewCompany.setBackgroundResource(R.drawable.b);
            }


            return itemRootView;
        }
    }

    class ItemInfo{
        String name;
        int age;
        String sex;
        String url;
    }
}
