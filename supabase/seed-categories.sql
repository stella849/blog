-- 기본 카테고리 시드 데이터
-- Supabase SQL Editor에서 실행 (schema.sql 실행 후 1회)

insert into categories (name) values
  ('바이브코딩'),
  ('일기'),
  ('식단'),
  ('건강'),
  ('운동')
on conflict (name) do nothing;

-- 일기 카테고리는 작성자 본인만 열람 가능 (비공개)
update categories set is_private = true where name = '일기';
