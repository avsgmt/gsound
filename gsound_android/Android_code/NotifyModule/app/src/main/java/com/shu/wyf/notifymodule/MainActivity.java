package com.shu.wyf.notifymodule;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.support.v7.app.NotificationCompat;
import android.view.View;

public class MainActivity extends AppCompatActivity {

    int notificationId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        findViewById(R.id.btn_notify).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                createNofication();
            }
        });

        findViewById(R.id.btn_notify_cancel).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
                 notificationManager.cancel(notificationId);
            }
        });
    }


    private void createNofication() {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this);
        builder.setSmallIcon(R.mipmap.ic_launcher);
        builder.setContentTitle("声波定位");
        builder.setContentText("欢迎您来到张江外科技园园区,点击可查看详细公司位置信息！");
        builder.setNumber(10);
        builder.setAutoCancel(true);

        PendingIntent pendingIntent = PendingIntent.getActivity(this,1,
                new Intent(this,SecondActivity.class),PendingIntent.FLAG_UPDATE_CURRENT);

        builder.setContentIntent(pendingIntent);

        Notification notification =  builder.build();

        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

        notificationId =100;
        notificationManager.notify(notificationId,notification);
    }
}
