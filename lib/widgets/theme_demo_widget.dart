import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeDemoWidget extends StatelessWidget {
  const ThemeDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demonstração do Tema'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Textos
            Text(
              'Tipografia',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Display Large - Título Principal',
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Headline Medium - Subtítulo',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Body Large - Texto do corpo principal',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Body Small - Texto secundário',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // Seção de Botões
            Text(
              'Botões',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seção de Chips
            Text(
              'Chips',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: true,
                  onSelected: (value) {},
                ),
                FilterChip(
                  label: const Text('Laticínios'),
                  selected: false,
                  onSelected: (value) {},
                ),
                FilterChip(
                  label: const Text('Bebidas'),
                  selected: false,
                  onSelected: (value) {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seção de Cards
            Text(
              'Cards',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card de Exemplo',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este é um exemplo de card usando o tema personalizado do Mercado da Sophia.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seção de Inputs
            Text(
              'Campos de Entrada',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome do Produto',
                hintText: 'Digite o nome do produto',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Preço',
                hintText: 'R\$ 0,00',
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 24),

            // Seção de Cores
            Text(
              'Paleta de Cores',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorBox('Primária', AppTheme.primaryColor),
                _buildColorBox('Secundária', AppTheme.secondaryColor),
                _buildColorBox('Acento', AppTheme.accentColor),
                _buildColorBox('Sucesso', AppTheme.successColor),
                _buildColorBox('Aviso', AppTheme.warningColor),
                _buildColorBox('Erro', AppTheme.errorColor),
              ],
            ),
            const SizedBox(height: 24),

            // Seção de Gradientes
            Text(
              'Gradientes',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Center(
                child: Text(
                  'Gradiente Primário',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Center(
                child: Text(
                  'Gradiente Secundário',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seção de Ícones
            Text(
              'Ícones',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Icon(Icons.favorite, color: AppTheme.secondaryColor),
                const SizedBox(width: 16),
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 16),
                Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: 16),
                Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 16),
                Icon(Icons.error, color: AppTheme.errorColor),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tema aplicado com sucesso!'),
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildColorBox(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 