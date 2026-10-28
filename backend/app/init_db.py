"""DB 초기화: backend/db/clubit_schema.sql을 실행합니다. 실행: python -m app.init_db

※ SQL 맨 위의 DROP DATABASE 때문에 기존 clubit DB의 데이터가 전부 지워집니다.
접속 정보는 .env(DB_USER, DB_PASSWORD, DB_HOST, DB_PORT)를 사용합니다.
"""
from pathlib import Path

import pymysql
from pymysql.constants import CLIENT

from app.config import settings

SQL_PATH = Path(__file__).resolve().parents[1] / "db" / "clubit_schema.sql"


def main():
    sql = SQL_PATH.read_text(encoding="utf-8")
    conn = pymysql.connect(
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        charset="utf8mb4",
        client_flag=CLIENT.MULTI_STATEMENTS,
        autocommit=True,
    )
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            while cur.nextset():  # 여러 SQL 문의 결과를 끝까지 소비
                pass
            cur.execute("SELECT COUNT(*) FROM clubit.user")
            users = cur.fetchone()[0]
        print(f"DB 초기화 완료: {SQL_PATH.name} 실행 (사용자 {users}명)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
