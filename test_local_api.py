#!/usr/bin/env python3
"""
Teste da API local
Verifica se os endpoints funcionam localmente
"""

import requests
import json

def test_local_api():
    """Testa a API local"""
    
    base_url = "http://localhost:5000"
    
    print("🔍 Testando API local...")
    print(f"🌐 URL: {base_url}")
    print("=" * 50)
    
    # Teste 1: Status geral
    print("1️⃣ Testando status geral...")
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        print(f"   Status: {response.status_code}")
        print(f"   Resposta: {response.text[:100]}...")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
        print("   💡 Dica: Execute 'python server.py' para iniciar a API local")
    
    # Teste 2: Endpoint de autorização
    print("\n2️⃣ Testando endpoint de autorização...")
    try:
        response = requests.get(f"{base_url}/api/aliexpress/auth", timeout=5)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Sucesso! URL de autorização gerada")
            print(f"   Auth URL: {data.get('auth_url', 'N/A')[:50]}...")
        else:
            print(f"   ❌ Erro: {response.text}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    print("\n" + "=" * 50)
    print("📋 INSTRUÇÕES")
    print("=" * 50)
    print("1. Execute: python server.py")
    print("2. Abra: http://localhost:5000")
    print("3. Teste novamente este script")

if __name__ == "__main__":
    test_local_api()
