import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // When an FCM message contains a `notification` payload, Android system FCM SDK
  // automatically displays a system notification when the app is in background/terminated.
  // We only trigger a local notification programmatically for data-only messages to prevent duplicates.
  if (message.notification == null) {
    await NotificationService.instance.showNotificationFromRemoteMessage(message);
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(settings: initSettings);

    // Create high importance notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'partnerpro_channel',
      'PartnerPro Notifications',
      description: 'Notifications for PartnerPro app',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Setup FCM Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotificationFromRemoteMessage(message);
    });

    // Register FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _isInitialized = true;
  }

  /// Downloads an image from [url] and returns raw bytes, or null if failed.
  Future<Uint8List?> fetchImageBytes(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      }
    } catch (e) {
      debugPrint('Error fetching notification image: $e');
    }
    return null;
  }
  /// Creates a standard 16:9 contained version of the image for BigPictureStyle
  /// to prevent Android's default CenterCrop behavior from cropping wide/tall logos.
  Future<Uint8List> createBigPictureBitmap(Uint8List imageBytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // 16:9 standard ratio for BigPicture
      const int canvasWidth = 1024;
      const int canvasHeight = 576;

      final double width = image.width.toDouble();
      final double height = image.height.toDouble();

      final double scale = math.min(canvasWidth / width, canvasHeight / height);
      final double scaledWidth = width * scale;
      final double scaledHeight = height * scale;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);

      final double left = (canvasWidth - scaledWidth) / 2.0;
      final double top = (canvasHeight - scaledHeight) / 2.0;

      final ui.Rect src = ui.Rect.fromLTWH(0, 0, width, height);
      final ui.Rect dst = ui.Rect.fromLTWH(left, top, scaledWidth, scaledHeight);
      canvas.drawImageRect(image, src, dst, ui.Paint());

      final ui.Picture picture = recorder.endRecording();
      final ui.Image paddedImage =
          await picture.toImage(canvasWidth, canvasHeight);
      final ByteData? byteData =
          await paddedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating big picture padded bitmap: $e');
    }
    return imageBytes;
  }


  /// Display notification from a RemoteMessage (FCM) or custom call
  Future<void> showNotificationFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final String title = notification?.title ?? data['title'] ?? 'PartnerPro';
    final String body = notification?.body ?? data['body'] ?? '';
    final String? imageUrl = notification?.android?.imageUrl ??
        notification?.apple?.imageUrl ??
        data['image'] ??
        data['imageUrl'];

    await showNotification(
      id: message.hashCode,
      title: title,
      body: body,
      imageUrl: imageUrl,
      payload: data.toString(),
    );
  }

  /// Low level method to display local notification with custom scaling logic
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
  }) async {
    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final rawBytes = await fetchImageBytes(imageUrl);
      if (rawBytes != null && rawBytes.isNotEmpty) {
        
        // 1. Create a 16:9 contained version for the expanded BigPictureStyle
        final bigPicBytes = await createBigPictureBitmap(rawBytes);

        androidDetails = AndroidNotificationDetails(
          'partnerpro_channel',
          'PartnerPro Notifications',
          channelDescription: 'Notifications for PartnerPro app',
          importance: Importance.max,
          priority: Priority.high,
          // Use the app icon (like WhatsApp) for the collapsed view to prevent cropping issues with rectangular logos
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), 
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bigPicBytes), // Used in expanded view
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
            hideExpandedLargeIcon: true, // Hides the small icon when fully expanded
          ),
        );
      } else {
        androidDetails = const AndroidNotificationDetails(
          'partnerpro_channel',
          'PartnerPro Notifications',
          channelDescription: 'Notifications for PartnerPro app',
          importance: Importance.max,
          priority: Priority.high,
        );
      }
    } else {
      androidDetails = const AndroidNotificationDetails(
        'partnerpro_channel',
        'PartnerPro Notifications',
        channelDescription: 'Notifications for PartnerPro app',
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
