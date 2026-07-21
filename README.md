# 블로그 CRUD 프로젝트

설계 문서: [crud-pure-clarke.md](crud-pure-clarke.md) · [prd.md](prd.md) · [checklist.md](checklist.md) · [DESIGN-notion.md](DESIGN-notion.md)

## 실행 전 준비 (1회만)

1. **Supabase SQL 실행**
   Supabase 프로젝트 대시보드 → SQL Editor → [supabase/schema.sql](supabase/schema.sql) 내용을 그대로 붙여넣고 실행.
   `profiles`/`categories`/`posts`/`tags`/`post_tags` 테이블과 RLS 정책, `post-images` Storage 버킷까지 한 번에 생성됩니다.

2. **Supabase 설정값 확인**
   `js/config.js`에 이미 프로젝트 URL과 publishable(anon) key가 채워져 있습니다. 다른 Supabase 프로젝트를 쓰려면 이 값만 바꾸면 됩니다.
   (publishable/anon key는 클라이언트에 노출돼도 안전하도록 설계된 키라 이 파일도 그대로 커밋·배포합니다 — `service_role` 키만 절대 커밋하면 안 됩니다.)

3. **로컬 실행**
   VS Code에서 Live Server 확장으로 `index.html`을 열면 됩니다. (배포 없이 로컬 확인)

## 페이지 구성
`crud-pure-clarke.md`의 "2. 페이지 목록" 참고 — `index.html`, `signup.html`, `login.html`, `post-new.html`, `post-detail.html?id=`, `post-edit.html?id=`, `mypage.html`, `mypage-edit.html`.

## 인증
회원가입/로그인은 **Supabase Auth**를 사용합니다 (비밀번호 자동 해시 저장). 앱 전용 프로필(닉네임·이미지·권한)은 `profiles` 테이블에서 관리하며, 가입 시 트리거로 자동 생성됩니다.

## 완료 후 확인
[checklist.md](checklist.md)의 항목을 순서대로 체크하세요.
