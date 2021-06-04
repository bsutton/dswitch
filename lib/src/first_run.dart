import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:settings_yaml/settings_yaml.dart';

import 'constants.dart';

var pathToSettings = join(HOME, '.dswitch', 'settings.yaml');
void firstRun() {
  if (!exists(dirname(pathToSettings))) {
    createDir(dirname(pathToSettings), recursive: true);
  }

  if (!exists(pathToSettings)) {
    firstRunMessage();
  }

  final script = DartScript.self;
  if (!script.isCompiled) {
    print('Compiling dswitch so it will run independant of your dart version.');
    script.compile();

    /// replace the pub-cache script with a compiled version.
    copy(script.pathToExe, PubCache().pathToBin, overwrite: true);
    print(orange('Restart dswitch to run from the compiled version'));
  }

  var settings = SettingsYaml.load(
    pathToSettings: pathToSettings,
  );

  settings.save();
}

void firstRunMessage() {
  print('''

${green('Welcome to dswitch.')}

dswitch creates four symlinks that you can use from your IDE:
active: $activeSymlinkPath
stable: $stableSymlinkPath
beta: $betaSymlinkPath
dev: $devSymlinkPath

The active symlink must be added to your path.

The channel symlinks can be configured in your IDE on a per project basis.

  ''');

  if (!exists(pathToSettings)) {
    if (Platform.isWindows) {
      windowsFirstRun();
    } else if (Platform.isLinux) {
      linuxFirstRun();
    } else if (Platform.isMacOS) {
      macosxFirstRun();
    }
  }
}

void macosxFirstRun() {}

void linuxFirstRun() {}

void windowsFirstRun() {
  var pre = Shell.current.checkInstallPreconditions();
  if (pre != null) {
    printerr(red(pre));
    exit(1);
  }
}
