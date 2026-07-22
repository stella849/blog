-- 마이그레이션: 게시글 댓글 기능 추가
-- Supabase SQL Editor에서 실행 (schema.sql 실행 후 1회)

create table if not exists comments (
  id bigint generated always as identity primary key,
  post_id bigint not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_comments_post_id on comments(post_id);

alter table comments enable row level security;

-- 댓글 읽기: 게시글과 동일한 공개 범위를 따름(비공개 카테고리 글의 댓글은 작성자 본인만)
drop policy if exists "comments are readable respecting post visibility" on comments;
create policy "comments are readable respecting post visibility" on comments
  for select using (
    exists (
      select 1 from posts p
      left join categories c on c.id = p.category_id
      where p.id = comments.post_id
        and (c.is_private is not true or auth.uid() = p.user_id)
    )
  );

-- 로그인한 사용자만 댓글 작성 가능, 작성자 본인 명의로만 + 열람 가능한 글에만
drop policy if exists "logged-in users can insert own comments" on comments;
create policy "logged-in users can insert own comments" on comments for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from posts p
      left join categories c on c.id = p.category_id
      where p.id = comments.post_id
        and (c.is_private is not true or auth.uid() = p.user_id)
    )
  );

-- 본인 댓글만 삭제 가능
drop policy if exists "owners can delete own comments" on comments;
create policy "owners can delete own comments" on comments for delete
  using (auth.uid() = user_id);

-- 관리자는 모든 댓글을 삭제 가능
drop policy if exists "admins can delete any comment" on comments;
create policy "admins can delete any comment" on comments for delete using (public.is_admin());
