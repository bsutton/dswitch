import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';

import '../../channel.dart';

class StatusCommand extends Command<void> {
  String channel;
  StatusCommand(this.channel);

  @override
  String get description => '''
Displays the status of the $channel channel.
  The active version of the channel.
  Whether a later version is available for downloading.
  Whether the channel is pinned and the pinned version no.''';

  @override
  String get name => 'status';

  @override
  void run() {
    printStatus(channel);
  }

  static void printStatus(String channel) {
    var ch = Channel(channel);

    print(green('Status for channel $channel:'));
    print('Current Version: ${ch.currentVersion}');
    print('Is Pinned: ${ch.isPinned}');
    print('Lastest cached Version: ${ch.latestVersion}');
    print('Available for download: ${ch.fetchLatestVersion()}');
  }
}
