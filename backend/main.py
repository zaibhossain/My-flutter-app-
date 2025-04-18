import os
import torch
import clip
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import shutil
import logging

app = FastAPI()

# Allow Flutter to connect (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize CLIP model
device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

UPLOAD_DIR = "uploaded_images"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# Use specific personality-driven labels
possible_labels = [
    "sports enthusiast",
    "fitness fanatic",
    "outdoor adventurer",
    "hiker",
    "cyclist",
    "runner",
    "yoga practitioner",
    "gym-goer",
    "creative thinker",
    "artist",
    "photographer",
    "musician",
    "music lover",
    "book lover",
    "writer",
    "tech-savvy",
    "gamer",
    "programmer",
    "collector",
    "fashion-forward",
    "foodie",
    "chef",
    "traveler",
    "nature lover",
    "homebody",
    "movie buff",
    "gardener",
    "DIY enthusiast",
    "board game player",
    "car enthusiast",
    "pet lover",
    "social butterfly",
    "party planner",
    "volunteer",
    "teacher",
    "researcher",
    "science enthusiast",
    "history buff",
    "language learner",
    "puzzle solver"
]

# Precompute tokenized labels once during server startup
tokenized_labels = clip.tokenize(possible_labels).to(device)

@app.post("/upload/")
async def upload_image(image: UploadFile = File(...)):
    try:
        file_path = os.path.join(UPLOAD_DIR, image.filename)
        
        # Save the uploaded image
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Run AI analysis
        img = preprocess(Image.open(file_path)).unsqueeze(0).to(device)

        with torch.no_grad():
            # Perform the CLIP analysis using precomputed tokenized labels
            logits_per_image, _ = model(img, tokenized_labels)
            probs = logits_per_image.softmax(dim=-1).cpu().numpy()

        # Sort and return the top 3 matches
        top_probs = sorted(zip(possible_labels, probs[0]), key=lambda x: x[1], reverse=True)
        results = [{"label": label, "probability": float(prob)} for label, prob in top_probs[:3]]

        return JSONResponse(content={"image": image.filename, "results": results})
    except Exception as e:
        logging.error(f"Error during upload or analysis: {str(e)}")
        return JSONResponse(status_code=500, content={"error": "Failed to process image."})