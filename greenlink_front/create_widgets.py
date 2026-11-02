import os
import re

# We will create the models, services, widgets in the correct structure 
# and then update the imports across all files.

# 1. First, we will just create all the UI widgets in lib/core/widgets/

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

card_content = """import 'package:flutter/material.dart';

class GreenlinkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const GreenlinkCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surface;

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
"""

button_content = """import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, disabled }

class GreenlinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;

  const GreenlinkButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color fgColor;

    switch (type) {
      case ButtonType.primary:
        bgColor = theme.primaryColor;
        fgColor = theme.primaryColorDark;
        break;
      case ButtonType.secondary:
        bgColor = theme.scaffoldBackgroundColor;
        fgColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
        break;
      case ButtonType.disabled:
        bgColor = theme.disabledColor.withValues(alpha: 0.1);
        fgColor = theme.disabledColor;
        break;
    }

    if (onPressed == null) {
      bgColor = theme.disabledColor.withValues(alpha: 0.1);
      fgColor = theme.disabledColor;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: type == ButtonType.secondary
                ? BorderSide(color: theme.disabledColor.withValues(alpha: 0.2))
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }
}
"""

chip_content = """import 'package:flutter/material.dart';

class GreenlinkChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const GreenlinkChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColorDark : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : theme.disabledColor.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
"""

empty_state_content = """import 'package:flutter/material.dart';

class GreenlinkEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const GreenlinkEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.disabledColor.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.textTheme.bodyLarge?.color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.disabledColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
"""

loading_content = """import 'package:flutter/material.dart';

class GreenlinkLoading extends StatelessWidget {
  const GreenlinkLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
"""

def write_widgets():
    create_file('lib/core/widgets/greenlink_card.dart', card_content)
    create_file('lib/core/widgets/greenlink_button.dart', button_content)
    create_file('lib/core/widgets/greenlink_chip.dart', chip_content)
    create_file('lib/core/widgets/greenlink_empty_state.dart', empty_state_content)
    create_file('lib/core/widgets/greenlink_loading.dart', loading_content)

write_widgets()
print("Created core widgets.")
