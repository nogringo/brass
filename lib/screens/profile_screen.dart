import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_widgets/functions/n_save_accounts_state.dart';
import 'package:toastification/toastification.dart';
import '../repository.dart';
import 'login_screen.dart';
import 'upload_video/upload_video_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ndk = Repository.ndk;
  Metadata? userMetadata;
  bool isLoading = true;
  NwcConnection? nwcConnection;
  bool isConnectingWallet = false;

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
          isLoading = false;
        });
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
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Settings'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Navigate to settings
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
        ],
      ),
    );
  }
}
