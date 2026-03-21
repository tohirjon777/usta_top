import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models.dart';
import '../store.dart';

class AdminController {
  const AdminController(
    this._store, {
    required this.locationsFilePath,
  });

  final InMemoryStore _store;
  final String locationsFilePath;

  Future<Response> workshopsPage(Request request) async {
    final String? saved = request.url.queryParameters['saved'];
    final String? error = request.url.queryParameters['error'];
    final List<WorkshopModel> workshops = _store.workshops();

    final String html = '''
<!DOCTYPE html>
<html lang="uz">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Usta Top Admin</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4f1ea;
      --card: #fffdf8;
      --line: #e3d8c8;
      --text: #1f2933;
      --muted: #6b7280;
      --accent: #b45309;
      --accent-strong: #92400e;
      --ok-bg: #ecfdf3;
      --ok-text: #166534;
      --err-bg: #fef2f2;
      --err-text: #b91c1c;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      font-family: "Segoe UI", Tahoma, sans-serif;
      background:
        radial-gradient(circle at top left, #fde7c7 0, transparent 28%),
        linear-gradient(180deg, #faf7f1 0%, var(--bg) 100%);
      color: var(--text);
    }

    .wrap {
      max-width: 1100px;
      margin: 0 auto;
      padding: 32px 16px 48px;
    }

    .hero {
      margin-bottom: 22px;
    }

    h1 {
      margin: 0 0 8px;
      font-size: 32px;
      line-height: 1.15;
    }

    .sub {
      margin: 0;
      color: var(--muted);
      max-width: 760px;
      line-height: 1.55;
    }

    .flash {
      margin: 18px 0 22px;
      padding: 14px 16px;
      border-radius: 16px;
      font-size: 15px;
      line-height: 1.45;
    }

    .flash.ok {
      background: var(--ok-bg);
      color: var(--ok-text);
      border: 1px solid #bbf7d0;
    }

    .flash.err {
      background: var(--err-bg);
      color: var(--err-text);
      border: 1px solid #fecaca;
    }

    .grid {
      display: grid;
      gap: 16px;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 22px;
      padding: 18px;
      box-shadow: 0 10px 30px rgba(74, 49, 8, 0.06);
    }

    .title {
      display: flex;
      gap: 10px;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 10px;
      flex-wrap: wrap;
    }

    .title h2 {
      margin: 0;
      font-size: 22px;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border-radius: 999px;
      padding: 7px 12px;
      background: #fff2df;
      color: var(--accent-strong);
      font-size: 13px;
      font-weight: 600;
    }

    .meta {
      margin: 0 0 14px;
      color: var(--muted);
      line-height: 1.55;
    }

    .current {
      margin: 0 0 14px;
      padding: 12px 14px;
      border-radius: 16px;
      background: #fbf7f1;
      border: 1px solid var(--line);
      font-size: 14px;
      line-height: 1.55;
    }

    form {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
    }

    label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 6px;
    }

    input {
      width: 100%;
      border-radius: 12px;
      border: 1px solid var(--line);
      padding: 12px 13px;
      font-size: 15px;
      background: white;
    }

    .actions {
      grid-column: 1 / -1;
      display: flex;
      gap: 10px;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      margin-top: 4px;
    }

    button {
      border: 0;
      border-radius: 12px;
      padding: 12px 16px;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-strong) 100%);
      color: white;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
    }

    a {
      color: var(--accent-strong);
      text-decoration: none;
      font-weight: 600;
    }

    .hint {
      color: var(--muted);
      font-size: 13px;
    }

    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 13px;
      background: #f5eee4;
      padding: 2px 6px;
      border-radius: 8px;
    }

    @media (max-width: 720px) {
      form {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="hero">
      <h1>Usta Top workshop lokatsiyalari</h1>
      <p class="sub">Bu sahifada ustaxonalar uchun taxminiy koordinata kiritishingiz mumkin. Saqlangan latitude va longitude ilovadagi xaritada ishlatiladi va backend qayta ishga tushsa ham <code>${_escapeHtml(locationsFilePath)}</code> faylida saqlanib qoladi.</p>
    </div>
    ${_flashHtml(saved: saved, error: error)}
    <div class="grid">
      ${workshops.map(_workshopCardHtml).join('\n')}
    </div>
  </div>
</body>
</html>
''';

    return Response.ok(
      html,
      headers: const <String, String>{
        'content-type': 'text/html; charset=utf-8',
      },
    );
  }

  Future<Response> updateWorkshopLocation(Request request, String id) async {
    try {
      final Map<String, String> form = await _readForm(request);
      final double latitude = _parseCoordinate(
        form['latitude'],
        min: -90,
        max: 90,
        fieldLabel: 'Latitude',
      );
      final double longitude = _parseCoordinate(
        form['longitude'],
        min: -180,
        max: 180,
        fieldLabel: 'Longitude',
      );

      final bool updated = _store.updateWorkshopLocation(
        workshopId: id,
        latitude: latitude,
        longitude: longitude,
      );
      if (!updated) {
        return _redirectWithError('Servis topilmadi');
      }

      await _store.saveWorkshopLocations(locationsFilePath);
      return Response.seeOther(
        Uri.parse('/admin/workshops?saved=${Uri.encodeQueryComponent(id)}'),
      );
    } on FormatException catch (error) {
      return _redirectWithError(error.message);
    } catch (_) {
      return _redirectWithError('Lokatsiyani saqlab bo\'lmadi');
    }
  }

  Future<Map<String, String>> _readForm(Request request) async {
    final String body = await request.readAsString();
    if (body.trim().isEmpty) {
      return <String, String>{};
    }
    return Uri.splitQueryString(body);
  }

  double _parseCoordinate(
    String? raw, {
    required double min,
    required double max,
    required String fieldLabel,
  }) {
    final String value = (raw ?? '').trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(value);
    if (parsed == null) {
      throw FormatException('$fieldLabel noto\'g\'ri kiritildi');
    }
    if (parsed < min || parsed > max) {
      throw FormatException('$fieldLabel ruxsat etilgan oraliqda emas');
    }
    return parsed;
  }

  Response _redirectWithError(String message) {
    return Response.seeOther(
      Uri.parse('/admin/workshops?error=${Uri.encodeQueryComponent(message)}'),
    );
  }

  String _flashHtml({
    required String? saved,
    required String? error,
  }) {
    if (saved != null && saved.isNotEmpty) {
      final WorkshopModel? workshop = _store.workshopById(saved);
      final String title = workshop == null
          ? 'Lokatsiya saqlandi.'
          : '${workshop.name} uchun lokatsiya saqlandi.';
      return '<div class="flash ok">${_escapeHtml(title)}</div>';
    }

    if (error != null && error.isNotEmpty) {
      return '<div class="flash err">${_escapeHtml(error)}</div>';
    }

    return '';
  }

  String _workshopCardHtml(WorkshopModel workshop) {
    final String mapUrl =
        'https://yandex.com/maps/?pt=${workshop.longitude.toStringAsFixed(6)},${workshop.latitude.toStringAsFixed(6)}&z=15&l=map';

    return '''
<section class="card">
  <div class="title">
    <h2>${_escapeHtml(workshop.name)}</h2>
    <div class="badge">${_escapeHtml(workshop.badge)}</div>
  </div>
  <p class="meta">
    <strong>Usta:</strong> ${_escapeHtml(workshop.master)}<br>
    <strong>Manzil:</strong> ${_escapeHtml(workshop.address)}
  </p>
  <div class="current">
    <strong>Joriy koordinata:</strong><br>
    Latitude: <code>${workshop.latitude.toStringAsFixed(6)}</code><br>
    Longitude: <code>${workshop.longitude.toStringAsFixed(6)}</code>
  </div>
  <form method="post" action="/admin/workshops/${Uri.encodeComponent(workshop.id)}/location">
    <div>
      <label for="lat-${_escapeHtml(workshop.id)}">Latitude</label>
      <input
        id="lat-${_escapeHtml(workshop.id)}"
        type="text"
        name="latitude"
        value="${_escapeHtml(workshop.latitude.toStringAsFixed(6))}"
        inputmode="decimal"
        autocomplete="off">
    </div>
    <div>
      <label for="lng-${_escapeHtml(workshop.id)}">Longitude</label>
      <input
        id="lng-${_escapeHtml(workshop.id)}"
        type="text"
        name="longitude"
        value="${_escapeHtml(workshop.longitude.toStringAsFixed(6))}"
        inputmode="decimal"
        autocomplete="off">
    </div>
    <div class="actions">
      <span class="hint">Maslahat: xaritadan taxminiy nuqtani olib <code>lat/lng</code> kiriting.</span>
      <div>
        <a href="${_escapeHtml(mapUrl)}" target="_blank" rel="noreferrer">Joriy nuqtani xaritada ko‘rish</a>
        &nbsp;&nbsp;
        <button type="submit">Saqlash</button>
      </div>
    </div>
  </form>
</section>
''';
  }

  String _escapeHtml(String value) => const HtmlEscape().convert(value);
}
