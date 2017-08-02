package com.shu.wyf.jnigsound;

import android.app.Activity;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import com.gmt.audio.PlayerTester;


public class MainActivity extends Activity {
    private Button btn_test;
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

    private char[] chararray1={'h', 'j', 'a', 'i', 'a', 'm', 'o', '2', 'k', '4', 'j', '8', '9', 'r', 'i', 'a', 'i', 'h', '8', 'd'};
    private char[] chararray2={'h', 'j', 'd', 'c', 'h', 'i', '2', 't', '9', 'b', 'h', 'i', 'g', 'p', 'd', 'f', 'i', 'g', 's', 'j'};
    private char[] chararray3={'h','j','g','5','a','m','n','0','1','a','f','g','i','m','7','3','i','r','2','d' };
    private char[] chararray4={'h','j','2','l','4','8','0','p','e','a','3','2','q','9','d','1','l','s','o','c' };

    public native void renderChirpData1(char[] chararray);
    public native void renderChirpData2(char[] chararray);
    public native void renderChirpData3(char[] chararray);
    public native void renderChirpData4(char[] chararray);
    static{
        System.loadLibrary("PCMRender");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);


        mTester = new PlayerTester();

        btn_test = (Button) findViewById(R.id.btn_test);
        btn_test.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d("wyf", "*********1********");
                try {
                    MainActivity.this.renderChirpData1(chararray1);
                    MainActivity.this.renderChirpData2(chararray2);
                    MainActivity.this.renderChirpData3(chararray3);
                    MainActivity.this.renderChirpData4(chararray4);
                    Log.d("wyf", "*********2********");
                } catch (Exception e) {
                    Log.d("wyf", "*********3********");
                    e.printStackTrace();
                }
                Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE1);
                Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE2);
                Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE3);
                Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE4);
            }
        });

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
        btn_stop= (Button) findViewById(R.id.btn_stop);
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


