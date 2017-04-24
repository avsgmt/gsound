package com.shu.wyf.gmtsound;

import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;

import com.facebook.drawee.view.SimpleDraweeView;

import java.util.ArrayList;

/**
 * Created by info_kerwin on 2017/4/24.
 */

public class ListViewModule {
    SimpleDraweeView imageViewCompany;
    ArrayList<ItemInfo> datalist;
    public void showListView(ListView listView,String jsondata){
        ParseFromJsonClass parseFromJsonClass = new ParseFromJsonClass();
        datalist = parseFromJsonClass.parseItemInfo(jsondata);

        InfoListAdapter infoListAdapter = new InfoListAdapter();
        listView.setAdapter(infoListAdapter);
    }


    class InfoListAdapter extends BaseAdapter {

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

            TextView tvName = (TextView) itemRootView.findViewById(R.id.tv_CompanyLocation);
            tvName.setText(datalist.get(i).CompanyLocation);

            TextView tvAge = (TextView) itemRootView.findViewById(R.id.tv_CompanyName);
            tvAge.setText(datalist.get(i).CompanyName);

            TextView tvTelnumber = (TextView) itemRootView.findViewById(R.id.tv_CompanyTel);
            tvTelnumber.setText(datalist.get(i).CompanyTel);

            TextView tvUrl = (TextView) itemRootView.findViewById(R.id.tv_CompanyUrl);
            tvUrl.setText(datalist.get(i).CompanyUrl);

            imageViewCompany = (SimpleDraweeView) itemRootView.findViewById(R.id.iv_item);
//            if(datalist.get(i).count%4==0){
//                imageViewCompany.setBackgroundResource(R.drawable.gmt);
//            }else if(datalist.get(i).count%4==1){
//                imageViewCompany.setBackgroundResource(R.drawable.anewpharm);
//            }else if(datalist.get(i).count%4==2){
//                imageViewCompany.setBackgroundResource(R.drawable.baibei);
//            }else if(datalist.get(i).count%4==3){
//                imageViewCompany.setBackgroundResource(R.drawable.cloud);
//            }
            Uri imageUrl = Uri.parse(datalist.get(i).LogoUrl);
            imageViewCompany.setImageURI(imageUrl);



            return itemRootView;
        }
    }
}
