import os
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from transformers import pipeline
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("API_KEY")

app = FastAPI(title="AI Inference API")

classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

class InferenceRequest(BaseModel):
    text: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(request: InferenceRequest, x_api_key: str = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    result = classifier(request.text)[0]
    return {"label": result["label"], "confidence": round(result["score"], 4)}
