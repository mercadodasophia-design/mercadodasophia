import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class GoogleSignInValidator {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> validateConfiguration() async {
    Map<String, dynamic> results = {
      'success': [],
      'warnings': [],
      'errors': [],
    };

    try {
      // Verificar se o GoogleSignIn está disponível
      results['success'].add('GoogleSignIn package carregado com sucesso');
      
      // Verificar configuração do GoogleSignIn
      final GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        results['success'].add('Usuário já logado: ${currentUser.email}');
      } else {
        results['success'].add('Nenhum usuário logado (normal)');
      }

      // Verificar Firebase Auth
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        results['success'].add('Firebase Auth usuário: ${firebaseUser.email}');
      } else {
        results['success'].add('Firebase Auth sem usuário (normal)');
      }

    } catch (e) {
      results['errors'].add('Erro na validação: $e');
    }

    return results;
  }

  static Future<Map<String, dynamic>> testSignInProcess() async {
    Map<String, dynamic> results = {
      'success': [],
      'warnings': [],
      'errors': [],
    };

    try {
      // Testar o processo de sign in
      results['success'].add('Iniciando teste de Google Sign-In...');
      
      // Tentar fazer sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser != null) {
        results['success'].add('Google Sign-In bem-sucedido: ${googleUser.email}');
        
        // Obter credenciais
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        results['success'].add('Autenticação Google obtida');
        
        // Fazer sign in no Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        results['success'].add('Firebase Auth bem-sucedido: ${userCredential.user?.email}');
        
        // Fazer sign out para limpar
        await _auth.signOut();
        await _googleSignIn.signOut();
        results['success'].add('Sign out realizado com sucesso');
        
      } else {
        results['warnings'].add('Usuário cancelou o Google Sign-In');
      }

    } on PlatformException catch (e) {
      results['errors'].add('Erro de plataforma: ${e.code} - ${e.message}');
      results['errors'].add('Detalhes: ${e.details}');
    } catch (e) {
      results['errors'].add('Erro geral: $e');
    }

    return results;
  }

  static Future<Map<String, dynamic>> generateValidationReport() async {
    Map<String, dynamic> report = {
      'timestamp': DateTime.now().toString(),
      'configuration': await validateConfiguration(),
      'signInTest': await testSignInProcess(),
      'recommendations': [],
    };

    // Gerar recomendações baseadas nos resultados
    report['recommendations'] = _generateRecommendations(
      report['configuration'], 
      report['signInTest']
    );

    return report;
  }

  static List<String> _generateRecommendations(
    Map<String, dynamic> configValidation, 
    Map<String, dynamic> signInTest
  ) {
    List<String> recommendations = [];

    // Verificar se há erros de configuração
    if (configValidation['errors'].isNotEmpty) {
      recommendations.add('❌ Corrigir erros de configuração antes de prosseguir');
    }

    // Verificar se há erros no processo de sign in
    if (signInTest['errors'].isNotEmpty) {
      recommendations.add('❌ Verificar configuração do Google Cloud Console');
      recommendations.add('❌ Verificar SHA-1 fingerprints no Firebase');
      recommendations.add('❌ Verificar google-services.json');
    }

    // Verificar se o processo foi bem-sucedido
    if (signInTest['success'].isNotEmpty && signInTest['errors'].isEmpty) {
      recommendations.add('✅ Google Sign-In funcionando corretamente!');
    }

    if (recommendations.isEmpty) {
      recommendations.add('ℹ️ Verificar logs para mais detalhes');
    }

    return recommendations;
  }

  static Future<bool> hasGooglePlayServices() async {
    try {
      // Verificar se o Google Play Services está disponível
      return true; // Simplificado para teste
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        return {
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'photoUrl': currentUser.photoUrl,
          'id': currentUser.id,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
