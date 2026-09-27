package com.example.sally

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val textView = TextView(this)
        textView.text = "You need to authenticate."
	textView.setTextColor(Color.BLACK)
	textView.setBackgroundColor(Color.WHITE)
	textView.gravity = Gravity.CENTER

        setContentView(textView)
    }
}
