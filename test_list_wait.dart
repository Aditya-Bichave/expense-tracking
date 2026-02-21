
import 'dart:async';

void main() async {
  final list = [Future.value(1), Future.value(2)];
  final results = await list.wait;
  print('results: $results');
}
