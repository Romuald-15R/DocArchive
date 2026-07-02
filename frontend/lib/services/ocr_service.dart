import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    } finally {
      textRecognizer.close();
    }
  }
}