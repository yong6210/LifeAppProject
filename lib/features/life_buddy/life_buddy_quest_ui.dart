import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestStatusUiState {
  const QuestStatusUiState({
    this.message,
    this.showSpinner = false,
    this.showRetry = false,
  });

  final String? message;
  final bool showSpinner;
  final bool showRetry;
}

// TODO: Move quest status strings into the localization bundle and drive them
// from the quest backend instead of hard-coding Korean copy here.
// The UI currently shows messages like '오늘 보상은 이미 받았어요.' directly in
// code, which blocks internationalization and prevents dynamic messaging from
// the database or remote configuration.
QuestStatusUiState describeQuestStatus(AsyncValue<bool> questStatus) {
  return questStatus.when<QuestStatusUiState>(
    data: (value) => value
        ? const QuestStatusUiState()
        : const QuestStatusUiState(message: '오늘 보상은 이미 받았어요.'),
    loading: () => const QuestStatusUiState(
      message: '보상 상태를 확인하고 있어요...',
      showSpinner: true,
    ),
    error: (error, stackTrace) => const QuestStatusUiState(
      message: '보상 상태를 불러올 수 없어요. 잠시 후 다시 시도해 주세요.',
      showRetry: true,
    ),
  );
}

class QuestStatusMessage extends StatelessWidget {
  const QuestStatusMessage({
    super.key,
    required this.message,
    this.showSpinner = false,
    this.onRetry,
  });

  final String message;
  final bool showSpinner;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showSpinner)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (showSpinner) const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('다시 불러오기'),
            ),
          ),
      ],
    );
  }
}

class QuestClaimButton extends StatelessWidget {
  const QuestClaimButton({
    super.key,
    required this.isClaiming,
    required this.isLoadingStatus,
    required this.canClaim,
    required this.onClaim,
  });

  final bool isClaiming;
  final bool isLoadingStatus;
  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final disabled = isClaiming || isLoadingStatus || !canClaim;
    Widget child;
    if (isClaiming) {
      child = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    } else if (isLoadingStatus) {
      // TODO: Localize the loading caption and button labels shown during quest
      // claim actions.
      // These fallbacks ('상태 확인 중...', '일일 퀘스트 보상 받기') are embedded in
      // the widget tree, so they won't honor the multi-language patch or any
      // runtime text updates from product copy reviews.
      child = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('상태 확인 중...'),
        ],
      );
    } else {
      child = const Text('일일 퀘스트 보상 받기');
    }
    return FilledButton.tonal(
      onPressed: disabled ? null : onClaim,
      child: child,
    );
  }
}
