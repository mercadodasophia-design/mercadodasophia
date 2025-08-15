#!/usr/bin/env python3
"""
Teste de status da API Python
Verifica se os endpoints estão funcionando
"""

import requests
import json

def test_api_status():
    """Testa se a API Python está funcionando"""
    
    base_url = "https://service-api-aliexpress.mercadodasophia.com.br"
    
    print("🔍 Testando status da API Python...")
    print(f"🌐 URL: {base_url}")
    print("=" * 50)
    
    # Teste 1: Status geral
    print("1️⃣ Testando status geral...")
    try:
        response = requests.get(f"{base_url}/", timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   Resposta: {response.text[:100]}...")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # Teste 2: Endpoint de autorização
    print("\n2️⃣ Testando endpoint de autorização...")
    try:
        response = requests.get(f"{base_url}/api/aliexpress/auth", timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Sucesso! URL de autorização gerada")
            print(f"   Auth URL: {data.get('auth_url', 'N/A')[:50]}...")
        else:
            print(f"   ❌ Erro: {response.text}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # Teste 3: Status dos tokens
    print("\n3️⃣ Testando status dos tokens...")
    try:
        response = requests.get(f"{base_url}/api/aliexpress/tokens/status", timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Sucesso! Status dos tokens:")
            print(f"   Tem tokens: {data.get('has_tokens', False)}")
            print(f"   Conta: {data.get('account', 'N/A')}")
        else:
            print(f"   ❌ Erro: {response.text}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # Teste 4: CORS headers
    print("\n4️⃣ Testando CORS...")
    try:
        response = requests.options(f"{base_url}/api/aliexpress/auth", timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   CORS Headers: {dict(response.headers)}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    print("\n" + "=" * 50)
    print("📋 RESUMO DOS TESTES")
    print("=" * 50)

if __name__ == "__main__":
    test_api_status()
