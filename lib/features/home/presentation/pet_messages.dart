import '../../../core/state/app_controller.dart';
import '../../shop/domain/shop_catalog.dart';

/// Short, child-friendly texts that say what changed and why (ТЗ 2.5.9,
/// 2.5.10). Kept short: they are shown in the pet's speech bubble.
abstract final class PetMessages {
  /// Below this a status is called out in the bubble with its cause.
  static const int lowThreshold = 30;

  /// Bubble text for the pet's current state: the cause of a low status
  /// first, then (with hints on) a next step.
  static String forState(AppController state) {
    final pet = state.petState;
    if (pet.isHungry) {
      return 'Я проголодался: сытость ${pet.satiety}. Покорми меня!';
    }
    if (pet.care < lowThreshold) {
      return 'Шёрстка растрепалась: забота ${pet.care}. Нужен уход!';
    }
    if (pet.mood < lowThreshold) {
      return 'Мне скучно: настроение ${pet.mood}. Поиграем?';
    }
    if (state.hintsEnabled) {
      if (!state.budgetPlanConfirmed && state.balance > 0) {
        return 'Давай распределим монеты в «Бюджете»!';
      }
      if (state.activeMission == null && !state.isCurrentPeriodCompleted) {
        return 'Нас ждёт новое задание!';
      }
    }
    return 'Финансовые приключения вместе!';
  }

  /// The pet's reaction to a purchase.
  static String reactionTo(PurchaseReceipt receipt) {
    final item = receipt.item;
    if (item.food != null) {
      if (receipt.petAfter.isHungry) {
        return 'Спасибо! Но я ещё голоден: сытость ${receipt.petAfter.satiety}.';
      }
      return receipt.petBefore.isHungry
          ? 'Спасибо, я наелся! Сытость ${receipt.petAfter.satiety}.'
          : 'Вкусно! Сытость ${receipt.petAfter.satiety}.';
    }
    if (item.isPermanent) {
      return 'Ура! ${item.title} теперь в комнате!';
    }
    return 'Как приятно! Забота ${receipt.petAfter.care}.';
  }

  /// "−20 монет · Сытость +30 · Настроение +4" — the financial and game
  /// consequence of a purchase.
  static String summaryOf(PurchaseReceipt receipt) {
    final parts = [
      '−${receipt.spent} монет',
      if (receipt.satietyDelta > 0) 'Сытость +${receipt.satietyDelta}',
      if (receipt.careDelta > 0) 'Забота +${receipt.careDelta}',
      if (receipt.moodDelta > 0) 'Настроение +${receipt.moodDelta}',
    ];
    final next = receipt.petAfter.isHungry
        ? ' Покорми ещё, чтобы он наелся.'
        : '';
    return '${parts.join(' · ')}. Баланс: ${receipt.balanceAfter}.$next';
  }

  /// Why a status meter shows its value and how to raise it.
  static String explainMeter(String label, int value) => switch (label) {
    'Сытость' =>
      'Сытость $value из 100. Она понемногу падает со временем. '
          'Поднять её можно едой во вкладке «Покормить».',
    'Забота' =>
      'Забота $value из 100. Она медленно падает. Её поднимают '
          'поглаживание и уход: расчёска или купание.',
    _ =>
      'Настроение $value из 100. Оно медленно падает, а игрушки в комнате '
          'замедляют это. Поднять его можно игрой, вкусняшкой или игрушкой.',
  };
}
