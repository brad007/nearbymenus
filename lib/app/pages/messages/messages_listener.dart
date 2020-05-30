import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearbymenus/app/common_widgets/platform_progress_indicator.dart';
import 'package:nearbymenus/app/config/flavour_config.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/models/user_message.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:provider/provider.dart';

class MessagesListener extends StatefulWidget {
  final Widget page;

  const MessagesListener({Key key, this.page}) : super(key: key);

  @override
  _MessagesListenerState createState() => _MessagesListenerState();
}

class _MessagesListenerState extends State<MessagesListener> {
  Database database;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String role = ROLE_PATRON;

  Future<void> _notifyUser(UserMessage message) async {
    // TODO temp notifications code for testing
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'CH1', 'Role notifications', 'Channel used to notify restaurant roles',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Nearby Menus',
        'Notification from ${message.fromRole}: ${message.type}',
        platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {
    database = Provider.of<Database>(context, listen: true);
    flutterLocalNotificationsPlugin =
        Provider.of<FlutterLocalNotificationsPlugin>(context);
    if (FlavourConfig.isManager()) {
      role = ROLE_MANAGER;
    } else if (FlavourConfig.isStaff()) {
      role = ROLE_STAFF;
    }
    return StreamBuilder<List<UserMessage>>(
        stream: database.userMessages(
          database.userId,
          role,
        ),
        //stream: database.userNotifications(database.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: PlatformProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            final notificationsList = snapshot.data;
            notificationsList.forEach((message) {
              print('Message for ${message.toRole}');
              if (message.toRole == role &&
                  !message.delivered) {
                _notifyUser(message);
                UserMessage readMessage = UserMessage(
                  id: message.id,
                  timestamp: message.timestamp,
                  fromUid: message.fromUid,
                  toUid: message.toUid,
                  restaurantId: message.restaurantId,
                  fromRole: message.fromRole,
                  toRole: message.toRole,
                  fromName: message.fromName,
                  type: message.type,
                  authFlag: message.authFlag,
                  delivered: true,
                );
                database.setMessageDetails(readMessage);
              }
            });
          }
          return widget.page;
        });
  }
}