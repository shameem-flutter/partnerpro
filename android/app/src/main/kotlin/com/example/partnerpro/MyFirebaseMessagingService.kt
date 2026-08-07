package com.example.partnerpro

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.max

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val title: String = remoteMessage.notification?.title 
            ?: remoteMessage.data["title"] 
            ?: "PartnerPro"
        val body: String = remoteMessage.notification?.body 
            ?: remoteMessage.data["body"] 
            ?: ""
        val imageUrl: String? = remoteMessage.notification?.imageUrl?.toString()
            ?: remoteMessage.data["image"]
            ?: remoteMessage.data["imageUrl"]

        showNotification(title, body, imageUrl)
    }

    private fun showNotification(title: String, body: String, imageUrl: String?) {
        val channelId = "partnerpro_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "PartnerPro Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for PartnerPro app"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        if (!imageUrl.isNullOrEmpty()) {
            val rawBitmap = getBitmapFromUrl(imageUrl)
            if (rawBitmap != null) {
                // Pad the image into a 16:9 canvas so it's 'contained' perfectly in BigPictureStyle
                val bigPictureBitmap = makeBigPictureBitmap(rawBitmap)
                
                // Do not set largeIcon to prevent showing "two logos"
                builder.setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(bigPictureBitmap)
                )
            }
        }

        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    private fun makeBigPictureBitmap(bitmap: Bitmap): Bitmap {
        // BigPictureStyle expects an approx 16:9 ratio. We create a 16:9 canvas and contain the logo.
        val canvasWidth = 1024
        val canvasHeight = 576
        val bgBitmap = Bitmap.createBitmap(canvasWidth, canvasHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bgBitmap)

        val width = bitmap.width.toDouble()
        val height = bitmap.height.toDouble()

        // Scale factor 'object-fit: contain' for 16:9 canvas
        val scale = minOf(canvasWidth / width, canvasHeight / height)
        val scaledWidth = (width * scale).toFloat()
        val scaledHeight = (height * scale).toFloat()

        val left = (canvasWidth - scaledWidth) / 2f
        val top = (canvasHeight - scaledHeight) / 2f

        val destRect = android.graphics.RectF(left, top, left + scaledWidth, top + scaledHeight)
        canvas.drawBitmap(bitmap, null, destRect, null)

        return bgBitmap
    }

    private fun getBitmapFromUrl(urlString: String): Bitmap? {
        return try {
            val url = URL(urlString)
            val connection = url.openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connect()
            val input = connection.inputStream
            BitmapFactory.decodeStream(input)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
