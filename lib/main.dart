import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestLocationPermission();
  runApp(const MyApp());
}

Future<void> requestLocationPermission() async {
  final PermissionStatus status = await Permission.location.request();
  if (status != PermissionStatus.granted) {
    throw Exception('Location permission denied !');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Geolocator Map',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Position? _previousPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _onScreenStart();
    _startLocationUpdates();
    _initializePolylines();
  }
  void _initializePolylines() {
    setState(() {
      _polylines = {};
    });
  }

  Future<void> _onScreenStart() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        _previousPosition = position;
        _updateMarker(position);
        _animateToLocation(position.latitude, position.longitude);
      } catch (e) {
        print(e.toString());
      }
    }
  }

  void _startLocationUpdates() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      _getCurrentLocation().then((position) {
        if (position != null) {
          _updateMarker(position);
          _updatePolyline(position);
          _animateToLocation(position.latitude, position.longitude);
        }
      });
    });
  }

  Future<Position?> _getCurrentLocation() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      print(e.toString());
    }
    return position;
  }
  void _updateMarker(Position position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('current_Location'),
          position: LatLng(position.latitude, position.longitude),
          draggable: true,
          infoWindow: InfoWindow(
            title: "My current location",
            snippet: "Lat: ${position.latitude}, Lng: ${position.longitude}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );

      if (_previousPosition != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('previous_Location'),
            position: LatLng(_previousPosition!.latitude, _previousPosition!.longitude),
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    });
  }


  void _updatePolyline(Position position) {
    if (_previousPosition != null) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: [
              LatLng(_previousPosition!.latitude, _previousPosition!.longitude),
              LatLng(position.latitude, position.longitude),
            ],
            color: Colors.blueAccent,
            width: 7,
          ),
        );
      });
    }
    _previousPosition = position;
  }


  void _animateToLocation(double latitude, double longitude) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16,
            bearing: 90,
            tilt: 90
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocator Map App'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        initialCameraPosition: CameraPosition(
            target: LatLng(0, 0),
            zoom: 16,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onTap: (LatLng latLng) {
          print('tapped on map : $latLng');
        },
        onLongPress: (LatLng latLng) {
          print('on Long press : $latLng');
        },
        compassEnabled: true,
        zoomGesturesEnabled: true,
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
