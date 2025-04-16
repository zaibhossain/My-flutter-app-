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

# Define possible labels for the analysis
possible_labels = [
    "a birthday cake", "flowers", "shoes", "a toy", "a watch", "apple",
    "perfume", "jewelry", "sports equipment", "a book", "chocolates"
]

@app.post("/upload/")
async def upload_image(image: UploadFile = File(...)):
    try:
        file_path = os.path.join(UPLOAD_DIR, image.filename)
        
        # Save the uploaded image
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Run AI analysis
        img = preprocess(Image.open(file_path)).unsqueeze(0).to(device)
        text = clip.tokenize(possible_labels).to(device)

        with torch.no_grad():
            # Perform the CLIP analysis
            logits_per_image, _ = model(img, text)
            probs = logits_per_image.softmax(dim=-1).cpu().numpy()

        # Sort and return the top 3 matches
        top_probs = sorted(zip(possible_labels, probs[0]), key=lambda x: x[1], reverse=True)
        results = [{"label": label, "probability": float(prob)} for label, prob in top_probs[:3]]

        return JSONResponse(content={"image": image.filename, "results": results})
    except Exception as e:
        logging.error(f"Error during upload or analysis: {str(e)}")
        return JSONResponse(status_code=500, content={"error": "Failed to process image."})

@app.get("/images/")
def get_uploaded_images():
    files = os.listdir(UPLOAD_DIR)
    return {"images": [f"{UPLOAD_DIR}/{file}" for file in files]}

@app.delete("/delete/{filename}")
async def delete_image(filename: str):
    try:
        file_path = os.path.join(UPLOAD_DIR, filename)

        if os.path.exists(file_path):
            os.remove(file_path)
            logging.info(f"Successfully deleted image {filename}")
            return JSONResponse(content={"message": f"Image {filename} deleted successfully."})
        else:
            logging.error(f"Attempted to delete non-existent image {filename}")
            return JSONResponse(status_code=404, content={"error": f"Image {filename} not found."})
    except Exception as e:
        logging.error(f"Failed to delete image {filename}: {str(e)}")
        return JSONResponse(status_code=500, content={"error": "Failed to delete image."})