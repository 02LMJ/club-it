"""테스트용 기본 데이터 넣기. 실행: python -m app.seed

- 시스템관리자 계정: admin@clubit.com / admin1234
- 동아리 임원 계정: officer@clubit.com / officer1234  (첫 번째 동아리의 임원)
- 샘플 동아리 3개
여러 번 실행해도 중복으로 들어가지 않습니다.
"""
from sqlalchemy import select

from app import models  # noqa: F401
from app.database import Base, SessionLocal, engine
from app.models import Club, MemberRole, Membership, MemberStatus, User, UserRole
from app.security import hash_password

SAMPLE_CLUBS = [
    {"name": "코딩하는사람들", "category": "학술", "description": "웹·앱 개발 스터디 동아리", "is_recruiting": True},
    {"name": "달리기클럽", "category": "운동", "description": "매주 화·목 저녁 러닝", "is_recruiting": True},
    {"name": "사진동아리 셔터", "category": "문화", "description": "출사와 사진전", "is_recruiting": False},
]


def get_or_create_user(db, email, password, name, student_id, role=UserRole.STUDENT):
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        user = User(email=email, password_hash=hash_password(password), name=name,
                    student_id=student_id, role=role)
        db.add(user)
        db.flush()
    return user


def main():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        get_or_create_user(db, "admin@clubit.com", "admin1234", "관리자", "0000000000", UserRole.ADMIN)
        officer = get_or_create_user(db, "officer@clubit.com", "officer1234", "임원", "0000000001")

        clubs = []
        for c in SAMPLE_CLUBS:
            club = db.scalar(select(Club).where(Club.name == c["name"]))
            if club is None:
                club = Club(**c)
                db.add(club)
                db.flush()
            clubs.append(club)

        first = clubs[0]
        if db.scalar(select(Membership).where(Membership.user_id == officer.id,
                                              Membership.club_id == first.id)) is None:
            db.add(Membership(user_id=officer.id, club_id=first.id,
                              role=MemberRole.OFFICER, status=MemberStatus.APPROVED))
        db.commit()
        print("기본 데이터 준비 완료")
    finally:
        db.close()


if __name__ == "__main__":
    main()
