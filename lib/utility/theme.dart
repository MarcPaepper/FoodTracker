import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../constants/ui.dart';

const appBarHeight = 50 * gsf;

const tabColorActive = Color.fromARGB(255, 193, 255, 253);
const warningColor = Color.fromARGB(255, 255, 174, 0);

const errorBorderColor = Color.fromARGB(255, 230, 0, 0);
const disabledBorderColor = Color.fromARGB(130, 158, 158, 158);

const tsNormal = TextStyle(fontSize: 16 * gsf);

var actionButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(163, 33, 197, 181)),
  foregroundColor: WidgetStateProperty.all(Colors.white),
  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16 * gsf)),
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 12) * gsf),
  shape: WidgetStateProperty.all(const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12 * gsf)),
  )),
);

var lightButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.teal.shade100.withOpacity(0.6),
  shadowColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10 * gsf)),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: kIsWeb ? 16 : 12) * gsf,
);

ThemeData getTheme() =>
  ThemeData(
    // set default text font size to 16
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16 * gsf),
      bodyMedium: TextStyle(fontSize: 16 * gsf),
      bodySmall: TextStyle(fontSize: 16 * gsf),
      labelMedium: TextStyle(fontSize: 16 * gsf),
    ),
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
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      labelStyle: const TextStyle(
        fontSize: 16.5 * gsf,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16.5 * gsf,
      ),
      unselectedLabelColor: Colors.white.withAlpha(150),
      indicator: const CustomUnderlineTabIndicator(
        borderSide: BorderSide(
          width: 3 * gsf,
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
        borderRadius: BorderRadius.circular(10.0 * gsf),
        borderSide: const BorderSide(
          width: 2.0 * gsf,
          color: Colors.grey
        )
      ),
      disabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0 * gsf),
        borderSide: BorderSide(
          width: 2.0 * gsf,
          color: Colors.grey.shade300
        )
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0 * gsf),
        borderSide: BorderSide(
          width: 2.0 * gsf,
          color: Colors.teal.shade300
        )
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0 * gsf),
        borderSide: const BorderSide(
          width: 2.0,
          color: Color.fromARGB(210, 193, 46, 27)
        )
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(10.0 * gsf),
        borderSide: BorderSide(
          width: 2.0 * gsf,
          color: Colors.red.shade500
        )
      ),
    ),
    dialogTheme: const DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14 * gsf)),
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
  minimumSize: const Size(double.infinity, 49 * gsf),
  alignment: Alignment.centerLeft,
  padding: const EdgeInsets.symmetric(horizontal: 16 * gsf, vertical: 0),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  textStyle: const TextStyle(fontSize: 16 * gsf),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

var dropdownStyleEnabled = const InputDecoration(
  // contentPadding: EdgeInsets.symmetric(vertical: kIsWeb ? (19 * gsf - 6) : (9 * gsf), horizontal: 14 * gsf),
  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 14 * gsf),
);

var dropdownStyleDisabled = InputDecoration(
  contentPadding: const EdgeInsets.symmetric(vertical: kIsWeb ? (19 * gsf - 6) : (9 * gsf), horizontal: 14 * gsf),
  // no enabled border
  enabledBorder: UnderlineInputBorder(
    borderRadius: BorderRadius.circular(10.0) * gsf,
    borderSide: BorderSide(
      width: 3.5 * gsf,
      color: Colors.grey.shade300
    )
  ),
);

var importantButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.all(Colors.teal.shade400),
  foregroundColor: WidgetStateProperty.all(Colors.white),
  minimumSize: WidgetStateProperty.all(const Size(double.infinity, 60 * gsf)),
  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16 * gsf)),
  shape: WidgetStateProperty.all(const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14 * gsf)),
  )),
);
  
List<Color> productColors = [
  Colors.red,      // red
  Colors.orange,   // orange
  const Color.fromARGB(255, 247, 222, 0),   // yellow
  const Color.fromARGB(255, 22, 190, 0),    // green
  const Color.fromARGB(255, 0, 225, 255), 		// cyan
  const Color.fromARGB(255, 40, 0, 255),	  // indigo
  const Color.fromARGB(255, 217, 0, 255),	  // purple
];

class MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}