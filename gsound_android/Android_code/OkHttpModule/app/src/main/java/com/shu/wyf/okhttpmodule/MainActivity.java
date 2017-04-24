package com.shu.wyf.okhttpmodule;

import android.app.Activity;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.drawee.view.SimpleDraweeView;

import okhttp3.OkHttpClient;

public class MainActivity extends Activity {
    private static final OkHttpClient okHttpClient =new OkHttpClient();
    private SimpleDraweeView simpleDraweeView;
    Button btn_1;
    Button btn_2;
    TextView tv_dis;
    ImageView im_1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Fresco.initialize(this);
        setContentView(R.layout.activity_main);

        btn_1 = (Button) findViewById(R.id.btn_1);
        btn_2 = (Button) findViewById(R.id.btn_2);
        tv_dis = (TextView) findViewById(R.id.tv_dis);
        im_1 = (ImageView) findViewById(R.id.im_1);
        btn_1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                PostUtilClass postUtilClass = new PostUtilClass();
                String jsondata=postUtilClass.doPost("0004",okHttpClient);
                if (jsondata != null) {
                    ParseFromJsonClass parseFromJsonClass = new ParseFromJsonClass();
                    String weburl = parseFromJsonClass.parseItemInfo(jsondata);
                    tv_dis.setText(weburl);
                }
            }
        });
        btn_2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                simpleDraweeView = (SimpleDraweeView) findViewById(R.id.im_1);
                Uri imageUrl = Uri.parse("http://123.206.206.42:8090/ShuVoice/UI/gmt.png");
                simpleDraweeView.setImageURI(imageUrl);
            }
        });

    }
}
