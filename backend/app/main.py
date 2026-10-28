"""서버 시작점. uvicorn app.main:app --reload 로 실행합니다."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import models  # noqa: F401  (테이블 정의를 불러와야 create_all이 테이블을 만듭니다)
from app.database import Base, engine
from app.routers import auth, clubs

# 서버가 켜질 때 테이블이 없으면 자동 생성 (나중에 Alembic으로 교체 예정)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Club-it API", version="0.1.0")

# Flutter 웹/에뮬레이터에서 접속할 수 있게 허용 (배포 때는 실제 주소만 허용하도록 좁히기)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(clubs.router)


@app.get("/", tags=["상태확인"])
def health():
    return {"status": "ok"}
