import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:developer' as devtools show log;
  
List<TextSpan> highlightOccurrences(String source, String? searchTerm, List<String>? searchList, [TextStyle? normalStyle, TextStyle? highlightStyle]) {
  assert(searchTerm != null || searchList != null, "Either searchTerm or searchList must be provided");
  // normalStyle ??= const TextStyle(color: Colors.blue);
  var exact = searchTerm != null;
  highlightStyle ??= const TextStyle(fontWeight: FontWeight.bold);
  if (source == "") return const [TextSpan(text: "")];
  if (!exact && searchList!.isEmpty) return [TextSpan(text: source, style: normalStyle)];
  
  var spans = <TextSpan>[];
  var lowerSource = source.toLowerCase();
  
  // mark all characters of the word in the charMatch map
  Map<int, bool> charMatch = source.split("").asMap().map((key, value) => MapEntry(key, false));
  if (exact) {
    var match = lowerSource == searchTerm.toLowerCase();
    return [TextSpan(text: source, style: match ? highlightStyle : normalStyle)];
  } else {
    for (var word in searchList!) {
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
    // fill in spaces between two highlighted characters
    for (var i = 1; i < source.length - 1; i++) {
      if (charMatch[i - 1] == true && charMatch[i + 1] == true && source[i] == " ") {
        charMatch[i] = true;
      }
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

int? getPrecision(double value) {
  // count the number of total digits in the amount
  int? currentPrecision;
  var str = value.toString();
  // remove trailing zeros 
  if (str.contains('.') && !str.endsWith('.0')) {
    str = str.replaceAll(RegExp(r"0+$"), "");
    str = str.replaceAll(RegExp(r"\.$"), "");
    currentPrecision = str.length;
    if (currentPrecision <= 3) currentPrecision = null;
  }
  return currentPrecision;
}

String roundDouble(double value, {int? precision}) {
  precision ??= 3;
  if (value == 0) return "0";
  if (value.isNaN) return "NaN";
  if (value.isInfinite) return "∞";
  var order = (log(value) / ln10).floor();
  if (order >= precision) {
    // if >= 1000, round to int
    return value.toInt().toString();
  } else {
    var str = value.toStringAsFixed(precision - order);
    
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

String convertToNaturalDateString(DateTime dateTime, String dateString, [DateTime? now]) {
  now ??= DateTime.now();
  
  // Convert date to natural string
  String text;
  int relativeDays = dateTime.difference(now.getDateOnly()).inDays.abs();
  
  if (relativeDays <= 7) {
    text = "${relativeDaysNatural(dateTime, now)} ($dateString)";
  } else {
    text = dateString;
  }
  return text;
}

// text should be yesterday / today / tomorrow / x days ago / in x days
String relativeDaysNatural(DateTime date, [DateTime? now]) {
  date = date.getDateOnly();
  now ??= DateTime.now();
  now = now.getDateOnly();
  int diff = (date.difference(now).inMinutes / 60.0 / 24.0).round();
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

enum YearMode {
  ifCurrent,
  ifAllCurrent,
  never,
}

List<String> conditionallyRemoveYear(dynamic localeOrContext, List<DateTime> dates, {bool showWeekDay = true, YearMode removeYear = YearMode.ifAllCurrent, DateTime? now}) {
  // var reg = RegExp(r"(\d{4})"); // match a year
  // var function = showWeekDay ? DateFormat.yMd : DateFormat.yMd;// yMEd
  String locale;
  if (localeOrContext is BuildContext) {
    locale = kIsWeb ? Localizations.localeOf(localeOrContext).toString() : Platform.localeName;
  } else {
    locale = localeOrContext;
  }
  var df = DateFormat.yMd(locale);
  // var texts = dates.map((date) => function(locale).format(date)).toList(); // format dates
  // var matches = texts.map((text) => reg.firstMatch(text)).toList();
  // var years = matches.map((match) => match?.group(1)).toList();
  List<String> texts = [];
  List<String?> years = [];
  for (var date in dates) {
    var text = df.format(date);
    texts.add(text);
    years.add(date.year.toString());
  }
  
  now ??= DateTime.now();
  var currentYear = now.year.toString();
  
  if (removeYear == YearMode.ifCurrent || removeYear == YearMode.ifAllCurrent && years.every((year) => year == currentYear)) {
    for (var i = 0; i < texts.length; i++) {
      if (removeYear == YearMode.ifCurrent && years[i] != currentYear) continue;
      
      // remove year completely and leading and trailing "/" or "-"
      texts[i] = texts[i].replaceFirst(currentYear, "");
                //  .replaceAll(RegExp(r"^[/-]"), "")
                //  .replaceAll(RegExp(r"[/-]$"), "");
      if (texts[i].startsWith("/") || texts[i].startsWith("-")) {
        texts[i] = texts[i].substring(1);
      }
      if (texts[i].endsWith("/") || texts[i].endsWith("-")) {
        texts[i] = texts[i].substring(0, texts[i].length - 1);
      }
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

class ExpressionParser {
  final String _input;
  int _pos = 0;
  late String _currentToken;

  ExpressionParser(this._input) {
    _currentToken = _nextToken();
  }

  /// Parse the full expression and return the computed value.
  double parse() {
    final value = _parseExpression();
    if (_currentToken != '') {
      throw const FormatException('Unexpected token: \$_currentToken');
    }
    return value;
  }

  /// Parse addition and subtraction.
  double _parseExpression() {
    var value = _parseTerm();
    while (_currentToken == '+' || _currentToken == '-') {
      final op = _currentToken;
      _eat(op);
      final term = _parseTerm();
      if (op == '+') {
        value += term;
      } else {
        value -= term;
      }
    }
    return value;
  }

  /// Parse multiplication and division.
  double _parseTerm() {
    var value = _parseFactor();
    while (_currentToken == '*' || _currentToken == '/') {
      final op = _currentToken;
      _eat(op);
      final factor = _parseFactor();
      if (op == '*') {
        value *= factor;
      } else {
        if (factor == 0) {
          throw UnsupportedError('Division by zero');
        }
        value /= factor;
      }
    }
    return value;
  }

  /// Parse numbers and parentheses.
  double _parseFactor() {
    if (_currentToken == '(') {
      _eat('(');
      final value = _parseExpression();
      _eat(')');
      return value;
    } else {
      return _parseNumber();
    }
  }

  /// Parse a number token into a double.
  double _parseNumber() {
    final token = _currentToken;
    final number = double.tryParse(token);
    if (number == null) {
      throw FormatException('Invalid number: $token');
    }
    _eat(token);
    return number;
  }

  /// Consume the expected token.
  void _eat(String token) {
    if (_currentToken == token) {
      _currentToken = _nextToken();
    } else {
      throw FormatException('Expected $token but found $_currentToken');
    }
  }

  /// Tokenizer: returns the next token (number, operator, parenthesis) or '' when done.
  String _nextToken() {
    // Skip whitespace
    while (_pos < _input.length && _isWhitespace(_input[_pos])) {
      _pos++;
    }
    if (_pos >= _input.length) return '';

    final char = _input[_pos];

    // Operator or parenthesis
    if ('+-*/()'.contains(char)) {
      _pos++;
      return char;
    }

    // Number (digits, optional decimal point)
    if (_isDigit(char) || char == '.') {
      final start = _pos;
      // Leading digits
      while (_pos < _input.length && _isDigit(_input[_pos])) {
        _pos++;
      }
      // Decimal point
      if (_pos < _input.length && _input[_pos] == '.') {
        _pos++;
        // Fractional digits
        while (_pos < _input.length && _isDigit(_input[_pos])) {
          _pos++;
        }
      }
      return _input.substring(start, _pos);
    }

    throw FormatException('Unexpected character: $char');
  }

  bool _isWhitespace(String ch) => ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
  bool _isDigit(String ch) => '0123456789'.contains(ch);
}

/// Utility function to evaluate an expression string.
double evaluateNumberString(String expr) {
  final parser = ExpressionParser(expr);
  return parser.parse();
}