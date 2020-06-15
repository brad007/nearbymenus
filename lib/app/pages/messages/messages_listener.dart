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
  Session session;
  Database database;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    session = Provider.of<Session>(context);
    database = Provider.of<Database>(context, listen: true);
    flutterLocalNotificationsPlugin =
        Provider.of<FlutterLocalNotificationsPlugin>(context);
    String role = '';
    Stream<List<UserMessage>> _stream;
    if (FlavourConfig.isManager()) {
      role = ROLE_MANAGER;
      _stream = database.managerMessages(database.userId, ROLE_MANAGER);
    } else if (FlavourConfig.isStaff()) {
      role = ROLE_STAFF;
      _stream = database.staffMessages(session.currentRestaurant.id, ROLE_STAFF);
    } else {
      _stream = database.patronMessages(database.userId);
      role = ROLE_PATRON;
    }
    return StreamBuilder<List<UserMessage>>(
      stream: _stream,
      builder: (context, snapshot) {
        session.pendingStaffAuthorizations = 0;
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
                attendedFlag: message.attendedFlag,
              );
              database.setMessageDetails(readMessage);
            }
            if (message.attendedFlag == false && message.toRole == ROLE_MANAGER) {
              session.pendingStaffAuthorizations++;
            }
          });
        }
        return widget.page;
      });
  }
}
