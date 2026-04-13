import 'package:flutter/material.dart';

class AdminFormDialog extends StatelessWidget {
  const AdminFormDialog({
    required this.title,
    required this.child,
    required this.onSave,
    this.onDelete,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECECEC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '✕',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECECEC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDelete != null)
                  Expanded(
                    child: AdminButton(
                      label: 'Xoá',
                      danger: true,
                      onPressed: () {
                        onDelete!();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                if (onDelete != null) const SizedBox(width: 8),
                Expanded(
                  child: AdminButton(
                    label: 'Huỷ',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdminButton(
                    label: 'Lưu',
                    filled: true,
                    onPressed: () {
                      onSave();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminFormField extends StatelessWidget {
  const AdminFormField({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.multiline = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: multiline ? null : maxLines,
          minLines: multiline ? 3 : null,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFea580c), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class AdminFormStatusToggle extends StatefulWidget {
  const AdminFormStatusToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeLabel = 'Hoạt động',
    this.inactiveLabel = 'Không hoạt động',
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String activeLabel;
  final String inactiveLabel;

  @override
  State<AdminFormStatusToggle> createState() => _AdminFormStatusToggleState();
}

class _AdminFormStatusToggleState extends State<AdminFormStatusToggle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.value ? const Color(0xFFea580c) : Colors.white,
                    border: Border.all(
                      color: widget.value ? const Color(0xFFea580c) : const Color(0xFFDDDDDD),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.activeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.value ? Colors.white : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !widget.value ? const Color(0xFFea580c) : Colors.white,
                    border: Border.all(
                      color: !widget.value ? const Color(0xFFea580c) : const Color(0xFFDDDDDD),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.inactiveLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !widget.value ? Colors.white : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class AdminButton extends StatelessWidget {
  const AdminButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFef4444)
              : filled
                  ? const Color(0xFFea580c)
                  : Colors.transparent,
          border: Border.all(
            color: danger
                ? const Color(0xFFef4444)
                : filled
                    ? Colors.transparent
                    : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: danger || filled ? Colors.white : const Color(0xFF171717),
            ),
          ),
        ),
      ),
    );
  }
}
