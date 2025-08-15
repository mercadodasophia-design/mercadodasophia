#!/usr/bin/env python3
import requests
import json

def test_mercadopago_create_preference():
    url = "https://service-api-aliexpress.mercadodasophia.com.br/api/payment/mp/create-preference"
    
    payload = {
        "items": [
            {
                "title": "Produto Teste",
                "quantity": 1,
                "unit_price": 10.50
            }
        ],
        "payer": {
            "email": "test@example.com"
        },
        "back_urls": {
            "success": "https://example.com/success",
            "failure": "https://example.com/failure", 
            "pending": "https://example.com/pending"
        },
        "auto_return": "approved"
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        print(f"Testing: {url}")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\nSUCESS! Preference created:")
            print(f"ID: {data.get('id')}")
            print(f"Init Point: {data.get('init_point')}")
        else:
            print(f"\nERROR: {response.status_code}")
            
    except Exception as e:
        print(f"Exception: {e}")

def test_debug_endpoint():
    url = "https://service-api-aliexpress.mercadodasophia.com.br/api/payment/mp/debug"
    
    try:
        print(f"\nTesting debug endpoint: {url}")
        response = requests.get(url, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    print("=== TESTING MERCADO PAGO INTEGRATION ===")
    
    # Test debug first
    test_debug_endpoint()
    
    print("\n" + "="*50)
    
    # Test create preference
    test_mercadopago_create_preference()
