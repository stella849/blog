-- 블로그 CRUD 프로젝트 스키마
-- crud-pure-clarke.md "1. 테이블 설계 (ERD)" 기준 (Supabase Auth 채택 반영)
-- Supabase SQL Editor에서 그대로 실행

-- ── 인증 ──
-- 회원가입/로그인은 Supabase Auth(auth.users)가 담당한다.
-- 비밀번호는 Supabase가 자동으로 해시 저장하므로 별도 password 컬럼을 두지 않는다.
-- 앱에서 쓰는 추가 프로필 정보(닉네임·프로필이미지·권한)만 profiles 테이블에 둔다.

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname varchar(50) not null,
  profile_image varchar(500),
  role varchar(20) not null default 'USER', -- USER / ADMIN
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 회원가입 시 auth.users에 행이 생기면 profiles에도 자동으로 기본 행을 만들어준다.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id, coalesce(new.raw_user_meta_data->>'nickname', split_part(new.email, '@', 1)));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- categories (카테고리)
create table categories (
  id bigint generated always as identity primary key,
  name varchar(50) unique not null,
  is_private boolean not null default false, -- true면 해당 카테고리 글은 작성자 본인만 열람 가능 (예: 일기)
  created_at timestamptz not null default now()
);

-- posts (게시글)
create table posts (
  id bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  category_id bigint references categories(id) on delete set null,
  title varchar(200) not null,
  content text not null,
  thumbnail_image varchar(500),
  attachment_url varchar(500),
  attachment_name varchar(255),
  view_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- tags (태그)
create table tags (
  id bigint generated always as identity primary key,
  name varchar(50) unique not null
);

-- post_tags (게시글-태그 연결, N:M)
create table post_tags (
  post_id bigint not null references posts(id) on delete cascade,
  tag_id bigint not null references tags(id) on delete cascade,
  primary key (post_id, tag_id)
);

create index idx_posts_user_id on posts(user_id);
create index idx_posts_category_id on posts(category_id);
create index idx_posts_created_at on posts(created_at desc);

-- ── Row Level Security ──
-- prd.md FR-4 AC-4.2: 본인 글만 수정·삭제 가능 — auth.uid() 기준으로 서버(DB) 단에서 실제로 강제된다.
alter table profiles enable row level security;
alter table posts enable row level security;
alter table categories enable row level security;
alter table tags enable row level security;
alter table post_tags enable row level security;

-- 전체 공개 읽기 (방문자도 목록/상세/프로필 열람 가능)
create policy "profiles are publicly readable" on profiles for select using (true);
-- 게시글 읽기: 비공개 카테고리(is_private=true, 예: 일기)는 작성자 본인만, 나머지는 전체 공개
create policy "posts are readable respecting category privacy" on posts
  for select using (
    not exists (
      select 1 from categories c
      where c.id = posts.category_id and c.is_private = true
    )
    or auth.uid() = posts.user_id
  );
create policy "categories are publicly readable" on categories for select using (true);
create policy "tags are publicly readable" on tags for select using (true);
create policy "post_tags are publicly readable" on post_tags for select using (true);

-- 본인 프로필만 수정 가능
create policy "users can update own profile" on profiles for update using (auth.uid() = id);

-- 로그인한 사용자만 글 작성 가능, 작성자 본인 명의로만 작성 가능
create policy "logged-in users can insert own posts" on posts for insert
  with check (auth.uid() = user_id);

-- 본인 글만 수정·삭제 가능 — 이게 실제 "인가" 강제 지점
create policy "owners can update own posts" on posts for update
  using (auth.uid() = user_id);
create policy "owners can delete own posts" on posts for delete
  using (auth.uid() = user_id);

-- 카테고리/태그/연결 테이블은 로그인한 사용자면 누구나 추가 가능(과제 범위 — 관리 화면 없음)
create policy "logged-in users can insert categories" on categories for insert
  with check (auth.uid() is not null);
create policy "logged-in users can insert tags" on tags for insert
  with check (auth.uid() is not null);
create policy "logged-in users can insert post_tags" on post_tags for insert
  with check (auth.uid() is not null);
create policy "logged-in users can delete post_tags" on post_tags for delete
  using (auth.uid() is not null);

-- ── 관리자(Admin) ──
-- profiles.role = 'ADMIN'인 계정은 전체 글/카테고리/회원을 관리할 수 있다 (admin.html).
-- security definer 함수로 profiles를 조회해 RLS 재귀(무한 순환) 없이 role을 확인한다.
create function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'ADMIN'
  );
$$;

-- 관리자는 모든 글을 수정/삭제 가능 (기존 "본인 글만" 정책과 OR로 결합됨)
create policy "admins can update any post" on posts for update using (public.is_admin());
create policy "admins can delete any post" on posts for delete using (public.is_admin());

-- 관리자는 카테고리를 수정(이름/공개여부)·삭제 가능
create policy "admins can update categories" on categories for update using (public.is_admin());
create policy "admins can delete categories" on categories for delete using (public.is_admin());

-- 관리자는 다른 회원의 role을 변경 가능 (관리자 지정/해제)
create policy "admins can update any profile" on profiles for update using (public.is_admin());

-- ── Storage: 게시글 대표 이미지 ──
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

create policy "post images are publicly readable" on storage.objects
  for select using (bucket_id = 'post-images');

create policy "logged-in users can upload post images" on storage.objects
  for insert with check (bucket_id = 'post-images' and auth.uid() is not null);
