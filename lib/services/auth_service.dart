import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Real Google Sign-In flow for Android/iOS (the old signInWithPopup only
  /// works on web). Requires the app's SHA-1 fingerprint to be registered in
  /// Firebase Console -> Project Settings -> your Android app.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in cancelled by user.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Starts Firebase Phone Auth for [phoneNumber] (E.164 format, e.g.
  /// "+919812345678"). Requires the Phone provider to be enabled in
  /// Firebase Console -> Authentication -> Sign-in method, and (for a
  /// smooth flow on real Android devices, via Play Integrity) the app's
  /// SHA-256 fingerprint registered alongside the SHA-1 already added for
  /// Google Sign-In.
  ///
  /// [onCodeSent] fires once an SMS has been dispatched, with the
  /// verification id needed by [signInWithSmsCode]. [onAutoVerified] fires
  /// instead if Android auto-detects the code without the user typing it
  /// (uncommon but handled). [onError] fires for a bad number, quota, etc.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
    required void Function(UserCredential credential) onAutoVerified,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: onError,
      codeSent: (verificationId, resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Deletes the signed-in Firebase Auth account itself - caller is
  /// responsible for wiping the user's Firestore/Storage data FIRST (see
  /// ProfileService.deleteAllUserData), since once this succeeds the user
  /// is signed out and no longer has permission to touch their old data.
  ///
  /// Firebase requires a "recent" sign-in for account deletion. If the
  /// session is stale, this throws FirebaseAuthException with code
  /// 'requires-recent-login' - the caller should tell the user to log out,
  /// log back in, and immediately retry rather than this method silently
  /// re-prompting a provider-specific reauth flow.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
    await _googleSignIn.signOut();
  }
}
