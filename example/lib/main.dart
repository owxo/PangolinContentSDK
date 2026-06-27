import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk.dart';

const _defaultAppId = String.fromEnvironment('PANGLE_APP_ID', defaultValue: '');
const _defaultAdAppId = String.fromEnvironment(
  'PANGLE_AD_APP_ID',
  defaultValue: '',
);
const _defaultConfigFile = String.fromEnvironment(
  'PANGLE_CONFIG_FILE',
  defaultValue: '',
);
const _androidAppId = '584358';
const _androidAdAppId = '5468137';
const _androidConfigFile = 'SDK_Setting_5468137.json';
const _iosAppId = '925856';
const _iosAdAppId = '5554773';
const _iosConfigFile = 'SDK_Setting_5554773.json';
const _autoInitialize = bool.fromEnvironment('PANGOLIN_AUTO_INIT');
const _disableTTPlayer = bool.fromEnvironment(
  'PANGOLIN_DISABLE_TT_PLAYER',
  defaultValue: false,
);

void main() {
  runApp(const PangolinExampleApp());
}

class PangolinExampleApp extends StatelessWidget {
  const PangolinExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b5b)),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xffd8e2df)),
          ),
        ),
      ),
      home: const DramaWorkbench(),
    );
  }
}

class DramaWorkbench extends StatefulWidget {
  const DramaWorkbench({super.key});

  @override
  State<DramaWorkbench> createState() => _DramaWorkbenchState();
}

class _DramaWorkbenchState extends State<DramaWorkbench> {
  final _sdk = PangolinContentSdk.instance;
  final _appIdController = TextEditingController(text: _initialAppId);
  final _adAppIdController = TextEditingController(text: _initialAdAppId);
  final _configController = TextEditingController(text: _initialConfigFile);
  final _searchController = TextEditingController();
  final _categoryController = TextEditingController();

  var _status = '未初始化';
  var _started = false;
  var _loading = false;
  var _dramas = <PangolinDrama>[];
  var _categories = <String>[];

  @override
  void initState() {
    super.initState();
    if (_autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initialize();
        }
      });
    }
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _adAppIdController.dispose();
    _configController.dispose();
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _loading = true);
    try {
      await task();
    } on PlatformException catch (error) {
      // Keep a plain print in release builds so devicectl --console can show it.
      // ignore: avoid_print
      print(
        'Pangolin example PlatformException: ${error.code} ${error.message}',
      );
      setState(() => _status = '${error.code}: ${error.message ?? ''}');
    } catch (error) {
      // ignore: avoid_print
      print('Pangolin example error: $error');
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _initialize() {
    return _run(() async {
      final ready = await _prepareEnvironment();
      if (!ready) return;

      final result = await _sdk.initialize(
        PangolinContentConfig(
          appId: _appIdController.text.trim(),
          adAppId: _adAppIdController.text.trim(),
          configFileName: _configController.text.trim(),
          appName: 'Pangolin Flutter Demo',
          debug: true,
          disableTTPlayer: _disableTTPlayer,
        ),
      );
      // ignore: avoid_print
      print(
        'Pangolin initialize result: success=${result.success}, '
        'code=${result.code}, message=${result.message}',
      );
      setState(() {
        _started = result.success;
        _status = result.success
            ? '初始化成功'
            : '初始化失败：${_initializationFailureText(result)}';
      });
    });
  }

  Future<bool> _prepareEnvironment() async {
    setState(() => _status = '正在请求 SDK 推荐权限...');
    final permissions = await _sdk.requestRecommendedPermissions();
    final deniedPermissions = permissions.entries
        .where((entry) => !entry.value)
        .map((entry) => _permissionLabel(entry.key))
        .toList();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (deniedPermissions.isNotEmpty) {
        setState(() {
          _status = 'iOS 权限未全部授予：${deniedPermissions.join('、')}。继续尝试初始化...';
        });
      } else {
        setState(() => _status = 'iOS 权限检查完成，正在初始化 SDK...');
      }
      return true;
    }

    setState(() => _status = '正在检测穿山甲服务连通性...');
    final checks = await _sdk.checkNetworkAccess(timeoutMillis: 5000);
    final unreachable = checks.where((check) => !check.reachable).toList();

    if (unreachable.isNotEmpty) {
      setState(() {
        _started = false;
        _status =
            '网络预检失败：${_networkFailureText(unreachable)}\n请换移动网络/热点，关闭代理或 VPN 后重试。';
      });
      return false;
    }

    if (deniedPermissions.isNotEmpty) {
      setState(() {
        _status = '权限未全部授予：${deniedPermissions.join('、')}。继续尝试初始化...';
      });
    } else {
      setState(() => _status = '权限和网络预检通过，正在初始化 SDK...');
    }
    return true;
  }

  Future<void> _diagnoseNetwork() {
    return _run(() async {
      setState(() => _status = '正在检测穿山甲服务连通性...');
      final checks = await _sdk.checkNetworkAccess(timeoutMillis: 5000);
      final failed = checks.where((check) => !check.reachable).toList();
      setState(() {
        _status = failed.isEmpty
            ? '网络诊断通过：${checks.map((check) => '${check.host} ${check.elapsedMs ?? 0}ms').join('，')}'
            : '网络诊断失败：${_networkFailureText(failed)}';
      });
    });
  }

  String _networkFailureText(List<PangolinNetworkCheckResult> checks) {
    return checks
        .map((check) => '${check.host}:${check.port} ${check.message ?? '不可达'}')
        .join('；');
  }

  String _permissionLabel(String permission) {
    return switch (permission) {
      'android.permission.READ_PHONE_STATE' => '读取手机状态',
      'android.permission.ACCESS_COARSE_LOCATION' => '粗略定位',
      'android.permission.ACCESS_FINE_LOCATION' => '精确定位',
      'android.permission.READ_EXTERNAL_STORAGE' => '读取存储',
      'android.permission.WRITE_EXTERNAL_STORAGE' => '写入存储',
      'android.permission.REQUEST_INSTALL_PACKAGES' => '安装未知应用',
      _ => permission,
    };
  }

  String _initializationFailureText(PangolinSdkStartResult result) {
    final rawMessage = result.message ?? result.code?.toString() ?? '未知错误';
    final lowerMessage = rawMessage.toLowerCase();
    if (lowerMessage.contains('socketexception') ||
        lowerMessage.contains('connection reset') ||
        lowerMessage.contains('failed to connect') ||
        lowerMessage.contains('connectexception') ||
        lowerMessage.contains('timed out') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('-1001')) {
      return '$rawMessage\n\n已完成广告 SDK 初始化，但内容 SDK 拉取 token 时联网失败。请先切换网络、关闭代理/VPN、换手机热点或移动网络后重试。';
    }
    if (lowerMessage.contains('libpangleflipped.so') ||
        lowerMessage.contains('x86_64')) {
      return '$rawMessage\n\n当前是 Android 模拟器环境，穿山甲广告/内容 SDK 缺少模拟器 x86_64 原生库，无法完成初始化。请使用真实 Android 手机测试短剧播放和滑滑流。';
    }
    if (lowerMessage.contains('token')) {
      return '$rawMessage\n\n内容 SDK token 初始化失败。请检查 SDK_Setting JSON、AppLog AppID、广告/媒体 ID 和包名是否与穿山甲后台配置一致。';
    }
    if (lowerMessage.contains('license_config') ||
        rawMessage.contains('配置文件')) {
      return '$rawMessage\n\n请在穿山甲后台录入当前包名后重新下载 SDK 参数配置文件，并替换 assets 里的 SDK_Setting JSON。';
    }
    return rawMessage;
  }

  Future<void> _loadRecommended() {
    return _run(() async {
      final dramas = await _sdk.requestRecommendedDramas(pageSize: 20);
      setState(() {
        _dramas = dramas;
        _status = '推荐短剧 ${dramas.length} 部';
      });
    });
  }

  Future<void> _loadAll() {
    return _run(() async {
      final dramas = await _sdk.requestAllDramas(pageSize: 40);
      setState(() {
        _dramas = dramas;
        _status = '全部短剧 ${dramas.length} 部';
      });
    });
  }

  Future<void> _loadCategories() {
    return _run(() async {
      final categories = await _sdk.requestDramaCategories();
      setState(() {
        _categories = categories;
        _status = '分类 ${categories.length} 个';
      });
    });
  }

  Future<void> _loadByCategory(String category) {
    if (category.trim().isEmpty) return Future<void>.value();
    return _run(() async {
      final dramas = await _sdk.requestDramasByCategory(category.trim());
      setState(() {
        _dramas = dramas;
        _status = '$category ${dramas.length} 部';
      });
    });
  }

  Future<void> _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return Future<void>.value();
    return _run(() async {
      final dramas = await _sdk.searchDramas(query);
      setState(() {
        _dramas = dramas;
        _status = '搜索到 ${dramas.length} 部';
      });
    });
  }

  Future<void> _open(PangolinDrama drama) {
    return _run(() {
      return _sdk.openDramaDetail(
        dramaId: drama.id,
        options: PangolinDramaDetailOptions(
          index: drama.index,
          freeSet: 5,
          lockSet: 2,
        ),
      );
    });
  }

  Future<void> _openDrawFeed() {
    return _run(() {
      return _sdk.openDramaDrawFeed(
        options: const PangolinDramaDrawOptions(
          channelType: PangolinDramaDrawChannelType.recommend,
          contentType: PangolinDramaDrawContentType.onlyDrama,
          hideChannelName: true,
          hideDramaInfo: false,
          hideDramaEnter: true,
          dramaFree: 5,
          detailFreeSet: 5,
          detailLockSet: -1,
          backRefreshEnabled: false,
          finishOnBlockedBack: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('穿山甲内容 SDK'),
        actions: [
          IconButton(
            tooltip: '初始化',
            onPressed: _loading ? null : _initialize,
            icon: const Icon(Icons.power_settings_new),
          ),
          IconButton(
            tooltip: '刷新推荐',
            onPressed: _started && !_loading ? _loadRecommended : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ConfigPanel(
              appIdController: _appIdController,
              adAppIdController: _adAppIdController,
              configController: _configController,
              status: _status,
              loading: _loading,
              initialized: _started,
              onInitialize: _initialize,
              onDiagnoseNetwork: _diagnoseNetwork,
              onLoadAll: _loadAll,
              onLoadRecommended: _loadRecommended,
              onLoadCategories: _loadCategories,
              onOpenDrawFeed: _openDrawFeed,
            ),
            _SearchPanel(
              enabled: _started && !_loading,
              searchController: _searchController,
              categoryController: _categoryController,
              categories: _categories,
              onSearch: _search,
              onCategoryInput: () => _loadByCategory(_categoryController.text),
              onCategoryTap: _loadByCategory,
            ),
            Expanded(
              child: _DramaList(
                dramas: _dramas,
                loading: _loading,
                onOpen: _open,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String get _initialAppId {
  if (_defaultAppId.isNotEmpty) return _defaultAppId;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _iosAppId,
    TargetPlatform.android => _androidAppId,
    _ => '',
  };
}

String get _initialAdAppId {
  if (_defaultAdAppId.isNotEmpty) return _defaultAdAppId;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _iosAdAppId,
    TargetPlatform.android => _androidAdAppId,
    _ => '',
  };
}

String get _initialConfigFile {
  if (_defaultConfigFile.isNotEmpty) return _defaultConfigFile;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _iosConfigFile,
    TargetPlatform.android => _androidConfigFile,
    _ => '',
  };
}

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.appIdController,
    required this.adAppIdController,
    required this.configController,
    required this.status,
    required this.loading,
    required this.initialized,
    required this.onInitialize,
    required this.onDiagnoseNetwork,
    required this.onLoadAll,
    required this.onLoadRecommended,
    required this.onLoadCategories,
    required this.onOpenDrawFeed,
  });

  final TextEditingController appIdController;
  final TextEditingController adAppIdController;
  final TextEditingController configController;
  final String status;
  final bool loading;
  final bool initialized;
  final VoidCallback onInitialize;
  final VoidCallback onDiagnoseNetwork;
  final VoidCallback onLoadAll;
  final VoidCallback onLoadRecommended;
  final VoidCallback onLoadCategories;
  final VoidCallback onOpenDrawFeed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: appIdController,
                  decoration: const InputDecoration(
                    labelText: 'AppLog AppID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: adAppIdController,
                  decoration: const InputDecoration(
                    labelText: '广告/媒体 ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: configController,
                  decoration: const InputDecoration(
                    labelText: '配置文件',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              FilledButton.icon(
                onPressed: loading ? null : onInitialize,
                icon: const Icon(Icons.play_arrow),
                label: const Text('初始化'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onDiagnoseNetwork,
                  icon: const Icon(Icons.network_check),
                  label: const Text('网络诊断'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: initialized && !loading ? onLoadRecommended : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('推荐'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: initialized && !loading ? onLoadAll : null,
                  icon: const Icon(Icons.grid_view),
                  label: const Text('全部'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: initialized && !loading ? onLoadCategories : null,
                  icon: const Icon(Icons.category),
                  label: const Text('分类'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: initialized && !loading ? onOpenDrawFeed : null,
              icon: const Icon(Icons.swipe_vertical),
              label: const Text('滑滑流'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.enabled,
    required this.searchController,
    required this.categoryController,
    required this.categories,
    required this.onSearch,
    required this.onCategoryInput,
    required this.onCategoryTap,
  });

  final bool enabled;
  final TextEditingController searchController;
  final TextEditingController categoryController;
  final List<String> categories;
  final VoidCallback onSearch;
  final VoidCallback onCategoryInput;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: '搜索短剧',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '搜索',
                onPressed: enabled ? onSearch : null,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: categoryController,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: '分类名',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onCategoryInput(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '按分类加载',
                onPressed: enabled ? onCategoryInput : null,
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ActionChip(
                    label: Text(category),
                    onPressed: enabled ? () => onCategoryTap(category) : null,
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: categories.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DramaList extends StatelessWidget {
  const _DramaList({
    required this.dramas,
    required this.loading,
    required this.onOpen,
  });

  final List<PangolinDrama> dramas;
  final bool loading;
  final ValueChanged<PangolinDrama> onOpen;

  @override
  Widget build(BuildContext context) {
    if (dramas.isEmpty) {
      return Center(
        child: Icon(
          loading ? Icons.hourglass_top : Icons.video_library_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.64,
      ),
      itemCount: dramas.length,
      itemBuilder: (context, index) {
        return _DramaCard(
          drama: dramas[index],
          onTap: () => onOpen(dramas[index]),
        );
      },
    );
  }
}

class _DramaCard extends StatelessWidget {
  const _DramaCard({required this.drama, required this.onTap});

  final PangolinDrama drama;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = drama.title ?? '短剧 ${drama.id}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xffeef4f2)),
                child: drama.coverUrl == null
                    ? const Icon(Icons.movie, size: 42)
                    : Image.network(
                        drama.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.movie, size: 42),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID ${drama.id}${drama.total == null ? '' : ' · ${drama.total} 集'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
