import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const tabColorActive = Color.fromARGB(255, 193, 255, 253);
const warningColor = Color.fromARGB(255, 255, 174, 0);

const errorBorderColor = Color.fromARGB(255, 230, 0, 0);
const disabledBorderColor = Color.fromARGB(130, 158, 158, 158);

var actionButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(163, 33, 197, 181)),
  foregroundColor: WidgetStateProperty.all(Colors.white),
  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16)),
  shape: WidgetStateProperty.all(const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  )),
);

var lightButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.teal.shade100.withOpacity(0.6),
  shadowColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: kIsWeb ? 16 : 12),
);

ThemeData getTheme() =>
  ThemeData(
    // red popup menu button
    popupMenuTheme: const PopupMenuThemeData(
      // from hex
      color: Color.fromARGB(249, 242, 255, 250),
      surfaceTintColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
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
      overlayColor: WidgetStateColor.resolveWith((Set<WidgetState> states) =>
        states.contains(WidgetState.pressed) ?
          Colors.white.withAlpha(50) :
          Colors.white.withAlpha(20)
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) =>
        states.contains(WidgetState.error) ?
          const Color.fromARGB(34, 255, 111, 0) :
          Colors.grey.withAlpha(35)
      ),
      enabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          width: 2.0,
          color: Colors.grey
        )
      ),
      disabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 2.0,
          color: Colors.grey.shade300
        )
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 2.0,
          color: Colors.teal.shade300
        )
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          width: 2.0,
          color: Color.fromARGB(210, 193, 46, 27)
        )
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          width: 2.0,
          color: Colors.red.shade500
        )
      ),
    ),
    dialogTheme: const DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
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

var addButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color.fromARGB(255, 210, 235, 198),
  foregroundColor: Colors.black,
  minimumSize: const Size(double.infinity, 49),
  alignment: Alignment.centerLeft,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  textStyle: const TextStyle(fontSize: 16),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);