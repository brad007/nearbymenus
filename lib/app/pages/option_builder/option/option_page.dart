import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearbymenus/app/common_widgets/list_items_builder.dart';
import 'package:nearbymenus/app/common_widgets/platform_alert_dialog.dart';
import 'package:nearbymenus/app/common_widgets/platform_exception_alert_dialog.dart';
import 'package:nearbymenus/app/common_widgets/platform_trailing_icon.dart';
import 'package:nearbymenus/app/models/option.dart';
import 'package:nearbymenus/app/models/restaurant.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/pages/option_builder/option/option_details_page.dart';
import 'package:nearbymenus/app/pages/option_builder/option_item/option_item_page.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:provider/provider.dart';

class OptionPage extends StatefulWidget {
  final Restaurant restaurant;

  const OptionPage({Key key, this.restaurant,})
      : super(key: key);

  @override
  _OptionPageState createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  Session session;
  Database database;

  void _createOptionDetailsPage(BuildContext context, Option option) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: false,
        builder: (context) => OptionDetailsPage(
          restaurant: widget.restaurant,
          option: option,
        ),
      ),
    );
  }

  Future<void> _deleteOption(BuildContext context, Option option) async {
    try {
      await database.deleteOption(option);
      widget.restaurant.restaurantOptions.remove(option.id);
      Restaurant.setRestaurant(database, widget.restaurant);
    } on PlatformException catch (e) {
      PlatformExceptionAlertDialog(
        title: 'Operation failed',
        exception: e,
      ).show(context);
    }
  }

  Future<bool> _confirmDismiss(BuildContext context, Option option) async {
    var message = '';
    var inUse = false;
    var hasChildren = false;
    if (widget.restaurant.restaurantOptions != null && widget.restaurant.restaurantOptions.isNotEmpty) {
      if (widget.restaurant.restaurantOptions[option.id]['usedByMenuItems']
          .length > 0) {
        inUse = true;
        message =
        'Please first unselect this option from the menu items that are using it.';
      }
      if (!inUse) {
        widget.restaurant.restaurantOptions[option.id].forEach((key, value) {
          if (key
              .toString()
              .length > 20) {
            hasChildren = true;
            message = 'Please delete all the option items first.';
          }
        });
      }
    }
    if (inUse || hasChildren) {
      return !await PlatformExceptionAlertDialog(
        title: 'Option is in use or is not empty',
        exception: PlatformException(
          code: 'MAP_IS_NOT_EMPTY',
          message: message,
          details: message,
        ),
      ).show(context);
    } else {
      return await PlatformAlertDialog(
        title: 'Confirm option deletion',
        content: 'Do you really want to delete this option?',
        cancelActionText: 'No',
        defaultActionText: 'Yes',
      ).show(context);
    }
  }

  Widget _buildContents(BuildContext context) {
    return StreamBuilder<List<Option>>(
      stream: database.restaurantOptions(widget.restaurant.id),
      builder: (context, snapshot) {
        return ListItemsBuilder<Option>(
            snapshot: snapshot,
            itemBuilder: (context, option) {
              return Dismissible(
                background: Container(color: Colors.red),
                key: Key('option-${option.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDismiss(context, option),
                onDismissed: (direction) => _deleteOption(context, option),
                child: Card(
                  margin: EdgeInsets.all(12.0),
                  child: ListTile(
                    isThreeLine: false,
                    // leading: Icon(Icons.link),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.name,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => OptionItemPage(
                            restaurant: widget.restaurant,
                            option: option,
                          ),
                        ),
                      ),
                      icon: PlatformTrailingIcon(),
                    ),
                    onTap: () => _createOptionDetailsPage(context, option),
                  ),
                ),
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    session = Provider.of<Session>(context);
    database = Provider.of<Database>(context);
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.restaurant.name}',
            style: TextStyle(color: Theme.of(context).appBarTheme.color),
          ),
        ),
        body: _buildContents(context),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add new option',
          child: Icon(
            Icons.add,
          ),
          onPressed: () => _createOptionDetailsPage(context, Option()),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.restaurant.name}',
            style: TextStyle(color: Theme.of(context).appBarTheme.color),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.add,
                color: Theme.of(context).appBarTheme.color,
              ),
              iconSize: 32.0,
              padding: const EdgeInsets.only(right: 16.0),
              onPressed: () => _createOptionDetailsPage(context, Option()),
            ),
          ],
        ),
        body: _buildContents(context),
      );
    }
  }
}
