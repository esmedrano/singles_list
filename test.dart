import 'package:dart_geohash/dart_geohash.dart';

List<dynamic> test(String centerGeohash) {
  final geohashes = [];
  final geohasher = GeoHasher();
  
  geohashes.add([geohasher.neighbors(centerGeohash)]);  // get the first ring of 
  
  return geohashes;
}

List<dynamic> _collectGeohashesInRings(String centerGeohash, int numberOfRings) {
  final List<List<String>> geohashes = [[]];  // First empty list is the first ring container
  final geohasher = GeoHasher();
  var currentRing = [];
  print(centerGeohash);
  
  Map centralNeighbors = geohasher.neighbors(centerGeohash);  // Get the first ring of neighbors
  
  // Reorder the neighbors bc they typically start at NORTH, go clockwise, and then add the central hash as the last entry
  geohashes[0].addAll([  // This function adds all the indeces of the iterable to the first list in the list of lists [['NORTHWEST', 'NORTH', ...]]
    centralNeighbors['NORTHWEST'],
    centralNeighbors['NORTH'],
    centralNeighbors['NORTHEAST'],
    centralNeighbors['EAST'],
    centralNeighbors['SOUTHEAST'],
    centralNeighbors['SOUTH'],
    centralNeighbors['SOUTHWEST'],
    centralNeighbors['WEST']
  ]);

  currentRing = geohashes[0]; // set the current ring to the first ring to calculate the second ring iteratively bellow 

  for (int ring = 2; ring <= numberOfRings + 1; ring++) {  // Start on the second ring
    List<String?> nextRing = [];

    int hashesPerRing = ring * 8;  // Use number of hashes in the last ring to calculate the next ring hash names
    int hashesPerSide = ((hashesPerRing - 4) / 4).toInt();  // hashes per side does not include corners

    // for first neighbors indeces 0, 2, 4, 6
    int topLeftCorner = 0;  
    int topRightCorner = hashesPerSide + 1; 
    int bottomRightCorner = hashesPerSide * 2 + 2; 
    int bottomLeftCorner = hashesPerSide * 3 + 3; 

    int hashCounter = 0;

    for (var gh in currentRing) {  // There are 8 sides to every ring and 8 cases to check for to no which neighbors to add to the next ring
      final neighbors = geohasher.neighbors(gh); // Get 8 neighbors of next hash in this ring but only add hashes to the next ring once
      print(gh);
      if (hashCounter == topLeftCorner) {  // Start on the top left corner (NORTHEAST) and add the left, top left, and top neighbor hashes
        nextRing.addAll([neighbors['WEST'], neighbors['NORTHWEST'], neighbors['NORTH']]);
        print(nextRing);
        hashCounter += 1;
      }

      if (hashCounter > topLeftCorner + 1 && hashCounter < topRightCorner - 1) {  // add the top neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['NORTH']);
        print(nextRing);
      }

      if (hashCounter == topRightCorner - 1) {
        nextRing.addAll([neighbors['NORTH'], neighbors['NORTHEAST'], neighbors['EAST']]);
        print(nextRing);
        hashCounter += 1;
      }

      if (hashCounter > topRightCorner && hashCounter < bottomRightCorner - 2) { // add the right neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['EAST']);
        print(nextRing);
      }

      if (hashCounter == bottomRightCorner - 2) {
        nextRing.addAll([neighbors['EAST'], neighbors['SOUTHEAST'], neighbors['SOUTH']]);
        print(nextRing);
        hashCounter += 1;
      }

      if (hashCounter > bottomRightCorner - 1 && hashCounter < bottomLeftCorner - 3) { // add the bottom neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['SOUTH']);
        print(nextRing);
      }

      if (hashCounter == bottomLeftCorner - 3) {
        nextRing.addAll([neighbors['SOUTH'], neighbors['SOUTHWEST'], neighbors['WEST']]);
        print(nextRing);
        hashCounter += 1;
      }

      if (hashCounter > bottomLeftCorner - 2 && hashCounter < bottomLeftCorner + numberOfRings * 2 - 2) { // add the top left as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['WEST']);
        print(nextRing);
      }
      print(hashCounter);
      hashCounter ++;
    }
    geohashes.add(nextRing.where((item) => item != null).cast<String>().toList());  // takes each item out of the list and if ti is not null then it casts as a string and puts it into another list
    
    // adjust next ring to start at top left corner
    List<String?> trueNextRing = [...nextRing.sublist(1), nextRing.first];

    currentRing = trueNextRing.where((item) => item != null).cast<String>().toList();  // takes each item out of the list and if ti is not null then it casts as a string and puts it into another list
  }
  return geohashes;
}

// void printGrid(geohashes, int ringCount) {
//   int i = 2;
//   for(int ring = 1; ring <= ringCount; ring++) {
//     int rows = ring + i;
//     for(int row = 0; row <= rows; rows ++) {
//       print(geohashes[ring - 1][rows]);
//     }
//     i ++;
//   }
// }

main() {
  String hash = GeoHasher().encode(45.1230, 45.1230, precision: 6);
  // print(hash);
  print(test(hash));

  print(_collectGeohashesInRings(hash, 1));
}
