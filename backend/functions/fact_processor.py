from firebase_admin import firestore
from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from typing import Dict, List, Any, Optional
import json
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class FactModel(BaseModel):
    """Pydantic model for structured fact output"""
    fact: str = Field(description="Il fatto estratto in forma chiara e concisa")
    tags: List[str] = Field(description="Lista di tag (massimo 3) che descrivono il fatto", max_items=3)
    sentiment: str = Field(description="Sentimento: positive, negative, o neutral")

class FactProcessor:
    """
    Enhanced AI service for processing relationship facts using LangChain + GPT-4.1 nano
    and saving them to Firestore with proper structure and tagging.
    """
    
    def __init__(self):
        self.db = firestore.client()
        
        # Initialize OpenAI with GPT-4.1 nano
        self.llm = ChatOpenAI(
            model="gpt-4o-mini",  # GPT-4.1 nano equivalent
            temperature=0.3,
            openai_api_key=os.getenv("OPENAI_API_KEY")
        )
        
        # Initialize Pydantic output parser
        self.output_parser = PydanticOutputParser(pydantic_object=FactModel)
        
        # Available tags (simplified from 7 main categories)
        self.available_tags = [
            "people",      # famiglia, amici, colleghi
            "dislikes",    # cose che odia/evitare
            "gifts",       # tutto ciò che può diventare regalo
            "activities",  # hobby, interessi, cose che ama fare
            "dates",       # posti dove andare, esperienze insieme
            "food",        # gusti alimentari, ristoranti, cucina
            "history"      # background, studi, passato
        ]
        
        # Italian system prompt for fact extraction
        self.fact_extraction_prompt = f"""
Sei un assistente AI specializzato nell'analizzare informazioni su relazioni romantiche.
Il tuo compito è trasformare input dell'utente in "facts" strutturati.

TAG DISPONIBILI (massimo 3 per fact):
- people: famiglia, amici, colleghi
- dislikes: cose che odia o da evitare
- gifts: tutto ciò che può diventare regalo
- activities: hobby, interessi, cose che ama fare
- dates: posti dove andare, esperienze insieme
- food: gusti alimentari, ristoranti, cucina
- history: background, studi, passato

REGOLE:
- Estrai il fatto in forma chiara e concisa
- Scegli massimo 3 tag più rilevanti dalla lista
- Determina il sentiment: positive, negative, o neutral
- Se l'input non contiene informazioni utili sulla partner, rispondi con "SKIP"

ESEMPI:
Input: "Odia quando sono in ritardo"
Fact: "Odia quando sono in ritardo"
Tags: ["dislikes"]
Sentiment: "negative"

Input: "Ama i film di Studio Ghibli"
Fact: "Ama i film di Studio Ghibli"
Tags: ["activities", "gifts"]
Sentiment: "positive"

Input: "Ha litigato con Sara per il matrimonio"
Fact: "Ha litigato con Sara per il matrimonio"
Tags: ["people"]
Sentiment: "negative"

{self.output_parser.get_format_instructions()}
"""

    def process_input_to_fact(self, user_input: str, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Process user input and convert it to a structured fact using LangChain + GPT-4.1 nano
        
        Args:
            user_input: Raw input from user
            user_id: User ID for context
            
        Returns:
            Structured fact dict or None if input is not useful
        """
        try:
            # Create messages for the LLM
            messages = [
                SystemMessage(content=self.fact_extraction_prompt),
                HumanMessage(content=f"Input da analizzare: {user_input}")
            ]
            
            # Get response from GPT-4.1 nano
            response = self.llm(messages)
            response_text = response.content.strip()
            
            # Handle SKIP response
            if "SKIP" in response_text.upper():
                return None
                
            # Parse structured response using Pydantic
            try:
                fact_model = self.output_parser.parse(response_text)
                
                # Convert to dict and add metadata
                fact_data = {
                    "fact": fact_model.fact,
                    "tags": fact_model.tags[:3],  # Ensure max 3 tags
                    "sentiment": fact_model.sentiment,
                    "date": datetime.now().isoformat()
                }
                
                return fact_data
                
            except Exception as parse_error:
                print(f"Failed to parse structured response: {response_text}, Error: {parse_error}")
                return None
                
        except Exception as e:
            print(f"Error processing input with AI: {e}")
            return None

    def save_fact_to_firestore(self, fact_data: Dict[str, Any], user_id: str) -> bool:
        """
        Save a structured fact to Firestore
        
        Args:
            fact_data: Structured fact dictionary
            user_id: User ID
            
        Returns:
            True if saved successfully, False otherwise
        """
        try:
            # Reference to user's facts collection
            facts_ref = self.db.collection('users').document(user_id).collection('facts')
            
            # Add the fact
            doc_ref = facts_ref.add(fact_data)
            
            print(f"Fact saved successfully with ID: {doc_ref[1].id}")
            return True
            
        except Exception as e:
            print(f"Error saving fact to Firestore: {e}")
            return False

    def process_and_save_fact(self, user_input: str, user_id: str) -> Dict[str, Any]:
        """
        Complete pipeline: process input with AI and save to Firestore
        
        Args:
            user_input: Raw input from user
            user_id: User ID
            
        Returns:
            Response dictionary with success status and details
        """
        try:
            # Step 1: Process input with AI
            fact_data = self.process_input_to_fact(user_input, user_id)
            
            if fact_data is None:
                return {
                    "success": False,
                    "message": "L'input non contiene informazioni utili da salvare.",
                    "type": "no_fact_extracted"
                }
            
            # Step 2: Save to Firestore
            saved = self.save_fact_to_firestore(fact_data, user_id)
            
            if saved:
                return {
                    "success": True,
                    "message": f"Fatto salvato: \"{fact_data['fact']}\"",
                    "type": "fact_saved",
                    "fact_data": {
                        "fact": fact_data["fact"],
                        "tags": fact_data["tags"],
                        "sentiment": fact_data["sentiment"]
                    }
                }
            else:
                return {
                    "success": False,
                    "message": "Errore nel salvare il fatto nel database.",
                    "type": "save_error"
                }
                
        except Exception as e:
            print(f"Error in process_and_save_fact: {e}")
            return {
                "success": False,
                "message": "Si è verificato un errore nell'elaborazione.",
                "type": "processing_error",
                "error": str(e)
            }

    def get_user_facts_by_tag(self, user_id: str, tag: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Retrieve facts by tag for a user
        
        Args:
            user_id: User ID
            tag: Tag to filter by (searches in tags array)
            limit: Maximum number of facts to return
            
        Returns:
            List of facts matching the tag
        """
        try:
            facts_ref = (self.db.collection('users')
                        .document(user_id)
                        .collection('facts')
                        .where('tags', 'array_contains', tag)
                        .order_by('date', direction=firestore.Query.DESCENDING)
                        .limit(limit))
            
            facts = facts_ref.stream()
            return [{'id': fact.id, **fact.to_dict()} for fact in facts]
            
        except Exception as e:
            print(f"Error retrieving facts by tag: {e}")
            return []

    def get_all_user_facts(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Retrieve all facts for a user, ordered by date
        
        Args:
            user_id: User ID
            limit: Maximum number of facts to return
            
        Returns:
            List of all user facts
        """
        try:
            facts_ref = (self.db.collection('users')
                        .document(user_id)
                        .collection('facts')
                        .order_by('date', direction=firestore.Query.DESCENDING)
                        .limit(limit))
            
            facts = facts_ref.stream()
            return [{'id': fact.id, **fact.to_dict()} for fact in facts]
            
        except Exception as e:
            print(f"Error retrieving all facts: {e}")
            return []

    def get_all_user_facts_by_hierarchy(self, user_id: str, limit: int = 50) -> List[List[Dict[str, Any]]]:
        """
        Retrieve all facts for a user grouped by highest priority tag
        
        Args:
            user_id: User ID
            limit: Maximum number of facts to return
            
        Returns:
            List of lists where each inner list contains facts grouped by highest priority tag
            Order: [people, dislikes, gifts, activities, dates, food, history]
        """
        try:
            # Get all facts
            all_facts = self.get_all_user_facts(user_id, limit)
            
            # Tag hierarchy (highest to lowest priority)
            tag_hierarchy = [
                "people",      # famiglia, amici, colleghi (massima priorità)
                "dislikes",    # cose da evitare (alta priorità)
                "gifts",       # idee regalo potenziali
                "activities",  # hobby, interessi, cose che ama fare
                "dates",       # posti dove andare, esperienze insieme
                "food",        # preferenze alimentari, ristoranti
                "history"      # background, studi, eventi passati (bassa priorità)
            ]
            
            # Group facts by highest priority tag
            grouped_facts = [[] for _ in tag_hierarchy]  # Initialize empty lists for each priority level
            
            for fact in all_facts:
                fact_tags = fact.get('tags', [])
                
                # Find the highest priority tag for this fact
                highest_priority_index = len(tag_hierarchy)  # Default to lowest priority
                
                for tag in fact_tags:
                    if tag in tag_hierarchy:
                        tag_index = tag_hierarchy.index(tag)
                        if tag_index < highest_priority_index:
                            highest_priority_index = tag_index
                
                # Add fact to the appropriate priority group
                if highest_priority_index < len(tag_hierarchy):
                    grouped_facts[highest_priority_index].append(fact)
                else:
                    # If no matching tag found, add to history (lowest priority)
                    grouped_facts[-1].append(fact)
            
            return grouped_facts
            
        except Exception as e:
            print(f"Error retrieving facts by hierarchy: {e}")
            return [[] for _ in range(7)]  # Return 7 empty lists on error

    def get_facts_summary_by_tags(self, user_id: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Get facts organized by tags for AI prompt generation
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with facts organized by tags
        """
        try:
            all_facts = self.get_all_user_facts(user_id, limit=100)
            
            # Organize by tags
            facts_by_tag = {
                'people': [],
                'dislikes': [],
                'gifts': [],
                'activities': [],
                'dates': [],
                'food': [],
                'history': []
            }
            
            for fact in all_facts:
                fact_tags = fact.get('tags', [])
                # Add fact to each relevant tag category
                for tag in fact_tags:
                    if tag in facts_by_tag:
                        facts_by_tag[tag].append(fact)
            
            return facts_by_tag
            
        except Exception as e:
            print(f"Error getting facts summary: {e}")
            return {}
