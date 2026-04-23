<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', config('app.name', 'Laravel'))</title>
    <link rel="stylesheet" href="{{ asset('prototype/css/fonts.css') }}">
    <link rel="stylesheet" href="{{ asset('prototype/css/post-login.css') }}">
</head>
<body>
<canvas></canvas>

<div class="page">
    <div class="shell">
        <aside class="sidebar">
            <div class="brand">
                <h1>ITV-System.</h1>
                <p>@yield('sidebar_subtitle', 'Panel de operación')</p>
            </div>

            <nav class="menu">
                <a class="menu-link {{ request()->routeIs('dashboard') ? 'active' : '' }}" href="{{ route('dashboard') }}">Dashboard</a>
                <a class="menu-link {{ request()->routeIs('inspecciones') ? 'active' : '' }}" href="{{ route('inspecciones') }}">Inspecciones</a>
                <a class="menu-link {{ request()->routeIs('perfil') ? 'active' : '' }}" href="{{ route('perfil') }}">Perfil y ajustes</a>
            </nav>

            <div class="sidebar-footer">
                @hasSection('status_pill')
                    <span class="status-pill">@yield('status_pill')</span>
                @endif
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="logout-link" type="submit">Cerrar sesión</button>
                </form>
            </div>
        </aside>

        <main class="content">
            @yield('content')
        </main>
    </div>
</div>

<script src="{{ asset('prototype/js/post-login.js') }}"></script>
<script src="{{ asset('prototype/js/anim.js') }}"></script>
</body>
</html>
