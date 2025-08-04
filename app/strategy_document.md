# Relationship AI App - Strategy Document

## Concept Core
**"Relationship Intelligence"** - L'app che trasforma piccole osservazioni casuali in insights actionable per migliorare le relazioni romantiche.

**Valore principale**: Ricorda quello che dimentichi e suggerisce quello che non avresti mai pensato.

---

## User Experience Design

### Input Ultra-Semplificato
**Principio**: Per l'utente deve essere estremamente facile inserire dati.

**Metodi di input:**
- **Chat conversazionale**: input principale sia per facts ("oggi ha detto che...") che per query ("cosa regalo?")
- **Quick input widget** sempre visibile in home screen
- **Voice notes** per registrazioni al volo
- **Quick tags predefiniti** + testo libero

**Esempi input naturali:**
- "Odia quando sono in ritardo"
- "Ama i film di Studio Ghibli" 
- "Compleanno mamma 15 marzo"
- "Vuole imparare ceramica"

### Core Features

**1. Chat Intelligence**
- Centro nevralgico dell'app
- Input conversazionale per facts
- Query dirette ("cosa posso regalare?", "dove la porto?")
- Risposte contestuali basate su tutti i facts storici

**2. Swipeable Random Cards**
- Cards quadrate swipabili orizzontalmente all'infinito
- L'AI genera nuove cards man mano che si scrolla
- **Modalità multiple:**
  - General feed: mix di insights, reminder, suggestions
  - Focused modes: solo regali, solo date ideas, solo "things to remember"
- Pattern coinvolgente tipo TikTok ma per la relazione

**3. Smart Suggestions**
- Gift suggestions basate su interessi + occasioni
- Date ideas personalizzate per mood/stagione
- Calendar reminder eventi importanti
- Surprise planning assistant

### Onboarding Gamificato
**Problema risolto**: Evitare il "blocco del foglio bianco" post-download.

**Soluzione**: Questionario interattivo stile personality quiz
- Domande veloci con visual appealing
- Mix di multiple choice + slider + multi-select
- Progress bar, sempre possibilità di skip
- Completa una baseline del partner in 2-3 minuti

**Esempi dimensioni:**
- Personalità: Introverso/Estroverso, Spontaneo/Pianificatore
- Lifestyle: Serata ideale, Tipo regali preferiti, Gestione conflitti
- Quick facts guidati: Cucina preferita, Budget regali, Hobby

---

## Architettura Tecnica

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase ecosystem
- **AI Processing**: Firebase Cloud Functions (Python + LangChain)
- **UI Components**: `flutter_card_swiper` per le swipeable cards

### Database Architecture
**Solo Firestore** (no SQLite locale)
- L'app non funziona offline (dipende da AI)
- Firestore ha già caching automatico nativo
- Zero complessità di sincronizzazione
- Meno codice da mantenere

### Data Structure

**Fact Structure:**
```json
{
  "fact": "Ama quel ristorante giapponese in centro",
  "date": "2025-01-15",
  "tags": ["food", "dates"],
  "sentiment": "positive"
}
```

**Fact Structure con Gerarchia:**
```json
{
  "fact": "Ha litigato con Sara, amica del liceo, per il matrimonio",
  "primary_tag": "people",
  "secondary_tags": ["history"],
  "sub_tags": {
    "person_name": "Sara",
    "relationship_type": "amica",
    "context": "conflict",
    "period": "liceo"
  },
  "date": "2025-01-15"
}
```

**Esempi pratici con gerarchia:**
```json
{
  "fact": "Ama cucinare ricette della nonna",
  "primary_tag": "activities",
  "secondary_tags": ["food", "history"],
  "date": "2025-01-15"
},
{
  "fact": "Odia quel ristorante dove la portavano da bambina",
  "primary_tag": "dislikes",
  "secondary_tags": ["food", "history"],
  "date": "2025-01-10"
},
{
  "fact": "Ha studiato architettura alla Bocconi",
  "primary_tag": "history",
  "secondary_tags": [],
  "sub_tags": {
    "category": "education",
    "period": "university"
  },
  "date": "2025-01-08"
},
{
  "fact": "Le piace ancora disegnare edifici nel tempo libero",
  "primary_tag": "activities",
  "secondary_tags": ["history"],
  "sub_tags": {
    "origin": "studies_architecture"
  },
  "date": "2025-01-12"
}
```

**Tag System con Gerarchia:**

**Core Tags (7 tags con priorità):**
1. `people` - famiglia, amici, colleghi (massima priorità)
2. `dislikes` - cose che odia/evitare (alta priorità)
3. `gifts` - tutto ciò che può diventare regalo
4. `activities` - hobby, interessi, cose che ama fare
5. `dates` - posti dove andare, esperienze insieme
6. `food` - gusti alimentari, ristoranti, cucina
7. `history` - background, studi, passato (bassa priorità)

**Sistema Gerarchico:**
- **Primary tag**: determina dove va nel prompt (sezione principale)
- **Secondary tags**: forniscono context aggiuntivo

**Partner Profile (da onboarding):**
```json
{
  "personality": {
    "introvert_extrovert": 7,
    "spontaneous_planner": 3,
    "adventurous_traditional": 8
  },
  "preferences": {
    "gift_style": "experiences",
    "cuisine": ["japanese", "italian"],
    "budget_comfort": "mid_range"
  },
  "facts": [...]
}
```

### AI Strategy
**Prompt Organization**: Facts organizzati per tag nel prompt AI

**Esempio struttura prompt per chat generale:**
```
RELATIONSHIP FACTS BY CATEGORY:

PEOPLE & RELATIONSHIPS:

SARA (amica, dal liceo):
- Ha litigato con lei per il fatto che non l'ha invitata al matrimonio [conflict, storia dal liceo, 15/01]
- Aveva organizzato quella festa sorpresa l'anno scorso [positive, 12/03]

PAPÀ (famiglia):
- Ha problemi di salute, lei si preoccupa molto [health_concern, 10/01]
- Compie 65 anni a marzo [birthday, 05/01]

MARCO (collega):
- Le ha fatto complimenti per il progetto [work_success, 14/01]
- È il suo manager diretto [work_context, 20/12]

DISLIKES & THINGS TO AVOID:
- Odia quando sono in ritardo
- Non sopporta quel ristorante dove la portavano da bambina [food, history]
- Odia i posti troppo affollati

GIFTS & INTERESTS:
- Vuole imparare ceramica
- Ama i film Studio Ghibli
- Colleziona vinili vintage
- Le piace ancora disegnare edifici [collegato a studi architettura]

ACTIVITIES & DATES:
- Ama passeggiate al tramonto
- Preferisce cinema d'essai
- Ama cucinare ricette della nonna [food, history]

FOOD & PREFERENCES:
- Ama quel ristorante giapponese in centro
- Ordina sempre pizza margherita

BACKGROUND & HISTORY:
- Ha studiato architettura alla Bocconi [education, university]
- È cresciuta a Milano centro [childhood]
- Ha fatto erasmus a Berlino, ama quella città [travel, education]
```

**Query specifiche**: subset filtrato per tag
- **Gift suggestions**: solo facts con tag "gifts" + "activities" + profilo personalità
- **Date ideas**: solo facts con tag "dates" + "activities" + "food" 
- **Random insights**: mix bilanciato di tutti i tag

**Scalabilità**: 50-200 facts per coppia, facilmente gestibili in prompt (RAG overkill per questi volumi)

---

## Firebase Setup

### Core Services
- **Authentication**: Email/password, Google, Apple sign-in
- **Firestore**: Storage facts e profili partner
- **Cloud Functions**: AI processing (Python + LangChain)

### Security & Privacy
- **Dati non sensibili**: focus su preferenze casual (regali, cibi, hobby)
- **Firebase security rules** per protezione dati utente
- **Encryption** automatica Firebase

---

## Development Priorities

### MVP (V1)
1. **Core chat** con input facts e query
2. **Onboarding** questionario interattivo
3. **Basic suggestions** (regali, date ideas)
4. **Swipeable cards** con insights random

### Future Features (V2+)
1. **Advanced AI insights** (pattern recognition, mood tracking)
2. **Calendar integration** per reminder automatici
3. **Surprise planning** assistant avanzato
4. **Relationship health** scoring

---

## Success Metrics
- **Engagement**: Frequenza input facts settimanali
- **Retention**: Usage delle suggestions generate
- **Value**: Feedback positivo su gift/date suggestions
- **Growth**: Organic sharing tra coppie