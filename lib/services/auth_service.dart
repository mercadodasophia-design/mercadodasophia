import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;

  // Stream do estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com email/senha
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualizar último login no Firestore
      await _updateLastLogin(credential.user!.uid);
      
      // Migrar carrinho local para Firebase se necessário
      await _migrateLocalCart();
      
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Cadastro com email/senha
  Future<UserCredential> signUpWithEmail({
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

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login com Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔍 [DEBUG] Iniciando Google Sign-In...');
      
      // Verificar se o Google Sign-In está configurado corretamente
      print('🔍 [DEBUG] Verificando configuração...');
      bool isConfigured = await _checkGoogleSignInConfiguration();
      print('🔍 [DEBUG] Configuração válida: $isConfigured');
      
      if (!isConfigured) {
        print('❌ [DEBUG] Google Sign-In não configurado');
        throw Exception(
          'Google Sign-In não está configurado corretamente.\n\n'
          'Para configurar:\n'
          '1. Acesse Google Cloud Console\n'
          '2. Crie OAuth 2.0 Client IDs para Android\n'
          '3. Configure SHA-1 fingerprints\n'
          '4. Baixe google-services.json atualizado\n\n'
          'Por favor, use o login com email por enquanto.'
        );
      }

      // Iniciar o processo de login com Google
      print('🔍 [DEBUG] Chamando _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔍 [DEBUG] Resultado do signIn: ${googleUser?.email ?? "null"}');
      
      if (googleUser == null) {
        print('❌ [DEBUG] Usuário cancelou o login');
        throw Exception('Login cancelado pelo usuário');
      }

      // Obter os detalhes da autenticação do Google
      print('🔍 [DEBUG] Obtendo autenticação do Google...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔍 [DEBUG] Autenticação obtida: ${googleAuth.accessToken != null ? "OK" : "FALHOU"}');

      // Criar credencial do Firebase
      print('🔍 [DEBUG] Criando credencial Firebase...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Fazer login no Firebase
      print('🔍 [DEBUG] Fazendo login no Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('🔍 [DEBUG] Login Firebase: ${userCredential.user?.email ?? "FALHOU"}');
      
      // Verificar se é um novo usuário
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // Criar documento do usuário no Firestore para novos usuários
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? 'Usuário Google',
          'email': userCredential.user!.email,
          'photoURL': userCredential.user!.photoURL,
          'role': 'customer', // Role padrão para clientes
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'preferences': {
            'notifications': true,
            'marketing': false,
          },
          'provider': 'google',
        });
      } else {
        // Atualizar último login para usuários existentes
        await _updateLastLogin(userCredential.user!.uid);
      }

      // Migrar carrinho local para Firebase se necessário
      await _migrateLocalCart();

      notifyListeners();
      print('✅ [DEBUG] Google Sign-In concluído com sucesso!');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ [DEBUG] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ [DEBUG] Erro geral: $e');
      throw Exception('Erro no login com Google: $e');
    }
  }

  // Verificar se o Google Sign-In está configurado
  Future<bool> _checkGoogleSignInConfiguration() async {
    try {
      print('🔍 [DEBUG] Verificando configuração do Google Sign-In...');
      // Tentar uma operação simples do Google Sign-In
      await _googleSignIn.signInSilently();
      print('🔍 [DEBUG] Configuração OK - signInSilently funcionou');
      return true;
    } catch (e) {
      print('🔍 [DEBUG] Erro na verificação: $e');
      // Se der erro 12500, significa que não está configurado
      if (e.toString().contains('12500')) {
        print('❌ [DEBUG] Erro 12500 - configuração inválida');
        return false;
      }
      // Outros erros podem ser temporários
      print('⚠️ [DEBUG] Outro erro - assumindo configuração OK');
      return true;
    }
  }

  // Fazer logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  // Verificar se o usuário está autenticado
  bool get isLoggedIn => _auth.currentUser != null;

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

  // Obter dados do usuário
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
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

  // Migrar carrinho local para Firebase
  Future<void> _migrateLocalCart() async {
    try {
      // A migração será feita pelo CartProvider quando necessário
      // Aqui apenas notificamos que o usuário fez login
      print('🛒 Usuário fez login - carrinho local será migrado se necessário');
    } catch (e) {
      print('Erro ao migrar carrinho local: $e');
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
      
      notifyListeners();
    } catch (e) {
      throw Exception('Erro ao deletar conta: $e');
    }
  }
} 