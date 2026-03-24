enum BookingChatSenderRole { customer, workshopOwner }

class BookingChatMessage {
  const BookingChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final BookingChatSenderRole senderRole;
  final String senderName;
  final String text;
  final DateTime createdAt;

  bool get isFromCustomer => senderRole == BookingChatSenderRole.customer;

  factory BookingChatMessage.fromJson(Map<String, dynamic> json) {
    return BookingChatMessage(
      id: (json['id'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      senderRole: bookingChatSenderRoleFromString(
        (json['senderRole'] ?? '').toString(),
      ),
      senderName: (json['senderName'] ?? '').toString().trim(),
      text: normalizeBookingChatText((json['text'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

BookingChatSenderRole bookingChatSenderRoleFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'workshop_owner':
      return BookingChatSenderRole.workshopOwner;
    case 'customer':
    default:
      return BookingChatSenderRole.customer;
  }
}

String bookingChatSenderRoleName(BookingChatSenderRole role) {
  switch (role) {
    case BookingChatSenderRole.customer:
      return 'customer';
    case BookingChatSenderRole.workshopOwner:
      return 'workshop_owner';
  }
}

String normalizeBookingChatText(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((String line) => line.trimRight())
      .join('\n')
      .trim();
}
