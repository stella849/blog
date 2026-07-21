// 모든 페이지 공통 — 로그인 상태에 따라 nav의 guest-only / auth-only 요소를 토글
async function initNav() {
  const { data: { session } } = await supabaseClient.auth.getSession();

  document.querySelectorAll(".guest-only").forEach((el) => {
    el.style.display = session ? "none" : "";
  });
  document.querySelectorAll(".auth-only").forEach((el) => {
    el.style.display = session ? "" : "none";
  });

  const admin = session ? await isAdmin(session) : false;
  document.querySelectorAll(".admin-only").forEach((el) => {
    el.style.display = admin ? "" : "none";
  });

  const logoutBtn = document.getElementById("logout-btn");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => {
      await supabaseClient.auth.signOut();
      window.location.href = "index.html";
    });
  }

  return session;
}

// 로그인이 꼭 필요한 페이지(글쓰기·수정·마이페이지)에서 호출 — 비로그인이면 로그인 페이지로 보냄
async function requireAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = "login.html";
    return null;
  }
  return session;
}

// 로그인된 사용자의 profiles.role이 'ADMIN'인지 확인
async function isAdmin(session) {
  if (!session) return false;
  const { data } = await supabaseClient.from("profiles").select("role").eq("id", session.user.id).single();
  return data?.role === "ADMIN";
}
