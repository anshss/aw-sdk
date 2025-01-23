const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const packagesDir = path.join(__dirname, '../packages');
const docsDir = path.join(__dirname, '../docs/api');

// Create docs directory if it doesn't exist
if (!fs.existsSync(docsDir)) {
  fs.mkdirSync(docsDir, { recursive: true });
}

// Get all package directories
const packages = fs.readdirSync(packagesDir)
  .filter(file => fs.statSync(path.join(packagesDir, file)).isDirectory());

// Generate documentation for each package
packages.forEach(pkg => {
  const pkgPath = path.join(packagesDir, pkg);
  const srcPath = path.join(pkgPath, 'src');
  
  if (!fs.existsSync(srcPath)) {
    console.log(`Skipping ${pkg} - no src directory found`);
    return;
  }

  console.log(`Generating documentation for ${pkg}...`);
  
  const typedocConfig = {
    entryPoints: [path.join(srcPath, 'index.ts')],
    out: path.join(docsDir, pkg),
    plugin: ['typedoc-plugin-markdown'],
    tsconfig: path.join(__dirname, '../tsconfig.base.json'),
    excludePrivate: true,
    excludeProtected: true,
    excludeExternals: false,
    exclude: ['**/*.spec.ts', '**/*.test.ts', '**/tests/**'],
    skipErrorChecking: true
  };

  // Write temporary typedoc config
  const tempConfigPath = path.join(__dirname, `typedoc-${pkg}.json`);
  fs.writeFileSync(tempConfigPath, JSON.stringify(typedocConfig, null, 2));

  try {
    execSync(`npx typedoc --options ${tempConfigPath}`, { stdio: 'inherit' });
  } catch (error) {
    console.error(`Error generating docs for ${pkg}:`, error.message);
  } finally {
    // Clean up temporary config
    fs.unlinkSync(tempConfigPath);
  }
});

console.log('Documentation generation complete!'); 