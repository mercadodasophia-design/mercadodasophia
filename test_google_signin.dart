import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  print('🧪 Testando Google Sign-In...');
  
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  try {
    print('1. Verificando se GoogleSignIn pode ser inicializado...');
    await googleSignIn.signInSilently();
    print('✅ GoogleSignIn inicializado com sucesso');
    
    print('2. Tentando fazer sign in...');
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    
    if (account != null) {
      print('✅ Sign in bem-sucedido: ${account.email}');
      
      print('3. Obtendo autenticação...');
      final GoogleSignInAuthentication auth = await account.authentication;
      print('✅ Autenticação obtida');
      
      print('4. Fazendo sign out...');
      await googleSignIn.signOut();
      print('✅ Sign out realizado');
      
    } else {
      print('⚠️ Usuário cancelou o sign in');
    }
    
  } catch (e) {
    print('❌ Erro: $e');
  }
}




