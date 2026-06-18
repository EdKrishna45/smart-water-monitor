from sqlalchemy import Column, Integer, String, Float, DateTime
from datetime import datetime
from database import Base
import uuid

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    phone_number = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String)
    name = Column(String)
    photo_url = Column(String, nullable=True)
    auth_provider = Column(String, default="email")

class WaterLog(Base):
    __tablename__ = "water_logs"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, index=True)
    rawTurbidity = Column(Float)
    trueTurbidity = Column(Float)
    ph = Column(Float)
    temperature = Column(Float)
    lightCondition = Column(String)
    wqi = Column(Float)
    status = Column(String)
    advice = Column(String)
    waterCategory = Column(String)
    waterLevel = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
