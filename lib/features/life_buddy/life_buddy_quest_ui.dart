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

QuestStatusUiState describeQuestStatus(AsyncValue<bool> questStatus) {
  // TODO(l10n): Replace inline status copy with localized strings.
  // 퀘스트 상태 메시지가 코드에 직접 작성되어 다른 언어 번역본을 제공할 수 없습니다.
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
              // TODO(l10n): Localize retry label instead of hardcoding Korean text.
              // 버튼 문구가 코드에 고정되어 있어 다국어 UI 구성 시 문제가 됩니다.
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
      child = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          // TODO(l10n): Provide localized loading copy for the claim button.
          // 현재 텍스트가 한국어로 박혀 있어 다른 언어 사용자에게 노출되지 않습니다.
          Text('상태 확인 중...'),
        ],
      );
    } else {
      // TODO(l10n): Translate claim CTA through localization files.
      // 일일 퀘스트 보상 문구가 하드코딩되어 있어 i18n 처리 대상입니다.
      child = const Text('일일 퀘스트 보상 받기');
    }
    return FilledButton.tonal(
      onPressed: disabled ? null : onClaim,
      child: child,
    );
  }
}
