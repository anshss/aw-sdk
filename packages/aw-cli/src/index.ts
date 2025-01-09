#!/usr/bin/env node

// Apply console patches before any other imports
// Save original references
const originalLog = console.log;
const originalWarn = console.warn;
const originalError = console.error;

// A helper that decides whether to suppress a particular message
function shouldSuppress(...args: any[]): boolean {
  const message = args.join(' ');

  // Add patterns to silence
  const suppressPatterns = [
    // Lit SDK deprecation warnings
    'lit-js-sdk:constants:errors',
    'lit-js-sdk:constants:constants',
    // Node.js deprecation warnings
    'punycode',
    '[DEP0040]',
    // Initialization messages
    'using deprecated parameters for `initSync()`',
    'Not a problem. Continue...',
  ];

  return suppressPatterns.some((pattern) => message.includes(pattern));
}

// Overwrite console methods to filter out undesired logs
console.log = (...args: any[]) => {
  if (!shouldSuppress(...args)) {
    originalLog(...args);
  }
};

console.warn = (...args: any[]) => {
  if (!shouldSuppress(...args)) {
    originalWarn(...args);
  }
};

console.error = (...args: any[]) => {
  if (!shouldSuppress(...args)) {
    originalError(...args);
  }
};

// Export original methods in case we need them
export const originalConsole = {
  log: originalLog,
  warn: originalWarn,
  error: originalError,
};

import { AwCli } from './lib/cli';

const cli = new AwCli();
cli.start().catch((error) => {
  console.error('Failed to start CLI:', error);
  process.exit(1);
});
