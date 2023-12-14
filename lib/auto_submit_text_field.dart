import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class AutoSubmitTextField extends StatelessWidget {
  final double value;
  final void Function(String text) onSubmitted;
  final TextAlign? textAlign;
  final InputDecoration? decoration;
  final Color? fillColor;
  final Color? textColor;
  const AutoSubmitTextField({
    required this.value,
    required this.onSubmitted,
    this.textAlign,
    this.decoration,
    this.fillColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController()..text = value.toString();
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _handleSubmit(controller.text);
      }
    });

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: _handleSubmit,
      textAlign: textAlign ?? TextAlign.start,
      decoration: decoration,
      onTap: () {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      },
    );
  }

  void _handleSubmit(String text) {
    if (text.isNotEmpty) {
      onSubmitted(text);
    }
  }
}

class DefParamTextField extends AutoSubmitTextField {
  final String defParamName;
  final double defParamValue;
  DefParamTextField({
    required this.defParamName,
    required this.defParamValue,
    required super.onSubmitted,
    super.fillColor,
    super.textColor,
    super.key,
  }) : super(
          value: defParamValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            label: SizedBox(
              width: 20, // TODO: 参数名的字体肯定要变大, 这个宽度现在刚刚好, 所以肯定要变大
              child: Math.tex(defParamName, textStyle: TextStyle(color: textColor)),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8), // Set your desired radius
            ),
          ),
        );
}

class ParamTextField extends AutoSubmitTextField {
  final String paramName;
  final double paramValue;
  ParamTextField({
    required this.paramName,
    required this.paramValue,
    required super.onSubmitted,
    super.fillColor,
    super.textColor,
    super.key,
  }) : super(
          value: paramValue,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            label: Math.tex(paramName, textStyle: TextStyle(color: textColor)),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
}

class TermTextField extends AutoSubmitTextField {
  final String termName; // 其实目前没用到
  final double termValue;
  TermTextField({
    required this.termName,
    required this.termValue,
    required super.onSubmitted,
    super.fillColor,
    super.key,
  }) : super(
          value: termValue,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
}
