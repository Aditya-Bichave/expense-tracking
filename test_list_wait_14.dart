
import 'dart:async';

void main() async {
  final list = List.generate(14, (i) => Future.value(i));
  final results = await list.wait;
  print('results: $results');
}
