from langchain_anthropic import ChatAnthropic
from langchain.schema import HumanMessage, SystemMessage, AIMessage
from langchain.memory import ConversationBufferMemory
from typing import List, Dict, Any, Optional
import json
import os
from datetime import datetime
from dotenv import load_dotenv
from fact_processor import FactProcessor
from firebase_admin import firestore

# Load environment variables
load_dotenv()

class ChatAgent:
    """
    AI chat agent with session-based persistence for conversational interactions.
    Uses the same model and facts as the recommendation agent but maintains chat history.
    """
    
    def __init__(self):
        self.fact_processor = FactProcessor()
        
        # Initialize Anthropic with Claude Sonnet (same as recommendation agent)
        self.llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            temperature=0.7,  # Balanced temperature for natural conversation
            anthropic_api_key=os.getenv("ANTHROPIC_API_KEY")
        )
        
        # Use Firestore for persistent session storage instead of memory
        self.db = firestore.client()
        
        # Available tags (same as other agents)
        self.available_tags = [
            "people",      # famiglia, amici, colleghi
            "dislikes",    # cose che odia/evitare
            "gifts",       # tutto ciò che può diventare regalo
            "activities",  # hobby, interessi, cose che ama fare
            "dates",       # posti dove andare, esperienze insieme
            "food",        # gusti alimentari, ristoranti, cucina
            "history"      # background, studi, passato
        ]
    
    def _get_session_id(self, user_id: str) -> str:
        """Generate session ID for the user"""
        return f"chat_session_{user_id}"
    
    def _initialize_session(self, user_id: str) -> None:
        """Initialize a new chat session for the user"""
        session_id = self._get_session_id(user_id)
        
        # Check if session exists in Firestore
        session_ref = self.db.collection('chat_sessions').document(session_id)
        session_doc = session_ref.get()
        
        if not session_doc.exists:
            # Create new session in Firestore
            session_data = {
                'messages': [],
                'created_at': datetime.now(),
                'last_activity': datetime.now(),
                'user_id': user_id
            }
            session_ref.set(session_data)
    
    def _format_facts_for_prompt(self, facts_by_tag: Dict[str, List[Dict[str, Any]]]) -> str:
        """
        Format facts organized by tags for inclusion in the AI prompt
        
        Args:
            facts_by_tag: Dictionary with facts organized by tags
            
        Returns:
            Formatted string with facts organized by hierarchical tags
        """
        formatted_facts = []
        
        for tag in self.available_tags:
            if tag in facts_by_tag and facts_by_tag[tag]:
                formatted_facts.append(f"\n## {tag.upper()}")
                for fact in facts_by_tag[tag]:
                    fact_content = fact.get('fact', '')
                    sentiment = fact.get('sentiment', 'neutral')
                    formatted_facts.append(f"- {fact_content} ({sentiment})")
        
        return "\n".join(formatted_facts) if formatted_facts else "Nessun fatto disponibile."
    
    def _get_system_prompt(self, formatted_facts: str) -> str:
        """Generate the system prompt with user facts"""
        return f"""Sei un assistente AI conversazionale specializzato nelle relazioni romantiche. 
Il tuo ruolo è aiutare l'utente a comprendere meglio la sua partner attraverso conversazioni naturali e coinvolgenti.

INFORMAZIONI SULLA PARTNER E RIFLESSIONI GENERALI:
{formatted_facts}

LINEE GUIDA PER LA CONVERSAZIONE:
1. Sii conversazionale, empatico e naturale
2. Usa le informazioni sui fatti per dare consigli personalizzati e pertinenti
3. Fai domande di approfondimento quando appropriato
4. Aiuta l'utente a riflettere sui pattern e le connessioni tra i fatti
5. Suggerisci idee creative basate sui fatti conosciuti
6. Mantieni un tono amichevole e di supporto
7. Ricorda i dettagli della conversazione corrente per continuità

STILE DI COMUNICAZIONE:
- Usa un linguaggio naturale e colloquiale
- Sii specifico quando fai riferimento ai fatti conosciuti
- Incoraggia la riflessione e l'approfondimento
- Offri prospettive utili e consigli pratici

Ricorda: stai aiutando qualcuno a costruire una relazione migliore attraverso la comprensione e l'attenzione ai dettagli."""

    def chat(self, user_id: str, message: str) -> Dict[str, Any]:
        """
        Process a chat message and return a response with conversation history
        
        Args:
            user_id: User ID
            message: User's message
            
        Returns:
            Dictionary with success status, response, and conversation context
        """
        try:
            # Initialize session if needed
            self._initialize_session(user_id)
            
            # Get user facts organized by tags
            facts_by_tag = self.fact_processor.get_facts_by_hierarchy(user_id)
            formatted_facts = self._format_facts_for_prompt(facts_by_tag)
            
            # Get session from Firestore
            session_id = self._get_session_id(user_id)
            session_ref = self.db.collection('chat_sessions').document(session_id)
            session_doc = session_ref.get()
            session_data = session_doc.to_dict() if session_doc.exists else {'messages': []}
            
            # Add user message to history
            user_message = {
                'role': 'user',
                'content': message,
                'timestamp': datetime.now().isoformat()
            }
            session_data['messages'].append(user_message)
            session_data['last_activity'] = datetime.now()
            
            # Update session in Firestore
            session_ref.set(session_data)
            
            # Build message history for the LLM (exclude the current message we just added)
            messages = [SystemMessage(content=self._get_system_prompt(formatted_facts))]
            
            # Add conversation history (excluding the current user message we just added)
            for msg in session_data['messages'][:-1]:  # Exclude the last message (current user message)
                if msg['role'] == 'user':
                    messages.append(HumanMessage(content=msg['content']))
                elif msg['role'] == 'assistant':
                    messages.append(AIMessage(content=msg['content']))
            
            # Add current user message
            messages.append(HumanMessage(content=message))
            
            # Get response from Claude
            ai_response = self.llm.invoke(messages)
            ai_response_text = ai_response.content.strip()
            
            # Update session with new messages
            session_data['messages'].append({
                'role': 'assistant',
                'content': ai_response_text,
                'timestamp': datetime.now().isoformat()
            })
            session_ref.set(session_data)
            
            return {
                'success': True,
                'response': ai_response_text,
                'session_id': session_id,
                'message_count': len(session_data['messages']),
                'facts_available': len([fact for facts in facts_by_tag.values() for fact in facts])
            }
            
        except Exception as e:
            print(f"Error in chat: {e}")
            return {
                'success': False,
                'error': str(e),
                'response': "Mi dispiace, si è verificato un errore. Riprova."
            }
    
    def get_conversation_history(self, user_id: str) -> Dict[str, Any]:
        """
        Get the conversation history for a user session
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with conversation history and metadata
        """
        session_id = self._get_session_id(user_id)
        
        # Get session from Firestore
        session_ref = self.db.collection('chat_sessions').document(session_id)
        session_doc = session_ref.get()
        
        if not session_doc.exists:
            return {
                'success': True,  # Changed to True - empty history is valid
                'messages': [],
                'message_count': 0
            }
        
        session_data = session_doc.to_dict()
        return {
            'success': True,
            'messages': session_data.get('messages', []),
            'created_at': session_data.get('created_at', datetime.now()).isoformat() if isinstance(session_data.get('created_at'), datetime) else str(session_data.get('created_at', '')),
            'last_activity': session_data.get('last_activity', datetime.now()).isoformat() if isinstance(session_data.get('last_activity'), datetime) else str(session_data.get('last_activity', '')),
            'message_count': len(session_data.get('messages', []))
        }
    
    def clear_conversation(self, user_id: str) -> Dict[str, Any]:
        """
        Clear the conversation history for a user (end session)
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with success status
        """
        session_id = self._get_session_id(user_id)
        
        # Get session from Firestore
        session_ref = self.db.collection('chat_sessions').document(session_id)
        session_doc = session_ref.get()
        
        if session_doc.exists:
            session_data = session_doc.to_dict()
            message_count = len(session_data.get('messages', []))
            
            # Delete the session document
            session_ref.delete()
            
            return {
                'success': True,
                'message': f'Conversazione cancellata. Rimossi {message_count} messaggi.',
                'cleared_messages': message_count
            }
        else:
            return {
                'success': True,
                'message': 'Nessuna conversazione attiva da cancellare.',
                'cleared_messages': 0
            }
    
    def get_active_sessions(self) -> Dict[str, Any]:
        """
        Get information about all active chat sessions
        
        Returns:
            Dictionary with active sessions info
        """
        try:
            # Get all chat sessions from Firestore
            sessions_ref = self.db.collection('chat_sessions')
            sessions_docs = sessions_ref.stream()
            
            active_sessions = []
            
            for doc in sessions_docs:
                session_data = doc.to_dict()
                active_sessions.append({
                    'session_id': doc.id,
                    'created_at': session_data.get('created_at', datetime.now()).isoformat() if isinstance(session_data.get('created_at'), datetime) else str(session_data.get('created_at', '')),
                    'last_activity': session_data.get('last_activity', datetime.now()).isoformat() if isinstance(session_data.get('last_activity'), datetime) else str(session_data.get('last_activity', '')),
                    'message_count': len(session_data.get('messages', [])),
                    'user_id': session_data.get('user_id', 'unknown')
                })
            
            return {
                'success': True,
                'active_sessions': active_sessions,
                'total_sessions': len(active_sessions)
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'active_sessions': [],
                'total_sessions': 0
            }
    
    def cleanup_old_sessions(self, max_age_hours: int = 24) -> Dict[str, Any]:
        """
        Clean up sessions older than specified hours
        
        Args:
            max_age_hours: Maximum age in hours before session cleanup
            
        Returns:
            Dictionary with cleanup results
        """
        try:
            from datetime import timedelta
            
            cutoff_time = datetime.now() - timedelta(hours=max_age_hours)
            
            # Get all chat sessions from Firestore
            sessions_ref = self.db.collection('chat_sessions')
            sessions_docs = sessions_ref.stream()
            
            sessions_to_remove = []
            
            for doc in sessions_docs:
                session_data = doc.to_dict()
                last_activity = session_data.get('last_activity')
                
                # Handle both datetime objects and timestamp strings
                if isinstance(last_activity, datetime):
                    if last_activity < cutoff_time:
                        sessions_to_remove.append(doc.id)
                elif isinstance(last_activity, str):
                    try:
                        last_activity_dt = datetime.fromisoformat(last_activity.replace('Z', '+00:00'))
                        if last_activity_dt < cutoff_time:
                            sessions_to_remove.append(doc.id)
                    except:
                        # If we can't parse the timestamp, consider it old
                        sessions_to_remove.append(doc.id)
            
            # Remove old sessions
            for session_id in sessions_to_remove:
                sessions_ref.document(session_id).delete()
            
            # Count remaining sessions
            remaining_sessions = len(list(sessions_ref.stream()))
            
            return {
                'success': True,
                'cleaned_sessions': len(sessions_to_remove),
                'remaining_sessions': remaining_sessions
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'cleaned_sessions': 0,
                'remaining_sessions': 0
            }
