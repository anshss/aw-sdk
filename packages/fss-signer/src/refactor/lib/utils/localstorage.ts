import { LocalStorage } from 'node-localstorage';

// Initialize local storage
const localStorage = new LocalStorage('./.fss-signer-storage');

// Use localStorage directly in your code
export { localStorage };
