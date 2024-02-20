// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';

//import "dart:developer" as devtools show log;

class SlidableList extends StatefulWidget {
  final List<SlidableListEntry> entries;
  final double menuWidth;
  
  const SlidableList({
    required this.entries,
    required this.menuWidth,
    Key? key
  }) : super(key: key);

  @override
  State<SlidableList> createState() => _SlidableListState();
}

class _SlidableListState extends State<SlidableList> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: List.generate(widget.entries.length, (index) {
        var entry = widget.entries[index];
        var menuItems = entry.menuItems;
        var child = entry.child;
        
        return SlideMenu(
          menuItems: menuItems,
          menuWidth: widget.menuWidth,
          child: child,
        );
      }).toList(),
    );
  }
}

class SlidableReorderableList extends StatefulWidget {
  final List<SlidableListEntry> entries;
  final double menuWidth;
  final bool buildDefaultDragHandles;
  final void Function(int oldIndex, int newIndex) onReorder;
  
  const SlidableReorderableList({
    required key,
    required this.entries,
    required this.menuWidth,
    this.buildDefaultDragHandles = true,
    required this.onReorder,
  }) : super(key: key);

  @override
  State<SlidableReorderableList> createState() => _SlidableReorderableListState();
}

class _SlidableReorderableListState extends State<SlidableReorderableList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      clipBehavior: Clip.antiAlias,
      shrinkWrap: true,
      buildDefaultDragHandles: widget.buildDefaultDragHandles,
      onReorder: widget.onReorder,
      children: List.generate(widget.entries.length, (index) {
        var entry = widget.entries[index];
        var menuItems = entry.menuItems;
        var child = entry.child;
        var key = entry.key;
        
        return SlideMenu(
          key: key,
          menuItems: menuItems,
          menuWidth: widget.menuWidth,
          child: child,
        );
      }).toList(),
    );
  }
}

class SlideMenu extends StatefulWidget {
  final List<Widget> menuItems;
  final double menuWidth;
  final Widget child;

  const SlideMenu({Key? key,
    required this.menuWidth,
    required this.menuItems,
    required this.child,
  }) : super(key: key);

  @override
  State<SlideMenu> createState() => _SlideMenuState();
}

class _SlideMenuState extends State<SlideMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      //Here the end field will determine the size of buttons which will appear after sliding
      //If you need to appear them at the beginning, you need to change to "+" Offset coordinates (0.2, 0.0)
      double maxSlide = widget.menuWidth / constraint.maxWidth;
      
      final animation =
      Tween(begin: const Offset(0.0, 0.0),
          end: Offset(-maxSlide, 0.0)) // -0.2
          .animate(CurveTween(curve: Curves.decelerate).animate(_controller));

      return GestureDetector(
        onHorizontalDragUpdate: (data) {
          // we can access context.size here
          setState(() {
            //Here we set value of Animation controller depending on our finger move in horizontal axis
            //If you want to slide to the right, change "-" to "+"
            _controller.value -= (data.primaryDelta! / (context.size!.width*maxSlide));//(data.primaryDelta! / widget.menuWidth);
          });
        },
        onHorizontalDragEnd: (data) {
          //To change slide direction, change to data.primaryVelocity! < -1500
          if (data.primaryVelocity! > 1500)
            _controller.animateTo(.0); //close menu on fast swipe in the right direction
          //To change slide direction, change to data.primaryVelocity! > 1500
          else if (_controller.value >= .5 || data.primaryVelocity! < -1500)
            _controller.animateTo(1.0); // fully open if dragged a lot to left or on fast swipe to left
          else // close if none of above
            _controller.animateTo(.0);
        },
        child: Stack(
          children: [
            SlideTransition(
              position: animation,
              child: widget.child,
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                //To change slide direction to right, replace the right parameter with left:
                return Positioned(
                  right: .0,
                  top: .0,
                  bottom: 0.0,
                  width: animation.value.dx * -1 * constraint.maxWidth, // * widget.menuWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.menuItems.map((child) {
                      return Expanded(
                        child: child,
                      );
                    }).toList(),
                  ),
                );
              }
            )
          ],
        )
      );
    });
  }
}

class SlidableListEntry {
  final Widget child;
  final List<Widget> menuItems;
  final Key key;
  
  SlidableListEntry({
    required this.child,
    required this.menuItems,
    required this.key,
  });
}