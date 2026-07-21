-- 관리자(Admin) 기능 마이그레이션 — 이미 schema.sql을 실행한 기존 DB에 적용
-- Supabase SQL Editor에서 실행

-- profiles.role = 'ADMIN'인지 확인하는 함수
-- security definer로 실행되어 profiles를 RLS 재귀(무한 순환) 없이 조회한다.
create or replace function public.is_admin()
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
drop policy if exists "admins can update any post" on posts;
create policy "admins can update any post" on posts for update using (public.is_admin());
drop policy if exists "admins can delete any post" on posts;
create policy "admins can delete any post" on posts for delete using (public.is_admin());

-- 관리자는 카테고리를 수정(이름/공개여부)·삭제 가능
drop policy if exists "admins can update categories" on categories;
create policy "admins can update categories" on categories for update using (public.is_admin());
drop policy if exists "admins can delete categories" on categories;
create policy "admins can delete categories" on categories for delete using (public.is_admin());

-- 관리자는 다른 회원의 role을 변경 가능 (관리자 지정/해제)
drop policy if exists "admins can update any profile" on profiles;
create policy "admins can update any profile" on profiles for update using (public.is_admin());

-- 최초 관리자 지정 — 아직 관리자가 없으면 아무도 admin.html에 못 들어가므로 1회 수동 실행 필요.
-- 아래 이메일을 본인 계정 이메일로 바꾼 뒤 주석 해제하고 실행하세요.
-- update profiles set role = 'ADMIN'
-- where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
