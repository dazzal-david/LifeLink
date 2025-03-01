import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeekOrganScreen extends StatefulWidget {
  const SeekOrganScreen({Key? key}) : super(key: key);

  @override
  _SeekOrganScreenState createState() => _SeekOrganScreenState();
}

class _SeekOrganScreenState extends State<SeekOrganScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _locationController = TextEditingController(); // New controller for location
  
  String _selectedOrgan = 'All';
  String _selectedBloodType = 'All';
  List<Map<String, dynamic>> _donors = [];
  bool _isLoading = false;
  bool _showLocationSuggestions = false; // Control suggestion list visibility
  
  final List<String> _organTypes = [
    'All',
    'Lungs (Lobe)',
    'Liver',
    'Kidneys',
    'Pancreas',
    'Intestines',
    'Blood & Plasma',
    'Bone & Cartilage',
    'Bone marrow',
  ];
  
  final List<String> _locations = [
    'Thrissur',
    'Kochi',
    'Palakkad',
    'Ottapalam',
    'Thiruvananthapuram',
    // Add more locations as needed
  ];

  final List<String> _bloodTypes = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('organ_donors')
          .select('''
            id,
            organs,
            location,
            contact,
            created_at,
            user_id,
            consent,
            blood_type
          ''')
          .eq('consent', true);
      
      if (mounted) {
        setState(() {
          _donors = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<String> _getFilteredLocations(String query) {
    return _locations.where((location) =>
        location.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<Map<String, dynamic>> _getFilteredDonors() {
    return _donors.where((donor) {
      // Filter by search term (if any)
      final searchMatch = _searchController.text.isEmpty ||
          donor['location'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      // Filter by organ type
      final organMatch = _selectedOrgan == 'All' ||
          (donor['organs'] as List).contains(_selectedOrgan);
      
      // Filter by location
      final locationMatch = _locationController.text.isEmpty ||
          donor['location'].toString().toLowerCase().contains(_locationController.text.toLowerCase());
      
      // Filter by blood type
      final bloodTypeMatch = _selectedBloodType == 'All' ||
          donor['blood_type'] == _selectedBloodType;
      
      return searchMatch && organMatch && locationMatch && bloodTypeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDonors = _getFilteredDonors();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Organ Donors'),
        backgroundColor: Colors.teal,
      ),
      body: GestureDetector(
        onTap: () {
          // Hide location suggestions when tapping outside
          setState(() {
            _showLocationSuggestions = false;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              
              // Filter options
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organ Type:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedOrgan,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _organTypes.map((organ) {
                            return DropdownMenuItem(
                              value: organ,
                              child: Text(organ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOrgan = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Location with autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Type to search location...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: _locationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _locationController.clear();
                                  _showLocationSuggestions = false;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _showLocationSuggestions = value.isNotEmpty;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _showLocationSuggestions = _locationController.text.isNotEmpty;
                      });
                    },
                  ),
                  if (_showLocationSuggestions)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _getFilteredLocations(_locationController.text)
                            .map((location) => ListTile(
                                  title: Text(location),
                                  onTap: () {
                                    setState(() {
                                      _locationController.text = location;
                                      _showLocationSuggestions = false;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              
              // Blood type filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blood Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedBloodType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _bloodTypes.map((bloodType) {
                      return DropdownMenuItem(
                        value: bloodType,
                        child: Text(bloodType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodType = value!;
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Results count
              Text(
                'Found ${filteredDonors.length} potential donors',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Donor list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDonors.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching donors found',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredDonors.length,
                            itemBuilder: (context, index) {
                              final donor = filteredDonors[index];
                              final organs = (donor['organs'] as List).join(', ');
                              
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    'Available Organs: $organs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16),
                                          const SizedBox(width: 4),
                                          Text(donor['location']),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Blood Type: ${donor['blood_type']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Registered: ${_formatDate(donor['created_at'])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _contactDonor(donor),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Contact'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchDonors,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _contactDonor(Map<String, dynamic> donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: ${donor['contact']}'),
            const SizedBox(height: 12),
            const Text(
              'Important: All organ donation processes must be conducted through proper medical channels. This contact information is provided for initial inquiry only.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would implement the actual contact functionality
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('Proceed to Contact'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}