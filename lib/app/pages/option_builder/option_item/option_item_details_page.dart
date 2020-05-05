import 'package:flutter/material.dart';
import 'package:nearbymenus/app/models/option.dart';
import 'package:nearbymenus/app/models/option_item.dart';
import 'package:nearbymenus/app/models/restaurant.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/pages/option_builder/option_item/option_item_details_form.dart';
import 'package:nearbymenus/app/services/database.dart';

class OptionItemDetailsPage extends StatelessWidget {
  final Session session;
  final Database database;
  final Restaurant restaurant;
  final Option option;
  final OptionItem optionItem;

  const OptionItemDetailsPage({
    Key key,
    this.restaurant,
    this.option,
    this.session,
    this.database,
    this.optionItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter option item details'),
        elevation: 2.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: OptionItemDetailsForm.create(
              context: context,
              session: session,
              database: database,
              option: option,
              restaurant: restaurant,
              item: optionItem,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}