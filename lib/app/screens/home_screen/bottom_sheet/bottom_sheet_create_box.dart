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

class BottomSheetCreateBox extends StatefulWidget {
  final BoxModel? boxModel;
  const BottomSheetCreateBox({super.key, this.boxModel});

  @override
  State<BottomSheetCreateBox> createState() => _BottomSheetCreateBoxState();
}

class _BottomSheetCreateBoxState extends State<BottomSheetCreateBox> {
  final HomeController homeController = Get.find();
  bool errorName = false;
  final nameBoxController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // if (widget.boxModel != null) {
    //   nameProductController.text = widget.boxModel!.name;
    //   descriptionProductController.text =
    //       widget.boxModel?.description ?? "";
    //   priceProductController.text = UtilBrasilFields.obterReal(
    //     widget.boxModel!.price.toDouble(),
    //   );
    //   quantityProductController.text = widget.boxModel!.quantity.toString();
    // }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _submit() {
    final name = nameBoxController.text.trim();

    setState(() {
      errorName = name.isEmpty;
    });

    if (errorName) return;
    if (widget.boxModel != null) {
      // homeController.editProduct(
      //   ProductModel(
      //     name: nameProductController.text,
      //     description: descriptionProductController.text,
      //     price: UtilBrasilFields.converterMoedaParaDouble(
      //       priceProductController.text,
      //     ),
      //     quantity: int.parse(quantityProductController.text),
      //   ),
      // );
    } else {
      homeController.createBox(BoxModel(name: nameBoxController.text));
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetDefault(
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextCustom(text: "Criar Box", fontSize: AppFontSizes.fz12),
          SizedBox(height: 12),
          SingleChildScrollView(
            child: Column(
              spacing: 24,
              children: [
                ModernTextField(
                  maxLength: 20,
                  hint: "Nome",
                  controller: nameBoxController,
                  errorText: errorName ? "Campo obrigatório" : null,
                  error: errorName,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: ButtonDefaultCustom(
                    label: "Adicionar",
                    onClick: _submit,
                  ),
                ),
                if (widget.boxModel != null)
                  InkWell(
                    onTap: errorName
                        ? null
                        : () {
                            Get.back();
                          },
                    child: Container(
                      padding: EdgeInsets.all(18),
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
