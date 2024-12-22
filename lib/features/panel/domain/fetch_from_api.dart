import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

// TODO OSS地址
const String apiUrl = 'https://kuaiyun1api.oss-cn-shenzhen.aliyuncs.com/api.json';

// 从 API 获取 OSS 地址并插入数据库
Future<void> fetchAndInsertApiData(Database db) async {
  print('Fetching OSS addresses from API: $apiUrl');
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;

      final List<Map<String, dynamic>> ossAddresses =
          (data['oss_addresses'] as List).cast<Map<String, dynamic>>();

      for (final ossAddress in ossAddresses) {
        final existing = await db.query(
          'apiTable',
          where: 'oss_url = ?',
          whereArgs: [ossAddress['oss_url']],
        );

        if (existing.isEmpty) {
          await db.insert(
            'apiTable',
            {
              'oss_url': ossAddress['oss_url'] as String,
              'priority': ossAddress['priority'] as int,
              'is_active': 1,
            },
          );
          print(
              'Inserted into apiTable: ${ossAddress['oss_url']} with priority ${ossAddress['priority']}');
        } else {
          print(
              'Skipping insert: ${ossAddress['oss_url']} already exists in apiTable.');
        }
      }
      print('All OSS addresses from API have been processed.');
    } else {
      throw Exception(
          'Failed to load OSS addresses from API with status code: ${response.statusCode}');
    }
  } catch (e) {
    await db.update('backupApis', {'is_active': 0},
        where: 'api_url = ?', whereArgs: [apiUrl]);
    print(
        'Failed to load OSS addresses from API. Error: $e. Marking as inactive.');
  }
}
