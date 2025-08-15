import 'package:flutter/material.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class AdminSyncSettingsScreen extends StatefulWidget {
  const AdminSyncSettingsScreen({super.key});

  @override
  State<AdminSyncSettingsScreen> createState() => _AdminSyncSettingsScreenState();
}

class _AdminSyncSettingsScreenState extends State<AdminSyncSettingsScreen> {
  final SyncService _syncService = SyncService();
  
  bool _autoSyncEnabled = true;
  int _syncIntervalHours = 6;
  bool _isLoading = false;
  Map<String, dynamic> _syncStats = {};
  Map<String, dynamic> _syncSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _syncService.getSyncSettings();
      setState(() {
        _syncSettings = settings;
        _autoSyncEnabled = settings['autoSyncEnabled'] ?? true;
        _syncIntervalHours = settings['syncInterval'].inHours;
      });
    } catch (e) {
      print('❌ Erro ao carregar configurações: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _syncService.getSyncStats();
      setState(() {
        _syncStats = stats;
      });
    } catch (e) {
      print('❌ Erro ao carregar estatísticas: $e');
    }
  }

  Future<void> _updateSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.updateSyncSettings(
        syncInterval: Duration(hours: _syncIntervalHours),
        autoSyncEnabled: _autoSyncEnabled,
      );

      if (_autoSyncEnabled) {
        await _syncService.startAutoSync();
      } else {
        _syncService.stopAutoSync();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações atualizadas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar configurações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.manualSync();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização manual concluída!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na sincronização: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Configurações de Sincronização',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estatísticas de sincronização
            _buildSyncStatsCard(),
            
            const SizedBox(height: 24),
            
            // Configurações de sincronização
            _buildSyncSettingsCard(),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Estatísticas de Sincronização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Importado',
                    _syncStats['totalImported']?.toString() ?? '0',
                    Icons.download,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Produtos Ativos',
                    _syncStats['activeProducts']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Atualizados Hoje',
                    _syncStats['recentlyUpdated']?.toString() ?? '0',
                    Icons.update,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_syncStats['lastSync'] != null) ...[
              _buildInfoRow(
                'Última Sincronização',
                _formatDateTime(_syncStats['lastSync']),
              ),
              _buildInfoRow(
                'Próxima Sincronização',
                _formatDateTime(_syncStats['nextSync']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Sincronização automática
            SwitchListTile(
              title: const Text('Sincronização Automática'),
              subtitle: const Text('Atualizar preços e estoque automaticamente'),
              value: _autoSyncEnabled,
              onChanged: (value) {
                setState(() {
                  _autoSyncEnabled = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // Intervalo de sincronização
            const Text(
              'Intervalo de Sincronização',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _syncIntervalHours,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text('1 hora')),
                DropdownMenuItem(value: 3, child: Text('3 horas')),
                DropdownMenuItem(value: 6, child: Text('6 horas')),
                DropdownMenuItem(value: 12, child: Text('12 horas')),
                DropdownMenuItem(value: 24, child: Text('24 horas')),
              ],
              onChanged: (value) {
                setState(() {
                  _syncIntervalHours = value ?? 6;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _updateSettings,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Salvando...' : 'Salvar Configurações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _manualSync,
            icon: const Icon(Icons.sync),
            label: const Text('Sincronização Manual'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      final dt = dateTime is DateTime ? dateTime : DateTime.parse(dateTime.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
} 