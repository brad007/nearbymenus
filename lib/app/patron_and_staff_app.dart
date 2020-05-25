import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearbymenus/app/config/flavour_config.dart';
import 'package:nearbymenus/app/models/notification_streams.dart';
import 'package:nearbymenus/app/models/received_notification.dart';
import 'package:nearbymenus/app/pages/landing/landing_page.dart';
import 'package:nearbymenus/app/pages/landing/splash_screen.dart';
import 'package:nearbymenus/app/services/auth.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/utilities/app_theme.dart';
import 'package:nearbymenus/app/utilities/logo_image_asset.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:rxdart/subjects.dart';

class PatronAndStaffApp extends StatefulWidget {
  final Position currentLocation;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject;
  final BehaviorSubject<String> selectNotificationSubject;
  
  const PatronAndStaffApp({Key key,
    this.currentLocation,
    this.flutterLocalNotificationsPlugin,
    this.didReceiveLocalNotificationSubject,
    this.selectNotificationSubject
  }) : super(key: key);
  
  @override
  _PatronAndStaffAppState createState() => _PatronAndStaffAppState();
}

class _PatronAndStaffAppState extends State<PatronAndStaffApp> {

  @override
  Widget build(BuildContext context) {
    // Below line disabled since the bottom android nav bar behaves funny
    // SystemChrome.setEnabledSystemUIOverlays([]);
    final role = FlavourConfig.isPatron() ? ROLE_PATRON : ROLE_STAFF;
    if (widget.currentLocation != null) {
      return MultiProvider(
          providers: [
            Provider.value(value: widget.flutterLocalNotificationsPlugin),
            Provider<NotificationStreams>(create: (context) => NotificationStreams(
                didReceiveLocalNotificationSubject: widget.didReceiveLocalNotificationSubject,
                selectNotificationSubject: widget.selectNotificationSubject),
            ),
            Provider<LogoImageAsset>(create: (context) => LogoImageAsset()),
            Provider<AuthBase>(create: (context) => Auth()),
            Provider<Database>(create: (context) => FirestoreDatabase()),
            Provider<Session>(create: (context) => Session(position: widget.currentLocation, role: role)),
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
