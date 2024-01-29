import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share/share.dart';

import 'main.dart';

class MyApplication extends StatelessWidget {
    final String texte;
      const MyApplication({Key? key, required this.texte}) : super(key: key);

    Future<void> _partagerTexte(String texte) async {
    await Share.share(texte);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultat'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MyApp())); // Utiliser pop pour revenir en arrière
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Hello World!'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TexteRecup(
                      text: 'Text to translate',
                    ),
                  ),
                );
              },
              child: Text('Go to Result'),
            ),
             FloatingActionButton(
            onPressed: () {
              _partagerTexte(texte);
            },
            tooltip: 'Partager le texte',
            child: const Icon(Icons.share),
          ),
          ],
        ),
      ),
    );
  }
}

class TexteRecup extends StatelessWidget {
  final String text;

  const TexteRecup({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  Future<String> retrieveTextFromImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final image = InputImage.fromFilePath(pickedFile.path);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(image);

        return recognizedText.text;
      } else {
        return 'No image selected.';
      }
    } catch (e) {
      return 'Error retrieving text.';
    }
  }
}
