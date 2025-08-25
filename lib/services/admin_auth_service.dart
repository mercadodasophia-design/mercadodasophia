import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verificar se o usuário atual tem permissão de admin
  static Future<bool> isAdmin() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      final String? role = userData['role'] as String?;

      return role == 'admin' || role == 'super_admin';
    } catch (e) {
      print('Erro ao verificar permissão de admin: $e');
      return false;
    }
  }

  // Verificar se o usuário tem permissão de super admin
  static Future<bool> isSuperAdmin() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      final String? role = userData['role'] as String?;

      return role == 'super_admin';
    } catch (e) {
      print('Erro ao verificar permissão de super admin: $e');
      return false;
    }
  }

  // Obter o ID do usuário admin atual
  static String? getCurrentAdminId() {
    return _auth.currentUser?.uid;
  }

  // Verificar se o usuário está autenticado
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }
}
