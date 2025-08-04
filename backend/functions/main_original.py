from firebase_functions import https_fn, options
from firebase_admin import initialize_app, firestore
import json
from typing import Any, Dict
from ai_service import AIService

# Initialize Firebase Admin
initialize_app()

# Initialize Firestore client
db = firestore.client()

# Initialize AI Service
ai_service = AIService()

@https_fn.on_call(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST"]
    )
)
def process_chat_message(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Process chat messages from the Flutter app.
    Handles both fact input and queries for suggestions.
    """
    try:
        # Get user ID and message from request
        user_id = req.auth.uid if req.auth else None
        if not user_id:
            raise ValueError("User must be authenticated")
        
        data = req.data
        message = data.get('message', '')
        message_type = data.get('type', 'fact')  # 'fact' or 'query'
        
        if message_type == 'fact':
            # Store fact in Firestore and return confirmation
            result = store_fact(user_id, message)
            return {
                'success': True,
                'type': 'fact_stored',
                'message': 'Fatto salvato! Cosa altro vuoi condividere?',
                'data': result
            }
        
        elif message_type == 'query':
            # Process query and return AI response
            response = ai_service.process_query(user_id, message)
            return {
                'success': True,
                'type': 'ai_response',
                'message': response,
                'data': {}
            }
        
        else:
            raise ValueError(f"Unknown message type: {message_type}")
            
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'message': 'Si è verificato un errore. Riprova.'
        }

def store_fact(user_id: str, fact_text: str) -> Dict[str, Any]:
    """Store a fact in Firestore with AI-generated tags"""
    try:
        # Use AI to extract tags and categorize the fact
        fact_analysis = ai_service.analyze_fact(fact_text)
        
        # Create fact document
        fact_doc = {
            'fact': fact_text,
            'date': firestore.SERVER_TIMESTAMP,
            'primary_tag': fact_analysis.get('primary_tag', 'general'),
            'secondary_tags': fact_analysis.get('secondary_tags', []),
            'sub_tags': fact_analysis.get('sub_tags', {}),
            'sentiment': fact_analysis.get('sentiment', 'neutral')
        }
        
        # Store in Firestore
        doc_ref = db.collection('users').document(user_id).collection('facts').add(fact_doc)
        
        return {
            'fact_id': doc_ref[1].id,
            'tags': fact_analysis
        }
        
    except Exception as e:
        raise Exception(f"Error storing fact: {str(e)}")

@https_fn.on_call(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST"]
    )
)
def generate_random_cards(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Generate random swipeable cards with insights, suggestions, or reminders
    """
    try:
        user_id = req.auth.uid if req.auth else None
        if not user_id:
            raise ValueError("User must be authenticated")
        
        data = req.data
        card_type = data.get('type', 'mixed')  # 'mixed', 'gifts', 'dates', 'insights'
        count = data.get('count', 5)
        
        cards = ai_service.generate_cards(user_id, card_type, count)
        
        return {
            'success': True,
            'cards': cards
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'cards': []
        }

@https_fn.on_call(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST"]
    )
)
def save_onboarding_data(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Save partner profile data from onboarding quiz
    """
    try:
        user_id = req.auth.uid if req.auth else None
        if not user_id:
            raise ValueError("User must be authenticated")
        
        profile_data = req.data
        
        # Store partner profile
        db.collection('users').document(user_id).set({
            'partner_profile': profile_data,
            'created_at': firestore.SERVER_TIMESTAMP,
            'onboarding_completed': True
        })
        
        return {
            'success': True,
            'message': 'Profilo salvato con successo!'
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'message': 'Errore nel salvare il profilo'
        }
