import 'dart:developer';
import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/models/product_model.dart';
import 'package:buy_control/app/models/unit_type.dart';
import 'package:buy_control/app/screens/home_screen/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BoxController extends GetxController {
  BoxController({required this.box});
  final BoxModel box;
  final HomeController homeController = Get.find();
  RxList<ProductModel> products = <ProductModel>[].obs;

  final units = [
    UnitType("UN", "Unidade"),
    UnitType("PCT", "Pacote"),
    UnitType("CX", "Caixa"),
    UnitType("FD", "Fardo"),
    UnitType("KG", "Quilo (kg)"),
    UnitType("G", "Grama (g)"),
    UnitType("L", "Litro (L)"),
    UnitType("ML", "Mililitro (ml)"),
    UnitType("FR", "Frasco"),
    UnitType("PT", "Pote"),
    UnitType("TB", "Tubo"),
    UnitType("BDJ", "Bandeja"),
    UnitType("DZ", "Dúzia"),
    UnitType("KIT", "Kit"),
  ];

  List<Map<String, String>> getValueDropdown() {
    return units.map((e) {
      return {"key": e.code, "label": e.label};
    }).toList();
  }

  Future<void> createProduct(ProductModel product) async {
    try {
      products.add(product);
      homeController.updateBox(box);
      log("Salvando produto: $product na box: ${box.name}");
    } catch (e) {
      log("Erro criar produto: $e");
    }
    update();
  }

  Future<void> editProduct(ProductModel updated) async {
    try {
      box.updateProduct(updated);
      homeController.updateBox(box);
    } catch (e) {
      log("Erro ao editar produto: $e");
    }
    update();
  }
  // Future<void> editProduct(ProductModel product) async {
  //   try {
  //     final result = box.products.firstWhere(
  //       (element) => element.id.toLowerCase() == product.id.toLowerCase(),
  //     );
  //     box.products.remove(result);
  //     box.addProduct(product);
  //     _saveBox();
  //   } catch (e) {
  //     log("Erro criar produto: $e");
  //   }
  //   update();
  // }

  Future<void> deleteProduct(ProductModel product) async {
    try {
      final result = await Get.bottomSheet<bool>(
        BottomSheetDefault(
          widget: Column(
            spacing: 12,
            children: [
              TextCustom(
                text: "Deseja realmente excluir o produto: ${product.name}?",
                fontSize: AppFontSizes.fz10,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ButtonDefaultCustom(
                      backgroundColor: AppColors.error,
                      label: "Excluir",
                      onClick: () {
                        Get.back(result: true);
                        // controller.homeController.deleteBox(
                        //   controller.homeController.listBox.indexOf(box),
                        // );
                      },
                    ),
                  ),
                  Expanded(
                    child: ButtonDefaultCustom(
                      label: "Cancelar",
                      onClick: () {
                        Get.back(result: false);
                        // controller.homeController.deleteBox(
                        //   controller.homeController.listBox.indexOf(box),
                        // );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (result ?? false) {
        box.products.remove(product);
        homeController.updateBox(box);
      }
    } catch (e) {
      log("Erro criar produto: $e");
    }
    update();
  }

  Future<void> deleteAllProduct() async {
    try {
      final result = await Get.bottomSheet<bool>(
        BottomSheetDefault(
          widget: Column(
            children: [
              TextCustom(
                text: "Excluir todos os produtos?",
                fontSize: AppFontSizes.fz10,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ButtonDefaultCustom(
                      backgroundColor: AppColors.error,
                      label: "Excluir",
                      onClick: () {
                        Get.back(result: true);
                        // controller.homeController.deleteBox(
                        //   controller.homeController.listBox.indexOf(box),
                        // );
                      },
                    ),
                  ),
                  Expanded(
                    child: ButtonDefaultCustom(
                      label: "Cancelar",
                      onClick: () {
                        Get.back(result: false);
                        // controller.homeController.deleteBox(
                        //   controller.homeController.listBox.indexOf(box),
                        // );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (result ?? false) {
        box.products.clear();
        homeController.updateBox(box);
      }
    } catch (e) {
      log("Erro apagar todos os produto: $e");
    }
    update();
  }

  void loadData() {
    products.value = box.products;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
}
