import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dswitch/dswitch.dart';
import 'package:dswitch/src/settings.dart';
import 'package:pubspec/pubspec.dart' as ps;

void main(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('verbose',
      abbr: 'v', defaultsTo: false, help: 'Dump verbose logging information');

  parser.addOption('stage2', abbr: '2', help: 'Stage 2');

  final parsed = parser.parse(args);
  Settings().setVerbose(enabled: parsed['verbose'] as bool);

  if (!parsed.wasParsed('stage2')) {
    runStage1();
  } else {
    var pathToDSwitch = parsed['stage2'] as String;
    runStage2(pathToDSwitch);
    exit(0);
  }

  print(orange('dswitch is ready to run'));
}

void runStage1() {
  if (!Shell.current.isPrivilegedUser) {
    if (Platform.isWindows) {
      print(red('Please run dswitch_install with Administrative privileges.'));
      exit(1);
    }
  }

  // build the path to the copy of bin/dswitch.dart in the pub cache.
  late final String pathToDSwitch;

  if (DartScript.self.isPubGlobalActivated) {
    pathToDSwitch = join(
      DartProject.fromCache('dswitch', packageVersion).pathToProjectRoot,
    );
  } else {
    /// Used when we are testing from local source
    pathToDSwitch = '.';
    print('dswitch located in: ${DartScript.self.pathToScript}');
  }

  if (!exists(join(pathToDSwitch, 'bin', 'dswitch_install.dart'))) {
    printerr(
        "Could not find dswitch_install in pub cache. Please run 'dart pub global activate dswitch' and try again.");
    exit(1);
  }

  withTempDir((compileDir) {
    copyTree(pathToDSwitch, compileDir);

    hackPubspecForDev(pathToDSwitch, compileDir);
    final installScript =
        DartScript.fromFile(join(compileDir, 'bin', 'dswitch_install.dart'));
    print('');
    print(blue('Compiling dswitch_install from ${truepath(pathToDSwitch)}'));
    DartSdk().runPubGet(compileDir, progress: Progress.printStdErr());
    installScript.compile(workingDirectory: compileDir);

    print('');
    print(blue('Compiling dswitch'));
    final dswitchScript =
        DartScript.fromFile(join(compileDir, 'bin', 'dswitch.dart'));
    dswitchScript.compile(workingDirectory: compileDir);

    // /// duplicate the script as we may not be able to copy ourselves
    // final duplicate =
    //     join(compileDir, '${script.basename}2${extension(script.basename)}');
    // copy(script.pathToExe, duplicate, overwrite: true);

    if (!Platform.isWindows) {
      print(green(
          'Please provide your sudo password so we can install dswitch into your PATH'));
    }
    print('');
    start('${installScript.pathToExe} --stage2=${dswitchScript.pathToExe}',
        privileged: true);
  }, keep: true);
}

/// during development we often have a dependency_override
/// with  a relative path
/// to dcli. This hack changes the relative path to an absolute path
/// so the copied pubspec.yaml will still function.
void hackPubspecForDev(String pathToDSwitch, String compileDir) {
  var pathToPubspec = truepath(compileDir, 'pubspec.yaml');
  var pubspec = PubSpec.fromFile(pathToPubspec);

  if (pubspec.dependencyOverrides.containsKey('dcli')) {
    var overrides = pubspec.dependencyOverrides;

    var dcli = overrides['dcli'];
    if (dcli!.reference is ps.PathReference) {
      var pathRef = dcli.reference as ps.PathReference;
      pathRef = ps.PathReference(truepath(pathToDSwitch, pathRef.path));

      final replacement = <String, Dependency>{};
      replacement.addAll(overrides);
      replacement['dcli'] = Dependency('dcli', pathRef);
      pubspec.dependencyOverrides = replacement;
      pubspec.saveToFile(pathToPubspec);
    }
  }
}

/// In stage 2 we are running from a compiled exe as a privilged user.
void runStage2(String pathToDSwitch) {
  var target = pathToInstallDir;

  if (!exists(pathToDSwitch)) {
    printerr(
        "Could not find dswitch in pub cache. Please run 'dart pub global activate dswitch' and try again.");
    exit(1);
  }

  print(blue('Installing dswitch into $target.'));
  copy(pathToDSwitch, target, overwrite: true);
  // save the version no. that we just installed so
  // that dswtich can check its running the current
  // version each time it starts.
  updateVersionNo();
  print('');
}

String get pathToInstallDir {
  String target;
  if (Platform.isWindows) {
    target = join(
        env['USERPROFILE']!, 'AppData', 'Local', 'Microsoft', 'WindowsApps');
  } else {
    target = '/usr/bin';
  }
  return target;
}
