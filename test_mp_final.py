#!/usr/bin/env python3
import requests
import json
import uuid

def test_mercadopago_integration():
    """Teste completo da integração Mercado Pago"""
    
    # 1. Testar debug primeiro
    print("🔍 1. Testando debug do Mercado Pago...")
    debug_url = "https://mercadodasophia-api.onrender.com/api/payment/mp/debug"
    
    try:
        response = requests.get(debug_url, timeout=30)
        print(f"Status: {response.status_code}")
        debug_data = response.json()
        
        access_token = debug_data.get('sdk_info', {}).get('access_token')
        if access_token and access_token != 'null':
            print(f"✅ Access Token: {access_token[:20]}...")
        else:
            print("❌ Access Token não encontrado")
            
    except Exception as e:
        print(f"❌ Erro no debug: {e}")
        return
    
    # 2. Testar criação de preferência via endpoint direto
    print("\n🔍 2. Testando criação de preferência (endpoint direto)...")
    preference_url = "https://mercadodasophia-api.onrender.com/api/payment/mp/create-preference"
    
    # Payload correto para o endpoint direto
    preference_payload = {
        "items": [
            {
                "title": "Produto Teste",
                "quantity": 1,
                "unit_price": 25.99,
                "currency_id": "BRL"
            }
        ],
        "payer": {
            "email": "test@mercadodasophia.com"
        },
        "back_urls": {
            "success": "https://mercadodasophia.com/success",
            "failure": "https://mercadodasophia.com/failure",
            "pending": "https://mercadodasophia.com/pending"
        },
        "auto_return": "approved",
        "external_reference": f"TEST-{uuid.uuid4().hex[:8]}"
    }
    
    try:
        response = requests.post(preference_url, json=preference_payload, timeout=30)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"✅ Preferência criada!")
                print(f"ID: {data.get('preference', {}).get('id')}")
                print(f"Init Point: {data.get('preference', {}).get('init_point')}")
            else:
                print(f"❌ Erro: {data.get('message')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # 3. Testar fluxo de pagamento integrado
    print("\n🔍 3. Testando fluxo de pagamento integrado...")
    payment_url = "https://mercadodasophia-api.onrender.com/api/payment/process"
    
    # Payload para o fluxo integrado (que inclui order_id)
    payment_payload = {
        "order_id": f"ORDER-{uuid.uuid4().hex[:8]}",
        "total_amount": 49.90,
        "customer_email": "customer@test.com",
        "items": [
            {
                "title": "Produto AliExpress Personalizado",
                "quantity": 2,
                "unit_price": 24.95
            }
        ]
    }
    
    try:
        response = requests.post(payment_url, json=payment_payload, timeout=30)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"✅ Pagamento iniciado!")
                print(f"Order ID: {data.get('order_id')}")
                print(f"Init Point: {data.get('init_point')}")
                print(f"Payment URL: {data.get('init_point')}")
            else:
                print(f"❌ Erro: {data.get('message')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    print("=== TESTE FINAL - INTEGRAÇÃO MERCADO PAGO ===")
    test_mercadopago_integration()
    print("\n=== TESTE CONCLUÍDO ===")
