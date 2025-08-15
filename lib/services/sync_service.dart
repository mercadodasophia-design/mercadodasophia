import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aliexpress_service.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const Duration _syncInterval = Duration(hours: 6); // Sincronizar a cada 6 horas
  
  final AliExpressService _aliExpressService = AliExpressService();
  Timer? _syncTimer;
  
  /// Inicia a sincronização automática
  Future<void> startAutoSync() async {
    print('🔄 Iniciando sincronização automática...');
    
    // Sincronizar imediatamente
    await _performSync();
    
    // Configurar timer para sincronização periódica
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await _performSync();
    });
  }
  
  /// Para a sincronização automática
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ Sincronização automática parada');
  }
  
  /// Executa a sincronização
  Future<void> _performSync() async {
    try {
      print('🔄 Executando sincronização...');
      
      final firestore = FirebaseFirestore.instance;
      final productsRef = firestore.collection('products');
      
      // Buscar produtos importados do AliExpress
      final query = await productsRef
          .where('importedFrom', isEqualTo: 'aliexpress')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (query.docs.isEmpty) {
        print('ℹ️ Nenhum produto importado encontrado para sincronizar');
        return;
      }
      
      final productUrls = <String>[];
      final productIds = <String>[];
      
      for (final doc in query.docs) {
        final data = doc.data();
        final url = data['aliexpressUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          productUrls.add(url);
          productIds.add(doc.id);
        }
      }
      
      if (productUrls.isEmpty) {
        print('ℹ️ Nenhuma URL válida encontrada para sincronizar');
        return;
      }
      
      print('🔄 Sincronizando ${productUrls.length} produtos...');
      
      // Sincronizar produtos
      await _aliExpressService.syncImportedProducts(productUrls);
      
      // Atualizar timestamp da última sincronização
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      print('✅ Sincronização concluída com sucesso');
      
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    }
  }
  
  /// Sincronização manual
  Future<void> manualSync() async {
    print('🔄 Iniciando sincronização manual...');
    await _performSync();
  }
  
  /// Verifica se precisa sincronizar
  Future<bool> needsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      if (lastSyncString == null) {
        return true; // Primeira sincronização
      }
      
      final lastSync = DateTime.parse(lastSyncString);
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      
      return difference >= _syncInterval;
    } catch (e) {
      print('❌ Erro ao verificar necessidade de sincronização: $e');
      return true; // Em caso de erro, sincronizar
    }
  }
  
  /// Obtém estatísticas de sincronização
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final productsRef = firestore.collection('products');
      
      // Produtos importados do AliExpress
      final importedQuery = await productsRef
          .where('importedFrom', isEqualTo: 'aliexpress')
          .get();
      
      // Produtos ativos
      final activeQuery = await productsRef
          .where('importedFrom', isEqualTo: 'aliexpress')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Produtos com preço atualizado recentemente
      final recentUpdateQuery = await productsRef
          .where('importedFrom', isEqualTo: 'aliexpress')
          .where('lastSync', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 24)),
          ))
          .get();
      
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      DateTime? lastSync;
      
      if (lastSyncString != null) {
        lastSync = DateTime.parse(lastSyncString);
      }
      
      return {
        'totalImported': importedQuery.docs.length,
        'activeProducts': activeQuery.docs.length,
        'recentlyUpdated': recentUpdateQuery.docs.length,
        'lastSync': lastSync,
        'nextSync': lastSync?.add(_syncInterval),
        'syncInterval': _syncInterval.inHours,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de sincronização: $e');
      return {
        'totalImported': 0,
        'activeProducts': 0,
        'recentlyUpdated': 0,
        'lastSync': null,
        'nextSync': null,
        'syncInterval': _syncInterval.inHours,
      };
    }
  }
  
  /// Verifica preço e estoque de um produto específico
  Future<Map<String, dynamic>> checkProductPriceAndStock(String productUrl) async {
    try {
      return await _aliExpressService.checkPriceAndStock(productUrl);
    } catch (e) {
      print('❌ Erro ao verificar preço e estoque: $e');
      return {
        'price': 0.0,
        'originalPrice': 0.0,
        'stockQuantity': 0,
        'isAvailable': false,
        'lastChecked': FieldValue.serverTimestamp(),
      };
    }
  }
  
  /// Atualiza configurações de sincronização
  Future<void> updateSyncSettings({
    Duration? syncInterval,
    bool? autoSyncEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (syncInterval != null) {
        await prefs.setInt('sync_interval_hours', syncInterval.inHours);
      }
      
      if (autoSyncEnabled != null) {
        await prefs.setBool('auto_sync_enabled', autoSyncEnabled);
      }
      
      print('✅ Configurações de sincronização atualizadas');
    } catch (e) {
      print('❌ Erro ao atualizar configurações: $e');
    }
  }
  
  /// Obtém configurações de sincronização
  Future<Map<String, dynamic>> getSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final syncIntervalHours = prefs.getInt('sync_interval_hours') ?? 6;
      final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      
      return {
        'syncInterval': Duration(hours: syncIntervalHours),
        'autoSyncEnabled': autoSyncEnabled,
      };
    } catch (e) {
      print('❌ Erro ao obter configurações: $e');
      return {
        'syncInterval': const Duration(hours: 6),
        'autoSyncEnabled': true,
      };
    }
  }
} 