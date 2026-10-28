"""시스템관리자: 사용자 목록 / OFFICER(동아리 등록 권한) 지정·회수 / 임원 목록 (FR11)."""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select, update
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Club, Membership, User
from app.schemas import OfficerClub, OfficerOut, RoleUpdate, UserOut, UserRole
from app.security import require_admin

router = APIRouter(prefix="/admin", tags=["관리자"], dependencies=[Depends(require_admin)])


@router.get("/users", response_model=list[UserOut])
def list_users(
    role: UserRole | None = None,
    q: str | None = Query(default=None, description="이름·이메일 검색"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    stmt = select(User)
    if role:
        stmt = stmt.where(User.role == role)
    if q:
        stmt = stmt.where(or_(User.name.like(f"%{q}%"), User.email.like(f"%{q}%")))
    return db.scalars(stmt.order_by(User.user_id).offset(skip).limit(limit)).all()


@router.patch("/users/{user_id}/role", response_model=UserOut)
def change_role(user_id: int, data: RoleUpdate, db: Session = Depends(get_db)):
    """OFFICER 지정 또는 STUDENT로 회수. 회수 시 소속 동아리의 임원 권한도 즉시 MEMBER로 내림 (FR11-01)."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "사용자를 찾을 수 없습니다.")
    if user.role == "ADMIN":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "관리자 계정의 권한은 변경할 수 없습니다.")
    user.role = data.role
    if data.role == "STUDENT":
        db.execute(
            update(Membership)
            .where(Membership.user_id == user_id, Membership.member_role == "OFFICER")
            .values(member_role="MEMBER")
        )
    db.commit()
    db.refresh(user)
    return user


@router.get("/officers", response_model=list[OfficerOut])
def list_officers(db: Session = Depends(get_db)):
    """user.role='OFFICER'인 사용자 + 임원으로 소속된 동아리 (FR11-03)"""
    officers = db.scalars(select(User).where(User.role == "OFFICER").order_by(User.name)).all()
    result = []
    for u in officers:
        clubs = db.execute(
            select(Club.club_id, Club.club_name)
            .join(Membership, Membership.club_id == Club.club_id)
            .where(
                Membership.user_id == u.user_id,
                Membership.member_role == "OFFICER",
                Membership.status == "APPROVED",
                Club.is_deleted.is_(False),
            )
            .order_by(Club.club_name)
        ).all()
        result.append(OfficerOut(user_id=u.user_id, name=u.name, email=u.email,
                                 clubs=[OfficerClub(club_id=c.club_id, club_name=c.club_name) for c in clubs]))
    return result
