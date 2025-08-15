import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OurHistoryScreen extends StatefulWidget {
  const OurHistoryScreen({super.key});

  @override
  State<OurHistoryScreen> createState() => _OurHistoryScreenState();
}

class _OurHistoryScreenState extends State<OurHistoryScreen> {
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
          'Nossa História',
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
            // Header com timeline
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
                      Icons.history,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Uma Jornada de Crescimento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Do sonho à realidade: nossa trajetória desde 2020',
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
            
            // Timeline da história
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTimelineItem(
                    '2020',
                    'O Início',
                    'Nascimento do Mercado da Sophia',
                    'Tudo começou com uma pequena loja no centro de São Paulo. Maria Silva, nossa fundadora, tinha um sonho: conectar produtores locais aos consumidores de forma direta e transparente.',
                    Icons.store,
                    Colors.green,
                  ),
                  
                  _buildTimelineItem(
                    '2021',
                    'Primeira Expansão',
                    'Crescimento e Reconhecimento',
                    'Com o sucesso inicial, expandimos para uma loja maior e começamos a trabalhar com mais produtores locais. Nossa equipe cresceu de 3 para 15 colaboradores.',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  
                  _buildTimelineItem(
                    '2022',
                    'Inovação Digital',
                    'Nascimento do App',
                    'Lançamos nosso primeiro aplicativo móvel, revolucionando a forma como nossos clientes fazem compras. A tecnologia se tornou parte fundamental do nosso DNA.',
                    Icons.phone_android,
                    Colors.purple,
                  ),
                  
                  _buildTimelineItem(
                    '2023',
                    'Sustentabilidade',
                    'Compromisso com o Futuro',
                    'Implementamos práticas sustentáveis em todas as nossas operações. Parcerias com produtores orgânicos e redução de plástico se tornaram prioridades.',
                    Icons.eco,
                    Colors.orange,
                  ),
                  
                  _buildTimelineItem(
                    '2024',
                    'Liderança Regional',
                    'Referência em Qualidade',
                    'Hoje somos referência em produtos artesanais e orgânicos na região. Mais de 1000 clientes satisfeitos e 50 produtores parceiros fazem parte da nossa história.',
                    Icons.star,
                    Colors.red,
                  ),
                ],
              ),
            ),
            
            // Momentos Especiais
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
                          Icon(Icons.celebration, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Momentos Especiais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMomentItem('Primeiro Cliente', '15 de Março de 2020', 'Dona Maria, nossa primeira cliente, ainda compra conosco toda semana!'),
                      const SizedBox(height: 12),
                      _buildMomentItem('Primeiro Produtor Parceiro', '20 de Abril de 2020', 'João da Fazenda Orgânica foi nosso primeiro produtor parceiro.'),
                      const SizedBox(height: 12),
                      _buildMomentItem('Primeira Milha de Pedidos', '10 de Dezembro de 2021', 'Celebramos nosso 1000º pedido com toda a equipe!'),
                      const SizedBox(height: 12),
                      _buildMomentItem('Lançamento do App', '15 de Junho de 2022', 'Nosso app revolucionou a experiência de compra dos clientes.'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Valores e Princípios
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
                          Icon(Icons.favorite, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Valores que Nos Guiaram',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildValueItem('Transparência', 'Sempre honestos com nossos clientes e parceiros', Icons.visibility),
                      const SizedBox(height: 8),
                      _buildValueItem('Qualidade', 'Produtos selecionados com rigoroso controle', Icons.verified),
                      const SizedBox(height: 8),
                      _buildValueItem('Comunidade', 'Apoio aos produtores locais e desenvolvimento regional', Icons.people),
                      const SizedBox(height: 8),
                      _buildValueItem('Inovação', 'Sempre buscando melhorar a experiência do cliente', Icons.lightbulb_outline),
                      const SizedBox(height: 8),
                      _buildValueItem('Sustentabilidade', 'Compromisso com o meio ambiente e futuro', Icons.eco),
                    ],
                  ),
                ),
              ),
            ),
            
            // Próximos Passos
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
                          Icon(Icons.rocket_launch, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Próximos Passos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nossa história não para aqui! Temos grandes planos para o futuro:',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFutureItem('Expansão Regional', 'Abrir novas lojas em outras cidades', Icons.location_city),
                      const SizedBox(height: 8),
                      _buildFutureItem('App Aprimorado', 'Novas funcionalidades e melhor experiência', Icons.phone_android),
                      const SizedBox(height: 8),
                      _buildFutureItem('Mais Produtores', 'Parcerias com novos produtores locais', Icons.handshake),
                      const SizedBox(height: 8),
                      _buildFutureItem('Sustentabilidade Total', '100% de operações sustentáveis', Icons.eco),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botão de Contato
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _contactUs,
                  icon: const Icon(Icons.message),
                  label: const Text('Fazer Parte da Nossa História'),
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

  Widget _buildTimelineItem(String year, String title, String subtitle, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentItem(String title, String date, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFutureItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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