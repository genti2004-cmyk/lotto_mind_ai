/// Central storage identifiers used by the app.
///
/// Keeping box names in one place makes future backup/restore and migration
/// work safer because storage identifiers are no longer spread across screens
/// and services.
abstract final class AppStorageBoxes {
  static const String appState = 'lotto_app_box';
  static const String drawHistory = 'lotto_draw_history_box';
  static const String trackingProEntries = 'tracking_pro_entries';
  static const String systemPlayTickets = 'system_play_tickets';
}
