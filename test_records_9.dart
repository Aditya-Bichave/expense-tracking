
void main() async {
  final (a, b, c, d, e, f, g, h, i) = await (
    Future.value(1),
    Future.value(2),
    Future.value(3),
    Future.value(4),
    Future.value(5),
    Future.value(6),
    Future.value(7),
    Future.value(8),
    Future.value(9),
  ).wait;
  print('done 9');
}
