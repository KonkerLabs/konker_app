import 'console_card.dart';
import 'package:flutter/material.dart';
import 'custom_icons.dart';
import 'konker_connection.dart';
import 'actuators_card.dart';
import 'sensors_card.dart';
import 'cutom_logging.dart';
import 'form_card.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
          primaryColor: Color.fromRGBO(0, 75, 155, 1),
          accentColor: Color.fromRGBO(180, 15, 15, 1),
          primaryColorDark: Color.fromRGBO(0, 60, 120, 1)),
      home: MyHomePage(title: 'Konker Sensors'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  BuildContext _scaffoldContext;


  void errorOut(Object error) {
    String err = error.toString();
    if (!KonkerCommunication().paused) {
      setState(() {
        KonkerCommunication().paused = true;

      });
    }
    Log().print('ERROR: $err');
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
      content: new Text(err),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Log().addErrFunc('MainErrorOut', errorOut);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Icon(IconFont.konker_full),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          _scaffoldContext = context;
          return SingleChildScrollView(
            child: Column(children: <Widget>[
              FormCard(),
              SensorsCard(),
              ActuatorsCard(),
              ConsoleCard()
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        //onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: KonkerCommunication().paused
            ? Icon(IconFont.play_arrow)
            : Icon(IconFont.pause),
        onPressed: () {
          setState(() {
            KonkerCommunication().togglePause();
          });
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}



