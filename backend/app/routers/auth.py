"""회원가입 / 로그인 / 내 정보."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import LoginRequest, Token, UserCreate, UserOut
from app.security import create_access_token, get_current_user, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["회원"])


@router.post("/signup", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def signup(data: UserCreate, db: Session = Depends(get_db)):
    exists = db.scalar(
        select(User).where(or_(User.email == data.email, User.student_id == data.student_id))
    )
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "이미 가입된 이메일 또는 학번입니다.")
    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        name=data.name,
        student_id=data.student_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == data.email))
    if user is None or not verify_password(data.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다.")
    return Token(access_token=create_access_token(user.id))


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
