import 'package:flutter/material.dart';

class ContextTooltip extends StatelessWidget {
  final String text;

  const ContextTooltip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      padding: EdgeInsets.all(8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
