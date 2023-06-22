import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:args/args.dart';

import 'package:wav_io/wav_io.dart';


int main(List<String> arguments) {
  
  final parser = ArgParser()..addOption('output', abbr: 'o', mandatory: true)
  ..addOption('samplerate', defaultsTo: '44100')
  ..addOption('duration', defaultsTo: '1')
  ..addOption('freq', defaultsTo: '440')
  ..addOption('format', defaultsTo: 'i16', allowed: ['i16','i24','i32','f32','f64']);
  ArgResults parsingResults;
  try
  {
    parsingResults = parser.parse(arguments);
  }
  on FormatException
  {
    print ("usage: \nsine --samplerate <sr> --duration <duration in seconds> --freq <note frequency> --format <i16|i24|i32|f32|f64> -o output.wav");
    return -1;
  }
  double duration = double.tryParse(parsingResults['duration'] as String)?? 0;
  if (duration<= 0 || duration > 60)
  {
    print("invalid duration. should be a positive number lower than 60 (seconds)");
    return -1;
  }
  int samplerate = int.tryParse(parsingResults['samplerate'] as String)?? 0;
  if (samplerate< 100 || samplerate > 100000)
  {
    print("invalid samplerate. should be a positive number larger than 100 and lower than 100,000");
    return -1;
  }
  double frequency = double.tryParse(parsingResults['freq'] as String)?? 0;
  if (frequency<5 || frequency > 22000)
  {
    print("invalid frequency. should be a positive number larger than 4 and lower than 22,000");
    return -1;
  }
  int samples = (samplerate*duration).floor();
  
  Float32List data = Float32List(samples);
  for (int i =0; i< samples;++i)
  {
    data[i] = 0.5*sin((i/samplerate)*frequency*2*pi);
  }
  
  WavContent<Float32Storage> floatWav = WavContent<Float32Storage>(WavFormat(1,samplerate,4,24,32,StorageType.Float32,channelMask: SPEAKER_FRONT_CENTER),
  StorageType.Float32, Float32Storage([data],samples), 
  info: ListInfo("sine","wav_io","computer","2023","generated by wav_io dart package","sinusidal","1")) ;
  late IWavContent result = floatWav.to(parsingResults['format']);
  File(parsingResults['output']).writeAsBytesSync(saveWav(result).buffer.asUint8List());
  return 0;
}