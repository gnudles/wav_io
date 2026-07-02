# wav_io Examples

This directory contains example scripts showing how to use the `wav_io` library for reading, writing, streaming, and manipulating WAV audio files.

---

## 1. Sine Generator (`sine.dart`)

Generates a sinusoidal test wave and saves it as a WAV file using the requested format.

### Usage
```bash
dart example/lib/sine.dart \
  --samplerate <sample_rate> \
  --duration <duration_in_seconds> \
  --freq <frequency_in_hz> \
  --format <u8|i16|i24|i32|f32|f64> \
  -o <output.wav>
```

---

## 2. Wave Concatenator (`concat.dart`)

Concatenates multiple WAV audio files into a single, merged output WAV file. Converts mono tracks to stereo and converts audio to Float32 format dynamically during the mixing process.

### Usage
```bash
dart example/lib/concat.dart <in1.wav> <in2.wav> <in3.wav> ... -o <output.wav>
```

---

## 3. Streaming Swept-Sine Generator (`stream_write.dart`)

Demonstrates how to use `WavWriter` to stream and write audio chunks to disk on the fly, which keeps memory usage low even for large files. Generates an exponential frequency sweep in stereo.

### Usage
```bash
dart example/lib/stream_write.dart \
  --samplerate <sample_rate> \
  --duration <duration_in_seconds> \
  --freq-start <start_freq_in_hz> \
  --freq-end <end_freq_in_hz> \
  -o <output.wav>
```

---

## 4. Metadata and Format Inspector (`info.dart`)

Reads a WAV file and prints comprehensive format specifications along with RIFF LIST INFO metadata.

### Usage
```bash
dart example/lib/info.dart <input.wav>
```

---

## 5. Audio Reverser (`reverse.dart`)

Demonstrates how to reverse a WAV audio file from end to start. It reads input blocks backwards using `WavReader`, reverses the samples for each channel, and writes the reversed blocks sequentially using `WavWriter`. This is a memory-efficient way to reverse long audio files.

### Usage
```bash
dart example/lib/reverse.dart -i <input.wav> -o <output.wav>
```

---

## 6. Multi-Channel to Mono Merger (`merge_mono.dart`)

Demonstrates how to merge all audio channels from a WAV file into a single mono track. It reads input chunks using `WavReader`, sums the sample values across all channels, and writes the resulting mono chunks sequentially using `WavWriter`. This is a memory-efficient way to process and mix multi-channel WAV files.

### Usage
```bash
dart example/lib/merge_mono.dart -i <input.wav> -o <output.wav>
```

