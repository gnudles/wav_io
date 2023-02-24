<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Simple reader and writer for WAVE files.

It reads the ByteData of the contents, and create a list of channels.
Each channel is packed as Int16List.

## Features

* Can read 16bit & 24bit PCM files.
* Can read 32bit float files.
* Can write to 16bit PCM file.

## Getting started

Add wav_io package to your pubspec.yaml file.

## Usage

This example can be found in `/example` folder.

```dart

import 'dart:io';

import 'package:wav_io/wav_io.dart';

void main() {
  var f = File("example/hello_float.wav").openSync(); 
  var buf = f.readSync(f.lengthSync());
  f.closeSync();
  // loads
  var wav = WavContent.fromBytes(buf.buffer.asByteData());

  print(wav.numChannels);
  print(wav.numSamples);
  print(wav.sampleRate);
  print(wav.bitsPerSample);
  // actual samples store in wav.samplesForChannel
  f = File("example/hello2.wav").openSync(mode: FileMode.writeOnly);
  f.writeFromSync(wav.toBytes().buffer.asInt8List());
  f.flushSync();
  f.closeSync();
}

```

## Additional information

WavContent stores each sample in 16 bit pcm format.


