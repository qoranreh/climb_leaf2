import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white, // 기본 배경색

      shape: RoundedRectangleBorder( // 모서리 둥글게
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      elevation: 8.0, // 그림자 높이
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white, // 기본 배경색
      foregroundColor: Colors.black, // 아이콘 및 텍스트 색상
      elevation: 8.0, // 기본 그림자 높이
      shape: RoundedRectangleBorder( // 버튼 모양
        borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
      ),
    ),
    dialogBackgroundColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // 버튼 배경색
        foregroundColor: Colors.black, // 버튼 텍스트 색상
        textStyle: const TextStyle(fontSize: 16), // 텍스트 스타일
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black, // TextButton 텍스트 색상
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // 모든 AppBar의 배경색
      foregroundColor: Colors.black, // 모든 AppBar의 텍스트 및 아이콘 색상
    ),
    primarySwatch: Colors.grey, // 앱 전체 색상
    scaffoldBackgroundColor: Colors.white, // Scaffold의 기본 배경색
  );
}
