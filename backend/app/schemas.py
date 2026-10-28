"""요청/응답 데이터 모양 정의. 앱(Flutter)과 주고받는 JSON의 형식입니다."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import MemberRole, MemberStatus, UserRole


# ---------- 회원 ----------
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=64)
    name: str = Field(min_length=1, max_length=50)
    student_id: str = Field(min_length=1, max_length=20)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    student_id: str
    role: UserRole


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ---------- 동아리 ----------
class ClubCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    category: str = Field(min_length=1, max_length=50)
    description: str = ""
    is_recruiting: bool = False


class ClubOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    category: str
    description: str
    is_recruiting: bool
    created_at: datetime


# ---------- 가입신청 ----------
class MembershipOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    club_id: int
    role: MemberRole
    status: MemberStatus
    created_at: datetime


class MembershipDecision(BaseModel):
    status: MemberStatus  # APPROVED 또는 REJECTED
