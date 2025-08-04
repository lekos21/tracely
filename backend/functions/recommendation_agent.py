from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import json
import os
import random
from dotenv import load_dotenv
from fact_processor import FactProcessor

# Load environment variables
load_dotenv()

class SuggestionModel(BaseModel):
    """Pydantic model for a single recommendation suggestion"""
    sentence: str = Field(description="Una frase breve e actionable che descrive il suggerimento")
    tags: List[str] = Field(description="Lista di tag associati al suggerimento (massimo 3)", max_items=3)

class RecommendationResponse(BaseModel):
    """Pydantic model for the complete recommendation response"""
    suggestions: List[SuggestionModel] = Field(description="Lista di suggerimenti generati")

class RecommendationAgent:
    """
    AI agent that generates personalized recommendations based on user facts and tags.
    Takes a list of tags as input and generates N relevant suggestions.
    """
    
    def __init__(self):
        self.fact_processor = FactProcessor()
        
        # Initialize OpenAI with GPT-4o-mini
        self.llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.7,  # Higher temperature for more creative suggestions
            openai_api_key=os.getenv("OPENAI_API_KEY")
        )
        
        # Initialize Pydantic output parser
        self.output_parser = PydanticOutputParser(pydantic_object=RecommendationResponse)
        
        # Available tags
        self.available_tags = [
            "people",      # famiglia, amici, colleghi
            "dislikes",    # cose che odia/evitare
            "gifts",       # tutto ciò che può diventare regalo
            "activities",  # hobby, interessi, cose che ama fare
            "dates",       # posti dove andare, esperienze insieme
            "food",        # gusti alimentari, ristoranti, cucina
            "history"      # background, studi, passato
        ]

    def _format_facts_for_prompt(self, facts_by_tag: Dict[str, List[Dict[str, Any]]], selected_tags: List[str]) -> str:
        """
        Format facts organized by tags for inclusion in the AI prompt
        
        Args:
            facts_by_tag: Dictionary with facts organized by tags
            selected_tags: List of tags to include (if empty, include all)
            
        Returns:
            Formatted string with facts organized by hierarchical tags
        """
        if not selected_tags:
            selected_tags = self.available_tags
        
        formatted_facts = []
        
        for tag in selected_tags:
            if tag in facts_by_tag and facts_by_tag[tag]:
                formatted_facts.append(f"\n## {tag.upper()}")
                for fact in facts_by_tag[tag]:
                    fact_content = fact.get('fact', '')
                    sentiment = fact.get('sentiment', 'neutral')
                    formatted_facts.append(f"- {fact_content} ({sentiment})")
        
        return "\n".join(formatted_facts) if formatted_facts else "Nessun fatto disponibile per i tag selezionati."

    def generate_recommendations(self, user_id: str, selected_tags: Optional[List[str]] = None, count: int = 5) -> Dict[str, Any]:
        """
        Generate N personalized recommendations based on user facts and selected tags
        
        Args:
            user_id: User ID to generate recommendations for
            selected_tags: List of tags to focus on (if None, use all tags)
            count: Number of suggestions to generate (default 5)
            
        Returns:
            Dictionary with success status and generated suggestions
        """
        try:
            # Validate selected tags
            if selected_tags:
                selected_tags = [tag for tag in selected_tags if tag in self.available_tags]
            else:
                selected_tags = self.available_tags.copy()
            
            if not selected_tags:
                return {
                    'success': False,
                    'error': 'No valid tags provided',
                    'suggestions': []
                }
            
            # Get facts organized by tags
            facts_by_tag = self.fact_processor.get_facts_summary_by_tags(user_id)
            
            # Check if user has any facts
            total_facts = sum(len(facts) for facts in facts_by_tag.values())
            if total_facts == 0:
                return {
                    'success': False,
                    'error': 'No facts available for this user',
                    'suggestions': [],
                    'message': 'Aggiungi alcuni fatti sulla tua partner per ricevere suggerimenti personalizzati.'
                }
            
            # Format facts for prompt
            formatted_facts = self._format_facts_for_prompt(facts_by_tag, selected_tags)
            
            # Create system prompt for recommendation generation
            system_prompt = f"""
Sei un assistente AI specializzato nel generare suggerimenti personalizzati per relazioni romantiche.
Il tuo compito è creare {count} suggerimenti creativi e actionable basati sui fatti forniti dall'utente.

TAG DISPONIBILI:
- people: famiglia, amici, colleghi
- dislikes: cose che odia o da evitare  
- gifts: tutto ciò che può diventare regalo
- activities: hobby, interessi, cose che ama fare
- dates: posti dove andare, esperienze insieme
- food: gusti alimentari, ristoranti, cucina
- history: background, studi, passato

REGOLE PER I SUGGERIMENTI:
1. Ogni suggerimento deve essere una frase breve e actionable (massimo 200 caratteri)
2. Deve essere basato sui fatti forniti e rilevante per i tag selezionati
3. Deve essere pratico e realizzabile
4. Evita suggerimenti generici - sii specifico basandoti sui fatti
5. Considera sia gli aspetti positivi che quelli da evitare (dislikes)
6. Assegna massimo 3 tag per suggerimento, scegliendo i più rilevanti

ESEMPI DI BUONI SUGGERIMENTI:
- "Organizza una serata film Studio Ghibli con popcorn fatto in casa" (tags: ["activities", "food"])
- "Evita di arrivare in ritardo al vostro prossimo appuntamento" (tags: ["dislikes", "dates"])
- "Regalale un libro di cucina giapponese per il suo compleanno" (tags: ["gifts", "food"])

{self.output_parser.get_format_instructions()}
"""
            
            # Create user message with facts
            user_message = f"""
FATTI SULLA PARTNER (organizzati per tag):
{formatted_facts}

TAG SELEZIONATI: {', '.join(selected_tags)}

Genera {count} suggerimenti personalizzati basati su questi fatti, concentrandoti sui tag selezionati.
"""
            
            # Create messages for the LLM
            messages = [
                SystemMessage(content=system_prompt),
                HumanMessage(content=user_message)
            ]
            
            # Get response from GPT-4o-mini
            response = self.llm(messages)
            response_text = response.content.strip()
            
            # Parse the structured response
            try:
                parsed_response = self.output_parser.parse(response_text)
                suggestions = [
                    {
                        'sentence': suggestion.sentence,
                        'tags': suggestion.tags
                    }
                    for suggestion in parsed_response.suggestions
                ]
                
                return {
                    'success': True,
                    'suggestions': suggestions,
                    'count': len(suggestions),
                    'selected_tags': selected_tags,
                    'total_facts_used': total_facts
                }
                
            except Exception as parse_error:
                print(f"Error parsing AI response: {parse_error}")
                print(f"Raw response: {response_text}")
                
                # Fallback: try to extract suggestions manually
                return {
                    'success': False,
                    'error': 'Failed to parse AI response',
                    'raw_response': response_text,
                    'suggestions': []
                }
                
        except Exception as e:
            print(f"Error generating recommendations: {e}")
            return {
                'success': False,
                'error': str(e),
                'suggestions': []
            }

    def get_available_tags(self) -> List[str]:
        """
        Get list of available tags for recommendations
        
        Returns:
            List of available tag names
        """
        return self.available_tags.copy()

    def get_user_tag_stats(self, user_id: str) -> Dict[str, int]:
        """
        Get statistics about how many facts the user has for each tag
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with tag counts
        """
        try:
            facts_by_tag = self.fact_processor.get_facts_summary_by_tags(user_id)
            return {tag: len(facts) for tag, facts in facts_by_tag.items()}
        except Exception as e:
            print(f"Error getting tag stats: {e}")
            return {tag: 0 for tag in self.available_tags}
