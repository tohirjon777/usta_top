@extends('layouts.ustatop-panel')

@section('content')
    <div class="login-shell">
        <article class="card">
            <h1>Owner login</h1>
            <form method="post" action="/owner/login">
                @csrf
                <label>Ustaxona</label>
                <select name="workshopId">
                    @foreach ($workshops as $workshop)
                        <option value="{{ $workshop['id'] }}">{{ $workshop['name'] }}</option>
                    @endforeach
                </select>
                <label>Access code</label>
                <input type="password" name="accessCode">
                <button type="submit">Kirish</button>
            </form>
        </article>
    </div>
@endsection
