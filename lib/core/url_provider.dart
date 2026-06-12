import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final baseUrlProvider = Provider<String>((ref){
  return 'http://localhost:8000/api/';
});