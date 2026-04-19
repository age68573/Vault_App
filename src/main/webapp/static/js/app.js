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
  if (seconds < 60) return seconds + 's';

  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;

  let result = '';
  if (h > 0) result += h + 'h ';
  if (m > 0) result += m + 'm ';
  result += s + 's';
  return result.trim();
}

/**
 * 依據剩餘秒數更新徽章的顏色類別。
 * 支援兩種模式：
 *  - navbar-ttl-badge（導覽列 TTL widget）
 *  - Bootstrap badge（儀表板 / 憑證頁）
 *
 * @param {HTMLElement} el  徽章元素
 * @param {number}      ttl 剩餘秒數
 */
function updateBadgeColor(el, ttl) {
  if (el.classList.contains('navbar-ttl-badge')) {
    // Navbar style — use custom ttl-* classes
    el.classList.remove('ttl-warning', 'ttl-danger');
    if (ttl <= 60) {
      el.classList.add('ttl-danger');
    } else if (ttl <= 300) {
      el.classList.add('ttl-warning');
    }
    // else: green (no extra class)
  } else {
    // Bootstrap badge style
    el.classList.remove('bg-success', 'bg-warning', 'bg-danger', 'bg-info', 'text-dark');
    if (ttl > 300) {
      el.classList.add('bg-success');
    } else if (ttl > 60) {
      el.classList.add('bg-warning', 'text-dark');
    } else {
      el.classList.add('bg-danger');
    }
  }
}

/**
 * 更新進度條寬度與顏色。
 * 支援兩種模式：
 *  - navbar-ttl-bar-fill（導覽列 TTL bar）
 *  - Bootstrap progress-bar（卡片內進度條）
 *
 * @param {string} barId     進度條元素 ID
 * @param {number} remaining 剩餘秒數
 */
function updateProgressBar(barId, remaining) {
  const bar = document.getElementById(barId);
  if (!bar) return;
  const total = parseInt(bar.getAttribute('data-total'), 10) || 1;
  const pct   = Math.max(0, Math.min(100, (remaining / total) * 100));
  bar.style.width = pct + '%';

  if (bar.classList.contains('navbar-ttl-bar-fill')) {
    // Navbar bar — update colour via inline style
    const color = remaining > 300 ? '#2fb344' : remaining > 60 ? '#f59f00' : '#d63939';
    bar.style.background = color;
  } else {
    // Bootstrap progress-bar — toggle bg-* classes
    bar.classList.remove('bg-success', 'bg-warning', 'bg-danger');
    if (remaining > 300) {
      bar.classList.add('bg-success');
    } else if (remaining > 60) {
      bar.classList.add('bg-warning');
    } else {
      bar.classList.add('bg-danger');
    }
  }
}

/**
 * 初始化所有帶有 data-ttl 屬性的元素，啟動倒數計時器。
 */
function initTtlCountdowns() {
  const ttlElements = document.querySelectorAll('[data-ttl]');

  ttlElements.forEach(el => {
    let remaining = parseInt(el.getAttribute('data-ttl'), 10);
    if (isNaN(remaining)) return;

    const barId = el.getAttribute('data-bar');

    const timer = setInterval(() => {
      remaining -= 1;
      el.textContent = formatTtl(remaining);
      updateBadgeColor(el, remaining);

      if (barId) {
        updateProgressBar(barId, remaining);
      }

      if (remaining <= 0) {
        clearInterval(timer);
        el.textContent = '已過期';

        if (el.classList.contains('navbar-ttl-badge')) {
          el.classList.remove('ttl-warning');
          el.classList.add('ttl-danger');
        } else {
          el.classList.remove('bg-success', 'bg-warning', 'bg-info', 'text-dark');
          el.classList.add('bg-danger');
        }

        // Token 過期後 5 秒跳回登入頁
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
