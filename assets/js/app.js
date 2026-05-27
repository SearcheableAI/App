// ============================================================
// app.js — Shared utilities used across all pages
// ============================================================

// ── Slug generation ──────────────────────────────────────────
function generateSlug(text) {
  return text.toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
}

// ── URL helpers ───────────────────────────────────────────────
function getParam(key) {
  return new URLSearchParams(window.location.search).get(key);
}

function buildUrl(base, params) {
  const url = new URL(base, window.location.origin);
  Object.entries(params).forEach(([k, v]) => { if (v) url.searchParams.set(k, v); });
  return url.toString();
}

// ── Date formatting ───────────────────────────────────────────
function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return 'Today';
  if (days === 1) return 'Yesterday';
  if (days < 30) return `${days}d ago`;
  if (days < 365) return `${Math.floor(days / 30)}mo ago`;
  return `${Math.floor(days / 365)}y ago`;
}

// ── Escaping ──────────────────────────────────────────────────
function esc(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ── Toast notifications ───────────────────────────────────────
function showToast(message, type = 'info') {
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.className = `toast toast--${type}`;
  toast.innerHTML = `
    <span>${esc(message)}</span>
    <button onclick="this.parentElement.remove()" class="toast__close">✕</button>
  `;
  document.body.appendChild(toast);
  requestAnimationFrame(() => toast.classList.add('toast--visible'));
  setTimeout(() => { toast.classList.remove('toast--visible'); setTimeout(() => toast.remove(), 300); }, 4000);
}

// ── Listing card renderer ─────────────────────────────────────
function renderListingCard(listing) {
  const services = listing.listing_services
    ? listing.listing_services.slice(0, 3).map(ls =>
        `<span class="service-tag">${esc(ls.services?.name || '')}</span>`
      ).join('')
    : '';

  const tierBadge = listing.listing_tier === 'sponsored'
    ? `<span class="badge badge--sponsored">Sponsored</span>`
    : listing.listing_tier === 'featured'
    ? `<span class="badge badge--featured">Featured</span>`
    : '';

  const verifiedBadge = listing.is_verified
    ? `<span class="badge badge--verified" title="Verified">✓</span>`
    : '';

  const logoHtml = listing.logo_url
    ? `<img src="${esc(listing.logo_url)}" alt="${esc(listing.name)} logo" class="card-logo" loading="lazy">`
    : `<div class="card-logo card-logo--placeholder">${esc(listing.name?.charAt(0) || '?')}</div>`;

  const listingType = LISTING_TYPES[listing.listing_type] || 'AI Company';
  const location = [listing.hq_city, listing.hq_country].filter(Boolean).join(', ');

  return `
    <a href="listing.html?slug=${esc(listing.slug)}" class="listing-card ${listing.listing_tier !== 'free' ? 'listing-card--elevated' : ''}">
      <div class="card-header">
        ${logoHtml}
        <div class="card-identity">
          <h3 class="card-name">${esc(listing.name)}</h3>
          <span class="card-type">${esc(listingType)}</span>
        </div>
        <div class="card-badges">${tierBadge}${verifiedBadge}</div>
      </div>
      <p class="card-tagline">${esc(listing.tagline)}</p>
      ${services ? `<div class="card-services">${services}</div>` : ''}
      <div class="card-footer">
        ${location ? `<span class="card-location">${esc(location)}</span>` : '<span></span>'}
        <span class="card-cta">View Profile →</span>
      </div>
    </a>
  `;
}

// ── Profile completeness bar ──────────────────────────────────
function renderCompletenessBar(score) {
  const color = score >= 80 ? 'var(--accent)' : score >= 50 ? '#FFB800' : '#FF4444';
  return `
    <div class="completeness-bar">
      <div class="completeness-bar__fill" style="width:${score}%;background:${color}"></div>
    </div>
  `;
}

// ── Loading skeleton ──────────────────────────────────────────
function renderSkeletonCards(count = 6) {
  return Array(count).fill(0).map(() => `
    <div class="listing-card listing-card--skeleton">
      <div class="card-header">
        <div class="skeleton skeleton--circle"></div>
        <div class="card-identity">
          <div class="skeleton skeleton--line" style="width:60%"></div>
          <div class="skeleton skeleton--line" style="width:40%;margin-top:6px"></div>
        </div>
      </div>
      <div class="skeleton skeleton--line" style="width:90%;margin:16px 0 8px"></div>
      <div class="skeleton skeleton--line" style="width:70%"></div>
    </div>
  `).join('');
}

// ── Nav active state ──────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const path = window.location.pathname;
  document.querySelectorAll('.nav__link').forEach(link => {
    if (link.getAttribute('href') === path) link.classList.add('nav__link--active');
  });
});
