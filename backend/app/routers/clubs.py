"""동아리 조회 / 등록.

등록 권한: user.role이 OFFICER(관리자가 지정한 전역 권한) 또는 ADMIN (요구사항 UD-04, FR11)
등록하면 club 1행 + 등록자의 membership(OFFICER, APPROVED) 1행을 함께 생성.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Club, Membership, User
from app.schemas import ClubCreate, ClubOut, ClubUpdate
from app.security import get_club_or_404, get_current_user, require_officer

router = APIRouter(prefix="/clubs", tags=["동아리"])


@router.get("", response_model=list[ClubOut])
def list_clubs(
    q: str | None = Query(default=None, description="이름·소개 검색어"),
    category: str | None = None,
    recruiting: bool | None = Query(default=None, description="true면 모집 중인 동아리만"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    stmt = select(Club).where(Club.is_deleted.is_(False))
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(Club.club_name.like(like), Club.description.like(like)))
    if category:
        stmt = stmt.where(Club.category == category)
    if recruiting is not None:
        stmt = stmt.where(Club.recruit_status.is_(recruiting))
    return db.scalars(stmt.order_by(Club.club_id).offset(skip).limit(limit)).all()


@router.get("/{club_id}", response_model=ClubOut)
def get_club(club_id: int, db: Session = Depends(get_db)):
    return get_club_or_404(db, club_id)


@router.post("", response_model=ClubOut, status_code=status.HTTP_201_CREATED)
def create_club(data: ClubCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if user.role not in ("OFFICER", "ADMIN"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "동아리 등록 권한(OFFICER)이 있는 사용자만 가능합니다.")
    if db.scalar(select(Club).where(Club.club_name == data.club_name)):
        raise HTTPException(status.HTTP_409_CONFLICT, "같은 이름의 동아리가 이미 있습니다.")
    club = Club(**data.model_dump())
    db.add(club)
    db.flush()  # club_id 받기
    db.add(Membership(user_id=user.user_id, club_id=club.club_id, member_role="OFFICER", status="APPROVED"))
    db.commit()
    db.refresh(club)
    return club

@router.patch("/{club_id}", response_model=ClubOut)
def update_club(
    club_id: int,
    data: ClubUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """동아리 정보·모집 여부 수정. 해당 동아리 임원(또는 관리자)만 가능."""
    club = get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    changes = data.model_dump(exclude_unset=True)
    new_name = changes.get("club_name")
    if new_name and new_name != club.club_name:
        if db.scalar(select(Club).where(Club.club_name == new_name)):
            raise HTTPException(status.HTTP_409_CONFLICT, "같은 이름의 동아리가 이미 있습니다.")
    for field, value in changes.items():
        if value is None and field in ("club_name", "recruit_status"):
            continue  # NOT NULL 컬럼은 null로 못 바꿈
        setattr(club, field, value)
    db.commit()
    db.refresh(club)
    return club


@router.delete("/{club_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_club(
    club_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """동아리 삭제 = is_deleted 를 TRUE 로 바꾸는 소프트 삭제 (클래스 문서 Club.delete())."""
    club = get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    club.is_deleted = True
    club.recruit_status = False
    db.commit()
