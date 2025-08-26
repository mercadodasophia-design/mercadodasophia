import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class FreightService {
  static const String _baseUrl = 'https://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx/CalcPrecoPrazo';
  
  // Códigos dos serviços dos Correios
  static const String _sedexCode = '04014';
  static const String _pacCode = '04510';
  
  // CEP de origem da loja (São Paulo - Centro)
  static const String _originCep = '01001000';
  
  // Frete padrão quando não há dados suficientes
  static const double _defaultFreight = 20.0;
  
  /// Calcula o frete usando a API dos Correios
  /// Retorna o valor do frete ou o valor padrão se não conseguir calcular
  static Future<double> calculateFreight({
    required String destinationCep,
    required double weight,
    required double length,
    required double height,
    required double width,
    double? diameter,
    String? formato,
  }) async {
    try {
      // Validar se temos todos os dados necessários
      if (weight <= 0 || length <= 0 || height <= 0 || width <= 0) {
        print('⚠️ Dados insuficientes para cálculo de frete. Usando valor padrão.');
        return _defaultFreight;
      }
      
      // Limpar CEP (remover hífen e espaços)
      final cleanCep = destinationCep.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanCep.length != 8) {
        print('⚠️ CEP inválido: $destinationCep. Usando valor padrão.');
        return _defaultFreight;
      }
      
      // Preparar parâmetros para a API
      final params = {
        'nCdEmpresa': '',
        'sDsSenha': '',
        'nCdServico': _pacCode, // Usar PAC por padrão (mais barato)
        'sCepOrigem': _originCep,
        'sCepDestino': cleanCep,
        'nVlPeso': weight.toString(),
        'nCdFormato': '1', // 1 = caixa/pacote
        'nVlComprimento': length.toString(),
        'nVlAltura': height.toString(),
        'nVlLargura': width.toString(),
        'nVlDiametro': (diameter ?? 0).toString(),
        'sCdMaoPropria': 'N',
        'nVlValorDeclarado': '0',
        'sCdAvisoRecebimento': 'N',
      };
      
      // Construir URL com parâmetros
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      
      print('🚚 Calculando frete para CEP: $cleanCep');
      print('📦 Dimensões: ${length}x${height}x${width}cm, Peso: ${weight}kg');
      
      // Fazer requisição para a API dos Correios
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        // Parsear resposta XML
        final xmlDoc = XmlDocument.parse(response.body);
        final servicos = xmlDoc.findAllElements('cServico');
        
        if (servicos.isNotEmpty) {
          final servico = servicos.first;
          final valorElement = servico.findElements('Valor').firstOrNull;
          final erroElement = servico.findElements('Erro').firstOrNull;
          
          if (erroElement != null && erroElement.text.isNotEmpty) {
            print('❌ Erro no cálculo de frete: ${erroElement.text}');
            return _defaultFreight;
          }
          
          if (valorElement != null) {
            // Converter valor de string para double
            final valorStr = valorElement.text.replaceAll(',', '.');
            final valor = double.tryParse(valorStr);
            
            if (valor != null && valor > 0) {
              print('✅ Frete calculado: R\$ ${valor.toStringAsFixed(2)}');
              return valor;
            }
          }
        }
      }
      
      print('⚠️ Não foi possível calcular o frete. Usando valor padrão.');
      return _defaultFreight;
      
    } catch (e) {
      print('❌ Erro ao calcular frete: $e');
      return _defaultFreight;
    }
  }
  
  /// Calcula frete para múltiplos produtos
  static Future<double> calculateMultipleProductsFreight({
    required String destinationCep,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      double totalWeight = 0;
      double maxLength = 0;
      double maxHeight = 0;
      double maxWidth = 0;
      double maxDiameter = 0;
      
      // Somar pesos e pegar as maiores dimensões
      for (final product in products) {
        final weight = product['weight'] ?? 0.0;
        final length = product['length'] ?? 0.0;
        final height = product['height'] ?? 0.0;
        final width = product['width'] ?? 0.0;
        final diameter = product['diameter'] ?? 0.0;
        
        totalWeight += weight;
        maxLength = maxLength < length ? length : maxLength;
        maxHeight = maxHeight < height ? height : maxHeight;
        maxWidth = maxWidth < width ? width : maxWidth;
        maxDiameter = maxDiameter < diameter ? diameter : maxDiameter;
      }
      
      // Se não há dados suficientes, usar frete padrão
      if (totalWeight <= 0 || maxLength <= 0 || maxHeight <= 0 || maxWidth <= 0) {
        print('⚠️ Dados insuficientes para cálculo de frete múltiplo. Usando valor padrão.');
        return _defaultFreight;
      }
      
      return await calculateFreight(
        destinationCep: destinationCep,
        weight: totalWeight,
        length: maxLength,
        height: maxHeight,
        width: maxWidth,
        diameter: maxDiameter,
      );
      
    } catch (e) {
      print('❌ Erro ao calcular frete múltiplo: $e');
      return _defaultFreight;
    }
  }
  
  /// Verifica se um produto tem dados suficientes para cálculo de frete
  static bool hasFreightData(Map<String, dynamic> product) {
    final weight = product['weight'] ?? 0.0;
    final length = product['length'] ?? 0.0;
    final height = product['height'] ?? 0.0;
    final width = product['width'] ?? 0.0;
    
    return weight > 0 && length > 0 && height > 0 && width > 0;
  }
  
  /// Retorna o prazo estimado de entrega (fixo da loja)
  static String getEstimatedDeliveryTime() {
    return '12 a 28 dias úteis';
  }
  
  /// Retorna o prazo estimado em dias
  static int getEstimatedDeliveryDays() {
    return 20; // Média entre 12 e 28 dias
  }
}
