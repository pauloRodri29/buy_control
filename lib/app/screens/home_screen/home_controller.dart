import 'dart:developer';
import 'package:buy_control/app/components/bottom_sheet_default.dart';
import 'package:buy_control/app/components/button_default_custom.dart';
import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:buy_control/app/controllers/hive_repository.dart';
import 'package:buy_control/app/models/box_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  HiveRepository hiveRepository = HiveRepository();
  var loading = false.obs;
  RxList<BoxModel> listBox = <BoxModel>[].obs;

  void saveListBoxHive(List<BoxModel> listBoxModel) async {
    try {
      final boxListMaps = listBoxModel.map((box) => box.toMap()).toList();
      await hiveRepository.save(key: 'boxList', value: boxListMaps);
    } catch (e) {
      log("Erro ao salvar lista de boxes no Hive: $e");
    }

    update();
  }

  Future<void> updateBox(BoxModel updatedBox) async {
    try {
      final index = listBox.indexWhere(
        (b) => b.id.toLowerCase() == updatedBox.id.toLowerCase(),
      );

      if (index == -1) {
        log("Box não encontrado para atualizar");
        return;
      }

      // Substitui o box antigo pelo atualizado
      listBox[index] = updatedBox;

      // Atualiza visual
      listBox.refresh();

      // Salva no Hive
      saveListBoxHive(listBox);

      log("Box atualizado com sucesso: ${updatedBox.name}");
    } catch (e) {
      log("Erro ao atualizar box: $e");
    }
  }

  Future<void> getBoxList() async {
    try {
      final result = await hiveRepository.get(key: 'boxList');
      log("result: $result");

      if (result != null && result is List) {
        listBox.value = result
            .map(
              (boxMap) => BoxModel.fromMap(Map<String, dynamic>.from(boxMap)),
            )
            .toList();
      } else {
        listBox.value = [];
      }
    } catch (e) {
      log("Erro ao pegar a lista de boxes no Hive: $e");
      listBox.value = [];
    }

    update();
  }

  Future<void> editBox(BoxModel box, String newName) async {
    try {
      final result = listBox.firstWhere(
        (b) => b.id.toLowerCase() == box.id.toLowerCase(),
      );
      result.name = newName;
      listBox.refresh();
      saveListBoxHive(listBox);
    } catch (e) {
      log("Erro ao editar box no Hive: $e");
    }
    update();
  }

  Future<void> createBox(BoxModel box) async {
    try {
      listBox.add(box);

      // Salva a lista completa como lista de Maps
      saveListBoxHive(listBox);
    } catch (e) {
      log("Erro ao criar box no Hive: $e");
    }
    update();
  }

  Future<void> deleteBox(BoxModel box) async {
    try {
      final result = await Get.bottomSheet<bool>(
        BottomSheetDefault(
          widget: Column(
            children: [
              TextCustom(
                text: "Box  ${box.name}",
                fontSize: AppFontSizes.fz11,
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
        listBox.remove(box);
        saveListBoxHive(listBox);
        Get.back();
      }
    } catch (e) {
      log("Erro ao deletar box no Hive: $e");
    }
    update();
  }

  Future<void> showHiveDate() async {
    try {
      final result = await hiveRepository.getBoxData(key: 'boxList');
      log("result: $result");
    } catch (e) {
      log("Erro ao pegar a data do Hive: $e");
    }
  }

  void loadData() async {
    loading.value = true;
    await getBoxList();
    Future.delayed(Duration(seconds: 2)).then((value) => loading.value = false);
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
}
