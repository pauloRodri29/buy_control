import 'dart:developer';
import 'package:buy_control/app/components/button_circle.dart';
import 'package:buy_control/app/components/card_default.dart';
import 'package:buy_control/app/components/lucide_icon_container.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/screens/box_screen/box_screen.dart';
import 'package:buy_control/app/screens/home_screen/bottom_sheet/bottom_sheet_box_options.dart';
import 'package:buy_control/app/screens/home_screen/bottom_sheet/bottom_sheet_create_box.dart';
import 'package:buy_control/app/screens/home_screen/home_controller.dart';
import 'package:buy_control/app/utils/data_time_custom_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masonry_view/flutter_masonry_view.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 12,
          children: [
            LucideIconContainer(
              icon: LucideIcons.clipboardList,
              size: 32,
              color: AppColors.backgroundLight,
            ),
            const TextCustom.title(
              'BuyControl',
              color: AppColors.secondary,
              fontSize: AppFontSizes.fz12,
            ),
          ],
        ),
      ),
      body: GetBuilder<HomeController>(
        builder: (_) {
          return Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: controller.listBox.isNotEmpty
                    ? MasonryView(
                        numberOfColumn: 2,
                        listOfItem: controller.listBox,
                        itemBuilder: (box) {
                          final BoxModel item = box;
                          return CardDefault(
                            onLongPressed: () {
                              Get.bottomSheet(
                                BottomSheetBoxOptions(boxModel: item),
                              );
                            },
                            onPressed: () {
                              Get.to(() => BoxScreen(box: item));
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextCustom(
                                  text: item.name,
                                  color: AppColors.textPrimaryDark,
                                  fontSize: AppFontSizes.fz09,
                                  maxLines: 2,
                                ),
                                SizedBox(height: 6),
                                TextCustom(
                                  text: "${item.getTotalQuantity()} itens",
                                  fontSize: AppFontSizes.fz08,
                                  color: AppColors.textPrimaryDark,
                                ),
                                SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextCustom(
                                    text:
                                        "criado em ${DataTimeCustomFormatter.formatDateCustom(item.createdAt)}",
                                    color: AppColors.textPrimaryDark,
                                    fontSize: AppFontSizes.fz05,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Get.bottomSheet(BottomSheetCreateBox());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              spacing: 18,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextCustom(
                                  text:
                                      'Nenhuma Box cadastrada \n Clique aqui para criar nova',
                                  fontSize: AppFontSizes.fz11,
                                  textAlign: TextAlign.center,
                                  color: AppColors.textSecondaryLight,
                                ),
                                LucideIconContainer(
                                  icon: LucideIcons.plus,
                                  size: 32,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              // Align(
              //   alignment: Alignment.bottomLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.all(24),
              //     child: ButtonCircle(
              //       onPressed: () {
              //         controller.showHiveDate();
              //       },
              //       icon: LucideIcons.database,
              //       size: 64,
              //     ),
              //   ),
              // ),
              if (controller.listBox.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ButtonCircle(
                      onPressed: () {
                        Get.bottomSheet(BottomSheetCreateBox());
                      },
                      icon: LucideIcons.plus,
                      size: 64,
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
