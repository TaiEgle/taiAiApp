import 'package:dio/dio.dart';
import '../models/models.dart';

/// Image generation API service
class ImageService {
  final Dio _dio;

  ImageService(this._dio);

  /// Generate image from prompt
  Future<ImageResult> generate({
    required String apiKey,
    required String apiUrl,
    required String prompt,
    required String size,
    required ResponseFormat format,
    ImageMode? imageMode,
    String? localImagePath,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'model': 'agnes-image-2.1-flash',
      'prompt': prompt,
      'n': 1,
      'size': size,
      'extra_body': {
        'response_format': format == ResponseFormat.b64Json ? 'b64_json' : 'url',
      },
    };

    if (imageMode == ImageMode.img2img) {
      final inputImage = localImagePath ?? imageUrl;
      if (inputImage != null) {
        body['extra_body']!['image'] = [inputImage];
      }
    }

    final response = await _dio.post(
      apiUrl,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw _parseError(response.data);
    }

    final json = response.data as Map<String, dynamic>;
    final apiResp = ImageApiResponse.fromJson(json);

    if (apiResp.data == null || apiResp.data!.isEmpty) {
      throw Exception('未获取到图片数据，请检查 API 响应');
    }

    return apiResp.data![0];
  }

  Exception _parseError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['error']?['message'] ?? data['message'] ?? '';
      return Exception('请求失败: $msg');
    }
    return Exception('请求失败');
  }
}
