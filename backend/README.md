# Club-it 백엔드 (FastAPI + MySQL)

동아리 통합 플랫폼 Club-it의 서버입니다. Flutter 앱이 이 서버에 요청을 보내고, 서버는 MySQL에 데이터를 저장합니다.

```
[Flutter 앱]  ──HTTP(JSON)──▶  [FastAPI 서버]  ──SQL──▶  [MySQL]
```

현재 구현된 기능
- 회원가입 / 로그인(JWT 토큰) / 내 정보 조회
- 동아리 목록·상세 조회 (카테고리·모집중 필터)
- 동아리 등록 (시스템관리자)
- 가입신청 (재학생) → 신청 목록 조회·승인·거절 (동아리 임원)

---

## 0. 설치할 프로그램 (처음 한 번만)

| 프로그램 | 확인 방법 | 비고 |
|---|---|---|
| Python 3.12 | 터미널에 `python --version` | 설치할 때 **"Add python.exe to PATH" 체크 필수** |
| MySQL 8 | `MySQL Workbench` 실행되는지 | 설치 중 정한 **root 비밀번호를 메모** |
| VS Code | - | 확장 탭에서 **Python**(Microsoft) 설치 |

> Python 3.13 이상도 대부분 되지만, 설치 오류를 줄이려면 3.12를 권장합니다.

---

## 1. VS Code로 폴더 열기

1. zip을 원하는 곳에 압축 해제 (경로에 한글·공백 없는 곳 추천, 예: `C:\dev\clubit-backend`)
2. VS Code → **파일 → 폴더 열기** → `clubit-backend` 폴더 선택
   - 왼쪽 탐색기에 `app` 폴더, `requirements.txt`, `README.md`가 바로 보여야 정상
3. ``Ctrl + ` `` 로 터미널 열기 (이후 명령은 전부 여기에)

## 2. 가상환경 만들고 켜기

```powershell
python -m venv venv
.\venv\Scripts\activate
```

- 성공하면 터미널 줄 앞에 `(venv)` 표시
- "스크립트를 실행할 수 없습니다" 오류가 나면 아래 실행 후 다시 activate
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```
- 오른쪽 아래 "인터프리터로 선택할까요?" 팝업 → **Yes**
- Mac: `python3 -m venv venv` → `source venv/bin/activate`

> VS Code를 다시 켤 때마다 `(venv)`가 없으면 `.\venv\Scripts\activate` 를 다시 실행하세요.

## 3. 패키지 설치

```powershell
pip install -r requirements.txt
```

## 4. MySQL에 DB 만들기

MySQL Workbench → root로 접속 → 쿼리 창에 아래를 붙여넣고 번개 버튼(실행)

```sql
CREATE DATABASE clubit DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

테이블은 만들 필요 없습니다. 서버가 처음 켜질 때 자동으로 만듭니다.

## 5. `.env` 파일 만들기

```powershell
copy .env.example .env
```

VS Code에서 `.env`를 열고 수정 후 저장:

```
DB_PASSWORD=MySQL설치할때정한비밀번호
JWT_SECRET=아래명령으로만든긴문자열
```

JWT_SECRET 만들기:
```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

> `.env`는 비밀번호가 들어있으므로 **GitHub에 올리지 않습니다** (`.gitignore`에 이미 등록됨).

## 6. 테스트용 기본 데이터 넣기

```powershell
python -m app.seed
```

`기본 데이터 준비 완료`가 나오면 성공. 만들어지는 것:
- 시스템관리자: `admin@clubit.com` / `admin1234`
- 동아리 임원: `officer@clubit.com` / `officer1234` (코딩하는사람들 임원)
- 샘플 동아리 3개

## 7. 서버 실행

```powershell
uvicorn app.main:app --reload
```

`Application startup complete.` 가 나오면 성공. **이 터미널은 끄지 마세요** (끄면 서버 꺼짐).
`--reload` 덕분에 코드를 저장하면 서버가 자동으로 다시 켜집니다.

## 8. 브라우저에서 테스트 (`http://localhost:8000/docs`)

각 API를 펼치고 **Try it out → (값 입력) → Execute**

1. `GET /clubs` → 동아리 3개가 보이면 DB 연결 성공
2. `POST /auth/signup` → 본인 정보로 회원가입
   ```json
   {"email": "test@test.com", "password": "test1234", "name": "김건우", "student_id": "2021000000"}
   ```
3. `POST /auth/login` → `access_token` 값 복사
4. 페이지 오른쪽 위 **Authorize** 버튼 → 복사한 토큰 붙여넣기 → Authorize
5. `GET /auth/me` → 내 정보 나오면 로그인 성공
6. `POST /clubs/1/join` → 가입신청 (상태 `PENDING`)
7. Authorize에서 **Logout** → `officer@clubit.com`으로 로그인한 토큰으로 다시 Authorize
8. `GET /clubs/1/applications` → 방금 신청 확인 → `PATCH /clubs/1/applications/{id}` 에 `{"status": "APPROVED"}`

## API 목록

| 메서드 | 주소 | 권한 | 설명 |
|---|---|---|---|
| GET | `/` | 누구나 | 서버 상태 확인 |
| POST | `/auth/signup` | 누구나 | 회원가입 |
| POST | `/auth/login` | 누구나 | 로그인 → 토큰 발급 |
| GET | `/auth/me` | 로그인 | 내 정보 |
| GET | `/clubs?category=&recruiting=` | 누구나 | 동아리 목록 |
| GET | `/clubs/{id}` | 누구나 | 동아리 상세 |
| POST | `/clubs` | 시스템관리자 | 동아리 등록 |
| POST | `/clubs/{id}/join` | 로그인 | 가입신청 |
| GET | `/clubs/{id}/applications` | 동아리 임원 | 대기 중 신청 목록 |
| PATCH | `/clubs/{id}/applications/{membership_id}` | 동아리 임원 | 승인/거절 |

Flutter에서 로그인 후 요청할 때는 헤더에 `Authorization: Bearer <토큰>` 을 붙입니다.

## 파일 구조 (각 파일이 하는 일)

```
clubit-backend/
├─ app/
│  ├─ main.py        서버 시작점. 라우터 연결, 테이블 자동 생성
│  ├─ config.py      .env 읽기 (DB 주소, JWT 비밀키)
│  ├─ database.py    DB 연결, 요청마다 세션 제공(get_db)
│  ├─ models.py      테이블 정의: users, clubs, memberships
│  ├─ schemas.py     앱과 주고받는 JSON 형식(요청/응답)
│  ├─ security.py    비밀번호 암호화, 토큰 발급·검사, 권한 체크
│  ├─ seed.py        테스트용 기본 데이터
│  └─ routers/
│     ├─ auth.py     회원가입·로그인·내정보
│     └─ clubs.py    동아리 조회·등록·가입신청·승인
├─ requirements.txt  설치할 패키지 목록
├─ .env.example      .env 견본
└─ .gitignore        GitHub에 안 올릴 파일 목록
```

새 기능(예: 게시물)을 추가할 때 순서: `models.py`에 테이블 → `schemas.py`에 JSON 형식 → `routers/posts.py` 작성 → `main.py`에 `include_router` 한 줄 추가.

## 자주 나는 오류

| 오류 메시지 | 원인 / 해결 |
|---|---|
| `'python'은(는) ... 인식되지 않습니다` | Python 설치 시 PATH 체크 안 함 → 재설치 |
| `No module named 'fastapi'` | 가상환경이 꺼짐 → `.\venv\Scripts\activate` 후 다시 |
| `No module named 'app'` | 폴더를 잘못 엶 → `requirements.txt` 있는 폴더를 열기 |
| `Access denied for user 'root'` | `.env`의 `DB_PASSWORD` 틀림 |
| `Unknown database 'clubit'` | 4번 DB 생성 안 함 |
| `Can't connect to MySQL server` | MySQL이 꺼져 있음 → Windows 서비스에서 MySQL80 시작 |
| `[Errno 10048] ... address already in use` | 서버가 이미 켜져 있음 → 기존 터미널에서 `Ctrl+C` |

## 다음 단계 (배포 대비)

1. 게시물/댓글/즐겨찾기 API 추가
2. LLM 작성 보조 API (`/ai/...`) 추가 — API 키는 `.env`에만
3. 테이블 변경 관리를 `create_all` → **Alembic** 으로 교체
4. Dockerfile 작성 → 클라우드 서버 + 클라우드 MySQL 배포 → HTTPS
5. 배포 시 `main.py`의 CORS `allow_origins`를 실제 주소로 좁히기
