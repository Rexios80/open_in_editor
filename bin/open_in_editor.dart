import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:pub_update_checker/pub_update_checker.dart';

const decoder = Utf8Decoder();
const help = '''
Usage:
  oie [editor] [path]

Supported editors:
  as:  Android Studio
  asp: Android Studio Preview
  xc:  Xcode
  xcb: Xcode-beta

Path is the path to the flutter project folder. If path is not provided, the current directory will be used.''';

final magentaPen = AnsiPen()..magenta();
final greenPen = AnsiPen()..green();
final yellowPen = AnsiPen()..yellow();
final redPen = AnsiPen()..red();

void main(List<String> arguments) async {
  if (Platform.isWindows) {
    // TODO: Is this possible without user configuration?
    print(redPen('This tool is currently not supported on Windows'));
    exit(1);
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

  final editorArg = arguments[0];
  final editor = Editor.values.asNameMap()[arguments.first];
  if (editor == null) {
    print(redPen('Invalid editor option: $editorArg'));
    print(magentaPen(help));
    exit(1);
  }

  final pathArg = arguments.length > 1 ? arguments[1] : '.';
  // Plugin projects should have a flutter project in the example folder
  final path =
      Directory('$pathArg/example').existsSync() ? '$pathArg/example' : pathArg;

  final projectError = redPen(
    '${editor.projectType} project not found in path: $path\nFlutter plugin projects must contain a valid example project',
  );

  final projectType = editor.projectType;
  final FileSystemEntity projectEntity;
  switch (projectType) {
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

  final result =
      Process.runSync('open', [projectEntity.path, '-a', editor.application]);

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

enum Editor {
  as,
  asp,
  xc,
  xcb;

  ProjectType get projectType {
    switch (this) {
      case Editor.as:
      case Editor.asp:
        return ProjectType.android;
      case Editor.xc:
      case Editor.xcb:
        return ProjectType.ios;
    }
  }

  String get application {
    switch (this) {
      case Editor.as:
        return 'Android Studio';
      case Editor.asp:
        return 'Android Studio Preview';
      case Editor.xc:
        return 'Xcode';
      case Editor.xcb:
        return 'Xcode-beta';
    }
  }
}

enum ProjectType {
  android,
  ios;

  @override
  String toString() {
    switch (this) {
      case ProjectType.android:
        return 'Android';
      case ProjectType.ios:
        return 'iOS';
    }
  }
}
