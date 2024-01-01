/*
 * Copyright (C) 2022-2024 Paranoid Android
 *
 * SPDX-License-Identifier: Apache-2.0
 */

package com.xiaomi.settings.doze;

import android.app.KeyguardManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.IBinder;
import android.os.PowerManager;
import android.os.SystemClock;
import android.util.Log;

public class PocketDetectionService extends Service {
    private static final String TAG = "XiaomiPartsPocketDetectionService";
    private static final boolean DEBUG = false;

    /* xiaomi.sensor.large_area_detect */
    private static final int TYPE_LARGE_AREA_TOUCH_SENSOR = 33171031;

    private PowerManager mPowerManager;
    private KeyguardManager mKeyguardManager;
    private SensorManager mSensorManager;
    private Sensor mTouchSensor;

    private boolean mUserPresent;

    @Override
    public void onCreate() {
        // Ensure to call the superclass method
        super.onCreate();
        if (DEBUG) Log.i(TAG, "Creating service");
        initializeManagers();
        registerScreenStateReceiver();
    }

    private void initializeManagers() {
        mPowerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mKeyguardManager = (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
        mSensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        mTouchSensor = mSensorManager.getDefaultSensor(TYPE_LARGE_AREA_TOUCH_SENSOR);
    }

    private void registerScreenStateReceiver() {
        IntentFilter screenStateFilter = new IntentFilter();
        screenStateFilter.addAction(Intent.ACTION_SCREEN_ON);
        screenStateFilter.addAction(Intent.ACTION_SCREEN_OFF);
        screenStateFilter.addAction(Intent.ACTION_USER_PRESENT);
        registerReceiver(mScreenStateReceiver, screenStateFilter);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (DEBUG) Log.i(TAG, "Starting service");
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        if (DEBUG) Log.i(TAG, "Destroying service");
        unregisterReceiver(mScreenStateReceiver);
        mSensorManager.unregisterListener(mSensorListener);
        // Call the superclass method at the end
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private final BroadcastReceiver mScreenStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent != null) {
                handleIntentAction(intent.getAction());
            }
        }
    };

    private void handleIntentAction(String action) {
        if (Intent.ACTION_SCREEN_ON.equals(action)) {
            handleScreenOn();
        } else if (Intent.ACTION_SCREEN_OFF.equals(action)) {
            handleScreenOff();
        } else if (Intent.ACTION_USER_PRESENT.equals(action)) {
            handleUserPresent();
        }
    }

    private void handleScreenOn() {
        if (DEBUG) Log.i(TAG, "Received ACTION_SCREEN_ON mUserPresent=" + mUserPresent);
        if (!mUserPresent) {
            mSensorManager.registerListener(mSensorListener, mTouchSensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }

    private void handleScreenOff() {
        if (DEBUG) Log.i(TAG, "Received ACTION_SCREEN_OFF");
        // Disable it when unlocked
        mSensorManager.unregisterListener(mSensorListener);
        mUserPresent = false;
    }

    private void handleUserPresent() {
        if (DEBUG) Log.i(TAG, "Received ACTION_USER_PRESENT");
        mSensorManager.unregisterListener(mSensorListener);
        mUserPresent = true;
    }

    private final SensorEventListener mSensorListener = new SensorEventListener() {
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) { }

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == TYPE_LARGE_AREA_TOUCH_SENSOR) {
                processSensorEvent(event);
            }
        }
    };

    private void processSensorEvent(SensorEvent event) {
        boolean isTouchDetected = event.values[0] == 1;
        boolean isOnKeyguard = mKeyguardManager.isKeyguardLocked();

        if (DEBUG) {
            Log.i(TAG, "onSensorChanged type=" + event.sensor.getType()
                    + " value=" + event.values[0] + " isTouchDetected="
                    + isTouchDetected + " isOnKeyguard=" + isOnKeyguard);
        }

        if (isTouchDetected && isOnKeyguard) {
            Log.i(TAG, "In pocket, going to sleep");
            mPowerManager.goToSleep(SystemClock.uptimeMillis());
        }
    }
}
