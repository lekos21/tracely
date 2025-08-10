#!/usr/bin/env python3
"""
Script per testare l'upload di fatti localmente con Firebase Emulator
"""
import requests
import json

# URL dell'emulatore Firebase Functions
EMULATOR_URL = "http://127.0.0.1:5001/tracely-project/europe-west1/process_chat_message"

def test_fact_upload(message, user_id="test_user_123"):
    """
    Testa l'upload di un fatto usando l'emulatore Firebase
    """
    
    # Payload per la richiesta
    payload = {
        "data": {
            "message": message,
            "type": "fact"
        }
    }
    
    # Headers per simulare autenticazione Firebase
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer owner"  # Token speciale per l'emulatore
    }
    
    print(f"🧪 Testing fact upload...")
    print(f"📝 Message: {message}")
    print(f"🔗 URL: {EMULATOR_URL}")
    
    try:
        response = requests.post(EMULATOR_URL, json=payload, headers=headers)
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📄 Response:")
        
        if response.headers.get('content-type', '').startswith('application/json'):
            result = response.json()
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(response.text)
            
        return response
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    # Test con diversi tipi di input
    test_messages = [
        "Le piace il gelato al cioccolato",
        "Odia i film horror",
        "Vorrei regalarle un libro di cucina",
        "Ama andare al cinema il venerdì sera",
        "Ha studiato ingegneria informatica",
        "ciao come stai"  # Questo dovrebbe essere scartato
    ]
    
    print("🚀 Avvio test upload fatti...\n")
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n{'='*50}")
        print(f"TEST {i}/{len(test_messages)}")
        print(f"{'='*50}")
        
        response = test_fact_upload(message)
        
        if response and response.status_code == 200:
            print("✅ Test completato")
        else:
            print("❌ Test fallito")
        
        print()
    
    print("🏁 Test completati!")
