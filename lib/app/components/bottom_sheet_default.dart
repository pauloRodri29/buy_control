import 'package:buy_control/app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomSheetDefault extends StatelessWidget {
  final Widget widget;
  final double? width;
  final double? height;
  const BottomSheetDefault({
    super.key,
    required this.widget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: Get.width,
      constraints: BoxConstraints(maxHeight: height ?? Get.height * 0.95),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.textOnDarkButton,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4, bottom: 12),
            height: 4,
            constraints: BoxConstraints(maxWidth: Get.width * 0.2),
            decoration: const BoxDecoration(color: AppColors.borderLight),
          ),
          widget,
        ],
      ),
    );
  }
}
