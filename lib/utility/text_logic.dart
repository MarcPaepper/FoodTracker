import 'package:flutter/material.dart';
  
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