
import 'dart:async';

void main() async {
  final list = [Future.value(1), Future.value('a')];
  final results = await list.wait;
  print('results: $results');
  print('type: ${results.runtimeType}');
}
