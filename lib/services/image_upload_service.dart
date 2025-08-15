import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Uuid _uuid = Uuid();

  /// Upload de uma lista de imagens para Firebase Storage
  /// Retorna lista de URLs públicas das imagens
  static Future<List<String>> uploadImages(
    List<File> images, 
    String productId, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    List<String> uploadedUrls = [];
    
    print('🚀 Iniciando upload de ${images.length} imagens para produto $productId');
    
    for (int i = 0; i < images.length; i++) {
      try {
        print('📸 Processando imagem ${i + 1}/${images.length}');
        
        // Verificar se o arquivo existe
        if (!await images[i].exists()) {
          print('❌ Arquivo da imagem $i não existe: ${images[i].path}');
          continue;
        }
        
        // Comprimir imagem
        File compressedImage = await compressImage(
          images[i],
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        
        print('✅ Imagem $i comprimida: ${compressedImage.path}');
        
        // Upload para Firebase Storage
        String imageUrl = await _uploadToFirebase(compressedImage, productId, i);
        uploadedUrls.add(imageUrl);
        
        print('✅ Imagem $i enviada com sucesso: $imageUrl');
        
        // Limpar arquivo temporário comprimido
        try {
          if (compressedImage.path != images[i].path) {
            await compressedImage.delete();
          }
        } catch (e) {
          print('⚠️ Erro ao limpar arquivo temporário: $e');
        }
        
      } catch (e) {
        print('❌ Erro ao fazer upload da imagem $i: $e');
        // Continuar com as próximas imagens mesmo se uma falhar
      }
    }
    
    print('📊 Upload concluído: ${uploadedUrls.length}/${images.length} imagens enviadas');
    return uploadedUrls;
  }

  /// Comprimir uma imagem
  static Future<File> compressImage(
    File imageFile, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      // Verificar se o arquivo existe
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não existe: ${imageFile.path}');
      }
      
      // Verificar tamanho do arquivo
      int fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Arquivo de imagem está vazio: ${imageFile.path}');
      }
      
      print('📏 Processando imagem: ${fileSize} bytes');
      
      // Por enquanto, retornar a imagem original sem compressão
      // TODO: Implementar compressão nativa ou usar outro plugin
      print('📏 Retornando imagem original (compressão desabilitada)');
      
      return imageFile;
      
    } catch (e) {
      print('❌ Erro ao processar imagem: $e');
      print('🔄 Retornando imagem original');
      // Retornar imagem original se a compressão falhar
      return imageFile;
    }
  }

  /// Upload para Firebase Storage
  static Future<String> _uploadToFirebase(
    File imageFile, 
    String productId, 
    int index,
  ) async {
    try {
      // Verificar se o usuário está autenticado
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não está autenticado. Faça login primeiro.');
      }
      
      print('🔐 Usuário autenticado: ${currentUser.email}');
      
      // Gerar nome único para o arquivo
      String fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      String storagePath = 'products/$productId/images/$fileName';
      
      print('📁 Caminho do storage: $storagePath');
      
      // Referência no Firebase Storage
      Reference storageRef = _storage.ref().child(storagePath);
      
      // Configurar metadados explícitos para evitar problemas de null
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
        customMetadata: {
          'productId': productId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'uploadedBy': currentUser.uid,
        },
      );
      
      print('📤 Iniciando upload...');
      
      // Upload do arquivo com metadados
      UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Aguardar conclusão
      TaskSnapshot snapshot = await uploadTask;
      
      print('✅ Upload concluído, obtendo URL...');
      
      // Obter URL pública
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('🔗 URL obtida: $downloadUrl');
      
      return downloadUrl;
      
    } catch (e) {
      print('❌ Erro detalhado no upload para Firebase: $e');
      throw Exception('Erro no upload para Firebase: $e');
    }
  }

  /// Deletar imagens do Firebase Storage
  static Future<void> deleteImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      try {
        Reference ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Erro ao deletar imagem $url: $e');
      }
    }
  }

  /// Obter URL pública de uma imagem
  static Future<String> getPublicUrl(String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao obter URL pública: $e');
    }
  }

  /// Validar se uma URL é válida
  static bool isValidImageUrl(String url) {
    return url.isNotEmpty && 
           (url.startsWith('http://') || url.startsWith('https://')) &&
           (url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.webp'));
  }

  /// Extrair nome do arquivo de uma URL
  static String getFileNameFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      return path.split('/').last;
    } catch (e) {
      return 'unknown.jpg';
    }
  }
}