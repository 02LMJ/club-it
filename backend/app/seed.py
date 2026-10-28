"""테스트 계정 준비. 실행: python -m app.seed  (python -m app.init_db 다음에)

clubit_schema.sql의 더미 계정은 비밀번호가 자리표시 문자열이라 로그인이 안 됩니다.
이 스크립트가 더미 계정 비밀번호를 전부 test1234 로 설정해서 바로 로그인할 수 있게 합니다.

  관리자  admin@cbnu.ac.kr     (ADMIN)
  임원    officer1@cbnu.ac.kr  (OFFICER, CATS·COSMIC 임원)
  임원    officer2@cbnu.ac.kr  (OFFICER, IPSE·CERT 임원)
  학생    student1~3@cbnu.ac.kr
  비밀번호: 모두 test1234

DB가 비어 있으면(더미 데이터 없이 테이블만 만든 경우) 위 관리자·임원 계정과 동아리 1개를 직접 만듭니다.
여러 번 실행해도 괜찮습니다.
"""
from sqlalchemy import select

from app.database import SessionLocal
from app.models import Club, Membership, User
from app.security import hash_password

PLACEHOLDER = "CHANGE_ME_BCRYPT_HASH"
TEST_PASSWORD = "test1234"


def main():
    db = SessionLocal()
    try:
        users = db.scalars(select(User).where(User.password == PLACEHOLDER)).all()
        for u in users:
            u.password = hash_password(TEST_PASSWORD)

        if db.scalar(select(User).limit(1)) is None:
            admin = User(email="admin@cbnu.ac.kr", name="관리자", role="ADMIN", password=hash_password(TEST_PASSWORD))
            officer = User(email="officer1@cbnu.ac.kr", name="김임원", role="OFFICER",
                           password=hash_password(TEST_PASSWORD))
            club = Club(club_name="CATS", category="학술", description="컴퓨터공학 기반 학술 동아리", recruit_status=True)
            db.add_all([admin, officer, club])
            db.flush()
            db.add(Membership(user_id=officer.user_id, club_id=club.club_id, member_role="OFFICER", status="APPROVED"))
            print("빈 DB라서 기본 계정과 동아리를 만들었습니다.")

        db.commit()
        print(f"테스트 계정 준비 완료 (비밀번호 설정 {len(users)}명, 비밀번호: {TEST_PASSWORD})")
    finally:
        db.close()


if __name__ == "__main__":
    main()
