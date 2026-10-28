"""서버 시작점. 실행: uvicorn app.main:app --reload --port 8001

테이블은 태수의 SQL(db/clubit_schema.sql)로 만듭니다. 이 서버는 테이블을 만들지 않습니다.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import admin, ai, auth, clubs, favorites, memberships, notifications, posts

app = FastAPI(title="Club-it API", version="0.3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(",")],
    allow_methods=["*"],
    allow_headers=["*"],
)

for r in (auth, clubs, memberships, posts, favorites, notifications, ai, admin):
    app.include_router(r.router)


@app.get("/", tags=["상태확인"])
def health():
    return {"status": "ok"}
