@extends('layouts.prototype')

@section('title', 'ITV-System | Inspecciones')
@section('status_pill', 'Operativo')

@section('content')
    <header class="header">
        <div>
            <h2>Cola de inspecciones</h2>
            <p>Gestiona el estado de cada vehiculo en revision.</p>
        </div>
        <span class="badge">Turno manana</span>
    </header>

    <section class="grid">
        <article class="card span-4">
            <h3>Pendientes</h3>
            <p class="metric">14</p>
        </article>
        <article class="card span-4">
            <h3>En proceso</h3>
            <p class="metric">6</p>
        </article>
        <article class="card span-4">
            <h3>Finalizadas hoy</h3>
            <p class="metric">27</p>
        </article>

        <article class="card span-12">
            <h3>Detalle de inspecciones</h3>
            <ul class="task-list">
                <li>
                    <span>ABC-123 - Particular - L. Mendez</span>
                    <span class="chip pending">Pendiente</span>
                </li>
                <li>
                    <span>JTR-834 - Transporte - R. Sosa</span>
                    <span class="chip review">En proceso</span>
                </li>
                <li>
                    <span>LMN-998 - Carga - K. Ruiz</span>
                    <span class="chip ready">Finalizada</span>
                </li>
                <li>
                    <span>FTD-448 - Particular - A. Rivas</span>
                    <span class="chip pending">Pendiente</span>
                </li>
            </ul>
            <div class="actions">
                <button class="btn primary" type="button">Nueva inspeccion</button>
                <button class="btn secondary" type="button">Exportar reporte</button>
            </div>
        </article>
    </section>
@endsection
