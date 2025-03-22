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

# Get all user profiles
@app.get("/users/")
def get_all_users():
    return {"users": list(user_profiles.values())}

# Delete user profile
@app.delete("/user/{user_id}")
async def delete_user_profile(user_id: int):
    if user_id not in user_profiles:
        raise HTTPException(status_code=404, detail="User not found")
    
    del user_profiles[user_id]  # Remove user from memory
    return {"message": f"User {user_id} deleted successfully"}

# Update user profile (PUT request)
@app.put("/user/{user_id}")
async def update_user_profile(user_id: int, user_profile: UserProfile):
    if user_id not in user_profiles:
        raise HTTPException(status_code=404, detail="User not found")
    updated_profile = user_profile.dict()
    updated_profile["user_id"] = user_id
    user_profiles[user_id] = updated_profile  # Update the user profile
    return {"message": "User profile updated", "data": updated_profile}