#!/usr/bin/env python3
import requests
import json

def test_env_vars():
    url = "https://service-api-aliexpress.mercadodasophia.com.br/test"
    
    try:
        print("🔍 Testando servidor...")
        response = requests.get(url, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
    except Exception as e:
        print(f"Exception: {e}")

def test_mp_debug():
    url = "https://service-api-aliexpress.mercadodasophia.com.br/api/payment/mp/debug"
    
    try:
        print("\n🔍 Testando debug MP...")
        response = requests.get(url, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        data = response.json()
        
        print(f"SDK Info: {json.dumps(data.get('sdk_info', {}), indent=2)}")
        
        # Verificar se as variáveis estão sendo carregadas
        access_token = data.get('sdk_info', {}).get('access_token')
        public_key = data.get('sdk_info', {}).get('public_key')
        
        if access_token and access_token != 'null':
            print(f"✅ Access Token encontrado: {access_token[:20]}...")
        else:
            print("❌ Access Token não encontrado ou null")
            
        if public_key and public_key != 'null':
            print(f"✅ Public Key encontrado: {public_key[:20]}...")
        else:
            print("❌ Public Key não encontrado ou null")
        
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    print("=== VERIFICANDO VARIÁVEIS DE AMBIENTE NO RENDER ===")
    test_env_vars()
    test_mp_debug()
