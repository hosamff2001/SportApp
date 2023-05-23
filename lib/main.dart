import 'dart:async';

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wave_image/wave_image.dart';

void main() {
  runApp(SportApp());
}

class SportApp extends StatelessWidget {
  Color color = Color.fromARGB(255, 42, 144, 86);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
            appBarTheme: AppBarTheme(color: color),
            scaffoldBackgroundColor: Color.fromARGB(255, 223, 212, 212)),
        home: MyApp(color));
  }
}

class MyApp extends StatefulWidget {
  final Color color;
  MyApp(this.color);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final player = AudioPlayer();
  PermissionStatus _locationStatus = PermissionStatus.denied;
  List<Position> _positions = [];
  double _distancesum = 0.0;
  int time = 0;
  List<double>? _userAccelerometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  int steps = 0;
  String statas = "Stop";
  bool flagspeed = false;
  double average = 0.0;
  bool isNear = false;
  Timer? timer;
  Timer? timer2;
  List<String>? userAccelerometer = ["0.0", "0.0", "0.0"];

  Future<void> detectObject() async {
    ProximitySensor.events.listen((int event) {
      if (event != 0) {
        isNear = true;
        soundEffect();
      } else {
        isNear = false;
      }
    });
  }

  void soundEffect() {
    player.play(AssetSource('sounds/near.wav'));
  }

  void _addPosition(Position position) {
    setState(() {
      _positions.add(position);
      if (_positions.length >= 2) {
        Position previousPosition = _positions[_positions.length - 2];
        double distanceInMeters = Geolocator.distanceBetween(
          previousPosition.latitude,
          previousPosition.longitude,
          position.latitude,
          position.longitude,
        );
        _distancesum += distanceInMeters;
      }
    });
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 5));
    _addPosition(position);
    // time += 5;
  }

  @override
  void initState() {
    super.initState();
    getLocationStatus();
    detectObject();
    stepsfun();
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
  }

  Future<PermissionStatus> getLocationStatus() async {
    // Request for permission
    // #4
    final status = await Permission.location.request();
    final status2 = await Permission.activityRecognition.request();
    // change the location status
    // #5
    _locationStatus = status;

    // notify listeners
    return status;
  }

  void stepsfun() {
    timer2 = Timer.periodic(Duration(milliseconds: 700), (timer) {
      double ass = userAccelerometer == null
          ? 0
          : sqrt(pow(double.parse(userAccelerometer![0]), 2) +
              pow(double.parse(userAccelerometer![1]), 2) +
              pow(double.parse(userAccelerometer![2]), 2));
      if (ass > 2.6 &&
          double.parse(userAccelerometer![1]) <
              double.parse(userAccelerometer![0]) +
                  double.parse(userAccelerometer![2])) {
        if (ass > 7) {
          statas = "Running";
        } else {
          statas = "Walking";
        }
        setState(() {
          steps++;
        });
      } else {
        if (double.parse(userAccelerometer![1]) >
            double.parse(userAccelerometer![0]) +
                double.parse(userAccelerometer![2])) {
          statas = "Jugging";
        }
        else
        {statas = "Stop";}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // sleep(Duration(seconds: 1));

    userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Sport App'),
        actions: [
          Container(
            width: 70,
            child: WaveImage(
              boarderColor: isNear ? Colors.green : Colors.red,
              boarderWidth: 1,
              imageSize: 20,
              imageUrl:
                  'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
              radius: 70,
              speed: 1000,
              waveColor: isNear ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: 300,
              height: MediaQuery.of(context).size.height * 0.33,
              child: Card(
                shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(150),
                    borderSide: BorderSide(color: widget.color)),
                color: widget.color,
                elevation: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(children: [
                        statas == "Stop"
                            ? Icon(Icons.person_2, size: 150)
                            : statas == "Walking"
                                ? Icon(Icons.directions_walk_outlined,
                                    size: 150)
                                : statas == "Jugging" ?
                                Icon(Icons.airline_stops_rounded, size: 150)
                                 :Icon(Icons.directions_run, size: 150),
                        Text(
                          "steps :  ${steps}",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 27),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            statas,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontSize: 27),
                          ),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 300,
              height: MediaQuery.of(context).size.height * 0.33,
              child: Card(
                shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(150),
                    borderSide: BorderSide(color: widget.color)),
                color: widget.color,
                elevation: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(children: [
                        Icon(Icons.directions_run_sharp, size: 150),
                        Text(
                          'Average Speed  \n ${average.toStringAsFixed(1)} m/s',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 24),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 35.0),
            child: CircleAvatar(
              backgroundColor: widget.color,
              radius: 30,
              child: Text(
                time.toString() + " s",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Spacer(),
          FloatingActionButton(
              backgroundColor: widget.color,
              child: !flagspeed ? Icon(Icons.play_arrow) : Icon(Icons.stop),
              onPressed: getlocation),
        ],
      ),
    );
  }

  void getlocation() {
    setState(() {
      flagspeed = !flagspeed;
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        time++;
      });
      if (flagspeed) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 5));
        _addPosition(position);
      } else {
        timer.cancel();
      }
      if (time == 31) {
        setState(() {
          average = _distancesum / 30;
          print(average);
          time = 0;
          _distancesum = 0;
        });
      }
    });
  }
}
