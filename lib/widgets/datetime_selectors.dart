import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utility/text_logic.dart';

// import 'dart:developer' as devtools show log;

class DateAndTimeTable extends StatefulWidget {
  final ValueNotifier<DateTime> dateTimeNotifier;
  final Function(DateTime) updateDateTime;
  final FixedExtentScrollController? scrollController;
  
  const DateAndTimeTable({
    required this.dateTimeNotifier,
    required this.updateDateTime,
             this.scrollController,
    super.key,
  });

  @override
  State<DateAndTimeTable> createState() => _DateAndTimeTableState();
}

class _DateAndTimeTableState extends State<DateAndTimeTable> {
  late final FixedExtentScrollController _scrollController;
  
  @override
  void initState() {
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = FixedExtentScrollController();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(widget.dateTimeNotifier.value.hour * 38.0);
    });
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(1),
      },
      children: [
        getDateTimeField(context, null, false, widget.dateTimeNotifier, widget.updateDateTime),
        const TableRow( // spacer
          children: [
            SizedBox(height: 10),
            SizedBox(height: 10),
            SizedBox(height: 10),
          ],
        ),
        getDateTimeField(context, _scrollController, true, widget.dateTimeNotifier, widget.updateDateTime),
      ]
    );
  }
}
  
TableRow getDateTimeField(
  BuildContext context,
  FixedExtentScrollController? controller,
  bool isTime,
  ValueNotifier<DateTime> dateTimeNotifier,
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
              child: ValueListenableBuilder(
                valueListenable: dateTimeNotifier,
                builder: (context, dateTime, child) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 0,
                          height: 25,
                        ),
                        _buildChevronButton(false, isTime, dateTime, onChanged, controller),
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
                          TimeSelector(controller, dateTime, onChanged) :
                          DateSelector(dateTime, onChanged),
                        // vertical divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Container(
                            width: 1,
                            height: 8,
                            color: Colors.black.withAlpha(100),
                          ),
                        ),
                        _buildChevronButton(true, isTime, dateTime, onChanged, controller),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (isTime) const Mark(),
        ],
      )
    ],
  );
}

class TimeSelector extends StatefulWidget {
  final FixedExtentScrollController? controller;
  final DateTime startTime;
  final Function(DateTime) onChanged;
  
  const TimeSelector(
    this.controller,
    this.startTime,
    this.onChanged,
    {super.key}
  );

  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> {
  @override
  Widget build(BuildContext context) {
    var dateTime = widget.startTime;
    var selectedHour = widget.startTime.hour;
  
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
                  controller: widget.controller,
                  scrollBehavior: MouseDragScrollBehavior().copyWith(scrollbars: false),
                  itemExtent: 38.0,
                  diameterRatio: 5.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      SystemSound.play(SystemSoundType.click); // not working
                    });
                    var newDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, index, dateTime.minute);
                    widget.onChanged(newDateTime);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      var hour = (index % 24).toString();
                      var selected = index == selectedHour;
                      return InkWell(
                        mouseCursor: SystemMouseCursors.basic,
                        onTap: () {
                          var time = (sqrt((index - selectedHour).abs()) * 150).round();
                          widget.controller?.animateToItem(index, duration: Duration(milliseconds: time), curve: Curves.easeInOut);
                          var newDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, index, dateTime.minute);
                          widget.onChanged(newDateTime);
                        },
                        child: RotatedBox(
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

class DateSelector extends StatefulWidget {
  final DateTime dateTime;
  final Function(DateTime) onChanged;
  
  const DateSelector(
    this.dateTime,
    this.onChanged,
    {super.key}
  );

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  @override
  Widget build(BuildContext context) {
    var label = "${relativeDaysNatural(widget.dateTime)} (${conditionallyRemoveYear(context, [widget.dateTime], showWeekDay: false)[0]})";
    
    return Expanded(
      child: InkWell(
        onTap: () {
          showDatePicker(
            context: context,
            initialDate: widget.dateTime,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ).then((nDT) {
            if (nDT != null) {
              nDT = DateTime(nDT.year, nDT.month, nDT.day, widget.dateTime.hour);
              widget.onChanged(nDT);
            }
          });
        },
        child: Center(
          child: Text(label),
        ),
      ),
    );
  }
}

Widget _buildChevronButton(bool isUp, bool isTime, DateTime dateTime, Function(DateTime) onChanged, FixedExtentScrollController? scrollController) =>
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
      padding: const EdgeInsets.fromLTRB(7, 9, 9, 9),
      child: Icon(isUp ? Icons.chevron_right : Icons.chevron_left),
    ),
  );