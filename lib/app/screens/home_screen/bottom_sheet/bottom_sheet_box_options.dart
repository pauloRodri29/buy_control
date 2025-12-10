import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/screens/home_screen/bottom_sheet/bottom_sheet_edit_box.dart';
import 'package:buy_control/app/screens/home_screen/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomSheetBoxOptions extends StatelessWidget {
  final BoxModel? boxModel;
  final HomeController controller = Get.find();
  BottomSheetBoxOptions({super.key, this.boxModel});
  @override
  Widget build(BuildContext context) {
    return BottomSheetDefault(
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextCustom(
            text: boxModel!.name,
            fontSize: AppFontSizes.fz12,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 12),
          SingleChildScrollView(child: Column(spacing: 24, children: [
               
              ],
            )),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: ButtonDefaultCustom(
                    label: "Editar",
                    onClick: () {
                      Get.back();
                      Get.bottomSheet(BottomSheetEditBox(boxModel: boxModel));
                    },
                  ),
                ),
                Expanded(
                  child: ButtonDefaultCustom(
                    onClick: () async {
                      Get.back();
                      controller.deleteBox(boxModel!);
                    },
                    label: "Excluir",
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
