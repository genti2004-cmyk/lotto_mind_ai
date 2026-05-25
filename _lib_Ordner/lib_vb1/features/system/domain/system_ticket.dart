import 'system_mode.dart';
import 'vew_system_type.dart';

class SystemTicket {
  final String title;
  final SystemMode mode;
  final List<int> baseNumbers;
  final List<List<int>> rows;
  final int? superNumber;
  final bool withSpiel77;
  final bool withSuper6;
  final int drawCount;
  final VewSystemType? vewType;

  const SystemTicket({
    this.title = '',
    required this.mode,
    required this.baseNumbers,
    required this.rows,
    this.superNumber,
    this.withSpiel77 = false,
    this.withSuper6 = false,
    this.drawCount = 1,
    this.vewType,
  });

  int get rowCount => rows.length;
}