
import 'dart:typed_data';

extension ByteData24Bit on ByteData
{
  /// Returns the (possibly negative) integer represented by the three bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between -2<sup>23</sup> and 2<sup>23</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 3` must be less than or equal to the length of this object.
  int getInt24(int byteOffset, [Endian endian = Endian.big])
  {
    if (endian == Endian.big)
    {
      return (this.getInt16(byteOffset,Endian.big)<<8)|this.getUint8(byteOffset+2);
    }
    else
    {
      return this.getUint16(byteOffset,Endian.little)|(this.getInt8(byteOffset+2)<<16);
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
  int getUint24(int byteOffset, [Endian endian = Endian.big])
  {
    if (endian == Endian.big)
    {
      return (this.getUint16(byteOffset,Endian.big)<<8)|this.getUint8(byteOffset+2);
    }
    else
    {
      return this.getUint16(byteOffset,Endian.little)|(this.getUint8(byteOffset+2)<<16);
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
  void setInt24(int byteOffset, int value, [Endian endian = Endian.big])
  {
    if (endian == Endian.big)
    {
      this.setInt16(byteOffset, value>>8);
      this.setUint8(byteOffset+2, value&0xff);
    }
    else
    {
      this.setUint16(byteOffset, value&0xffff);
      this.setInt8(byteOffset+2, value>>16);
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
  void setUint24(int byteOffset, int value, [Endian endian = Endian.big])
  {
    if (endian == Endian.big)
    {
      this.setUint16(byteOffset, value>>8);
      this.setUint8(byteOffset+2, value&0xff);
    }
    else
    {
      this.setUint16(byteOffset, value&0xffff);
      this.setUint8(byteOffset+2, value>>16);
    }
  }
}