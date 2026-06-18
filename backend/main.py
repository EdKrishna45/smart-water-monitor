from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import bcrypt
import models
import schemas
from database import engine, get_db
import uuid
from typing import List

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="HydroSense API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow Flutter Web
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

@app.post("/auth/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    if user.phone_number:
        db_phone = db.query(models.User).filter(models.User.phone_number == user.phone_number).first()
        if db_phone:
            raise HTTPException(status_code=400, detail="Phone number already registered")
    
    hashed_password = get_password_hash(user.password)
    new_user = models.User(email=user.email, phone_number=user.phone_number, hashed_password=hashed_password, name=user.name)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"uid": new_user.id, "email": new_user.email, "phone_number": new_user.phone_number, "name": new_user.name}

@app.post("/auth/login", response_model=schemas.UserResponse)
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    # Check if input matches email OR phone_number
    db_user = db.query(models.User).filter(
        (models.User.email == user.email_or_phone) | 
        (models.User.phone_number == user.email_or_phone)
    ).first()

    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid email/phone or password")
    
    return {"uid": db_user.id, "email": db_user.email, "phone_number": db_user.phone_number, "name": db_user.name}

@app.post("/auth/google", response_model=schemas.UserResponse)
def google_login(request: schemas.GoogleLoginRequest, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == request.email).first()
    if db_user:
        return {"uid": db_user.id, "email": db_user.email, "phone_number": db_user.phone_number, "name": db_user.name}
    
    import secrets
    dummy_password = secrets.token_urlsafe(16)
    hashed_password = get_password_hash(dummy_password)
    
    new_user = models.User(
        email=request.email,
        phone_number=None,
        hashed_password=hashed_password,
        name=request.name,
        auth_provider="google"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"uid": new_user.id, "email": new_user.email, "phone_number": new_user.phone_number, "name": new_user.name}

@app.post("/auth/forgot-password")
def forgot_password(request: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(
        (models.User.email == request.contact) | 
        (models.User.phone_number == request.contact)
    ).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="No account found with this email/phone.")
        
    # Send OTP Logic Here (Simulated)
    import random
    otp = str(random.randint(100000, 999999))
    return {"status": "success", "otp": otp}

@app.post("/auth/reset-password")
def reset_password(request: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(
        (models.User.email == request.contact) | 
        (models.User.phone_number == request.contact)
    ).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="No account found.")

    db_user.hashed_password = get_password_hash(request.new_password)
    db.commit()
    return {"status": "success", "message": "Password updated successfully"}

@app.post("/auth/change-password")
def change_password(request: schemas.ChangePasswordRequest, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.id == request.uid).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_user.hashed_password = get_password_hash(request.new_password)
    db.commit()
    return {"status": "success", "message": "Password updated successfully"}

@app.put("/auth/profile/{uid}", response_model=schemas.UserResponse)
def update_profile(uid: str, request: schemas.UserUpdate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.id == uid).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if request.name is not None:
        db_user.name = request.name
    if request.phone_number is not None:
        # Check if another user already has this phone number
        db_phone = db.query(models.User).filter(models.User.phone_number == request.phone_number, models.User.id != uid).first()
        if db_phone:
            raise HTTPException(status_code=400, detail="Phone number already registered")
        db_user.phone_number = request.phone_number
    if request.photo_base64 is not None:
        db_user.photo_url = request.photo_base64

    db.commit()
    db.refresh(db_user)
    return {"uid": db_user.id, "email": db_user.email, "phone_number": db_user.phone_number, "name": db_user.name, "photo_url": db_user.photo_url}

@app.get("/logs/{uid}", response_model=List[schemas.WaterLogResponse])
def get_logs(uid: str, db: Session = Depends(get_db)):
    logs = db.query(models.WaterLog).filter(models.WaterLog.user_id == uid).order_by(models.WaterLog.timestamp.desc()).all()
    return logs

@app.post("/logs/{uid}", response_model=schemas.WaterLogResponse)
def create_log(uid: str, log: schemas.WaterLogCreate, db: Session = Depends(get_db)):
    db_log = models.WaterLog(**log.model_dump(), user_id=uid)
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

@app.delete("/logs/{uid}/{log_id}")
def delete_log(uid: str, log_id: str, db: Session = Depends(get_db)):
    db_log = db.query(models.WaterLog).filter(models.WaterLog.id == log_id, models.WaterLog.user_id == uid).first()
    if not db_log:
        raise HTTPException(status_code=404, detail="Log not found")
    
    db.delete(db_log)
    db.commit()
    return {"status": "success"}

@app.get("/")
def root():
    return {"message": "HydroSense Backend is running!"}
