-- 마이그레이션: 카테고리별 비공개 지원 (일기 = 작성자 본인만 열람)
-- Supabase SQL Editor에서 실행 (schema.sql 실행 후 1회)

alter table categories add column if not exists is_private boolean not null default false;

update categories set is_private = true where name = '일기';

-- 기존 "전체 공개" 읽기 정책을 "비공개 카테고리는 본인 글만" 정책으로 교체
drop policy if exists "posts are publicly readable" on posts;

create policy "posts are readable respecting category privacy" on posts
  for select using (
    not exists (
      select 1 from categories c
      where c.id = posts.category_id and c.is_private = true
    )
    or auth.uid() = posts.user_id
  );
