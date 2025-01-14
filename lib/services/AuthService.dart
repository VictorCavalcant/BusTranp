import 'package:firebase_auth/firebase_auth.dart';
import 'package:ubus/services/DriverService.dart';

class AuthService {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> logUser(
      {required String email, required String password}) async {
    try {
      RegExp regExp = RegExp(r'\d+');

      // Encontrar o número na string
      Match? match = regExp.firstMatch(email);

      String numero = "";

      if (match != null) {
        numero = match.group(0)!; // O número encontrado
      }

      String username = "Van $numero";

      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      await DriverService().addUser(userCredential.user!.uid, numero);

      await userCredential.user!.reload();

      await userCredential.user!.updateDisplayName(username);

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
