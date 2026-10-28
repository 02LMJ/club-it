# Club-it 백엔드 (FastAPI + SQLAlchemy + MySQL)

```
[Flutter 앱 (mobile/)]  ──HTTP(JSON)──▶  [FastAPI 서버 (backend/)]  ──SQL──▶  [MySQL]
                                                  └──▶ [LLM API] (작성 보조)
```

| 항목 | 값 |
|---|---|
| 폴더 | `club-it/backend` |
| Python | 3.12 권장 (3.11 이상) |
| 패키지 | `requirements.txt` (FastAPI 0.115+, SQLAlchemy 2.0+, PyMySQL) |
| DB 접속 | `.env` 파일 (`.env.example` 복사해서 작성, **GitHub에 올리지 않음**) |
| 테이블 생성 | `db/clubit_schema.sql`(태수)로 생성 (서버는 테이블을 만들지 않음) |
| 포트 | **8001** (`localhost:8001/docs`) |

## 구현된 기능

| 구분 | 기능 |
|---|---|
| 회원 | 회원가입, 로그인(JWT), 내 정보 |
| 동아리 | 목록(검색·분야·모집중 필터, 삭제된 동아리 제외), 상세, 등록(OFFICER 권한 → 등록자가 임원으로 자동 등록) |
| 가입신청 | 신청(신청서 내용), 신청 취소(CANCELED), 거절·취소 후 재신청, 내 신청/가입 현황 |
| 임원 | 신청 목록, 승인/거절(거절 사유), 멤버 목록 |
| 게시물·댓글 | 게시물 CRUD(작성은 임원, 종류 RECRUIT/NOTICE/PROMO, 종류별 필터), 댓글 CRUD, 댓글 수 표시 |
| 즐겨찾기 | 추가/삭제, 새 글 알림 켜기/끄기, 내 즐겨찾기 |
| 알림 | 새 게시물 알림(즐겨찾기+알림 켠 사용자, 누르면 게시물로 이동할 post_id 포함), 가입 승인·거절 알림, 읽음 처리, 안 읽은 개수 |
| 관리자 | 사용자 목록, OFFICER 지정·회수(회수 시 소속 동아리 임원 권한 즉시 해제), 임원 목록 |
| LLM 작성보조 | 제목 추천(5개), 본문 초안, 문장 개선, 요약 — 모집글/공지사항/홍보글 |

권한 정리
- `user.role`: STUDENT / OFFICER(동아리 **등록** 권한, 관리자가 지정) / ADMIN
- 동아리 안의 임원 권한(게시물 작성, 가입 승인·거절): `membership.member_role='OFFICER' AND status='APPROVED'` (ADMIN은 모든 동아리에서 임원 권한)

---

## 처음 실행하기 (Windows / VS Code)

### 0. 설치 (처음 한 번)
- Python 3.12 (설치 시 **Add python.exe to PATH** 체크)
- MySQL 8.4 (root 비밀번호 메모)
- VS Code + Python 확장

### 1. 가상환경 + 패키지
VS Code → **파일 → 폴더 열기 → `club-it\backend`** → 터미널(``Ctrl+` ``)
```powershell
python -m venv venv
.\venv\Scripts\activate          # 앞에 (venv) 표시되면 성공
pip install -r requirements.txt
```
> "스크립트를 실행할 수 없습니다" → `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` 후 다시 activate

### 2. `.env`
```powershell
copy .env.example .env
python -c "import secrets; print(secrets.token_hex(32))"   # JWT_SECRET 값 생성
notepad .env
```
`DB_PASSWORD`(MySQL root 비밀번호)와 `JWT_SECRET`을 채우고 저장.

### 3. DB 만들기 (테이블 + 더미 데이터)
```powershell
python -m app.init_db      # db/clubit_schema.sql 실행 (기존 clubit DB는 지워짐!)
python -m app.seed         # 더미 계정 비밀번호를 test1234로 설정
```

### 4. 서버 실행
```powershell
uvicorn app.main:app --reload --port 8001
```
테스트 계정 (비밀번호 모두 `test1234`)
- 관리자: `admin@cbnu.ac.kr`
- 임원(OFFICER): `officer1@cbnu.ac.kr` (CATS·COSMIC), `officer2@cbnu.ac.kr` (IPSE·CERT)
- 학생: `student1@cbnu.ac.kr` ~ `student3@cbnu.ac.kr`

브라우저에서 `http://localhost:8001/docs` → 로그인 → 오른쪽 위 **Authorize**에 토큰 붙여넣기 → 각 API **Try it out → Execute**

---

## API 목록

화면별로 어떤 API를 부르는지는 [`docs/app-server-flow.md`](../docs/app-server-flow.md) 참고.

로그인이 필요한 API는 헤더에 `Authorization: Bearer <access_token>`

| 메서드 | 주소 | 권한 | 설명 |
|---|---|---|---|
| POST | `/auth/signup` | 누구나 | 회원가입 `{email, password(8자+), name}` |
| POST | `/auth/login` | 누구나 | 로그인 → `access_token` |
| GET | `/auth/me` | 로그인 | 내 정보 |
| GET | `/clubs?q=&category=&recruiting=&skip=&limit=` | 누구나 | 동아리 목록 |
| GET | `/clubs/{club_id}` | 누구나 | 동아리 상세 (목록·상세 모두 `member_count`, 토큰 보내면 `is_favorite`·`my_status`·`my_role` 포함) |
| POST | `/clubs` | OFFICER·관리자 | 동아리 등록 → 등록자 membership(OFFICER, APPROVED) 자동 생성 |
| PATCH | `/clubs/{club_id}` | 동아리 임원 | 동아리 정보·모집 여부 수정 (보낸 필드만) |
| DELETE | `/clubs/{club_id}` | 동아리 임원 | 동아리 삭제 (is_deleted=TRUE, 목록에서 숨김) |
| POST | `/clubs/{club_id}/join` | 로그인 | 가입신청 `{message}` (선택) |
| POST | `/clubs/{club_id}/join/cancel` | 로그인 | 대기 중 신청 취소 |
| GET | `/me/memberships?status=` | 로그인 | 내 신청·가입 현황 (동아리명, 거절 사유 포함) |
| GET | `/clubs/{club_id}/applications?status=PENDING` | 임원 | 신청 목록 (신청자 이름·이메일) |
| PATCH | `/clubs/{club_id}/applications/{membership_id}` | 임원 | `{status: APPROVED/REJECTED, reject_reason}` |
| GET | `/clubs/{club_id}/members` | 임원 | 멤버 목록 |
| GET | `/clubs/{club_id}/posts?post_type=&skip=&limit=` | 누구나 | 게시물 목록 (최신순, 작성자명·댓글 수, 종류 필터) |
| POST | `/clubs/{club_id}/posts` | 임원 | 게시물 작성 `{post_type, title, content}` → 알림 발송 |
| GET | `/posts/{post_id}` | 누구나 | 게시물 상세 |
| PATCH | `/posts/{post_id}` | 작성자 | 게시물 수정 |
| DELETE | `/posts/{post_id}` | 작성자·임원 | 게시물 삭제 (댓글 함께 삭제) |
| GET | `/posts/{post_id}/comments` | 누구나 | 댓글 목록 |
| POST | `/posts/{post_id}/comments` | 로그인 | 댓글 작성 `{content}` |
| PATCH | `/comments/{comment_id}` | 작성자 | 댓글 수정 |
| DELETE | `/comments/{comment_id}` | 작성자·임원 | 댓글 삭제 |
| GET | `/me/favorites` | 로그인 | 내 즐겨찾기 |
| POST | `/clubs/{club_id}/favorite` | 로그인 | 즐겨찾기 추가 (알림 기본 켜짐) |
| PATCH | `/clubs/{club_id}/favorite` | 로그인 | `{notify_enabled: true/false}` |
| DELETE | `/clubs/{club_id}/favorite` | 로그인 | 즐겨찾기 해제 |
| GET | `/notifications?unread_only=` | 로그인 | 내 알림 (최신순, `post_id` 있으면 게시물로 이동) |
| GET | `/notifications/unread-count` | 로그인 | 안 읽은 알림 수 (앱 배지용) |
| PATCH | `/notifications/{notification_id}/read` | 로그인 | 읽음 처리 |
| POST | `/notifications/read-all` | 로그인 | 모두 읽음 |
| POST | `/ai/assist` | 로그인 | LLM 작성 보조 (아래 참고) |
| GET | `/admin/users?role=&q=` | 관리자 | 사용자 목록 |
| PATCH | `/admin/users/{user_id}/role` | 관리자 | `{role: OFFICER}` 지정 / `{role: STUDENT}` 회수 |
| GET | `/admin/officers` | 관리자 | OFFICER 사용자 + 임원으로 소속된 동아리 |

### LLM 작성 보조 `POST /ai/assist`
```json
{"task": "title", "post_type": "RECRUIT", "club_id": 1, "text": "개발 스터디 신입 모집, 주 1회"}
```
| task | text에 넣을 것 | 결과 |
|---|---|---|
| `title` | 본문 | `suggestions`에 제목 후보 5개 |
| `draft` | 키워드/메모 | `result`에 본문 초안 (없는 정보는 "(입력 필요)") |
| `improve` | 원문 | `result`에 다듬은 글 |
| `summary` | 원문 | `result`에 2~3문장 요약 |

`.env`의 `LLM_PROVIDER`로 선택:
- `mock` (기본) — API 키 없이 예시 응답. **앱 화면 개발은 이걸로 충분**
- `anthropic` — `LLM_API_KEY` 입력 (모델 기본값 `claude-haiku-5-5`, `LLM_MODEL`로 변경)
- `openai` — `LLM_API_KEY`, `LLM_MODEL` 입력
- `ollama` — `OLLAMA_URL`, `LLM_MODEL` (로컬/교내 서버 모델)

---

## 파일 구조

```
backend/
├─ app/
│  ├─ main.py            서버 시작점, 라우터 연결
│  ├─ config.py          .env 읽기
│  ├─ database.py        DB 연결
│  ├─ models.py          테이블 구조 (db/clubit_schema.sql과 1:1로 맞춤)
│  ├─ schemas.py         요청/응답 JSON 형식
│  ├─ security.py        비밀번호·토큰·권한(임원 판별)
│  ├─ llm.py             LLM 호출 (mock/anthropic/openai/ollama)
│  ├─ init_db.py         db/clubit_schema.sql 실행 (DB 초기화)
│  ├─ seed.py            더미 계정 비밀번호 설정
│  └─ routers/
│     ├─ auth.py         회원
│     ├─ clubs.py        동아리 조회·등록 (동아리 관리 = 태수)
│     ├─ memberships.py  가입신청·승인·멤버
│     ├─ posts.py        게시물·댓글·새 글 알림
│     ├─ favorites.py    즐겨찾기
│     ├─ notifications.py 알림
│     ├─ ai.py           LLM 작성 보조
│     └─ admin.py        관리자: OFFICER 지정·회수, 임원 목록
├─ db/clubit_schema.sql 테이블 생성 SQL (태수)
├─ requirements.txt
└─ .env.example
```

**DB 컬럼을 바꿀 때**: `db/clubit_schema.sql` 수정 → `models.py` 같이 수정 → `schemas.py`(응답에 필요하면) 수정.

## Flutter에서 접속 주소
- 안드로이드 에뮬레이터: `http://10.0.2.2:8001`
- 실제 휴대폰(같은 와이파이): `http://<PC IP>:8001` — 서버를 `--host 0.0.0.0`으로 실행
- 웹/윈도우 앱: `http://localhost:8001`

## 자주 나는 오류

| 메시지 | 해결 |
|---|---|
| `No module named 'fastapi'` | `(venv)` 꺼짐 → `.\venv\Scripts\activate` |
| `No module named 'app'` | `backend` 폴더에서 실행 |
| `Access denied for user 'root'` | `.env`의 `DB_PASSWORD` 확인 |
| `Table 'clubit.user' doesn't exist` | `python -m app.init_db` 실행 안 함 |
| `Unknown column ...` | 예전 테이블 → `python -m app.init_db`로 다시 생성 |
| `Can't connect to MySQL server` | Windows 서비스에서 MySQL84 시작 |
| `address already in use` | 이미 켜진 서버를 `Ctrl+C`로 종료 |
| `/ai/assist` 502 | `.env`의 LLM 설정(키·모델명) 확인 |

## 다음 단계
- [ ] 이미지 업로드(동아리 로고·게시물 사진) 필요 여부 결정
- [ ] RAG 기반 동아리 추천 (지도교수 제안)
- [ ] 배포: Dockerfile → 클라우드 서버 + 클라우드 MySQL → HTTPS, `CORS_ORIGINS` 좁히기
