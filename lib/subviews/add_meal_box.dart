import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utility/text_logic.dart';

// import 'dart:developer' as devtools show log;

class AddMealBox extends StatefulWidget {
  // final DateTime copyDateTime;
  
  const AddMealBox({
    // required this.copyDateTime,
    super.key,
  });

  @override
  State<AddMealBox> createState() => _AddMealBoxState();
}

class _AddMealBoxState extends State<AddMealBox> {
  late DateTime dateTime;
  late final ScrollController _scrollController;
  
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
          _buildDateTimeField(context, null, false, dateTime, updateDateTime),
          const SizedBox(height: 10),
          _buildDateTimeField(context, _scrollController, true, dateTime, updateDateTime),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Add"),
          )
        ],
      ),
    );
  }
  
  void updateDateTime(DateTime newDateTime) => setState(() => dateTime = newDateTime);
  
  Widget _buildDateTimeField(
    BuildContext context,
    ScrollController? controller,
    bool isTime,
    DateTime dateTime,
    Function(DateTime) onChanged,
  ) {
    assert(controller != null || !isTime);
    
    var label = "";
    if (isTime) {
      label = "${dateTime.hour}h";
    } else {
      label = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: false)[0]})";
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isTime) ...[
            const Text(
              "Select hour:",
              style: TextStyle(
              ),
            ),
            const SizedBox(height: 4),
          ],
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
                        InkWell(
                          onTap: () {
                            var duration = isTime ? const Duration(hours: 1) : const Duration(days: 1);
                            onChanged(dateTime.subtract(duration));
                          },
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(9, 8, 7, 8),
                            child: Icon(Icons.chevron_left),
                          ),
                        ),
                        // vertical divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            width: 1,
                            height: 10,
                            color: Colors.black.withAlpha(100),
                          ),
                        ),
                        isTime ?
                          _getTimeSelector(context, controller, dateTime, onChanged) :
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // if (isTime) {
                                //   // show time picker
                                //   showTimePicker(
                                //     context: context,
                                //     initialTime: TimeOfDay.fromDateTime(dateTime),
                                //   ).then((time) {
                                //     if (time != null) {
                                //       onChanged(DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute));
                                //     }
                                //   });
                                // }
                              },
                              child: Center(
                                child: Text(label),
                              ),
                            ),
                          ),
                        // vertical divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            width: 1,
                            height: 10,
                            color: Colors.black.withAlpha(100),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            var duration = isTime ? const Duration(hours: 1) : const Duration(days: 1);
                            onChanged(dateTime.add(duration));
                          },
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(7, 8, 9, 8),
                            child: Icon(Icons.chevron_right),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isTime) const Mark(),
            ],
          )
        ],
      ),
    );
  }
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
                return LinearGradient(
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
                  Future.delayed(const Duration(milliseconds: 500), () {
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