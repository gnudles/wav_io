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
Each channel is packed as Int16List/Int32List/Float32List/Float64List.

## Features

* Can read/write 16bit/24bit/32bit PCM files.
* Can read/write 32bit/64bit float files.
* Can read/write RIFX format (big endian version)
* Can be used to write wav utilities.

## Getting started

Add wav_io package to your pubspec.yaml file.

## Usage

See examples in `/example` folder.

## Additional information

Every file gets loaded, and samples data is stored in a suitable container.
You can convert from one storage method to another (integer PCM to floats and vice versa).


