import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:developer' as devtools show log;
  
List<TextSpan> highlightOccurrences(String source, List<String> search, [TextStyle? normalStyle, TextStyle? highlightStyle]) {
  // normalStyle ??= const TextStyle(color: Colors.blue);
  highlightStyle ??= const TextStyle(fontWeight: FontWeight.bold);
  if (source == "") return const [TextSpan(text: "")];
  if (search.isEmpty) return [TextSpan(text: source, style: normalStyle)];
  
  var spans = <TextSpan>[];
  var lowerSource = source.toLowerCase();
  
  // mark all characters of the word in the charMatch map
  Map<int, bool> charMatch = source.split("").asMap().map((key, value) => MapEntry(key, false));
  for (var word in search) {
    if (word == "") {
      devtools.log("Empty search word");
      continue;
    }
    var lowerWord = word.toLowerCase();
    int startIndex = 0;
    int safetyCounter = 0;
    do {
      var subSrc = lowerSource.substring(startIndex);
      var wordIndex = subSrc.indexOf(lowerWord, 0);
      if (wordIndex == -1) {
        break;
      }
      for (var i = wordIndex + startIndex; i < wordIndex + startIndex + word.length; i++) {
        charMatch[i] = true;
      }
      startIndex += wordIndex + word.length;
      safetyCounter++;
      if (safetyCounter > 127) {
        devtools.log("Safety Counter exceeded when highlighting");
        break;
      }
    } while (startIndex < lowerSource.length);
  }
  
  // split the source string into normal and highlighted parts
  
  String? currentNormal;
  String? currentHighlight;
  
  for (var i = 0; i < source.length; i++) {
    if (charMatch[i] == true) {
      if (currentNormal != null) {
        spans.add(TextSpan(text: currentNormal, style: normalStyle));
        currentNormal = null;
      }
      currentHighlight = (currentHighlight ?? "") + source[i];
    } else {
      if (currentHighlight != null) {
        spans.add(TextSpan(text: currentHighlight, style: highlightStyle));
        currentHighlight = null;
      }
      currentNormal = (currentNormal ?? "") + source[i];
    }
  }
  if (currentNormal != null) {
    spans.add(TextSpan(text: currentNormal, style: normalStyle));
  }
  if (currentHighlight != null) {
    spans.add(TextSpan(text: currentHighlight, style: highlightStyle));
  }
  
  return spans;
}

// convert a double or int to double
double toDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else {
    // throw ArgumentError("Value is not a number, type is ${value.runtimeType}");
    return double.nan;
  }
}

String? numberValidator(String? value, {bool canBeEmpty = false}) {
  if (value == null || (!canBeEmpty && value.isEmpty)) {
    return "Required Field";
  }
  if (canBeEmpty && value.isEmpty) {
    return null;
  }
  try {
    double.parse(value);
  } catch (e) {
    return "Invalid Number";
  }
  return null;
}

String roundDouble(double value) {
  if (value == 0) return "0";
  if (value.isNaN) return "NaN";
  if (value.isInfinite) return "∞";
  var order = (log(value) / ln10).floor();
  if (order >= 3) {
    return value.toInt().toString();
  } else {
    var str = value.toStringAsFixed(3 - order);
    
    // delete decimal point if only zeros follow
    str = str.replaceAll(RegExp(r"\.0+$"), "");
    
    // delete trailing zeros after a number
    var regex = RegExp(r"^(.*\.\d*[1-9])0+$");
    return regex.hasMatch(str) ? regex.firstMatch(str)!.group(1)! : str;
  }
}

String _truncateZeros(String text) {
  if (text.endsWith(".0")) {
    return text.substring(0, text.length - 2);
  }
  return text;
}

String truncateZeros(dynamic number) => _truncateZeros(number.toString());

// text should be yesterday / today / tomorrow / x days ago / in x days
String relativeDaysNatural(DateTime date) {
  date = date.getDateOnly();
  // Select beginning of current day
  var now = DateTime.now().getDateOnly();
  var diff = date.difference(now).inDays;
  if (diff == 0) {
    return "Today";
  } else if (diff == 1) {
    return "Tomorrow";
  } else if (diff == -1) {
    return "Yesterday";
  } else if (diff > 0) {
    return "in $diff days";
  } else {
    return "${-diff} days ago";
  }
}

String relativeWeeksNatural(DateTime date) {
  date = date.getDateOnly();
  // Select beginning of current day
  var now = DateTime.now().getDateOnly();
  // set monday of now week
  now = now.subtract(Duration(days: now.weekday - 1));
  var diff = date.difference(now).inDays;
  var weeks = (diff / 7.0).round();
  if (weeks == 0) {
    return "This week";
  } else if (weeks == 1) {
    return "Next week";
  } else if (weeks == -1) {
    return "Last week";
  } else if (weeks > 0) {
    return "in $weeks weeks";
  } else {
    return "${-weeks} weeks ago";
  }
}

extension MyDateExtension on DateTime {
  DateTime getDateOnly(){
    return DateTime(year, month, day);
  }
}

List<String> conditionallyRemoveYear(BuildContext context, List<DateTime> dates, {bool showWeekDay = true, bool removeYear = true}) {
  var reg = RegExp(r"(\d{4})"); // match a year
  var function = showWeekDay ? DateFormat.yMd : DateFormat.yMd;// yMEd
  String locale = kIsWeb ? Localizations.localeOf(context).toString() : Platform.localeName;
  var texts = dates.map((date) => function(locale).format(date)).toList(); // format dates
  var matches = texts.map((text) => reg.firstMatch(text)).toList();
  var years = matches.map((match) => match?.group(1)).toList();
  var currentYear = DateTime.now().year.toString();
  
  if (removeYear && years.every((year) => year == currentYear)) {
    for (var i = 0; i < texts.length; i++) {
      // remove year completely and leading and trailing "/" or "-"
      texts[i] = texts[i].replaceFirst(currentYear, "")
                 .replaceAll(RegExp(r"^[/-]"), "")
                 .replaceAll(RegExp(r"[/-]$"), "");
    }
  } else {
    // replace year with last two digits
    texts = texts.map((text) => text.replaceFirst(currentYear, currentYear.substring(2))).toList();
  }
  
  if (showWeekDay) {
    // dont use the abbreviated weekday, but the full one
    var weekDayFunction = DateFormat("EEEE");
    for (var i = 0; i < texts.length; i++) {
      var weekDay = weekDayFunction.format(dates[i]);
      texts[i] = "$weekDay, ${texts[i]}";
    }
  }
  return texts;
}