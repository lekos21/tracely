from firebase_admin import firestore
from typing import Dict, List, Any
import json
import re

class AIService:
    """
    AI Service for processing relationship facts and generating insights.
    This is a simplified version for MVP - will be enhanced with LangChain later.
    """
    
    def __init__(self):
        self.db = firestore.client()
        
        # Tag keywords for fact categorization
        self.tag_keywords = {
            'people': ['amico', 'amica', 'famiglia', 'mamma', 'papà', 'sorella', 'fratello', 'collega', 'capo'],
            'dislikes': ['odia', 'non sopporta', 'detesta', 'non piace', 'fastidio', 'irritante'],
            'gifts': ['regalo', 'vuole', 'desidera', 'sogna', 'colleziona', 'ama', 'interessato'],
            'activities': ['hobby', 'sport', 'passione', 'tempo libero', 'fare', 'giocare', 'leggere'],
            'dates': ['ristorante', 'cinema', 'teatro', 'viaggio', 'posto', 'locale', 'bar'],
            'food': ['cibo', 'cucina', 'ristorante', 'pizza', 'pasta', 'dolce', 'mangiare', 'bere'],
            'history': ['studiato', 'università', 'lavoro', 'passato', 'bambina', 'cresciuta', 'famiglia']
        }
    
    def analyze_fact(self, fact_text: str) -> Dict[str, Any]:
        """
        Analyze a fact and extract tags, sentiment, and categorization.
        For MVP, uses simple keyword matching. Will be replaced with LLM later.
        """
        fact_lower = fact_text.lower()
        
        # Determine primary tag
        primary_tag = 'general'
        secondary_tags = []
        
        for tag, keywords in self.tag_keywords.items():
            if any(keyword in fact_lower for keyword in keywords):
                if primary_tag == 'general':
                    primary_tag = tag
                else:
                    secondary_tags.append(tag)
        
        # Simple sentiment analysis
        sentiment = 'neutral'
        if any(word in fact_lower for word in ['ama', 'piace', 'felice', 'contenta', 'bello']):
            sentiment = 'positive'
        elif any(word in fact_lower for word in ['odia', 'non piace', 'triste', 'arrabbiata', 'male']):
            sentiment = 'negative'
        
        # Extract sub_tags (names, places, etc.)
        sub_tags = {}
        
        # Simple name extraction (capitalized words)
        names = re.findall(r'\b[A-Z][a-z]+\b', fact_text)
        if names:
            sub_tags['mentioned_names'] = names
        
        return {
            'primary_tag': primary_tag,
            'secondary_tags': secondary_tags,
            'sub_tags': sub_tags,
            'sentiment': sentiment
        }
    
    def get_user_facts(self, user_id: str) -> List[Dict[str, Any]]:
        """Retrieve all facts for a user from Firestore"""
        try:
            facts_ref = self.db.collection('users').document(user_id).collection('facts')
            facts = facts_ref.order_by('date', direction=firestore.Query.DESCENDING).limit(50).stream()
            
            return [{'id': fact.id, **fact.to_dict()} for fact in facts]
        except Exception as e:
            print(f"Error retrieving facts: {e}")
            return []
    
    def get_partner_profile(self, user_id: str) -> Dict[str, Any]:
        """Retrieve partner profile from onboarding"""
        try:
            user_doc = self.db.collection('users').document(user_id).get()
            if user_doc.exists:
                return user_doc.to_dict().get('partner_profile', {})
            return {}
        except Exception as e:
            print(f"Error retrieving profile: {e}")
            return {}
    
    def process_query(self, user_id: str, query: str) -> str:
        """
        Process a user query and return AI-generated response.
        For MVP, uses template-based responses. Will be enhanced with LLM later.
        """
        query_lower = query.lower()
        facts = self.get_user_facts(user_id)
        profile = self.get_partner_profile(user_id)
        
        # Gift suggestions
        if any(word in query_lower for word in ['regalo', 'regalare', 'gift', 'cosa comprare']):
            return self._generate_gift_suggestions(facts, profile)
        
        # Date ideas
        elif any(word in query_lower for word in ['dove andare', 'appuntamento', 'date', 'uscire']):
            return self._generate_date_suggestions(facts, profile)
        
        # General relationship advice
        else:
            return self._generate_general_response(facts, profile, query)
    
    def _generate_gift_suggestions(self, facts: List[Dict], profile: Dict) -> str:
        """Generate gift suggestions based on facts and profile"""
        gift_facts = [f for f in facts if f.get('primary_tag') == 'gifts' or 'gifts' in f.get('secondary_tags', [])]
        activity_facts = [f for f in facts if f.get('primary_tag') == 'activities']
        
        suggestions = []
        
        # Based on facts
        for fact in gift_facts[:3]:
            fact_text = fact.get('fact', '')
            if 'ceramica' in fact_text.lower():
                suggestions.append("🏺 Un corso di ceramica o kit per ceramica fai-da-te")
            elif 'vinili' in fact_text.lower():
                suggestions.append("🎵 Un vinile vintage del suo artista preferito")
            elif 'ghibli' in fact_text.lower():
                suggestions.append("🎬 Merchandise Studio Ghibli o box set dei film")
        
        # Based on activities
        for fact in activity_facts[:2]:
            fact_text = fact.get('fact', '')
            if 'disegnare' in fact_text.lower():
                suggestions.append("✏️ Set di matite professionali per disegno")
            elif 'cucinare' in fact_text.lower():
                suggestions.append("👩‍🍳 Libro di ricette della tradizione italiana")
        
        if not suggestions:
            suggestions = [
                "🎁 Qualcosa legato ai suoi hobby preferiti",
                "📚 Un libro del suo genere preferito",
                "🌸 Un'esperienza che potete condividere insieme"
            ]
        
        return "Ecco alcune idee regalo basate su quello che mi hai raccontato:\n\n" + "\n".join(suggestions)
    
    def _generate_date_suggestions(self, facts: List[Dict], profile: Dict) -> str:
        """Generate date suggestions based on facts and profile"""
        date_facts = [f for f in facts if f.get('primary_tag') == 'dates' or 'dates' in f.get('secondary_tags', [])]
        food_facts = [f for f in facts if f.get('primary_tag') == 'food']
        
        suggestions = []
        
        # Based on facts
        for fact in date_facts[:2]:
            fact_text = fact.get('fact', '')
            if 'tramonto' in fact_text.lower():
                suggestions.append("🌅 Una passeggiata al tramonto in un posto speciale")
            elif 'cinema' in fact_text.lower():
                suggestions.append("🎬 Cinema d'essai per vedere un film indipendente")
        
        for fact in food_facts[:2]:
            fact_text = fact.get('fact', '')
            if 'giapponese' in fact_text.lower():
                suggestions.append("🍣 Cena in quel ristorante giapponese che ama")
            elif 'cucinare' in fact_text.lower():
                suggestions.append("👩‍🍳 Cucinare insieme una ricetta speciale")
        
        if not suggestions:
            suggestions = [
                "🍽️ Una cena in un posto nuovo da scoprire insieme",
                "🎨 Un'attività creativa che potete fare insieme",
                "🌳 Una gita fuori porta in un posto tranquillo"
            ]
        
        return "Ecco alcune idee per il vostro prossimo appuntamento:\n\n" + "\n".join(suggestions)
    
    def _generate_general_response(self, facts: List[Dict], profile: Dict, query: str) -> str:
        """Generate general response based on context"""
        recent_facts = facts[:5]
        
        if recent_facts:
            return f"Basandomi su quello che mi hai raccontato recentemente, ti suggerisco di considerare i suoi interessi attuali. Ricorda che {recent_facts[0].get('fact', '')}. Vuoi che ti dia suggerimenti più specifici per regali o appuntamenti?"
        else:
            return "Dimmi di più su di lei! Cosa le piace fare? Quali sono i suoi hobby? Più mi racconti, meglio posso aiutarti con suggerimenti personalizzati."
    
    def generate_cards(self, user_id: str, card_type: str, count: int) -> List[Dict[str, Any]]:
        """
        Generate swipeable cards with insights, suggestions, or reminders.
        For MVP, generates template-based cards. Will be enhanced with AI later.
        """
        facts = self.get_user_facts(user_id)
        profile = self.get_partner_profile(user_id)
        
        cards = []
        
        if card_type == 'gifts' or card_type == 'mixed':
            cards.extend(self._generate_gift_cards(facts, profile))
        
        if card_type == 'dates' or card_type == 'mixed':
            cards.extend(self._generate_date_cards(facts, profile))
        
        if card_type == 'insights' or card_type == 'mixed':
            cards.extend(self._generate_insight_cards(facts, profile))
        
        # Ensure we have enough cards
        while len(cards) < count:
            cards.append({
                'type': 'tip',
                'title': 'Consiglio del giorno',
                'content': 'Ricorda di ascoltare attivamente quando ti parla. I piccoli dettagli fanno la differenza!',
                'icon': '💡'
            })
        
        return cards[:count]
    
    def _generate_gift_cards(self, facts: List[Dict], profile: Dict) -> List[Dict[str, Any]]:
        """Generate gift suggestion cards"""
        return [
            {
                'type': 'gift',
                'title': 'Idea Regalo',
                'content': 'Basandoti sui suoi interessi, potresti considerare qualcosa di creativo che possa fare insieme a te.',
                'icon': '🎁'
            }
        ]
    
    def _generate_date_cards(self, facts: List[Dict], profile: Dict) -> List[Dict[str, Any]]:
        """Generate date suggestion cards"""
        return [
            {
                'type': 'date',
                'title': 'Appuntamento Speciale',
                'content': 'Che ne dici di una serata diversa dal solito? Prova qualcosa che rifletta i suoi gusti.',
                'icon': '💕'
            }
        ]
    
    def _generate_insight_cards(self, facts: List[Dict], profile: Dict) -> List[Dict[str, Any]]:
        """Generate relationship insight cards"""
        return [
            {
                'type': 'insight',
                'title': 'Ricorda',
                'content': 'Le piccole attenzioni quotidiane valgono più dei grandi gesti occasionali.',
                'icon': '💭'
            }
        ]
