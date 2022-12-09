import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:pub_update_checker/pub_update_checker.dart';

const decoder = Utf8Decoder();
const help = '''
Usage:
  oie [editor] [path]

Editor options:
  as:  Android Studio
  asp: Android Studio Preview
  xc:  Xcode
  xcb: Xcode-beta

Path is the path to the flutter project folder. If path is not provided, the current directory will be used.
''';

final magentaPen = AnsiPen()..magenta();
final greenPen = AnsiPen()..green();
final yellowPen = AnsiPen()..yellow();
final redPen = AnsiPen()..red();

void main(List<String> arguments) async {
  if (Platform.isWindows) {
    print(redPen('This tool is not supported on Windows'));
    exit(1);
  }

  final newVersion = await PubUpdateChecker.check();
  if (newVersion != null) {
    print(
      yellowPen(
        'There is an update available: $newVersion. Run `dart pub global activate puby` to update.',
      ),
    );
  }

  if (arguments.first == 'help' || arguments.isEmpty) {
    print(magentaPen(help));
  }

  final editorArg = arguments[0];
  final editor = Editor.values.asNameMap()[arguments.first];
  if (editor == null) {
    print(redPen('Invalid editor option: $editorArg'));
    print(magentaPen(help));
    exit(1);
  }

  final pathArg = arguments.length > 1 ? arguments[1] : '.';
  final path =
      Directory('$pathArg/example').existsSync() ? '$pathArg/example' : pathArg;

  final projectFilePath = '$path/${editor.projectFilePath}';
  if (!File(projectFilePath).existsSync()) {
    print(redPen('${editor.projectType} project not found in path: $path'));
    exit(1);
  }

  final result = Process.runSync(
    'open',
    [projectFilePath, '-a', editor.application],
  );

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

  String get projectFilePath {
    switch (this) {
      case Editor.as:
      case Editor.asp:
        return 'android/build.gradle';
      case Editor.xc:
      case Editor.xcb:
        return 'ios/Runner.xcworkspace';
    }
  }

  String get projectType {
    switch (this) {
      case Editor.as:
      case Editor.asp:
        return 'Android';
      case Editor.xc:
      case Editor.xcb:
        return 'iOS';
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
