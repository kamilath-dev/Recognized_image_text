import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'text_recupere.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hidden Text App',
      theme: ThemeData(
        primarySwatch: Colors.purple, // Couleur principale
      ),
      home: const MainScreen(),
    );
  }
}

final textRecognizer = TextRecognizer();

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _isCameraPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = _initializeApplication();
  }

  // Initialiser l'application, demander l'autorisation d'accéder à la caméra et initialiser la caméra si l'autorisation est accordée
  Future<void> _initializeApplication() async {
    await _requestCameraPermission();
    if (_isCameraPermissionGranted) {
      await _initializeCamera();
    }
  }

  // Demander l'autorisation d'accéder à la caméra
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status == PermissionStatus.granted;
    });
  }

  // Initialiser la caméra en sélectionnant la première caméra arrière disponible
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _initializeCameraController(cameras);
  }

  // Initialiser le contrôleur de caméra avec la première caméra arrière disponible
  void _initializeCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null || cameras.isEmpty) {
      return;
    }

    // Sélectionnez la première caméra arrière.
    final CameraDescription camera = cameras.firstWhere(
      (current) => current.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  // Démarrer la caméra si elle est initialisée
  Future<void> _startCamera() async {
    if (_cameraController != null && !_cameraController!.value.isInitialized) {
      await _cameraController!.initialize();
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      (_cameraController!.description);
    }
  }

  // Arrêter la caméra
  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
  }

  // Observer le changement d'état de l'application et agir en conséquence (arrêter ou démarrer la caméra)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  // Libérer les ressources lorsque l'écran est fermé
  @override
  void dispose() {
    _stopCamera();
    textRecognizer.close();
    super.dispose();
    setState(() {});
  }

  // Obtenir une image de la galerie
  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              TexteRecup(text: recognizedText.text),
        ),
      );
    } else {
      print('No image selected.');
    }
  }

  // Scanner une image en utilisant la caméra
  Future<void> _scanImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final navigator = Navigator.of(context);

    try {
      final pictureFile = await _cameraController!.takePicture();

      final file = File(pictureFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              TexteRecup(text: recognizedText.text),
        ),
      );
    } catch (e) {
      // Afficher une notification en cas d'erreur lors de la reconnaissance de texte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Une erreur s'est produite lors de la numérisation du texte"),
        ),
      );
    }
  }

  // Construire l'interface utilisateur en fonction de l'état de l'application
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            // Afficher l'aperçu de la caméra si la permission est accordée
            if (_isCameraPermissionGranted)
              FutureBuilder<List<CameraDescription>>(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _initializeCameraController(snapshot.data!);

                    return Center(child: CameraPreview(_cameraController!));
                  } else {
                    return const LinearProgressIndicator();
                  }
                },
              ),
            Scaffold(
              appBar: AppBar(
                title: const Text('Hidden Text App'),
              ),
              backgroundColor:
                  _isCameraPermissionGranted ? Colors.transparent : null,
              body: _isCameraPermissionGranted
                  ? Column(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton pour scanner une image en utilisant la caméra
                                FloatingActionButton(
                                  onPressed: _scanImage,
                                  child: Text("Scan"),
                                ),
                                // Bouton pour obtenir une image de la galerie
                                FloatingActionButton(
                                  onPressed: _getImage,
                                  child: Text("Gallery"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                        child: const Text(
                          "Autorisation de la caméra refusée",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
