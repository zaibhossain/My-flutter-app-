import torch
import clip
from PIL import Image

device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

# Load and preprocess the image
image = preprocess(Image.open(r"C:\Users\zaib0\Pictures\istockphoto-184276818-612x612.jpg")).unsqueeze(0).to(device)


# Define possible labels (descriptions/keywords to test against)
possible_labels = [
    "a birthday cake", "flowers", "shoes", "a toy", "a watch", "apple",
    "perfume", "jewelry", "sports equipment", "a book", "chocolates"
]
text = clip.tokenize(possible_labels).to(device)

# Run the model
with torch.no_grad():
    image_features = model.encode_image(image)
    text_features = model.encode_text(text)

    logits_per_image, _ = model(image, text)
    probs = logits_per_image.softmax(dim=-1).cpu().numpy()

# Show top matches
top_probs = sorted(zip(possible_labels, probs[0]), key=lambda x: x[1], reverse=True)
for label, prob in top_probs[:3]:
    print(f"{label}: {prob:.2f}")
