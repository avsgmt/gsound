package com.shu.wyf.jnigsound;

import android.app.Activity;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;

import java.io.IOException;


public class MainActivity extends Activity {

    //private final String file="//sdcard//audio.wav";
    private static final String DEFAULT_TEST_FILE = Environment.getExternalStorageDirectory() + "/audio.wav";

    private AudioPlayer mAudioPlayer;
    private WavFileReader mWavFileReader;
    private SoundPool soundPool;

    private volatile boolean mIsTestingExit = false;
    private Button btn_test;
    private Button btn_play;
    private Button btn_stop;

    public native void renderChirpData();
    static{
        System.loadLibrary("PCMRender");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mAudioPlayer = new AudioPlayer();

        Log.d("wyf", "默认保存了路径: "+DEFAULT_TEST_FILE);
        btn_test = (Button) findViewById(R.id.btn_test);
        btn_test.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d("wyf", "*********1********");
                try {
                    MainActivity.this.renderChirpData();
                    Log.d("wyf", "*********2********");
                } catch (RuntimeException e) {
                    Log.d("wyf", "*********3********");
                    e.printStackTrace();
                }
            }
        });

        btn_play= (Button) findViewById(R.id.btn_play);
        btn_play.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mIsTestingExit = false;
                SoundPool();
             //   MainActivity.this.startTesting();
            }
        });
        btn_stop= (Button) findViewById(R.id.btn_stop);
        btn_stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mIsTestingExit = true;
            }
        });
    }
    void startTesting() {

        mWavFileReader = new WavFileReader();
        mAudioPlayer = new AudioPlayer();

        try {
            mWavFileReader.openFile(DEFAULT_TEST_FILE);
        } catch (IOException e) {
            e.printStackTrace();
        }

        mAudioPlayer.startPlayer();

        new Thread(AudioPlayRunnable).start();
    }

    private Runnable AudioPlayRunnable = new Runnable() {
        @Override
        public void run() {
            byte[] buffer = new byte[mAudioPlayer.getMinBufferSize()];
            while (!mIsTestingExit && mWavFileReader.readData(buffer, 0, buffer.length) > 0) {
                mAudioPlayer.play(buffer, 0, buffer.length);
            }
            mAudioPlayer.stopPlayer();
            try {
                mWavFileReader.closeFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    };

    private void SoundPool(){

//        soundPool= new SoundPool(10, AudioManager.STREAM_SYSTEM,5);
//        soundPool.load(this,R.raw.audio,1);
//        soundPool.play(1,1, 1, 0, 0, 1);
//        MediaPlayer mediaPlayer = MediaPlayer.create(MainActivity.this, R.raw.audio);
//        mediaPlayer.start();

        MediaPlayer mediaPlayer = new MediaPlayer();
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
//        mediaPlayer.setDataSource(getApplicationContext(),);

        try {
            mediaPlayer.setDataSource(DEFAULT_TEST_FILE);
            mediaPlayer.prepare();
        } catch (IOException e) {
            e.printStackTrace();
        }
        mediaPlayer.start();
    }

}


