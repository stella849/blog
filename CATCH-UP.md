# 캐치업 노트 — 내가(Claude) 대신 구현한 것들 정리

이 문서는 코드가 아니라 **"자고 일어나서 5분 안에 지금까지 뭘 만들었는지 따라잡기"** 용도입니다.
순서대로 읽으면 됩니다. 급하면 1번(CRUD)과 5번(내일 할 일)만 봐도 됩니다.

---

## 1. CRUD, 우리 프로젝트에서 각각 어디 있나

| 글자 | 뜻 | 트리거(화면) | 코드 위치 |
|---|---|---|---|
| **C**reate | 글 새로 만들기 | [post-new.html](post-new.html) "게시하기" 버튼 | `supabaseClient.from("posts").insert({...})` — [post-new.html:137](post-new.html#L137) |
| **R**ead | 글 목록/상세 보기 | [index.html](index.html), [post-detail.html](post-detail.html) | `.select()` — [index.html:100](index.html#L100), [post-detail.html:44](post-detail.html#L44) |
| **U**pdate | 글 수정 | [post-edit.html](post-edit.html) "수정 완료" 버튼 | `.update({...})` — [post-edit.html:184](post-edit.html#L184) |
| **D**elete | 글 삭제 | 상세/마이페이지/관리자 페이지의 "삭제" 버튼 | `.delete()` — [post-detail.html:90](post-detail.html#L90) |

같은 패턴이 카테고리(관리자 페이지에서 추가=Create, 목록=Read, 공개전환=Update, 삭제=Delete)와
회원 role(관리자 페이지에서 Read+Update)에도 똑같이 반복됩니다. CRUD를 한 번 이해하면
나머지는 다 같은 4개 동작의 반복이에요.

---

## 2. 이 프로젝트에서 "그냥 CRUD"보다 한 단계 더 들어간 것들

과제 자체는 CRUD가 핵심이지만, 진행하면서 자연스럽게 아래 개념들이 추가됐습니다.
**왜** 이렇게 했는지가 중요합니다 (누가 물어보면 이 이유로 설명하면 됩니다).

### 2-1. 회원가입/로그인을 직접 안 만들고 Supabase Auth를 씀
- 처음엔 `users` 테이블 + `password` 컬럼을 직접 만들려 했는데, 그러면 "이 글 작성자가 진짜 로그인한 나 맞나?"를
  서버(DB)가 확인할 방법이 없습니다 — 클라이언트가 "저 user_id는 3번이에요"라고 거짓말해도 막을 수 없음.
- Supabase Auth를 쓰면 `auth.uid()`라는, **위조 불가능한 로그인 사용자 ID**를 DB가 직접 알 수 있어서,
  "본인 글만 수정 가능" 같은 규칙을 진짜로 강제할 수 있습니다. → 이게 아래 RLS.

### 2-2. RLS (Row Level Security) — "본인 글만 수정 가능"을 DB가 직접 막음
- 파일: [supabase/schema.sql](supabase/schema.sql) 76번째 줄 아래
- 예: `create policy "owners can update own posts" on posts for update using (auth.uid() = user_id);`
- 뜻: "posts 테이블을 UPDATE하려는 사람이 있으면, 그 글의 user_id랑 지금 로그인한 사람이 같을 때만 허용"
- 이게 없으면 프론트엔드(HTML/JS)에서 "수정 버튼 숨기기"만 해도 되는데, 그건 개발자도구로 뚫립니다.
  RLS는 브라우저를 완전히 무시하고 서버(DB) 단에서 막아서 우회가 불가능합니다.

### 2-3. 일기 카테고리 비공개 (`is_private`)
- `categories.is_private = true`인 카테고리(일기)는 작성자 본인 로그인 상태에서만 보임.
- SQL: [supabase/schema.sql:87-94](supabase/schema.sql#L87-L94) — "이 글의 카테고리가 비공개면, 로그인한 내가 작성자일 때만 보여줘"
- RLS 정책 하나로 처리해서, 나중에 다른 카테고리도 비공개로 바꾸고 싶으면 체크박스 하나(관리자 페이지)로 끝남.

### 2-4. 관리자(admin.html) — 이건 과제 필수 요구사항은 아니었고, 요청하셔서 추가한 기능
- `profiles.role = 'ADMIN'`인 계정만 [admin.html](admin.html) 접근 가능, 전체 글/카테고리/회원 관리 가능.
- 이것도 RLS로 구현: [supabase/migration-admin.sql](supabase/migration-admin.sql)의 `is_admin()` 함수가
  "이 사람 role이 ADMIN 맞아?"를 확인해서, 맞으면 "본인 글만" 규칙에 예외를 하나 더 추가.
- 즉 admin 정책도 결국 RLS policy — 새 개념이 아니라 2-2에서 배운 걸 한 번 더 응용한 것.

### 2-5. 이미지 vs 첨부파일 — 파일 하나로 자동 분기
- 업로드 파일이 이미지(`file.type.startsWith("image/")`)면 `thumbnail_image`에, 아니면(PDF 등) `attachment_url`에 저장.
- [post-new.html:77-87](post-new.html#L77-L87)의 `uploadMedia()` 함수가 그 분기 담당.

---

## 3. 파일이 뭐가 왜 이렇게 많은지 (지도)

| 파일 | 역할 |
|---|---|
| `index.html` | 글 목록 (R) + 카테고리 필터 |
| `post-new.html` / `post-edit.html` / `post-detail.html` | C / U / R(상세)+D |
| `login.html` / `signup.html` / `forgot-password.html` / `reset-password.html` | Supabase Auth 화면들 |
| `mypage.html` / `mypage-edit.html` | 내 프로필 + 내가 쓴 글 |
| `admin.html` | 관리자 전용 CRUD (2-4 참고) |
| `js/nav.js` | 로그인 여부·관리자 여부에 따라 메뉴 보이기/숨기기 |
| `js/util.js` | `escapeHtml()` — XSS(악성 스크립트 삽입) 방지용 |
| `supabase/schema.sql` | 테이블 + RLS 정책 원본 (fresh 설치용) |
| `supabase/migration-*.sql` | 이미 만든 DB에 나중에 추가한 변경사항들 |
| `DESIGN-notion.md` | 디자인 시스템 (색/타이포/간격 기준) |
| `prd.md` / `checklist.md` | 요구사항 명세 / 완료 체크리스트 |

---

## 4. 배포 중 겪은 사고들 (내일 누가 물어보면 답할 수 있게)

1. **Live Server가 엉뚱한 페이지를 보여줌** → 알고 보니 예전에 켜놨던 파이썬 서버가 같은 포트(5500)를 이미 점유.
   포트를 5501로 바꿔서 해결.
2. **회원가입 후 로그인 안 됨** → Supabase 기본 설정이 "이메일 인증 전엔 로그인 불가"인데 에러 메시지가 불친절해서
   헷갈렸던 것. 에러 메시지를 구체화하고 비밀번호 재설정 페이지를 만들어서 해결.
3. **배포 후 글 목록이 무한 로딩** → `js/config.js`(Supabase 접속 정보)를 보안상 `.gitignore`에 넣어놨는데,
   그러면 GitHub·Vercel에 이 파일 자체가 안 올라감 → 배포본엔 Supabase 접속 정보가 아예 없어서 첫 줄부터 에러.
   이 파일 안의 키는 "공개돼도 안전한 키(publishable/anon key)"라서 그냥 커밋하는 걸로 해결.
4. **Chrome이 "위험한 사이트" 경고** → 실제 위험이 아니라, `blog-ochre-rho-27.vercel.app`처럼
   무작위 이름 서브도메인 + 로그인 폼 조합을 Chrome이 피싱 사이트 패턴으로 기계적으로 의심한 것 (오탐).

---

## 5. 내일 확인/할 일

- [ ] `checklist.md` 훑으면서 실제로 하나씩 눌러보며 확인 (특히 "권한" 섹션 — 다른 계정으로 로그인해서 남의 글 수정 시도해보기)
- [ ] 배포 사이트(`https://blog-ochre-rho-27.vercel.app`)에서 최종적으로 전체 플로우(가입→글쓰기→수정→삭제) 한 번 다시 테스트
- [ ] 제출 전, 원한다면 저랑 코드 한 파일씩 같이 읽으면서 "이 줄이 왜 이렇게 생겼는지" 리뷰
- [ ] Slack에 URL 제출 — 마감 2026-07-23(목) 17:00

수고하셨어요, 편히 주무세요.
