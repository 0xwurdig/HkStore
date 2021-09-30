import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_apps/device_apps.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hkstore/size_config.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List apps = [];
  String status = "";
  String progress = '0';
  Directory dir;
  @override
  void initState() {
    super.initState();
    versionControl();
  }

  versionControl() async {
    try {
      Directory dira = await getTemporaryDirectory();
      dira.deleteSync(recursive: true);
      setState(() {
        dir = dira;
      });
      FirebaseFirestore.instance
          .collection("apps")
          .snapshots()
          .listen((snapshots) {
        var asd = [];
        snapshots.docs.forEach((e) => asd.add(e.data()));
        // List<Application> qwe = await DeviceApps.getInstalledApplications();
        asd.forEach((element) async {
          Application app = await DeviceApps.getApp(element['package']);
          bool isInstalled =
              await DeviceApps.isAppInstalled(element['package']);
          if (!isInstalled) {
            update(element);
          } else {
            if (app.versionName.toString() + "+" + app.versionCode.toString() !=
                element['version']) {
              update(element);
            } else {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          }
        });
      });
    } catch (e) {
      print("error $e");
    }
  }

  update(Map a) async {
    try {
      await downloadFile(a["url"], a["package"].split(".")[2]);
    } catch (e) {
      print('Failed to make OTA update. Details: $e');
    }
  }

  Future<String> getFilePath(uniqueFileName) async {
    String path = '';

    path = '${dir.path}/$uniqueFileName.apk';
    return path;
  }

  Future<void> downloadFile(uri, fileName) async {
    setState(() {
      status = "downloading";
    });

    String savePath = await getFilePath(fileName);

    Dio dio = Dio();

    dio.download(
      uri,
      savePath,
      onReceiveProgress: (rcv, total) {
        // print(
        //     'received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');

        setState(() {
          progress = ((rcv / total) * 100).toStringAsFixed(0);
        });

        if (progress == '100') {
          setState(() {
            status = "installing";
          });
        } else if (double.parse(progress) < 100) {}
      },
      deleteOnError: true,
    ).then((_) {
      OpenFile.open(savePath);
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            SizeConfig().init(constraints, orientation);
            return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Store',
                theme: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  primaryColor: Colors.black,
                  textTheme: GoogleFonts.poppinsTextTheme(
                    Theme.of(context).textTheme,
                  ),
                  primarySwatch: Colors.blue,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                ),
                home: Scaffold(
                  body: Container(
                      color: Colors.cyanAccent[50],
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                apps.length != 0 ? Colors.black : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          height: getHeight(80),
                          width: getWidth(250),
                          child: Center(
                            child: apps != []
                                ? progress != "0" && progress != "100"
                                    ? Text(progress,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: getText(28)))
                                    : Text(
                                        "$status",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: getText(28)),
                                      )
                                : Text("Up-toDate",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: getText(28))),
                          ),
                        ),
                      )),
                ));
          },
        );
      },
    );
  }
}
