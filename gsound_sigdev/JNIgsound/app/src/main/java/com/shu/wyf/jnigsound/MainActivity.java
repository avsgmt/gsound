package com.shu.wyf.jnigsound;

import android.app.Activity;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;

import java.io.IOException;


public class MainActivity extends Activity {

    private static final String DEFAULT_TEST_FILE1 = Environment.getExternalStorageDirectory() + "/audio1.wav";
    private static final String DEFAULT_TEST_FILE2 = Environment.getExternalStorageDirectory() + "/audio2.wav";


    private Button btn_test;
    private Button btn_play1;
    private Button btn_play2;
    private Button btn_stop;
    private char[] chararray1={'h', 'j', 'a', 'i', 'a', 'm', 'o', '2', 'k', '4', 'j', '8', '9', 'r', 'i', 'a', 'i', 'h', '8', 'd'};
    private char[] chararray2={'h', 'j', 'd', 'c', 'h', 'i', '2', 't', '9', 'b', 'h', 'i', 'g', 'p', 'd', 'f', 'i', 'g', 's', 'j'};

    public native void renderChirpData1(char[] chararray);
    public native void renderChirpData2(char[] chararray);
    static{
        System.loadLibrary("PCMRender");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE1);
        Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE2);
        btn_test = (Button) findViewById(R.id.btn_test);
        btn_test.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d("wyf", "*********1********");
                try {
                    MainActivity.this.renderChirpData1(chararray1);
                    MainActivity.this.renderChirpData2(chararray2);
                    Log.d("wyf", "*********2********");
                } catch (RuntimeException e) {
                    Log.d("wyf", "*********3********");
                    e.printStackTrace();
                }
            }
        });

        btn_play1= (Button) findViewById(R.id.btn_play1);
        btn_play1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                SoundPool(DEFAULT_TEST_FILE1);
            }
        });
        btn_play2= (Button) findViewById(R.id.btn_play2);
        btn_play2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                SoundPool(DEFAULT_TEST_FILE2);
            }
        });
        btn_stop= (Button) findViewById(R.id.btn_stop);
        btn_stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

            }
        });
    }


    private void SoundPool(String filePath){

        MediaPlayer mediaPlayer = new MediaPlayer();
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

        try {
            mediaPlayer.setDataSource(filePath);
            mediaPlayer.prepare();
        } catch (IOException e) {
            e.printStackTrace();
        }
        mediaPlayer.start();
    }

}


