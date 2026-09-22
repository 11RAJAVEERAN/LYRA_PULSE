import 'package:dio/dio.dart';

class DioClient {
  DioClient({Dio? dio}) : dio = dio ?? Dio();

  final Dio dio;
}
