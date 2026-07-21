-- 마이그레이션: 게시글에 이미지 외 첨부파일(PDF 등) 지원 컬럼 추가
-- Supabase SQL Editor에서 실행 (schema.sql 실행 후 1회)

alter table posts add column if not exists attachment_url varchar(500);
alter table posts add column if not exists attachment_name varchar(255);
