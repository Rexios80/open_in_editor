import 'dart:io';

import 'package:yaml/yaml.dart';

class OieConfig {
  final Map<String, OieAlias> aliases;

  const OieConfig({required this.aliases});

  static OieConfig? fromYaml() {
    final file = File('$_home/.oie.yaml');
    if (!file.existsSync()) return null;

    final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
    final aliases = (yaml['aliases'] as YamlMap)
        .cast<String, dynamic>()
        .map((k, v) => MapEntry(k, OieAlias.fromYaml(v)));
    return OieConfig(aliases: aliases);
  }
}

final _home =
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;

class OieAlias {
  final ProjectType type;
  final String path;

  const OieAlias(this.type, this.path);

  factory OieAlias.fromYaml(YamlMap yaml) {
    return OieAlias(
      ProjectType.values.byName(yaml['type']),
      yaml['path'],
    );
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
