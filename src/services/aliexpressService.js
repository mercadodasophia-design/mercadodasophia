const puppeteer = require('puppeteer');
const axios = require('axios');
const cheerio = require('cheerio');

class AliExpressService {
  constructor() {
    this.browser = null;
    this.baseUrl = 'https://www.aliexpress.com';
  }

  async initBrowser() {
    if (!this.browser) {
      this.browser = await puppeteer.launch({
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--no-first-run',
          '--no-zygote',
          '--disable-gpu'
        ]
      });
    }
    return this.browser;
  }

  async closeBrowser() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  async searchProducts(query, limit = 20) {
    try {
      const browser = await this.initBrowser();
      const page = await browser.newPage();
      
      // Configurar user agent
      await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
      
      // Navegar para a página de busca
      const searchUrl = `${this.baseUrl}/wholesale?SearchText=${encodeURIComponent(query)}`;
      await page.goto(searchUrl, { waitUntil: 'networkidle2', timeout: 30000 });
      
      // Aguardar carregamento dos produtos
      await page.waitForSelector('.list-item', { timeout: 10000 });
      
      // Extrair dados dos produtos
      const products = await page.evaluate(() => {
        const items = document.querySelectorAll('.list-item');
        const results = [];
        
        items.forEach((item, index) => {
          if (index >= 20) return; // Limitar a 20 produtos
          
          try {
            const nameElement = item.querySelector('.item-title');
            const priceElement = item.querySelector('.price-current');
            const imageElement = item.querySelector('.item-image img');
            const ratingElement = item.querySelector('.rating-value');
            const reviewsElement = item.querySelector('.rating-reviews');
            const salesElement = item.querySelector('.sold-count');
            const linkElement = item.querySelector('a');
            
            if (nameElement && priceElement) {
              const name = nameElement.textContent.trim();
              const price = priceElement.textContent.trim().replace(/[^\d.,]/g, '');
              const image = imageElement ? imageElement.src : null;
              const rating = ratingElement ? parseFloat(ratingElement.textContent) : null;
              const reviews = reviewsElement ? parseInt(reviewsElement.textContent.replace(/[^\d]/g, '')) : null;
              const sales = salesElement ? parseInt(salesElement.textContent.replace(/[^\d]/g, '')) : null;
              const url = linkElement ? linkElement.href : null;
              const idMatch = url ? url.match(/item\/(\d+)\.html/) : null;
              const aliexpress_id = idMatch ? idMatch[1] : null;
              
              results.push({
                name,
                price: parseFloat(price.replace(',', '.')),
                image,
                rating,
                reviews,
                sales,
                url,
                aliexpress_id
              });
            }
          } catch (error) {
            console.error('Erro ao processar produto:', error);
          }
        });
        
        return results;
      });
      
      await page.close();
      return products;
      
    } catch (error) {
      console.error('Erro ao buscar produtos:', error);
      throw new Error('Falha ao buscar produtos no AliExpress');
    }
  }

  async getProductDetails(productUrl) {
    try {
      const browser = await this.initBrowser();
      const page = await browser.newPage();
      
      await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
      
      await page.goto(productUrl, { waitUntil: 'networkidle2', timeout: 30000 });
      
      const productData = await page.evaluate(() => {
        const nameElement = document.querySelector('.product-title');
        const priceElement = document.querySelector('.product-price-current');
        const originalPriceElement = document.querySelector('.product-price-original');
        const descriptionElement = document.querySelector('.product-description');
        const images = Array.from(document.querySelectorAll('.product-image img')).map(img => img.src);
        const specifications = {};
        
        // Extrair especificações
        const specElements = document.querySelectorAll('.product-specification-item');
        specElements.forEach(spec => {
          const key = spec.querySelector('.spec-key')?.textContent.trim();
          const value = spec.querySelector('.spec-value')?.textContent.trim();
          if (key && value) {
            specifications[key] = value;
          }
        });
        
        const currentUrl = window.location.href;
        const idMatch = currentUrl.match(/item\/(\d+)\.html/);
        const aliexpress_id = idMatch ? idMatch[1] : null;
        const description_html = descriptionElement ? descriptionElement.innerHTML : '';
        const description_text = descriptionElement ? descriptionElement.textContent.trim() : '';

        return {
          name: nameElement ? nameElement.textContent.trim() : '',
          price: priceElement ? parseFloat(priceElement.textContent.replace(/[^\d.,]/g, '').replace(',', '.')) : 0,
          original_price: originalPriceElement ? parseFloat(originalPriceElement.textContent.replace(/[^\d.,]/g, '').replace(',', '.')) : null,
          description: description_text,
          description_html,
          images,
          specifications,
          url: currentUrl,
          aliexpress_id
        };
      });
      
      await page.close();
      return productData;
      
    } catch (error) {
      console.error('Erro ao obter detalhes do produto:', error);
      throw new Error('Falha ao obter detalhes do produto');
    }
  }

  extractProductId(url) {
    if (!url) return null;
    const match = url.match(/item\/(\d+)\.html/);
    return match ? match[1] : null;
  }

  async downloadImage(imageUrl, productId) {
    try {
      const response = await axios.get(imageUrl, {
        responseType: 'arraybuffer',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      });
      
      // Aqui você pode salvar a imagem localmente ou fazer upload para um serviço de CDN
      // Por enquanto, vamos retornar a URL original
      return imageUrl;
      
    } catch (error) {
      console.error('Erro ao baixar imagem:', error);
      return null;
    }
  }

  async processProductForImport(aliexpressData) {
    try {
      // Processar e limpar dados do AliExpress
      const processedData = {
        name: this.cleanProductName(aliexpressData.name),
        description: this.cleanDescription(aliexpressData.description),
        description_html: aliexpressData.description_html || null,
        price: this.calculateLocalPrice(aliexpressData.price),
        original_price: aliexpressData.original_price ? this.calculateLocalPrice(aliexpressData.original_price) : null,
        aliexpress_id: aliexpressData.aliexpress_id || this.extractProductId(aliexpressData.url),
        aliexpress_url: aliexpressData.url,
        aliexpress_rating: aliexpressData.rating,
        aliexpress_reviews_count: aliexpressData.reviews,
        aliexpress_sales_count: aliexpressData.sales,
        images: aliexpressData.images || [],
        specifications: {
          ...(aliexpressData.specifications || {}),
          raw_description_html: aliexpressData.description_html || null,
          fulfillment: {
            mode: 'own_warehouse',
            inbound_lead_time_days: 12,
          }
        },
        status: 'pending', // Aguardando aprovação
        stock_quantity: 0, // Será definido manualmente
        cost_price: this.calculateCostPrice(aliexpressData.price)
      };
      
      return processedData;
      
    } catch (error) {
      console.error('Erro ao processar produto:', error);
      throw new Error('Falha ao processar dados do produto');
    }
  }

  cleanProductName(name) {
    if (!name) return '';
    
    // Remover caracteres especiais e normalizar
    return name
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, ' ')
      .trim()
      .substring(0, 255); // Limitar tamanho
  }

  cleanDescription(description) {
    if (!description) return '';
    
    // Limpar HTML e caracteres especiais
    return description
      .replace(/<[^>]*>/g, '')
      .replace(/&[a-zA-Z]+;/g, '')
      .trim();
  }

  calculateLocalPrice(aliexpressPrice) {
    // Converter preço do AliExpress para moeda local
    // Aqui você pode adicionar lógica de conversão de moeda
    const exchangeRate = 5.5; // Taxa de câmbio aproximada (USD para BRL)
    const markup = 1.3; // Margem de lucro de 30%
    
    return Math.round((aliexpressPrice * exchangeRate * markup) * 100) / 100;
  }

  calculateCostPrice(aliexpressPrice) {
    // Preço de custo (preço do AliExpress + frete + impostos)
    const exchangeRate = 5.5;
    const shipping = 2.0; // Frete estimado
    const taxes = 0.6; // Impostos (60% do valor)
    
    return Math.round((aliexpressPrice * exchangeRate + shipping) * (1 + taxes) * 100) / 100;
  }
}

module.exports = new AliExpressService(); 