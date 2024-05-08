import 'dart:math';

import 'package:flutter/material.dart';

// import 'dart:developer' as devtools show log;
  
List<TextSpan> highlightOccurrences(String source, List<String> search) {
  var spans = <TextSpan>[];
  var lowerSource = source.toLowerCase();
  var index = 0;
  for (var word in search) {
    var lowerWord = word.toLowerCase();
    var wordIndex = lowerSource.indexOf(lowerWord, index);
    if (wordIndex == -1) {
      continue;
    }
    spans.add(TextSpan(
      text: source.substring(index, wordIndex),
    ));
    spans.add(TextSpan(
      text: source.substring(wordIndex, wordIndex + word.length),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    index = wordIndex + word.length;
  }
  spans.add(TextSpan(
    text: source.substring(index),
  ));
  return spans;
}

// convert a double or int to double
double toDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else {
    throw ArgumentError("Value is not a number");
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

String truncateZeros(double number) => _truncateZeros(number.toString());