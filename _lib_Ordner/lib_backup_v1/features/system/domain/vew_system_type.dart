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
        return 'Intervall 3';
      case VewSystemType.vew4:
        return 'Intervall 4';
      case VewSystemType.vew5:
        return 'Intervall 5';
      case VewSystemType.vew6:
        return 'Intervall 6';
      case VewSystemType.vew7_3:
        return 'Intervall 7-3';
      case VewSystemType.vew8_4:
        return 'Intervall 8-4';
      case VewSystemType.vew9_4:
        return 'Intervall 9-4';
      case VewSystemType.vew9_5:
        return 'Intervall 9-5';
      case VewSystemType.vew10_5:
        return 'Intervall 10-5';
    }
  }
}