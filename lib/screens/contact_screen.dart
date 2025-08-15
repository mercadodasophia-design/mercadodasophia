import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedSubject = 'Dúvida Geral';

  final List<String> _subjects = [
    'Dúvida Geral',
    'Problema com Pedido',
    'Reclamação',
    'Sugestão',
    'Parceria',
    'Outro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
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
          'Contato',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com informações
            Container(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.contact_support,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fale Conosco',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estamos aqui para ajudar você!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Informações de contato
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Cards de contato
                  _buildContactCard(
                    'Telefone',
                    '(11) 99999-9999',
                    Icons.phone,
                    Colors.green,
                    () => _callPhone(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    'WhatsApp',
                    '(11) 99999-9999',
                    Icons.chat,
                    Colors.green,
                    () => _openWhatsApp(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    'Email',
                    'contato@mercadodasophia.com',
                    Icons.email,
                    Colors.blue,
                    () => _sendEmail(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    'Endereço',
                    'Rua das Flores, 123 - Centro\nSão Paulo/SP - CEP: 01234-567',
                    Icons.location_on,
                    Colors.red,
                    () => _openMaps(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Horário de funcionamento
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Horário de Funcionamento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildScheduleItem('Segunda a Sexta', '8h às 18h'),
                          _buildScheduleItem('Sábado', '8h às 16h'),
                          _buildScheduleItem('Domingo', '9h às 14h'),
                          _buildScheduleItem('Feriados', '9h às 14h'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Formulário de contato
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Envie uma Mensagem',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Nome
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu nome';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu email';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor, insira um email válido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Telefone
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Assunto
                            DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Assunto',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.subject),
                              ),
                              items: _subjects.map((String subject) {
                                return DropdownMenuItem<String>(
                                  value: subject,
                                  child: Text(subject),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSubject = newValue!;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Mensagem
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Mensagem',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.message),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua mensagem';
                                }
                                if (value.length < 10) {
                                  return 'A mensagem deve ter pelo menos 10 caracteres';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Botão enviar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitForm,
                                icon: const Icon(Icons.send),
                                label: const Text('Enviar Mensagem'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Seção superior (cinza claro)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        const Text(
                          'Categorias',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildFooterCategory('Garrafeira'),
                            _buildFooterCategory('Compotas e Mel'),
                            _buildFooterCategory('Doces'),
                            _buildFooterCategory('Chás e Refrescos'),
                            _buildFooterCategory('Queijos e Pão'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Seção inferior (preta)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black,
                    child: Column(
                      children: [
                        const Text(
                          'Mercado da Sophia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rua das Flores, 123 - Centro',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          'São Paulo/SP - CEP: 01234-567',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          children: [
                            _buildFooterContact(Icons.phone, '(11) 99999-9999'),
                            _buildFooterContact(Icons.email, 'contato@mercadodasophia.com'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '© 2024 Mercado da Sophia. Todos os direitos reservados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String info, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String day, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _callPhone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de ligação em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _openWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade do WhatsApp em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de email em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _openMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de mapas em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Simular envio do formulário
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mensagem Enviada'),
          content: const Text(
            'Obrigado pelo contato! Retornaremos em breve.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Limpar formulário
                _nameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _messageController.clear();
                setState(() {
                  _selectedSubject = 'Dúvida Geral';
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFooterCategory(String label) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // Navegar para produtos com categoria selecionada
        Navigator.pushReplacementNamed(context, '/products');
      },
    );
  }

  Widget _buildFooterContact(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
} 