-- ============================================================
-- Club-it DB schema (MySQL 8.x)
-- 기준 문서: 소프트웨어공학 요구사항 정의서/상세설계서 (6. 테이블 정의서, 48~50쪽)
-- 문서의 컬럼/타입은 그대로 두고, 이수신청서(2026-2학기)와 요구사항에서
-- 필요한 것만 "[추가]" 로 표시해서 덧붙였습니다.
--
-- 실행 주의: 맨 위의 DROP DATABASE 는 기존 clubit DB 를 통째로 지웁니다.
-- ============================================================

DROP DATABASE IF EXISTS clubit;
CREATE DATABASE clubit DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE clubit;

-- 1. USER ------------------------------------------------------
CREATE TABLE user (
    user_id     INT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL,
    role        VARCHAR(20)  NOT NULL DEFAULT 'STUDENT',     -- STUDENT / OFFICER / ADMIN
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    password    VARCHAR(255) NOT NULL,                       -- [추가] 비밀번호 해시(BCrypt) 저장 (요구사항: 해시 저장)
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_user_email (email),                        -- FR01-02 이메일 중복 가입 불가
    CONSTRAINT ck_user_role CHECK (role IN ('STUDENT','OFFICER','ADMIN'))
) ENGINE=InnoDB;

-- 2. CLUB ------------------------------------------------------
CREATE TABLE club (
    club_id         INT          NOT NULL AUTO_INCREMENT,
    club_name       VARCHAR(100) NOT NULL,
    description     TEXT         NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    category        VARCHAR(50)  NULL,                       -- [추가] 이수신청서: 동아리 카테고리
    recruit_status  BOOLEAN      NOT NULL DEFAULT FALSE,     -- [추가] 이수신청서: 모집 여부
    is_deleted      BOOLEAN      NOT NULL DEFAULT FALSE,     -- [추가] 클래스 문서 Club.delete(): "삭제 상태로 변경"
    PRIMARY KEY (club_id),
    UNIQUE KEY uq_club_name (club_name)                      -- [추가] 같은 이름 동아리 중복 방지
) ENGINE=InnoDB;

-- 3. MEMBERSHIP ------------------------------------------------
CREATE TABLE membership (
    membership_id  INT          NOT NULL AUTO_INCREMENT,
    user_id        INT          NOT NULL,
    club_id        INT          NOT NULL,
    member_role    VARCHAR(20)  NOT NULL DEFAULT 'MEMBER',  -- MEMBER / OFFICER (동아리 임원 표시)
    join_date      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- 클래스 문서: 가입 신청이 이루어진 날짜
    status         VARCHAR(20)  NOT NULL DEFAULT 'PENDING', -- [추가] FR05: 신청 대기/승인/거부/취소
    reject_reason  VARCHAR(500) NULL,                        -- [추가] FR05-05: 거부 사유
    message        TEXT         NULL,                        -- [추가] 화면정의서 그림27: 신청서 내용(가입 사유)
    PRIMARY KEY (membership_id),
    UNIQUE KEY uq_membership_user_club (user_id, club_id),   -- [추가] 중복 신청 방지 (취소 후 재신청은 같은 행을 PENDING 으로 갱신)
    CONSTRAINT fk_membership_user FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_membership_club FOREIGN KEY (club_id) REFERENCES club(club_id) ON DELETE CASCADE,
    CONSTRAINT ck_membership_role   CHECK (member_role IN ('MEMBER','OFFICER')),
    CONSTRAINT ck_membership_status CHECK (status IN ('PENDING','APPROVED','REJECTED','CANCELED'))
) ENGINE=InnoDB;

-- 4. POST ------------------------------------------------------
CREATE TABLE post (
    post_id     INT          NOT NULL AUTO_INCREMENT,
    user_id     INT          NOT NULL,
    club_id     INT          NOT NULL,
    title       VARCHAR(200) NOT NULL,
    content     TEXT         NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    post_type   VARCHAR(20)  NOT NULL DEFAULT 'NOTICE',      -- [추가] RECRUIT(모집글) / NOTICE(공지사항) / PROMO(활동 홍보글)
    PRIMARY KEY (post_id),
    KEY idx_post_club_created (club_id, created_at),         -- [추가] FR10-04: 동아리별 최신순 조회용
    CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_post_club FOREIGN KEY (club_id) REFERENCES club(club_id) ON DELETE CASCADE,
    CONSTRAINT ck_post_type CHECK (post_type IN ('RECRUIT','NOTICE','PROMO'))
) ENGINE=InnoDB;

-- 5. COMMENT ---------------------------------------------------
CREATE TABLE comment (
    comment_id  INT      NOT NULL AUTO_INCREMENT,
    user_id     INT      NOT NULL,
    post_id     INT      NOT NULL,
    content     TEXT     NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (comment_id),
    CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_post FOREIGN KEY (post_id) REFERENCES post(post_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. FAVORITE --------------------------------------------------
CREATE TABLE favorite (
    favorite_id     INT      NOT NULL AUTO_INCREMENT,
    user_id         INT      NOT NULL,
    club_id         INT      NOT NULL,
    notify_enabled  BOOLEAN  NOT NULL DEFAULT TRUE,          -- [추가] FR10-02/03: 동아리별 게시물 알림 해제/재활성화
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- [추가] 클래스 문서 dateFavorited
    PRIMARY KEY (favorite_id),
    UNIQUE KEY uq_favorite_user_club (user_id, club_id),     -- [추가] 중복 즐겨찾기 방지
    CONSTRAINT fk_favorite_user FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_favorite_club FOREIGN KEY (club_id) REFERENCES club(club_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. NOTIFICATION ----------------------------------------------
CREATE TABLE notification (
    notification_id  INT          NOT NULL AUTO_INCREMENT,
    user_id          INT          NOT NULL,
    message          VARCHAR(255) NOT NULL,
    is_read          BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    post_id          INT          NULL,                      -- [추가] 알림을 눌렀을 때 이동할 게시물
    PRIMARY KEY (notification_id),
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_post FOREIGN KEY (post_id) REFERENCES post(post_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ===================== 더미 데이터 =====================
-- password 는 자리표시 문자열입니다. 이 계정들로는 로그인되지 않으니,
-- 로그인 테스트는 회원가입 API 로 계정을 새로 만들어서 하세요.

INSERT INTO user (name, email, role, password) VALUES
('관리자', 'admin@cbnu.ac.kr',    'ADMIN',   'CHANGE_ME_BCRYPT_HASH'),
('김임원', 'officer1@cbnu.ac.kr', 'OFFICER', 'CHANGE_ME_BCRYPT_HASH'),
('이임원', 'officer2@cbnu.ac.kr', 'OFFICER', 'CHANGE_ME_BCRYPT_HASH'),
('박학생', 'student1@cbnu.ac.kr', 'STUDENT', 'CHANGE_ME_BCRYPT_HASH'),
('최학생', 'student2@cbnu.ac.kr', 'STUDENT', 'CHANGE_ME_BCRYPT_HASH'),
('정학생', 'student3@cbnu.ac.kr', 'STUDENT', 'CHANGE_ME_BCRYPT_HASH');

INSERT INTO club (club_name, description, category, recruit_status) VALUES
('CATS',   '컴퓨터공학 기반 학술 동아리', '학술', TRUE),
('COSMIC', '천문/우주 탐구 동아리',        '학술', FALSE),
('IPSE',   '지역 사회 봉사 동아리',        '봉사', TRUE),
('CERT',   '정보보안 스터디 동아리',       '학술', TRUE);

-- 임원: 동아리를 등록한 사람은 member_role='OFFICER', status='APPROVED' 로 membership 에 들어갑니다.
INSERT INTO membership (user_id, club_id, member_role, status, message, reject_reason) VALUES
(2, 1, 'OFFICER', 'APPROVED', NULL, NULL),
(2, 2, 'OFFICER', 'APPROVED', NULL, NULL),
(3, 3, 'OFFICER', 'APPROVED', NULL, NULL),
(3, 4, 'OFFICER', 'APPROVED', NULL, NULL),
(4, 1, 'MEMBER',  'PENDING',  '프로그래밍을 배우고 싶습니다.', NULL),
(5, 1, 'MEMBER',  'APPROVED', '스터디에 참여하고 싶습니다.',   NULL),
(6, 1, 'MEMBER',  'REJECTED', '관심이 있어 지원합니다.',       '이번 학기 모집 정원 마감'),
(4, 3, 'MEMBER',  'PENDING',  '봉사 활동에 관심이 많습니다.',  NULL);

INSERT INTO post (user_id, club_id, title, content, post_type) VALUES
(2, 1, 'CATS 신입 부원 모집', '컴퓨터공학 관심 있는 누구나 지원 가능합니다.', 'RECRUIT'),
(2, 1, '이번 주 스터디 공지', '목요일 저녁 7시 공학관에서 진행합니다.',       'NOTICE'),
(3, 3, 'IPSE 봉사활동 안내',  '11월 첫째 주 토요일 봉사 활동이 있습니다.',      'NOTICE');

INSERT INTO comment (user_id, post_id, content) VALUES
(4, 1, '지원하고 싶습니다!'),
(5, 1, '모집 기간이 언제까지인가요?'),
(5, 2, '참석하겠습니다.');

INSERT INTO favorite (user_id, club_id, notify_enabled) VALUES
(4, 1, TRUE),
(4, 3, FALSE),
(5, 1, TRUE);

INSERT INTO notification (user_id, message, is_read, post_id) VALUES
(4, 'CATS 에 새 게시물이 등록되었습니다: 이번 주 스터디 공지', FALSE, 2),
(5, 'CATS 에 새 게시물이 등록되었습니다: 이번 주 스터디 공지', TRUE,  2);
