import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleDoctorSearchScreen extends StatefulWidget {
  const SimpleDoctorSearchScreen({Key? key}) : super(key: key);

  @override
  _SimpleDoctorSearchScreenState createState() => _SimpleDoctorSearchScreenState();
}

class _SimpleDoctorSearchScreenState extends State<SimpleDoctorSearchScreen> {
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _isLoading = false;
  bool _isLoaded = false;
  List<Map<String, dynamic>> _doctors = [];

  // Move this to secure configuration in production
  static const String _googleApiKey = 'AIzaSyDUdmED_YAApTax2-EKLgkrW4v5WozPTDg';

  // Predefined list of medical specialties
  final List<String> _specialties = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedist',
    'Gynecologist',
    'Psychiatrist',
    'Dentist',
    'Ophthalmologist',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  Future<void> _searchDoctors() async {
    final location = _locationController.text;
    final specialty = _specialtyController.text;
    
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final searchQuery = specialty.isNotEmpty 
          ? '$specialty doctor in $location'
          : 'doctors in $location';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(searchQuery)}'
        '&type=doctor'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);
        
        // Get detailed information for each doctor
        final doctors = await Future.wait(
          results.map((place) async {
            final details = await _getDoctorDetails(place['place_id']);
            return {
              'name': place['name'],
              'address': place['formatted_address'],
              'rating': place['rating']?.toString() ?? 'Not rated',
              'phone': details['phone'],
              'website': details['website'],
              'specialty': specialty.isNotEmpty ? specialty : 'Doctor',
              'open_now': place['opening_hours']?['open_now'],
            };
          }),
        );

        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch doctors');
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

  Future<Map<String, dynamic>> _getDoctorDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=formatted_phone_number,website,reviews'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'phone': data['result']['formatted_phone_number'],
          'website': data['result']['website'],
          'reviews': data['result']['reviews'],
        };
      }
    } catch (e) {
      print('Error fetching doctor details: $e');
    }
    return {'phone': null, 'website': null, 'reviews': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF009688),
              size: 18,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Doctor Search',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildSpecialtySelector(),
                    const SizedBox(height: 16),
                    _buildLocationSearchBox(),
                    const SizedBox(height: 24),
                    _buildResultsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuad,
      transform: Matrix4.translationValues(
        0, 
        _isLoaded ? 0 : 30, 
        0
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _isLoaded ? 1.0 : 0.0,
        child: Container(
          width: double.infinity,
          height: 180,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1505751172876-fa1923c5c528?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Find Doctors Nearby',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Search for specialized doctors in your area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtySelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuad,
      transform: Matrix4.translationValues(
        0, 
        _isLoaded ? 0 : 30, 
        0
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _isLoaded ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _specialties.where((String option) {
                return option.toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _specialtyController.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Select specialty (optional)',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF009688),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xFF009688),
                    ),
                    onPressed: () {
                      controller.clear();
                      _specialtyController.clear();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSearchBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuad,
      transform: Matrix4.translationValues(
        0, 
        _isLoaded ? 0 : 30, 
        0
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _isLoaded ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Enter location to find doctors...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.location_on,
                color: Color(0xFF009688),
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF009688),
                ),
                onPressed: _searchDoctors,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _searchDoctors(),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuad,
        transform: Matrix4.translationValues(
          0, 
          _isLoaded ? 0 : 30, 
          0
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _isLoaded ? 1.0 : 0.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_doctors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Found ${_doctors.length} doctors',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
                      ),
                    )
                  : _doctors.isEmpty 
                    ? Center(
                        child: Text(
                          _locationController.text.isEmpty
                            ? 'Enter a location to search for doctors'
                            : 'No doctors found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          doctor['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                      ),
                                      if (doctor['rating'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF009688).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Color(0xFF009688),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                doctor['rating'],
                                                style: const TextStyle(
                                                  color: Color(0xFF009688),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF009688).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      doctor['specialty'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF009688),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    doctor['address'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (doctor['phone'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          doctor['phone'],
                                          style: const TextStyle(
                                            color: Color(0xFF009688),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (doctor['website'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.language,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            doctor['website'],
                                            style: const TextStyle(
                                              color: Color(0xFF009688),
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (doctor['open_now'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: doctor['open_now']
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          doctor['open_now'] ? 'Open now' : 'Closed',
                                          style: TextStyle(
                                            color: doctor['open_now']
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }
}