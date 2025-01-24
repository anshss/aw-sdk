import { createServer } from 'http';
import { createReadStream, readFileSync, existsSync } from 'fs';
import { join, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const docsDir = join(__dirname, '../../docs/api');

// Check if docs directory exists
if (!existsSync(docsDir)) {
    console.error(`Documentation directory not found at: ${docsDir}`);
    console.error('Please run "pnpm docs" first to generate the documentation.');
    process.exit(1);
}

const port = 3001;

const server = createServer((req, res) => {
    console.log(`Request: ${req.url}`);
    
    // Default to index.html
    let filePath = join(docsDir, req.url === '/' ? 'index.html' : req.url);
    
    // If no extension is provided and file doesn't exist, try adding .html
    if (!extname(filePath) && !existsSync(filePath)) {
        filePath += '.html';
    }

    // Check if file exists
    if (!existsSync(filePath)) {
        console.log(`File not found: ${filePath}`);
        res.writeHead(404);
        res.end('File not found');
        return;
    }

    const ext = extname(filePath);
    const contentType = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'text/javascript',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.json': 'application/json'
    }[ext] || 'text/plain';

    createReadStream(filePath)
        .on('error', (error) => {
            console.error(`Error streaming file: ${error.message}`);
            res.writeHead(500);
            res.end('Internal Server Error');
        })
        .on('open', () => {
            res.writeHead(200, { 'Content-Type': contentType });
        })
        .pipe(res);
});

server.listen(port, () => {
    console.log(`Documentation server running at http://localhost:${port}`);
    console.log('Available documentation:');
    console.log(`- Main documentation: http://localhost:${port}`);
    console.log(`- Class hierarchy: http://localhost:${port}/hierarchy.html`);
    console.log(`- Modules: http://localhost:${port}/modules.html`);
    console.log(`- Classes: http://localhost:${port}/classes`);
}); 