enum SystemMode {
  normal,
  full,
  vew,
}

extension SystemModeX on SystemMode {
  String get label {
    switch (this) {
      case SystemMode.normal:
        return 'Normalschein';
      case SystemMode.full:
        return 'Vollsystem';
      case SystemMode.vew:
        return 'Intervall';
    }
  }
}