// ============================================================
// auth.js — Authentication state, login, register, logout
// ============================================================

// ── Session state ─────────────────────────────────────────────
let currentUser = null;
let currentProfile = null;

async function getSession() {
  const { data: { session } } = await db.auth.getSession();
  return session;
}

async function getUser() {
  const { data: { user } } = await db.auth.getUser();
  return user;
}

// Fetch the public profile row for the current user
async function loadProfile(userId) {
  const { data, error } = await db
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) return null;
  return data;
}

// ── Require auth (redirect if not logged in) ──────────────────
async function requireAuth() {
  const session = await getSession();
  if (!session) {
    window.location.href = `login.html?redirect=${encodeURIComponent(window.location.pathname)};`
    return null;
  }
  currentUser = session.user;
  currentProfile = await loadProfile(session.user.id);
  return session;
}

// ── Redirect if already logged in ────────────────────────────
async function redirectIfAuthed(to = 'dashboard.html') {
  const session = await getSession();
  if (session) window.location.href = to;
}

// ── Update nav based on auth state ────────────────────────────
async function updateNavAuth() {
  const session = await getSession();
  const navActions = document.getElementById('nav-actions');
  if (!navActions) return;

  if (session) {
    navActions.innerHTML = `
      <a href="dashboard.html" class="btn btn--ghost btn--sm">Dashboard</a>
      <button onclick="logout()" class="btn btn--outline btn--sm">Sign Out</button>
    `;
  } else {
    navActions.innerHTML = `
      <a href="login.html" class="btn btn--ghost btn--sm">Sign In</a>
      <a href="register.html" class="btn btn--primary btn--sm">List Your Business</a>
    `;
  }
}

// ── Register ─────────────────────────────────────────────────
async function register(email, password, fullName, companyName) {
  const { data, error } = await db.auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName, company_name: companyName }
    }
  });

  if (error) throw error;

  // Create public profile row
  if (data.user) {
    const { error: profileError } = await db.from('users').insert({
      id: data.user.id,
      email: email,
      full_name: fullName,
      company_name: companyName,
    });
    if (profileError) console.warn('Profile insert error:', profileError);
  }

  return data;
}

// ── Login ─────────────────────────────────────────────────────
async function login(email, password) {
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

// ── Logout ────────────────────────────────────────────────────
async function logout() {
  await db.auth.signOut();
  window.location.href = 'index.html';
}

// ── Password reset ────────────────────────────────────────────
async function resetPassword(email) {
  const { error } = await db.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}reset-password.html`
  });
  if (error) throw error;
}

// ── Form handler helpers ──────────────────────────────────────
function setFormLoading(form, loading) {
  const btn = form.querySelector('[type="submit"]');
  if (!btn) return;
  btn.disabled = loading;
  btn.textContent = loading ? 'Please wait…' : btn.dataset.label;
}

function showFormError(form, message) {
  let el = form.querySelector('.form-error');
  if (!el) {
    el = document.createElement('div');
    el.className = 'form-error';
    form.prepend(el);
  }
  el.textContent = message;
  el.style.display = 'block';
}

function clearFormError(form) {
  const el = form.querySelector('.form-error');
  if (el) el.style.display = 'none';
}

// ── Init nav on every page load ───────────────────────────────
document.addEventListener('DOMContentLoaded', updateNavAuth);
