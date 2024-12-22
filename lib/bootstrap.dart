import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/panel/domain/fetch_from_api.dart';
import 'package:hiddify/features/panel/domain/models/init_database.dart';
import 'package:hiddify/features/panel/domain/oss/ossMonitorService.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError =
      Logger.logPlatformDispatcherError;
  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(env),
    ],
  );

  // 初始化数据库和启动服务，不阻塞应用的其他部分
  unawaited(_initializeServices(container, env));

  // 尝试读取 token 并设置登录状态
  unawaited(_validateToken(container));

  await _init(
    "directories",
    () => container.read(appDirectoriesProvider.future),
  );
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init(
    "app info",
    () => container.read(appInfoProvider.future),
  );
  await _init(
    "preferences",
    () => container.read(sharedPreferencesProvider.future),
  );

  final enableAnalytics =
      await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init(
      "analytics",
      () => container
          .read(analyticsControllerProvider.notifier)
          .enableAnalytics(),
    );
  }

  await _init(
    "preferences migration",
    () async {
      try {
        await PreferencesMigration(
          sharedPreferences:
              container.read(sharedPreferencesProvider).requireValue,
        ).migrate();
      } catch (e, stackTrace) {
        Logger.bootstrap.error("preferences migration failed", e, stackTrace);
        if (env == Environment.dev) rethrow;
        Logger.bootstrap.info("clearing preferences");
        await container.read(sharedPreferencesProvider).requireValue.clear();
      }
    },
  );

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init(
      "window controller",
      () => container.read(windowNotifierProvider.future),
    );

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap
        .debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");
    if (!silentStart) {
      await container.read(windowNotifierProvider.notifier).open(focus: false);
    } else {
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }
    await _init(
      "auto start service",
      () => container.read(autoStartNotifierProvider.future),
    );
  }
  await _init(
    "logs repository",
    () => container.read(logRepositoryProvider.future),
  );
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init(
    "profile repository",
    () => container.read(profileRepositoryProvider.future),
  );

  await _safeInit(
    "active profile",
    () => container.read(activeProfileProvider.future),
    timeout: 1000,
  );
  await _safeInit(
    "deep link service",
    () => container.read(deepLinkNotifierProvider.future),
    timeout: 1000,
  );
  await _init(
    "sing-box",
    () => container.read(singboxServiceProvider).init(),
  );
  if (PlatformUtils.isDesktop) {
    await _safeInit(
      "system tray",
      () => container.read(systemTrayNotifierProvider.future),
      timeout: 1000,
    );
  }

  if (Platform.isAndroid) {
    await _safeInit(
      "android display mode",
      () async {
        await FlutterDisplayMode.setHighRefreshRate();
      },
    );
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();
  runApp(
    ProviderScope(
      parent: container,
      child: SentryUserInteractionWidget(
        child: const App(),
      ),
    ),
  );

  FlutterNativeSplash.remove();
}

Future<T> _init<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap
        .debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  final OssMonitorService ossMonitorService;
  Timer? _monitorTimer;

  AppLifecycleObserver(this.ossMonitorService);

  // 启动定时监控任务
  void startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await ossMonitorService.monitorAndUpdateDomains();
    });
    if (kDebugMode) {
      print("Domain monitoring started.");
    }
  }

  // 停止定时监控任务
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    if (kDebugMode) {
      print("Domain monitoring stopped.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startMonitoring(); // 应用回到前台时启动监控任务
    } else if (state == AppLifecycleState.paused) {
      stopMonitoring(); // 应用进入后台时停止监控任务
    }
  }
}

Future<void> _initializeServices(
    ProviderContainer container, Environment env) async {
  const int maxRetries = 3; // 最大重试次数
  const Duration retryDelay = Duration(seconds: 5); // 每次重试的间隔时间

  int currentAttempt = 0;

  while (currentAttempt < maxRetries) {
    try {
      initializeDesktopDatabase(); // 初始化桌面平台数据库
      // 检查是否需要重建数据库
      final bool recreate = currentAttempt > 0; // 如果发生重试则重建数据库
      // 初始化数据库（第一次尝试不重建）
      final db = await initDatabase(recreate: recreate);

      // 初始化服务
      await _initializeOssMonitor(db);
      // await HttpService.initialize(db);

      // 如果初始化成功，退出重试循环
      if (kDebugMode) print("Service initialization successful.");
      return;
    } catch (e) {
      currentAttempt++;
      if (currentAttempt < maxRetries) {
        if (kDebugMode) {
          print(
              "Error during service initialization. Retrying in ${retryDelay.inSeconds} seconds... (Attempt $currentAttempt/$maxRetries)");
        }
        await Future.delayed(retryDelay); // 等待一段时间再重试
      } else {
        if (kDebugMode) {
          print(
              "Error during service initialization after $maxRetries attempts: $e");
        }
        // 设置状态为未登录
        container.read(authProvider.notifier).state = false;
        // 抛出最后的异常
        throw Exception(
            "Service initialization failed after $maxRetries attempts.");
      }
    }
  }
}

Future<void> _initializeOssMonitor(Database db) async {
  final ossMonitorService = OssMonitorService(db);
  await fetchAndInsertApiData(db);
  await ossMonitorService.monitorAndUpdateDomains();

  final lifecycleObserver = AppLifecycleObserver(ossMonitorService);
  WidgetsBinding.instance.addObserver(lifecycleObserver);
  lifecycleObserver.startMonitoring();
}

Future<void> _validateToken(ProviderContainer container) async {
  try {
    final token = await getToken();
    if (token != null) {
      final userService = UserService();
      final isValid = await userService.validateToken(token);
      container.read(authProvider.notifier).state = isValid;
    } else {
      container.read(authProvider.notifier).state = false;
    }
  } catch (e) {
    if (kDebugMode) print("Error during token validation: $e");
    container.read(authProvider.notifier).state = false;
  }
}

void initializeDesktopDatabase() {
  if (isDesktop()) {
      sqfliteFfiInit(); // 初始化 FFI
      databaseFactory = databaseFactoryFfi; // 设置 FFI 数据库工厂
  }
}

bool isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
