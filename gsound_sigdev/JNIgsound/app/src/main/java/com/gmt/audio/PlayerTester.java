package com.gmt.audio;

import android.util.Log;

import java.io.IOException;

public class PlayerTester {
    //the global variable flag judge the thread's state,only when the thread shutdown ,it can be true
    public static boolean flag = true;
    //the volatile running judge if the thread should run
    private volatile boolean running = false;
    //declare Class AudioPlayRunnable 's instance mAudioPlayRunnable
    private AudioPlayRunnable mAudioPlayRunnable = new AudioPlayRunnable();

    private AudioPlayer mAudioPlayer;
    private WavFileReader mWavFileReader;

    public boolean startTesting(String file) {

        mWavFileReader = new WavFileReader();
        mAudioPlayer = new AudioPlayer();

        try {
            mWavFileReader.openFile(file);
        } catch (IOException e) {
            e.printStackTrace();
        }
        /**
         *2017-08-02
         * kerwin
         * the logic is only when the flag is true (the thread has shutdown),running can be true,
         * and the new thread can be built!
         */
        if (flag) {
            running = true;
            mAudioPlayer.startPlayer();

            new Thread(mAudioPlayRunnable).start();
            return true;
        } else
            return false;
    }

    public boolean stopTesting() {

        running = false;
        return true;
    }

    public class AudioPlayRunnable implements Runnable {
        public void run() {
            //the buffer is set to hold all of the buffer data one time
            float[] buffer_float = new float[mAudioPlayer.getMinBufferSize() * 6];
            // the length of byte buffer must be the fourth of float buffer
            byte[] buffer = new byte[buffer_float.length * 4];

            flag = false;
            while (running) {
                //the file's size is fixed
                int a = mWavFileReader.readData(buffer, 44, 615280);
                Log.d("wyf", "run: **********normal***a:" + a);
                for (int i = 0; i < buffer_float.length; i++) {
                    buffer_float[i] = byte2float(buffer, i * 4);
                }
                try {
                    mAudioPlayer.play(buffer_float, 0, buffer_float.length);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                // break the thread
                if (!running) {
                    Log.d("wyf", "*********stop**********");
                    break;
                }
            }
            // only when the thread broken down ,flag can be true
            flag = true;
            mAudioPlayer.stopPlayer();
            try {
                mWavFileReader.closeFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * 字节转换为浮点
     *
     * @param b     字节（至少4个字节）
     * @param index 开始位置
     * @return
     */
    private static float byte2float(byte[] b, int index) {
        int l;
        l = b[index + 0];
        l &= 0xff;
        l |= ((long) b[index + 1] << 8);
        l &= 0xffff;
        l |= ((long) b[index + 2] << 16);
        l &= 0xffffff;
        l |= ((long) b[index + 3] << 24);
        return Float.intBitsToFloat(l);
    }

}
