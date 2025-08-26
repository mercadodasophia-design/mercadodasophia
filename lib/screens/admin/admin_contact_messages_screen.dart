import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminContactMessagesScreen extends StatefulWidget {
  const AdminContactMessagesScreen({super.key});

  @override
  State<AdminContactMessagesScreen> createState() => _AdminContactMessagesScreenState();
}

class _AdminContactMessagesScreenState extends State<AdminContactMessagesScreen> {
  List<DocumentSnapshot> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('contact_messages')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _messages = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar mensagens: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMessageStatus(String messageId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('contact_messages')
          .doc(messageId)
          .update({'status': newStatus});
      
      // Recarregar mensagens
      await _loadMessages();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status atualizado para: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('contact_messages')
            .doc(messageId)
            .delete();
        
        await _loadMessages();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensagem excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir mensagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageDetails(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mensagem de ${data['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nome', data['name'] ?? ''),
              _buildDetailRow('Email', data['email'] ?? ''),
              if (data['phone']?.isNotEmpty == true)
                _buildDetailRow('Telefone', data['phone'] ?? ''),
              _buildDetailRow('Assunto', data['subject'] ?? ''),
              const SizedBox(height: 16),
              const Text(
                'Mensagem:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(data['message'] ?? ''),
              const SizedBox(height: 16),
              _buildDetailRow('Status', data['status'] ?? 'new'),
              if (data['createdAt'] != null)
                _buildDetailRow(
                  'Data',
                  data['createdAt'] is Timestamp
                      ? _formatDate(data['createdAt'] as Timestamp)
                      : data['createdAt'].toString(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.orange;
      case 'read':
        return Colors.blue;
      case 'replied':
        return Colors.green;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'Nova';
      case 'read':
        return 'Lida';
      case 'replied':
        return 'Respondida';
      case 'archived':
        return 'Arquivada';
      default:
        return status;
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
          'Mensagens de Contato',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMessages,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma mensagem encontrada',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final data = message.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'new';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['name'] ?? 'Sem nome',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Assunto: ${data['subject'] ?? 'Sem assunto'}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${data['email'] ?? 'Sem email'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (data['phone']?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Telefone: ${data['phone']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    data['message'] ?? 'Sem mensagem',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  if (data['createdAt'] != null)
                                    Text(
                                      data['createdAt'] is Timestamp
                                          ? _formatDate(data['createdAt'] as Timestamp)
                                          : data['createdAt'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showMessageDetails(message);
                                      break;
                                    case 'mark_read':
                                      _updateMessageStatus(message.id, 'read');
                                      break;
                                    case 'mark_replied':
                                      _updateMessageStatus(message.id, 'replied');
                                      break;
                                    case 'archive':
                                      _updateMessageStatus(message.id, 'archived');
                                      break;
                                    case 'delete':
                                      _deleteMessage(message.id);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('Ver Detalhes'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'mark_read',
                                    child: Row(
                                      children: [
                                        Icon(Icons.mark_email_read),
                                        SizedBox(width: 8),
                                        Text('Marcar como Lida'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'mark_replied',
                                    child: Row(
                                      children: [
                                        Icon(Icons.reply),
                                        SizedBox(width: 8),
                                        Text('Marcar como Respondida'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'archive',
                                    child: Row(
                                      children: [
                                        Icon(Icons.archive),
                                        SizedBox(width: 8),
                                        Text('Arquivar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showMessageDetails(message),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
