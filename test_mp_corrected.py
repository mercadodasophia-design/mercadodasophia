#!/usr/bin/env python3
import requests
import json
import uuid

def test_mp_create_preference():
    """Testar endpoint direto de criação de preferência"""
    print("🔍 Testando /api/payment/mp/create-preference...")
    
    url = "https://mercadodasophia-api.onrender.com/api/payment/mp/create-preference"
    
    # Payload correto conforme código do servidor
    payload = {
        "order_id": f"ORDER-{uuid.uuid4().hex[:8]}",
        "total_amount": 29.99,
        "payer": {
            "email": "test@mercadodasophia.com",
            "name": "João",
            "surname": "Silva"
        }
    }
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Sucesso!")
            print(f"Preference ID: {data.get('preference_id')}")
            print(f"Init Point: {data.get('init_point')}")
            return data.get('preference_id')
        else:
            print(f"❌ Erro HTTP: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return None

def test_mp_process_payment():
    """Testar fluxo integrado de pagamento"""
    print("\n🔍 Testando /api/payment/process...")
    
    url = "https://mercadodasophia-api.onrender.com/api/payment/process"
    
    # Payload correto conforme código do servidor
    payload = {
        "order_id": f"ORDER-{uuid.uuid4().hex[:8]}",
        "total_amount": 49.90,
        "items": [
            {
                "title": "Produto AliExpress",
                "quantity": 1,
                "unit_price": 49.90
            }
        ],
        "customer_info": {
            "email": "customer@test.com",
            "name": "Maria",
            "surname": "Santos",
            "phone": {
                "area_code": "85",
                "number": "999123456"
            }
        }
    }
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Sucesso!")
            print(f"Preference ID: {data.get('preference_id')}")
            print(f"Init Point: {data.get('init_point')}")
            print(f"Sandbox Init Point: {data.get('sandbox_init_point')}")
            return data.get('preference_id')
        else:
            print(f"❌ Erro HTTP: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return None

def test_mp_debug():
    """Testar debug do Mercado Pago"""
    print("\n🔍 Testando /api/payment/mp/debug...")
    
    url = "https://mercadodasophia-api.onrender.com/api/payment/mp/debug"
    
    try:
        response = requests.get(url, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            sdk_info = data.get('sdk_info', {})
            
            access_token = sdk_info.get('access_token')
            public_key = sdk_info.get('public_key')
            sandbox_mode = sdk_info.get('sandbox_mode')
            
            print(f"Access Token: {'✅ Configurado' if access_token else '❌ Não encontrado'}")
            print(f"Public Key: {'✅ Configurado' if public_key else '❌ Não encontrado'}")
            print(f"Sandbox Mode: {sandbox_mode}")
            
            return access_token is not None
        else:
            print(f"❌ Erro HTTP: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    print("=== TESTE CORRIGIDO - MERCADO PAGO ===")
    
    # 1. Debug primeiro
    debug_ok = test_mp_debug()
    
    # 2. Se debug OK, testar endpoints
    if debug_ok:
        print("\n✅ Debug OK! Testando endpoints...")
        
        # Testar endpoint direto
        preference_id_1 = test_mp_create_preference()
        
        # Testar fluxo integrado  
        preference_id_2 = test_mp_process_payment()
        
        if preference_id_1 or preference_id_2:
            print(f"\n🎉 SUCESSO! Integração Mercado Pago funcionando!")
            if preference_id_1:
                print(f"🔗 Preferência 1: {preference_id_1}")
            if preference_id_2:
                print(f"🔗 Preferência 2: {preference_id_2}")
        else:
            print(f"\n❌ Falha nos testes de criação de preferência")
    else:
        print(f"\n❌ Debug falhou. Verificar configuração das variáveis de ambiente.")
    
    print("\n=== TESTE CONCLUÍDO ===")
