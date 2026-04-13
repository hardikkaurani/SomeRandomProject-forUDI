package com.example.sms_parser_basically

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Intentionally left blank. Live SMS observation is handled by android_sms_reader.
    }
}
