import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
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
          'Quem Somos',
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
            // Header com logo
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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mercado da Sophia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Desde 2020, conectando você aos melhores produtos',
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
            
            // Nossa História
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
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
                          Icon(Icons.history, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Nossa História',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'O Mercado da Sophia nasceu em 2020 com a missão de conectar produtores locais aos consumidores, oferecendo produtos frescos e de qualidade. Nossa história começou com uma pequena loja no centro de São Paulo e hoje somos referência em produtos artesanais e orgânicos.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Acreditamos que cada produto tem uma história para contar, e queremos compartilhar essas histórias com você através de uma experiência de compra única e personalizada.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Nossos Valores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
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
                          Icon(Icons.favorite, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Nossos Valores',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildValueItem('Qualidade', 'Produtos selecionados com rigoroso controle de qualidade', Icons.verified),
                      const SizedBox(height: 12),
                      _buildValueItem('Sustentabilidade', 'Compromisso com o meio ambiente e práticas sustentáveis', Icons.eco),
                      const SizedBox(height: 12),
                      _buildValueItem('Comunidade', 'Apoio aos produtores locais e desenvolvimento da comunidade', Icons.people),
                      const SizedBox(height: 12),
                      _buildValueItem('Inovação', 'Tecnologia para melhorar sua experiência de compra', Icons.lightbulb_outline),
                    ],
                  ),
                ),
              ),
            ),
            
            // Nossos Números
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
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
                            'Nossos Números',
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
                          Expanded(child: _buildStatItem('+1000', 'Clientes Satisfeitos', Icons.people)),
                          Expanded(child: _buildStatItem('+500', 'Produtos Únicos', Icons.inventory)),
                          Expanded(child: _buildStatItem('+50', 'Produtores Parceiros', Icons.handshake)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatItem('4.8', 'Avaliação Média', Icons.star)),
                          Expanded(child: _buildStatItem('24/7', 'Suporte ao Cliente', Icons.support_agent)),
                          Expanded(child: _buildStatItem('100%', 'Satisfação Garantida', Icons.check_circle)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Nossa Equipe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
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
                          Icon(Icons.group, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Nossa Equipe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nossa equipe é formada por profissionais apaixonados por qualidade e inovação. Trabalhamos juntos para oferecer a melhor experiência possível aos nossos clientes.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTeamMember('Maria Silva', 'CEO & Fundadora', Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTeamMember('João Santos', 'Diretor de Operações', Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTeamMember('Ana Costa', 'Gerente de Qualidade', Icons.person)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contato
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
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
                          Icon(Icons.contact_phone, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Entre em Contato',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(Icons.location_on, 'Rua das Flores, 123 - Centro, São Paulo/SP'),
                      const SizedBox(height: 8),
                      _buildContactItem(Icons.phone, '(11) 99999-9999'),
                      const SizedBox(height: 8),
                      _buildContactItem(Icons.email, 'contato@mercadodasophia.com'),
                      const SizedBox(height: 8),
                      _buildContactItem(Icons.access_time, 'Segunda a Sexta: 8h às 18h'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _contactUs,
                          icon: const Icon(Icons.message),
                          label: const Text('Enviar Mensagem'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildValueItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
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
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String role, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          role,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
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