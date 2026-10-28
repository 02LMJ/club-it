"""동아리 조회 / 등록 / 가입신청 / 승인·거절."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Club, MemberRole, Membership, MemberStatus, User, UserRole
from app.schemas import ClubCreate, ClubOut, MembershipDecision, MembershipOut
from app.security import get_current_user, require_admin

router = APIRouter(prefix="/clubs", tags=["동아리"])


def _get_club_or_404(db: Session, club_id: int) -> Club:
    club = db.get(Club, club_id)
    if club is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "동아리를 찾을 수 없습니다.")
    return club


def _is_officer(db: Session, user: User, club_id: int) -> bool:
    if user.role == UserRole.ADMIN:
        return True
    m = db.scalar(
        select(Membership).where(
            Membership.user_id == user.id,
            Membership.club_id == club_id,
            Membership.role == MemberRole.OFFICER,
            Membership.status == MemberStatus.APPROVED,
        )
    )
    return m is not None


# ----- 조회 (로그인 없이 가능) -----
@router.get("", response_model=list[ClubOut])
def list_clubs(category: str | None = None, recruiting: bool | None = None, db: Session = Depends(get_db)):
    q = select(Club).order_by(Club.id)
    if category:
        q = q.where(Club.category == category)
    if recruiting is not None:
        q = q.where(Club.is_recruiting == recruiting)
    return db.scalars(q).all()


@router.get("/{club_id}", response_model=ClubOut)
def get_club(club_id: int, db: Session = Depends(get_db)):
    return _get_club_or_404(db, club_id)


# ----- 등록 (시스템관리자) -----
@router.post("", response_model=ClubOut, status_code=status.HTTP_201_CREATED)
def create_club(data: ClubCreate, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    if db.scalar(select(Club).where(Club.name == data.name)):
        raise HTTPException(status.HTTP_409_CONFLICT, "같은 이름의 동아리가 이미 있습니다.")
    club = Club(**data.model_dump())
    db.add(club)
    db.commit()
    db.refresh(club)
    return club


# ----- 가입신청 (재학생) -----
@router.post("/{club_id}/join", response_model=MembershipOut, status_code=status.HTTP_201_CREATED)
def apply_join(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    club = _get_club_or_404(db, club_id)
    if not club.is_recruiting:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "현재 모집 중이 아닌 동아리입니다.")
    existing = db.scalar(
        select(Membership).where(Membership.user_id == user.id, Membership.club_id == club_id)
    )
    if existing:
        if existing.status != MemberStatus.REJECTED:
            raise HTTPException(status.HTTP_409_CONFLICT, "이미 신청했거나 가입된 동아리입니다.")
        existing.status = MemberStatus.PENDING  # 거절됐던 사람은 재신청 가능
        db.commit()
        db.refresh(existing)
        return existing
    m = Membership(user_id=user.id, club_id=club_id)
    db.add(m)
    db.commit()
    db.refresh(m)
    return m


# ----- 신청 목록 / 승인·거절 (동아리 임원 또는 관리자) -----
@router.get("/{club_id}/applications", response_model=list[MembershipOut])
def list_applications(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    _get_club_or_404(db, club_id)
    if not _is_officer(db, user, club_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "동아리 임원만 볼 수 있습니다.")
    return db.scalars(
        select(Membership).where(Membership.club_id == club_id, Membership.status == MemberStatus.PENDING)
    ).all()


@router.patch("/{club_id}/applications/{membership_id}", response_model=MembershipOut)
def decide_application(
    club_id: int,
    membership_id: int,
    data: MembershipDecision,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if not _is_officer(db, user, club_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "동아리 임원만 처리할 수 있습니다.")
    if data.status == MemberStatus.PENDING:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "APPROVED 또는 REJECTED만 가능합니다.")
    m = db.get(Membership, membership_id)
    if m is None or m.club_id != club_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "신청 내역을 찾을 수 없습니다.")
    m.status = data.status
    db.commit()
    db.refresh(m)
    return m
