from firebase_functions import https_fn, options
from firebase_admin import initialize_app
import json
from fact_processor import FactProcessor
from ai_service import AIService
from recommendation_agent import RecommendationAgent

# Initialize Firebase Admin
initialize_app()

# Initialize AI services lazily to avoid deployment timeouts
fact_processor = None
ai_service = None
recommendation_agent = None

def get_fact_processor():
    global fact_processor
    if fact_processor is None:
        fact_processor = FactProcessor()
    return fact_processor

def get_ai_service():
    global ai_service
    if ai_service is None:
        ai_service = AIService()
    return ai_service

def get_recommendation_agent():
    global recommendation_agent
    if recommendation_agent is None:
        recommendation_agent = RecommendationAgent()
    return recommendation_agent

@https_fn.on_call(region="europe-west1")
def test_function(req):
    """Simple test function to verify deployment works"""
    return {
        'success': True,
        'message': 'Hello from TraceLy Cloud Functions!',
        'data': req.data
    }

@https_fn.on_call(region="europe-west1")
def process_chat_message(req):
    """Enhanced chat message processor with AI fact extraction"""
    try:
        message = req.data.get('message', '')
        message_type = req.data.get('type', 'fact')
        
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
            
            # Automatically store/update user profile on each interaction
            try:
                from firebase_admin import firestore
                db = firestore.client()
                
                email = req.auth.token.get('email', '')
                name = req.auth.token.get('name', '')
                picture = req.auth.token.get('picture', '')
                
                user_profile = {
                    'email': email,
                    'name': name,
                    'picture': picture,
                    'last_login': firestore.SERVER_TIMESTAMP
                }
                
                # Update profile with merge=True (creates if doesn't exist, updates if exists)
                db.collection('users').document(user_id).set(user_profile, merge=True)
                
            except Exception as profile_error:
                print(f"Warning: Could not update user profile: {profile_error}")
                # Continue with the main function even if profile update fails
                
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'message': 'Devi essere autenticato per usare questa funzione.'
            }
        
        if message_type == 'fact':
            # Use AI to process and save the fact
            result = get_fact_processor().process_and_save_fact(message, user_id)
            return result
            
        elif message_type == 'query':
            # Use existing AI service for queries
            response = get_ai_service().process_query(user_id, message)
            return {
                'success': True,
                'type': 'ai_response',
                'message': response,
                'data': {}
            }
        else:
            return {
                'success': False,
                'message': 'Tipo di messaggio non riconosciuto.',
                'error': 'Invalid message type'
            }
            
    except Exception as e:
        print(f"Error in process_chat_message: {e}")
        return {
            'success': False,
            'error': str(e),
            'message': 'Si è verificato un errore nell\'elaborazione del messaggio.'
        }

@https_fn.on_call(region="europe-west1")
def get_user_facts(req):
    """Retrieve user facts with optional filtering"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'facts': []
            }
            
        tag = req.data.get('tag', None)
        limit = req.data.get('limit', 50)
        
        if tag:
            facts = get_fact_processor().get_user_facts_by_tag(user_id, tag, limit)
        else:
            facts = get_fact_processor().get_all_user_facts(user_id, limit)
        
        return {
            'success': True,
            'facts': facts,
            'count': len(facts)
        }
    except Exception as e:
        print(f"Error in get_user_facts: {e}")
        return {
            'success': False,
            'error': str(e),
            'facts': []
        }

@https_fn.on_call(region="europe-west1")
def store_user_profile(req):
    """Store user profile information on first login"""
    try:
        # Get authenticated user info from Firebase Auth
        if not req.auth or not req.auth.uid:
            return {
                'success': False,
                'error': 'Authentication required',
                'message': 'Devi essere autenticato per salvare il profilo.'
            }
        
        user_id = req.auth.uid
        email = req.auth.token.get('email', '')
        name = req.auth.token.get('name', '')
        picture = req.auth.token.get('picture', '')
        
        # Store user profile in Firestore
        from firebase_admin import firestore
        db = firestore.client()
        
        user_profile = {
            'email': email,
            'name': name,
            'picture': picture,
            'created_at': firestore.SERVER_TIMESTAMP,
            'last_login': firestore.SERVER_TIMESTAMP
        }
        
        # Use merge=True to update existing profile or create new one
        db.collection('users').document(user_id).set(user_profile, merge=True)
        
        return {
            'success': True,
            'message': 'Profilo utente salvato con successo.',
            'profile': {
                'email': email,
                'name': name,
                'picture': picture
            }
        }
        
    except Exception as e:
        print(f"Error storing user profile: {e}")
        return {
            'success': False,
            'error': str(e),
            'message': 'Errore nel salvare il profilo utente.'
        }

@https_fn.on_call(region="europe-west1")
def get_facts_summary(req):
    """Get facts organized by tags for AI context"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'facts_by_tag': {}
            }
        
        facts_by_tag = get_fact_processor().get_facts_summary_by_tags(user_id)
        
        # Count facts by tag
        tag_counts = {tag: len(facts) for tag, facts in facts_by_tag.items()}
        
        return {
            'success': True,
            'facts_by_tag': facts_by_tag,
            'tag_counts': tag_counts,
            'total_facts': sum(tag_counts.values())
        }
    except Exception as e:
        print(f"Error in get_facts_summary: {e}")
        return {
            'success': False,
            'error': str(e),
            'facts_by_tag': {}
        }

@https_fn.on_call(region="europe-west1")
def get_user_facts_by_hierarchy(req):
    """Get facts organized by priority hierarchy"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'facts_hierarchy': [[] for _ in range(7)]
            }
            
        limit = req.data.get('limit', 50)
        
        facts_hierarchy = get_fact_processor().get_all_user_facts_by_hierarchy(user_id, limit)
        
        # Tag names for reference
        tag_names = ['people', 'dislikes', 'gifts', 'activities', 'dates', 'food', 'history']
        
        # Count facts in each hierarchy level
        hierarchy_counts = [len(facts) for facts in facts_hierarchy]
        
        return {
            'success': True,
            'facts_hierarchy': facts_hierarchy,
            'tag_names': tag_names,
            'hierarchy_counts': hierarchy_counts,
            'total_facts': sum(hierarchy_counts)
        }
    except Exception as e:
        print(f"Error in get_user_facts_by_hierarchy: {e}")
        return {
            'success': False,
            'error': str(e),
            'facts_hierarchy': [[] for _ in range(7)]
        }

@https_fn.on_call(region="europe-west1")
def generate_recommendations(req):
    """Generate personalized recommendations based on user facts and selected tags"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'suggestions': []
            }
        
        # Get parameters from request
        selected_tags = req.data.get('tags', None)  # List of tags to focus on (None = all tags)
        count = req.data.get('count', 5)  # Number of suggestions to generate
        
        # Validate count
        if count < 1 or count > 20:
            count = 5
        
        # Generate recommendations using the agent
        result = get_recommendation_agent().generate_recommendations(
            user_id=user_id,
            selected_tags=selected_tags,
            count=count
        )
        
        return result
        
    except Exception as e:
        print(f"Error in generate_recommendations: {e}")
        return {
            'success': False,
            'error': str(e),
            'suggestions': []
        }

@https_fn.on_call(region="europe-west1")
def get_recommendation_tags(req):
    """Get available tags and user's tag statistics for recommendations"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required',
                'available_tags': [],
                'user_tag_stats': {}
            }
        
        # Get available tags and user statistics
        available_tags = get_recommendation_agent().get_available_tags()
        user_tag_stats = get_recommendation_agent().get_user_tag_stats(user_id)
        
        return {
            'success': True,
            'available_tags': available_tags,
            'user_tag_stats': user_tag_stats,
            'total_facts': sum(user_tag_stats.values())
        }
        
    except Exception as e:
        print(f"Error in get_recommendation_tags: {e}")
        return {
            'success': False,
            'error': str(e),
            'available_tags': [],
            'user_tag_stats': {}
        }

@https_fn.on_call(region="europe-west1")
def update_fact(req):
    """Update an existing fact"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required'
            }
        
        fact_id = req.data.get('fact_id')
        fact_text = req.data.get('fact_text')
        
        if not fact_id or not fact_text:
            return {
                'success': False,
                'error': 'Missing fact_id or fact_text'
            }
        
        # Process the new fact text with AI to get updated tags and sentiment
        result = get_fact_processor().process_input_to_fact(fact_text, user_id)
        
        if result:
            # Update the fact in Firestore
            from firebase_admin import firestore
            db = firestore.client()
            
            # Use the correct path: users/{user_id}/facts/{fact_id}
            fact_ref = (db.collection('users')
                       .document(user_id)
                       .collection('facts')
                       .document(fact_id))
            
            fact_doc = fact_ref.get()
            
            if not fact_doc.exists:
                return {
                    'success': False,
                    'error': 'Fact not found'
                }
            
            # Update with new processed data
            update_data = {
                'fact': result['fact'],
                'tags': result['tags'],
                'sentiment': result['sentiment'],
                'updated_at': firestore.SERVER_TIMESTAMP
            }
            
            fact_ref.update(update_data)
            
            return {
                'success': True,
                'message': 'Fact updated successfully',
                'fact': result
            }
        else:
            return {
                'success': False,
                'error': 'Invalid fact content'
            }
        
    except Exception as e:
        print(f"Error in update_fact: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@https_fn.on_call(region="europe-west1")
def delete_fact(req):
    """Delete a fact"""
    try:
        # Get authenticated user ID from Firebase Auth
        if req.auth and req.auth.uid:
            user_id = req.auth.uid
        else:
            return {
                'success': False,
                'error': 'Authentication required'
            }
        
        fact_id = req.data.get('fact_id')
        
        if not fact_id:
            return {
                'success': False,
                'error': 'Missing fact_id'
            }
        
        from firebase_admin import firestore
        db = firestore.client()
        
        # Use the correct path: users/{user_id}/facts/{fact_id}
        fact_ref = (db.collection('users')
                   .document(user_id)
                   .collection('facts')
                   .document(fact_id))
        
        fact_doc = fact_ref.get()
        
        if not fact_doc.exists:
            return {
                'success': False,
                'error': 'Fact not found'
            }
        
        # Delete the fact
        fact_ref.delete()
        
        return {
            'success': True,
            'message': 'Fact deleted successfully'
        }
        
    except Exception as e:
        print(f"Error in delete_fact: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@https_fn.on_call(region="europe-west1")
def generate_random_cards(req):
    """Generate sample cards"""
    try:
        card_type = req.data.get('type', 'mixed')
        count = req.data.get('count', 3)
        
        # Sample cards
        cards = [
            {
                'type': 'gift',
                'title': 'Idea Regalo',
                'content': 'Considera qualcosa di creativo che rifletta i suoi interessi.',
                'icon': '🎁'
            },
            {
                'type': 'date',
                'title': 'Appuntamento',
                'content': 'Una serata tranquilla a casa con il suo film preferito.',
                'icon': '💕'
            },
            {
                'type': 'insight',
                'title': 'Consiglio',
                'content': 'Ricorda di ascoltare attivamente quando ti parla.',
                'icon': '💡'
            }
        ]
        
        return {
            'success': True,
            'cards': cards[:count]
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'cards': []
        }
