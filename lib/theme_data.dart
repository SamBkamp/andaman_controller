import 'package:flutter/material.dart';

class Theme_data {

  const Theme_data();

  Widget small_text_bold(String text){
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget small_text(String text){
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
      ),
    );
  }

  Widget generic_text(String text, double fontsize, FontWeight fontweight){
    return Text(
      text,
      style: TextStyle(
        fontSize: fontsize,
        fontWeight: fontweight,
      ),
    );
  }

  Widget title_text(String text){
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget subtitle_text(String text){
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

}
