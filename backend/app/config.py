"""설정값: .env 파일에서 읽어옵니다."""
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # --- DB ---
    DB_USER: str = "root"
    DB_PASSWORD: str = ""
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_NAME: str = "clubit"
    DATABASE_URL: str | None = None  # 직접 지정하면 위 DB_* 대신 사용 (테스트·배포용)

    # --- 로그인 토큰 ---
    JWT_SECRET: str = "change-me"
    JWT_EXPIRE_MINUTES: int = 1440

    # --- LLM 작성 보조 ---
    LLM_PROVIDER: str = "mock"  # mock | anthropic | openai | ollama
    LLM_API_KEY: str = ""
    LLM_MODEL: str = ""
    OLLAMA_URL: str = "http://localhost:11434"
    LLM_TIMEOUT: float = 60.0

    # --- CORS (쉼표로 구분, 배포 시 실제 주소만) ---
    CORS_ORIGINS: str = "*"

    @property
    def db_url(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        pw = quote_plus(self.DB_PASSWORD)
        return (
            f"mysql+pymysql://{self.DB_USER}:{pw}@{self.DB_HOST}:{self.DB_PORT}"
            f"/{self.DB_NAME}?charset=utf8mb4"
        )


settings = Settings()
