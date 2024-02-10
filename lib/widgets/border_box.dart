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
    // default values
    var borderColor = widget.borderColor ?? const Color.fromARGB(200, 25, 82, 77);
    
    var titleWidget = widget.title != null
      ? Text(
        widget.title!,
        style: const TextStyle(
          fontSize: 16,
        ),
      ) : null;
    
    // If the title is null, just use the widget.child as the container child
    // If the title is not null, use a Column as the container child

    late final Widget child;
    if (widget.title == null) {
      child = widget.child!;
    } else {
      child = Column(
        crossAxisAlignment: widget.titlePosition == TitlePosition.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
        children: [
          Container(
            transform: Matrix4.translationValues(
              widget.titlePosition == TitlePosition.left
                ? 18
                : 0,
              -13,
              0,
            ),
            // background color
            color: widget.titleBgColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.0),
              child: titleWidget!
            )
          ),
          Container(
            transform: widget.title == null ? null : Matrix4.translationValues(0, -8, 0),
            child: widget.child!,
          )
        ],
      );
    }
    
    return Padding(
      padding: EdgeInsets.fromLTRB(8, widget.title == null ? 8 : 11, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0), //15
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}