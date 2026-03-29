@extends('layouts.ustatop-panel')

@section('content')
    <div class="login-shell">
        <article class="card">
            <h1>Admin login</h1>
            <form method="post" action="/admin/login">
                @csrf
                <label>Username</label>
                <input type="text" name="username" value="{{ $username }}">
                <label>Password</label>
                <input type="password" name="password" value="">
                <button type="submit">Kirish</button>
            </form>
        </article>
    </div>
@endsection
