@extends('layouts.prototype')

@section('title', 'ITV-System | Perfil')
@section('sidebar_subtitle', 'Panel operativo')
@section('status_pill', 'Sesion activa')

@section('content')
    <header class="header">
        <div>
            <h2>Perfil y ajustes</h2>
            <p>Configura tu cuenta y preferencias de visualizacion.</p>
        </div>
    </header>

    <section class="grid">
        <article class="card span-12">
            <h3>Perfil del operador</h3>
            <div class="profile-grid">
                <div class="avatar">OI</div>
                <div>
                    <p>Usuario principal para el panel de inspecciones.</p>
                    <div class="profile-fields">
                        <div class="field">
                            <span class="field-label">Nombre</span>
                            <span class="field-value">{{ auth()->user()->name }}</span>
                        </div>
                        <div class="field">
                            <span class="field-label">Rol</span>
                            <span class="field-value">Supervisor</span>
                        </div>
                        <div class="field">
                            <span class="field-label">Correo</span>
                            <span class="field-value">{{ auth()->user()->email }}</span>
                        </div>
                        <div class="field">
                            <span class="field-label">Turno</span>
                            <span class="field-value">Manana</span>
                        </div>
                    </div>
                </div>
            </div>
        </article>

        <article class="card span-6">
            <h3>Preferencias</h3>
            <ul class="task-list">
                <li>Idioma del panel <span class="chip ready">Espanol</span></li>
                <li>Tema visual <span class="chip review">Claro</span></li>
                <li>Alertas por correo <span class="chip ready">Activas</span></li>
            </ul>
        </article>

        <article class="card span-6">
            <h3>Acciones rapidas</h3>
            <p>Modifica la configuracion general de tu cuenta.</p>
            <div class="actions">
                <a class="btn primary" href="{{ route('profile.edit') }}">Editar perfil</a>
                <button class="btn secondary" type="button">Cambiar contrasena</button>
            </div>
        </article>
    </section>
@endsection
