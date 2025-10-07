import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_widgets/functions/n_save_accounts_state.dart';
import 'package:toastification/toastification.dart';
import '../repository.dart';
import '../models/nostr_video.dart';
import 'login_screen.dart';
import 'settings/blossom_settings_screen.dart';
import 'settings/theme_settings_screen.dart';
import 'upload_video/upload_video_screen.dart';
import 'video_player/video_player_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ndk = Repository.ndk;
  final Repository _repository = Repository.to;
  Metadata? userMetadata;
  bool isLoading = true;
  NwcConnection? nwcConnection;
  bool isConnectingWallet = false;
  List<NostrVideo> _userVideos = [];
  List<NostrVideo> _likedVideos = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey != null) {
      try {
        final metadata = await ndk.metadata.loadMetadata(pubkey);
        setState(() {
          userMetadata = metadata;
        });
        // Load user's videos and liked videos
        _loadUserVideos(pubkey);
        _loadLikedVideos(pubkey);
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserVideos(String pubkey) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _repository.fetchVideoEvents(limit: 100);
      final videos = _repository.getChannelVideos(pubkey);
      setState(() {
        _userVideos = videos;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLikedVideos(String pubkey) async {
    try {
      final likedVideos = await _repository.fetchLikedVideos(pubkey);
      setState(() {
        _likedVideos = likedVideos;
      });
    } catch (e) {
      // Failed to load liked videos
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _connectWallet() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect NWC Wallet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Wallet Connect URI',
            hintText: 'nostr+walletconnect://...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processWalletConnection(controller.text.trim());
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWalletConnection(String uri) async {
    if (uri.isEmpty) return;

    setState(() {
      isConnectingWallet = true;
    });

    try {
      final connection = await ndk.nwc.connect(
        uri,
        doGetInfoMethod: true,
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        nwcConnection = connection;
        isConnectingWallet = false;
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Wallet Connected'),
          description: Text(
            'Connected to ${connection.info?.alias ?? "wallet"}',
          ),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() {
        isConnectingWallet = false;
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Connection Failed'),
          description: Text(e.toString()),
          alignment: Alignment.bottomRight,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _disconnectWallet() {
    setState(() {
      nwcConnection = null;
    });

    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text('Wallet Disconnected'),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text('$label copied to clipboard'),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _shareProfile() {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Public Key (hex)'),
              subtitle: Text(
                pubkey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  _copyToClipboard(pubkey, 'Public key');
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pubkey = ndk.accounts.getPublicKey();
    final isLoggedIn = pubkey != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Profile'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text("Upload"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadVideoScreen(),
                    ),
                  );
                },
              ),
              SizedBox(width: 12),
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                SizedBox(width: 154),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (isLoggedIn && userMetadata?.picture != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userMetadata!.picture!),
                    )
                  else
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLoggedIn
                            ? (userMetadata?.name ??
                                  userMetadata?.displayName ??
                                  'Nostr User')
                            : 'Guest User',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (isLoggedIn) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: _shareProfile,
                          tooltip: 'Share profile',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoggedIn
                        ? (userMetadata?.about ?? pubkey)
                        : 'Not logged in',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!isLoggedIn)
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                        _loadUserData();
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Login with Nostr'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () async {
                        ndk.accounts.logout();
                        await nSaveAccountsState(ndk);
                        setState(() {
                          userMetadata = null;
                        });
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  const SizedBox(height: 32),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  if (isLoggedIn) ...[
                    ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      title: Text(
                        nwcConnection != null
                            ? 'Wallet: ${nwcConnection!.info?.alias ?? "Connected"}'
                            : 'Connect Wallet (NWC)',
                      ),
                      subtitle: isConnectingWallet
                          ? const Text('Connecting...')
                          : nwcConnection != null
                          ? const Text('Connected')
                          : null,
                      trailing: isConnectingWallet
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : nwcConnection != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _disconnectWallet,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            )
                          : Icon(
                              Icons.chevron_right,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      onTap: nwcConnection == null && !isConnectingWallet
                          ? _connectWallet
                          : null,
                    ),
                    Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.cloud_upload,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      title: const Text('Blossom Servers'),
                      subtitle: const Text('Configure file storage servers'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        Get.to(() => const BlossomSettingsScreen());
                      },
                    ),
                    Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Theme Settings'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      Get.to(() => const ThemeSettingsScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('About'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Navigate to about
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isLoggedIn && _userVideos.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Videos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_userVideos.length} video${_userVideos.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          if (isLoggedIn && _userVideos.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 16 / 12,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final video = _userVideos[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoPlayerScreen(video: video),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                image: video.thumbnailUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          video.thumbnailUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  if (video.thumbnailUrl == null)
                                    Center(
                                      child: Icon(
                                        Icons.play_circle_outline,
                                        size: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  if (video.duration != null)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .scrim
                                              .withValues(alpha: 0.87),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _formatDuration(video.duration),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _userVideos.length),
              ),
            ),
          if (isLoggedIn && _userVideos.isEmpty && !isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No videos yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload your first video to get started',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Liked Videos Section
          if (isLoggedIn && _likedVideos.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liked Videos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_likedVideos.length} video${_likedVideos.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          if (isLoggedIn && _likedVideos.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 16 / 12,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = _likedVideos[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VideoPlayerScreen(video: video),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  image: video.thumbnailUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            video.thumbnailUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    if (video.thumbnailUrl == null)
                                      Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          size: 40,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    if (video.duration != null)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .scrim
                                                .withValues(alpha: 0.87),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _formatDuration(video.duration),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                video.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _likedVideos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
