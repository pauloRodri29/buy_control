import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/components/lucide_icon_container.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/components/text_field_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/screens/home_screen/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BottomSheetEditBox extends StatefulWidget {
  final BoxModel? boxModel;
  const BottomSheetEditBox({super.key, this.boxModel});

  @override
  State<BottomSheetEditBox> createState() => _BottomSheetEditBoxState();
}

class _BottomSheetEditBoxState extends State<BottomSheetEditBox> {
  final HomeController homeController = Get.find();
  bool nameIsValid = true;
  final nameProductController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.boxModel != null) {
      nameProductController.text = widget.boxModel!.name;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isValidForm() {
    return nameProductController.text.isNotEmpty &&
        nameProductController.text.trim().isNotEmpty;
  }

  void _edit() {
    final valid = isValidForm();
    if (valid) {
      homeController.editBox(widget.boxModel!, nameProductController.text);
      Get.back();
    } else {
      setState(() {
        nameIsValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return BottomSheetDefault(
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextCustom(
            text: widget.boxModel != null ? "Editar Box" : "Criar Box",
            fontSize: AppFontSizes.fz12,
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            child: Column(
              spacing: 24,
              children: [
                ModernTextField(
                  hint: "Nome",
                  controller: nameProductController,
                  isValid: nameIsValid,
                  onChanged: (value) {
                    setState(() {
                      nameIsValid = isValidForm();
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              spacing: 4,
              children: [
                Expanded(
                  child: ButtonDefaultCustom(label: "Salvar", onClick: _edit),
                ),
                if (widget.boxModel != null)
                  InkWell(
                    onTap: () {
                      Get.back();
                      homeController.deleteBox(widget.boxModel!);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.error,
                      ),
                      child: LucideIconContainer(
                        icon: LucideIcons.trash,
                        color: AppColors.iconActiveDark,
                      ),
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
