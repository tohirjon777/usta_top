import '../core/localization/app_localizations.dart';

String bookingCancellationReasonLabel(
  String raw,
  AppLocalizations l10n,
) {
  switch (raw.trim().toLowerCase()) {
    case 'workshop_busy':
      return l10n.cancellationReasonWorkshopBusy;
    case 'master_unavailable':
      return l10n.cancellationReasonMasterUnavailable;
    case 'workshop_closed':
      return l10n.cancellationReasonWorkshopClosed;
    case 'missing_parts':
      return l10n.cancellationReasonMissingParts;
    case 'customer_request':
      return l10n.cancellationReasonCustomerRequest;
    default:
      return l10n.cancellationUnknown;
  }
}

String bookingCancellationActorLabel(
  String raw,
  AppLocalizations l10n,
) {
  switch (raw.trim().toLowerCase()) {
    case 'customer':
      return l10n.cancellationActorCustomer;
    case 'admin':
      return l10n.cancellationActorAdmin;
    case 'owner_panel':
      return l10n.cancellationActorOwnerPanel;
    case 'owner_telegram':
      return l10n.cancellationActorOwnerTelegram;
    default:
      return l10n.cancellationUnknown;
  }
}

String bookingRescheduleActorLabel(
  String raw,
  AppLocalizations l10n,
) {
  switch (raw.trim().toLowerCase()) {
    case 'customer':
      return l10n.cancellationActorCustomer;
    case 'admin':
      return l10n.cancellationActorAdmin;
    case 'owner_panel':
      return l10n.cancellationActorOwnerPanel;
    case 'owner_telegram':
      return l10n.cancellationActorOwnerTelegram;
    default:
      return l10n.cancellationUnknown;
  }
}
