import 'package:flutter/material.dart';
import 'package:nearbymenus/app/common_widgets/purchase_button.dart';
import 'package:nearbymenus/app/models/session.dart';
import 'package:provider/provider.dart';

class UpsellScreen extends StatefulWidget {
  final int blockedOrders;
  final int ordersLeft;

  const UpsellScreen({Key key, this.blockedOrders, this.ordersLeft}) : super(key: key);

  @override
  _UpsellScreenState createState() => _UpsellScreenState();
}

class _UpsellScreenState extends State<UpsellScreen> {
  Session session;
  int get ordersLeft => widget.ordersLeft;
  int get blockedOrders => widget.blockedOrders;

  List<Widget> buildPackages(BuildContext context) {
    print('Orders left: $ordersLeft');
    List<Widget> packages = List<Widget>();
    if (ordersLeft != null) {
      packages.add(Text(
        'Orders left: ${ordersLeft.toString()}',
        style: Theme
            .of(context)
            .textTheme
            .headline4,
      ));
      packages.add(SizedBox(height: 16.0,));
    }
    if (blockedOrders != null) {
      packages.add(Text(
        'Orders locked: $blockedOrders',
        style: Theme
            .of(context)
            .textTheme
            .headline4,
      ));
      packages.add(SizedBox(height: 16.0,));
    }
    session.subscription.availableOfferings.forEach((pkg) {
      packages.add(PurchaseButton(
        package: pkg,
        blockedOrders: blockedOrders,
      ));
      packages.add(SizedBox(height: 24.0,));
    });
    return packages;
  }

  @override
  Widget build(BuildContext context) {
    session = Provider.of<Session>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Buy a bundle to unlock your orders',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: buildPackages(context),
          ),
        ));
  }
}