Quickly open a Flutter project in the requested editor for native code development

## NOTE

This tool is currently not supported on Windows

## Installation

```console
$ dart pub global activate open_in_editor
```

## Usage

```console
$ oie [editor] [path]
```

Supported editors
| Alias | Editor                 |
| ----- | ---------------------- |
| as    | Android Studio         |
| asp   | Android Studio Preview |
| xc    | Xcode                  |
| xcb   | Xcode Beta             |

Path is the path to the flutter project folder. If path is not provided, the current directory will be used.
