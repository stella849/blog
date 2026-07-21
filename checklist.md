# 완료 체크리스트 — 블로그 CRUD 프로젝트

기능 구현을 마친 뒤, 배포 전에 아래 항목을 하나씩 직접 확인한다. 각 그룹은 `prd.md`의 "2. 목표 & 성공지표(KPI)" 표와 1:1로 대응한다.

## 기능 완성도 — CRUD 4개 모두 성공
- [ ] Create: 로그인 후 `/posts/new`에서 글 작성 → Supabase `posts`에 새 행이 생성되는지 확인
- [ ] Read: `/`에서 목록이 최신순으로 뜨고 카테고리/태그 필터가 동작하는지 확인
- [ ] Read: `/posts/:id` 상세에서 내용이 정확히 표시되고 `view_count`가 증가하는지 확인
- [ ] Update: 본인 글을 `/posts/:id/edit`에서 수정 → 변경사항이 반영되는지 확인
- [ ] Delete: 본인 글 삭제 → 목록에서 사라지고 Supabase에서도 삭제됐는지 확인

## 데이터 연동 — Supabase 반영률 100%
- [ ] Supabase 테이블 편집기를 열어, 앱에서 만들고/수정하고/지운 데이터가 정확히 일치하는지 대조
- [ ] 카테고리/태그 선택이 `category_id` / `post_tags`에 올바르게 저장되는지 확인
- [ ] 이미지 업로드 시 URL이 `thumbnail_image`에 저장되는지 확인

## 보안 — 비밀번호 평문 저장 0건
- [ ] Supabase 대시보드 Authentication > Users 메뉴에서 가입한 계정이 보이는지, 비밀번호 원문이 어디에도 노출되지 않는지 확인 (Supabase Auth가 자동 해시 저장)
- [ ] Supabase URL/anon key가 `js/config.js`(또는 `.env`)에 있고 코드에 하드코딩되어 있지 않은지 확인
- [ ] `js/config.js`가 `.gitignore`에 포함되어 GitHub에 올라가지 않는지 확인

## 권한(인가) — 타인 글 수정·삭제 100% 차단
- [ ] 계정 A로 글 작성 → 계정 B로 로그인 후 A의 글 `/posts/:id/edit`에 URL로 직접 접근 시 거부되는지 확인
- [ ] 계정 B가 A의 글을 삭제 시도해도(버튼 또는 API 직접 호출) `posts` 테이블 RLS에 막혀 삭제되지 않는지 확인 (브라우저 콘솔에서 `supabase.from('posts').delete()...`를 직접 호출해도 실패해야 함)
- [ ] 비로그인 상태로 `/posts/new`, `/posts/:id/edit` 접근 시 로그인으로 유도되는지 확인

## 로컬 검증 — 배포 전 필수
- [ ] Live Server로 로컬(localhost)에서 가입 → 작성 → 수정 → 삭제 전체 흐름이 에러 없이 동작하는지 확인

## 일정 준수 — 2026-07-23(목) 17:00 이전 제출
- [ ] 배포 완료 후 접속 가능한 URL 확보
- [ ] Slack에 URL 제출
