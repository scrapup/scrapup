#!/usr/bin/env node
'use strict';

/*
 * Registers scrapup as a Claude Code plugin after `npm install @scrapup/scrapup`.
 *
 * Best-effort and non-fatal: it never fails the npm install. It requires the
 * `claude` CLI on PATH; if absent (or registration fails), it prints the manual
 * commands and exits 0. Also runnable on demand via `npx @scrapup/scrapup`
 * (useful when installs run with --ignore-scripts).
 */

const { execFileSync } = require('node:child_process');
const path = require('node:path');

const pkgRoot = path.resolve(__dirname, '..');
const manual = [
  '  claude plugin marketplace add ' + pkgRoot,
  '  claude plugin install scrapup@scrapup',
].join('\n');

// Skip in CI — registering a global plugin from a pipeline is never intended.
if (process.env.CI) process.exit(0);

function claude(args, opts) {
  return execFileSync('claude', args, Object.assign({ stdio: 'inherit' }, opts));
}

try {
  claude(['--version'], { stdio: 'ignore' });
} catch {
  console.warn('[scrapup] Claude Code CLI not found on PATH — the plugin was NOT registered.');
  console.warn('[scrapup] Install Claude Code: https://claude.com/claude-code');
  console.warn('[scrapup] Then register it manually:');
  console.warn(manual);
  process.exit(0);
}

try {
  // marketplace add is idempotent enough; ignore "already exists" failures.
  try { claude(['plugin', 'marketplace', 'add', pkgRoot]); } catch {}
  claude(['plugin', 'install', 'scrapup@scrapup']);
  console.log('[scrapup] Registered as a Claude Code plugin. Run /reload-plugins in Claude Code (or restart the session) to load it.');
} catch {
  console.log('[scrapup] Could not register automatically. Run manually:');
  console.log(manual);
}

process.exit(0);
