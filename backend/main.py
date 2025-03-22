from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# User profile data model (user_id removed)
class UserProfile(BaseModel):
    name: str
    interests: str  
    gift_preferences: str  

# In-memory "database" to store user profiles
user_profiles = {}

# Create user profile (ID is generated automatically)
@app.post("/user/")
async def create_user_profile(user_profile: UserProfile):
    user_id = len(user_profiles) + 1  # Generate a new user_id

    user_profile_dict = user_profile.dict()
    user_profile_dict["user_id"] = user_id  # Assign generated ID

    user_profiles[user_id] = user_profile_dict  # Store in dictionary

    return {"message": "User profile created", "data": user_profile_dict}

# Get user profile
@app.get("/user/{user_id}")
def get_user_profile(user_id: int):
    if user_id not in user_profiles:
        raise HTTPException(status_code=404, detail="User not found")
    return user_profiles[user_id]
