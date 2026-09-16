import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A customizable input field widget that interfaces with the Google Places API
/// to provide real-time address and city autocomplete suggestions.
class AddressSearchField extends StatefulWidget {
  /// Callback triggered when a user successfully selects a location from predictions.
  final Function(String fullAddress, String city, double lat, double lng)
      onAddressSelected;

  /// Determines whether predictions should be restricted to cities only.
  final bool isCityOnly;

  const AddressSearchField({
    super.key,
    required this.onAddressSelected,
    this.isCityOnly = false,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _controller = TextEditingController();
  List<dynamic> _predictions = [];
  bool _isLoading = false;

  // Google Maps API Key retrieved from environment variables
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Fetches autocomplete address predictions from the Google Places API based on user input.
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String typeFilter = widget.isCityOnly ? "(cities)" : "address";

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$query'
            '&types=$typeFilter'
            '&components=country:il'
            '&language=iw'
            '&key=$_googleApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _predictions = data['predictions'];
          });
        } else {
          setState(() {
            _predictions = [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches geographic coordinates and address components for a selected prediction place ID.
  Future<void> _getPlaceDetails(String placeId, String description) async {
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=geometry,address_components'
            '&key=$_googleApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];

          String extractedCity = "";
          final addressComponents =
              result['address_components'] as List<dynamic>;
          for (var component in addressComponents) {
            final types = component['types'] as List<dynamic>;
            if (types.contains('locality')) {
              extractedCity = component['long_name'];
              break;
            }
          }

          if (extractedCity.isEmpty) {
            extractedCity = description.split(',')[0];
          }

          _controller.text = description;
          setState(() {
            _predictions = [];
          });

          widget.onAddressSelected(description, extractedCity, lat, lng);
        }
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          controller: _controller,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText:
                widget.isCityOnly ? 'הקלד עיר...' : 'הקלד כתובת עסק מלאה...',
            hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _predictions = [];
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                  color: isDark ? Colors.transparent : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                  color: isDark ? Colors.transparent : Colors.grey.shade300),
            ),
          ),
          onChanged: _searchAddress,
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];

                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      prediction['description'],
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black),
                      textDirection: TextDirection.rtl,
                    ),
                    onTap: () => _getPlaceDetails(
                        prediction['place_id'], prediction['description']),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
