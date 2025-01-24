import { execSync } from 'child_process';
import { readFileSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const rootDir = resolve(__dirname, '../..');

// Read all package directories
function listPackageDirs() {
  const packagesDir = join(rootDir, 'packages');
  return readdirSync(packagesDir)
    .filter(dir => statSync(join(packagesDir, dir)).isDirectory())
    .map(dir => `./packages/${dir}/src/index.ts`);
}

// Update typedoc.json with package entry points
async function updateTypedocConfig() {
  const configPath = join(rootDir, 'typedoc.json');
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  
  config.entryPoints = listPackageDirs();
  
  writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log('Updated typedoc.json with package entry points');
}

// Generate documentation
async function generateDocs() {
  try {
    await updateTypedocConfig();
    console.log('Generating documentation...');
    execSync('npx typedoc --options typedoc.json', { stdio: 'inherit' });
    console.log('Documentation generated successfully!');
  } catch (error) {
    console.error('Error generating documentation:', error);
    process.exit(1);
  }
}

generateDocs(); 