import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Location location = Location();
  late PermissionStatus permissionStatus;
  bool isServiceEnable = false;
  late StreamSubscription<LocationData> streamSubscription;
  LocationData? locationData;
  double defLat = 29.9652252;
  double defLong = 30.9466826;
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(29.9652252, 30.9466826),
    zoom: 20.4746,
  );

  /*final CameraPosition _kLake = const CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(30.0346666, 31.1961541),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);*/

  @override
  void dispose() {

    super.dispose();
    streamSubscription.cancel();
  }

  Set<Marker> markers = {};

  @override
  void initState() {

    super.initState();
    getUserLocation();
    var userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(locationData?.latitude ?? defLat,
            locationData?.longitude ?? defLong));
    markers.add(userMarker);
  }

  void updateUserLocation(LatLng latLng) async {
    var userMarker =
        Marker(markerId: const MarkerId('user_location'), position: latLng);
    markers.add(userMarker);
    setState(() {});
    final GoogleMapController controller = await _controller.future;
    var newCameraPos = CameraPosition(target: latLng, zoom: 19, tilt: 40.25);

    controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        markers: markers,
        onTap: (latlon) {
          updateUserLocation(latlon);
        },
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        }, //30.035863,31.1290426
      ),
    );
  }



  void getUserLocation() async {
    bool perGranted = await isPermissionGranted();
    bool enableService = await isServicesEnabled();
    if (!perGranted) return; // user deined permission
    if (!enableService) return; // user didnt allow enable location
    if (perGranted && enableService) {
      // get location
      locationData = await location.getLocation();
      //print(" ${locationData?.latitude} && ${locationData?.longitude}");
      streamSubscription = location.onLocationChanged.listen((newestLoacaton) {
        locationData = newestLoacaton;
        updateUserLocation(LatLng(locationData?.latitude ?? defLat,
            locationData?.longitude ?? defLong));
        //print(" ${locationData?.latitude} && ${locationData?.longitude}");
      });
    }
  }

  Future<bool> isPermissionGranted() async {
    permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
    }
    return permissionStatus == PermissionStatus.granted;
  }

  Future<bool> isServicesEnabled() async {
    isServiceEnable = await location.serviceEnabled();
    if (!isServiceEnable) {
      isServiceEnable = await location.requestService();
    }

    return isServiceEnable;
  }
}
