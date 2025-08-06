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

Crea {count} suggerimenti o reminder che vanno oltre l'ovvio - pensa come un detective dell'amore che scopre opportunità nascoste!

TAG DISPONIBILI (pensa a questi come ingredienti per la magia):
- people: il suo mondo sociale - famiglia, amici, colleghi che contano
- dislikes: cose da evitare
- gifts: tesori che potrebbero farla sorridere o commuovere
- activities: passioni, hobby
- dates: avventure insieme - luoghi, esperienze, momenti da creare
- food: tutto ciò che riguarda il cibo
- history: il suo passato
- general: idee generali


LA TUA MISSIONE CREATIVA:
1. Ogni suggerimento deve essere un piccolo capolavoro di premura (max 200 caratteri)
2. Scava nei dettagli nascosti - cosa rivela davvero questo fatto su di lei?
3. Pensa a gesti che la sorprenderebbero perché mostri di aver davvero ascoltato
4. Combina elementi inaspettati - mescola i tag in modi creativi!
5. Trasforma i DISLIKES in azioni POSITIVE che prevengono il problema
6. Assegna max 3 tag, scegliendo quelli che catturano l'essenza del gesto

ESEMPI:
- "Crea una playlist delle sue canzoni preferite per quando è stressata dal lavoro" (tags: ["activities", "people"])
- "Porta sempre con te delle mentine, dato che odia l'alito cattivo" (tags: ["dislikes", "gifts"])
- "Organizza una cena a tema del suo paese d'origine con i suoi genitori" (tags: ["food", "people", "history"])

Non limitarti solo ai fatti inseriti! Usa questi come ISPIRAZIONE per:
- Categorie simili (ama Studio Ghibli → potrebbe amare anime, Giappone, arte)  
- Pattern nascosti (3 fatti su cucina → probabilmente ama cucinare insieme)
- Connessioni creative (studia architettura + ama disegnare → museo design)

REGOLA D'ORO: Per ogni suggerimento "diretto" dai fatti, crea un suggerimento "creativo" che esce un po' dal seminato.

Ricorda di essere anche realistico, non mischiare troppe cose tutte insieme altrimenti diventa difficile fare tutto, alterna cose più impegnative a cose più semplici ma rimanendo ragionevole.

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
