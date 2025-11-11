import 'package:flutter/material.dart';

/// Modern button with refined interactions and animations
class ModernButton extends StatefulWidget {
  const ModernButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ModernButtonVariant.filled,
    this.size = ModernButtonSize.medium,
    this.fullWidth = false,
    this.leading,
    this.trailing,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final bool fullWidth;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Size configuration
    final EdgeInsets padding;
    final double minHeight;
    final TextStyle? textStyle;

    switch (widget.size) {
      case ModernButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        minHeight = 40;
        textStyle = theme.textTheme.labelMedium;
        break;
      case ModernButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        minHeight = 48;
        textStyle = theme.textTheme.labelLarge;
        break;
      case ModernButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        minHeight = 56;
        textStyle = theme.textTheme.titleMedium;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null && !widget.isLoading) ...[
          widget.leading!,
          const SizedBox(width: 8),
        ],
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == ModernButtonVariant.filled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        DefaultTextStyle(
          style: textStyle ?? const TextStyle(),
          child: widget.child,
        ),
        if (widget.trailing != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        child: _buildButton(context, padding, minHeight, content),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    EdgeInsets padding,
    double minHeight,
    Widget content,
  ) {
    switch (widget.variant) {
      case ModernButtonVariant.filled:
        return FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            padding: padding,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              minHeight,
            ),
          ),
          child: content,
        );

      case ModernButtonVariant.outlined:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              minHeight,
            ),
          ),
          child: content,
        );

      case ModernButtonVariant.text:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              minHeight,
            ),
          ),
          child: content,
        );

      case ModernButtonVariant.elevated:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding,
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 0,
              minHeight,
            ),
          ),
          child: content,
        );
    }
  }
}

enum ModernButtonVariant { filled, outlined, text, elevated }

enum ModernButtonSize { small, medium, large }

/// Icon button with refined design
class ModernIconButton extends StatefulWidget {
  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  @override
  State<ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<ModernIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color:
                widget.backgroundColor ??
                theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.size / 3.5),
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? theme.colorScheme.onSurface,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
