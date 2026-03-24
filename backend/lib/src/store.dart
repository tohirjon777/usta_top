import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'booking_cancellation.dart';
import 'models.dart';
import 'vehicle_types.dart';

class InMemoryStore {
  InMemoryStore({
    required List<UserModel> users,
    required List<WorkshopModel> workshops,
    required List<BookingModel> bookings,
    required List<BookingChatMessageModel> bookingMessages,
    required List<WorkshopReviewModel> reviews,
  })  : _workshops = List<WorkshopModel>.from(workshops),
        _bookings = List<BookingModel>.from(bookings),
        _bookingMessages = List<BookingChatMessageModel>.from(bookingMessages),
        _reviews = List<WorkshopReviewModel>.from(reviews) {
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
        ownerAccessCode: '5252',
        telegramChatId: '',
        telegramChatLabel: '',
        telegramLinkCode: '',
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
        ownerAccessCode: '0002',
        telegramChatId: '',
        telegramChatLabel: '',
        telegramLinkCode: '',
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
        ownerAccessCode: '0003',
        telegramChatId: '',
        telegramChatLabel: '',
        telegramLinkCode: '',
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
        customerName: 'Tokhirjon',
        customerPhone: '+998901234567',
        workshopId: 'w-1',
        workshopName: 'Turbo Usta Servis',
        masterName: 'Aziz Usta',
        serviceId: 'srv-1',
        serviceName: 'Kompyuter diagnostika',
        vehicleModel: 'Chevrolet Cobalt',
        vehicleTypeId: 'sedan',
        dateTime: now.add(const Duration(days: 1, hours: 2)),
        basePrice: 120,
        price: 120,
        status: BookingStatus.upcoming,
        createdAt: now,
      ),
    ];

      return InMemoryStore(
      users: users,
      workshops: workshops,
      bookings: bookings,
      bookingMessages: const <BookingChatMessageModel>[],
      reviews: const <WorkshopReviewModel>[],
    );
  }

  final Random _random = Random();
  final List<WorkshopModel> _workshops;
  final List<BookingModel> _bookings;
  final List<BookingChatMessageModel> _bookingMessages;
  final List<WorkshopReviewModel> _reviews;
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

  int revokeUserSessions(
    String userId, {
    Set<String> exceptTokens = const <String>{},
  }) {
    final List<String> tokensToRemove = _tokenToUserId.entries
        .where(
          (MapEntry<String, String> entry) =>
              entry.value == userId && !exceptTokens.contains(entry.key),
        )
        .map((MapEntry<String, String> entry) => entry.key)
        .toList(growable: false);
    for (final String token in tokensToRemove) {
      _tokenToUserId.remove(token);
    }
    return tokensToRemove.length;
  }

  UserModel? userById(String userId) => _usersById[userId];

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

  UserModel? registerUserPushToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    final UserModel? current = _usersById[userId];
    if (current == null) {
      return null;
    }

    final String normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw StateError('Push token majburiy');
    }

    _removePushTokenFromAllUsers(
      normalizedToken,
      exceptUserId: userId,
    );

    final List<PushTokenModel> nextTokens = current.pushTokens
        .where((PushTokenModel item) => item.token != normalizedToken)
        .toList(growable: true)
      ..insert(
        0,
        PushTokenModel(
          token: normalizedToken,
          platform: normalizePushPlatform(platform),
          updatedAt: DateTime.now(),
        ),
      );

    final UserModel updated = current.copyWith(
      pushTokens: List<PushTokenModel>.unmodifiable(nextTokens),
    );
    _usersById[userId] = updated;
    _usersByPhone[_normalizePhone(updated.phone)] = updated;
    return updated;
  }

  UserModel? unregisterUserPushToken({
    required String userId,
    required String token,
  }) {
    final UserModel? current = _usersById[userId];
    if (current == null) {
      return null;
    }

    final String normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw StateError('Push token majburiy');
    }

    final List<PushTokenModel> nextTokens = current.pushTokens
        .where((PushTokenModel item) => item.token != normalizedToken)
        .toList(growable: false);
    final UserModel updated = current.copyWith(
      pushTokens: List<PushTokenModel>.unmodifiable(nextTokens),
    );
    _usersById[userId] = updated;
    _usersByPhone[_normalizePhone(updated.phone)] = updated;
    return updated;
  }

  UserModel? rememberUserVehicle({
    required String userId,
    required String brand,
    required String model,
    required String vehicleTypeId,
    String catalogVehicleId = '',
    required bool isCustom,
  }) {
    final UserModel? current = _usersById[userId];
    if (current == null) {
      return null;
    }

    final String normalizedBrand = normalizeSavedVehicleBrand(brand);
    final String normalizedModel = normalizeSavedVehicleModelName(model);
    if (normalizedBrand.isEmpty || normalizedModel.isEmpty) {
      throw StateError('Mashina brandi va modeli majburiy');
    }

    final DateTime now = DateTime.now();
    final List<SavedVehicleModel> nextVehicles = <SavedVehicleModel>[];
    SavedVehicleModel? matched;

    for (final SavedVehicleModel item in current.savedVehicles) {
      final bool isSameVehicle =
          item.brand.toLowerCase() == normalizedBrand.toLowerCase() &&
              item.model.toLowerCase() == normalizedModel.toLowerCase();
      if (isSameVehicle) {
        matched = item.copyWith(
          brand: normalizedBrand,
          model: normalizedModel,
          vehicleTypeId: vehicleTypePricingById(vehicleTypeId).id,
          catalogVehicleId: catalogVehicleId.trim(),
          isCustom: isCustom,
          usageCount: item.usageCount + 1,
          lastUsedAt: now,
        );
      } else {
        nextVehicles.add(item);
      }
    }

    nextVehicles.insert(
      0,
      matched ??
          SavedVehicleModel(
            id: _newId('veh'),
            brand: normalizedBrand,
            model: normalizedModel,
            vehicleTypeId: vehicleTypePricingById(vehicleTypeId).id,
            catalogVehicleId: catalogVehicleId.trim(),
            isCustom: isCustom,
            usageCount: 1,
            lastUsedAt: now,
          ),
    );

    nextVehicles.sort((SavedVehicleModel a, SavedVehicleModel b) {
      final int usageOrder = b.usageCount.compareTo(a.usageCount);
      if (usageOrder != 0) {
        return usageOrder;
      }
      final DateTime aTime =
          a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final List<SavedVehicleModel> trimmed = nextVehicles.take(8).toList(
          growable: false,
        );
    final UserModel updated = current.copyWith(
      savedVehicles: List<SavedVehicleModel>.unmodifiable(trimmed),
    );
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
    _pruneInvalidAuthSessions();
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

  Future<void> loadAuthSessions(String filePath) async {
    final File file = File(filePath);
    _tokenToUserId.clear();
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Auth sessions file object bo\'lishi kerak');
    }

    decoded.forEach((String token, dynamic rawUserId) {
      final String normalizedToken = token.trim();
      final String userId = rawUserId?.toString().trim() ?? '';
      if (normalizedToken.isEmpty || userId.isEmpty) {
        return;
      }
      if (!_usersById.containsKey(userId)) {
        return;
      }
      _tokenToUserId[normalizedToken] = userId;
    });
    _pruneInvalidAuthSessions();
  }

  Future<void> saveAuthSessions(String filePath) async {
    _pruneInvalidAuthSessions();

    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final Map<String, String> data = <String, String>{
      for (final MapEntry<String, String> entry in _tokenToUserId.entries)
        entry.key: entry.value,
    };
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  Future<void> loadBookings(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    final String trimmed = raw.trim();
    _bookings.clear();
    if (trimmed.isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is! List) {
      throw const FormatException('Bookings file list bo\'lishi kerak');
    }

    final List<BookingModel> bookings = decoded
        .whereType<Map<String, dynamic>>()
        .map(BookingModel.fromJson)
        .toList(growable: false);
    _bookings.addAll(bookings);
  }

  Future<void> saveBookings(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final List<Map<String, Object>> data = _bookings
        .map((BookingModel item) => item.toStorageJson())
        .toList(growable: false);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  Future<void> loadBookingMessages(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    final String trimmed = raw.trim();
    _bookingMessages.clear();
    if (trimmed.isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is! List) {
      throw const FormatException('Booking messages file list bo\'lishi kerak');
    }

    final List<BookingChatMessageModel> messages = decoded
        .whereType<Map<String, dynamic>>()
        .map(BookingChatMessageModel.fromJson)
        .where((BookingChatMessageModel item) {
      return item.bookingId.isNotEmpty && item.text.isNotEmpty;
    }).toList(growable: false);
    _bookingMessages.addAll(messages);
  }

  Future<void> saveBookingMessages(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final List<Map<String, Object>> data = _bookingMessages
        .map((BookingChatMessageModel item) => item.toJson())
        .toList(growable: false);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  Future<void> loadReviews(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final String raw = await file.readAsString();
    final String trimmed = raw.trim();
    _reviews.clear();
    if (trimmed.isEmpty) {
      return;
    }

    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is! List) {
      throw const FormatException('Reviews file list bo\'lishi kerak');
    }

    final List<WorkshopReviewModel> reviews = decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkshopReviewModel.fromJson)
        .where((WorkshopReviewModel item) {
      return item.workshopId.isNotEmpty &&
          item.serviceId.isNotEmpty &&
          item.comment.isNotEmpty;
    }).toList(growable: false);
    _reviews.addAll(reviews);
  }

  Future<void> saveReviews(String filePath) async {
    final File file = File(filePath);
    await file.parent.create(recursive: true);

    final List<Map<String, Object>> data = _reviews
        .map((WorkshopReviewModel item) => item.toJson())
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

  WorkshopModel? workshopByOwnerAccess({
    required String workshopId,
    required String accessCode,
  }) {
    final WorkshopModel? workshop = workshopById(workshopId);
    if (workshop == null) {
      return null;
    }

    if (workshop.ownerAccessCode.trim() != accessCode.trim()) {
      return null;
    }
    return workshop;
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

  BookingModel? bookingById(String bookingId) {
    for (final BookingModel item in _bookings) {
      if (item.id == bookingId) {
        return item;
      }
    }
    return null;
  }

  BookingModel? bookingForUser({
    required String userId,
    required String bookingId,
  }) {
    for (final BookingModel item in _bookings) {
      if (item.id == bookingId && item.userId == userId) {
        return item;
      }
    }
    return null;
  }

  BookingModel? bookingForWorkshop({
    required String workshopId,
    required String bookingId,
  }) {
    for (final BookingModel item in _bookings) {
      if (item.id == bookingId && item.workshopId == workshopId) {
        return item;
      }
    }
    return null;
  }

  List<BookingModel> bookings({
    String? workshopId,
    BookingStatus? status,
  }) {
    final List<BookingModel> items = _bookings.where((BookingModel item) {
      if (workshopId != null &&
          workshopId.trim().isNotEmpty &&
          item.workshopId != workshopId.trim()) {
        return false;
      }
      if (status != null && item.status != status) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((BookingModel a, BookingModel b) {
        return b.createdAt.compareTo(a.createdAt);
      });
    return List<BookingModel>.unmodifiable(items);
  }

  List<BookingModel> bookingsAwaitingReviewReminder({
    required Duration delay,
    DateTime? now,
  }) {
    final DateTime effectiveNow = now ?? DateTime.now();
    final List<BookingModel> items = _bookings.where((BookingModel item) {
      if (item.status != BookingStatus.completed ||
          item.completedAt == null ||
          item.reviewReminderSentAt != null) {
        return false;
      }
      if (reviewByBookingId(item.id) != null) {
        return false;
      }
      return item.completedAt!.add(delay).isBefore(effectiveNow);
    }).toList(growable: false)
      ..sort((BookingModel a, BookingModel b) {
        return a.completedAt!.compareTo(b.completedAt!);
      });
    return List<BookingModel>.unmodifiable(items);
  }

  BookingModel markReviewReminderSent(
    String bookingId, {
    DateTime? sentAt,
  }) {
    final int index =
        _bookings.indexWhere((BookingModel item) => item.id == bookingId);
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel updated = _bookings[index].copyWith(
      reviewReminderSentAt: sentAt ?? DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  List<WorkshopReviewModel> reviewsForWorkshop({
    required String workshopId,
    String? serviceId,
    bool includeHidden = false,
  }) {
    final String normalizedWorkshopId = workshopId.trim();
    final String normalizedServiceId = (serviceId ?? '').trim();
    final List<WorkshopReviewModel> items = _reviews.where(
      (WorkshopReviewModel item) {
        if (item.workshopId != normalizedWorkshopId) {
          return false;
        }
        if (normalizedServiceId.isNotEmpty && item.serviceId != normalizedServiceId) {
          return false;
        }
        if (!includeHidden && item.isHidden) {
          return false;
        }
        return true;
      },
    ).toList(growable: false)
      ..sort((WorkshopReviewModel a, WorkshopReviewModel b) {
        return b.createdAt.compareTo(a.createdAt);
      });
    return List<WorkshopReviewModel>.unmodifiable(items);
  }

  WorkshopReviewModel? reviewById(String reviewId) {
    final String normalizedReviewId = reviewId.trim();
    if (normalizedReviewId.isEmpty) {
      return null;
    }
    for (final WorkshopReviewModel item in _reviews) {
      if (item.id == normalizedReviewId) {
        return item;
      }
    }
    return null;
  }

  WorkshopReviewModel? reviewByBookingId(String bookingId) {
    final String normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) {
      return null;
    }
    for (final WorkshopReviewModel item in _reviews) {
      if (item.bookingId == normalizedBookingId) {
        return item;
      }
    }
    return null;
  }

  WorkshopReviewModel createWorkshopReview({
    required String userId,
    required String workshopId,
    required String serviceId,
    required int rating,
    required String comment,
    String bookingId = '',
  }) {
    final UserModel? user = _usersById[userId];
    if (user == null) {
      throw StateError('Foydalanuvchi topilmadi');
    }

    final String normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isNotEmpty) {
      final BookingModel? booking = bookingForUser(
        userId: user.id,
        bookingId: normalizedBookingId,
      );
      if (booking == null) {
        throw StateError('Sharh uchun zakaz topilmadi');
      }
      if (booking.status != BookingStatus.completed) {
        throw StateError('Sharh faqat yakunlangan zakazdan keyin qoldiriladi');
      }
      if (booking.workshopId != workshopId || booking.serviceId != serviceId) {
        throw StateError('Sharh tanlangan zakaz xizmatiga mos emas');
      }
      if (reviewByBookingId(normalizedBookingId) != null) {
        throw StateError('Bu zakaz uchun sharh allaqachon qoldirilgan');
      }
    }

    final int workshopIndex = _workshops.indexWhere(
      (WorkshopModel item) => item.id == workshopId,
    );
    if (workshopIndex < 0) {
      throw StateError('Servis topilmadi');
    }

    final WorkshopModel workshop = _workshops[workshopIndex];
    final ServiceModel? service = workshop.getServiceById(serviceId);
    if (service == null) {
      throw StateError('Xizmat topilmadi');
    }

    final int normalizedRating = rating.clamp(1, 5);
    final String normalizedComment = normalizeWorkshopReviewText(comment);
    if (normalizedComment.length < 3) {
      throw StateError('Sharh kamida 3 ta belgidan iborat bo\'lsin');
    }

    final WorkshopReviewModel review = WorkshopReviewModel(
      id: _newId('rv'),
      workshopId: workshop.id,
      serviceId: service.id,
      serviceName: service.name,
      userId: user.id,
      customerName: user.fullName.trim().isEmpty ? user.phone : user.fullName,
      customerPhone: user.phone,
      rating: normalizedRating,
      comment: normalizedComment,
      createdAt: DateTime.now(),
      bookingId: normalizedBookingId,
    );
    _reviews.add(review);

    final int currentCount = workshop.reviewCount;
    final double nextRating = currentCount <= 0
        ? normalizedRating.toDouble()
        : ((workshop.rating * currentCount) + normalizedRating) /
            (currentCount + 1);
    _workshops[workshopIndex] = workshop.copyWith(
      rating: double.parse(nextRating.toStringAsFixed(1)),
      reviewCount: currentCount + 1,
    );
    return review;
  }

  WorkshopReviewModel replyToWorkshopReview({
    required String workshopId,
    required String reviewId,
    required String reply,
    required String source,
  }) {
    final String normalizedWorkshopId = workshopId.trim();
    final String normalizedReviewId = reviewId.trim();
    final String normalizedReply = normalizeWorkshopReviewText(reply);
    if (normalizedReply.length < 2) {
      throw StateError('Javob kamida 2 ta belgidan iborat bo\'lsin');
    }

    final int index = _reviews.indexWhere((WorkshopReviewModel item) {
      return item.id == normalizedReviewId &&
          item.workshopId == normalizedWorkshopId;
    });
    if (index < 0) {
      throw StateError('Sharh topilmadi');
    }

    final WorkshopReviewModel updated = _reviews[index].copyWith(
      ownerReply: normalizedReply,
      ownerReplyAt: DateTime.now(),
      ownerReplySource: source.trim(),
    );
    _reviews[index] = updated;
    return updated;
  }

  WorkshopReviewModel setWorkshopReviewHidden({
    required String workshopId,
    required String reviewId,
    required bool hidden,
    required String actorRole,
    required String reason,
  }) {
    final String normalizedWorkshopId = workshopId.trim();
    final String normalizedReviewId = reviewId.trim();
    final String normalizedReason = normalizeWorkshopReviewText(reason);
    final int workshopIndex = _workshops.indexWhere(
      (WorkshopModel item) => item.id == normalizedWorkshopId,
    );
    if (workshopIndex < 0) {
      throw StateError('Servis topilmadi');
    }
    final int index = _reviews.indexWhere((WorkshopReviewModel item) {
      return item.id == normalizedReviewId &&
          item.workshopId == normalizedWorkshopId;
    });
    if (index < 0) {
      throw StateError('Sharh topilmadi');
    }

    final WorkshopReviewModel current = _reviews[index];
    if (current.isHidden == hidden) {
      return current;
    }
    final WorkshopReviewModel updated = hidden
        ? current.copyWith(
            isHidden: true,
            hiddenAt: DateTime.now(),
            hiddenByRole: actorRole.trim(),
            hiddenReason:
                normalizedReason.isEmpty ? 'admin_flagged' : normalizedReason,
          )
        : WorkshopReviewModel(
            id: current.id,
            workshopId: current.workshopId,
            serviceId: current.serviceId,
            serviceName: current.serviceName,
            userId: current.userId,
            customerName: current.customerName,
            customerPhone: current.customerPhone,
            rating: current.rating,
            comment: current.comment,
            createdAt: current.createdAt,
            ownerReply: current.ownerReply,
            ownerReplyAt: current.ownerReplyAt,
            ownerReplySource: current.ownerReplySource,
            isHidden: false,
            hiddenAt: null,
            hiddenByRole: '',
            hiddenReason: '',
          );
    _reviews[index] = updated;
    final WorkshopModel workshop = _workshops[workshopIndex];
    final int currentCount = workshop.reviewCount;
    final double currentRating = workshop.rating;
    late final int nextCount;
    late final double nextRating;
    if (hidden) {
      nextCount = currentCount <= 0 ? 0 : currentCount - 1;
      nextRating = nextCount <= 0
          ? 0
          : (((currentRating * currentCount) - current.rating) / nextCount);
    } else {
      nextCount = currentCount + 1;
      nextRating = (((currentRating * currentCount) + current.rating) / nextCount);
    }
    _workshops[workshopIndex] = workshop.copyWith(
      reviewCount: nextCount,
      rating: double.parse(nextRating.toStringAsFixed(1)),
    );
    return updated;
  }

  List<BookingChatMessageModel> bookingMessagesForUser({
    required String userId,
    required String bookingId,
  }) {
    final BookingModel? booking = bookingForUser(
      userId: userId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Buyurtma topilmadi');
    }
    return _messagesForBooking(booking.id);
  }

  List<BookingChatMessageModel> bookingMessagesForWorkshop({
    required String workshopId,
    required String bookingId,
  }) {
    final BookingModel? booking = bookingForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Zakaz topilmadi');
    }
    return _messagesForBooking(booking.id);
  }

  BookingChatMessageModel createCustomerBookingMessage({
    required String userId,
    required String bookingId,
    required String text,
  }) {
    final UserModel? user = _usersById[userId];
    if (user == null) {
      throw StateError('Foydalanuvchi topilmadi');
    }

    final BookingModel? booking = bookingForUser(
      userId: userId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Buyurtma topilmadi');
    }

    return _appendBookingMessage(
      bookingId: booking.id,
      senderRole: BookingChatSenderRole.customer,
      senderName: user.fullName.trim().isEmpty ? user.phone : user.fullName,
      text: text,
    );
  }

  BookingChatMessageModel createWorkshopBookingMessage({
    required String workshopId,
    required String bookingId,
    required String text,
  }) {
    final WorkshopModel? workshop = workshopById(workshopId);
    if (workshop == null) {
      throw StateError('Workshop topilmadi');
    }

    final BookingModel? booking = bookingForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Zakaz topilmadi');
    }

    final String senderName =
        workshop.master.trim().isEmpty ? workshop.name : workshop.master;
    return _appendBookingMessage(
      bookingId: booking.id,
      senderRole: BookingChatSenderRole.workshopOwner,
      senderName: senderName,
      text: text,
    );
  }

  int markBookingMessagesReadForCustomer({
    required String userId,
    required String bookingId,
  }) {
    final BookingModel? booking = bookingForUser(
      userId: userId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Buyurtma topilmadi');
    }

    final DateTime now = DateTime.now();
    int updatedCount = 0;
    for (int i = 0; i < _bookingMessages.length; i++) {
      final BookingChatMessageModel message = _bookingMessages[i];
      if (message.bookingId != booking.id ||
          message.isFromCustomer ||
          message.readByCustomerAt != null) {
        continue;
      }
      _bookingMessages[i] = message.copyWith(readByCustomerAt: now);
      updatedCount += 1;
    }
    return updatedCount;
  }

  int markBookingMessagesReadForWorkshop({
    required String workshopId,
    required String bookingId,
  }) {
    final BookingModel? booking = bookingForWorkshop(
      workshopId: workshopId,
      bookingId: bookingId,
    );
    if (booking == null) {
      throw StateError('Zakaz topilmadi');
    }

    final DateTime now = DateTime.now();
    int updatedCount = 0;
    for (int i = 0; i < _bookingMessages.length; i++) {
      final BookingChatMessageModel message = _bookingMessages[i];
      if (message.bookingId != booking.id ||
          !message.isFromCustomer ||
          message.readByOwnerAt != null) {
        continue;
      }
      _bookingMessages[i] = message.copyWith(readByOwnerAt: now);
      updatedCount += 1;
    }
    return updatedCount;
  }

  BookingChatSummaryModel chatSummaryForBooking(String bookingId) {
    final List<BookingChatMessageModel> messages =
        _messagesForBooking(bookingId);
    if (messages.isEmpty) {
      return const BookingChatSummaryModel();
    }

    final BookingChatMessageModel latest = messages.last;
    int unreadForCustomerCount = 0;
    int unreadForOwnerCount = 0;
    for (final BookingChatMessageModel item in messages) {
      if (item.isFromCustomer) {
        if (item.readByOwnerAt == null) {
          unreadForOwnerCount += 1;
        }
      } else if (item.readByCustomerAt == null) {
        unreadForCustomerCount += 1;
      }
    }

    return BookingChatSummaryModel(
      messageCount: messages.length,
      unreadForCustomerCount: unreadForCustomerCount,
      unreadForOwnerCount: unreadForOwnerCount,
      lastMessagePreview: bookingChatPreview(latest.text),
      lastMessageSenderRole: bookingChatSenderRoleName(latest.senderRole),
      lastMessageAt: latest.createdAt,
    );
  }

  BookingModel createBooking({
    required String userId,
    required String workshopId,
    required String serviceId,
    required String vehicleModel,
    String vehicleBrand = '',
    String vehicleModelName = '',
    String catalogVehicleId = '',
    bool isCustomVehicle = false,
    required String vehicleTypeId,
    required DateTime dateTime,
  }) {
    final UserModel? user = _usersById[userId];
    if (user == null) {
      throw StateError('Foydalanuvchi topilmadi');
    }

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
    final String normalizedVehicleBrand = normalizeSavedVehicleBrand(
      vehicleBrand,
    );
    final String normalizedVehicleModelName = normalizeSavedVehicleModelName(
      vehicleModelName,
    );
    final String normalizedVehicleModel = vehicleModel.trim().isEmpty
        ? formatSavedVehicleDisplayName(
            brand: normalizedVehicleBrand,
            model: normalizedVehicleModelName,
          )
        : vehicleModel.trim();
    if (normalizedVehicleModel.isEmpty) {
      throw StateError('Mashina modeli ko\'rsatilishi kerak');
    }
    final VehicleTypePricing vehicleType =
        vehicleTypePricingById(vehicleTypeId);
    final int finalPrice = adjustedServicePrice(
      basePrice: service.price,
      vehicleTypeId: vehicleType.id,
    );

    final BookingModel booking = BookingModel(
      id: _newId('b'),
      userId: userId,
      customerName: user.fullName,
      customerPhone: user.phone,
      workshopId: workshop.id,
      workshopName: workshop.name,
      masterName: workshop.master,
      serviceId: service.id,
      serviceName: service.name,
      vehicleModel: normalizedVehicleModel,
      vehicleTypeId: vehicleType.id,
      dateTime: dateTime,
      basePrice: service.price,
      price: finalPrice,
      status: BookingStatus.upcoming,
      createdAt: now,
    );
    _bookings.insert(0, booking);
    if (normalizedVehicleBrand.isNotEmpty &&
        normalizedVehicleModelName.isNotEmpty) {
      rememberUserVehicle(
        userId: userId,
        brand: normalizedVehicleBrand,
        model: normalizedVehicleModelName,
        vehicleTypeId: vehicleType.id,
        catalogVehicleId: catalogVehicleId,
        isCustom: isCustomVehicle,
      );
    }
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
    _ensureCustomerCancellationAllowed(current);
    final BookingModel updated = current.copyWith(
      status: BookingStatus.cancelled,
      cancelReasonId: 'customer_request',
      cancelledByRole: 'customer',
      cancelledAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  BookingModel cancelBookingByAdmin({
    required String bookingId,
    required String reasonId,
  }) {
    final int index =
        _bookings.indexWhere((BookingModel item) => item.id == bookingId);
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel current = _bookings[index];
    _ensureWorkshopCancellationAllowed(
      booking: current,
      reasonId: reasonId,
    );
    final BookingModel updated = current.copyWith(
      status: BookingStatus.cancelled,
      cancelReasonId: normalizeBookingCancellationReasonId(reasonId),
      cancelledByRole: 'admin',
      cancelledAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  BookingModel updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) {
    final int index =
        _bookings.indexWhere((BookingModel item) => item.id == bookingId);
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel current = _bookings[index];
    _ensureStatusTransitionAllowed(
      current: current,
      nextStatus: status,
    );
    final BookingModel updated = current.copyWith(
      status: status,
      completedAt: status == BookingStatus.completed ? DateTime.now() : null,
      reviewReminderSentAt: null,
    );
    _bookings[index] = updated;
    return updated;
  }

  BookingModel updateWorkshopBookingStatus({
    required String workshopId,
    required String bookingId,
    required BookingStatus status,
  }) {
    final int index = _bookings.indexWhere(
      (BookingModel item) =>
          item.id == bookingId && item.workshopId == workshopId,
    );
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel current = _bookings[index];
    _ensureStatusTransitionAllowed(
      current: current,
      nextStatus: status,
    );
    final BookingModel updated = current.copyWith(
      status: status,
      completedAt: status == BookingStatus.completed ? DateTime.now() : null,
      reviewReminderSentAt: null,
    );
    _bookings[index] = updated;
    return updated;
  }

  BookingModel cancelWorkshopBooking({
    required String workshopId,
    required String bookingId,
    required String reasonId,
    required String actorRole,
  }) {
    final int index = _bookings.indexWhere(
      (BookingModel item) =>
          item.id == bookingId && item.workshopId == workshopId,
    );
    if (index < 0) {
      throw StateError('Buyurtma topilmadi');
    }

    final BookingModel current = _bookings[index];
    _ensureWorkshopCancellationAllowed(
      booking: current,
      reasonId: reasonId,
    );
    final BookingModel updated = current.copyWith(
      status: BookingStatus.cancelled,
      cancelReasonId: normalizeBookingCancellationReasonId(reasonId),
      cancelledByRole: normalizeBookingCancellationActor(actorRole),
      cancelledAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  void _ensureCustomerCancellationAllowed(BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.upcoming:
      case BookingStatus.accepted:
        return;
      case BookingStatus.completed:
        throw StateError('Yakunlangan buyurtmani bekor qilib bo‘lmaydi');
      case BookingStatus.cancelled:
        throw StateError('Buyurtma allaqachon bekor qilingan');
    }
  }

  void _ensureWorkshopCancellationAllowed({
    required BookingModel booking,
    required String reasonId,
  }) {
    _ensureCustomerCancellationAllowed(booking);
    final String normalizedReason =
        normalizeBookingCancellationReasonId(reasonId);
    if (normalizedReason.isEmpty) {
      throw StateError('Bekor qilish sababi tanlanishi kerak');
    }

    final DateTime now = DateTime.now();
    if (!booking.dateTime.isAfter(now)) {
      throw StateError('Vaqti o‘tgan zakazni bekor qilib bo‘lmaydi');
    }
    if (!booking.dateTime.isAfter(now.add(workshopCancellationLeadTime))) {
      throw StateError(
        'Zakazni faqat bron vaqtigacha kamida ${workshopCancellationLeadTime.inMinutes} daqiqa qolganda bekor qilish mumkin',
      );
    }
  }

  void _ensureStatusTransitionAllowed({
    required BookingModel current,
    required BookingStatus nextStatus,
  }) {
    if (nextStatus == BookingStatus.cancelled) {
      throw StateError(
        'Bekor qilish uchun alohida bekor qilish tugmasidan foydalaning',
      );
    }

    if (current.status == nextStatus) {
      return;
    }

    switch (current.status) {
      case BookingStatus.upcoming:
        return;
      case BookingStatus.accepted:
        if (nextStatus == BookingStatus.completed) {
          return;
        }
        throw StateError('Qabul qilingan zakazni faqat yakunlash mumkin');
      case BookingStatus.completed:
        throw StateError(
            'Yakunlangan zakaz statusini qayta o‘zgartirib bo‘lmaydi');
      case BookingStatus.cancelled:
        throw StateError(
            'Bekor qilingan zakaz statusini qayta o‘zgartirib bo‘lmaydi');
    }
  }

  List<BookingChatMessageModel> _messagesForBooking(String bookingId) {
    final List<BookingChatMessageModel> items = _bookingMessages
        .where((BookingChatMessageModel item) => item.bookingId == bookingId)
        .toList(growable: false)
      ..sort((BookingChatMessageModel a, BookingChatMessageModel b) {
        return a.createdAt.compareTo(b.createdAt);
      });
    return List<BookingChatMessageModel>.unmodifiable(items);
  }

  BookingChatMessageModel _appendBookingMessage({
    required String bookingId,
    required BookingChatSenderRole senderRole,
    required String senderName,
    required String text,
  }) {
    final String normalizedText = normalizeBookingChatText(text);
    if (normalizedText.isEmpty) {
      throw StateError('Xabar matni majburiy');
    }
    if (normalizedText.length > 1000) {
      throw StateError('Xabar 1000 belgidan oshmasligi kerak');
    }

    final DateTime now = DateTime.now();
    final BookingChatMessageModel message = BookingChatMessageModel(
      id: _newId('msg'),
      bookingId: bookingId,
      senderRole: senderRole,
      senderName: senderName.trim().isEmpty ? 'Usta Top' : senderName.trim(),
      text: normalizedText,
      createdAt: now,
      readByCustomerAt:
          senderRole == BookingChatSenderRole.customer ? now : null,
      readByOwnerAt:
          senderRole == BookingChatSenderRole.workshopOwner ? now : null,
    );
    _bookingMessages.add(message);
    return message;
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

  void _pruneInvalidAuthSessions() {
    final List<String> invalidTokens = _tokenToUserId.entries
        .where(
          (MapEntry<String, String> entry) => !_usersById.containsKey(
            entry.value,
          ),
        )
        .map((MapEntry<String, String> entry) => entry.key)
        .toList(growable: false);
    for (final String token in invalidTokens) {
      _tokenToUserId.remove(token);
    }
  }

  void _removePushTokenFromAllUsers(
    String pushToken, {
    String? exceptUserId,
  }) {
    for (final String userId in _usersById.keys.toList(growable: false)) {
      if (exceptUserId != null && userId == exceptUserId) {
        continue;
      }

      final UserModel current = _usersById[userId]!;
      final List<PushTokenModel> nextTokens = current.pushTokens
          .where((PushTokenModel item) => item.token != pushToken)
          .toList(growable: false);
      if (nextTokens.length == current.pushTokens.length) {
        continue;
      }

      final UserModel updated = current.copyWith(
        pushTokens: List<PushTokenModel>.unmodifiable(nextTokens),
      );
      _usersById[userId] = updated;
      _usersByPhone[_normalizePhone(updated.phone)] = updated;
    }
  }
}
