import 'package:buy_control/app/components/lucide_icon_container.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/screens/box_screen/bottom_sheet/bottom_sheet_create_products.dart';
import 'package:buy_control/app/screens/box_screen/box_controller.dart';
import 'package:buy_control/app/utils/formatter_price.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BoxScreen extends StatelessWidget {
  late BoxController controller;
  final BoxModel box;
  BoxScreen({super.key, required this.box}) {
    controller = Get.put(BoxController(box: box));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: InkWell(
              onTap: () {
                Get.bottomSheet(BottomSheetCreateProducts());
              },
              child: LucideIconContainer(
                icon: LucideIcons.plus,
                color: AppColors.buttonSecondaryLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: InkWell(
              onTap: () async {
                controller.homeController.deleteBox(box);
              },
              child: LucideIconContainer(
                icon: LucideIcons.trash,
                color: AppColors.buttonSecondaryLight,
              ),
            ),
          ),
        ],
        title: TextCustom(
          text: box.name,
          color: AppColors.textPrimaryDark,
          fontSize: AppFontSizes.fz10,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: InkWell(
            onTap: () => Get.back(),
            child: LucideIconContainer(
              icon: LucideIcons.arrowLeft,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
      body: GetBuilder<BoxController>(
        builder: (_) {
          return Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 2),
                height: 60,
                decoration: BoxDecoration(color: AppColors.cardDark),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextCustom(
                      text: 'Total: ${formatPrice(box.calculateTotalPrice())}',
                      color: AppColors.textPrimaryDark,
                      fontSize: AppFontSizes.fz10,
                    ),
                    TextCustom(
                      text: 'Qtd: ${box.getTotalQuantity()}',
                      color: AppColors.textPrimaryDark,
                      fontSize: AppFontSizes.fz10,
                    ),
                  ],
                ),
              ),
              Container(
                height: 2,
                margin: EdgeInsets.only(
                  right: 10,
                  left: 10,
                  top: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(color: AppColors.textSecondaryLight),
              ),
              Expanded(
                // ADICIONE ISSO
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(right: 10, left: 10),
                  child: controller.products.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextCustom(
                              text: 'Nenhum produto cadastrado',
                              color: AppColors.textSecondaryDark,
                              fontSize: AppFontSizes.fz10,
                            ),
                          ],
                        )
                      : Column(
                          children: controller.products
                              .map(
                                (product) => InkWell(
                                  onTap: () {
                                    Get.bottomSheet(
                                      BottomSheetCreateProducts(
                                        productModel: product,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 80,
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TextCustom(
                                              text: product.name,
                                              color: AppColors.textPrimaryDark,
                                              fontSize: AppFontSizes.fz10,
                                            ),
                                            if (product
                                                    .description
                                                    ?.isNotEmpty ??
                                                false)
                                              TextCustom(
                                                text: product.description!,
                                                color:
                                                    AppColors.textSecondaryDark,
                                                fontSize: AppFontSizes.fz08,
                                              ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            TextCustom(
                                              text: formatPrice(product.price),
                                              color: AppColors.textPrimaryDark,
                                              fontSize: AppFontSizes.fz10,
                                            ),
                                            TextCustom(
                                              text: 'Qtd: ${product.quantity}',
                                              color: AppColors.textPrimaryDark,
                                              fontSize: AppFontSizes.fz10,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
