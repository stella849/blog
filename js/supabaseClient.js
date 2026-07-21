// Supabase 클라이언트 초기화
// 사용 페이지의 <head>에 다음 순서로 스크립트를 넣어야 합니다:
//   1) https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2 (CDN)
//   2) js/config.js
//   3) js/supabaseClient.js

const supabaseClient = window.supabase.createClient(
  window.SUPABASE_CONFIG.url,
  window.SUPABASE_CONFIG.publishableKey
);
