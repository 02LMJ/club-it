"""요청/응답 JSON 형식. Flutter 앱과 주고받는 데이터 모양입니다."""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

UserRole = Literal["STUDENT", "OFFICER", "ADMIN"]
MemberRole = Literal["MEMBER", "OFFICER"]
MemberStatus = Literal["PENDING", "APPROVED", "REJECTED", "CANCELED"]
PostType = Literal["RECRUIT", "NOTICE", "PROMO"]  # 모집글 / 공지사항 / 활동 홍보글
POST_TYPE_LABELS = {"RECRUIT": "모집글", "NOTICE": "공지사항", "PROMO": "활동 홍보글"}


class ORM(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class Message(BaseModel):
    detail: str


# ---------- 회원 ----------
class UserCreate(BaseModel):
    email: EmailStr = Field(max_length=100)
    password: str = Field(min_length=8, max_length=64)
    name: str = Field(min_length=1, max_length=50)


class UserOut(ORM):
    user_id: int
    email: str
    name: str
    role: UserRole
    created_at: datetime


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ---------- 동아리 ----------
class ClubUpdate(BaseModel):
    """동아리 수정: 보낸 필드만 바뀜 (PATCH)"""
    club_name: str | None = Field(default=None, min_length=1, max_length=100)
    description: str | None = None
    category: str | None = Field(default=None, max_length=50)
    recruit_status: bool | None = None


class ClubOut(ORM):
    club_id: int
    club_name: str
    description: str | None
    category: str | None
    recruit_status: bool
    created_at: datetime


# ---------- 가입신청 / 멤버 ----------
class JoinRequest(BaseModel):
    message: str | None = Field(default=None, max_length=2000)  # 신청서 내용


class MembershipOut(ORM):
    membership_id: int
    user_id: int
    club_id: int
    member_role: MemberRole
    status: MemberStatus
    join_date: datetime
    message: str | None
    reject_reason: str | None


class ApplicationOut(MembershipOut):
    """임원이 보는 신청 목록: 신청자 이름·이메일 포함"""
    user_name: str
    user_email: str


class MyMembershipOut(MembershipOut):
    """내 신청/가입 현황: 동아리 이름 포함"""
    club_name: str


class MembershipDecision(BaseModel):
    status: Literal["APPROVED", "REJECTED"]
    reject_reason: str | None = Field(default=None, max_length=500)


# ---------- 게시물 / 댓글 ----------
class PostCreate(BaseModel):
    post_type: PostType = "NOTICE"
    title: str = Field(min_length=1, max_length=200)
    content: str = Field(min_length=1)


class PostUpdate(BaseModel):
    post_type: PostType | None = None
    title: str | None = Field(default=None, min_length=1, max_length=200)
    content: str | None = Field(default=None, min_length=1)


class PostOut(ORM):
    post_id: int
    club_id: int
    user_id: int
    author_name: str
    post_type: PostType
    title: str
    content: str
    created_at: datetime
    comment_count: int = 0


class CommentCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class CommentOut(ORM):
    comment_id: int
    post_id: int
    user_id: int
    author_name: str
    content: str
    created_at: datetime


# ---------- 즐겨찾기 ----------
class FavoriteUpdate(BaseModel):
    notify_enabled: bool


class FavoriteOut(ORM):
    favorite_id: int
    club_id: int
    club_name: str
    notify_enabled: bool
    created_at: datetime


# ---------- 알림 ----------
class NotificationOut(ORM):
    notification_id: int
    message: str
    post_id: int | None  # 있으면 앱에서 해당 게시물로 이동
    is_read: bool
    created_at: datetime


class UnreadCount(BaseModel):
    unread: int


# ---------- LLM 작성 보조 ----------
AssistTask = Literal["title", "draft", "improve", "summary"]


class AssistRequest(BaseModel):
    task: AssistTask = Field(description="title=제목추천, draft=본문초안, improve=문장개선, summary=요약")
    post_type: PostType = "RECRUIT"
    club_id: int | None = Field(default=None, description="동아리 정보를 프롬프트에 넣고 싶을 때")
    text: str = Field(
        default="",
        max_length=5000,
        description="draft: 핵심 키워드/메모, title·improve·summary: 대상 본문",
    )


class AssistResponse(BaseModel):
    task: AssistTask
    result: str
    suggestions: list[str] = []  # title 작업일 때 제목 후보 목록
    provider: str


# ---------- 관리자: OFFICER(동아리 등록 권한) 관리 ----------
class RoleUpdate(BaseModel):
    role: Literal["STUDENT", "OFFICER"]  # OFFICER 지정 / STUDENT로 회수


class OfficerClub(BaseModel):
    club_id: int
    club_name: str


class OfficerOut(BaseModel):
    user_id: int
    name: str
    email: str
    clubs: list[OfficerClub]
