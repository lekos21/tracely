import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv
from fact_processor import FactProcessor
from firebase_admin import firestore

# Load environment variables
load_dotenv()

# Initialize OpenAI with GPT-5 nano - optimized for latency
llm = ChatOpenAI(
    model="gpt-5-nano",  
    openai_api_key=os.getenv("OPENAI_API_KEY"),
    timeout=15  # 15 second timeout to prevent hanging
)

# Fai una query
response = llm.invoke("Dimmi una curiosità su Marte in 2 frasi.")
print(response.content)
