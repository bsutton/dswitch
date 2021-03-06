@Timeout(Duration(minutes: 10))
import 'package:dcli/dcli.dart';
import 'package:dswitch/dswitch.dart';
import 'package:dswitch/src/settings.dart';
import 'package:settings_yaml/settings_yaml.dart';
import 'package:test/test.dart';

void main() {
  test('no directory', () {
    if (exists(dirname(pathToSettings))) deleteDir(dirname(pathToSettings));
    // no directory
    expect(settingsExist, isFalse);
    expect(isCurrentVersionInstalled, isFalse);
  }, skip: true);
  test('no file', () {
    createSettings();

    // No file
    delete(pathToSettings);
    expect(settingsExist, isFalse);
    expect(isCurrentVersionInstalled, isFalse);
  });
  test('no version', () {
    createSettings();

    // No version
    var settings = SettingsYaml.load(
      pathToSettings: pathToSettings,
    );
    settings['version'] = null;
    settings.save();
    expect(settingsExist, isTrue);
    expect(isCurrentVersionInstalled, isFalse);
  });

  test('old version', () {
    createSettings();

    var settings = SettingsYaml.load(
      pathToSettings: pathToSettings,
    );

    settings['version'] = '0.0.1';
    settings.save();

    expect(settingsExist, isTrue);
    expect(isCurrentVersionInstalled, isFalse);
  });

  test('current version', () {
    createSettings();
    var settings = SettingsYaml.load(
      pathToSettings: pathToSettings,
    );

    settings['version'] = '0.0.1';
    settings.save();
    expect(settingsExist, isTrue);

    expect(isCurrentVersionInstalled, isFalse);
  });

  test('update version', () {
    createSettings();
    var settings = SettingsYaml.load(
      pathToSettings: pathToSettings,
    );

    settings['version'] = '0.0.1';
    settings.save();

    updateVersionNo();

    expect(settingsExist, isTrue);

    withTempDir((mockCache) {
      PubCache.reset();
      env[PubCache.envVarPubCache] = mockCache;
      final pubCache = PubCache();
      createDir(join(pubCache.pathToDartLang, 'dswitch-3.3.0'),
          recursive: true);
      createDir(join(pubCache.pathToDartLang, 'dswitch-4.0.1'));
      createDir(join(pubCache.pathToDartLang, 'dswitch-4.0.3'));

      expect(isCurrentVersionInstalled, isFalse);

      createDir(join(pubCache.pathToDartLang, 'dswitch-$packageVersion'));

      expect(isCurrentVersionInstalled, isTrue);
    });
  });
}
