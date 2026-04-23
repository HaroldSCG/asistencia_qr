<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ITV-System | Login</title>
    <link rel="stylesheet" href="{{ asset('prototype/css/fonts.css') }}">
    <link rel="stylesheet" href="{{ asset('prototype/css/login.css') }}">
</head>
<body>
<canvas></canvas>

<div class="main-container">
    <div class="box box1">
        <div class="box box2">
            <div class="box box3">
                <div class="box box4">
                    <div class="box box5">
                        <img src="{{ asset('prototype/images/itv_proto2.png') }}" alt="itv">
                    </div>
                </div>
            </div>
        </div>

        <div class="box_a">
            <div class="tittle-container">
                <h1 class="title1">ITV-System.</h1>
                <h1 class="title2">.Inicia sesion para continuar.</h1>
            </div>

            @if (session('status'))
                <span class="session-status">{{ session('status') }}</span>
            @endif

            <form class="form" method="POST" action="{{ route('login') }}">
                @csrf

                <div class="input-container">
                    <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus autocomplete="username">
                    <label for="email">Correo</label>
                    <div class="underline"></div>
                </div>
                @error('email')
                    <span class="error-message">{{ $message }}</span>
                @enderror

                <div class="input-container password-container">
                    <input id="password" type="password" name="password" required autocomplete="current-password">
                    <label for="password">Contrasena</label>
                    <span class="toggle-password"></span>
                    <div class="underline"></div>
                </div>
                @error('password')
                    <span class="error-message">{{ $message }}</span>
                @enderror

                <div class="button-container">
                    <button class="button1" type="submit">Iniciar sesion</button>
                </div>

                <div class="remember-container">
                    <label for="remember_me">
                        <input id="remember_me" type="checkbox" name="remember" {{ old('remember') ? 'checked' : '' }}>
                        Recordarme
                    </label>
                </div>

                @if (Route::has('password.request'))
                    <div class="forgot-password">
                        <a href="{{ route('password.request') }}">Olvide mi contrasena</a>
                    </div>
                @endif
            </form>
        </div>
    </div>

    <div class="glass"></div>
</div>

<script>
    const toggle = document.querySelector(".toggle-password");
    const input = document.querySelector("input[type='password']");

    if (toggle && input) {
        toggle.addEventListener("click", () => {
            const isHidden = input.type === "password";
            input.type = isHidden ? "text" : "password";

            toggle.style.webkitMaskImage = isHidden
                ? 'url("{{ asset('prototype/svg/eye-slash.svg') }}")'
                : 'url("{{ asset('prototype/svg/eye-fill.svg') }}")';

            toggle.style.maskImage = isHidden
                ? 'url("{{ asset('prototype/svg/eye-slash.svg') }}")'
                : 'url("{{ asset('prototype/svg/eye-fill.svg') }}")';
        });
    }
</script>
<script src="{{ asset('prototype/js/anim.js') }}"></script>
</body>
</html>
