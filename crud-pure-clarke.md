# 블로그 CRUD 과제 설계

## Context
CRUD 강의 과제로 블로그를 제작하기 위한 설계 문서. 코드 작성 전 단계로, 테이블(스키마)과 페이지 목록을 먼저 확정한다.
확인된 요구사항:
- 회원가입/로그인 포함 (작성자 정보는 로그인한 회원 정보와 연결)
- 부가 기능: 카테고리, 태그, 이미지 업로드
- 관계형 DB(MySQL/PostgreSQL 등) 기준으로 설계

---

## 1. 테이블 설계 (ERD)

> **인증**: 회원가입/로그인은 Supabase Auth(`auth.users`)가 담당한다 — 이메일·비밀번호 저장·해싱을 Supabase가 자동 처리하며, RLS의 `auth.uid()`로 "본인 글만 수정·삭제" 같은 인가를 DB 단에서 실제로 강제할 수 있다(커스텀 `users` 테이블 + anon key 조합으로는 이 강제가 불가능해 채택). 앱 전용 프로필 정보만 아래 `profiles` 테이블에 별도로 둔다.

### profiles (회원 프로필 — `auth.users` 확장)
| 컬럼명 | 타입 | 설명 |
|---|---|---|
| id | UUID (PK) | `auth.users.id`를 그대로 참조(FK) — 회원가입 시 트리거로 자동 생성 |
| nickname | VARCHAR(50) | 화면에 노출되는 작성자 이름 |
| profile_image | VARCHAR(500), NULL | 프로필 이미지 URL |
| role | VARCHAR(20), DEFAULT 'USER' | USER / ADMIN 등 권한 구분 |
| created_at | DATETIME | 가입일 |
| updated_at | DATETIME | 정보 수정일 |

### categories (카테고리)
| 컬럼명 | 타입 | 설명 |
|---|---|---|
| id | BIGINT (PK, AI) | 카테고리 고유 번호 |
| name | VARCHAR(50), UNIQUE | 카테고리 이름 (예: 일상, 개발, 여행) |
| is_private | BOOLEAN, DEFAULT false | true면 해당 카테고리 글은 작성자 본인만 열람 가능 (예: 일기) |
| created_at | DATETIME | 생성일 |

### posts (게시글)
| 컬럼명 | 타입 | 설명 |
|---|---|---|
| id | BIGINT (PK, AI) | 게시글 고유 번호 |
| user_id | UUID (FK → profiles.id) | **작성자 정보** — 글쓴이 |
| category_id | BIGINT (FK → categories.id), NULL | 소속 카테고리 (1글 : 1카테고리) |
| title | VARCHAR(200) | 제목 |
| content | TEXT | 본문 (에디터 HTML 또는 마크다운) |
| thumbnail_image | VARCHAR(500), NULL | 대표 이미지 URL |
| attachment_url | VARCHAR(500), NULL | 첨부파일 URL (이미지 외 PDF 등) |
| attachment_name | VARCHAR(255), NULL | 첨부파일 원본 파일명 |
| view_count | INT, DEFAULT 0 | 조회수 |
| created_at | DATETIME | 작성일 |
| updated_at | DATETIME | 수정일 |

### tags (태그)
| 컬럼명 | 타입 | 설명 |
|---|---|---|
| id | BIGINT (PK, AI) | 태그 고유 번호 |
| name | VARCHAR(50), UNIQUE | 태그명 (예: #자바, #스프링) |

### post_tags (게시글-태그 연결, N:M)
| 컬럼명 | 타입 | 설명 |
|---|---|---|
| post_id | BIGINT (FK → posts.id) | 게시글 |
| tag_id | BIGINT (FK → tags.id) | 태그 |
| — | PK(post_id, tag_id) | 복합 기본키 |

### post_images (게시글 첨부 이미지, 선택 확장)
> 본문 안에 이미지를 여러 장 넣고 싶을 때만 추가. 대표 이미지 1장이면 `posts.thumbnail_image`만으로 충분.

| 컬럼명 | 타입 | 설명 |
|---|---|---|
| id | BIGINT (PK, AI) | 이미지 고유 번호 |
| post_id | BIGINT (FK → posts.id) | 소속 게시글 |
| image_url | VARCHAR(500) | 이미지 경로/URL |
| created_at | DATETIME | 업로드일 |

### 관계 요약
- profiles(=auth.users) 1 : N posts (한 회원이 여러 글 작성, 작성자 정보는 여기서 옴)
- categories 1 : N posts
- posts N : M tags (post_tags 통해 연결)
- posts 1 : N post_images (선택)

---

## 2. 페이지 목록

| 페이지 | 파일 | 설명 | 권한 |
|---|---|---|---|
| 회원가입 | `signup.html` | 이메일/비밀번호/닉네임 입력 | 비로그인 |
| 로그인 | `login.html` | 이메일/비밀번호 로그인 | 비로그인 |
| 비밀번호 재설정 요청 | `forgot-password.html` | 이메일 입력 → 재설정 메일 발송 | 비로그인 |
| 새 비밀번호 설정 | `reset-password.html` | 이메일 링크로 진입해 새 비밀번호 설정 | 비로그인(이메일 링크 필요) |
| 게시글 목록 (홈) | `index.html` | 전체 글 목록, 카테고리/태그 필터(`?category=`,`?tag=`), 페이지네이션(`?page=`) | 전체 |
| 게시글 상세 | `post-detail.html?id=` | 제목/본문/작성자/작성일/카테고리/태그 표시, 조회수 증가 | 전체 |
| 게시글 작성 | `post-new.html` | 제목/본문/카테고리/태그/이미지 업로드 | 로그인 필요 |
| 게시글 수정 | `post-edit.html?id=` | 기존 내용 불러와 수정 | 작성자 본인만 |
| 게시글 삭제 | (버튼, 별도 페이지 없음) | 상세/마이페이지에서 삭제 버튼 → 확인 후 삭제 | 작성자 본인만 |
| 마이페이지 | `mypage.html` | 내 프로필 정보, 내가 쓴 글 목록 | 로그인 필요 |
| 프로필 수정 | `mypage-edit.html` | 닉네임/프로필 이미지 수정 | 로그인 필요 |
| 관리자 | `admin.html` | 전체 글 관리(수정/삭제), 카테고리 관리(추가/공개-비공개 전환/삭제), 회원 목록·관리자 권한 부여 | `profiles.role = 'ADMIN'`만 |

> 정적 HTML(경로 라우팅 없음) 기준이라 카테고리/태그별 목록은 별도 페이지 대신 `index.html`의 쿼리 파라미터 필터로 구현했다.

---

## 3. 설계 시 고려사항
- 비밀번호는 Supabase Auth가 자동으로 해시 저장 — 별도 구현·평문 저장 없음
- 로그인 상태 유지는 Supabase Auth의 세션(JWT)을 그대로 사용
- 게시글 수정/삭제는 `posts.user_id`와 로그인한 `auth.uid()`가 일치하는지 **DB의 RLS 정책**에서 강제 (`supabase/schema.sql` 참고) — URL 조작·API 직접 호출로도 우회 불가
- `profiles.role = 'ADMIN'`인 계정은 `is_admin()` 함수(security definer)를 통해 RLS 정책에서 예외적으로 전체 글/카테고리/회원을 관리할 수 있음 (`supabase/migration-admin.sql` 참고) — 최초 관리자 지정은 SQL로 1회 수동 실행 필요
- 이미지 업로드는 로컬 디스크 저장 또는 S3 등 외부 스토리지 중 선택, DB에는 URL/경로만 저장
- `category_id`는 NULL 허용(미분류) 여부를 강의 요구사항에 맞춰 결정

---

## 4. 과제 안내

- 주제: 블로그 페이지 만들기
- 상세 내용: 게시글 생성/수정/삭제/보기 기능 구현, Supabase 연동해 데이터 확인 & 게시글 관리 기능 추가
- 기한: 2026-07-23(목) 17:00
- 제출 방법: 완료한 페이지 URL을 Slack에 남기기
- 추가 과제(완료자용): PRD.md 작성 — 강사님 안내는 "완료 후 작성"이었으나, 이번엔 정석대로 **개발 착수 전** 요구사항 명세로 먼저 작성함 (`prd.md` 참고)

---

## 5. 작업 순서 (PRD 선행)

PRD(`prd.md`) 작성이 개발 착수보다 먼저 진행된다:

1. **설계 (완료)**: 테이블(ERD)·페이지 목록 확정 — 본 문서 1~3번
2. **PRD 작성 (완료)**: 기능/비기능 요구사항, 수용기준(Given/When/Then) 확정 — `prd.md`
3. **로컬 구현**: 프레임워크/언어 확정 → 테이블을 마이그레이션/엔티티로 구현 → 인증(회원가입/로그인) → 게시글 CRUD → 카테고리/태그 → 이미지 업로드 순으로 단계별 구현, Supabase 연동
4. **배포 및 제출**: Live Server로 로컬 확인 후 배포, URL을 Slack에 제출 (기한: 2026-07-23(목) 17:00)
