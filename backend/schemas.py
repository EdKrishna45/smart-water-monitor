from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: str
    phone_number: Optional[str] = None
    password: str
    name: str

class UserLogin(BaseModel):
    email_or_phone: str
    password: str

class GoogleLoginRequest(BaseModel):
    email: str
    name: str
    google_id: str

class UserResponse(BaseModel):
    uid: str
    email: str
    phone_number: Optional[str] = None
    name: str
    photo_url: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    uid: str
    new_password: str

class ForgotPasswordRequest(BaseModel):
    contact: str

class ResetPasswordRequest(BaseModel):
    contact: str
    new_password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    photo_base64: Optional[str] = None

class WaterLogBase(BaseModel):
    rawTurbidity: float
    trueTurbidity: float
    ph: float
    temperature: float
    lightCondition: str
    wqi: float
    status: str
    advice: str
    waterCategory: str
    waterLevel: str

class WaterLogCreate(WaterLogBase):
    pass

class WaterLogResponse(WaterLogBase):
    id: str
    user_id: str
    timestamp: datetime

    class Config:
        from_attributes = True
