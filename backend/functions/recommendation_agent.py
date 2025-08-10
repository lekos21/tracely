from langchain_anthropic import ChatAnthropic
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
    effort: int = Field(description="Livello di sforzo richiesto da 1 (minimo) a 3 (massimo)", ge=1, le=3)

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
        
        # Initialize Anthropic with Claude Sonnet
        self.llm = ChatAnthropic(
            model="claude-sonnet-4-20250514",
            temperature=0.8,  # Higher temperature for more creative suggestions
            anthropic_api_key=os.getenv("ANTHROPIC_API_KEY")
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

    def generate_recommendations(self, user_id: str, selected_tags: Optional[List[str]] = None, count: int = 8) -> Dict[str, Any]:
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
Sei un assistente AI creativo e intuitivo, specializzato nel trasformare piccoli dettagli in gesti d'amore memorabili.
Il tuo superpotere è leggere tra le righe dei fatti e immaginare modi sorprendenti per far sentire speciale la persona amata.

Crea {count} suggerimenti bilanciati tra diversi livelli di sforzo - pensa come un detective dell'amore che scopre opportunità nascoste!

TAG DISPONIBILI:
- people: il suo mondo sociale - famiglia, amici, colleghi che contano
- dislikes: cose da evitare
- gifts: tesori che potrebbero farla sorridere o commuovere
- activities: passioni, hobby
- dates: avventure insieme - luoghi, esperienze, momenti da creare
- food: tutto ciò che riguarda il cibo
- history: il suo passato

LIVELLI DI SFORZO (IMPORTANTE):
- EFFORT 1: Gesti semplici, immediati, che richiedono pochi minuti (es: mandare un messaggio, comprare qualcosa di piccolo, ricordare una preferenza)
- EFFORT 2: Attività che richiedono pianificazione moderata o qualche ora (es: cucinare qualcosa di speciale, organizzare una serata, fare un piccolo regalo personalizzato)
- EFFORT 3: Progetti più impegnativi che richiedono giorni di preparazione o budget significativo (es: viaggi, eventi elaborati, regali costosi)

STRATEGIA DI BILANCIAMENTO:
- Circa 40% dei suggerimenti dovrebbero essere EFFORT 1 (gesti quotidiani dolci)
- Circa 40% dei suggerimenti dovrebbero essere EFFORT 2 (momenti speciali pianificati)
- Circa 20% dei suggerimenti dovrebbero essere EFFORT 3 (grandi gesti memorabili)

PRINCIPI GUIDA:
1. NON combinare troppi fatti insieme - spesso un singolo fatto può generare un ottimo suggerimento
2. Varia tra suggerimenti "diretti" (basati sui fatti) e "creativi" (ispirati dai fatti)
3. Ogni suggerimento deve essere actionable e specifico (max 200 caratteri)
4. Trasforma i DISLIKES in azioni POSITIVE che prevengono il problema
5. Assegna max 3 tag che catturano l'essenza del gesto
6. Assegna sempre un effort score da 1 a 3

ESEMPI CON EFFORT SCORE:
- "Mandagli un messaggio dolce quando sai che ha una giornata difficile" (tags: ["people"], effort: 1)
- "Prepara la sua colazione preferita nel weekend" (tags: ["food"], effort: 2)
- "Organizza una sorpresa con tutti i suoi amici per il compleanno" (tags: ["people", "dates"], effort: 3)
- "Tieni sempre delle mentine in borsa dato che odia l'alito cattivo" (tags: ["dislikes"], effort: 1)

ESPLORA ANCHE OLTRE I FATTI:
- Se ama qualcosa, pensa a categorie correlate
- Se ha una passione, immagina modi creativi per supportarla
- Se ha un background specifico, connettilo a esperienze nuove

{self.output_parser.get_format_instructions()}
"""
            
            # Create user message with facts
            user_message = f"""
🔍 CONTESTO E IDEE GENERALI:
{formatted_facts}

✨ FOCUS: {', '.join(selected_tags)}

Ora è il momento di brillare! Analizza questi indizi come un detective dell'amore e crea {count} suggerimenti che la faranno sentire davvero vista e amata. 
Pensa a gesti che nessun altro farebbe perché solo tu conosci questi dettagli su di lei.

Sii creativo, sii specifico, sii magico! 💫
"""
            
            # Create messages for the LLM
            messages = [
                SystemMessage(content=system_prompt),
                HumanMessage(content=user_message)
            ]
            
            # Get response from Claude Sonnet
            response = self.llm(messages)
            response_text = response.content.strip()
            
            # Debug logging
            print(f"DEBUG: Raw AI response: {response_text[:500]}...")
            
            # Parse the structured response
            try:
                parsed_response = self.output_parser.parse(response_text)
                print(f"DEBUG: Parsed response has {len(parsed_response.suggestions)} suggestions")
                suggestions = []
                for i, suggestion in enumerate(parsed_response.suggestions):
                    suggestion_dict = {
                        'sentence': suggestion.sentence,
                        'tags': suggestion.tags,
                        'effort': suggestion.effort
                    }
                    suggestions.append(suggestion_dict)
                    print(f"DEBUG: Suggestion {i+1}: effort={suggestion.effort}, tags={suggestion.tags}")
                
                print(f"DEBUG: Final suggestions array has {len(suggestions)} items")
                
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
