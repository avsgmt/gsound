package com.gmt.audiotest;

import android.os.Environment;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity {
    private Button btn_play1;
    private Button btn_play2;
    private Button btn_play3;
    private Button btn_play4;
    private Button btn_stop;
    private PlayerTester mTester;
    private static final String DEFAULT_TEST_FILE1 = Environment.getExternalStorageDirectory() + "/audio1.wav";
    private static final String DEFAULT_TEST_FILE2 = Environment.getExternalStorageDirectory() + "/audio2.wav";
    private static final String DEFAULT_TEST_FILE3 = Environment.getExternalStorageDirectory() + "/audio3.wav";
    private static final String DEFAULT_TEST_FILE4 = Environment.getExternalStorageDirectory() + "/audio4.wav";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mTester = new PlayerTester();

        btn_play1 = (Button) findViewById(R.id.btn_play1);
        btn_play1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mTester != null) {
                    mTester.stopTesting();
                    /*
                    *   when click the button ,first stop the thread ,but the thread takes some time
                    *   so i set a boolean "a",while(!a),i will invoke the startTesting method every
                    *   0.5s ,until it invokes successfully!
                    * */
                    boolean a = false;
                    while (!a) {
                        try {
                            Thread.sleep(500);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        a = mTester.startTesting(DEFAULT_TEST_FILE1);
                    }
                    Toast.makeText(MainActivity.this, "Start Testing !", Toast.LENGTH_SHORT).show();
                }
            }
        });
        btn_play2 = (Button) findViewById(R.id.btn_play2);
        btn_play2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mTester != null) {
                    mTester.stopTesting();
                    boolean a = false;
                    while (!a) {
                        try {
                            Thread.sleep(500);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        a = mTester.startTesting(DEFAULT_TEST_FILE2);
                    }
                    Toast.makeText(MainActivity.this, "Start Testing !", Toast.LENGTH_SHORT).show();
                }
            }
        });
        btn_play3 = (Button) findViewById(R.id.btn_play3);
        btn_play3.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mTester != null) {
                    mTester.stopTesting();
                    boolean a = false;
                    while (!a) {
                        try {
                            Thread.sleep(500);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        a = mTester.startTesting(DEFAULT_TEST_FILE3);
                    }
                    Toast.makeText(MainActivity.this, "Start Testing !", Toast.LENGTH_SHORT).show();
                }
            }
        });
        btn_play4 = (Button) findViewById(R.id.btn_play4);
        btn_play4.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mTester != null) {
                    mTester.stopTesting();
                    boolean a = false;
                    while (!a) {
                        try {
                            Thread.sleep(500);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        a = mTester.startTesting(DEFAULT_TEST_FILE4);
                    }
                    Toast.makeText(MainActivity.this, "Start Testing !", Toast.LENGTH_SHORT).show();
                }
            }
        });

        btn_stop = (Button) findViewById(R.id.btn_stop);
        btn_stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mTester != null) {
                    mTester.stopTesting();
                    Toast.makeText(MainActivity.this, "Stop Testing !", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }
}
