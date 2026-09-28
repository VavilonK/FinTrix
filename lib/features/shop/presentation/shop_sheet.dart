import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../budget/domain/budget_usage.dart';
import '../domain/shop_catalog.dart';

/// Purchases for the pet: food, care and room items. Resolves to what the
/// purchase changed, or null when nothing was bought.
Future<PurchaseReceipt?> showShopSheet({
  required BuildContext context,
  required VoidCallback onOpenTasks,
  ShopSection initialSection = ShopSection.food,
}) {
  return showAppModalSheet<PurchaseReceipt>(
    context: context,
    builder: (sheetContext) => ShopSheet(
      initialSection: initialSection,
      onOpenTasks: () {
        Navigator.of(sheetContext).pop();
        onOpenTasks();
      },
    ),
  );
}

class ShopSheet extends StatefulWidget {
  const ShopSheet({
    required this.onOpenTasks,
    this.initialSection = ShopSection.food,
    super.key,
  });

  final VoidCallback onOpenTasks;
  final ShopSection initialSection;

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  late ShopSection _section = widget.initialSection;
  late ShopItem _selected = ShopCatalog.section(_section).first;
  bool _insufficientFunds = false;
  ShopItem? _pendingOverrun;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = ShopCatalog.section(_section);
    final owned = state.ownedRoomItems.contains(_selected.id);
    final shortBy = _selected.cost - state.balance;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= 1.3 ||
        MediaQuery.sizeOf(context).width < 340;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            Expanded(
              child: Text(
                'Что купим?',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _CloseButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
        if (state.hintsEnabled) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Сначала важное: еда и уход. Приятное — если останутся монеты.',
            key: const ValueKey('shop_hint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _SectionTabs(section: _section, onChanged: _selectSection),
        const SizedBox(height: AppSpacing.sm),
        if (stacked)
          for (final item in items) ...[
            _ShopItemCard(
              key: ValueKey(_keyFor(item)),
              item: item,
              horizontal: true,
              selected: item.id == _selected.id,
              owned: state.ownedRoomItems.contains(item.id),
              shortBy: item.cost - state.balance,
              onTap: () => _select(item),
            ),
            if (item != items.last) const SizedBox(height: AppSpacing.xs),
          ]
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  Expanded(
                    child: _ShopItemCard(
                      key: ValueKey(_keyFor(item)),
                      item: item,
                      selected: item.id == _selected.id,
                      owned: state.ownedRoomItems.contains(item.id),
                      shortBy: item.cost - state.balance,
                      onTap: () => _select(item),
                    ),
                  ),
                  if (item != items.last) const SizedBox(width: AppSpacing.xs),
                ],
                // Keep card widths equal when a section has fewer items.
                for (var i = items.length; i < 3; i++) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (!owned && shortBy <= 0)
          _BalanceAfter(balanceAfter: state.balance - _selected.cost),
        const SizedBox(height: AppSpacing.sm),
        if (owned)
          const PrimaryGradientButton(
            key: ValueKey('shop_owned'),
            label: 'Уже в комнате',
            height: 56,
            onPressed: null,
          )
        else if (shortBy > 0 || _insufficientFunds)
          _NotEnoughCoins(
            item: _selected,
            shortBy: shortBy,
            cheaper: _cheaperAffordable(state),
            onOpenTasks: widget.onOpenTasks,
            onChooseCheaper: _select,
          )
        else if (_pendingOverrun == null)
          PrimaryGradientButton(
            key: const ValueKey('feed_confirm'),
            label: _selected.food != null
                ? 'Покормить за ${_selected.cost}'
                : 'Купить за ${_selected.cost}',
            height: 56,
            maxLines: 2,
            onPressed: () => _buy(state, _selected),
          ),
        if (_pendingOverrun case final item?)
          _OverrunCard(
            item: item,
            planned: state.plannedForExpense(item.category),
            spentAfter: state.spentForExpense(item.category) + item.cost,
            onCancel: () => setState(() => _pendingOverrun = null),
            onConfirm: () => _buy(state, item, confirmPlanOverrun: true),
          ),
      ],
    );
  }

  String _keyFor(ShopItem item) =>
      item.food != null ? 'feed_${item.food!.name}' : 'shop_${item.id}';

  ShopItem? _cheaperAffordable(AppController state) {
    final candidates = ShopCatalog.section(_section)
        .where(
          (item) =>
              item.cost <= state.balance &&
              !state.ownedRoomItems.contains(item.id),
        )
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.cost.compareTo(b.cost));
    return candidates.first;
  }

  void _selectSection(ShopSection section) {
    setState(() {
      _section = section;
      _selected = ShopCatalog.section(section).first;
      _insufficientFunds = false;
      _pendingOverrun = null;
    });
  }

  void _select(ShopItem item) {
    setState(() {
      _selected = item;
      _insufficientFunds = false;
      _pendingOverrun = null;
    });
  }

  void _buy(
    AppController state,
    ShopItem item, {
    bool confirmPlanOverrun = false,
  }) {
    final (result, receipt) = state.buyItem(
      item,
      confirmPlanOverrun: confirmPlanOverrun,
    );
    switch (result) {
      case ShopPurchaseResult.success:
        Navigator.of(context).pop(receipt);
      case ShopPurchaseResult.insufficientFunds:
        setState(() {
          _insufficientFunds = true;
          _pendingOverrun = null;
        });
      case ShopPurchaseResult.requiresConfirmation:
        setState(() {
          _pendingOverrun = item;
          _insufficientFunds = false;
        });
      case ShopPurchaseResult.alreadyOwned:
        setState(() {});
    }
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.section, required this.onChanged});

  final ShopSection section;
  final ValueChanged<ShopSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLavender,
        borderRadius: AppRadii.capsule,
      ),
      child: Row(
        children: [
          for (final value in ShopSection.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == section,
                child: Material(
                  color: value == section
                      ? AppColors.surface
                      : AppColors.transparent,
                  borderRadius: AppRadii.capsule,
                  child: InkWell(
                    key: ValueKey('shop_tab_${value.name}'),
                    borderRadius: AppRadii.capsule,
                    onTap: () => onChanged(value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minimumTouchTarget,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value.title,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 15,
                              color: value == section
                                  ? AppColors.primaryBlue
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});

  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final essential = category == ExpenseCategory.essential;
    final color = essential ? AppColors.primaryBlue : AppColors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: AppRadii.capsule,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            essential ? Icons.check_circle_rounded : Icons.favorite_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            essential ? 'Важное' : 'Приятное',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.selected,
    required this.owned,
    required this.shortBy,
    required this.onTap,
    this.horizontal = false,
    super.key,
  });

  final ShopItem item;
  final bool selected;
  final bool owned;

  /// Coins missing for this item; <= 0 when affordable.
  final int shortBy;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final muted = owned || shortBy > 0;
    final price = owned
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'В комнате',
                style: AppTextStyles.label.copyWith(color: AppColors.green),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 16,
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AppAssets.financeCoinSingle, width: 20, height: 20),
              const SizedBox(width: 4),
              Text(
                '${item.cost} монет',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
    final shortage = !owned && shortBy > 0
        ? Text(
            'не хватает $shortBy',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.pink,
              fontWeight: FontWeight.w800,
            ),
          )
        : null;
    final effects = Text(
      item.effectsLabel,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.navy,
        fontSize: 12,
        height: 1.2,
      ),
    );
    final image = Opacity(
      opacity: muted ? 0.55 : 1,
      child: Image.asset(item.asset, fit: BoxFit.contain),
    );

    return Semantics(
      selected: selected,
      button: true,
      label:
          '${item.title}, ${item.cost} монет, ${item.categoryLabel}, '
          '${item.effectsLabel}${shortBy > 0 ? ', не хватает $shortBy' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlueLight : AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.borderLight,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected ? AppShadows.primaryControl : AppShadows.card,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: horizontal
                  ? Row(
                      children: [
                        SizedBox(width: 64, height: 56, child: image),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _CategoryTag(category: item.category),
                              const SizedBox(height: 2),
                              effects,
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [price, ?shortage],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        AspectRatio(aspectRatio: 1.3, child: image),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            fontSize: MediaQuery.sizeOf(context).width < 400
                                ? 13
                                : 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _CategoryTag(category: item.category),
                        ),
                        const SizedBox(height: 4),
                        Expanded(child: Center(child: effects)),
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, child: price),
                        if (shortage != null)
                          FittedBox(fit: BoxFit.scaleDown, child: shortage),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceAfter extends StatelessWidget {
  const _BalanceAfter({required this.balanceAfter});

  final int balanceAfter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Flexible(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: balanceAfter >= 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Баланс после покупки: ',
                          style: AppTextStyles.caption,
                        ),
                        Image.asset(
                          AppAssets.financeCoinSingle,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _coins(balanceAfter),
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                      ],
                    )
                  : Text(
                      'Не хватает ${_coins(-balanceAfter)} монет',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.pink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Explains what is missing and what the child can do instead; buying on
/// credit is never offered.
class _NotEnoughCoins extends StatelessWidget {
  const _NotEnoughCoins({
    required this.item,
    required this.shortBy,
    required this.cheaper,
    required this.onOpenTasks,
    required this.onChooseCheaper,
  });

  final ShopItem item;
  final int shortBy;
  final ShopItem? cheaper;
  final VoidCallback onOpenTasks;
  final ValueChanged<ShopItem> onChooseCheaper;

  @override
  Widget build(BuildContext context) {
    final want = item.category == ExpenseCategory.want;
    return RoundedSurfaceCard(
      key: const ValueKey('shop_not_enough'),
      backgroundColor: AppColors.backgroundLavender,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text(
            'На «${item.title}» не хватает ${shortBy > 0 ? _coins(shortBy) : ''} монет.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            want
                ? 'Это приятная покупка — её можно отложить на потом. '
                      'А монеты можно заработать в заданиях.'
                : 'Можно заработать монеты в заданиях или выбрать '
                      'что-то подешевле.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryGradientButton(
            key: const ValueKey('feed_open_tasks'),
            label: 'К заданиям',
            height: 52,
            onPressed: onOpenTasks,
          ),
          if (cheaper case final option?) ...[
            const SizedBox(height: AppSpacing.xxs),
            TextButton(
              key: const ValueKey('shop_choose_cheaper'),
              onPressed: () => onChooseCheaper(option),
              child: Text('Выбрать дешевле: ${option.title} (${option.cost})'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverrunCard extends StatelessWidget {
  const _OverrunCard({
    required this.item,
    required this.planned,
    required this.spentAfter,
    required this.onCancel,
    required this.onConfirm,
  });

  final ShopItem item;
  final int planned;
  final int spentAfter;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final essential = item.category == ExpenseCategory.essential;
    return RoundedSurfaceCard(
      backgroundColor: const Color(0xFFFFF3D8),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text(
            '${essential ? 'На важное' : 'На приятное'} мы планировали '
            '${_coins(planned)} монет.\n'
            'Если купить это, получится ${_coins(spentAfter)}.\n\n'
            '${essential ? 'Всё равно купить?' : 'Можно отложить покупку на потом. Всё равно купить?'}',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  key: const ValueKey('feed_overrun_cancel'),
                  onPressed: onCancel,
                  child: Text(essential ? 'Не сейчас' : 'Отложить'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: PrimaryGradientButton(
                  key: const ValueKey('feed_overrun_confirm'),
                  label: 'Купить',
                  height: 50,
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Закрыть',
      child: InkResponse(
        key: const ValueKey('sheet_close'),
        onTap: onPressed,
        radius: 24,
        child: const SizedBox.square(
          dimension: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.backgroundLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppColors.secondaryText,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

String _coins(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ' ',
);
