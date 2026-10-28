"""테스트용 기본 데이터 넣기. 실행: python -m app.seed
(먼저 backend/db/clubit_schema.sql로 테이블이 만들어져 있어야 합니다)

- 시스템관리자: admin@clubit.com / admin1234
- 동아리 임원:  officer@clubit.com / officer1234  (user.role=OFFICER, 코딩하는사람들 임원)
- 샘플 동아리 3개
여러 번 실행해도 중복으로 들어가지 않습니다.
"""
from sqlalchemy import select

from app.database import SessionLocal
from app.models import Club, Membership, User
from app.security import hash_password

SAMPLE_CLUBS = [
    {"club_name": "코딩하는사람들", "category": "학술", "description": "웹·앱 개발 스터디 동아리", "recruit_status": True},
    {"club_name": "달리기클럽", "category": "운동", "description": "매주 화·목 저녁 러닝", "recruit_status": True},
    {"club_name": "사진동아리 셔터", "category": "문화", "description": "출사와 사진전", "recruit_status": False},
]


def get_or_create_user(db, email, password, name, role="STUDENT"):
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        user = User(email=email, password=hash_password(password), name=name, role=role)
        db.add(user)
        db.flush()
    return user


def main():
    db = SessionLocal()
    try:
        get_or_create_user(db, "admin@clubit.com", "admin1234", "관리자", "ADMIN")
        officer = get_or_create_user(db, "officer@clubit.com", "officer1234", "임원", "OFFICER")

        clubs = []
        for c in SAMPLE_CLUBS:
            club = db.scalar(select(Club).where(Club.club_name == c["club_name"]))
            if club is None:
                club = Club(**c)
                db.add(club)
                db.flush()
            clubs.append(club)

        first = clubs[0]
        if db.scalar(select(Membership).where(Membership.user_id == officer.user_id,
                                              Membership.club_id == first.club_id)) is None:
            db.add(Membership(user_id=officer.user_id, club_id=first.club_id,
                              member_role="OFFICER", status="APPROVED"))
        db.commit()
        print("기본 데이터 준비 완료")
    finally:
        db.close()


if __name__ == "__main__":
    main()
