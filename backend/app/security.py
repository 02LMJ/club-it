"""비밀번호 암호화, 로그인 토큰(JWT), 현재 사용자/권한 확인."""
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Club, Membership, User

ALGORITHM = "HS256"
bearer = HTTPBearer(auto_error=False)


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except ValueError:
        return False


def create_access_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    return jwt.encode({"sub": str(user_id), "exp": expire}, settings.JWT_SECRET, algorithm=ALGORITHM)


def get_current_user(
    cred: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if cred is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "로그인이 필요합니다.")
    try:
        payload = jwt.decode(cred.credentials, settings.JWT_SECRET, algorithms=[ALGORITHM])
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "토큰이 올바르지 않거나 만료되었습니다.")
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "존재하지 않는 사용자입니다.")
    return user


def get_optional_user(
    cred: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User | None:
    """로그인 안 해도 되는 API에서, 토큰이 있으면 사용자 정보를 함께 쓰기 위함 (잘못된 토큰은 무시)"""
    if cred is None:
        return None
    try:
        payload = jwt.decode(cred.credentials, settings.JWT_SECRET, algorithms=[ALGORITHM])
        return db.get(User, int(payload["sub"]))
    except (jwt.PyJWTError, KeyError, ValueError):
        return None


def require_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != "ADMIN":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "시스템관리자만 가능합니다.")
    return user


# ---------- 공통 조회/권한 도우미 ----------
def get_club_or_404(db: Session, club_id: int) -> Club:
    club = db.get(Club, club_id)
    if club is None or club.is_deleted:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "동아리를 찾을 수 없습니다.")
    return club


def get_membership(db: Session, user_id: int, club_id: int) -> Membership | None:
    return db.scalar(
        select(Membership).where(Membership.user_id == user_id, Membership.club_id == club_id)
    )


def is_officer(db: Session, user: User, club_id: int) -> bool:
    """동아리 임원 판별: member_role='OFFICER' AND status='APPROVED' (관리자는 항상 True)"""
    if user.role == "ADMIN":
        return True
    m = get_membership(db, user.user_id, club_id)
    return m is not None and m.member_role == "OFFICER" and m.status == "APPROVED"


def require_officer(db: Session, user: User, club_id: int) -> None:
    if not is_officer(db, user, club_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "동아리 임원만 가능합니다.")
