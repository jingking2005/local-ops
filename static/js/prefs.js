'use strict';
/* ============================================================
   prefs.js — 界面质感 / 字号 / 正文字体（localStorage，可一键还原）
   ============================================================ */
import { $ } from './core.js';

const SKIN_KEY = 'console-ui-skin';
const SCALE_KEY = 'console-font-scale';
const FONT_KEY = 'console-font-family';

const FONT_PRESETS = {
  apple: {
    label: '苹方 · 系统',
    stack: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif",
  },
  heiti: {
    label: '黑体',
    stack: "'Heiti SC', 'STHeiti', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'SimHei', sans-serif",
  },
  kaiti: {
    label: '楷体',
    stack: "'Kaiti SC', 'STKaiti', 'KaiTi', '楷体', 'Songti SC', serif",
  },
  songti: {
    label: '宋体',
    stack: "'Songti SC', 'STSong', 'SimSun', '宋体', 'Noto Serif CJK SC', serif",
  },
  fangsong: {
    label: '仿宋',
    stack: "'STFangsong', 'FangSong', '仿宋', 'Songti SC', serif",
  },
  yuan: {
    label: '圆体',
    stack: "'Yuanti SC', 'STYuanti', 'PingFang SC', 'Hiragino Sans GB', sans-serif",
  },
};

const DEFAULTS = {
  skin: 'glass',
  scale: 1.08,
  font: 'apple',
};

function clampScale(n) {
  const v = Number(n);
  if (!Number.isFinite(v)) return DEFAULTS.scale;
  return Math.min(1.4, Math.max(0.85, Math.round(v * 100) / 100));
}

export function listFontPresets() {
  return Object.entries(FONT_PRESETS).map(([id, meta]) => ({ id, label: meta.label }));
}

export function currentSkin() {
  const v = localStorage.getItem(SKIN_KEY);
  return v === 'classic' ? 'classic' : 'glass';
}

export function currentScale() {
  const raw = localStorage.getItem(SCALE_KEY);
  return raw == null ? DEFAULTS.scale : clampScale(raw);
}

export function currentFont() {
  const v = localStorage.getItem(FONT_KEY);
  return FONT_PRESETS[v] ? v : DEFAULTS.font;
}

export function applyUiPrefs() {
  const root = document.documentElement;
  const skin = currentSkin();
  const scale = currentScale();
  const font = currentFont();
  root.dataset.uiSkin = skin;
  root.style.setProperty('--font-scale', String(scale));
  root.style.setProperty('--font-sans', FONT_PRESETS[font].stack);
  return { skin, scale, font };
}

export function setSkin(skin) {
  const next = skin === 'classic' ? 'classic' : 'glass';
  localStorage.setItem(SKIN_KEY, next);
  applyUiPrefs();
}

export function setScale(scale) {
  const next = clampScale(scale);
  localStorage.setItem(SCALE_KEY, String(next));
  applyUiPrefs();
  return next;
}

export function setFont(font) {
  const next = FONT_PRESETS[font] ? font : DEFAULTS.font;
  localStorage.setItem(FONT_KEY, next);
  applyUiPrefs();
  return next;
}

export function resetUiPrefs() {
  localStorage.removeItem(SKIN_KEY);
  localStorage.removeItem(SCALE_KEY);
  localStorage.removeItem(FONT_KEY);
  applyUiPrefs();
}

export function syncPrefsControls() {
  const { skin, scale, font } = applyUiPrefs();
  const skinTabs = $('#setSkin');
  if (skinTabs) {
    for (const tab of skinTabs.querySelectorAll('.mini-tab')) {
      tab.classList.toggle('active', tab.dataset.skin === skin);
    }
  }
  const scaleRange = $('#setFontScale');
  const scaleVal = $('#setFontScaleVal');
  if (scaleRange) scaleRange.value = String(scale);
  if (scaleVal) scaleVal.textContent = Math.round(scale * 100) + '%';
  const fontTabs = $('#setFontFamily');
  if (fontTabs) {
    for (const tab of fontTabs.querySelectorAll('.font-chip')) {
      tab.classList.toggle('active', tab.dataset.font === font);
      tab.style.fontFamily = FONT_PRESETS[tab.dataset.font]
        ? FONT_PRESETS[tab.dataset.font].stack
        : '';
    }
  }
}

export function initUiPrefs() {
  applyUiPrefs();
  const skinTabs = $('#setSkin');
  if (skinTabs) {
    skinTabs.addEventListener('click', e => {
      const tab = e.target.closest('.mini-tab');
      if (!tab) return;
      setSkin(tab.dataset.skin);
      syncPrefsControls();
    });
  }
  const scaleRange = $('#setFontScale');
  if (scaleRange) {
    const onScale = () => {
      setScale(scaleRange.value);
      syncPrefsControls();
    };
    scaleRange.addEventListener('input', onScale);
    scaleRange.addEventListener('change', onScale);
  }
  const fontTabs = $('#setFontFamily');
  if (fontTabs) {
    fontTabs.addEventListener('click', e => {
      const tab = e.target.closest('.font-chip');
      if (!tab) return;
      setFont(tab.dataset.font);
      syncPrefsControls();
    });
  }
  const resetBtn = $('#setUiReset');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      resetUiPrefs();
      syncPrefsControls();
    });
  }
}
