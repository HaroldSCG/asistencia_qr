# Ejecutar este frontend junto al backend Gymflow en Windows

Esta app Laravel/Blade puede correr en paralelo con el backend Gymflow.
El backend que ya tienes levantado usa:

- Laravel: `http://127.0.0.1:8000`
- Vite: `http://localhost:5173`

Para evitar choques de puertos, este proyecto queda configurado para usar:

- Laravel frontend: `http://127.0.0.1:8001`
- Vite frontend: `http://127.0.0.1:5174`
- API backend: `http://127.0.0.1:8000/api`

## 1. Preparar `.env`

Desde la carpeta de este proyecto:

```powershell
copy .env.example .env
php artisan key:generate
```

Confirma que estas variables existan en `.env`:

```env
APP_NAME=GymflowFrontend
APP_URL=http://127.0.0.1:8001

VITE_DEV_SERVER_URL=http://127.0.0.1:5174
VITE_PORT=5174
VITE_BACKEND_URL=http://127.0.0.1:8000
VITE_API_BASE_URL=http://127.0.0.1:8000/api
VITE_WITH_CREDENTIALS=false
```

El `.env.example` usa `SESSION_DRIVER=file`, `QUEUE_CONNECTION=sync` y
`CACHE_STORE=file` para que este frontend pueda arrancar sin depender de las
tablas de sesion, jobs y cache del backend.

Si tu backend no expone rutas bajo `/api`, cambia `VITE_API_BASE_URL` al prefijo real.

## 2. Instalar dependencias

```powershell
composer install
npm install
```

## 3. Ejecutar este proyecto

Con un solo comando:

```powershell
composer run dev:local
```

O en dos terminales:

```powershell
php artisan serve --host=127.0.0.1 --port=8001
npm run dev:local
```

Abre la app en:

```text
http://127.0.0.1:8001
```

## 4. Configurar el backend

En el backend Gymflow, permite llamadas desde este frontend.
Si consumes la API con tokens Bearer, normalmente basta con CORS:

```env
APP_URL=http://127.0.0.1:8000
FRONTEND_URL=http://127.0.0.1:8001
```

Y en `config/cors.php` del backend:

```php
'allowed_origins' => [
    'http://127.0.0.1:8001',
    'http://localhost:8001',
],
```

Si usas Sanctum con cookies, cambia en este proyecto:

```env
VITE_WITH_CREDENTIALS=true
```

Y en el backend agrega:

```env
SANCTUM_STATEFUL_DOMAINS=127.0.0.1:8001,localhost:8001
SESSION_DOMAIN=127.0.0.1
```
