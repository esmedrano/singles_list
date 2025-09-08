import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> generateCsvFiles(List<List<String>> datasetA, List<String> datasetB, {String prefix = 'dataset', double defaultValue = 1.0}) async {
  try {
    // Get the temporary directory to save CSVs
    final directory = await getTemporaryDirectory();
    final String dirPath = directory.path;

    // Generate CSV for Dataset A (flatten List<List<String>>)
    final fileA = File('$dirPath/${prefix}_a.csv');
    final bufferA = StringBuffer();
    bufferA.writeln('geohash,value'); // CSV header
    for (List<String> geohashList in datasetA) {
      for (String geohash in geohashList) {
        bufferA.writeln('$geohash,$defaultValue');
      }
    }
    await fileA.writeAsString(bufferA.toString());
    print('CSV file generated: ${fileA.path}');

    // Generate CSV for Dataset B (List<String>)
    final fileB = File('$dirPath/${prefix}_b.csv');
    final bufferB = StringBuffer();
    bufferB.writeln('geohash,value');
    for (String geohash in datasetB) {
      bufferB.writeln('$geohash,$defaultValue');
    }
    await fileB.writeAsString(bufferB.toString());
    print('CSV file generated: ${fileB.path}');
  } catch (e) {
    print('Error generating CSV files: $e');
  }
}

// Example usage
main() async {
  // Sample data
  List<List<String>> datasetA = [
    ['u4pruyd', 'u4pruyf'],
    ['u4pruyg', 'u4pruyh'],
  ]; // Dataset A: List<List<String>>
  List<String> datasetB = ['u4pruyi', 'u4pruyj']; // Dataset B: List<String>

  // Generate CSVs
  await generateCsvFiles(datasetA, datasetB);

  // Output files:
  // - /tmp/dataset_a.csv:
  //   geohash,value
  //   u4pruyd,1.0
  //   u4pruyf,1.0
  //   u4pruyg,1.0
  //   u4pruyh,1.0
  // - /tmp/dataset_b.csv:
  //   geohash,value
  //   u4pruyi,1.0
  //   u4pruyj,1.0
}