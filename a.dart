import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget content;
  final IconData leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingContainerColor;
  final bool initiallyExpanded;
  final Duration animationDuration;

  const CustomExpansionTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.content,
    required this.leadingIcon,
    this.leadingIconColor,
    this.leadingContainerColor,
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(_expandAnimation);

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Leading square container with icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.leadingContainerColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.leadingIcon,
                    color: widget.leadingIconColor ?? Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.title,
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.grey[600],
                              ),
                          child: widget.subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                // Rotating arrow icon
                RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ),
        // Expandable content
        SizeTransition(
          axisAlignment: 1.0,
          sizeFactor: _expandAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: widget.content,
          ),
        ),
      ],
    );
  }
}