// Flutter CSS Injector
// Script para aplicar classes CSS aos elementos Flutter automaticamente

class FlutterCSSInjector {
  constructor() {
    this.observer = null;
    this.init();
  }

  init() {
    // Aguardar o Flutter carregar
    this.waitForFlutter();
  }

  waitForFlutter() {
    const checkFlutter = () => {
      const flutterTarget = document.getElementById('flutter_target');
      if (flutterTarget && flutterTarget.children.length > 0) {
        this.startObserving();
        this.injectClasses();
      } else {
        setTimeout(checkFlutter, 100);
      }
    };
    checkFlutter();
  }

  startObserving() {
    // Observer para detectar mudanças no DOM
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList') {
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              this.processElement(node);
            }
          });
        }
      });
    });

    const flutterTarget = document.getElementById('flutter_target');
    if (flutterTarget) {
      this.observer.observe(flutterTarget, {
        childList: true,
        subtree: true
      });
    }
  }

  injectClasses() {
    const flutterTarget = document.getElementById('flutter_target');
    if (flutterTarget) {
      this.processElement(flutterTarget);
    }
  }

  processElement(element) {
    // Processar o elemento atual
    this.applyClassesToElement(element);

    // Processar filhos
    const children = element.children;
    for (let i = 0; i < children.length; i++) {
      this.processElement(children[i]);
    }
  }

  applyClassesToElement(element) {
    const tagName = element.tagName.toLowerCase();
    const className = element.className || '';
    const role = element.getAttribute('role') || '';

    // AppBar
    if (tagName === 'header' || className.includes('app-bar') || role === 'banner') {
      element.classList.add('app-bar');
    }

    // Scaffold Body
    if (tagName === 'main' || className.includes('scaffold-body')) {
      element.classList.add('scaffold-body');
    }

    // Wrap (Grid de produtos)
    if (className.includes('wrap') || this.isProductGrid(element)) {
      element.classList.add('wrap');
    }

    // Cards de produto
    if (this.isProductCard(element)) {
      element.classList.add('card');
      this.processProductCard(element);
    }

    // Imagens de produto
    if (tagName === 'img' && this.isProductImage(element)) {
      element.classList.add('product-image');
    }

    // Container de informações do produto
    if (this.isProductInfo(element)) {
      element.classList.add('product-info');
    }

    // Título do produto
    if (this.isProductTitle(element)) {
      element.classList.add('product-title');
    }

    // Preço do produto
    if (this.isProductPrice(element)) {
      element.classList.add('product-price');
    }

    // Rating do produto
    if (this.isProductRating(element)) {
      element.classList.add('product-rating');
    }

    // Status do produto
    if (this.isProductStatus(element)) {
      element.classList.add('product-status');
    }

    // Logo
    if (this.isLogo(element)) {
      element.classList.add('logo');
    }

    // Botão do menu
    if (this.isMenuButton(element)) {
      element.classList.add('menu-button');
    }

    // Container de filtros
    if (this.isFilterContainer(element)) {
      element.classList.add('filter-container');
    }

    // Chips de filtro
    if (this.isFilterChip(element)) {
      element.classList.add('filter-chip');
    }

    // Footer
    if (tagName === 'footer' || className.includes('footer')) {
      element.classList.add('footer');
    }

    // Footer categories
    if (this.isFooterCategories(element)) {
      element.classList.add('footer-categories');
    }

    // Footer contact
    if (this.isFooterContact(element)) {
      element.classList.add('footer-contact');
    }
  }

  processProductCard(cardElement) {
    // Adicionar animação de fade-in
    cardElement.classList.add('fade-in');
  }

  // Métodos de detecção
  isProductGrid(element) {
    return element.children.length > 0 && 
           Array.from(element.children).some(child => this.isProductCard(child));
  }

  isProductCard(element) {
    const className = element.className || '';
    const style = window.getComputedStyle(element);
    
    return className.includes('card') || 
           className.includes('product') ||
           style.borderRadius !== '0px' ||
           style.boxShadow !== 'none';
  }

  isProductImage(element) {
    const parent = element.parentElement;
    return parent && this.isProductCard(parent);
  }

  isProductInfo(element) {
    const parent = element.parentElement;
    return parent && this.isProductCard(parent) && 
           element.children.length > 0;
  }

  isProductTitle(element) {
    const text = element.textContent || '';
    return text.length > 10 && text.length < 100 && 
           !text.includes('R$') && 
           !text.includes('★') &&
           !text.includes('Disponível') &&
           !text.includes('Fora de estoque');
  }

  isProductPrice(element) {
    const text = element.textContent || '';
    return text.includes('R$') && text.length < 20;
  }

  isProductRating(element) {
    const text = element.textContent || '';
    return text.includes('★') || text.includes('N/A') || text.includes('vendidos');
  }

  isProductStatus(element) {
    const text = element.textContent || '';
    return text.includes('Disponível') || text.includes('Fora de estoque') || text.includes('Novo');
  }

  isLogo(element) {
    const tagName = element.tagName.toLowerCase();
    const src = element.src || '';
    return tagName === 'img' && (src.includes('logo') || src.includes('name-logo'));
  }

  isMenuButton(element) {
    const tagName = element.tagName.toLowerCase();
    const className = element.className || '';
    return tagName === 'button' && (className.includes('menu') || className.includes('hamburger'));
  }

  isFilterContainer(element) {
    const children = element.children;
    return children.length > 0 && 
           Array.from(children).some(child => this.isFilterChip(child));
  }

  isFilterChip(element) {
    const tagName = element.tagName.toLowerCase();
    const className = element.className || '';
    return tagName === 'button' && (className.includes('chip') || className.includes('filter'));
  }

  isFooterCategories(element) {
    const text = element.textContent || '';
    return text.includes('Categorias') && element.children.length > 0;
  }

  isFooterContact(element) {
    const text = element.textContent || '';
    return text.includes('Mercado da Sophia') || text.includes('contato@');
  }

  // Método para forçar reaplicação
  forceReapply() {
    this.injectClasses();
  }

  // Método para parar o observer
  destroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }
}

// Inicializar quando o DOM estiver pronto
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.flutterCSSInjector = new FlutterCSSInjector();
  });
} else {
  window.flutterCSSInjector = new FlutterCSSInjector();
}

// Expor para uso global
window.FlutterCSSInjector = FlutterCSSInjector;
