"""게시물 / 댓글 CRUD + 새 게시물 알림.

권한
- 게시물 조회·댓글 조회: 누구나
- 게시물 작성: 해당 동아리 임원 (모집글·공지·홍보글)
- 게시물 수정: 작성자 / 삭제: 작성자, 동아리 임원, 관리자
- 댓글 작성: 로그인 사용자 / 수정: 작성자 / 삭제: 작성자, 동아리 임원, 관리자
"""
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Comment, Favorite, Notification, Post, User
from app.schemas import POST_TYPE_LABELS, CommentCreate, CommentOut, PostCreate, PostOut, PostType, PostUpdate
from app.security import get_club_or_404, get_current_user, is_officer, require_officer

router = APIRouter(tags=["게시물·댓글"])


# ---------- 도우미 ----------
def _post_out(db: Session, post: Post) -> PostOut:
    author = db.get(User, post.user_id)
    count = db.scalar(select(func.count()).select_from(Comment).where(Comment.post_id == post.post_id))
    return PostOut.model_validate(
        {**{c: getattr(post, c) for c in ("post_id", "club_id", "user_id", "post_type", "title", "content", "created_at")},
         "author_name": author.name if author else "(탈퇴)", "comment_count": count or 0}
    )


def _comment_out(c: Comment, author_name: str) -> CommentOut:
    return CommentOut(comment_id=c.comment_id, post_id=c.post_id, user_id=c.user_id,
                      author_name=author_name, content=c.content, created_at=c.created_at)


def _get_post_or_404(db: Session, post_id: int) -> Post:
    post = db.get(Post, post_id)
    if post is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "게시물을 찾을 수 없습니다.")
    get_club_or_404(db, post.club_id)  # 삭제된 동아리의 게시물은 숨김
    return post


# ---------- 게시물 ----------
@router.get("/clubs/{club_id}/posts", response_model=list[PostOut])
def list_posts(
    club_id: int,
    post_type: PostType | None = Query(default=None, description="RECRUIT/NOTICE/PROMO 중 하나만 보기"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    get_club_or_404(db, club_id)
    comment_count = (
        select(func.count()).select_from(Comment).where(Comment.post_id == Post.post_id).scalar_subquery()
    )
    stmt = (
        select(Post, User.name, comment_count)
        .join(User, User.user_id == Post.user_id)
        .where(Post.club_id == club_id)
    )
    if post_type:
        stmt = stmt.where(Post.post_type == post_type)
    rows = db.execute(
        stmt.order_by(Post.created_at.desc(), Post.post_id.desc()).offset(skip).limit(limit)
    ).all()
    return [
        PostOut(post_id=p.post_id, club_id=p.club_id, user_id=p.user_id, author_name=name, post_type=p.post_type, title=p.title,
                content=p.content, created_at=p.created_at, comment_count=cnt or 0)
        for p, name, cnt in rows
    ]


@router.post("/clubs/{club_id}/posts", response_model=PostOut, status_code=status.HTTP_201_CREATED)
def create_post(club_id: int, data: PostCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    club = get_club_or_404(db, club_id)
    require_officer(db, user, club_id)
    post = Post(user_id=user.user_id, club_id=club_id, post_type=data.post_type,
                title=data.title, content=data.content)
    db.add(post)
    db.flush()  # post_id를 알림에 넣기 위해 먼저 번호 받기

    # 새 게시물 알림: 이 동아리를 즐겨찾기하고 알림을 켠 사용자에게 (작성자 제외)
    receivers = db.scalars(
        select(Favorite.user_id).where(
            Favorite.club_id == club_id, Favorite.notify_enabled.is_(True), Favorite.user_id != user.user_id
        )
    ).all()
    msg = f"[{club.club_name}] 새 {POST_TYPE_LABELS[data.post_type]}: {data.title}"[:255]
    db.add_all([Notification(user_id=uid, message=msg, post_id=post.post_id) for uid in receivers])

    db.commit()
    db.refresh(post)
    return _post_out(db, post)


@router.get("/posts/{post_id}", response_model=PostOut)
def get_post(post_id: int, db: Session = Depends(get_db)):
    return _post_out(db, _get_post_or_404(db, post_id))


@router.patch("/posts/{post_id}", response_model=PostOut)
def update_post(post_id: int, data: PostUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    post = _get_post_or_404(db, post_id)
    if post.user_id != user.user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "작성자만 수정할 수 있습니다.")
    for k, v in data.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(post, k, v)
    db.commit()
    db.refresh(post)
    return _post_out(db, post)


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(post_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    post = _get_post_or_404(db, post_id)
    if post.user_id != user.user_id and not is_officer(db, user, post.club_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "삭제 권한이 없습니다.")
    # 댓글은 DB의 ON DELETE CASCADE로 함께 삭제됨. (CASCADE가 없는 DB에서도 안전하게 직접 삭제)
    for c in db.scalars(select(Comment).where(Comment.post_id == post_id)).all():
        db.delete(c)
    db.delete(post)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---------- 댓글 ----------
@router.get("/posts/{post_id}/comments", response_model=list[CommentOut])
def list_comments(post_id: int, db: Session = Depends(get_db)):
    _get_post_or_404(db, post_id)
    rows = db.execute(
        select(Comment, User.name)
        .join(User, User.user_id == Comment.user_id)
        .where(Comment.post_id == post_id)
        .order_by(Comment.created_at, Comment.comment_id)
    ).all()
    return [_comment_out(c, name) for c, name in rows]


@router.post("/posts/{post_id}/comments", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
def create_comment(post_id: int, data: CommentCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    _get_post_or_404(db, post_id)
    c = Comment(user_id=user.user_id, post_id=post_id, content=data.content)
    db.add(c)
    db.commit()
    db.refresh(c)
    return _comment_out(c, user.name)


@router.patch("/comments/{comment_id}", response_model=CommentOut)
def update_comment(comment_id: int, data: CommentCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    c = db.get(Comment, comment_id)
    if c is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "댓글을 찾을 수 없습니다.")
    if c.user_id != user.user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "작성자만 수정할 수 있습니다.")
    c.content = data.content
    db.commit()
    db.refresh(c)
    return _comment_out(c, user.name)


@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment(comment_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    c = db.get(Comment, comment_id)
    if c is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "댓글을 찾을 수 없습니다.")
    post = db.get(Post, c.post_id)
    if c.user_id != user.user_id and not (post and is_officer(db, user, post.club_id)):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "삭제 권한이 없습니다.")
    db.delete(c)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
