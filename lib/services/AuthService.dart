import 'package:firebase_auth/firebase_auth.dart';
import 'package:ubus/services/DriverService.dart';

class AuthService {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> logUser(
      {required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      DriverService().addUser(userCredential.user!.uid);
      userCredential.user!.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut(driverId) async {
    DriverService().resetActive(driverId);
    DriverService().resetCoords(driverId);
    return _firebaseAuth.signOut();
  }
}
