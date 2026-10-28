"""DB 테이블 정의. 클래스 하나 = 테이블 하나."""
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class UserRole(str, enum.Enum):
    STUDENT = "STUDENT"  # 재학생
    ADMIN = "ADMIN"      # 시스템관리자


class MemberRole(str, enum.Enum):
    MEMBER = "MEMBER"    # 일반 부원
    OFFICER = "OFFICER"  # 동아리 임원


class MemberStatus(str, enum.Enum):
    PENDING = "PENDING"    # 대기
    APPROVED = "APPROVED"  # 승인
    REJECTED = "REJECTED"  # 거절


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(100))
    name: Mapped[str] = mapped_column(String(50))
    student_id: Mapped[str] = mapped_column(String(20), unique=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.STUDENT)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    memberships: Mapped[list["Membership"]] = relationship(back_populates="user")


class Club(Base):
    __tablename__ = "clubs"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    category: Mapped[str] = mapped_column(String(50))
    description: Mapped[str] = mapped_column(Text, default="")
    is_recruiting: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    memberships: Mapped[list["Membership"]] = relationship(back_populates="club")


class Membership(Base):
    """누가 어느 동아리에 어떤 상태(대기/승인/거절)로 속해 있는지."""
    __tablename__ = "memberships"
    __table_args__ = (UniqueConstraint("user_id", "club_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    club_id: Mapped[int] = mapped_column(ForeignKey("clubs.id"))
    role: Mapped[MemberRole] = mapped_column(Enum(MemberRole), default=MemberRole.MEMBER)
    status: Mapped[MemberStatus] = mapped_column(Enum(MemberStatus), default=MemberStatus.PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped[User] = relationship(back_populates="memberships")
    club: Mapped[Club] = relationship(back_populates="memberships")
