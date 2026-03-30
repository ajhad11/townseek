import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'location_page.dart';
import '../services/osm_service.dart';
import '../utils/time_helper.dart';
import 'dart:async'; // Added for Timer
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class BusinessEditPage extends StatefulWidget {
  final Map<String, dynamic>? shopToEdit;
  const BusinessEditPage({super.key, this.shopToEdit});

  @override
  State<BusinessEditPage> createState() => _BusinessEditPageState();
}

class _BusinessEditPageState extends State<BusinessEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(); // Added location controller
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _googleMapLinkController =
      TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Added Email Controller

  dynamic _selectedImage;
  bool _isLoading = false;

  // Working Days (0=Sunday, 6=Saturday)
  // Default to Mon-Fri (1,2,3,4,5) or All Days? Let's default to Mon-Sat (1-6)
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6};

  // Dropdown value
  String _selectedCategory = 'Groceries';
  final List<String> _categories = [
    'Groceries',
    'Food',
    'Fashion',
    'Health',
    'Services',
    'Finance',
    'Animals',
    'Education',
    'Religious',
    'Entertainment',
    'Public Services',
    'Commercial',
    'Hospital',
  ];

  // Tags Navigation State
  final Set<String> _selectedTags = {};
  final List<String> _customTags = []; // Store user-added tags
  final Set<String> _selectedSubCategories =
      {}; // Tracks expanded sub-categories

  // Common tags shown everywhere at the bottom
  final List<String> _commonTags = [
    'Parking',
    'Street parking',
    'Delivery',
    'Wifi',
    'Offer',
  ];

  // Main level tags for each category (These act as sub-categories when they have children)
  final Map<String, List<String>> _categoryTags = {
    'Groceries': [
      'Vegetables',
      'Fruits',
      'Bakery',
      'Frozen',
      'Snacks',
      'Beverages',
      'Spices',
      'Organic',
      'Delivery',
    ],
    'Food': [
      'Dine In',
      'Take Away',
      'Cafe',
      'Fast Food',
      'Restaurant',
      'Bakery',
      'Vegetarian',
      'Non-Veg',
      'Coffee',
      'Delivery',
    ],
    'Fashion': [
      'Men',
      'Women',
      'Kids',
      'Shoes',
      'Accessories',
      'Formal',
      'Casual',
      'Traditional',
      'Sale',
      'Sustainable',
    ],
    'Health': [
      'Pharmacy',
      'Clinic',
      'Hospital',
      'Gym',
      'Dental',
      'Ayurveda',
      'Opticals',
      'Lab',
      'Doctors',
      'Emergency',
    ],
    'Services': [
      'Repair',
      'Cleaning',
      'Plumbing',
      'Electrical',
      'Carpentry',
      'Mechanic',
      'Laundry',
      'Salon',
      'Tailor',
      'Rental',
    ],
    'Finance': [
      'ATM',
      'Loan',
      'Insurance',
      'Investment',
      'Tax',
      'Consulting',
      'Exchange',
    ],
    'Animals': [
      'Vet',
      'Grooming',
      'Pet Food',
      'Accessories',
      'Boarding',
      'Training',
      'Rescue',
    ],
    'Education': [
      'Tutoring',
      'Courses',
      'Language',
      'Music',
      'Arts',
      'Sports',
      'Consulting',
      'Library',
    ],
    'Religious': ['Temple', 'Mosque', 'Church', 'Books', 'Items'],
    'Entertainment': [
      'Cinema',
      'Gaming',
      'Amusement Park',
      'Bowling',
      'Theater',
      'Sports',
      'Events',
      'Music',
    ],
    'Public Services': [
      'Government',
      'Post Office',
      'Police',
      'Fire Station',
      'Library',
      'Community Center',
      'Court',
    ],
    'Commercial': [
      'Office',
      'Coworking',
      'Warehouse',
      'Wholesale',
      'Factory',
      'B2B',
      'Agency',
    ],
    'Hospital': [
      'Emergency',
      'Pharmacy',
      'OPD',
      'Maternity',
      'ICU',
      'Pediatrics',
    ],
  };

  // Specific tags mapped to Sub-categories
  final Map<String, List<String>> _subCategoryMap = {
    // Services
    'Repair': ['Mobile', 'Laptop', 'Appliance', 'AC', 'TV', 'Automobile'],
    'Cleaning': ['Home', 'Office', 'Car', 'Sofa', 'Deep Cleaning'],
    'Tailor': ['Stitching', 'Alteration', 'Men', 'Women', 'Kids'],
    'Rental': ['Car', 'Bike', 'Costume', 'Equipment', 'House'],
    'Salon': ['Haircut', 'Spa', 'Facial', 'Makeup', 'Massage'],
    // Food
    'Restaurant': [
      'Indian',
      'Chinese',
      'Italian',
      'Mexican',
      'Seafood',
      'Buffet',
    ],
    'Cafe': ['Smoothies', 'Pastries', 'Desserts', 'Tea'],
    // Fashion
    'Men': ['Shirts', 'T-Shirts', 'Trousers', 'Jeans', 'Suits', 'Ethnic'],
    'Women': ['Dresses', 'Tops', 'Sarees', 'Kurtis', 'Bridal', 'Lingerie'],
    'Shoes': ['Sneakers', 'Formal', 'Heels', 'Boots', 'Sandals'],
    // Health
    'Clinic': [
      'General Physician',
      'Pediatrician',
      'Dermatologist',
      'Orthopedic',
    ],
    'Hospital': ['Cardiology', 'Neurology', 'Oncology', 'Private Room'],
  };

  TimeOfDay? _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _closeTime = const TimeOfDay(hour: 21, minute: 0);
  bool _is24Hours = false;

  // Coordinates
  double? _selectedLat;
  double? _selectedLng;

  // Edit Mode State
  String? _existingImageUrl;

  // Autocomplete State
  final OSMService _osmService = OSMService();
  List<OSMPlace> _locationSuggestions = [];
  Timer? _debounceTimer;
  bool _isLoadingSuggestions = false;
  bool _isFetchingLocation = false; // Added to prevent search triggers during GPS fetch

  // Doctor Management State
  final List<Map<String, dynamic>> _doctorsCache = [];

  // Hospital Departments State
  final Map<String, int> _selectedHospitalDeptExperts = {};
  final List<String> _hospitalDepartmentsList = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Dermatology',
    'General Medicine',
    'Gynecology',
    'Oncology',
    'ENT',
    'Psychiatry',
    'Urology',
    'Gastroenterology',
    'Radiology',
    'Anesthesiology',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.shopToEdit != null) {
      final shop = widget.shopToEdit!;
      _shopNameController.text = shop['name'] ?? '';
      _descriptionController.text = shop['description'] ?? '';
      _addressController.text = shop['address'] ?? '';
      _mobileNumberController.text = shop['phone'] ?? shop['mobile'] ?? '';
      _emailController.text = shop['email'] ?? '';
      _googleMapLinkController.text = shop['google_map_link'] ?? '';
      _locationController.text = shop['location'] ?? '';
      _existingImageUrl = shop['image_url'];

      // Category mapping
      String dbCat = (shop['category'] ?? '').toString().toLowerCase().replaceAll(' ', '');
      for (String displayCat in _categories) {
        if (displayCat.toLowerCase().replaceAll(' ', '') == dbCat) {
          _selectedCategory = displayCat;
          break;
        }
      }

      // Lat/Lng
      _selectedLat = (shop['latitude'] as num?)?.toDouble();
      _selectedLng = (shop['longitude'] as num?)?.toDouble();

      // Tags
      if (shop['tags'] != null) {
        dynamic tagsData = shop['tags'];
        List<dynamic> tags = [];
        if (tagsData is List) {
          tags = tagsData;
        } else if (tagsData is String) {
          try {
            if (tagsData.startsWith('{') && tagsData.endsWith('}')) {
               String inner = tagsData.substring(1, tagsData.length - 1);
               if (inner.isNotEmpty) tags = inner.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
            } else if (tagsData.startsWith('[') && tagsData.endsWith(']')) {
               tags = jsonDecode(tagsData) as List<dynamic>;
            } else {
               tags = [tagsData];
            }
          } catch (_) {}
        }
        for (var t in tags) {
          _selectedTags.add(t.toString());
        }

        // Auto-expand sub-categories if specific tags are present
        final preset = _categoryTags[_selectedCategory] ?? [];
        for (var t in _selectedTags) {
          if (preset.contains(t) && _subCategoryMap.containsKey(t)) {
            _selectedSubCategories.add(t); // Top-level sub-category selected
          } else if (!preset.contains(t) && !_commonTags.contains(t)) {
            // Check if it's a specific tag
            bool isSpecific = false;
            _subCategoryMap.forEach((parent, children) {
              if (children.contains(t)) {
                isSpecific = true;
                _selectedSubCategories.add(parent);
              }
            });

            // If not a specific tag either, it must be custom
            if (!isSpecific) {
              _customTags.add(t);
            }
          }
        }
      }

      // Times
      final openStr = shop['opening_time'] as String?;
      final closeStr = shop['closing_time'] as String?;
      if (openStr != null && closeStr != null) {
        _is24Hours = TimeHelper.is24Hours(openStr, closeStr);
        if (_is24Hours) {
          _openTime = const TimeOfDay(hour: 0, minute: 0);
          _closeTime = const TimeOfDay(hour: 23, minute: 59);
        } else {
          final now = DateTime.now();
          final openDt = TimeHelper.parseTime(openStr, now);
          final closeDt = TimeHelper.parseTime(closeStr, now);
          if (openDt != null) _openTime = TimeOfDay.fromDateTime(openDt);
          if (closeDt != null) _closeTime = TimeOfDay.fromDateTime(closeDt);
        }
      }

      // Working Days
      if (shop['working_days'] != null) {
        dynamic wdData = shop['working_days'];
        List<dynamic> wd = [];
        if (wdData is List) {
          wd = wdData;
        } else if (wdData is String) {
          try {
             wd = jsonDecode(wdData) as List<dynamic>;
          } catch (_) {}
        }
        
        if (wd.isNotEmpty) {
          _selectedDays.clear();
          for (var d in wd) {
            if (d is Map && d['day_of_week'] is int) {
              _selectedDays.add(d['day_of_week'] as int);
            }
          }
        }
      }

      if (_selectedCategory == 'Hospital') {
        _loadHospitalDepartments(shop['id']);
      }
    }
  }

  Future<void> _loadHospitalDepartments(String shopId) async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('department, expert')
          .eq('shop_id', shopId);

      if (mounted) {
        setState(() {
          for (var row in response) {
            final dept = row['department'].toString();
            final count = row['expert'] != null
                ? int.tryParse(row['expert'].toString()) ?? 1
                : 1;
            _selectedHospitalDeptExperts[dept] = count;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading hospital departments: $e');
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _locationController.dispose(); // Dispose location controller
    _customTagController.dispose();
    _googleMapLinkController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _debounceTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
        });
      } else {
        setState(() {
          _selectedImage = io.File(image.path);
        });
      }
    }
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2962FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_openTime == null || _closeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select opening and closing times'),
          ),
        );
        return;
      }

      if (_selectedLat == null || _selectedLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a precise location from the map or suggestions dropdown',
            ),
          ),
        );
        return;
      }

      if (_locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the location area search term'),
          ),
        );
        return;
      }

      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one working day'),
          ),
        );
        return;
      }

      if (_selectedCategory.toLowerCase() == 'hospital') {
        if (_selectedHospitalDeptExperts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select at least one department for the hospital',
              ),
            ),
          );
          return;
        }
        if (_doctorsCache.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add at least one doctor for the hospital'),
            ),
          );
          return;
        }
      }
      if (_selectedTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one descriptive tag'),
          ),
        );
        return;
      }

      // Show loading indicator? For now, just blocking interaction via Future not implemented but good enough.

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to add a business'),
            ),
          );
          return;
        }

        // Format times before async operations to avoid BuildContext across gaps
        final String openingTimeStr = _openTime!.format(context);
        final String closingTimeStr = _closeTime!.format(context);

        // Prepare data
        // If no image is selected, save as an empty string to trigger symbol generation
        String imageUrl = _existingImageUrl ?? '';

        if (_selectedImage != null) {
          try {
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
            final String path = 'uploads/$fileName';

            if (kIsWeb) {
              await Supabase.instance.client.storage
                  .from('shop-images')
                  .uploadBinary(path, _selectedImage as Uint8List);
            } else {
              await Supabase.instance.client.storage
                  .from('shop-images')
                  .upload(path, _selectedImage as io.File);
            }

            imageUrl = Supabase.instance.client.storage
                .from('shop-images')
                .getPublicUrl(path);
          } catch (uploadError) {
            debugPrint('Error uploading image: $uploadError');
            // Proceed with default image or handle error?
            // For now, we'll proceed but maybe warn user?
            // Or better, failing to upload image might be critical for "Add Business".
            // Let's rethrow to show error in catch block below.
            throw 'Image upload failed: $uploadError';
          }
        }

        final Map<String, dynamic> shopData = {
          'name': _shopNameController.text.trim(),
          'address': _addressController.text.trim(),
          'description': _descriptionController.text.trim(),
          'phone': _mobileNumberController.text.trim(),
          'tags': _selectedTags.toList(),
          'image_url': imageUrl,
          'google_map_link': _googleMapLinkController.text.trim(),
          'opening_time': openingTimeStr,
          'closing_time': closingTimeStr,
          'category': _selectedCategory.toLowerCase().replaceAll(' ', ''),
          'latitude': _selectedLat,
          'longitude': _selectedLng,
          'location': _locationController.text.trim(),
          'email': _emailController.text.trim(),
          'owner_id': userId,
        };

        // If editing, use update; else insert
        List<dynamic> response;
        if (widget.shopToEdit != null) {
          response = await Supabase.instance.client
              .from('shops')
              .update(shopData)
              .eq('id', widget.shopToEdit!['id'])
              .select();
        } else {
          response = await Supabase.instance.client
              .from('shops')
              .insert(shopData)
              .select();
        }

        if (response.isNotEmpty) {
          final shopId = response[0]['id'];

          // Handle Working Days (Delete old, Insert new for simplicity)
          if (widget.shopToEdit != null) {
            await Supabase.instance.client
                .from('working_days')
                .delete()
                .eq('shop_id', shopId);
          }

          if (_selectedDays.isNotEmpty) {
            final List<Map<String, dynamic>> daysData = _selectedDays
                .map((day) => {'shop_id': shopId, 'day_of_week': day})
                .toList();

            await Supabase.instance.client
                .from('working_days')
                .insert(daysData);
          }

          // Handle Hospital Departments
          if (_selectedCategory.toLowerCase() == 'hospital') {
            if (widget.shopToEdit != null) {
              await Supabase.instance.client
                  .from('departments')
                  .delete()
                  .eq('shop_id', shopId);
            }
            if (_selectedHospitalDeptExperts.isNotEmpty) {
              final List<Map<String, dynamic>> deptData =
                  _selectedHospitalDeptExperts.entries
                      .map(
                        (entry) => {
                          'shop_id': shopId,
                          'department': entry.key,
                          'expert': entry.value,
                        },
                      )
                      .toList();

              debugPrint('--- [DEBUG] INSERTING HOSPITAL DEPARTMENTS ---');
              debugPrint('Payload: $deptData');

              await Supabase.instance.client
                  .from('departments')
                  .insert(deptData);
            }
          }

          // Handle Doctors
          if (_doctorsCache.isNotEmpty) {
            try {
              // Note: If editing, we might want to delete old doctors. But this is simple create.
              for (var doc in _doctorsCache) {
                // Ensure available_days is strictly List<String>
                List<String> validDays = [];
                if (doc['available_days'] != null &&
                    (doc['available_days'] as List).isNotEmpty) {
                  validDays = (doc['available_days'] as List)
                      .map((e) => e.toString())
                      .toList();
                }

                final doctorPayload = {
                  'shop_id': shopId,
                  'name': doc['name'].toString().trim(),
                  'department':
                      doc['department'], // Exact case match required for enum
                  if (validDays.isNotEmpty) 'available_days': validDays,
                  if (doc['booking_limit'] != null)
                    'booking_limit': doc['booking_limit'],
                };

                debugPrint('--- [DEBUG] INSERTING DOCTOR ---');
                debugPrint('Payload: $doctorPayload');

                final doctorResponse = await Supabase.instance.client
                    .from('doctors')
                    .insert(doctorPayload)
                    .select();

                if (doctorResponse.isNotEmpty) {
                  final newDocId = doctorResponse[0]['id'];

                  // Insert Qualification
                  if (doc['qualifications'] != null &&
                      doc['qualifications'].toString().isNotEmpty) {
                    // Let's split comma-separated qualifications into separate rows
                    final List<String> qualsList = doc['qualifications']
                        .toString()
                        .split(',');
                    final List<Map<String, dynamic>> qualDataList = qualsList
                        .map(
                          (q) => {
                            'doctor_id': newDocId,
                            'qualification': q.trim(),
                          },
                        )
                        .toList();
                    await Supabase.instance.client
                        .from('doctor_qualifications')
                        .insert(qualDataList);
                  }

                  // Insert Availability
                  if (doc['availability'] != null &&
                      (doc['availability'] as List).isNotEmpty) {
                    final List<Map<String, dynamic>> availData =
                        (doc['availability'] as List).map((a) {
                          dynamic dayVal = a['day_of_week'];
                          const dayNames = [
                            'Sunday',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                          ];

                          int parsedDay = 0;
                          if (dayVal is int) {
                            parsedDay = dayVal;
                          } else if (dayVal is String) {
                            final tryInt = int.tryParse(dayVal);
                            if (tryInt != null) {
                              parsedDay = tryInt;
                            } else {
                              final idx = dayNames.indexOf(dayVal);
                              if (idx != -1) parsedDay = idx;
                            }
                          }

                          return {
                            'doctor_id': newDocId,
                            'day_of_week': parsedDay,
                            'start_time': a['start_time'],
                            'end_time': a['end_time'],
                          };
                        }).toList();
                    await Supabase.instance.client
                        .from('doctor_availability')
                        .insert(availData);
                  }
                }
              }
            } catch (doctorError) {
              debugPrint('Doctor Insertion Error: $doctorError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Business saved, but failed to save doctor: $doctorError',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
                Navigator.pop(context); // Go back but user sees the snackbar
              }
              return; // Stop execution so we don't show the success snackbar below
            }
          }
        }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Business Added Successfully!')),
            );
            Navigator.pop(context);
          }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding business: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ... (dispose and existing methods) ...

  // ADD THIS AT THE BOTTOM OF CLASS or before build
  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? selectedTime,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime != null
                      ? selectedTime.format(context)
                      : 'Select Time',
                  style: TextStyle(
                    color: selectedTime != null ? Colors.black : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF2962FF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addCustomTag() {
    final newTag = _customTagController.text.trim();
    if (newTag.isNotEmpty) {
      setState(() {
        if (!_categoryTags[_selectedCategory]!.contains(newTag) &&
            !_customTags.contains(newTag)) {
          _customTags.add(newTag);
          _selectedTags.add(newTag); // Select it by default
        } else if (!_selectedTags.contains(newTag)) {
          // If already exists but not selected, select it
          _selectedTags.add(newTag);
        }
        _customTagController.clear();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingSuggestions = true;
      _isFetchingLocation = true; // Block suggestions
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save coordinates
      _selectedLat = position.latitude;
      _selectedLng = position.longitude;

      // Update map link
      _googleMapLinkController.text =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      // Reverse geocode to get a readable address
      final place = await _osmService.getPlaceAt(LatLng(position.latitude, position.longitude));
      
      if (place != null) {
         _locationController.text = place.cityCountry;
         if (_addressController.text.isEmpty) {
            _addressController.text = place.displayName;
         }
      } else {
         _locationController.text = "Current Location";
      }

      // FINAL RE-ASSERTION: Ensure coordinates and maps link are the EXACT GPS ones, 
      // not those of the town centre that Nominatim might return in the 'place' object.
      _selectedLat = position.latitude;
      _selectedLng = position.longitude;
      _googleMapLinkController.text =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _onLocationChanged(String query) {
    if (_isFetchingLocation) return; // Ignore changes from GPS fetch
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Do NOT clear precise coordinates if user types manually.
    // This allows users to tweak the location name after selecting it from the map.
    // _selectedLat = null;
    // _selectedLng = null;

    if (query.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoadingSuggestions = true;
      });

      try {
        final results = await _osmService.searchPlaces(query);
        if (mounted) {
          setState(() {
            _locationSuggestions = results;
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSuggestions = false;
            _locationSuggestions = [];
          });
        }
      }
    });
  }

  void _selectSuggestion(OSMPlace place) {
    setState(() {
      _locationController.text =
          place.cityCountry; // Use helper to get clean name
      _selectedLat = place.lat;
      _selectedLng = place.lon;
      _locationSuggestions = []; // Clear suggestions
      _isLoadingSuggestions = false;

      // Also update Google Maps link if empty
      if (_googleMapLinkController.text.isEmpty) {
        _googleMapLinkController.text =
            "https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lon}";
      }
    });
  }

  Widget _buildLocationAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Location (City/Place)'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _getCurrentLocation,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                height: 55, // Match height of TextFormField
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF2962FF),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
              TextFormField(
                controller: _locationController,
                onChanged: _onLocationChanged,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Location is required';
                  }
                  if (_selectedLat == null || _selectedLng == null) {
                    return 'Select a precise location from the suggestions or the map';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. Downtown, City Center',
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: _isLoadingSuggestions
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              ],
            ),
          ),
        ),
      ],
    ),
    if (_locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _locationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                  title: Text(
                    place.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _selectSuggestion(place),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildPremiumHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 100,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF2962FF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Basic Details",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // --- 1. Basic Details ---
                              _buildLabel('Shop Name'),
                              _buildTextField(
                                controller: _shopNameController,
                                hintText: 'Enter your shop name',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter shop name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Category'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue!;
                                        _selectedTags
                                            .clear(); // Clear tags on category change
                                        _customTags
                                            .clear(); // Clear custom tags too
                                      });
                                    },
                                    items: _categories
                                        .map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_selectedCategory.toLowerCase() ==
                                  'hospital') ...[
                                _buildLabel('Available Departments'),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: _hospitalDepartmentsList.map((
                                      String dept,
                                    ) {
                                      final isSelected =
                                          _selectedHospitalDeptExperts
                                              .containsKey(dept);
                                      return FilterChip(
                                        label: Text(
                                          dept,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedHospitalDeptExperts[dept] =
                                                  1; // Default to 1 expert
                                            } else {
                                              _selectedHospitalDeptExperts
                                                  .remove(dept);
                                            }
                                          });
                                        },
                                        selectedColor: const Color(0xFF2962FF),
                                        backgroundColor: const Color(
                                          0xFFF8F9FA,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? const Color(0xFF2962FF)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        showCheckmark: false,
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // Experts counters for selected departments
                                if (_selectedHospitalDeptExperts
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildLabel('Number of Specialists'),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: _selectedHospitalDeptExperts.entries.map((
                                        entry,
                                      ) {
                                        final dept = entry.key;
                                        final expertsCount = entry.value;

                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade100,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dept,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  // Minus button
                                                  InkWell(
                                                    onTap: expertsCount > 1
                                                        ? () {
                                                            setState(() {
                                                              _selectedHospitalDeptExperts[dept] =
                                                                  expertsCount -
                                                                  1;
                                                            });
                                                          }
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: expertsCount > 1
                                                            ? Colors
                                                                  .grey
                                                                  .shade100
                                                            : Colors
                                                                  .grey
                                                                  .shade50,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 16,
                                                        color: expertsCount > 1
                                                            ? Colors.black87
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                    ),
                                                  ),

                                                  // Count display
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    width: 24,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      expertsCount.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),

                                                  // Plus button
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedHospitalDeptExperts[dept] =
                                                            expertsCount + 1;
                                                      });
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 16,
                                                        color: Color(
                                                          0xFF2962FF,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                              ],

                              _buildLabel('Description'),
                              _buildTextField(
                                controller: _descriptionController,
                                hintText: 'e.g. "Best organic grocery in town"',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Contact & Location Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF2962FF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Contact & Location",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Mobile Number'),
                              _buildTextField(
                                controller: _mobileNumberController,
                                hintText: 'Enter 10-digit mobile number',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  if (value.length != 10 ||
                                      int.tryParse(value) == null) {
                                    return 'Please enter a valid 10-digit number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Email Address'),
                              _buildTextField(
                                controller: _emailController,
                                hintText: 'e.g. shop@example.com',
                              ),
                              const SizedBox(height: 16),
                              _buildLocationAutocompleteField(),
                              const SizedBox(height: 16),

                              _buildLabel('Map Link'),
                              _buildTextField(
                                controller: _googleMapLinkController,
                                hintText: 'e.g. https://maps.app.goo.gl/...',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LocationPage(
                                          isSelecting: true,
                                          initialQuery: _locationController.text
                                              .trim(), // Pass location query
                                        ),
                                      ),
                                    );

                                    if (result != null && result is OSMPlace) {
                                      setState(() {
                                        // Create a Google Maps link using the coordinates
                                        // Format: https://www.google.com/maps/search/?api=1&query=lat,lng
                                        final link =
                                            "https://www.google.com/maps/search/?api=1&query=${result.lat},${result.lon}";
                                        _googleMapLinkController.text = link;

                                        if (_addressController.text.isEmpty) {
                                          _addressController.text =
                                              result.displayName;
                                        }
                                        if (_locationController.text.isEmpty) {
                                          _locationController.text =
                                              result.displayName;
                                        }

                                        // Save coordinates
                                        _selectedLat = result.lat;
                                        _selectedLng = result.lon;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('Select location on map'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2962FF),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildLabel('Address'),
                              _buildTextField(
                                controller: _addressController,
                                hintText: 'Enter full address manually',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Tags Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.sell_outlined,
                                      color: Color(0xFF2962FF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Search Tags",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Select Tags'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Sub-categories (Main tags for this category)
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: (_categoryTags[_selectedCategory] ?? []).map((
                                        String tag,
                                      ) {
                                        final isSelected = _selectedTags
                                            .contains(tag);
                                        final hasChildren = _subCategoryMap
                                            .containsKey(tag);
                                        final isExpanded =
                                            _selectedSubCategories.contains(
                                              tag,
                                            );

                                        return FilterChip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                tag,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              if (hasChildren) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                            .keyboard_arrow_down,
                                                  size: 16,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                                ),
                                              ],
                                            ],
                                          ),
                                          selected: isSelected,
                                          onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedTags.add(tag);
                                                if (hasChildren) {
                                                  _selectedSubCategories.add(
                                                    tag,
                                                  );
                                                }
                                              } else {
                                                _selectedTags.remove(tag);
                                                if (hasChildren) {
                                                  _selectedSubCategories.remove(
                                                    tag,
                                                  );
                                                  // Remove child tags if parent untoggled
                                                  final children =
                                                      _subCategoryMap[tag] ??
                                                      [];
                                                  _selectedTags.removeAll(
                                                    children,
                                                  );
                                                }
                                              }
                                            });
                                          },
                                          selectedColor: const Color(
                                            0xFF2962FF,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF8F9FA,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF2962FF)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          showCheckmark: false,
                                        );
                                      }).toList(),
                                    ),

                                    // 2. Specific Tags (Only show for expanded sub-categories)
                                    if (_selectedSubCategories.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade100,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Specific Tags",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8.0,
                                              runSpacing: 4.0,
                                              children: _selectedSubCategories.expand((
                                                subCat,
                                              ) {
                                                final children =
                                                    _subCategoryMap[subCat] ??
                                                    [];
                                                return children.map((
                                                  String childTag,
                                                ) {
                                                  final isChildSelected =
                                                      _selectedTags.contains(
                                                        childTag,
                                                      );
                                                  return FilterChip(
                                                    label: Text(
                                                      childTag,
                                                      style: TextStyle(
                                                        color: isChildSelected
                                                            ? Colors.white
                                                            : Colors.black87,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    selected: isChildSelected,
                                                    onSelected: (bool selected) {
                                                      setState(() {
                                                        selected
                                                            ? _selectedTags.add(
                                                                childTag,
                                                              )
                                                            : _selectedTags
                                                                  .remove(
                                                                    childTag,
                                                                  );
                                                      });
                                                    },
                                                    selectedColor:
                                                        Colors.blue.shade600,
                                                    backgroundColor:
                                                        const Color(0xFFF8F9FA),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      side: BorderSide(
                                                        color: isChildSelected
                                                            ? Colors
                                                                  .blue
                                                                  .shade600
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                    ),
                                                    showCheckmark: false,
                                                  );
                                                });
                                              }).toList(),
                                            ),
                                            // Render custom tags here if a subcategory is selected
                                            if (_customTags.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8.0,
                                                runSpacing: 4.0,
                                                children: _customTags.map((
                                                  String tag,
                                                ) {
                                                  final isSelected =
                                                      _selectedTags.contains(
                                                        tag,
                                                      );
                                                  return FilterChip(
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          tag,
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _customTags
                                                                  .remove(tag);
                                                              _selectedTags
                                                                  .remove(tag);
                                                            });
                                                          },
                                                          child: Icon(
                                                            Icons.close,
                                                            size: 14,
                                                            color: isSelected
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    selected: isSelected,
                                                    onSelected:
                                                        (bool selected) {
                                                          setState(() {
                                                            selected
                                                                ? _selectedTags
                                                                      .add(tag)
                                                                : _selectedTags
                                                                      .remove(
                                                                        tag,
                                                                      );
                                                          });
                                                        },
                                                    selectedColor:
                                                        Colors.blue.shade600,
                                                    backgroundColor:
                                                        const Color(0xFFF8F9FA),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      side: BorderSide(
                                                        color: isSelected
                                                            ? Colors
                                                                  .blue
                                                                  .shade600
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                    ),
                                                    showCheckmark: false,
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],

                                    const Divider(height: 24),

                                    // 3. Common/Global Tags & Custom Tags (fallback)
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children:
                                          [
                                            ..._commonTags,
                                            if (_selectedSubCategories.isEmpty)
                                              ..._customTags,
                                          ].map((String tag) {
                                            final isSelected = _selectedTags
                                                .contains(tag);
                                            final isCustom = _customTags
                                                .contains(tag);
                                            return FilterChip(
                                              label: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    tag,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (isCustom) ...[
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _customTags.remove(
                                                            tag,
                                                          );
                                                          _selectedTags.remove(
                                                            tag,
                                                          );
                                                        });
                                                      },
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: isSelected
                                                            ? Colors.white70
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              selected: isSelected,
                                              onSelected: (bool selected) {
                                                setState(() {
                                                  selected
                                                      ? _selectedTags.add(tag)
                                                      : _selectedTags.remove(
                                                          tag,
                                                        );
                                                });
                                              },
                                              selectedColor:
                                                  Colors.orange.shade700,
                                              backgroundColor: const Color(
                                                0xFFF8F9FA,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? Colors.orange.shade700
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              showCheckmark: false,
                                            );
                                          }).toList(),
                                    ),

                                    const SizedBox(height: 12),
                                    // Custom Tag Input
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: TextField(
                                              controller: _customTagController,
                                              decoration: const InputDecoration(
                                                hintText: 'Add custom tag...',
                                                hintStyle: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                                border: OutlineInputBorder(
                                                  // Simple border
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 0,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              onSubmitted: (_) =>
                                                  _addCustomTag(),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _addCustomTag,
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Color(0xFF2962FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedTags.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4, left: 4),
                                  child: Text(
                                    'Please select at least one tag',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Business Hours Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Business Hours',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Open 24 Hours',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Switch(
                                        value: _is24Hours,
                                        onChanged: (val) {
                                          setState(() {
                                            _is24Hours = val;
                                            if (_is24Hours) {
                                              _openTime = const TimeOfDay(
                                                hour: 0,
                                                minute: 0,
                                              );
                                              _closeTime = const TimeOfDay(
                                                hour: 23,
                                                minute: 59,
                                              );
                                            } else {
                                              // Reset to default business hours if unchecked
                                              _openTime = const TimeOfDay(
                                                hour: 9,
                                                minute: 0,
                                              );
                                              _closeTime = const TimeOfDay(
                                                hour: 21,
                                                minute: 0,
                                              );
                                            }
                                          });
                                        },
                                        activeTrackColor: const Color(
                                          0xFF2962FF,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (!_is24Hours)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Opening Time',
                                        selectedTime: _openTime,
                                        onTap: () => _selectTime(true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Closing Time',
                                        selectedTime: _closeTime,
                                        onTap: () => _selectTime(false),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF2962FF,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.access_time_filled,
                                        color: Color(0xFF2962FF),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Business is open 24 hours every day',
                                          style: TextStyle(
                                            color: Color(0xFF2962FF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Working Days
                              const Text(
                                'Working Days',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.start,
                                children: List.generate(7, (index) {
                                  // 0=Sun, 1=Mon, ..., 6=Sat
                                  // Display: S, M, T, W, T, F, S
                                  const weekDays = [
                                    'S',
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                  ];
                                  final isSelected = _selectedDays.contains(
                                    index,
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedDays.remove(index);
                                        } else {
                                          _selectedDays.add(index);
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2962FF)
                                            : Colors.grey[200],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2962FF)
                                              : Colors.grey[400]!,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        weekDays[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              // Doctor Management Section
                              if (_selectedCategory == 'Hospital' ||
                                  _selectedCategory == 'Health') ...[
                                const SizedBox(height: 24),
                                _buildDoctorManagementSection(),
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Delete Establishment Section
                        if (widget.shopToEdit != null)
                          _buildDeleteSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2962FF),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A47CC), Color(0xFF2962FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: _selectedImage != null
                                ? DecorationImage(
                                   image: kIsWeb
                                       ? MemoryImage(_selectedImage as Uint8List)
                                       : FileImage(_selectedImage as io.File) as ImageProvider,
                                   fit: BoxFit.cover,
                                 )
                                : (_existingImageUrl != null)
                                ? DecorationImage(
                                    image: NetworkImage(_existingImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              _selectedImage == null &&
                                  _existingImageUrl == null
                              ? const Icon(
                                  Icons.store,
                                  color: Color(0xFF2962FF),
                                  size: 40,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2962FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopToEdit != null
                              ? (widget.shopToEdit?['name'] ?? 'Your Business')
                              : 'Add Establishment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Configure Profile & Settings',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDoctorManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Manage Doctors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _showAddDoctorDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Doctor'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2962FF),
              ),
            ),
          ],
        ),
        if (_doctorsCache.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No doctors added yet.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _doctorsCache.length,
            itemBuilder: (context, index) {
              final doc = _doctorsCache[index];
              return Card(
                elevation: 0,
                color: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    doc['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${doc['department']} • ${doc['qualifications']}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _doctorsCache.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDeleteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeleteConfirmationDialog,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete Establishment',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Are you absolutely sure you want to delete this establishment? This action is irreversible and all associated catalog items will be permanently lost.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteShop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Yes, Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShop() async {
    if (widget.shopToEdit == null || widget.shopToEdit!['id'] == null) return;
    
    setState(() => _isLoading = true);

    try {
      final shopId = widget.shopToEdit!['id'];
      
      // Delete the shop from Supabase
      await Supabase.instance.client
          .from('shops')
          .delete()
          .eq('id', shopId);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Establishment deleted successfully",
          backgroundColor: Colors.green,
        );
        // Pop back to the Dashboard
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error deleting establishment: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDoctorDialog() {
    const blue = Color(0xFF2962FF);
    final nameCtrl = TextEditingController();
    final qualCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String? selectedDept;
    const departments = [
      'Cardiology',
      'Neurology',
      'Orthopedics',
      'Pediatrics',
      'Dermatology',
      'General Medicine',
      'Gynecology',
      'Oncology',
      'ENT',
      'Psychiatry',
      'Urology',
      'Gastroenterology',
      'Radiology',
      'Anesthesiology',
      'Emergency',
    ];
    TimeOfDay defaultStart = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay defaultEnd = const TimeOfDay(hour: 17, minute: 0);
    final Set<int> selectedDocDays = {};

    // Helper to build a styled input field
    Widget buildField({
      required TextEditingController ctrl,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: keyboardType,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Gradient Header ──────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A47CC), Color(0xFF2962FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.medical_services_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add Doctor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Fill in the doctor\'s details below',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Form Fields ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Doctor Name
                            const Text(
                              'Doctor Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            buildField(
                              ctrl: nameCtrl,
                              hint: 'e.g. Dr. Jane Smith',
                              icon: Icons.person_outline,
                            ),

                            const SizedBox(height: 16),

                            // Department Dropdown
                            const Text(
                              'Department',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_hospital_outlined,
                                    color: blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedDept,
                                        hint: Text(
                                          'Select Department',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: blue,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                        items: departments
                                            .map(
                                              (dept) => DropdownMenuItem(
                                                value: dept,
                                                child: Text(dept),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          setDialogState(
                                            () => selectedDept = val,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Qualifications
                            const Text(
                              'Qualifications',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            buildField(
                              ctrl: qualCtrl,
                              hint: 'e.g. MBBS, MD',
                              icon: Icons.school_outlined,
                            ),

                            const SizedBox(height: 16),

                            // Booking Limit
                            const Text(
                              'Booking Limit (per day)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            buildField(
                              ctrl: limitCtrl,
                              hint: 'e.g. 20 (leave blank for no limit)',
                              icon: Icons.people_outline,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 20),

                            // Schedule Section
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: blue,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Availability Schedule',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Day picker - Multi-select UI using FilterChip
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: List.generate(7, (index) {
                                const fullDayNames = [
                                  'Sunday',
                                  'Monday',
                                  'Tuesday',
                                  'Wednesday',
                                  'Thursday',
                                  'Friday',
                                  'Saturday',
                                ];
                                final isSelected = selectedDocDays.contains(
                                  index,
                                );
                                return FilterChip(
                                  label: Text(
                                    fullDayNames[index].substring(0, 3),
                                  ), // 'Sun', 'Mon', etc.
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedDocDays.add(index);
                                      } else {
                                        selectedDocDays.remove(index);
                                      }
                                    });
                                  },
                                  selectedColor: blue.withValues(alpha: 0.2),
                                  checkmarkColor: blue,
                                  backgroundColor: const Color(0xFFF5F7FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? blue
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected ? blue : Colors.black54,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final t = await showTimePicker(
                                        context: context,
                                        initialTime: defaultStart,
                                      );
                                      if (t != null) {
                                        setDialogState(() => defaultStart = t);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'START',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: blue,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                defaultStart.format(context),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final t = await showTimePicker(
                                        context: context,
                                        initialTime: defaultEnd,
                                      );
                                      if (t != null) {
                                        setDialogState(() => defaultEnd = t);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'END',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: blue,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                defaultEnd.format(context),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Add Doctor Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (nameCtrl.text.isNotEmpty &&
                                      selectedDept != null) {
                                    String formatPosgresTime(TimeOfDay t) {
                                      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
                                    }

                                    final startTimeStr = formatPosgresTime(
                                      defaultStart,
                                    );
                                    final endTimeStr = formatPosgresTime(
                                      defaultEnd,
                                    );

                                    final sortedDays = selectedDocDays.toList()
                                      ..sort();
                                    const dayNames = [
                                      'Sunday',
                                      'Monday',
                                      'Tuesday',
                                      'Wednesday',
                                      'Thursday',
                                      'Friday',
                                      'Saturday',
                                    ];
                                    final docData = {
                                      'name': nameCtrl.text.trim(),
                                      'department': selectedDept!,
                                      'qualifications': qualCtrl.text.trim(),
                                      'available_days': sortedDays
                                          .map((d) => dayNames[d])
                                          .toList(),
                                      'availability': sortedDays
                                          .map(
                                            (d) => {
                                              'day_of_week': dayNames[d],
                                              'start_time': startTimeStr,
                                              'end_time': endTimeStr,
                                            },
                                          )
                                          .toList(),
                                      if (limitCtrl.text.trim().isNotEmpty)
                                        'booking_limit': int.tryParse(limitCtrl.text.trim()),
                                    };
                                    setState(() {
                                      _doctorsCache.add(docData);
                                    });
                                    Navigator.pop(ctx);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Add Doctor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Cancel
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
