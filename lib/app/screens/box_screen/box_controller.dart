import 'dart:developer';
import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:buy_control/app/models/product_model.dart';
import 'package:buy_control/app/screens/home_screen/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BoxController extends GetxController {
  final BoxModel box;
  final HomeController homeController = Get.find();
  RxList<ProductModel> products = <ProductModel>[].obs;

  BoxController({required this.box});

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
          widget: Row(
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
