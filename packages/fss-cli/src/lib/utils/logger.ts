// Utility to handle CLI logging
export const logger = {
  log: (message: string) => {
    console.log(message);
  },
  info: (message: string) => {
    console.log('\nℹ️ ', message);
  },
  success: (message: string) => {
    console.log('\n✅', message);
  },
  error: (message: string, error?: Error) => {
    const errorMessage = error ? error.message : message;
    console.error('\n❌', errorMessage);
  },
  warn: (message: string) => {
    console.warn('\n⚠️ ', message);
  },
};
