@extends('layouts.prototype')

@section('title', 'ITV-System | Dashboard')
@section('sidebar_subtitle', 'Panel de operación')
@section('status_pill', 'Sistema operativo')

@section('content')
    <header class="header">
        <div>
            <h2>Bienvenido de nuevo</h2>
            <p>Resumen rápido de la operación diaria después del login.</p>
        </div>
        <span class="badge">Turno mañana</span>
    </header>

    <section class="grid">
        <article class="card span-4">
            <h3>Citas de hoy</h3>
            <p class="metric">24</p>
        </article>

        <article class="card span-4">
            <h3>Inspecciones activas</h3>
            <p class="metric">7</p>
        </article>

        <article class="card span-4">
            <h3>Completadas</h3>
            <p class="metric">18</p>
        </article>

        <article class="card span-7">
            <h3>Próximas tareas</h3>
            <ul class="task-list">
                <li>
                    <span>Validar documentación de citas comerciales</span>
                    <span class="chip pending">Pendiente</span>
                </li>
                <li>
                    <span>Revisar reportes de pista #2</span>
                    <span class="chip review">Revisión</span>
                </li>
                <li>
                    <span>Confirmar entrega de certificados</span>
                    <span class="chip ready">Listo</span>
                </li>
            </ul>
        </article>

        <article class="card span-5">
            <h3>Acciones rápidas</h3>
            <p>Usa estas rutas para navegar al flujo post-login.</p>
            <div class="actions">
                <a class="btn primary" href="{{ route('inspecciones') }}">Ver inspecciones</a>
                <a class="btn secondary" href="{{ route('perfil') }}">Abrir ajustes</a>
            </div>
        </article>
    </section>
@endsection
