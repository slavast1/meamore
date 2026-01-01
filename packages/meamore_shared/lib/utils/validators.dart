class Validators {
  static bool isDigitsOnly(String s) => RegExp(r'^\d+$').hasMatch(s);
}
