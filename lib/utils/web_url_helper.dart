import 'dart:html' as html;

class WebUrlHelper {
  // Atualizar URL no navegador sem recarregar a página
  static void updateUrl(String path) {
    try {
      // Para web, usar window.history.pushState
      html.window.history.pushState(null, '', path);
    } catch (e) {
      // Fallback para outras plataformas
      print('Erro ao atualizar URL: $e');
    }
  }

  // Atualizar título da página
  static void updateTitle(String title) {
    try {
      html.document.title = title;
    } catch (e) {
      print('Erro ao atualizar título: $e');
    }
  }

  // Obter URL atual
  static String getCurrentUrl() {
    try {
      return html.window.location.pathname ?? '/';
    } catch (e) {
      return '/';
    }
  }

  // Navegar para URL amigável
  static void navigateToFriendlyUrl(String path, {String? title}) {
    try {
      // Forçar URLs limpas - remover qualquer hash
      final cleanPath = path.startsWith('/') ? path : '/$path';
      
      // Usar replaceState para não adicionar ao histórico
      html.window.history.replaceState(null, '', cleanPath);
      
      if (title != null) {
        updateTitle(title);
      }
      
      // Forçar atualização da página se necessário
      if (html.window.location.pathname != cleanPath) {
        html.window.location.pathname = cleanPath;
      }
    } catch (e) {
      print('Erro ao navegar para URL amigável: $e');
    }
  }
}
