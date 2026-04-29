import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    server: {
        host: '127.0.0.1',
        port: Number(process.env.VITE_PORT ?? 5174),
        strictPort: true,
        hmr: {
            host: '127.0.0.1',
            port: Number(process.env.VITE_PORT ?? 5174),
        },
    },
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
