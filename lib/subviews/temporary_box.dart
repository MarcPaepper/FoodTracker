
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../utility/data_logic.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';
import '../widgets/border_box.dart';

// import 'dart:developer' as devtools show log;

class TemporaryBox extends StatelessWidget {
  final ValueNotifier<bool> isTemporaryNotifier;
  final ValueNotifier<DateTime?> beginningNotifier;
  final ValueNotifier<DateTime?> endNotifier;
  
  final Function() intermediateSave;
  
  final List<Meal> meals;
  final int productId;
  
  const TemporaryBox({
    required this.isTemporaryNotifier,
    required this.beginningNotifier,
    required this.endNotifier,
    required this.intermediateSave,
    required this.meals,
    required this.productId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        isTemporaryNotifier,
        beginningNotifier,
        endNotifier,
      ],
      builder: (context, values, child) {
        var isTemporary = values[0] as bool;
        var beginning   = values[1] as DateTime?;
        var end         = values[2] as DateTime?;
        
        if (isTemporary && (beginning == null || end == null)) {
          beginning = DateTime.now().getDateOnly();
          end = DateTime.now().add(const Duration(days: 6, hours: 23, minutes: 59));
          
          // test if there are meals using this product outside the interval
          for (var meal in meals) {
            if (productId < 0 || meal.productQuantity.productId != productId) continue;
            
            var dt = meal.dateTime.getDateOnly();
            if (dt.isBefore(beginning!)) {
              beginning = dt;
            }
            if (dt.isAfter(end!)) {
              end = dt;
            }
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            beginningNotifier.value = beginning;
            endNotifier.value = end;
            intermediateSave();
          });
        }
        
        var textAlpha = isTemporary ? 255 : 100;
        String? validationString = isTemporary ? validateTemporaryInterval(beginning, end) : null;
        Color? borderColor;
        if (isTemporary) {
          borderColor = validationString == null ? null : errorBorderColor;
        } else {
          borderColor = disabledBorderColor;
        }
        
        const textStyle = TextStyle(
          fontSize: 16 * gsf,
          color: Colors.black,
          fontWeight: FontWeight.normal,
        );
        
        var beginningText = "";
        var endText = "";
        var beginningTextNat = "";
        var endTextNat = "";
        
        if (isTemporary) {
          var texts = conditionallyRemoveYear(context, [beginning!, end!]);
          beginningText = texts[0];
          endText = texts[1];
          
          beginningTextNat = isTemporary ? relativeDaysNatural(beginning) : "";
          endTextNat       = isTemporary ? relativeDaysNatural(end)       : "";
        }
        
        return BorderBox(
          borderColor: borderColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 6, 12, isTemporary ? 14 : 0) * gsf,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  visualDensity: VisualDensity.compact,
                  value: isTemporary,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    isTemporaryNotifier.value = value;
                    intermediateSave();
                  },
                  title: Padding(
                    padding: const EdgeInsets.only(top: 2) * gsf,
                    child: Text(
                      "Temporary",
                      style: TextStyle(
                        color: Colors.black.withAlpha(((textAlpha + 255) / 2).round()),
                        fontSize: 16 * gsf,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (isTemporary ? 8 : 6) * gsf),
                // Single button to show a date range picker
                if (isTemporary)
                  Padding(
                    padding: const EdgeInsets.only(left: 12) * gsf,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade50,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14 * gsf)),
                        ),
                        padding: const EdgeInsets.fromLTRB(8 * gsf, 12 * gsf - 6, 0, 12 * gsf - 6),
                      ),
                      onPressed: () async {
                        var range = await showDateRangePicker(
                          context: context,
                          locale: PlatformDispatcher.instance.locale,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: DateTimeRange(
                            start: beginning!,
                            end: end!,
                          ),
                        );
                        if (range != null) {
                          beginningNotifier.value = range.start;
                          endNotifier.value = range.end;
                          intermediateSave();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8) * gsf,
                            child: const Icon(
                              Icons.edit_calendar,
                              size: 28 * gsf,
                            ),
                          ),
                          const Spacer(),
                          UnconstrainedBox(
                            child: Table(
                              // make the table as small as possible
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: IntrinsicColumnWidth(),
                                2: IntrinsicColumnWidth(),
                                3: IntrinsicColumnWidth(),
                                4: IntrinsicColumnWidth(),
                              },
                              children: [
                                TableRow(
                                  children: [
                                    const SizedBox(width: 0),
                                    const SizedBox(width: 10 * gsf),
                                    Text(
                                      beginningText,
                                      style: textStyle,
                                    ),
                                    const SizedBox(width: 14 * gsf),
                                    Text(
                                      "($beginningTextNat)",
                                      style: textStyle.copyWith(
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const Text(
                                      "-",
                                      style: textStyle,
                                    ),
                                    const SizedBox(width: 10 * gsf),
                                    Text(
                                      endText,
                                      style: textStyle,
                                    ),
                                    const SizedBox(width: 14 * gsf),
                                    Text(
                                      "($endTextNat)",
                                      style: textStyle.copyWith(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}