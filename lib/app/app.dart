import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearbymenus/app/models/received_notification.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/pages/landing/landing_page.dart';
import 'package:nearbymenus/app/pages/landing/splash_screen.dart';
import 'package:nearbymenus/app/services/auth.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:nearbymenus/app/services/notification_streams.dart';
import 'package:nearbymenus/app/utilities/app_theme.dart';
import 'package:nearbymenus/app/utilities/logo_image_asset.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:rxdart/subjects.dart';

import 'common_widgets/platform_exception_alert_dialog.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Geolocator _geolocator;
  Position _currentLocation;
  PermissionStatus _permissionStatus;
  final MethodChannel platform = MethodChannel('crossingthestreams.io/resourceResolver');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
  final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
  BehaviorSubject<ReceivedNotification>();

  final BehaviorSubject<String> selectNotificationSubject =
  BehaviorSubject<String>();

  NotificationAppLaunchDetails notificationAppLaunchDetails;

  @override
  void initState() {
    super.initState();
    _determineLocationPermissions();
    _initNotifications();
    _requestIOSPermissions();
  }

  void _initNotifications() async {
    notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    var initializationSettingsAndroid = AndroidInitializationSettings('launchericon');
    // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
    // of the `IOSFlutterLocalNotificationsPlugin` class
    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification:
            (int id, String title, String body, String payload) async {
          didReceiveLocalNotificationSubject.add(ReceivedNotification(
              id: id, title: title, body: body, payload: payload));
        });

    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
          if (payload != null) {
            debugPrint('notification payload: ' + payload);
          }
          selectNotificationSubject.add(payload);
        });
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  _determineLocationPermissions(){
    PermissionHandler().checkPermissionStatus(PermissionGroup.location)
        .then((status) => _updateLocationPermissions(status));
  }

  _updateLocationPermissions(PermissionStatus status){
    if (_permissionStatus != status) {
      setState(() {
        _permissionStatus = status;
        if (_permissionStatus == PermissionStatus.granted){
          // print('Permission had already been granted... determining location...');
          _determineCurrentLocation();
        } else {
          // print('Permission not granted yet... asking...');
          PermissionHandler().requestPermissions([PermissionGroup.location])
              .then((permission){
            if (permission[PermissionGroup.location] == PermissionStatus.granted){
              // print('Permission granted... determining location...');
              _determineCurrentLocation();
            } else {
              // print('Permission not granted by user... exiting...');
              exit (0);
            }
          });
        }
      });
    }
  }

  _determineCurrentLocation() {
    _geolocator = Geolocator();
    _geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best
    ).timeout(
        Duration(
            seconds: 30
        ),
        onTimeout: () {
          print('Geolocator timed out');
          return;
    }).then((position) async {
      if (position != null) {
        _currentLocation = position;
        print(
            'Current location: ${_currentLocation.latitude} : ${_currentLocation
                .longitude}');
        setState(() {
          _currentLocation = position;
        });
      } else {
        await PlatformExceptionAlertDialog(
            title: 'Could not determine location',
            exception: PlatformException(
            code: 'NO_LOCATION_SERVICE',
            message:  'Please make sure location services are enabled.',
            details:  'Please make sure location services are enabled.',
        ),
        ).show(context);
        exit(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Below line disabled since the bottom android nav bar behaves funny
    // SystemChrome.setEnabledSystemUIOverlays([]);
    if (_currentLocation != null) {
      return MultiProvider(
          providers: [
            Provider.value(value: flutterLocalNotificationsPlugin),
            Provider<NotificationStreams>(create: (context) => NotificationStreams(
                didReceiveLocalNotificationSubject: didReceiveLocalNotificationSubject,
                selectNotificationSubject: selectNotificationSubject),
            ),
            Provider<LogoImageAsset>(create: (context) => LogoImageAsset()),
            Provider<AuthBase>(create: (context) => Auth()),
            Provider<Database>(create: (context) => FirestoreDatabase()),
            Provider<Session>(create: (context) => Session(position: _currentLocation)),
          ],
          child: MaterialApp(
            title: 'Nearby Menus',
            theme: AppTheme.createTheme(context),
            home: LandingPage(),
            builder: (context, widget) => ResponsiveWrapper.builder(
              widget,
              maxWidth: 1200,
              minWidth: 450,
              defaultScale: true,
              breakpoints: [
                ResponsiveBreakpoint(breakpoint: 450, name: MOBILE),
                ResponsiveBreakpoint(breakpoint: 800, name: TABLET, autoScale: true),
                ResponsiveBreakpoint(breakpoint: 1000, name: TABLET, autoScale: true),
              ],
            ),
          )
      );
    } else {
      return SplashScreen();
    }
  }
}
