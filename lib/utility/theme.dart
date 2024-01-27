import 'package:flutter/material.dart';

const tabColorActive = Color.fromARGB(255, 193, 255, 253);

ThemeData getTheme() =>
  ThemeData(
    colorSchemeSeed: Colors.teal,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade400,
      foregroundColor: Colors.white,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      labelStyle: const TextStyle(
        fontSize: 16.5,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16.5,
      ),
      unselectedLabelColor: Colors.white.withAlpha(150),
      indicator: const CustomUnderlineTabIndicator(
        borderSide: BorderSide(
          width: 3,
          color: Colors.white
        )
      ),
      // bright press and hover color
      overlayColor: MaterialStateColor.resolveWith((Set<MaterialState> states) =>
        states.contains(MaterialState.pressed) ?
          Colors.white.withAlpha(50) :
          Colors.white.withAlpha(20)
      ),
    ),
    // textTheme: const TextTheme(
    //   bodySmall: TextStyle(color: Colors.black),
    //   bodyMedium: TextStyle(color: Colors.black),
    //   bodyLarge: TextStyle(color: Colors.black),
    //   displayLarge: TextStyle(color: Colors.black),
    //   displayMedium: TextStyle(color: Colors.black),
    //   displaySmall: TextStyle(color: Colors.black),
    //   headlineLarge: TextStyle(color: Colors.black),
    //   headlineMedium: TextStyle(color: Colors.black),
    //   headlineSmall: TextStyle(color: Colors.black),
    //   labelLarge: TextStyle(color: Colors.black),
    //   labelMedium: TextStyle(color: Colors.black),
    //   labelSmall: TextStyle(color: Colors.black),
    // ).apply(
    //   bodyColor: Colors.black,
    //   displayColor: Colors.black,
    // ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: MaterialStateColor.resolveWith((Set<MaterialState> states) =>
        states.contains(MaterialState.error) ?
          const Color.fromARGB(34, 255, 111, 0) :
          Colors.grey.withAlpha(35)
      ),
      enabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          width: 3.5,
          color: Colors.grey
        )
      ),
      disabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 3.5,
          color: Colors.grey.shade300
        )
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 3.5,
          color: Colors.teal.shade300
        )
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          width: 3.5,
          color: Color.fromARGB(210, 193, 46, 27)
        )
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 4,
          color: Colors.red.shade500
        )
      ),
    ),
  );

class CustomUnderlineTabIndicator extends UnderlineTabIndicator {
  const CustomUnderlineTabIndicator({required BorderSide borderSide})
      : super(borderSide: borderSide);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomUnderlinePainter(this, onChanged);
  }
  
  
}

class _CustomUnderlinePainter extends BoxPainter {
  _CustomUnderlinePainter(this.decoration, VoidCallback? onChanged)
      : super(onChanged);

  final CustomUnderlineTabIndicator decoration;

  BorderSide get borderSide => decoration.borderSide;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = Offset(offset.dx,
            (configuration.size!.height - decoration.borderSide.width) - 5) &
        Size(configuration.size!.width, decoration.borderSide.width);
    final Paint paint = decoration.borderSide.toPaint()
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(rect.topLeft, rect.topRight, paint);
  }
}