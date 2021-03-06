import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class User {
  User({@required this.uid, @required this.photoUrl, @required this.displayName});
  final String uid;
  final String photoUrl;
  final String displayName;
}

abstract class AuthBase {
  Stream<User> get onAuthStateChanged;
  Future<User> currentUser();
  Future<User> signInAnonymously();
  Future<User> signInWithGoogle();
  Future<User> signInWithFacebook();
  Future<User> signInWithApple();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

class Auth implements AuthBase {
  final _fireBaseAuth = FirebaseAuth.instance;

  User _userFromFirebase(FirebaseUser user) {
    return user == null ? null : User(uid: user.uid, displayName: user.displayName, photoUrl: user.photoUrl);
  }

  @override
  Stream<User> get onAuthStateChanged {
    return _fireBaseAuth.onAuthStateChanged.map(_userFromFirebase);
  }

  @override
  Future<User> currentUser() async {
    final user = await _fireBaseAuth.currentUser();
    return _userFromFirebase(user);
  }

  @override
  Future<User> signInAnonymously() async {
    final authResult = await _fireBaseAuth.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<User> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    var googleAccount;
    try {
      googleAccount = await googleSignIn.signIn();
//      print('Google account => ${googleAccount.toString()}');
    } catch (e) {
      print(e.toString());
    }
    if (googleAccount != null) {
      final googleAuth = await googleAccount.authentication;
      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final authResult = await _fireBaseAuth.signInWithCredential(
          GoogleAuthProvider.getCredential(
              idToken: googleAuth.idToken,
              accessToken: googleAuth.accessToken),
        );
        return _userFromFirebase(authResult.user);
      } else {
        print('MISSING TOKEN...');
        throw PlatformException(
            code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN',
            message: 'Missing Google Auth Token');
      }
    } else {
      print('ABORTED by USER...');
      throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER', message: 'Sign In Aborted By User');
    }
  }

  @override
  Future<User> signInWithFacebook() async {
    final facebookLogin = FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    FacebookLoginResult result = await facebookLogin.logInWithReadPermissions(
      ['public_profile'],
    );
    if (result.accessToken != null) {
      final authResult = await _fireBaseAuth.signInWithCredential(
        FacebookAuthProvider.getCredential(
            accessToken: result.accessToken.token),
      );
      return _userFromFirebase(authResult.user);
    } else {
      print('ABORTED by USER...');
      throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER', message: 'Sign In Aborted by User');
    }
  }

  @override
  Future<User> signInWithApple() async {
//    try {
      final AuthorizationResult result = await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);
      switch (result.status) {
        case AuthorizationStatus.authorized:
//          try {
            print("Apple successfull sign in");
            final appleIdCredential = result.credential;
            final oAuthProvider = OAuthProvider(providerId: "apple.com");
            final credential = oAuthProvider.getCredential(
              idToken: String.fromCharCodes(appleIdCredential.identityToken),
              accessToken: String.fromCharCodes(appleIdCredential.authorizationCode),
            );
            final authResult = await _fireBaseAuth.signInWithCredential(credential);
            final firebaseUser = authResult.user;
            final updateUser = UserUpdateInfo();
            updateUser.displayName = '${appleIdCredential.fullName.givenName} ${appleIdCredential.fullName.familyName}';
            await firebaseUser.updateProfile(updateUser);
            return _userFromFirebase(authResult.user);
//          } catch (e) {
//            print('Apple Sign-in ERROR during Firebase auth');
//            throw PlatformException(
//                code: 'ERROR_', message: 'Apple Firebase Sign-in error');
//          }
          break;
        case AuthorizationStatus.error:
        // do something
          print('Apple authorization denied');
          throw PlatformException(
              code: 'ERROR_AUTHORIZATION_DENIED',
              message: 'Apple Authorization denied');
          break;
        case AuthorizationStatus.cancelled:
          print('Apple Sign in cancelled by user...');
          throw PlatformException(
              code: 'ERROR_ABORTED_BY_USER',
              message: 'Apple Sign In Cancelled by User');
          break;
      }
 //   } catch (error) {
//      print('ERROR during Apple Sign-in');
//      throw PlatformException(
//          code: 'ERROR_',
//          message: 'Apple Sign-in error');
 //   }
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final authResult = await _fireBaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    final authResult = await _fireBaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final facebookLogin = FacebookLogin();
    await facebookLogin.logOut();
    await _fireBaseAuth.signOut();
  }
}
