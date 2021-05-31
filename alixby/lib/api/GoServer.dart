import 'dart:convert';
import 'dart:io';

import 'package:alixby/api/HttpHelper.dart';
import 'package:alixby/models/Setting.dart';
import 'package:alixby/states/Global.dart';
import 'package:alixby/utils/LoadingWidget.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;

class GoServer {
  GoServer();
  void runServer() {
    if (Platform.isWindows) {
      var dbPath = Path.join(Path.current, "data", 'aliserver.exe');
      Process.start(dbPath, [''], mode: ProcessStartMode.detached);
    }
  }

  static Future<bool> connServer() async {
    try {
      CancelFunc hidecb = BotToast.showCustomLoading(
          toastBuilder: (cancelFunc) {
            return LoadingWidget(cancelFunc: cancelFunc, title: "正在启动服务，可能需要40秒");
          },
          allowClick: true,
          clickClose: false,
          crossPage: true,
          duration: Duration(seconds: 15),
          align: Alignment.center,
          backButtonBehavior: BackButtonBehavior.ignore,
          ignoreContentClick: true,
          backgroundColor: Color(0x99000000));
      var response = await HttpHelper.postToServer("Ping", "");
      if (response["code"] != 0) {
        for (int i = 0; i < 60; i++) {
          response = await HttpHelper.postToServer("Ping", "");
          if (response["code"] == 0) break;
          sleep(Duration(milliseconds: 800));
        }
      }
      hidecb();
      if (response["code"] != 0) {
        BotToast.showSimpleNotification(
            title: "严重错误::无法连接到后台进程!!请退出程序后重新打开", hideCloseButton: true, duration: Duration(hours: 5));
        return false;
      }
      //成功连接
      await Global.settingState.loadSetting();
      if (Global.settingState.setting.ver == "") {
        BotToast.showSimpleNotification(
            title: "严重错误::无法连接到后台进程!!请退出程序后重新打开", hideCloseButton: true, duration: Duration(hours: 5));
        return false;
      }

      if (Global.settingState.setting.ver != Setting.UIVER) {
        BotToast.showSimpleNotification(
            title:
                "严重错误::后台进程版本(" + Global.settingState.setting.ver + ")和主界面版本(" + Setting.UIVER + ") 不一致！！请重新下载完整的安装包",
            hideCloseButton: true,
            duration: Duration(hours: 5));
      } else {
        Global.userState.loadUser();
        Global.pageDownState.runTimer();
        Global.panFileState.runTimer();
      }
      return true;
    } catch (e) {
      print('ConnError');
    }
    return false;
  }

  static Future<Setting> goSetting(String key, String val) async {
    try {
      var result = await HttpHelper.postToServer("GoSetting", jsonEncode({"key": key, "val": val}));
      if (result["code"] == 0) {
        var setting = Setting.fromJson(result["setting"]);
        return setting;
      }
    } catch (e) {
      print('goSetting ' + e.toString());
    }
    return Setting();
  }
}
