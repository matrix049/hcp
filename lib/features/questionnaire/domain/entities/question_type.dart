/// All question types the app is designed to support. Only a subset is
/// implemented now (see [QuestionWidgetFactory]); the rest are reserved so the
/// engine stays extensible — adding one later is a single new `case`.
enum QuestionType {
  // --- Implemented now ---
  text,
  number,
  radio,
  checkbox,
  dropdown,
  date,

  // --- Reserved for later (render a graceful placeholder for now) ---
  textarea,
  decimal,
  time,
  datetime,
  boolean, // a.k.a. switch
  slider,
  image,
  gps,
  signature,
  barcode,
  qr,
  file,
  section,
  note,

  /// Unknown / unrecognised type in the JSON.
  unknown;

  /// Maps a raw JSON `type` string to a [QuestionType], accepting common
  /// synonyms so surveys authored with either naming convention work.
  static QuestionType parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'text':
        return text;
      case 'textarea':
        return textarea;
      case 'number':
      case 'integer':
        return number;
      case 'decimal':
      case 'float':
        return decimal;
      case 'date':
        return date;
      case 'time':
        return time;
      case 'datetime':
        return datetime;
      case 'radio':
      case 'single_choice':
        return radio;
      case 'checkbox':
      case 'multi_choice':
        return checkbox;
      case 'dropdown':
      case 'select':
        return dropdown;
      case 'boolean':
      case 'switch':
        return boolean;
      case 'slider':
        return slider;
      case 'image':
        return image;
      case 'gps':
        return gps;
      case 'signature':
        return signature;
      case 'barcode':
        return barcode;
      case 'qr':
        return qr;
      case 'file':
        return file;
      case 'section':
        return section;
      case 'note':
        return note;
      default:
        return unknown;
    }
  }
}
