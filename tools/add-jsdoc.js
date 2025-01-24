const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const packagesDir = path.join(__dirname, '../packages');

// Get all package directories
const packages = fs.readdirSync(packagesDir)
  .filter(file => fs.statSync(path.join(packagesDir, file)).isDirectory());

// Add JSDoc comments to each package's index.ts
packages.forEach(pkg => {
  const indexPath = path.join(packagesDir, pkg, 'src/index.ts');
  
  if (!fs.existsSync(indexPath)) {
    console.log(`Skipping ${pkg} - no index.ts found`);
    return;
  }

  console.log(`Adding JSDoc comments to ${pkg}...`);
  
  let content = fs.readFileSync(indexPath, 'utf8');
  const lines = content.split('\n');
  let newLines = [];
  let inExportBlock = false;

  lines.forEach((line, i) => {
    // If line starts with 'export', add JSDoc comment
    if (line.trim().startsWith('export')) {
      // Don't add comment if previous line was also an export (part of export block)
      const prevLine = lines[i - 1]?.trim() || '';
      if (!inExportBlock && !prevLine.startsWith('export') && !prevLine.startsWith('*')) {
        // Extract the name being exported
        const match = line.match(/export\s+(?:type\s+)?(?:{?\s*(\w+)[,}]|(\w+))/);
        const exportName = match ? (match[1] || match[2]) : 'item';
        
        newLines.push('/**');
        newLines.push(` * ${exportName} - Add description here`);
        if (line.includes('type') || line.includes('interface')) {
          newLines.push(' * @type');
        } else if (line.includes('class')) {
          newLines.push(' * @class');
        } else if (line.includes('function')) {
          newLines.push(' * @function');
        } else if (line.includes('const') || line.includes('let')) {
          newLines.push(' * @const');
        }
        newLines.push(' */');
      }
      
      // Check if this is the start of an export block
      if (line.includes('{') && !line.includes('}')) {
        inExportBlock = true;
      }
    }
    
    // If we're in an export block and find a closing brace, end the block
    if (inExportBlock && line.includes('}')) {
      inExportBlock = false;
    }
    
    newLines.push(line);
  });

  fs.writeFileSync(indexPath, newLines.join('\n'));
});

console.log('JSDoc comments added!'); 