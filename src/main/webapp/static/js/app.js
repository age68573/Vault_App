/**
 * Vault MongoDB 動態憑證展示 — 前端 JavaScript
 * 主要功能：Token / Lease TTL 倒數計時器
 */

'use strict';

/**
 * 格式化秒數為人類可讀字串。
 * 例如：3661 → "1小時 1分 1秒"
 *
 * @param {number} seconds 秒數
 * @returns {string} 格式化字串
 */
function formatTtl(seconds) {
  if (seconds <= 0) return '已過期';
  if (seconds < 60) return seconds + '秒';

  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;

  let result = '';
  if (h > 0) result += h + '小時 ';
  if (m > 0) result += m + '分 ';
  result += s + '秒';
  return result.trim();
}

/**
 * 依據剩餘秒數更新徽章的顏色類別。
 *
 * @param {HTMLElement} el  徽章元素
 * @param {number}      ttl 剩餘秒數
 */
function updateBadgeColor(el, ttl) {
  el.classList.remove('bg-success', 'bg-warning', 'bg-danger', 'bg-info', 'text-dark');
  if (ttl > 300) {
    el.classList.add('bg-success');
  } else if (ttl > 60) {
    el.classList.add('bg-warning', 'text-dark');
  } else {
    el.classList.add('bg-danger');
  }
}

/**
 * 更新進度條寬度與顏色。
 *
 * @param {string} barId   進度條元素 ID
 * @param {number} remaining 剩餘秒數
 */
function updateProgressBar(barId, remaining) {
  const bar = document.getElementById(barId);
  if (!bar) return;
  const total = parseInt(bar.getAttribute('data-total'), 10) || 1;
  const pct = Math.max(0, Math.min(100, (remaining / total) * 100));
  bar.style.width = pct + '%';
  bar.classList.remove('bg-success', 'bg-warning', 'bg-danger');
  if (remaining > 300) {
    bar.classList.add('bg-success');
  } else if (remaining > 60) {
    bar.classList.add('bg-warning');
  } else {
    bar.classList.add('bg-danger');
  }
}

/**
 * 初始化所有帶有 data-ttl 屬性的元素，啟動倒數計時器。
 */
function initTtlCountdowns() {
  // 找出所有 TTL 元素（導覽列、儀表板卡片、動態憑證頁等）
  const ttlElements = document.querySelectorAll('[data-ttl]');

  ttlElements.forEach(el => {
    let remaining = parseInt(el.getAttribute('data-ttl'), 10);
    if (isNaN(remaining)) return;

    // 每秒更新一次
    const barId = el.getAttribute('data-bar');

    const timer = setInterval(() => {
      remaining -= 1;
      el.textContent = formatTtl(remaining);
      updateBadgeColor(el, remaining);

      // 同步更新對應的進度條（透過 data-bar 屬性指定）
      if (barId) {
        updateProgressBar(barId, remaining);
      }

      // 過期後停止計時並顯示「已過期」
      if (remaining <= 0) {
        clearInterval(timer);
        el.textContent = '已過期';
        el.classList.remove('bg-success', 'bg-warning', 'bg-info', 'text-dark');
        el.classList.add('bg-danger');

        // 若 Token 過期，5 秒後自動跳轉至登入頁
        if (el.id === 'tokenTtl' || el.id === 'dashTtl') {
          setTimeout(() => {
            const contextPath = document.querySelector('meta[name="context-path"]')
                                  ?.getAttribute('content') || '';
            alert('Vault Token 已過期，將重新導向至登入頁面。');
            window.location.href = contextPath + '/login';
          }, 5000);
        }
      }
    }, 1000);
  });
}

// DOM 載入完成後初始化
document.addEventListener('DOMContentLoaded', () => {
  initTtlCountdowns();

  // 啟用所有 Bootstrap Tooltip
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
    new bootstrap.Tooltip(el, { trigger: 'hover' });
  });
});
