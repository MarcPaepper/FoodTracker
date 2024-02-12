import 'package:flutter/material.dart';

enum TitlePosition {
  left,
  center,
}

class BorderBox extends StatefulWidget {
  final Color? borderColor;
  final Widget? child;
  final String? title;
  final TitlePosition titlePosition;
  final Color titleBgColor;
  
  const BorderBox({
    super.key,
    this.borderColor,
    this.child,
    this.title,
    this.titleBgColor = const Color(0xFFFAFDFB),
    this.titlePosition = TitlePosition.center,
  });

  @override
  State<BorderBox> createState() => _BorderBoxState();
}

class _BorderBoxState extends State<BorderBox> {
  
  
  @override
  Widget build(BuildContext context) {
    var borderColor = widget.borderColor ?? const Color.fromARGB(200, 25, 82, 77);
    
    var titleWidget = widget.title != null
      ? Text(
        widget.title!,
        style: const TextStyle(
          fontSize: 16,
        ),
      ) : const SizedBox.shrink();
    
    return Stack(
      alignment: widget.titlePosition == TitlePosition.left
        ? Alignment.topLeft
        : Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, widget.title == null ? 8 : 11, 8, 0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: widget.title == null ? 0 : 17),
              child: widget.child,
            ),
          ),
        ),
        widget.title == null ? const SizedBox.shrink() :
          Container(
            transform: Matrix4.translationValues(widget.titlePosition == TitlePosition.left ? 18 : 0, 0, 0),
            color: widget.titleBgColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9.0),
              child: titleWidget,
            )
          ),
      ],
    );
  }
}