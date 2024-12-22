// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 初始化数据库的方法，支持选择是否重建数据库
Future<Database> initDatabase({bool recreate = false}) async {
  final directory = await getApplicationSupportDirectory();
  final dbPath = join(directory.path, 'domain_backup.db');

  // 判断是否需要重建数据库
  if (recreate) {
    print('Recreating database: $dbPath');
    await deleteDatabase(dbPath); // 删除已有的数据库
    print('Old database deleted.');
  }

  print('Initializing database at path: $dbPath');

  return openDatabase(
    dbPath,
    onCreate: (db, version) async {
      print('Creating tables...');

      await db.execute(
        'CREATE TABLE apiTable ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'oss_url TEXT NOT NULL UNIQUE,' // 设置 oss_url 为唯一值
        'priority INTEGER,'
        'is_active BOOLEAN DEFAULT 1' // 标记是否可用
        ')',
      );
      print('Created table: apiTable');

      await db.execute(
        'CREATE TABLE ossTable ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'domain TEXT NOT NULL UNIQUE,' // 设置 domain 为唯一值
        'is_active BOOLEAN DEFAULT 1,' // 标记是否可用
        'failures INTEGER DEFAULT 0' // 新增字段，用于记录失败次数
        ')',
      );

      await db.execute(
        'CREATE TABLE backupApis ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'api_url TEXT NOT NULL UNIQUE,' // 设置 api_url 为唯一值
        'priority INTEGER,'
        'is_active BOOLEAN DEFAULT 1' // 标记是否可用
        ')',
      );
      print('Created table: backupApis');
    },
    version: 1,
  );
}

/// 重建数据库的方法
Future<Database> recreateDatabase() async {
  return await initDatabase(recreate: true);
}
