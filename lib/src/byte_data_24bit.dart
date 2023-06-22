import 'dart:typed_data';

extension ByteData24Bit on ByteData {
  /// Returns the (possibly negative) integer represented by the three bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between -2<sup>23</sup> and 2<sup>23</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 3` must be less than or equal to the length of this object.
  int getInt24(int byteOffset, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (getInt16(byteOffset, Endian.big) << 8) | getUint8(byteOffset + 2);
    } else {
      return getUint16(byteOffset, Endian.little) |
          (getInt8(byteOffset + 2) << 16);
    }
  }

  /// Returns the positive integer represented by the three bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between 0 and 2<sup>24</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 3` must be less than or equal to the length of this object.
  int getUint24(int byteOffset, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (getUint16(byteOffset, Endian.big) << 8) |
          getUint8(byteOffset + 2);
    } else {
      return getUint16(byteOffset, Endian.little) |
          (getUint8(byteOffset + 2) << 16);
    }
  }

  /// Sets the three bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in two bytes.
  ///
  /// In other words, [value] must lie
  /// between -2<sup>23</sup> and 2<sup>23</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 3` must be less than or equal to the length of this object.
  void setInt24(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      setInt16(byteOffset, value >> 8);
      setUint8(byteOffset + 2, value & 0xff);
    } else {
      setUint16(byteOffset, value & 0xffff);
      setInt8(byteOffset + 2, value >> 16);
    }
  }

  /// Sets the three bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in two bytes.
  ///
  /// In other words, [value] must be between
  /// 0 and 2<sup>24</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 3` must be less than or equal to the length of this object.
  void setUint24(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      setUint16(byteOffset, value >> 8);
      setUint8(byteOffset + 2, value & 0xff);
    } else {
      setUint16(byteOffset, value & 0xffff);
      setUint8(byteOffset + 2, value >> 16);
    }
  }
}
