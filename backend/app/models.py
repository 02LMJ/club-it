"""DB 테이블 정의 (태수 스키마 backend/db/clubit_schema.sql 기준).

테이블은 태수의 SQL로 만듭니다. 이 파일은 그 테이블 구조를 코드에서 쓰기 위한 '지도'입니다.
※ 컬럼을 바꿀 때는 SQL과 이 파일을 반드시 같이 바꿔야 합니다.
"""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base

# ---- 값 목록 (DB에는 VARCHAR 문자열로 저장) ----
USER_ROLES = ("STUDENT", "OFFICER", "ADMIN")
MEMBER_ROLES = ("MEMBER", "OFFICER")
MEMBER_STATUSES = ("PENDING", "APPROVED", "REJECTED", "CANCELED")
POST_TYPES = ("RECRUIT", "NOTICE", "PROMO")  # 모집글 / 공지사항 / 활동 홍보글


class User(Base):
    """role: STUDENT(재학생) / OFFICER(동아리 등록 가능한 전역 권한, 관리자가 지정) / ADMIN"""

    __tablename__ = "user"

    user_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50))
    email: Mapped[str] = mapped_column(String(100), unique=True)
    role: Mapped[str] = mapped_column(String(20), default="STUDENT", server_default="STUDENT")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    password: Mapped[str] = mapped_column(String(255))  # [추가] bcrypt 해시


class Club(Base):
    __tablename__ = "club"

    club_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    club_name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    category: Mapped[str | None] = mapped_column(String(50), nullable=True)  # [추가]
    recruit_status: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")  # [추가]
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")  # [추가]


class Membership(Base):
    __tablename__ = "membership"
    __table_args__ = (UniqueConstraint("user_id", "club_id"),)

    membership_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.user_id", ondelete="CASCADE"))
    club_id: Mapped[int] = mapped_column(ForeignKey("club.club_id", ondelete="CASCADE"))
    member_role: Mapped[str] = mapped_column(String(20), default="MEMBER", server_default="MEMBER")
    join_date: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())  # = 가입 신청일
    status: Mapped[str] = mapped_column(String(20), default="PENDING", server_default="PENDING")  # [추가]
    reject_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)  # [추가]
    message: Mapped[str | None] = mapped_column(Text, nullable=True)  # [추가] 신청서 내용


class Post(Base):
    __tablename__ = "post"
    __table_args__ = (Index("idx_post_club_created", "club_id", "created_at"),)

    post_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.user_id", ondelete="CASCADE"))
    club_id: Mapped[int] = mapped_column(ForeignKey("club.club_id", ondelete="CASCADE"))
    title: Mapped[str] = mapped_column(String(200))
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    post_type: Mapped[str] = mapped_column(String(20), default="NOTICE", server_default="NOTICE")  # [추가]


class Comment(Base):
    __tablename__ = "comment"

    comment_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.user_id", ondelete="CASCADE"))
    post_id: Mapped[int] = mapped_column(ForeignKey("post.post_id", ondelete="CASCADE"))
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class Favorite(Base):
    __tablename__ = "favorite"
    __table_args__ = (UniqueConstraint("user_id", "club_id"),)

    favorite_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.user_id", ondelete="CASCADE"))
    club_id: Mapped[int] = mapped_column(ForeignKey("club.club_id", ondelete="CASCADE"))
    notify_enabled: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")  # [추가]
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class Notification(Base):
    __tablename__ = "notification"

    notification_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.user_id", ondelete="CASCADE"))
    message: Mapped[str] = mapped_column(String(255))
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    post_id: Mapped[int | None] = mapped_column(  # [추가] 알림 눌렀을 때 이동할 게시물
        ForeignKey("post.post_id", ondelete="CASCADE"), nullable=True
    )
