import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nearbymenus/app/common_widgets/form_submit_button.dart';
import 'package:nearbymenus/app/common_widgets/platform_alert_dialog.dart';
import 'package:nearbymenus/app/common_widgets/platform_exception_alert_dialog.dart';
import 'package:nearbymenus/app/models/order.dart';
import 'package:nearbymenus/app/models/order_counter.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:nearbymenus/app/services/database.dart';
import 'package:nearbymenus/app/utilities/format.dart';
import 'package:provider/provider.dart';

class ViewOrder extends StatefulWidget {
  final Order order;

  const ViewOrder({Key key, this.order}) : super(key: key);

  @override
  _ViewOrderState createState() => _ViewOrderState();
}

class _ViewOrderState extends State<ViewOrder> {
  Session session;
  Database database;
  final f = NumberFormat.simpleCurrency(locale: "en_ZA");
  String paymentMethod;
  ScrollController orderScrollController = ScrollController();
  ScrollController itemsScrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  Order get order => widget.order;

  @override
  void initState() {
    super.initState();
    paymentMethod = order.paymentMethod ?? '';
    _notesController.text = order.notes;
  }


  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _deleteOrderItem(int index) {
    setState(() {
      order.orderItems.removeAt(index);
    });
  }

  Future<bool> _confirmDismiss(BuildContext context) async {
    if (order.status != ORDER_ON_HOLD) {
      return false;
    }
    return await PlatformAlertDialog(
      title: 'Confirm order item deletion',
      content: 'Do you really want to delete this order item?',
      cancelActionText: 'No',
      defaultActionText: 'Yes',
    ).show(context);
  }

  Future<bool> _confirmCancelOrder(BuildContext context) async {
    return await PlatformAlertDialog(
      title: 'Confirm order cancelation',
      content: 'Do you really want to cancel this order?',
      cancelActionText: 'No',
      defaultActionText: 'Yes',
    ).show(context);
  }

  void _submitOrder() async {
    int orderNumber = 0;
    OrderCounter orderCounter = OrderCounter(ordersLeft: 0, lastUpdated: order.id);
    await database.orderNumber(session.nearestRestaurant.id).then((value) {
      if (value != null) {
        orderNumber = value;
      }
    }).catchError((_) => null);
    await database.ordersLeft(session.nearestRestaurant.managerId).then((value) {
      if (value != null) {
        orderCounter = value;
      }
    }).catchError((_) => null);
    if (orderCounter.ordersLeft < 1) {
      order.isBlocked = true;
    }
    print('Orders left in bundle: ${orderCounter.ordersLeft}');
    try {
      orderCounter.ordersLeft--;
      orderCounter.lastUpdated = order.id;
      orderNumber++;
      print('Order number: $orderNumber');
      order.orderNumber = orderNumber;
      order.notes = _notesController.text;
      order.status = ORDER_PLACED;
      await database.setOrder(order);
      await database.setOrderNumber(session.nearestRestaurant.id, orderNumber);
      await database.setOrderCounter(session.nearestRestaurant.managerId, orderCounter);
      session.currentOrder = null;
      //await Future.delayed(Duration(seconds: 2)); // Simulate slow network
      Navigator.of(context).pop();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Widget _buildContents(BuildContext context) {
    session = Provider.of<Session>(context);
    database = Provider.of<Database>(context);
    if (order == null) {
      return null;
    }
    final orderTotal = order.orderTotal;
    return SingleChildScrollView(
      controller: orderScrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: MediaQuery.of(context).size.width - 16.0,
          color: Theme.of(context).dialogBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Column(
                children: [
                  SizedBox(
                    height: 16.0,
                  ),
                  if (order.status != ORDER_ON_HOLD)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24.0),
                    child: Text(
                      'Order # ${order.orderNumber}',
                      style: Theme.of(context).accentTextTheme.headline5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24.0),
                    child: Text(
                      'Deliver to:',
                      style: Theme.of(context).accentTextTheme.headline4,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(order.name),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(order.deliveryAddress),
                  ),
                  SizedBox(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Scrollbar(
                        isAlwaysShown: true,
                        controller: itemsScrollController,
                        child: ListView.builder(
                          controller: itemsScrollController,
                          shrinkWrap: true,
                          itemCount: order.orderItems.length,
                          itemBuilder: (BuildContext context, int index) {
                          final orderItem = order.orderItems[index];
                          final List<dynamic> orderItemOptions = orderItem['options'];
                          return Dismissible(
                            background: Container(color: Colors.red),
                            key: Key('${orderItem['id']}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDismiss(context),
                            onDismissed: (direction) => _deleteOrderItem(index),
                            child: Card(
                              child: ListTile(
                                isThreeLine: false,
                                leading: Text(
                                  orderItem['quantity'].toString(),
                                ),
                                title: Row(
                                  children: [
                                    SizedBox(
                                      width: 60.0,
                                      child: Text(orderItem['menuCode']),
                                    ),
                                    Text(
                                      orderItem['name'],
                                    ),
                                  ],
                                ),
                                subtitle: orderItemOptions.isEmpty ? Text('') : Text(
                                  orderItem['options'].toString().replaceAll(RegExp(r'\[|\]'), ''),
                                ),
                                trailing: Text(
                                    f.format(orderItem['lineTotal'])
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Swipe items to the left to remove.'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Total: ' + f.format(orderTotal),
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Select payment method',
                    ),
                  ),
                  Column(
                     children: _buildPaymentMethods(),
                  ),
                  Text(
                      Format.formatDateTime(order.timestamp.toInt()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Order status: ${order.statusString}'
                    ),
                  ),
                  _notesField(context, order.notes),
                  if (order.status == ORDER_ON_HOLD)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FormSubmitButton(
                          context: context,
                          text: 'Cancel',
                          color: Theme.of(context).primaryColor,
                          onPressed: () async {
                            final bool cancelOrder = await _confirmCancelOrder(context);
                            if (cancelOrder) {
                              order.status = ORDER_CANCELLED;
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        Builder(
                          builder: (context) => FormSubmitButton(
                            context: context,
                            text: 'Submit',
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              _checkAndSubmitOrder(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesField(BuildContext context, String notes) {
    var notesField;
    if (session.currentOrder != null && session.currentOrder.status == ORDER_ON_HOLD) {
      notesField = TextField(
        style: Theme.of(context).inputDecorationTheme.labelStyle,
        controller: _notesController,
        focusNode: _notesFocusNode,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelText: 'Notes',
          enabled: true,
        ),
        autocorrect: false,
        enableSuggestions: false,
        enableInteractiveSelection: false,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        //onChanged: model.updateMenuName,
        //onEditingComplete: () => _menuNameEditingComplete(),
      );
    } else {
      notesField = Text(notes);
    }
    return Column(
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.headline5,
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: notesField,
        )
      ],
    );
  }

  void _checkAndSubmitOrder(BuildContext context) async {
    if (paymentMethod != '') {
      order.paymentMethod = paymentMethod;
      _submitOrder();
      _showSnackBar(context, 'Order submitted successfully to ${session.nearestRestaurant.name}!');
    } else {
        await PlatformExceptionAlertDialog(
            title: 'Payment method not selected',
            exception: PlatformException(
            code: 'INCORRECT_PAYMENT_METHOD',
            message:  'Please select a payment method.',
            details:  'Please select a payment method.',
        ),
      ).show(context);
    }
  }

  List<Widget> _buildPaymentMethods() {
    List<Widget> paymentOptionsList = List<Widget>();
    Map<String, dynamic> restaurantPaymentOptions = session.nearestRestaurant.paymentFlags;
    restaurantPaymentOptions.forEach((key, value) {
      if (value) {
        paymentOptionsList.add(CheckboxListTile(
          title: Text(
            key,
          ),
          value: _optionCheck(key),
          onChanged: (flag) => _updatePaymentMethod(key, flag),
        ));
      }
    });
    return paymentOptionsList;
  }

  void _updatePaymentMethod(String key, bool flag) {
    if (order.status != ORDER_ON_HOLD) {
      return;
    }
    setState(() {
      if (flag) {
        paymentMethod = key;
      } else {
        paymentMethod = '';
      }
    });
  }

  bool _optionCheck(String key) => paymentMethod == key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your order details',
          style: TextStyle(color: Theme.of(context).appBarTheme.color),
        ),
      ),
      body: _buildContents(context),
    );
  }
}
