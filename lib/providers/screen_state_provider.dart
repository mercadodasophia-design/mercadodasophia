import 'package:flutter/material.dart';

class ScreenStateProvider extends ChangeNotifier {
  // Estado da tela de produtos
  double _productsScrollPosition = 0.0;
  bool _productsLoaded = false;
  List<dynamic> _productsData = [];
  
  // Estado da tela SexyShop
  double _sexyshopScrollPosition = 0.0;
  bool _sexyshopLoaded = false;
  List<dynamic> _sexyshopData = [];
  
  // Getters
  double get productsScrollPosition => _productsScrollPosition;
  bool get productsLoaded => _productsLoaded;
  List<dynamic> get productsData => _productsData;
  
  double get sexyshopScrollPosition => _sexyshopScrollPosition;
  bool get sexyshopLoaded => _sexyshopLoaded;
  List<dynamic> get sexyshopData => _sexyshopData;
  
  // Setters
  void setProductsScrollPosition(double position) {
    _productsScrollPosition = position;
    notifyListeners();
  }
  
  void setProductsLoaded(bool loaded) {
    _productsLoaded = loaded;
    notifyListeners();
  }
  
  void setProductsData(List<dynamic> data) {
    _productsData = data;
    notifyListeners();
  }
  
  void setSexyshopScrollPosition(double position) {
    _sexyshopScrollPosition = position;
    notifyListeners();
  }
  
  void setSexyshopLoaded(bool loaded) {
    _sexyshopLoaded = loaded;
    notifyListeners();
  }
  
  void setSexyshopData(List<dynamic> data) {
    _sexyshopData = data;
    notifyListeners();
  }
  
  // Limpar estado
  void clearState() {
    _productsScrollPosition = 0.0;
    _productsLoaded = false;
    _productsData = [];
    _sexyshopScrollPosition = 0.0;
    _sexyshopLoaded = false;
    _sexyshopData = [];
    notifyListeners();
  }
}
