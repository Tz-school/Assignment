import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SelectedLocation {
  final String address;
  final String state;
  final double latitude;
  final double longitude;

  const SelectedLocation({
    required this.address,
    required this.state,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
  });

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {
  final MapController _mapController =
  MapController();

  LatLng _selectedLocation = const LatLng(
    3.1390,
    101.6869,
  );

  String _selectedAddress =
      'Tap on the map to select an address';

  String _selectedState = '';

  bool _loadingAddress = false;



  Future<void> _getAddressFromLocation(
      LatLng location,
      ) async {
    setState(() {
      _loadingAddress = true;
      _selectedAddress = 'Finding address...';
      _selectedState = '';
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2'
            '&lat=${location.latitude}'
            '&lon=${location.longitude}'
            '&zoom=18'
            '&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'com.example.assignment',
        },
      );

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _selectedAddress =
          'Unable to find address. Please try again.';
          _selectedState = '';
        });

        return;
      }

      final data =
      jsonDecode(response.body);

      final Map<String, dynamic> addressData =
      Map<String, dynamic>.from(
        data['address'] ?? {},
      );

      final String address =
          data['display_name']
              ?.toString() ??
              '';


      String state =
          addressData['state']?.toString() ??
              '';

      if (state.trim().isEmpty) {
        state =
            addressData['region']
                ?.toString() ??
                '';
      }

      if (state.trim().isEmpty) {
        state =
            addressData['state_district']
                ?.toString() ??
                '';
      }

      if (state.trim().isEmpty) {
        state =
            addressData['county']?.toString() ??
                '';
      }

      if (state.trim().isEmpty) {
        state =
            addressData['city']?.toString() ??
                '';
      }

      if (state.trim().isEmpty) {
        state =
            addressData['municipality']
                ?.toString() ??
                '';
      }


      state = _standardizeMalaysiaState(
        state,
        addressData,
      );

      if (!mounted) return;

      if (address.isNotEmpty) {
        setState(() {
          _selectedAddress = address;
          _selectedState = state;
        });
      } else {
        setState(() {
          _selectedAddress =
          'Address not found for this location';
          _selectedState = '';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _selectedAddress =
        'Unable to find address. Please check your internet connection.';
        _selectedState = '';
      });

      debugPrint(
        'Nominatim error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAddress = false;
        });
      }
    }
  }

  String _standardizeMalaysiaState(
      String state,
      Map<String, dynamic> addressData,
      ) {
    final String value =
    state.toLowerCase().trim();


    if (value.contains('kuala lumpur')) {
      return 'Kuala Lumpur';
    }


    if (value.contains('putrajaya')) {
      return 'Putrajaya';
    }

    if (value.contains('labuan')) {
      return 'Labuan';
    }


    if (value.contains('johor')) {
      return 'Johor';
    }

    if (value.contains('kedah')) {
      return 'Kedah';
    }


    if (value.contains('kelantan')) {
      return 'Kelantan';
    }


    if (value.contains('melaka') ||
        value.contains('malacca')) {
      return 'Melaka';
    }


    if (value.contains('negeri sembilan')) {
      return 'Negeri Sembilan';
    }


    if (value.contains('pahang')) {
      return 'Pahang';
    }


    if (value.contains('penang') ||
        value.contains('pulau pinang')) {
      return 'Penang';
    }


    if (value.contains('perak')) {
      return 'Perak';
    }


    if (value.contains('perlis')) {
      return 'Perlis';
    }


    if (value.contains('sabah')) {
      return 'Sabah';
    }

    if (value.contains('sarawak')) {
      return 'Sarawak';
    }


    if (value.contains('selangor')) {
      return 'Selangor';
    }


    if (value.contains('terengganu')) {
      return 'Terengganu';
    }


    return state.trim();
  }

  void _selectLocation(
      LatLng point,
      ) {
    setState(() {
      _selectedLocation = point;
    });

    _getAddressFromLocation(point);
  }

  void _confirmLocation() {
    if (_loadingAddress) {
      return;
    }

    if (_selectedAddress ==
        'Tap on the map to select an address' ||
        _selectedAddress ==
            'Finding address...') {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an address first.',
          ),
        ),
      );

      return;
    }

    if (_selectedState.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'State could not be detected. Please select another location.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      SelectedLocation(
        address: _selectedAddress,
        state: _selectedState,
        latitude:
        _selectedLocation.latitude,
        longitude:
        _selectedLocation.longitude,
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Address',
        ),
      ),

      body: Stack(
        children: [

          FlutterMap(
            mapController:
            _mapController,

            options: MapOptions(
              initialCenter:
              _selectedLocation,
              initialZoom: 10,

              onTap: (
                  tapPosition,
                  point,
                  ) {
                _selectLocation(
                  point,
                );
              },
            ),

            children: [

              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.example.assignment',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point:
                    _selectedLocation,
                    width: 50,
                    height: 50,
                    child:
                    const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),


              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),


          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () {
                    final zoom =
                        _mapController
                            .camera
                            .zoom;

                    _mapController.move(
                      _mapController
                          .camera
                          .center,
                      zoom + 1,
                    );
                  },
                  child:
                  const Icon(
                    Icons.add,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () {
                    final zoom =
                        _mapController
                            .camera
                            .zoom;

                    _mapController.move(
                      _mapController
                          .camera
                          .center,
                      zoom - 1,
                    );
                  },
                  child:
                  const Icon(
                    Icons.remove,
                  ),
                ),
              ],
            ),
          ),


          Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: Card(
              elevation: 5,
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _loadingAddress
                          ? const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                            ),
                          ),

                          SizedBox(
                            width: 10,
                          ),

                          Text(
                            'Finding address...',
                          ),
                        ],
                      )
                          : Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            _selectedAddress,
                            style:
                            const TextStyle(
                              fontSize:
                              14,
                            ),
                          ),

                          if (_selectedState
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              'State: $_selectedState',
                              style:
                              const TextStyle(
                                fontSize:
                                14,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                _loadingAddress
                    ? null
                    : _confirmLocation,
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}