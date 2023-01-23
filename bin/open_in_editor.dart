import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:pub_update_checker/pub_update_checker.dart';

import 'oie_config.dart';

const defaultNixAliases = {
  'as': OieAlias(ProjectType.android, 'Android Studio'),
  'asp': OieAlias(ProjectType.android, 'Android Studio Preview'),
  'xc': OieAlias(ProjectType.ios, 'Xcode'),
  'xcb': OieAlias(ProjectType.ios, 'Xcode-beta'),
};

const defaultWindowsAliases = {
  'as': OieAlias(
    ProjectType.android,
    'C:/Program Files/Android/Android Studio/bin/studio64.exe',
  ),
  'asp': OieAlias(
    ProjectType.android,
    'C:/Program Files/Android/Android Studio Preview/bin/studio64.exe',
  ),
};

const decoder = Utf8Decoder();
const help = '''
Usage:
  oie [alias] [path]

Default aliases:
  as:  Android Studio
  asp: Android Studio Preview
  xc:  Xcode
  xcb: Xcode-beta

Path is the path to the flutter project folder. If path is not provided, the current directory will be used.
Aliases can be configured using the ~/.oie.yaml file. See the README for more information.''';

final magentaPen = AnsiPen()..magenta();
final greenPen = AnsiPen()..green();
final yellowPen = AnsiPen()..yellow();
final redPen = AnsiPen()..red();

void main(List<String> arguments) async {
  final config = OieConfig.fromYaml();

  final Map<String, OieAlias> aliases;
  if (Platform.isWindows) {
    aliases = {...defaultWindowsAliases, ...?config?.aliases};
  } else {
    aliases = {...defaultNixAliases, ...?config?.aliases};
  }

  final newVersion = await PubUpdateChecker.check();
  if (newVersion != null) {
    print(
      yellowPen(
        'There is an update available: $newVersion. Run `dart pub global activate open_in_editor` to update.',
      ),
    );
  }

  if (arguments.isEmpty || arguments.first == 'help') {
    print(magentaPen(help));
    exit(1);
  }

  final aliasArg = arguments[0];
  final alias = aliases[aliasArg];
  if (alias == null) {
    print(redPen('Invalid alias: $aliasArg'));
    print(magentaPen(help));
    exit(1);
  }

  final pathArg = arguments.length > 1 ? arguments[1] : '.';
  // Plugin projects should have a flutter project in the example folder
  final path =
      Directory('$pathArg/example').existsSync() ? '$pathArg/example' : pathArg;

  final projectError = redPen(
    '${alias.type} project not found in path: $path\nFlutter plugin projects must contain a valid example project',
  );

  final type = alias.type;
  final FileSystemEntity projectEntity;
  switch (type) {
    case ProjectType.android:
      // Plugin project root/android/app does not exist
      // This will happen if a valid example project does not exist
      if (!Directory('$path/android/app').existsSync()) {
        print(projectError);
        exit(1);
      }
      projectEntity = File('$path/android/build.gradle');
      break;
    case ProjectType.ios:
      projectEntity = Directory('$path/ios/Runner.xcworkspace');
      break;
  }
  if (!projectEntity.existsSync()) {
    print(projectError);
    exit(1);
  }

  final ProcessResult result;
  if (Platform.isWindows) {
    result = Process.runSync(alias.path, [projectEntity.path]);
  } else {
    result = Process.runSync('open', [projectEntity.path, '-a', alias.path]);
  }

  final resultStdout = result.stdout;
  final resultStderr = result.stderr;

  if (resultStdout is String && resultStdout.isNotEmpty) {
    stdout.write(result.stdout);
  }
  if (resultStderr is String && resultStderr.isNotEmpty) {
    stderr.write(redPen(result.stderr));
  }
  exit(result.exitCode);
}
