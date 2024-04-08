import 'dart:async';

import 'package:drivers/global/global.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Assistant/assistant_method.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {

  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962),
      zoom: 14.4746,
  );

  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;

  String statusText = "Now Offline";
  Color buttonColor = Colors.grey;
  bool isDriverActive = false;

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    driverCurrentPosition = cPosition;
    LatLng latLngPosition =
    LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
    CameraPosition cameraPosition =
    CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    String humanReadableAddress =
    await AssistantMethods.searchAddressForGeographicCoordinates(
        driverCurrentPosition!, context);
    print("This is our address" + humanReadableAddress);

  }

  readCurrentDriverInformation() async {
    currentUser = firebaseAuth.currentUser;
    FirebaseDatabase.instance.ref()
    .child("drivers")
    .child(currentUser!.uid)
    .once()
    .then((snap){
      if(snap.snapshot.value != null){
        onlineDriverData.id = (snap.snapshot.value as Map)["id"];
        onlineDriverData.name = (snap.snapshot.value as Map)["name"];
        onlineDriverData.phone = (snap.snapshot.value as Map)["phone"];
        onlineDriverData.email = (snap.snapshot.value as Map)["email"];
        onlineDriverData.address = (snap.snapshot.value as Map)["address"];
        onlineDriverData.car_model = (snap.snapshot.value as Map)["car_details"]["car_model"];
        onlineDriverData.car_number = (snap.snapshot.value as Map)["car_details"]["car_number"];
        onlineDriverData.car_color = (snap.snapshot.value as Map)["car_details"]["car_color"];

        driverVehicleType = (snap.snapshot.value as Map)["car_details"]["type"];
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
    readCurrentDriverInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: EdgeInsets.only(top: 40),
          mapType: MapType.normal,
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller){
            _controllerGoogleMap.complete(controller);

            newGoogleMapController = controller;

            locateDriverPosition();
          },
        ),

        //ui for online\offline driver
        statusText != "Now online"
        ? Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          color: Colors.black87,
        ): Container(),

        //button for online\offline driver
        Positioned(
          top: statusText != "Now online" ? MediaQuery.of(context).size.height * 0.45 : 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: (){
                    if(isDriverActive != true) {
                      driverIsOnlineNow();
                      updateDriversLocationAtRealTime();

                      setState(() {
                        statusText = "Now Online";
                        isDriverActive = true;
                        buttonColor = Colors.transparent;
                      });
                    }
                    else{
                      driverIsOfflineNow();
                      setState(() {
                        statusText = "Now Offline";
                        isDriverActive = false;
                        buttonColor = Colors.grey;
                      });
                      Fluttertoast.showToast(msg: "Your are Offline now");
                    }
                  },
                   style: ElevatedButton.styleFrom(
                     primary: buttonColor,
                     padding: EdgeInsets.symmetric(horizontal: 18),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(26),
                     )
                   ),
                  child: statusText != "Now Online" ? Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ) : Icon(
                    Icons.phonelink_ring,
                    color: Colors.white,
                    size: 26,
                  )
              )
            ],
          ),
        ),

      ],
    );
  }

  driverIsOnlineNow() async{
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    driverCurrentPosition = pos;

    Geofire.initialize("activeDrivers");
    Geofire.setLocation(currentUser!.uid,driverCurrentPosition!.latitude,driverCurrentPosition!.longitude);

    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers").child(currentUser!.uid).child("newRideStatus");
    
    ref.set("idle");
    ref.onValue.listen((event) { });

  }

  updateDriversLocationAtRealTime(){
  streamSubscriptionPosition = Geolocator.getPositionStream().listen((Position position) {
    if(isDriverActive == true){
      Geofire.setLocation(currentUser!.uid, driverCurrentPosition!.latitude,driverCurrentPosition!.longitude);
    }

    LatLng latLng = LatLng(driverCurrentPosition!.latitude,driverCurrentPosition!.longitude);

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
  });
  }

  driverIsOfflineNow(){
    Geofire.removeLocation(currentUser!.uid);

    DatabaseReference? ref= FirebaseDatabase.instance.ref().child("drivers").child(currentUser!.uid).child("newRideStatus");

    ref.onDisconnect();
    ref.remove();
    ref = null;

    Future.delayed(Duration(milliseconds: 2000),(){
      SystemChannels.platform.invokeMethod("SystemNavigator.pop");
    });
  }

}
