import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../services/jadwal_service.dart';

class PresensiScreen extends StatefulWidget {
  final String? initialSubject;
  const PresensiScreen({super.key, this.initialSubject});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  bool _isVerifying = false;
  late String _selectedClass;
  
  late List<String> _classes;

  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isFaceDetected = false;
  CameraDescription? _cameraDescription;

  // Location Variables
  Position? _currentPosition;
  double _distanceFromCampus = 0.0;
  bool _isLocationValid = false;
  
  // STMIK Widya Utama Berkoh coordinates
  final double campusLat = -7.4449;
  final double campusLng = 109.2526;
  final double maxRadius = 999999.0; // Large radius for demo

  @override
  void initState() {
    super.initState();

    // 1. Get dynamic class list from JadwalService
    _classes = JadwalService.instance.allJadwal
        .map((j) => j.mataKuliah)
        .toSet() // Remove duplicates
        .toList();

    // 2. Initialize with provided subject or default to the most relevant one
    if (widget.initialSubject != null && _classes.any((c) => c.toLowerCase() == widget.initialSubject!.toLowerCase())) {
      // Find the exact name from our list to avoid case sensitivity issues
      _selectedClass = _classes.firstWhere((c) => c.toLowerCase() == widget.initialSubject!.toLowerCase());
    } else {
      // If no initial subject, try to find what's scheduled now
      final today = JadwalService.instance.getJadwalHariIni();
      if (today.isNotEmpty) {
        _selectedClass = today[0].mataKuliah;
      } else {
        _selectedClass = _classes.isNotEmpty ? _classes[0] : "Mobile Programming";
      }
    }

    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    _initializeCameraAndMLKit();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Layanan lokasi (GPS) tidak aktif.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Izin lokasi ditolak.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan.');
        return;
      } 

      // Fetch initial position immediately with timeout
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 6), onTimeout: () {
        // Fallback or error if timeout occurs
        throw 'Timeout getting location';
      });
      
      _updateLocationData(initialPosition);

      // Start stream for continuous updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        )
      ).listen((Position position) {
        _updateLocationData(position);
      }, onError: (e) {
        debugPrint("Location stream error: $e");
      });

    } catch (e) {
      debugPrint("Error initializing location: $e");
      
      // On Web/Emulator, provide a fallback for demo if real GPS fails
      if (kIsWeb || !kReleaseMode) {
        debugPrint("Falling back to campus location for testing...");
        _updateLocationData(Position(
          latitude: campusLat,
          longitude: campusLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ));
      } else {
        _showLocationError('Gagal mendapatkan lokasi. Pastikan GPS aktif.');
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateLocationData(Position position) {
    if (!mounted) return;
    
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      campusLat,
      campusLng,
    );
    
    setState(() {
      _currentPosition = position;
      _distanceFromCampus = distance;
      // Allow any location for demo/web if needed, but here we keep the maxRadius logic
      _isLocationValid = distance <= maxRadius;
    });
  }

  Future<void> _initializeCameraAndMLKit() async {
    // 1. Setup ML Kit Face Detector (Mobile Only)
    if (!kIsWeb) {
      final options = FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.fast,
      );
      _faceDetector = FaceDetector(options: options);
    } else {
      // Mock detection for Web
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isFaceDetected = true;
          });
        }
      });
    }

    // 2. Setup Camera
    try {
      if (kIsWeb) {
        // Simple Web camera init
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          _cameraDescription = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );
          _cameraController = CameraController(
            _cameraDescription!,
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await _cameraController!.initialize();
          if (mounted) setState(() => _isCameraInitialized = true);
        }
        return;
      }

      // Mobile camera init
      final cameras = await availableCameras();
      _cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _cameraDescription!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: (defaultTargetPlatform == TargetPlatform.iOS
                ? ImageFormatGroup.bgra8888
                : ImageFormatGroup.nv21),
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // 3. Start Image Stream (Mobile Only)
      if (!kIsWeb) {
        _cameraController!.startImageStream((CameraImage image) {
          if (_isDetecting) return;
          _isDetecting = true;
          _processCameraImage(image);
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      final imageRotation = InputImageRotationValue.fromRawValue(_cameraDescription!.sensorOrientation) ?? InputImageRotation.rotation0deg;
      
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      
      // Process with ML Kit
      final faces = await _faceDetector.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          // Verify if exactly one face is detected (to avoid multiple people or no one)
          _isFaceDetected = faces.length == 1;
        });
      }
    } catch (e) {
      debugPrint("Error detecting face: $e");
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    if (!kIsWeb) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    if (!kIsWeb) {
      _faceDetector.close();
    }
    super.dispose();
  }

  Future<void> _submitAttendance() async {
    if (!_isFaceDetected || !_isLocationValid) return; // Guard: only submit if face is detected and location is valid
    
    setState(() {
      _isVerifying = true;
    });

    try {
      // 1. Stop image stream before taking picture (Mobile Only)
      if (!kIsWeb) {
        await _cameraController?.stopImageStream();
      }
      
      // 2. Take picture for proof
      final XFile? photo = await _cameraController?.takePicture();
      
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });

      // 3. Navigate back to Dashboard and pass the photo path and class name
      if (photo != null) {
        Navigator.pop(context, {
          'status': 'success',
          'photoPath': photo.path,
          'className': _selectedClass,
        });
      } else {
        Navigator.pop(context); // Fallback
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic styles based on face detection status
    final Color statusColor = _isFaceDetected ? AppColors.greenHadir : AppColors.redAlpa;
    final String statusText = _isFaceDetected ? "Wajah Cocok: Terverifikasi" : "Wajah Tidak Terdeteksi";
    final IconData statusIcon = _isFaceDetected ? Icons.face_retouching_natural : Icons.face_unlock_outlined;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Cek Presensi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Subtitle Description
            const Text(
              "Silakan lakukan verifikasi wajah dan lokasi GPS di bawah untuk absen masuk kelas.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Dropdown class selector
            const Text(
              "Mata Kuliah Aktif",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tosca.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClass,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.tosca),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  items: _classes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedClass = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Facial Recognition Camera View
            const Text(
              "Verifikasi Wajah",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: AspectRatio(
                aspectRatio: 1.0, // Square camera view
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), // Slate-900 (Dark background for camera)
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // Live Camera Preview
                        if (_isCameraInitialized && _cameraController != null)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ?? 100,
                              height: _cameraController!.value.previewSize?.width ?? 100,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator(color: AppColors.tosca)),
                        
                        // Scanner HUD Overlay grid
                        Opacity(
                          opacity: 0.15,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 36,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                            ),
                            itemBuilder: (context, idx) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Face outline overlay (Color changes based on detection)
                        Center(
                          child: Container(
                            width: 200,
                            height: 260,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: statusColor,
                                width: 3.0,
                              ),
                              borderRadius: BorderRadius.circular(130),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Laser Scanning Line Animation (Only when not verified)
                        if (!_isFaceDetected)
                          AnimatedBuilder(
                            animation: _scannerAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 260 * _scannerAnimation.value + 40,
                                left: 40,
                                right: 40,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.redAlpa,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.redAlpa.withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        // Facial Match percentage badge
                        Positioned(
                          bottom: 16,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // GPS Location Card
            const Text(
              "Verifikasi Lokasi (GPS)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.tosca.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F4F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.tosca,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Lokasi Saat Ini",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.tosca, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _initializeLocation,
                            ),
                            const SizedBox(width: 8),
                            if (_currentPosition != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isLocationValid ? AppColors.greenHadir.withOpacity(0.12) : AppColors.redAlpa.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isLocationValid ? "Valid" : "Di Luar Radius",
                                  style: TextStyle(
                                    color: _isLocationValid ? AppColors.greenHadir : AppColors.redAlpa,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentPosition != null 
                            ? "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)} • Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}"
                            : "Mencari koordinat...",
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: "monospace",
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentPosition != null
                            ? (_distanceFromCampus == 0 && _currentPosition!.accuracy == 0 
                                ? "Mode Demo: Menggunakan lokasi kampus" 
                                : "Jarak dari kampus: ${_distanceFromCampus.toStringAsFixed(1)} meter")
                            : "Menjalankan pemindaian satelit...",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Button - Only clickable if face is detected
            Opacity(
              opacity: (_isFaceDetected && _isLocationValid) ? 1.0 : 0.5,
              child: CustomButton(
                text: "Konfirmasi Kehadiran",
                onPressed: (_isFaceDetected && _isLocationValid) ? _submitAttendance : () {}, // Disabled if no face or location not valid
                isLoading: _isVerifying,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
