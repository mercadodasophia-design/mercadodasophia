import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/banner_model.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Coleção de banners
  CollectionReference get _banners => _firestore.collection('banners');

  // Obter todos os banners
  Future<List<Banner>> getBanners() async {
    try {
      final querySnapshot = await _banners.get();
      return querySnapshot.docs.map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Erro ao obter banners: $e');
      return [];
    }
  }

  // Obter banners ativos
  Future<List<Banner>> getActiveBanners() async {
    try {
      final querySnapshot = await _banners.where('isAtivo', isEqualTo: true).get();
      return querySnapshot.docs.map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Erro ao obter banners ativos: $e');
      return [];
    }
  }

  // Obter banners por seção (ex: SexyShop)
  Future<List<Banner>> getBannersBySection(String section) async {
    try {
      Query query = _banners;
      
      // Filtrar por seção e status ativo
      query = query.where('isAtivo', isEqualTo: true).where('secao', isEqualTo: section);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      // Se a coleção não existe ou não há dados, retorna lista vazia
      print('Nenhum banner encontrado para a seção $section: $e');
      return [];
    }
  }

  // Obter banners da seção SexyShop
  Future<List<Banner>> getSexyShopBanners() async {
    return await getBannersBySection('SexyShop');
  }

  // Obter banners da loja
  Future<List<Banner>> getLojaBanners() async {
    return await getBannersBySection('Loja');
  }

  // Adicionar banner
  Future<String> addBanner(Banner banner) async {
    try {
      final docRef = await _banners.add(banner.toMap());
      
      // Atualizar o banner com o ID gerado
      await _banners.doc(docRef.id).update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar banner: $e');
    }
  }

  // Atualizar banner
  Future<void> updateBanner(String id, Banner banner) async {
    try {
      await _banners.doc(id).update(banner.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar banner: $e');
    }
  }

  // Deletar banner
  Future<void> deleteBanner(String id) async {
    try {
      await _banners.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar banner: $e');
    }
  }

  // Alternar status do banner
  Future<void> toggleBannerStatus(String id, bool isAtivo) async {
    try {
      await _banners.doc(id).update({'isAtivo': isAtivo});
    } catch (e) {
      throw Exception('Erro ao alterar status do banner: $e');
    }
  }

  // Upload de imagem do banner
  Future<String> uploadBannerImage(String imagePath, String bannerId) async {
    try {
      final ref = _storage.ref().child('banners/$bannerId.jpg');
      await ref.putFile(File(imagePath));
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  // Deletar imagem do banner
  Future<void> deleteBannerImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Erro ao deletar imagem: $e');
    }
  }
}
