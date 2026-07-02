# wav_io

A high-performance, pure Dart library for reading, writing, streaming, and manipulating RIFF-WAV audio files. It operates directly on binary `ByteData` buffers, providing flexible access to audio samples without native dependencies.

## Features

- **Broad Format Support**: Read and write 8-bit unsigned PCM, 16-bit/24-bit/32-bit signed PCM, and 32-bit/64-bit IEEE floating-point formats.
- **RIFF & RIFX Support**: Full compatibility with both standard little-endian (RIFF) and big-endian (RIFX) byte orderings.
- **Streaming Reads**: Use `WavReader` to read audio chunks and seek to arbitrary positions on the fly, keeping memory footprint low.
- **Streaming Writes**: Use `WavWriter` to stream and write audio chunks to disk sequentially, minimizing memory overhead.
- **Multichannel & Channel Masks**: Supports speaker layout configurations (mono, stereo, quad, 5.1 surround) using standardized channel mask structures.
- **Metadata Management**: Access, edit, and write standard LIST INFO fields (e.g., track name, artist, album, genre, year).
- **Quantization Dithering**: Offers high-quality Triangular Probability Density Function (TPDF) dithering for reducing quantization distortion when downsampling.

---

## Getting Started

Add the `wav_io` package to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  wav_io: ^3.0.0
```

Run `pub get` or `flutter pub get` to install the package.

---

## Storage & Format Mapping

Audio data is managed internally using memory-efficient typed lists via dedicated storage classes:

| WAV Format | Bit Depth | Internal Storage Class | Typed Array | Amplitude Range |
|---|---|---|---|---|
| **PCM 8-bit** | 8 bit | `Uint8Storage` | `Uint8List` | `0` to `255` (Silence at `128`) |
| **PCM 16-bit** | 16 bit | `Int16Storage` | `Int16List` | `-32768` to `32767` |
| **PCM 24-bit / 32-bit** | 24 / 32 bit | `Int32Storage` | `Int32List` | `-2147483648` to `2147483647` |
| **IEEE Float 32-bit** | 32 bit | `Float32Storage` | `Float32List` | `-1.0` to `1.0` |
| **IEEE Float 64-bit** | 64 bit | `Float64Storage` | `Float64List` | `-1.0` to `1.0` |

---

## Usage Examples

### 1. Reading a WAV File

To read a WAV file, read its bytes as `ByteData` and decode using `loadWav`:

```dart
import 'dart:io';
import 'package:wav_io/wav_io.dart';

void main() {
  final bytes = File('input.wav').readAsBytesSync();
  final result = loadWav(bytes.buffer.asByteData());

  result.match(
    onOk: (wav) {
      print("Channels: ${wav.numChannels}");
      print("Sample Rate: ${wav.sampleRate} Hz");
      print("Duration: ${wav.duration} seconds");
      
      // Access sample data for channel 0
      final storage = wav.samplesStorage;
      if (storage is Int16Storage) {
        final samples = storage.samplesData[0];
        print("First sample: ${samples[0]}");
      }
    },
    onError: (error) {
      print("Error loading WAV: $error");
    },
  );
}
```

### 2. Writing a WAV File

Create an audio storage container, populate the samples, and serialize it to disk:

```dart
import 'dart:io';
import 'package:wav_io/wav_io.dart';

void main() {
  final int sampleRate = 44100;
  final int numSamples = 44100 * 2; // 2 seconds
  
  // Allocate mono 16-bit storage
  final storage = Int16Storage(numSamples, 1);
  final samples = storage.samplesData[0];
  
  // Generate silence or fill samples...
  samples.fillRange(0, numSamples, 0);

  final format = WavFormat(
    1, // Channels
    sampleRate,
    2, // Block align (1 channel * 2 bytes)
    16, // Valid bits
    16, // Container bits
    FormatType.pcm16,
    channelMask: SPEAKER_FRONT_CENTER,
  );

  final wav = WavContent<Int16Storage>(format, StorageType.int16, storage);
  final encodedBytes = saveWav(wav);
  
  File('output.wav').writeAsBytesSync(encodedBytes.buffer.asUint8List());
}
```

### 3. Streaming Writes with `WavWriter`

Write audio block by block directly to a file, which keeps the memory footprint low:

```dart
import 'dart:io';
import 'package:wav_io/wav_io.dart';
import 'package:wav_io/wav_writer.dart';

void main() {
  final file = File('streaming.wav').openSync(mode: FileMode.write);
  final format = WavFormat(
    2, 44100, 4, 16, 16, FormatType.pcm16,
    channelMask: SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT,
  );

  final writer = WavWriter(file, format, StorageType.int16);

  // Generate and write chunks
  for (int block = 0; block < 100; block++) {
    final chunk = Int16Storage(1024, 2);
    // Fill chunk samples...
    writer.write(chunk);
  }

  writer.close(); // Finalizes headers and pads the file size automatically
}
```

### 4. Streaming Reads with `WavReader`

Read audio samples chunk by chunk or seek to arbitrary positions without loading the entire file into memory:

```dart
import 'dart:io';
import 'package:wav_io/wav_io.dart';
import 'package:wav_io/wav_reader.dart';

void main() {
  final file = File('input.wav').openSync(mode: FileMode.read);
  final reader = WavReader(file);

  print("Format: ${reader.format.formatType}");
  print("Sample Rate: ${reader.format.sampleRate} Hz");
  print("Total Samples: ${reader.totalSamples}");

  // Seek to 1 second in (at 44.1kHz)
  reader.seek(44100);

  // Read a block of 1024 sample frames
  final chunk = reader.read(1024);
  if (chunk != null) {
    print("Read ${chunk.length} frames.");
  }

  reader.close();
}
```

### 5. Format Conversion & Channel Layout Manipulation

Convert WAV files dynamically to other representations, such as mixing channels down to mono:

```dart
import 'dart:io';
import 'package:wav_io/wav_io.dart';

void main() {
  final bytes = File('stereo_float.wav').readAsBytesSync();
  final wav = loadWav(bytes.buffer.asByteData()).unwrap();

  // Convert stereo to mono
  final monoWav = wav.toMono();

  // Convert to 16-bit PCM format
  final pcm16Wav = monoWav.toPcm16();

  // Save the modified file
  File('mono_pcm16.wav')
      .writeAsBytesSync(saveWav(pcm16Wav).buffer.asUint8List());
}
```

---

## Additional Information

Find more detailed integration scripts in the [example directory](file:///home/orr/Projects/wav_io/wav_io/example).
If you have questions, run into issues, or want to contribute, feel free to open a pull request or file an issue on the [GitHub repository](https://github.com/gnudles/wav_io).
