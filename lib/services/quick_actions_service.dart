import 'package:quick_actions/quick_actions.dart';
import '../models/qr_code_model.dart';

class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  final QuickActions _quickActions = const QuickActions();

  factory QuickActionsService() => _instance;

  QuickActionsService._internal();

  void init(Function(String actionType) onActionSelected) {
    _quickActions.initialize((String type) {
      onActionSelected(type);
    });
  }

  /// Updates quick actions list with available QRs (up to 4)
  Future<void> updateQuickActions(List<QRCodeModel> qrCodes) async {
    final items = qrCodes.take(4).map((qr) {
      return ShortcutItem(
        type: 'qr_${qr.id}',
        localizedTitle: '${qr.banco} (${qr.referencia})',
        icon: 'ic_launcher',
      );
    }).toList();

    await _quickActions.setShortcutItems(items);
  }
}
