import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleHospitalSearchScreen extends StatefulWidget {
  const SimpleHospitalSearchScreen({Key? key}) : super(key: key);

  @override
  _SimpleHospitalSearchScreenState createState() => _SimpleHospitalSearchScreenState();
}

class _SimpleHospitalSearchScreenState extends State<SimpleHospitalSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _hospitals = [];

  // This would come from your secure configuration
  static const String _googleApiKey = 'AIzaSyDUdmED_YAApTax2-EKLgkrW4v5WozPTDg';

  Future<void> _searchHospitals(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=hospitals+in+$query'
        '&type=hospital'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);
        
        // Get basic details for each hospital
        final hospitals = await Future.wait(
          results.map((place) async {
            // Only fetch phone number if place_id is available
            String? phoneNumber;
            if (place['place_id'] != null) {
              phoneNumber = await _getPhoneNumber(place['place_id']);
            }
            
            return {
              'name': place['name'],
              'address': place['formatted_address'],
              'phone': phoneNumber,
            };
          }),
        );

        setState(() {
          _hospitals = hospitals;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch hospitals');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<String?> _getPhoneNumber(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=formatted_phone_number'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result']['formatted_phone_number'];
      }
    } catch (e) {
      print('Error fetching phone number: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Search'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter location to find hospitals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _hospitals.clear();
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) => _searchHospitals(value),
            ),
            
            const SizedBox(height: 16),
            
            // Results count
            if (_hospitals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Found ${_hospitals.length} hospitals',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            
            // Loading indicator or results
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _hospitals.isEmpty 
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                          ? 'Enter a location to search for hospitals'
                          : 'No hospitals found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _hospitals.length,
                      itemBuilder: (context, index) {
                        final hospital = _hospitals[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              hospital['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(hospital['address']),
                                if (hospital['phone'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    hospital['phone'],
                                    style: const TextStyle(
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}