import 'package:flutter/material.dart';

abstract final class AppIcons {
  // All five tabs share one outlined/rounded Material icon family.
  // Reading, juz sections and memorization have deliberately distinct symbols.
  static const navigation = [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.library_books_outlined,
    Icons.psychology_outlined,
    Icons.insights_outlined,
  ];
  static const selectedNavigation = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.library_books_rounded,
    Icons.psychology_rounded,
    Icons.insights_rounded,
  ];
  static const audio = Icons.headphones_rounded;
  static const settings = Icons.tune_rounded;
  static const prayer = Icons.mosque_outlined;
}
