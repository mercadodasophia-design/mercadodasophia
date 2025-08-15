import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
          'Política de Privacidade',
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
                      Icons.privacy_tip,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sua Privacidade é Importante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Última atualização: 15 de Dezembro de 2024',
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
            
            // Seções da política
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    '1. Informações que Coletamos',
                    Icons.collections,
                    [
                      'Informações pessoais (nome, email, telefone)',
                      'Endereço de entrega',
                      'Histórico de pedidos',
                      'Preferências de produtos',
                      'Dados de navegação no app',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '2. Como Usamos Suas Informações',
                    Icons.how_to_reg,
                    [
                      'Processar e entregar seus pedidos',
                      'Comunicar sobre status de pedidos',
                      'Enviar ofertas e promoções',
                      'Melhorar nossos serviços',
                      'Personalizar sua experiência',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '3. Compartilhamento de Dados',
                    Icons.share,
                    [
                      'Não vendemos suas informações pessoais',
                      'Compartilhamos apenas com produtores parceiros',
                      'Dados podem ser compartilhados por obrigação legal',
                      'Sempre com seu consentimento explícito',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '4. Segurança dos Dados',
                    Icons.security,
                    [
                      'Criptografia de ponta a ponta',
                      'Acesso restrito aos dados',
                      'Monitoramento contínuo de segurança',
                      'Backup regular das informações',
                      'Conformidade com LGPD',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '5. Seus Direitos',
                    Icons.gavel,
                    [
                      'Acessar seus dados pessoais',
                      'Corrigir informações incorretas',
                      'Solicitar exclusão de dados',
                      'Revogar consentimento a qualquer momento',
                      'Portabilidade dos dados',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '6. Cookies e Tecnologias',
                    Icons.cookie,
                    [
                      'Usamos cookies para melhorar a experiência',
                      'Cookies de análise e performance',
                      'Você pode desativar cookies nas configurações',
                      'Tecnologias de rastreamento limitadas',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '7. Retenção de Dados',
                    Icons.schedule,
                    [
                      'Mantemos dados enquanto necessário',
                      'Exclusão automática após inatividade',
                      'Dados de pedidos por 5 anos',
                      'Informações de conta até cancelamento',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '8. Menores de Idade',
                    Icons.child_care,
                    [
                      'Não coletamos dados de menores de 13 anos',
                      'Pais devem consentir para menores de 18 anos',
                      'Supervisão parental recomendada',
                      'Exclusão imediata se detectado menor',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '9. Alterações na Política',
                    Icons.update,
                    [
                      'Podemos atualizar esta política',
                      'Notificaremos sobre mudanças importantes',
                      'Continuar usando o serviço = aceitar mudanças',
                      'Versão atual sempre disponível no app',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '10. Contato',
                    Icons.contact_support,
                    [
                      'Dúvidas sobre privacidade? Entre em contato:',
                      'Email: privacidade@mercadodasophia.com',
                      'Telefone: (11) 99999-9999',
                      'Endereço: Rua das Flores, 123 - Centro, São Paulo/SP',
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão de aceitar política
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _acceptPolicy,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Aceitar Política de Privacidade'),
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
                  
                  const SizedBox(height: 12),
                  
                  // Botão de dúvidas
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _contactUs,
                      icon: const Icon(Icons.help),
                      label: const Text('Tirar Dúvidas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
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

  Widget _buildSection(String title, IconData icon, List<String> items) {
    return Card(
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
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _acceptPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política Aceita'),
        content: const Text(
          'Obrigado por aceitar nossa política de privacidade! Suas informações estão seguras conosco.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de contato em desenvolvimento'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
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