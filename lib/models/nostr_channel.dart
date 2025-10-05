import 'package:ndk/ndk.dart';

class NostrChannel {
  final String pubkey;
  final String? name;
  final String? about;
  final String? picture;
  final String? banner;
  final String? nip05;

  NostrChannel({
    required this.pubkey,
    this.name,
    this.about,
    this.picture,
    this.banner,
    this.nip05,
  });

  factory NostrChannel.fromMetadata(String pubkey, Metadata? metadata) {
    if (metadata == null) {
      return NostrChannel(pubkey: pubkey);
    }

    return NostrChannel(
      pubkey: pubkey,
      name: metadata.name,
      about: metadata.about,
      picture: metadata.picture,
      banner: metadata.banner,
      nip05: metadata.nip05,
    );
  }

  String get displayName => name ?? pubkey.substring(0, 16);
}
