"""설정값: .env 파일에서 읽어옵니다."""
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    DB_USER: str = "root"
    DB_PASSWORD: str = ""
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_NAME: str = "clubit"
    # 직접 지정하면 위 DB_* 값 대신 이 주소를 사용 (테스트·배포용)
    DATABASE_URL: str | None = None

    JWT_SECRET: str = "change-me"
    JWT_EXPIRE_MINUTES: int = 1440

    @property
    def db_url(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        pw = quote_plus(self.DB_PASSWORD)  # 비밀번호에 특수문자가 있어도 안전하게
        return (
            f"mysql+pymysql://{self.DB_USER}:{pw}@{self.DB_HOST}:{self.DB_PORT}"
            f"/{self.DB_NAME}?charset=utf8mb4"
        )


settings = Settings()
