// import 'dart:io';
// import 'package:dio/dio.dart';
//
// class DioHelper {
//   static Dio? dio;
//
//   static init() {
//     dio = Dio(
//       BaseOptions(
//         // ✅ رابط Chatwoot الخاص بك - غيّره
//         baseUrl: 'https://chat.lynomia.com/api/v1/',
//         receiveDataWhenStatusError: true,
//       ),
//     );
//   }
//
//   // ─── GET ─────────────────────────────────────
//   static Future<Response> getData({
//     required String url,
//     Map<String, dynamic>? query,
//     String? token,
//   }) async {
//     dio!.options.headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//     return await dio!.get(url, queryParameters: query);
//   }
//
//   // ─── POST ────────────────────────────────────
//   static Future<Response> postData({
//     required String url,
//     Map<String, dynamic>? query,
//     dynamic data,
//     String? token,
//   }) async {
//     dio!.options.headers = {
//       if (data is! FormData) 'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//     return await dio!.post(
//       url,
//       queryParameters: query,
//       data: data,
//     );
//   }
//
//   // ─── PUT ─────────────────────────────────────
//   static Future<Response> putData({
//     required String url,
//     Map<String, dynamic>? query,
//     dynamic data,
//     String? token,
//   }) async {
//     dio!.options.headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//     return await dio!.put(
//       url,
//       queryParameters: query,
//       data: data,
//     );
//   }
//
//   // ─── DELETE ──────────────────────────────────
//   static Future<Response> deleteData({
//     required String url,
//     Map<String, dynamic>? query,
//     dynamic data,
//     String? token,
//   }) async {
//     dio!.options.headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//     return await dio!.delete(
//       url,
//       queryParameters: query,
//       data: data,
//     );
//   }
//
//   // ─── UPLOAD FILE ─────────────────────────────
//   static Future<Response> uploadFile({
//     required String url,
//     required File file,
//     required String fieldName,
//     Map<String, dynamic>? extraData,
//     String? token,
//   }) async {
//     final formData = FormData.fromMap({
//       fieldName: await MultipartFile.fromFile(file.path),
//       if (extraData != null) ...extraData,
//     });
//
//     dio!.options.headers = {
//       'Content-Type': 'multipart/form-data',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//
//     return await dio!.post(url, data: formData);
//   }
// }

import 'dart:io';
import 'package:dio/dio.dart';

class DioHelper {
  static Dio? dio;

  static init() {
    dio = Dio(
      BaseOptions(
        // ✅ رابط Chatwoot الخاص بك - غيّره
        baseUrl: 'https://chat.lynomia.com/api/v1/',
        receiveDataWhenStatusError: true,
      ),
    );
  }

  // ─── GET ─────────────────────────────────────
  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await dio!.get(url, queryParameters: query);
  }

  // ─── POST ────────────────────────────────────
  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String? token,
  }) async {
    dio!.options.headers = {
      if (data is! FormData) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await dio!.post(
      url,
      queryParameters: query,
      data: data,
    );
  }

  // ─── PUT ─────────────────────────────────────
  static Future<Response> putData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await dio!.put(
      url,
      queryParameters: query,
      data: data,
    );
  }

  // ─── DELETE ──────────────────────────────────
  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await dio!.delete(
      url,
      queryParameters: query,
      data: data,
    );
  }

  // ─── UPLOAD FILE ─────────────────────────────
  static Future<Response> uploadFile({
    required String url,
    required File file,
    required String fieldName,
    Map<String, dynamic>? extraData,
    String? token,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
      if (extraData != null) ...extraData,
    });

    dio!.options.headers = {
      'Content-Type': 'multipart/form-data',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return await dio!.post(url, data: formData);
  }
}