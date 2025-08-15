import 'package:http/http.dart' as http;
import 'dart:convert';

class Category {
  final String id;
  final String name;
  final String? parentId;
  final String? level;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.level,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'] ?? json['id'] ?? '',
      name: json['category_name'] ?? json['name'] ?? '',
      parentId: json['parent_category_id'],
      level: json['level'],
    );
  }
}

class CategoryService {
  static const String baseUrl = 'https://service-api-aliexpress.mercadodasophia.com.br';

  // Categorias padrão caso a API não funcione
  static final List<Category> defaultCategories = [
    Category(id: '509', name: 'Smartphones'),
    Category(id: '14', name: 'Computadores'),
    Category(id: '15', name: 'Roupas'),
    Category(id: '16', name: 'Casa & Jardim'),
    Category(id: '17', name: 'Automóveis'),
    Category(id: '18', name: 'Esportes'),
    Category(id: '19', name: 'Brinquedos'),
    Category(id: '20', name: 'Beleza'),
    Category(id: '21', name: 'Livros'),
    Category(id: '22', name: 'Ferramentas'),
  ];

  static Future<List<Category>> getCategories() async {
    // Usar apenas categorias padrão por enquanto
    return defaultCategories;
  }

  // Buscar produtos por categoria usando busca por texto
  static Future<List<dynamic>> getProductsByCategory(String categoryId, String categoryName) async {
    try {
      // Usar a busca por texto com o nome da categoria como termo
      final response = await http.get(
        Uri.parse('$baseUrl/api/aliexpress/products?q=${Uri.encodeComponent(categoryName)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final productsData = data['data']['aliexpress_ds_text_search_response']['data']['products']['selection_search_product'];
          return productsData;
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Erro ao buscar produtos da categoria: $e');
      return [];
    }
  }
} 