"""즐겨찾기 (+ 새 글 알림 켜기/끄기)."""
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Club, Favorite, User
from app.schemas import FavoriteOut, FavoriteUpdate
from app.security import get_club_or_404, get_current_user

router = APIRouter(tags=["즐겨찾기"])


def _out(f: Favorite, club_name: str) -> FavoriteOut:
    return FavoriteOut(favorite_id=f.favorite_id, club_id=f.club_id, club_name=club_name,
                       notify_enabled=f.notify_enabled, created_at=f.created_at)


def _get_fav(db: Session, user_id: int, club_id: int) -> Favorite | None:
    return db.scalar(select(Favorite).where(Favorite.user_id == user_id, Favorite.club_id == club_id))


@router.get("/me/favorites", response_model=list[FavoriteOut])
def my_favorites(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = db.execute(
        select(Favorite, Club.club_name)
        .join(Club, Club.club_id == Favorite.club_id)
        .where(Favorite.user_id == user.user_id, Club.is_deleted.is_(False))
        .order_by(Favorite.created_at.desc())
    ).all()
    return [_out(f, name) for f, name in rows]


@router.post("/clubs/{club_id}/favorite", response_model=FavoriteOut, status_code=status.HTTP_201_CREATED)
def add_favorite(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    club = get_club_or_404(db, club_id)
    if _get_fav(db, user.user_id, club_id):
        raise HTTPException(status.HTTP_409_CONFLICT, "이미 즐겨찾기한 동아리입니다.")
    f = Favorite(user_id=user.user_id, club_id=club_id)
    db.add(f)
    db.commit()
    db.refresh(f)
    return _out(f, club.club_name)


@router.patch("/clubs/{club_id}/favorite", response_model=FavoriteOut)
def set_notify(club_id: int, data: FavoriteUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    club = get_club_or_404(db, club_id)
    f = _get_fav(db, user.user_id, club_id)
    if f is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "즐겨찾기하지 않은 동아리입니다.")
    f.notify_enabled = data.notify_enabled
    db.commit()
    db.refresh(f)
    return _out(f, club.club_name)


@router.delete("/clubs/{club_id}/favorite", status_code=status.HTTP_204_NO_CONTENT)
def remove_favorite(club_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    f = _get_fav(db, user.user_id, club_id)
    if f is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "즐겨찾기하지 않은 동아리입니다.")
    db.delete(f)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
