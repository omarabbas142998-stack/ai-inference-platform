from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline

app = FastAPI(title="AI Inference API")

# Loaded once at startup, reused for every request
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

class InferenceRequest(BaseModel):
    text: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(request: InferenceRequest):
    result = classifier(request.text)[0]
    return {"label": result["label"], "confidence": round(result["score"], 4)}
