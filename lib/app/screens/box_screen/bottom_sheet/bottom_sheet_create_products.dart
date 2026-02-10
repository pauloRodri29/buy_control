import 'package:brasil_fields/brasil_fields.dart';
import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/components/lucide_icon_container.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/components/text_field_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/product_model.dart';
import 'package:buy_control/app/screens/box_screen/box_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BottomSheetCreateProducts extends StatefulWidget {
  final ProductModel? productModel;
  const BottomSheetCreateProducts({super.key, this.productModel});

  @override
  State<BottomSheetCreateProducts> createState() =>
      _BottomSheetCreateProductsState();
}

class _BottomSheetCreateProductsState extends State<BottomSheetCreateProducts> {
  final BoxController boxController = Get.find();
  final nameProductController = TextEditingController();
  final descriptionProductController = TextEditingController();
  final priceProductController = TextEditingController();
  final quantityProductController = TextEditingController();

  bool errorName = false;
  bool errorPrice = false;
  bool errorQuantity = false;
  @override
  void initState() {
    super.initState();
    if (widget.productModel != null) {
      nameProductController.text = widget.productModel!.name;
      descriptionProductController.text =
          widget.productModel?.description ?? "";
      priceProductController.text = UtilBrasilFields.obterReal(
        widget.productModel!.price.toDouble(),
      );
      quantityProductController.text = widget.productModel!.quantity.toString();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool validetForm() {
    setState(() {
      errorName = nameProductController.text.isEmpty;
      errorPrice = priceProductController.text.isEmpty;
      errorQuantity = quantityProductController.text.isEmpty;
    });
    return errorName || errorPrice || errorQuantity;
  }

  void _submit() {
    if (validetForm()) {
      return;
    }
    if (widget.productModel != null) {
      boxController.editProduct(
        ProductModel(
          id: widget.productModel!.id,
          name: nameProductController.text,
          description: descriptionProductController.text,
          price: UtilBrasilFields.converterMoedaParaDouble(
            priceProductController.text,
          ),
          quantity: int.parse(quantityProductController.text),
        ),
      );
    } else {
      boxController.createProduct(
        ProductModel(
          name: nameProductController.text,
          description: descriptionProductController.text,
          price: UtilBrasilFields.converterMoedaParaDouble(
            priceProductController.text,
          ),
          quantity: int.parse(quantityProductController.text),
        ),
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetDefault(
      height: Get.height * 0.44,
      widget: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextCustom(
              text: widget.productModel != null
                  ? "Editar Produto"
                  : "Novo Produto",
              fontSize: AppFontSizes.fz11,
            ),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    ModernTextField(
                      hint: "Nome",
                      controller: nameProductController,
                      errorText: errorName ? "Campo obrigatório" : null,
                      error: errorName,
                    ),
                    ModernTextField(
                      hint: "Descrição (Opcional)",
                      controller: descriptionProductController,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ModernTextField(
                            hint: "Quantidade",
                            controller: quantityProductController,
                            errorText: errorQuantity
                                ? "Campo obrigatório"
                                : null,
                            error: errorQuantity,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ModernTextField(
                            hint: "Preço",
                            controller: priceProductController,
                            errorText: errorPrice ? "Campo obrigatório" : null,
                            error: errorPrice,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CentavosInputFormatter(moeda: true),
                            ],
                            // prefix: TextCustom(
                            //   text: 'R\$',
                            //   fontSize: AppFontSizes.fz08,
                            // ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              spacing: 4,
              children: [
                Expanded(
                  child: ButtonDefaultCustom(
                    label: widget.productModel != null ? "Salvar" : "Adicionar",
                    onClick: _submit,
                  ),
                ),
                if (widget.productModel != null)
                  InkWell(
                    onTap: () {
                      Get.back();
                      boxController.deleteProduct(widget.productModel!);
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
          ],
        ),
      ),
    );
  }
}
