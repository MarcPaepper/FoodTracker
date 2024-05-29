import 'package:flutter/material.dart';
import 'package:food_tracker/utility/text_logic.dart';

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
  
  @override
  void initState() {
    // dateTime = widget.copyDateTime;
    dateTime = DateTime.now();
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
          _buildDateTimeField(context, false, dateTime, updateDateTime),
          const SizedBox(height: 12),
          _buildDateTimeField(context, true, dateTime, updateDateTime),
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
    bool isTime,
    DateTime dateTime,
    Function(DateTime) onChanged,
  ) {
    var label = "";
    if (isTime) {
      label = "${dateTime.hour}h";
    } else {
      label = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: false)[0]})";
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade100.withAlpha(200),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Container(
                    width: 1,
                    height: 25,
                    color: Colors.black.withAlpha(100),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (isTime) {
                          // show time picker
                          showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dateTime),
                          ).then((time) {
                            if (time != null) {
                              onChanged(DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute));
                            }
                          });
                        }
                      },
                      child: Center(
                        child: Text(label),
                      ),
                    ),
                  ),
                  // vertical divider
                  Container(
                    width: 1,
                    height: 25,
                    color: Colors.black.withAlpha(100),
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
        )
      ],
    );
  }
}