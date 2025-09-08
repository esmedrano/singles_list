import 'package:dart_geohash/dart_geohash.dart';
import 'dart:math';

List<dynamic> test(String centerGeohash) {
  final geohashes = [];
  final geohasher = GeoHasher();
  
  geohashes.add([geohasher.neighbors(centerGeohash)]);  // get the first ring of 
  
  return geohashes;
}

Future<String> getTargetGeohash(double lat1, double lon1, int radiusMiles) async{  // This finds a hash radius miles due north of the user's location
  final geohasher = GeoHasher();

  // Earth's radius in meters
  const double R = 6371000;

  double bearingDeg = 90;

  // Convert to radians
  final double lat1Rad = lat1 * pi / 180;
  final double lon1Rad = lon1 * pi / 180;
  final double bearingRad = bearingDeg * pi / 180;

  // Convert radius from miles to meters
  double doubleRadiusMiles = radiusMiles.toDouble();
  double radiusMeters = doubleRadiusMiles / 0.000621371;

  // Distance as a fraction of Earth's radius
  final double dR = radiusMeters / R;

  // Calculate destination latitude
  final double lat2Rad = asin(
    sin(lat1Rad) * cos(dR) +
        cos(lat1Rad) * sin(dR) * cos(bearingRad),
  );

  // Calculate destination longitude
  final double lon2Rad = lon1Rad +
      atan2(
        sin(bearingRad) * sin(dR) * cos(lat1Rad),
        cos(dR) - sin(lat1Rad) * sin(lat2Rad),
      );

  // Convert back to degrees
  final double lat2 = lat2Rad * 180 / pi;
  final double lon2 = lon2Rad * 180 / pi;

  // Normalize longitude to [-180, 180]
  final double lon2Normalized = ((lon2 + 180) % 360) - 180;

  final targetGeohash = geohasher.encode(lon2Normalized, lat2, precision: 5);

  return targetGeohash;
}

Future<List<List<String>>> collectGeohashesInRings(double latitude, double longitude, int radiusMiles, String p6UserHash) async{
  final List<List<String>> geohashes = [[]];  // First empty list is the first ring container
  final geohasher = GeoHasher();
  var currentRing = [];

  // Be sure to start with collecting 5p rings. The user hash is always 6, so shorten it here:
  String p5CentralHash = p6UserHash.substring(0, 5);  // indeces 0-4 

  // If statement required to set central hash to 6 precision if 5 precision contains too many profiles:

  ///////////////////////
  
  ///////////////////////

  // String centerGeohash = geohasher.encode(longitude, latitude, precision: 6); 

  String targetGeohash = await getTargetGeohash(latitude, longitude, radiusMiles);  // Find the geohash due north that is radius miles from the central hash
  bool findingTargetHash = true;  // While loop state management

  Map centralNeighbors = geohasher.neighbors(p5CentralHash);  // Get the first ring of neighbors
  
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

  int ring = 2;  // Count rings starting on ring 2
  while (findingTargetHash) {  // Iterate throught each ring until the targhet geohash is found
    List<String?> nextRing = [];

    int hashesPerRing = (ring - 1) * 8;  // Use number of hashes in the last ring to calculate the next ring hash names
    int hashesPerSide = ((hashesPerRing - 4) / 4).toInt();  // hashes per side of the last ring that does not include corners 

    // It is necessary to use the values from teh last ring becuase of how the rings are built. 
    // Starting in the Northwest corner of the last ring, the three neighbors surrounding the corner are found first, then the side neighbors are found based on how many hashes are left in the side of the previous ring.  

    // for first neighbors indeces 0, 2, 4, 6
    int topLeftCorner = 0;  
    int topRightCorner = hashesPerSide + 1; 
    int bottomRightCorner = hashesPerSide * 2 + 2; 
    int bottomLeftCorner = hashesPerSide * 3 + 3; 

    int hashCounter = 0;
    for (var gh in currentRing) {  // There are 8 sides to every ring and 8 cases to check for to no which neighbors to add to the next ring
      final neighbors = geohasher.neighbors(gh); // Get 8 neighbors of next hash in this ring but only add hashes to the next ring once
      //print(gh);
      if (hashCounter == topLeftCorner) {  // Start on the top left corner (NORTHEAST) and add the left, top left, and top neighbor hashes
        nextRing.addAll([neighbors['WEST'], neighbors['NORTHWEST'], neighbors['NORTH']]);
        //print(nextRing);
      }

      if (hashCounter > topLeftCorner && hashCounter < topRightCorner) {  // add the top neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['NORTH']);
        //print(nextRing);
      }

      if (hashCounter == topRightCorner) {
        nextRing.addAll([neighbors['NORTH'], neighbors['NORTHEAST'], neighbors['EAST']]);
        //print(nextRing);
      }

      if (hashCounter > topRightCorner && hashCounter < bottomRightCorner) { // add the right neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['EAST']);
        //print(nextRing);
      }

      if (hashCounter == bottomRightCorner) {
        nextRing.addAll([neighbors['EAST'], neighbors['SOUTHEAST'], neighbors['SOUTH']]);
        //print(nextRing);
      }

      if (hashCounter > bottomRightCorner && hashCounter < bottomLeftCorner) { // add the bottom neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['SOUTH']);
        //print(nextRing);
      }

      if (hashCounter == bottomLeftCorner) {
        nextRing.addAll([neighbors['SOUTH'], neighbors['SOUTHWEST'], neighbors['WEST']]);
        //print(nextRing);
      }

      if (hashCounter > bottomLeftCorner && hashCounter < bottomLeftCorner + ring * 2) { // add the left neighbor as many times as there are hashes in the side of the current ring
        nextRing.add(neighbors['WEST']);
        //print(nextRing);
      }
      //print(hashCounter);
      hashCounter ++;

      if (gh == targetGeohash) {  // Break while loop after this ring
        findingTargetHash = false;
      }
    }
    geohashes.add(nextRing.where((item) => item != null).cast<String>().toList());  // takes each item out of the list and if ti is not null then it casts as a string and puts it into another list
    
    // adjust next ring to start at top left corner
    List<String?> trueNextRing = [...nextRing.sublist(1), nextRing.first];
    
    //print(currentRing);
    
    currentRing = trueNextRing.where((item) => item != null).cast<String>().toList();  // takes each item out of the list and if ti is not null then it casts as a string and puts it into another list        
    
    ring ++;      
  }
  return geohashes; 
}

main() {
  String hash = GeoHasher().encode(45.1230, 45.1230, precision: 6);
  //print(hash);
  print(test(hash));

  print(collectGeohashesInRings(45.12345, 45.12345, 250, hash));
}
