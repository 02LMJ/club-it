"""가입신청 / 신청취소 / 승인·거절 / 멤버 목록 / 내 동아리."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Club, Membership, Notification, User
from app.schemas import (
    ApplicationOut,
    JoinRequest,
    MembershipDecision,
    MembershipOut,
    MemberStatus,
    MyMembershipOut,
)
from app.security import get_club_or_404, get_current_user, get_membership, require_officer

router = APIRouter(tags=["가입신청"])


def _with_user(m: Membership, u: User) -> ApplicationOut:
    return ApplicationOut.model_validate(
        {**MembershipOut.model_validate(m).model_dump(), "user_name": u.name, "user_email": u.email}
    )


# ----- 재학생 -----
@router.post("/clubs/{club_id}/join", response_model=MembershipOut, status_code=status.HTTP_201_CREATED)
def apply_join(
    club_id: int,
    data: JoinRequest | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    club = get_club_or_404(db, club_id)
    if not club.recruit_status:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "현재 모집 중이 아닌 동아리입니다.")
    message = data.message if data else None
    m = get_membership(db, user.user_id, club_id)
    if m:
        if m.status in ("PENDING", "APPROVED"):
            raise HTTPException(status.HTTP_409_CONFLICT, "이미 신청했거나 가입된 동아리입니다.")
        # 거절·취소됐던 신청은 같은 행을 재사용해 다시 신청 (UNIQUE(user_id, club_id) 때문)
        m.status, m.member_role, m.reject_reason, m.message = "PENDING", "MEMBER", None, message
        m.join_date = datetime.now()
    else:
        m = Membership(user_id=user.user_id, club_id=club_id, message=message)
        db.add(m)
    db.commit()
    db.refresh(m)
    return m


@router.post("/clubs/{club_id}/join/cancel", response_model=MembershipOut)
def cancel_join(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    m = get_membership(db, user.user_id, club_id)
    if m is None or m.status != "PENDING":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "취소할 수 있는 대기 중 신청이 없습니다.")
    m.status = "CANCELED"
    db.commit()
    db.refresh(m)
    return m


@router.get("/me/memberships", response_model=list[MyMembershipOut])
def my_memberships(
    status_: MemberStatus | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    stmt = (
        select(Membership, Club)
        .join(Club, Club.club_id == Membership.club_id)
        .where(Membership.user_id == user.user_id, Club.is_deleted.is_(False))
    )
    if status_:
        stmt = stmt.where(Membership.status == status_)
    rows = db.execute(stmt.order_by(Membership.join_date.desc())).all()
    return [
        MyMembershipOut.model_validate(
            {**MembershipOut.model_validate(m).model_dump(), "club_name": c.club_name}
        )
        for m, c in rows
    ]


# ----- 동아리 임원 -----
@router.get("/clubs/{club_id}/applications", response_model=list[ApplicationOut])
def list_applications(
    club_id: int,
    status_: MemberStatus = Query(default="PENDING", alias="status"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    rows = db.execute(
        select(Membership, User)
        .join(User, User.user_id == Membership.user_id)
        .where(Membership.club_id == club_id, Membership.status == status_)
        .order_by(Membership.join_date)
    ).all()
    return [_with_user(m, u) for m, u in rows]


@router.patch("/clubs/{club_id}/applications/{membership_id}", response_model=MembershipOut)
def decide_application(
    club_id: int,
    membership_id: int,
    data: MembershipDecision,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    club = get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    m = db.get(Membership, membership_id)
    if m is None or m.club_id != club_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "신청 내역을 찾을 수 없습니다.")
    if m.status != "PENDING":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "대기 중인 신청만 처리할 수 있습니다.")
    m.status = data.status
    m.reject_reason = data.reject_reason if data.status == "REJECTED" else None
    result = "승인" if data.status == "APPROVED" else "거절"
    db.add(Notification(user_id=m.user_id, message=f"[{club.club_name}] 가입 신청이 {result}되었습니다."[:255]))
    db.commit()
    db.refresh(m)
    return m


@router.get("/clubs/{club_id}/members", response_model=list[ApplicationOut])
def list_members(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    rows = db.execute(
        select(Membership, User)
        .join(User, User.user_id == Membership.user_id)
        .where(Membership.club_id == club_id, Membership.status == "APPROVED")
        .order_by(Membership.member_role.desc(), User.name)
    ).all()
    return [_with_user(m, u) for m, u in rows]

