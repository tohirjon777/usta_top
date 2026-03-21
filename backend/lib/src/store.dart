import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'models.dart';

class InMemoryStore {
  InMemoryStore({
    required List<UserModel> users,
    required List<WorkshopModel> workshops,
    required List<BookingModel> bookings,
  })  : _workshops = workshops,
        _bookings = bookings {
    for (final UserModel user in users) {
      _usersById[user.id] = user;
      _usersByPhone[_normalizePhone(user.phone)] = user;
    }
  }

  factory InMemoryStore.withSeedData() {
    final List<UserModel> users = <UserModel>[
      const UserModel(
        id: 'u-1',
        fullName: 'Tokhirjon',
        phone: '+998901234567',
        password: '123456',
      ),
    ];

    final List<WorkshopModel> workshops = <WorkshopModel>[
      const WorkshopModel(
        id: 'w-1',
        name: 'Turbo Usta Servis',
        master: 'Aziz Usta',
        rating: 4.9,
        reviewCount: 218,
        address: 'Chilonzor, Toshkent',
        description:
            'Tez diagnostika va sifatli ta\'mirlash ishlari bir joyda.',
        distanceKm: 1.2,
        latitude: 41.2756,
        longitude: 69.2034,
        isOpen: true,
        badge: 'Eng ishonchli',
        services: <ServiceModel>[
          ServiceModel(
            id: 'srv-1',
            name: 'Kompyuter diagnostika',
            price: 120,
            durationMinutes: 35,
          ),
          ServiceModel(
            id: 'srv-2',
            name: 'Moy va filtr almashtirish',
            price: 90,
            durationMinutes: 30,
          ),
          ServiceModel(
            id: 'srv-3',
            name: 'Tormoz kolodkasini almashtirish',
            price: 180,
            durationMinutes: 55,
          ),
        ],
      ),
      const WorkshopModel(
        id: 'w-2',
        name: 'Motor Usta Markazi',
        master: 'Sardor Usta',
        rating: 4.8,
        reviewCount: 167,
        address: 'Yunusobod, Toshkent',
        description:
            'Dvigatel va yurish qismini puxta tekshiruv va kafolatli ta\'mirlash.',
        distanceKm: 2.4,
        latitude: 41.3631,
        longitude: 69.2897,
        isOpen: true,
        badge: 'Tez qabul',
        services: <ServiceModel>[
          ServiceModel(
            id: 'srv-4',
            name: 'Dvigatel diagnostikasi',
            price: 140,
            durationMinutes: 45,
          ),
          ServiceModel(
            id: 'srv-5',
            name: 'Akkumulyator va elektr tizimi tekshiruvi',
            price: 110,
            durationMinutes: 40,
          ),
          ServiceModel(
            id: 'srv-6',
            name: 'Konditsioner xizmati',
            price: 220,
            durationMinutes: 70,
          ),
        ],
      ),
      const WorkshopModel(
        id: 'w-3',
        name: 'Usta Mashina Servis',
        master: 'Bekzod Usta',
        rating: 4.7,
        reviewCount: 102,
        address: 'Mirzo Ulugbek, Toshkent',
        description:
            'Murakkab nosozliklarni tajribali ustalar bilan aniq bartaraf etish.',
        distanceKm: 3.1,
        latitude: 41.3301,
        longitude: 69.3382,
        isOpen: false,
        badge: 'Yuqori toifa',
        services: <ServiceModel>[
          ServiceModel(
            id: 'srv-7',
            name: 'Kuzov geometriyasi tekshiruvi',
            price: 160,
            durationMinutes: 55,
          ),
          ServiceModel(
            id: 'srv-8',
            name: 'Yurish qismi ta\'miri',
            price: 130,
            durationMinutes: 50,
          ),
          ServiceModel(
            id: 'srv-9',
            name: 'To\'liq texnik ko\'rik',
            price: 240,
            durationMinutes: 85,
          ),
        ],
      ),
    ];

    final DateTime now = DateTime.now();
    final List<BookingModel> bookings = <BookingModel>[
      BookingModel(
        id: 'b-seed-1',
        userId: 'u-1',
        workshopId: 'w-1',
        workshopName: 'Turbo Usta Servis',
        masterName: 'Aziz Usta',
        serviceId: 'srv-1',
        serviceName: 'Kompyuter diagnostika',
        dateTime: now.add(const Duration(days: 1, hours: 2)),
        price: 120,
        status: BookingStatus.upcoming,
        createdAt: now,
      ),
    ];

    return InMemoryStore(
      users: users,
      workshops: workshops,
      bookings: bookings,
    );
  }

  final Random _random = Random();
  final List<WorkshopModel> _workshops;
  final List<BookingModel> _bookings;
  final Map<String, UserModel> _usersByPhone = <String, UserModel>{};
  final Map<String, UserModel> _usersById = <String, UserModel>{};
  final Map<String, String> _tokenToUserId = <String, String>{};

  String? login({
    required String phone,
    required String password,
  }) {
    final UserModel? user = _usersByPhone[_normalizePhone(phone)];
    if (user == null || user.password != password) {
      return null;
    }

    final String token = _newId('token');
    _tokenToUserId[token] = user.id;
    return token;
  }

  UserModel? userByToken(String token) {
    final String? userId = _tokenToUserId[token];
    if (userId == null) {
      return null;
    }
    return _usersById[userId];
  }

  String newUserId() => _newId('u');

  UserModel createUser({
    required String fullName,
    required String phone,
    required String password,
  }) {
    final String normalizedPhone = _normalizePhone(phone);
    if (_usersByPhone.containsKey(normalizedPhone)) {
      throw StateError('Bu telefon raqam allaqachon ishlatilgan');
    }

    final UserModel user = UserModel(
      id: newUserId(),
      fullName: fullName,
      phone: phone,
      password: password,
    );
    _usersById[user.id] = user;
    _usersByPhone[normalizedPhone] = user;
    return user;
  }

  UserModel? resetUserPasswordByPhone({
    required String phone,
    required String newPassword,
  }) {
    final UserModel? current = _usersByPhone[_normalizePhone(phone)];
    if (current == null) {
      return null;
    }

    final UserModel updated = current.copyWith(password: newPassword);
    _usersById[current.id] = updated;
    _usersByPhone[_normalizePhone(updated.phone)] = updated;
    return updated;
  }

  UserModel? updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) {
    final UserModel? current = _usersById[userId];
    if (current == null) {
      return null;
    }

    final String normalizedPhone = _normalizePhone(phone);
    final UserModel? existing = _usersByPhone[normalizedPhone];
    if (existing != null && existing.id != userId) {
      throw StateError('Bu telefon raqam allaqachon ishlatilgan');
    }

    final UserModel updated = current.copyWith(
      fullName: fullName,
      phone: phone,
    );
    _usersByPhone.remove(_normalizePhone(current.phone));
    _usersById[userId] = updated;
    _usersByPhone[normalizedPhone] = updated;
    return updated;
  }

  UserModel? updateUserPassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    final UserModel? current = _usersById[userId];
    if (current == null) {
      return null;
    }
    if (current.password != currentPassword) {
      throw StateError('Joriy parol noto\'g\'ri');
    }

    final UserModel updated = current.copyWith(password: newPassword);
    _usersById[userId] = updated;
    _usersByPhone[_normalizePhone(updated.phone)] = updated;
    return updated;
  }

  Future<void> loadUsers(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Users file list bo\'lishi kerak');
    }

    final List<UserModel> users = decoded
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList(growable: false);
    if (users.isEmpty) {
      return;
    }

    _usersById.clear();
    _usersByPhone.clear();
    for (final UserModel user in users) {
      _usersById[user.id] = user;
      _usersByPhone[_normalizePhone(user.phone)] = user;
    }
  }

  Future<void> saveUsers(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final List<Map<String, Object>> data = _usersById.values
        .map((UserModel item) => item.toStorageJson())
        .toList(growable: false);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  List<WorkshopModel> workshops({String? query}) {
    final String q = (query ?? '').trim();
    if (q.isEmpty) {
      return List<WorkshopModel>.unmodifiable(_workshops);
    }

    final List<WorkshopModel> filtered = _workshops
        .where((WorkshopModel item) => item.matchesQuery(q))
        .toList(growable: false);
    return List<WorkshopModel>.unmodifiable(filtered);
  }

  WorkshopModel? workshopById(String id) {
    for (final WorkshopModel item in _workshops) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  String newWorkshopId() => _newId('w');

  String newServiceId() => _newId('srv');

  WorkshopModel createWorkshop({
    required WorkshopModel workshop,
  }) {
    if (workshopById(workshop.id) != null) {
      throw StateError('Workshop ID allaqachon mavjud');
    }
    _workshops.insert(0, workshop);
    return workshop;
  }

  WorkshopModel? updateWorkshop({
    required String workshopId,
    required WorkshopModel workshop,
  }) {
    final int index = _workshops.indexWhere(
      (WorkshopModel item) => item.id == workshopId,
    );
    if (index < 0) {
      return null;
    }

    final WorkshopModel updated = workshop.copyWith(id: workshopId);
    _workshops[index] = updated;
    return updated;
  }

  bool deleteWorkshop(String workshopId) {
    final int index = _workshops.indexWhere(
      (WorkshopModel item) => item.id == workshopId,
    );
    if (index < 0) {
      return false;
    }
    _workshops.removeAt(index);
    return true;
  }

  bool updateWorkshopLocation({
    required String workshopId,
    required double latitude,
    required double longitude,
  }) {
    final int index = _workshops.indexWhere(
      (WorkshopModel item) => item.id == workshopId,
    );
    if (index < 0) {
      return false;
    }

    _workshops[index] = _workshops[index].copyWith(
      latitude: latitude,
      longitude: longitude,
    );
    return true;
  }

  Future<void> loadWorkshopLocations(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Workshop locations file object bo\'lishi kerak',
      );
    }

    for (int i = 0; i < _workshops.length; i++) {
      final WorkshopModel workshop = _workshops[i];
      final dynamic item = decoded[workshop.id];
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final double? latitude = _toNullableDouble(item['latitude']);
      final double? longitude = _toNullableDouble(item['longitude']);
      if (latitude == null || longitude == null) {
        continue;
      }

      _workshops[i] = workshop.copyWith(
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  Future<void> loadWorkshops(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Workshops file list bo\'lishi kerak');
    }

    final List<WorkshopModel> workshops = decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkshopModel.fromJson)
        .toList(growable: false);
    if (workshops.isEmpty) {
      return;
    }

    _workshops
      ..clear()
      ..addAll(workshops);
  }

  Future<void> saveWorkshops(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final List<Map<String, Object>> data = _workshops
        .map((WorkshopModel item) => item.toJson())
        .toList(growable: false);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  Future<void> saveWorkshopLocations(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final Map<String, Object> data = <String, Object>{
      for (final WorkshopModel workshop in _workshops)
        workshop.id: <String, double>{
          'latitude': workshop.latitude,
          'longitude': workshop.longitude,
        },
    };

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  List<BookingModel> bookingsForUser(String userId) {
    final List<BookingModel> items = _bookings
        .where((BookingModel item) => item.userId == userId)
        .toList(growable: false)
      ..sort((BookingModel a, BookingModel b) {
        return b.dateTime.compareTo(a.dateTime);
      });
    return List<BookingModel>.unmodifiable(items);
  }

  BookingModel createBooking({
    required String userId,
    required String workshopId,
    required String serviceId,
    required DateTime dateTime,
  }) {
    final WorkshopModel? workshop = workshopById(workshopId);
    if (workshop == null) {
      throw StateError('Servis topilmadi');
    }

    final ServiceModel? service = workshop.getServiceById(serviceId);
    if (service == null) {
      throw StateError('Xizmat topilmadi');
    }

    final DateTime now = DateTime.now();
    if (dateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      throw StateError('Sana kelajakdagi vaqt bo\'lishi kerak');
    }

    final BookingModel booking = BookingModel(
      id: _newId('b'),
      userId: userId,
      workshopId: workshop.id,
      workshopName: workshop.name,
      masterName: workshop.master,
      serviceId: service.id,
      serviceName: service.name,
      dateTime: dateTime,
      price: service.price,
      status: BookingStatus.upcoming,
      createdAt: now,
    );
    _bookings.insert(0, booking);
    return booking;
  }

  BookingModel cancelBooking({
    required String userId,
    required String bookingId,
  }) {
    final int index = _bookings.indexWhere(
      (BookingModel item) => item.id == bookingId && item.userId == userId,
    );
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel current = _bookings[index];
    if (current.status == BookingStatus.cancelled) {
      return current;
    }

    final BookingModel updated =
        current.copyWith(status: BookingStatus.cancelled);
    _bookings[index] = updated;
    return updated;
  }

  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), '');
  }

  double? _toNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }

  String _newId(String prefix) {
    final String randomPart = _random.nextInt(10000).toString().padLeft(4, '0');
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }
}
