package com.shu.wyf.sinsoundingmodule;

import android.content.Context;
import android.os.PowerManager;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

import com.libra.sinvoice.Common;
import com.libra.sinvoice.LogHelper;
import com.libra.sinvoice.SinVoicePlayer;

import java.io.UnsupportedEncodingException;

public class MainActivity extends AppCompatActivity implements SinVoicePlayer.Listener {
    private final static String TAG = "MainActivityxx";

    private final static int[] TOKENS = { 32, 32, 32, 32, 32, 32 };
    private final static int TOKEN_LEN = TOKENS.length;

    private SinVoicePlayer mSinVoicePlayer;
    private PowerManager.WakeLock mWakeLock;
    private EditText mPlayTextView;

    static {
        System.loadLibrary("sinvoice");
        LogHelper.d(TAG, "sinvoice jnicall loadlibrary");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, TAG);

        mSinVoicePlayer = new SinVoicePlayer();
        mSinVoicePlayer.init(this);
        mSinVoicePlayer.setListener(this);

        mPlayTextView = (EditText) findViewById(R.id.playtext);
        mPlayTextView.setMovementMethod(ScrollingMovementMethod.getInstance());

        Button playStart = (Button) findViewById(R.id.start_play);
        playStart.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /**********************************************************************************/
                try {
                    byte[] strs = mPlayTextView.getText().toString().getBytes("UTF8");
                    if ( null != strs ) {
                        int len = strs.length;
                        int []tokens = new int[len];
                        int maxEncoderIndex = mSinVoicePlayer.getMaxEncoderIndex();
                        LogHelper.d(TAG, "maxEncoderIndex:" + maxEncoderIndex);
                        String encoderText = mPlayTextView.getText().toString();
                        for ( int i = 0; i < len; ++i ) {
                            if ( maxEncoderIndex < 255 ) {
                                tokens[i] = Common.DEFAULT_CODE_BOOK.indexOf(encoderText.charAt(i));
                            } else {
                                tokens[i] = strs[i];
                            }
                        }
                        mSinVoicePlayer.play(tokens, len, false, 2000);
                    } else {
                        mSinVoicePlayer.play(TOKENS, TOKEN_LEN, false, 2000);
                    }
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                /**********************************************************************************/
            }
        });

        Button playStop = (Button) findViewById(R.id.stop_play);
        playStop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View arg0) {
                /**********************************************************************************/
                mSinVoicePlayer.stop();
                /**********************************************************************************/
            }
        });

    }

    @Override
    public void onResume() {
        super.onResume();

        mWakeLock.acquire();
    }

    @Override
    public void onPause() {
        super.onPause();

        mWakeLock.release();

        mSinVoicePlayer.stop();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mSinVoicePlayer.uninit();
    }

    @Override
    public void onSinVoicePlayStart() {
        LogHelper.d(TAG, "start play");
    }

    @Override
    public void onSinVoicePlayEnd() {
        LogHelper.d(TAG, "stop play");
    }

    @Override
    public void onSinToken(int[] tokens) {}
}
