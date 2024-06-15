import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utility/theme.dart';
import '../utility/text_logic.dart';

// import 'dart:developer' as devtools show log;

class AddMealBox extends StatefulWidget {
  final DateTime copyDateTime;
  final Function(DateTime) onDateTimeChanged;
  
  const AddMealBox({
    required this.copyDateTime,
    required this.onDateTimeChanged,
    super.key,
  });

  @override
  State<AddMealBox> createState() => _AddMealBoxState();
}

class _AddMealBoxState extends State<AddMealBox> {
  late DateTime dateTime;
  late final FixedExtentScrollController _scrollController;
  
  @override
  void initState() {
    // dateTime = widget.copyDateTime;
    dateTime = DateTime.now();
    
    _scrollController = FixedExtentScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(dateTime.hour * 38.0);
    });
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.all(0.0),
      title: Column(
        
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 200, 200, 200),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Text("New Meal"),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: FlexColumnWidth(1),
              },
              children: [
                _buildDateTimeField(context, null, false, dateTime, updateDateTime),
                const TableRow( // spacer
                  children: [
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                  ],
                ),
                _buildDateTimeField(context, _scrollController, true, dateTime, updateDateTime),
              ]
            ),
          ),
          const SizedBox(height: 12),
          // FoodBox(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              style: addButtonStyle.copyWith(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minimumSize: WidgetStateProperty.all<Size>(const Size(0, 0)),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
                alignment: Alignment.center,
                iconSize: WidgetStateProperty.all<double>(20),
              ),
              icon: const Icon(Icons.add),
              onPressed: () {},
              label: const Text("Add Meal"),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
  
  void updateDateTime(DateTime newDateTime) {
    setState(() => dateTime = newDateTime);
  }
  
  TableRow _buildDateTimeField(
    BuildContext context,
    FixedExtentScrollController? controller,
    bool isTime,
    DateTime dateTime,
    Function(DateTime) onChanged,
  ) {
    assert(controller != null || !isTime);
    
    return TableRow(
      children: [
        isTime
          ? const Text(
            "Hour:",
            style: TextStyle(
            ),
          )
          : const Text(
            "Date:",
            style: TextStyle(
            ),
          ),
        const SizedBox(width: 12),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(top: isTime ? 2 : 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade100.withAlpha(200),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        width: 0,
                        height: 25,
                      ),
                      _getChevronButton(false, isTime, dateTime, onChanged, controller),
                      // vertical divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Container(
                          width: 1,
                          height: 8,
                          color: Colors.black.withAlpha(100),
                        ),
                      ),
                      isTime ?
                        _getTimeSelector(context, controller, dateTime, onChanged) :
                        _getDateSelector(context, dateTime, onChanged),
                      // vertical divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Container(
                          width: 1,
                          height: 8,
                          color: Colors.black.withAlpha(100),
                        ),
                      ),
                      _getChevronButton(true, isTime, dateTime, onChanged, controller),
                    ],
                  ),
                ),
              ),
            ),
            if (isTime) const Mark(),
          ],
        )
      ],
    );
  }
}

Widget _getChevronButton(bool isUp, bool isTime, DateTime dateTime, Function(DateTime) onChanged, FixedExtentScrollController? scrollController) =>
  InkWell(
    enableFeedback: !isTime,
    onTap: () {
      Duration duration = isTime ? const Duration(hours: 1) : const Duration(days: 1);
      if (isTime) {
        if ((isUp && dateTime.hour == 23) || (!isUp && dateTime.hour == 0)) {
          duration = const Duration(hours: -23);
          dateTime = isUp ? dateTime.add(duration) : dateTime.subtract(duration);
          scrollController?.jumpToItem(isUp ? 0 : 23);
        } else {
          duration = isUp ? const Duration(hours: 1) : const Duration(hours: -1);
          var newDateTime = dateTime.add(duration);
          Future.delayed(const Duration(milliseconds: 400), () {
            // dateTime = newDateTime;
          });
          scrollController?.animateToItem(newDateTime.hour, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
        }
      } else {
        duration = isUp ? const Duration(days: 1) : const Duration(days: -1);
        dateTime = dateTime.add(duration);
      }
      onChanged(dateTime);
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(7, 8, 9, 8),
      child: Icon(isUp ? Icons.chevron_right : Icons.chevron_left),
    ),
  );

Widget _getDateSelector(BuildContext context, DateTime dateTime, Function(DateTime) onChanged) {
  var label = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: false)[0]})";
  
  return Expanded(
    child: InkWell(
      onTap: () {
        showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        ).then((newDateTime) {
          if (newDateTime != null) {
            onChanged(newDateTime);
          }
        });
      },
      child: Center(
        child: Text(label),
      ),
    ),
  );
}

Widget _getTimeSelector(
  BuildContext context,
  ScrollController? controller,
  DateTime dateTime,
  Function(DateTime) onChanged,
) {
  var selectedHour = dateTime.hour;
  
    return Expanded(
    child: Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: RotatedBox(
        quarterTurns: -1,
        child: Stack(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                  stops: [0.02, 0.12, 0.88, 0.98],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 38.0,
                diameterRatio: 5.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    SystemSound.play(SystemSoundType.click);
                  });
                  var newDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, index, dateTime.minute);
                  onChanged(newDateTime);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    var hour = (index % 24).toString();
                    var selected = index == selectedHour;
                    return RotatedBox(
                      quarterTurns: 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Center(
                          child: Text(
                            hour,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.black.withAlpha(150),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

}

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

class Mark extends StatelessWidget {
  const Mark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 9,
      child: CustomPaint(
        painter: TrianglePainter(const Color.fromARGB(255, 69, 139, 128)),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  // specify color in constructor
  Color color;
  
  TrianglePainter(this.color) : super();
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}