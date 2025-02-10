import 'package:flutter/material.dart';

import '../constants/ui.dart';

enum TitlePosition {
  left,
  center,
}

class BorderBox extends StatefulWidget {
  final Color? borderColor;
  final Widget? child;
  final Widget? titleWidget;
  final String? title;
  final Color titleBgColor;
  final TitlePosition titlePosition;
  final double horizontalPadding;
  
  const BorderBox({
    super.key,
    this.borderColor,
    this.child,
    this.titleWidget,
    this.title,
    // this.titleBgColor = const Color(0xFFFAFDFB),
    this.titleBgColor = Colors.white,
    this.titlePosition = TitlePosition.center,
    this.horizontalPadding = 8 * gsf,
  });

  @override
  State<BorderBox> createState() => _BorderBoxState();
}

class _BorderBoxState extends State<BorderBox> {
  @override
  Widget build(BuildContext context) {
    var borderColor = widget.borderColor ?? const Color.fromARGB(200, 25, 82, 77);
    
    Widget? titleWidget = widget.titleWidget ?? (widget.title != null
      ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9.0 * gsf),
        child: Text(
          widget.title!,
          style: const TextStyle(
            fontSize: 16 * gsf,
          ),
        ),
      ) : null);
    
    return Stack(
      alignment: widget.titlePosition == TitlePosition.left
        ? Alignment.topLeft
        : Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(widget.horizontalPadding, titleWidget == null ? 8 : 11, widget.horizontalPadding, 0) * gsf,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15 * gsf),
              border: Border.all(
                color: borderColor,
                width: 2 * gsf,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: titleWidget == null ? 0 : 15) * gsf,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13) * gsf,
                child: widget.child,
              ),
            ),
          ),
        ),
        titleWidget == null ? const SizedBox.shrink() :
          Container(
            transform: Matrix4.translationValues(widget.titlePosition == TitlePosition.left ? 18 * gsf : 0, 0, 0),
            color: widget.titleBgColor,
            child: titleWidget,
          ),
      ],
    );
  }
}