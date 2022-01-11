// TODO: Put public facing types in this file.

import 'dart:typed_data';

class WavContent {
  final List<Int16List> samplesForChannel;
  final int numChannels;
  final int bitsPerSample;
  final int sampleRate;
  final int numSamples;
  WavContent(this.numChannels, this.sampleRate, this.bitsPerSample,
      this.numSamples, this.samplesForChannel) {
    assert(samplesForChannel.length == numChannels);
    assert(numChannels > 0);
    assert(numChannels <= 18);
  }
  factory WavContent.fromBytes(ByteData data) {
    return _parseWav(data);
  }
  ByteData toBytes() {
    int bitsPerSample = this.bitsPerSample > 16 ? 16 : this.bitsPerSample;

    int bytesPerSample = (bitsPerSample + 7) ~/ 8;

    var actualDataInBytes = numSamples * numChannels * bytesPerSample;
    actualDataInBytes =
        (actualDataInBytes + 1) & (~1); //we better make it even.

    var data = ByteData(44 + actualDataInBytes);

    data.setUint32(0, RIFF_ID, Endian.big);
    data.setUint32(4, 36 + actualDataInBytes, Endian.little);
    data.setUint32(8, WAVE_ID, Endian.big);
    data.setUint32(12, fmt_ID, Endian.big);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, WAVE_FORMAT_PCM, Endian.little);
    data.setUint16(22, numChannels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(
        28, bytesPerSample * numChannels * sampleRate, Endian.little);
    data.setUint16(32, bytesPerSample * numChannels, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    data.setUint32(36, data_ID, Endian.big);
    data.setUint32(
        40, numSamples * numChannels * bytesPerSample, Endian.little);
    var currentDataOffset = 44;
    if (bytesPerSample == 2) {
      for (int s = 0; s < numSamples; ++s) {
        for (int ch = 0; ch < numChannels; ++ch) {
          data.setInt16(
              currentDataOffset, samplesForChannel[ch][s], Endian.little);
          currentDataOffset += 2;
        }
      }
    } else if (bytesPerSample == 1) {
      for (int s = 0; s < numSamples; ++s) {
        for (int ch = 0; ch < numChannels; ++ch) {
          data.setUint8(currentDataOffset, samplesForChannel[ch][s]);
          currentDataOffset++;
        }
      }
    }
    return data;
  }
}

const RIFF_ID = 0x52494646; // 0x52494646 == 'RIFF'
const WAVE_ID = 0x57415645; // 0x57415645 == 'WAVE'
const fmt_ID = 0x666d7420; // 0x666d7420 == 'fmt '
const data_ID = 0x64617461; // 0x64617461 == 'data'
const fact_ID = 0x66616374; // 0x64617461 == 'fact'
const cue_ID = 0x63756520; // 0x666d7420 == 'cue '
//I haven't found information on the following, but audacity exports floats with
//this chunk.
const PEAK_ID = 0x5045414B; // 0x5045414B == 'PEAK'

const WAVE_FORMAT_PCM = 0x0001;
const WAVE_FORMAT_IEEE_FLOAT = 0x0003;

/* channel ordering
1. Front Left - FL
2. Front Right - FR
3. Front Center - FC
4. Low Frequency - LF
5. Back Left - BL
6. Back Right - BR
7. Front Left of Center - FLC
8. Front Right of Center - FRC
9. Back Center - BC
10. Side Left - SL
11. Side Right - SR
12. Top Center - TC
13. Top Front Left - TFL
14. Top Front Center - TFC
15. Top Front Right - TFR
16. Top Back Left - TBL
17. Top Back Center - TBC
18. Top Back Right - TBR
*/

WavContent _parseWav(ByteData data) {
  List<Int16List> samplesForChannel;
  if (data.lengthInBytes <= 44) {
    throw ArgumentError("input buffer is too small");
  }
  int ckID = data.getUint32(0, Endian.big); //intent. big endian
  if (ckID != RIFF_ID) {
    throw ArgumentError("unexpected chunkID");
  }
  int ckSize = data.getUint32(4, Endian.little);
  if (ckSize + 8 > data.lengthInBytes) {
    throw ArgumentError(
        "could not read that much data in supplied buffer ($ckSize)");
  }

  int fmtId = data.getUint32(8, Endian.big);
  if (fmtId != WAVE_ID) {
    throw ArgumentError("unexpected fmtId");
  }
  int subCkFmtId = data.getUint32(12, Endian.big);
  if (subCkFmtId != fmt_ID) {
    throw ArgumentError("unexpected subCkFmtId");
  }
  int subCkFmtSize = data.getUint32(16, Endian.little);
  int wFormatTag = data.getUint16(20, Endian.little);
  if (wFormatTag != WAVE_FORMAT_PCM && wFormatTag != WAVE_FORMAT_IEEE_FLOAT) {
    throw ArgumentError("unsupported format");
  }
  if (subCkFmtSize != 16 && wFormatTag == WAVE_FORMAT_PCM) {
    throw ArgumentError(
        "fmt subChunk expected to have 16 bytes of data in PCM");
  }
  if (subCkFmtSize + 20 > data.lengthInBytes) {
    throw ArgumentError(
        "could not read that much data in supplied buffer ($subCkFmtSize)");
  }
  int numChannels = data.getUint16(22, Endian.little);
  if (numChannels > 18) {
    throw ArgumentError("number of channels is not supported.");
  }
  int sampleRate = data.getUint32(24, Endian.little);
  if (sampleRate == 0) {
    throw ArgumentError("invalid sample rate");
  }
  int byteRate = data.getUint32(28, Endian.little);
  int blockAlign = data.getUint16(32, Endian.little);

  int bitsPerSample = data.getUint16(34, Endian.little);
  if (bitsPerSample == 0) throw ArgumentError("bits per sample cannot be zero");
  int bytesPerSample = (bitsPerSample + 7) ~/ 8;
  if (wFormatTag == WAVE_FORMAT_PCM && bitsPerSample > 24) {
    throw ArgumentError(
        "PCM allows bits per sample of 1-24. got $bitsPerSample");
  }
  if (blockAlign != bytesPerSample * numChannels) {
    throw ArgumentError("bad block alignment. got $blockAlign");
  }
  if (byteRate != bytesPerSample * numChannels * sampleRate) {
    throw ArgumentError("bad bytes per second. got $byteRate");
  }
  if (wFormatTag == WAVE_FORMAT_IEEE_FLOAT && bitsPerSample != 32) {
    throw ArgumentError(
        "floats should have 32 bits per sample. got $bitsPerSample instead.");
  }
  int additionalOffset = 36;
  if (subCkFmtSize > 16) {
    int ckExtSize = data.getUint16(36, Endian.little);
    if (ckExtSize != 0 && ckExtSize != 22) {
      throw ArgumentError("invalid extension size");
    }
    if (ckExtSize == 22) {
      throw ArgumentError("extensions are not supported :(");
    }
    additionalOffset += 2 + ckExtSize;
  }
  int nextSubCkFmtId = data.getUint32(additionalOffset, Endian.big);
  int nextSubCkFmtSize = data.getUint32(additionalOffset + 4, Endian.little);
  if (additionalOffset + 4 + nextSubCkFmtSize > data.lengthInBytes) {
    throw ArgumentError(
        "could not read that much data in supplied buffer ($nextSubCkFmtSize), ${data.lengthInBytes}");
  }
  int fmtBitMask = 0;
  while (nextSubCkFmtId == fact_ID ||
      nextSubCkFmtId == PEAK_ID || nextSubCkFmtId == cue_ID) // I hope they are not using compressions
  {
    if ((fmtBitMask & nextSubCkFmtId ) != 0) {
      throw ArgumentError("duplicate entry");
    }
    fmtBitMask |= nextSubCkFmtId & 0x40f;
    //print("found fact section, skipping ${8 + nextSubCkFmtSize} bytes");
    //do not handle this, just skip to data section.
    additionalOffset += 8 + nextSubCkFmtSize;

    nextSubCkFmtId = data.getUint32(additionalOffset, Endian.big);
    nextSubCkFmtSize = data.getUint32(additionalOffset + 4, Endian.little);
    if (additionalOffset + 4 + nextSubCkFmtSize > data.lengthInBytes) {
      throw ArgumentError(
          "could not read that much data in supplied buffer ($nextSubCkFmtSize)");
    }
  }
  if (nextSubCkFmtId == data_ID) {
    int samples = nextSubCkFmtSize ~/ (numChannels * bytesPerSample);
    samplesForChannel =
        List.generate(numChannels, (index) => Int16List(samples));
    int currentDataOffset = additionalOffset + 8;
    //go ahead, read the data (interleaved).
    if (wFormatTag == WAVE_FORMAT_PCM) {
      if (bytesPerSample == 1) {
        for (int s = 0; s < samples; ++s) {
          for (int ch = 0; ch < numChannels; ++ch) {
            samplesForChannel[ch][s] = data.getUint8(currentDataOffset);
            currentDataOffset++;
          }
        }
      }
      if (bytesPerSample == 2) {
        for (int s = 0; s < samples; ++s) {
          for (int ch = 0; ch < numChannels; ++ch) {
            samplesForChannel[ch][s] =
                data.getInt16(currentDataOffset, Endian.little);
            currentDataOffset += 2;
          }
        }
      }
      if (bytesPerSample == 3) {
        int bitRounding = bytesPerSample * 8 - bitsPerSample;
        if (bitRounding == 0) {
          for (int s = 0; s < samples; ++s) {
            for (int ch = 0; ch < numChannels; ++ch) {
              samplesForChannel[ch][s] =
                  data.getInt16(currentDataOffset + 1, Endian.little);
              currentDataOffset += 3;
            }
          }
        } else {
          for (int s = 0; s < samples; ++s) {
            for (int ch = 0; ch < numChannels; ++ch) {
              samplesForChannel[ch][s] =
                  data.getInt16(currentDataOffset + 1, Endian.little) <<
                      bitRounding + data.getUint8(currentDataOffset) >>
                      (8 - bitRounding);
              currentDataOffset += 3;
            }
          }
        }
      }
    } else //floats
    {
      for (int s = 0; s < samples; ++s) {
        for (int ch = 0; ch < numChannels; ++ch) {
          samplesForChannel[ch][s] =
              (data.getFloat32(currentDataOffset, Endian.little) * 32768)
                  .toInt();
          currentDataOffset += 4;
        }
      }
    }
    return WavContent(
        numChannels, sampleRate, bitsPerSample, samples, samplesForChannel);
  } else {
    throw ArgumentError("missing data chunk");
  }
}
