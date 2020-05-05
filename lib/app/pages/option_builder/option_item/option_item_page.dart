import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearbymenus/app/common_widgets/list_items_builder.dart';
import 'package:nearbymenus/app/common_widgets/platform_alert_dialog.dart';
import 'package:nearbymenus/app/common_widgets/platform_exception_alert_dialog.dart';
import 'package:nearbymenus/app/models/option.dart';
import 'package:nearbymenus/app/models/option_item.dart';
import 'package:nearbymenus/app/models/restaurant.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/pages/option_builder/option_item/option_item_details_page.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:provider/provider.dart';

class OptionItemPage extends StatefulWidget {
  final Restaurant restaurant;
  final Option option;

  const OptionItemPage({Key key, this.restaurant, this.option}) : super(key: key);

  @override
  _OptionItemPageState createState() => _OptionItemPageState();
}

class _OptionItemPageState extends State<OptionItemPage> {
  Session session;
  Database database;

  void _createOptionItemDetailsPage(BuildContext context, OptionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: false,
        builder: (context) => OptionItemDetailsPage(
          session: session,
          database: database,
          restaurant: widget.restaurant,
          option: widget.option,
          optionItem: item,
        ),
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, OptionItem item) async {
    try {
      await database.deleteOptionItem(item);
      widget.restaurant.restaurantMenus[widget.option.id].remove(item.id);
      Restaurant.setRestaurant(database, widget.restaurant);
    } on PlatformException catch (e) {
      PlatformExceptionAlertDialog(
        title: 'Operation failed',
        exception: e,
      ).show(context);
    }
  }

  Future<bool> _confirmDismiss(BuildContext context, OptionItem item) async {
    return await PlatformAlertDialog(
      title: 'Confirm option item deletion',
      content: 'Do you really want to delete this option item?',
      cancelActionText: 'No',
      defaultActionText: 'Yes',
    ).show(context);
  }

  Widget _buildContents(BuildContext context) {
    return StreamBuilder<List<OptionItem>>(
      stream: database.optionItems(widget.option.id),
      builder: (context, snapshot) {
        return ListItemsBuilder<OptionItem>(
            snapshot: snapshot,
            itemBuilder: (context, item) {
              return Dismissible(
                background: Container(color: Colors.red),
                key: Key('item-${item.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDismiss(context, item),
                onDismissed: (direction) => _deleteItem(context, item),
                child: Card(
                  margin: EdgeInsets.all(12.0),
                  child: ListTile(
                    isThreeLine: true,
                    leading: Icon(Icons.link),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        SizedBox(
                          height: 4.0,
                        ),
                      ],
                    ),
                    onTap: () => _createOptionItemDetailsPage(context, item),
                  ),
                ),
              );
            }
        );
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
            '${widget.option.name}', style: TextStyle(color: Theme
              .of(context)
              .appBarTheme
              .color),
          ),
        ),
        body: _buildContents(context),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add new option item',
          child: Icon(
            Icons.add,
          ),
          onPressed: () => _createOptionItemDetailsPage(context, OptionItem(optionId: widget.option.id)),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.option.name}', style: TextStyle(color: Theme
              .of(context)
              .appBarTheme
              .color),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).appBarTheme.color,),
              iconSize: 32.0,
              padding: const EdgeInsets.only(right: 16.0),
              onPressed: () => _createOptionItemDetailsPage(context, OptionItem(optionId: widget.option.id)),
            ),
          ],
        ),
        body: _buildContents(context),
      );
    }
  }

}