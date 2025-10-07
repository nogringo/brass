import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../repository.dart';

class BlossomSettingsController extends GetxController {
  static BlossomSettingsController get to => Get.find();

  final RxList<String> servers = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  List<String> _originalServers = [];

  final serverUrlController = TextEditingController();
  final searchFocusNode = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxBool isSearchFocused = false.obs;
  final RxList<String> filteredSuggestions = <String>[].obs;

  // List of suggested blossom servers (ordered by popularity/references)
  final List<String> suggestedServers = [
    'https://blossom.primal.net',
    'https://nostr.download',
    'https://blossom.band',
    'https://cdn.nostrcheck.me',
    'https://24242.io',
    'https://nostrmedia.com',
    'https://nostr.media',
    'https://blsm.bostr.shop',
    'https://nosto.re',
    'https://nostr.build',
    'https://nostrcheck.me',
    'https://blossom.nosotros.app',
    'https://cdn.hzrd149.com',
    'https://blossom.nostr.build',
    'https://internationalright-wing.org',
    'https://files.v0l.io',
    'https://blossom.f7z.io',
    'https://blossom.yakihonne.com',
    'https://nostr.sudocarlos.com',
    'https://blsm.moonward.io',
    'https://23img.com',
    'https://files.sovbit.host',
    'https://void.cat',
    'https://image.nostr.build',
    'https://blossom.azzamo.net',
    'https://blossom.poster.place',
    'https://aegis.relayted.de',
    'https://bloss1.poster.place',
    'https://midia.eepy.express',
    'https://link.storjshare.io',
    'https://im.gurl.eu.org',
    'https://img.fzxx.xyz/index2',
    'https://cdn.sovbit.host',
    'https://pomf2.lain.la',
    'https://blossom2.puhcho.me',
    'https://mockingyou.com',
    'https://img.ax',
    'https://blossom.hzrd149.com',
    'https://storjshare.io',
    'https://blossom.westernbtc.com',
    'https://swarm.hivetalk.org',
    'https://blossom.highperfocused.tech',
    'https://imgdb.cn',
  ];

  @override
  void onInit() {
    super.onInit();
    loadServerList();
    serverUrlController.addListener(_onSearchChanged);
    searchFocusNode.addListener(_onFocusChanged);
    updateFilteredSuggestions();
  }

  @override
  void onClose() {
    serverUrlController.removeListener(_onSearchChanged);
    searchFocusNode.removeListener(_onFocusChanged);
    serverUrlController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = serverUrlController.text;
    updateFilteredSuggestions();
  }

  void _onFocusChanged() {
    isSearchFocused.value = searchFocusNode.hasFocus;
  }

  void updateFilteredSuggestions() {
    final query = searchQuery.value.toLowerCase().trim();

    if (query.isEmpty) {
      // Show all available servers when no search query
      filteredSuggestions.value = suggestedServers
          .where((server) => !servers.contains(server))
          .toList();
    } else {
      // Filter servers based on search query
      filteredSuggestions.value = suggestedServers
          .where(
            (server) =>
                !servers.contains(server) &&
                server.toLowerCase().contains(query),
          )
          .toList();
    }
  }

  Future<void> loadServerList() async {
    try {
      isLoading.value = true;
      final ndk = Repository.ndk;

      // Get the current user's pubkey
      final pubkey = ndk.accounts.getPublicKey();
      if (pubkey == null) {
        throw Exception('No user logged in');
      }

      final serverList = await ndk.blossomUserServerList.getUserServerList(
        pubkeys: [pubkey],
      );

      if (serverList != null && serverList.isNotEmpty) {
        servers.value = serverList;
        _originalServers = List.from(serverList);
      } else {
        _originalServers = [];
      }
    } catch (e) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Failed to load server list'),
          description: Text('$e'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasChanges {
    if (servers.length != _originalServers.length) return true;
    for (int i = 0; i < servers.length; i++) {
      if (servers[i] != _originalServers[i]) return true;
    }
    return false;
  }

  Future<void> saveServerList() async {
    try {
      isSaving.value = true;
      final ndk = Repository.ndk;

      await ndk.blossomUserServerList.publishUserServerList(
        serverUrlsOrdered: servers,
      );

      _originalServers = List.from(servers);

      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.success,
          title: const Text('Server list saved'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Failed to save server list'),
          description: Text('$e'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

  void addServer(String url) {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('URL cannot be empty'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('URL must start with http:// or https://'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (servers.contains(trimmedUrl)) {
      if (Get.context != null) {
        toastification.show(
          context: Get.context!,
          type: ToastificationType.error,
          title: const Text('Server already exists'),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
      return;
    }

    servers.add(trimmedUrl);
    serverUrlController.clear();
    updateFilteredSuggestions();
  }

  Future<void> confirmRemoveServer(int index) async {
    if (index < 0 || index >= servers.length) return;

    final server = servers[index];
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Server'),
        content: Text(
          'Are you sure you want to remove this server?\n\n$server',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      removeServer(index);
    }
  }

  void removeServer(int index) {
    if (index >= 0 && index < servers.length) {
      servers.removeAt(index);
      updateFilteredSuggestions();
    }
  }

  void moveServerUp(int index) {
    if (index > 0 && index < servers.length) {
      final server = servers.removeAt(index);
      servers.insert(index - 1, server);
    }
  }

  void moveServerDown(int index) {
    if (index >= 0 && index < servers.length - 1) {
      final server = servers.removeAt(index);
      servers.insert(index + 1, server);
    }
  }

  void reorderServer(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final server = servers.removeAt(oldIndex);
    servers.insert(newIndex, server);
  }
}
