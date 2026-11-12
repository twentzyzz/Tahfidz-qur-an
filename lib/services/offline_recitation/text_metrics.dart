int editDistance<T>(List<T> reference, List<T> hypothesis) {
  var previous = List.generate(hypothesis.length + 1, (i) => i);
  for (var i = 1; i <= reference.length; i++) {
    final current = List<int>.filled(hypothesis.length + 1, 0)..[0] = i;
    for (var j = 1; j <= hypothesis.length; j++) {
      final options = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + (reference[i - 1] == hypothesis[j - 1] ? 0 : 1),
      ]..sort();
      current[j] = options.first;
    }
    previous = current;
  }
  return previous.last;
}
