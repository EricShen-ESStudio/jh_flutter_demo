// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '/jh_common/jh_form/jh_form.dart';
import '/jh_common/utils/jh_common_utils.dart';
import '/jh_common/utils/jh_device_utils.dart';
import '/jh_common/widgets/jh_photo_browser.dart';
import '/project/configs/project_config.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _styles = [FlutterLogoStyle.stacked, FlutterLogoStyle.markOnly, FlutterLogoStyle.horizontal];

  // final _colors = [
  //   Colors.red,
  //   Colors.orange,
  //   Colors.yellow,
  //   Colors.blue,
  //   Colors.purple,
  //   Colors.pink,
  //   Colors.amber
  // ];

  final _curves = [
    Curves.ease,
    Curves.easeIn,
    Curves.easeInOutCubic,
    Curves.easeInOut,
    Curves.easeInQuad,
    Curves.easeInCirc,
    Curves.easeInBack,
    Curves.easeInOutExpo,
    Curves.easeInToLinear,
    Curves.easeOutExpo,
    Curves.easeInOutSine,
    Curves.easeOutSine,
  ];

  // 取随机颜色
  Color _randomColor() {
    var red = Random.secure().nextInt(255);
    var greed = Random.secure().nextInt(255);
    var blue = Random.secure().nextInt(255);
    return Color.fromARGB(255, red, greed, blue);
  }

  Timer? _countdownTimer;

  var _currentVersion = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 2s定时器
      _countdownTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        // https://www.jianshu.com/p/e4106b829bff
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });

    _getInfo(); // 获取设备信息
  }

  void _getInfo() async {
    if (JhDeviceUtils.isIOS) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print(iosInfo.toString());
      print('name ${iosInfo.name}');
      print('Running on ${iosInfo.utsname.machine}');
      print('Running on ${iosInfo.utsname.sysname}');
      print('Running on ${iosInfo.utsname.nodename}');
      print('Running on ${iosInfo.utsname.release}');
      print('Running on ${iosInfo.utsname.version}');
    }

    print('---------------------------------------');

    PackageInfo packageInfo = await JhDeviceUtils.getPackageInfo();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    print('appName $appName');
    print('packageName $packageName');
    print('version $version');
    print('buildNumber $buildNumber');

    setState(() {
      _currentVersion = version;
    });

//   print('$appName=$packageName=$version=$buildNumber');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar('关于我们'),
      body: _body(),
    );
  }

  _body() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 50),
        FlutterLogo(
          size: 100.0,
          textColor: _randomColor(),
          style: _styles[Random.secure().nextInt(3)],
          curve: _curves[Random.secure().nextInt(12)],
        ),
        const SizedBox(height: 20),
        Text('Version：$_currentVersion'),
        const SizedBox(height: 50),
        Container(
          margin: const EdgeInsets.all(20),
          decoration: KStyles.cellBorderStyle,
          child: Column(
            children: [
              JhSetCell(
                title: 'Github',
                text: 'Go Star',
                clickCallBack: () => _jumpWeb('jh_flutter_demo', 'https://github.com/iotjin/jh_flutter_demo'),
              ),
              JhSetCell(
                title: 'author',
                text: 'iotjin',
                clickCallBack: () => _jumpWeb('作者博客', 'https://blog.csdn.net/iotjin'),
              ),
              JhSetCell(
                title: '赞赏支持',
                clickCallBack: () => _showPicture(),
              ),
              JhSetCell(
                title: '检查更新',
                clickCallBack: () => JhCommonUtils.jumpAppStore,
              ),
            ],
          ),
        )
      ],
    );
  }

  _jumpWeb(String title, String url) {
    if (JhDeviceUtils.isWeb) {
      JhCommonUtils.launchWebURL(url);
    } else {
      JhNavUtils.jumpWebViewPage(context, title, url);
    }
  }

  _showPicture() {
    var imgData = ['assets/images/PayCode.jpg'];
    JhPhotoBrowser.show(context, data: imgData, index: 0, isHiddenClose: true);
  }
}
