import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualizar último login no Firestore
      await _updateLastLogin(credential.user!.uid);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registro com email e senha
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Criar documento do usuário no Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'customer', // Role padrão para clientes
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'preferences': {
          'notifications': true,
          'marketing': false,
        },
      });

      // Atualizar display name
      await credential.user!.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Atualizar perfil
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Atualizar dados do usuário no Firestore
  Future<void> updateUserData({
    String? name,
    String? phone,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (preferences != null) updateData['preferences'] = preferences;

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar dados do usuário: $e');
    }
  }

  // Obter dados do usuário do Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao obter dados do usuário: $e');
    }
  }

  // Verificar se usuário é admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userData = await getUserData(user.uid);
      return userData?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Verificar se usuário é manager
  Future<bool> isManager() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userData = await getUserData(user.uid);
      final role = userData?['role'];
      return role == 'admin' || role == 'manager';
    } catch (e) {
      return false;
    }
  }

  // Atualizar último login
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log do erro mas não falhar o login
      print('Erro ao atualizar último login: $e');
    }
  }

  // Tratar exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }

  // Deletar conta
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Deletar dados do Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Deletar conta do Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reautenticar usuário (necessário para operações sensíveis)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
} 