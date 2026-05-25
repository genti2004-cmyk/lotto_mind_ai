enum VewSystemType {
  vew3,
  vew4,
  vew5,
  vew6,
  vew7_3,
  vew8_4,
  vew9_4,
  vew9_5,
  vew10_5,
}

extension VewSystemTypeX on VewSystemType {
  int get selectedCount {
    switch (this) {
      case VewSystemType.vew3:
        return 3;
      case VewSystemType.vew4:
        return 4;
      case VewSystemType.vew5:
        return 5;
      case VewSystemType.vew6:
        return 6;
      case VewSystemType.vew7_3:
        return 7;
      case VewSystemType.vew8_4:
        return 8;
      case VewSystemType.vew9_4:
        return 9;
      case VewSystemType.vew9_5:
        return 9;
      case VewSystemType.vew10_5:
        return 10;
    }
  }

  int get guaranteeHits {
    switch (this) {
      case VewSystemType.vew3:
        return 3;
      case VewSystemType.vew4:
        return 4;
      case VewSystemType.vew5:
        return 5;
      case VewSystemType.vew6:
        return 6;
      case VewSystemType.vew7_3:
        return 3;
      case VewSystemType.vew8_4:
        return 4;
      case VewSystemType.vew9_4:
        return 4;
      case VewSystemType.vew9_5:
        return 5;
      case VewSystemType.vew10_5:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case VewSystemType.vew3:
        return 'VEW 3';
      case VewSystemType.vew4:
        return 'VEW 4';
      case VewSystemType.vew5:
        return 'VEW 5';
      case VewSystemType.vew6:
        return 'VEW 6';
      case VewSystemType.vew7_3:
        return 'VEW 7-3';
      case VewSystemType.vew8_4:
        return 'VEW 8-4';
      case VewSystemType.vew9_4:
        return 'VEW 9-4';
      case VewSystemType.vew9_5:
        return 'VEW 9-5';
      case VewSystemType.vew10_5:
        return 'VEW 10-5';
    }
  }
}