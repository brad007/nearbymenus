import 'package:flutter/material.dart';
import 'package:nearbymenus/app/utilities/logo_image_asset.dart';
import 'package:provider/provider.dart';
import 'email_sign_in_page.dart';
import 'sign_in_button.dart';

class SignInPage extends StatelessWidget {

  void _signInWithEmail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => EmailSignInPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageAsset = Provider.of<LogoImageAsset>(context);
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: screenWidth / 3,
              height: screenHeight / 3,
              child: imageAsset.image,
            ),
          ),
          SizedBox(height: 24.0),
          SizedBox(height: 50.0, child: _buildHeader(context)),
          SizedBox(height: 36.0),
          // EMAIL
          SignInButton(
            text: 'Sign in',
            textColor: Theme.of(context).buttonTheme.colorScheme.onPrimary,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => _signInWithEmail(context),
          ),
          SizedBox(height: 36.0),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Welcome',
      textAlign: TextAlign.center,
      style: Theme.of(context).primaryTextTheme.headline4,
    );
  }

}
