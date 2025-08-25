import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfUseScreen extends StatefulWidget {
  const TermsOfUseScreen({super.key});

  @override
  State<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

class _TermsOfUseScreenState extends State<TermsOfUseScreen> {
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
          'Termos de Uso',
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
                      Icons.description,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Termos e Condições de Uso',
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
            
            // Seções dos termos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    '1. Aceitação dos Termos',
                    Icons.check_circle,
                    [
                      'Ao usar o Mercado da Sophia, você concorda com estes termos',
                      'Leia atentamente antes de fazer pedidos',
                      'Uso do app indica aceitação completa',
                      'Termos aplicáveis a todos os usuários',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '2. Cadastro e Conta',
                    Icons.person_add,
                    [
                      'Cadastro obrigatório para compras',
                      'Informações verdadeiras e atualizadas',
                      'Responsabilidade pela segurança da senha',
                      'Uma conta por pessoa física',
                      'Proibido compartilhar credenciais',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '3. Produtos e Serviços',
                    Icons.shopping_basket,
                    [
                      'Produtos de produtores parceiros',
                      'Qualidade garantida pelos fornecedores',
                      'Fotos ilustrativas dos produtos',
                      'Preços podem sofrer alterações',
                      'Estoque limitado e sujeito a disponibilidade',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '4. Pedidos e Pagamento',
                    Icons.payment,
                    [
                      'Pedidos confirmados após pagamento',
                      'Aceitamos cartões e PIX',
                      'Preços em Reais (R\$)',
                      'Impostos incluídos nos preços',
                      'Comprovante enviado por email',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '5. Entrega e Frete',
                    Icons.local_shipping,
                    [
                      'Entrega em até 48 horas',
                      'Frete grátis acima de R\$ 100',
                      'Horários de entrega: 8h às 18h',
                      'Endereço de entrega responsabilidade do cliente',
                      'Recebimento obrigatório com documento',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '6. Cancelamento e Devolução',
                    Icons.undo,
                    [
                      'Cancelamento até 2h após pedido',
                      'Devolução em até 7 dias',
                      'Produto deve estar em perfeito estado',
                      'Reembolso em até 5 dias úteis',
                      'Custos de frete de devolução do cliente',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '7. Responsabilidades',
                    Icons.gavel,
                    [
                      'Mercado da Sophia: entrega e qualidade',
                      'Cliente: informações corretas e pagamento',
                      'Produtores: qualidade e descrição dos produtos',
                      'Limitação de responsabilidade por danos indiretos',
                      'Foro da comarca de São Paulo/SP',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '8. Uso Adequado',
                    Icons.verified_user,
                    [
                      'Uso apenas para compras legítimas',
                      'Proibido uso comercial não autorizado',
                      'Não compartilhar dados de outros usuários',
                      'Respeitar direitos autorais',
                      'Não tentar burlar sistemas de segurança',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '9. Propriedade Intelectual',
                    Icons.copyright,
                    [
                      'Conteúdo do app protegido por direitos autorais',
                      'Marca Mercado da Sophia registrada',
                      'Proibida reprodução sem autorização',
                      'Logos e designs são propriedade da empresa',
                      'Uso apenas para compras autorizadas',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '10. Modificações',
                    Icons.edit,
                    [
                      'Termos podem ser alterados a qualquer momento',
                      'Notificação de mudanças importantes',
                      'Continuar usando = aceitar novos termos',
                      'Versão atual sempre disponível no app',
                      'Data de vigência sempre atualizada',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '11. Rescisão',
                    Icons.block,
                    [
                      'Conta pode ser suspensa por violação',
                      'Pedidos em andamento serão processados',
                      'Reembolso de valores pagos',
                      'Dados mantidos conforme legislação',
                      'Direito de defesa antes da suspensão',
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSection(
                    '12. Disposições Gerais',
                    Icons.library_books,
                    [
                      'Lei brasileira aplicável',
                      'Cláusulas independentes',
                      'Acordo completo entre as partes',
                      'Comunicação oficial por email',
                      'Foro competente: São Paulo/SP',
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão de aceitar termos
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _acceptTerms,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Aceitar Termos de Uso'),
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
                          'República, São Paulo - SP, 01037-010',
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
                            _buildFooterContact(Icons.phone, '(85) 99764-0050'),
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

  void _acceptTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos Aceitos'),
        content: const Text(
          'Obrigado por aceitar nossos termos de uso! Agora você pode aproveitar todos os serviços do Mercado da Sophia.',
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