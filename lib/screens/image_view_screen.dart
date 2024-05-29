import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewScreen extends StatelessWidget {
  final String imageURL;
  final String nombre;
  const ImageViewScreen(
      {super.key, required this.imageURL, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          nombre,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w300),
        ),
      ),
      body: Container(
        child: Center(
          child: PhotoView(imageProvider: NetworkImage(imageURL)),
        ),
      ),
    );
  }
}