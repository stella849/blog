-- 추가 더미데이터: 식단 카테고리 3개 (과거 날짜)
-- Supabase SQL Editor에서 실행
-- 실행 전 꼭 해야 할 일: 아래 '1aad2d82-c80d-4409-ad1f-c2d603f1d622' 를 본인 profiles.id (UUID)로 교체하세요.
-- (seed-posts.sql에서 쓴 값과 같으면 그대로 두면 됩니다)

insert into posts (user_id, category_id, title, content, created_at)
values
  (
    '1aad2d82-c80d-4409-ad1f-c2d603f1d622',
    (select id from categories where name = '식단'),
    '간헐적 단식 3일째, 배고픔이 줄었다',
    '저녁 8시 이후엔 안 먹기로 했는데 첫날은 배고파서 힘들었다. 3일째부터는 오히려 속이 편해지는 느낌. 아침 공복 컨디션도 나쁘지 않다.',
    '2026-07-18 20:30:00+09'
  ),
  (
    '1aad2d82-c80d-4409-ad1f-c2d603f1d622',
    (select id from categories where name = '식단'),
    '야식 대신 견과류 한 줌으로 바꿔봤다',
    '늦게까지 작업하다 보면 꼭 뭔가 먹고 싶어지는데, 오늘은 라면 대신 아몬드랑 호두 한 줌으로 참아봤다. 생각보다 만족스러웠다.',
    '2026-07-19 22:15:00+09'
  ),
  (
    '1aad2d82-c80d-4409-ad1f-c2d603f1d622',
    (select id from categories where name = '식단'),
    '물 2리터 채우기 챌린지 시작',
    '하루 종일 앉아있으면서 물을 거의 안 마신다는 걸 깨달았다. 오늘부터 1리터짜리 물병 두 개를 채우는 걸 목표로 잡았다. 화장실은 좀 자주 가게 됐다.',
    '2026-07-20 13:00:00+09'
  );
