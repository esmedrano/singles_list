const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');
const fs = require('fs').promises;
const path = require('path');
const { geohashForLocation } = require('geofire-common');

process.env.FIRESTORE_EMULATOR_HOST = '192.168.1.153:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '192.168.1.153:9199';

admin.initializeApp({
  projectId: 'integridate',
  storageBucket: 'integridate.firebasestorage.app',
});

const db = admin.firestore();
const storage = admin.storage().bucket('integridate.firebasestorage.app');

// Wait for emulator readiness
async function waitForEmulator(maxAttempts = 20, interval = 3000) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await db.collection('test').doc('test').get();
      return true;
    } catch (error) {
      if (attempt === maxAttempts) {
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, interval));
    }
  }
}

// Calculate distance between two points (in miles) for verification
function calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadiusMiles = 3958.8;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusMiles * c;
}

// Generate random coordinates within 0 to maxRadiusMiles
function generateRandomCoordinates(lat, lon, maxRadiusMiles) {
  const earthRadiusMiles = 3958.8;
  // Randomly scale the radius to be between 0 and maxRadiusMiles
  const randomRadius = Math.random() * maxRadiusMiles;
  const radiusRad = randomRadius / earthRadiusMiles;
  const u = Math.random();
  const v = Math.random();
  const w = radiusRad * Math.sqrt(u);
  const t = 2 * Math.PI * v;
  const x = w * Math.cos(t);
  const y = w * Math.sin(t);
  const latRad = lat * Math.PI / 180;
  const lonRad = lon * Math.PI / 180;
  const newLatRad = latRad + y;
  const newLonRad = lonRad + x / Math.cos(latRad);
  const newLat = newLatRad * 180 / Math.PI;
  const newLon = newLonRad * 180 / Math.PI;

  // Verify the generated coordinates are within maxRadiusMiles
  const actualDistance = calculateDistance(lat, lon, newLat, newLon);
  if (actualDistance > maxRadiusMiles) {
    // Recursively try again if outside the range (rare due to randomization)
    return generateRandomCoordinates(lat, lon, maxRadiusMiles);
  }

  return { latitude: parseFloat(newLat.toFixed(7)), longitude: parseFloat(newLon.toFixed(7)) };
}

// Upload image to Storage emulator
async function uploadImage(userId, fileName, filePath) {
  try {
    const fileBuffer = await fs.readFile(filePath);
    const extension = path.extname(fileName).toLowerCase();
    const contentType = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
    }[extension] || 'application/octet-stream';

    const storageRef = storage.file(`profile_images/${userId}/${fileName}`);
    await storageRef.save(fileBuffer, {
      metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    });

    return `profile_images/${userId}/${fileName}`;
  } catch (error) {
    return '';
  }
}

async function seedData() {
  const NUM_PROFILES = 315;
  try {
    if (!await waitForEmulator()) {
      return;
    }

    const profiles = [];
    const distances = Array.from({ length: 2 }, (_, i) => (i + 1) * 5).concat(1); // [1, 5, 10]
    const centerLat = 32.8170382;
    const centerLon = -97.0900704;
    const tagsOptions = ['Journaling', 'Reading', 'Video Games', 'Hiking', 'Photography', 'Running'];
    const relationshipIntentOptions = ['Casual', 'Serious', 'Open'];
    const personalityOptions = ['none', 'INTP', 'ENTJ', 'ISFP', 'ESTP'];
    const childrenOptions = ['I have children', 'no children'];
    const heightOptions = [
      "4' 0\"", "4' 1\"", "4' 2\"", "4' 3\"", "4' 4\"", "4' 5\"", "4' 6\"", "4' 7\"", "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"",
      "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"", "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
      "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\"", "6' 5\"", "6' 6\"", "6' 7\"", "6' 8\"", "6' 9\"", "6' 10\"", "6' 11\"",
      "7' 0\""
    ];
    const imageFile = 'through the dome.webp';

    for (let i = 0; i < NUM_PROFILES; i++) {
      const userId = `testUser${i}`;
      const phoneNumber = `+1234567890${i.toString().padStart(2, '0')}`;
      // Cycle through distances
      const distanceIndex = i % distances.length;
      const maxDistance = distances[distanceIndex];
      const { latitude, longitude } = generateRandomCoordinates(centerLat, centerLon, maxDistance);
      const timestamp = Date.now() + i * 1000;
      const imagePaths = [];
      for (let j = 1; j <= 3; j++) {
        const fileName = imageFile;
        const filePath = path.join(__dirname, 'assets_not', imageFile);
        const imageUrl = await uploadImage(phoneNumber, fileName, filePath);
        if (imageUrl) imagePaths.push(imageUrl);
      }

      const geohash = geohashForLocation([latitude, longitude], 6);

      const profile = {
        children: faker.helpers.arrayElement(childrenOptions),
        email: faker.internet.email(),
        geohash: geohash,
        height: faker.helpers.arrayElement(heightOptions),
        imagePaths: imagePaths,
        intro: faker.lorem.sentence({ min: 5, max: 15 }),
        latitude: latitude,
        longitude: longitude,
        personality: faker.helpers.arrayElement(personalityOptions),
        phone: phoneNumber,
        provider: 'phone',
        relationship_intent: faker.helpers.arrayElements(relationshipIntentOptions, { min: 0, max: 2 }),
        tags: faker.helpers.arrayElements(tagsOptions, { min: 0, max: 3 }),
        uid: userId,
        updated_at: timestamp,
        verified: faker.datatype.boolean(),
      };
      profiles.push({ phoneNumber, profile });
    }

    const batch = db.batch();
    profiles.forEach(({ phoneNumber, profile }) => {
      const ref = db.collection('user_ids').doc(phoneNumber);
      batch.set(ref, profile);
    });
    await batch.commit();
  } catch (error) {
    process.exit(1);
  }
}

seedData();

// version 4 gens profs outside the max rad
/* const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');
const fs = require('fs').promises;
const path = require('path');
const { geohashForLocation } = require('geofire-common');

process.env.FIRESTORE_EMULATOR_HOST = '192.168.1.153:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '192.168.1.153:9199';  // change this back to home wifi

// Initialize Admin SDK for emulator
admin.initializeApp({
  projectId: 'integridate',
  storageBucket: 'integridate.firebasestorage.app',
});

const db = admin.firestore();
const storage = admin.storage().bucket('integridate.firebasestorage.app');

// Wait for emulator readiness
async function waitForEmulator(maxAttempts = 20, interval = 3000) {
  //console.log(`Checking if Firestore emulator is ready at ${process.env.FIRESTORE_EMULATOR_HOST}...`);
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await db.collection('test').doc('test').get();
      //console.log('Firestore emulator is ready!');
      return true;
    } catch (error) {
      //console.log(`Attempt ${attempt}/${maxAttempts}: Emulator not ready yet. Error: ${error.message}`);
      if (attempt === maxAttempts) {
        //console.error(`Firestore emulator failed to start within ${maxAttempts * interval / 1000} seconds.`);
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, interval));
    }
  }
}

// Generate random coordinates within a specific radius (in miles)
function generateRandomCoordinates(lat, lon, radiusMiles) {
  const earthRadiusMiles = 3958.8;
  const radiusRad = radiusMiles / earthRadiusMiles;
  const u = Math.random();
  const v = Math.random();
  const w = radiusRad * Math.sqrt(u);
  const t = 2 * Math.PI * v;
  const x = w * Math.cos(t);
  const y = w * Math.sin(t);
  const latRad = lat * Math.PI / 180;
  const lonRad = lon * Math.PI / 180;
  const newLatRad = latRad + y;
  const newLonRad = lonRad + x / Math.cos(latRad);
  const newLat = newLatRad * 180 / Math.PI;
  const newLon = newLonRad * 180 / Math.PI;
  return { latitude: parseFloat(newLat.toFixed(7)), longitude: parseFloat(newLon.toFixed(7)) };
}

// Upload image to Storage emulator
async function uploadImage(userId, fileName, filePath) {
  try {
    const fileBuffer = await fs.readFile(filePath);
    const extension = path.extname(fileName).toLowerCase();
    const contentType = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
    }[extension] || 'application/octet-stream';

    const storageRef = storage.file(`profile_images/${userId}/${fileName}`);
    await storageRef.save(fileBuffer, {
      metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    });

    // Return only the storage path
    return `profile_images/${userId}/${fileName}`;
  } catch (error) {
    //console.error(`Error uploading image for ${userId}/${fileName}: ${error.message}`);
    return '';
  }
}

async function seedData() {
  const NUM_PROFILES = 2000;
  try {
    //console.log('Starting seedData...');
    if (!await waitForEmulator()) {
      //console.error('Failed to connect to Firestore emulator. Aborting seed.');
      return;
    }

    const profiles = [];
    // Define exact distances: 1, 5, 10, 15, ..., 150 miles
    const distances = Array.from({ length: 3 }, (_, i) => (i + 1) * 5).concat(1);  // [1, 5, 10, ..., 150] // length 2 = [1,5,10]
    const centerLat = 32.8170382;
    const centerLon = -97.0900704;
    const tagsOptions = ['Journaling', 'Reading', 'Video Games', 'Hiking', 'Photography', 'Running'];
    const relationshipIntentOptions = ['Casual', 'Serious', 'Open'];
    const personalityOptions = ['none', 'INTP', 'ENTJ', 'ISFP', 'ESTP'];
    const childrenOptions = ['I have children', 'no children'];
    const heightOptions = [
      "4' 0\"", "4' 1\"", "4' 2\"", "4' 3\"", "4' 4\"", "4' 5\"", "4' 6\"", "4' 7\"", "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"",
      "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"", "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
      "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\"", "6' 5\"", "6' 6\"", "6' 7\"", "6' 8\"", "6' 9\"", "6' 10\"", "6' 11\"",
      "7' 0\""
    ];
    const imageFile = 'through the dome.webp';

    for (let i = 0; i < NUM_PROFILES; i++) {
      //console.log(`Generating profile ${i}`);
      const userId = `testUser${i}`;
      const phoneNumber = `+1234567890${i.toString().padStart(2, '0')}`;
      // Cycle through distances, repeating as needed for 1000 profiles
      const distanceIndex = i % distances.length;
      const distance = distances[distanceIndex];
      const { latitude, longitude } = generateRandomCoordinates(centerLat, centerLon, distance);
      const timestamp = Date.now() + i * 1000;
      const imagePaths = [];
      for (let j = 1; j <= 3; j++) {
        const fileName = imageFile;
        const filePath = path.join(__dirname, 'assets_not', imageFile);
        const imageUrl = await uploadImage(phoneNumber, fileName, filePath);
        if (imageUrl) imagePaths.push(imageUrl);
      }
      //console.log(`Image URLs for profile ${i}: ${imagePaths}`);

      const geohash = geohashForLocation([latitude, longitude], precision=6);

      const profile = {
        children: faker.helpers.arrayElement(childrenOptions),
        email: faker.internet.email(),
        geohash: geohash,
        height: faker.helpers.arrayElement(heightOptions),
        imagePaths: imagePaths,
        intro: faker.lorem.sentence({ min: 5, max: 15 }),
        latitude: latitude,
        longitude: longitude,
        personality: faker.helpers.arrayElement(personalityOptions),
        phone: phoneNumber,
        provider: 'phone',
        relationship_intent: faker.helpers.arrayElements(relationshipIntentOptions, { min: 0, max: 2 }),
        tags: faker.helpers.arrayElements(tagsOptions, { min: 0, max: 3 }),
        uid: userId,
        updated_at: timestamp,
        verified: faker.datatype.boolean(),
      };
      profiles.push({ phoneNumber, profile });
    }

    //console.log('Committing batch...');
    const batch = db.batch();
    profiles.forEach(({ phoneNumber, profile }) => {
      const ref = db.collection('user_ids').doc(phoneNumber);
      batch.set(ref, profile);
    });
    await batch.commit();
    //console.log(`Seeded ${NUM_PROFILES} profiles successfully in user_ids collection`);
  } catch (error) {
    //console.error('Error seeding data:', error);
    if (error.name === 'SigningError') {
      //console.error('Credential error detected. Ensure emulator mode is active or set GOOGLE_APPLICATION_CREDENTIALS.');
    }
    process.exit(1);
  }
}

seedData();
 */

/* // version 3 calcs accurate geo hash

const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');
const fs = require('fs').promises;
const path = require('path');
const { geohashForLocation } = require('geofire-common'); // Import geofire-common

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '192.168.1.153:9199';

// Initialize Admin SDK without credentials for emulator use
admin.initializeApp({
  projectId: 'integridate',
  storageBucket: 'integridate.firebasestorage.app',
});

const db = admin.firestore();
const storage = admin.storage();

// Wait for emulator readiness
async function waitForEmulator(maxAttempts = 20, interval = 3000) {
  //console.log(`Checking if Firestore emulator is ready at ${process.env.FIRESTORE_EMULATOR_HOST}...`);
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await db.collection('test').doc('test').get();
      //console.log('Firestore emulator is ready!');
      return true;
    } catch (error) {
      //console.log(`Attempt ${attempt}/${maxAttempts}: Emulator not ready yet. Error: ${error.message}`);
      if (attempt === maxAttempts) {
        //console.error(`Firestore emulator failed to start within ${maxAttempts * interval / 1000} seconds.`);
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, interval));
    }
  }
}

// Generate random coordinates within a radius (in miles)
function generateRandomCoordinates(lat, lon, radiusMiles) {
  const earthRadiusMiles = 3958.8;
  const radiusRad = radiusMiles / earthRadiusMiles;
  const u = Math.random();
  const v = Math.random();
  const w = radiusRad * Math.sqrt(u);
  const t = 2 * Math.PI * v;
  const x = w * Math.cos(t);
  const y = w * Math.sin(t);
  const latRad = lat * Math.PI / 180;
  const lonRad = lon * Math.PI / 180;
  const newLatRad = latRad + y;
  const newLonRad = lonRad + x / Math.cos(latRad);
  const newLat = newLatRad * 180 / Math.PI;
  const newLon = newLonRad * 180 / Math.PI;
  return { latitude: parseFloat(newLat.toFixed(7)), longitude: parseFloat(newLon.toFixed(7)) };
}

// Upload image to Storage emulator with HTTP fallback
async function uploadImage(userId, timestamp) {
  try {
    const filePath = path.join(__dirname, 'assets_not', 'through the dome.webp');
    const fileBuffer = await fs.readFile(filePath);
    const bucket = storage.bucket();
    const storageRef = bucket.file(`profile_images/${userId}/${timestamp}.jpg`);
    await storageRef.save(fileBuffer, {
      metadata: { cacheControl: 'public, max-age=31536000' },
      userProject: 'integridate',
    });
    const emulatorUrl = `http://192.168.1.153:9199/v0/b/integridate.firebasestorage.app/o/profile_images%2F${encodeURIComponent(userId)}%2F${timestamp}.jpg?alt=media`;
    //console.log(`Successfully uploaded image for ${userId}/${timestamp}: ${emulatorUrl}`);
    return emulatorUrl;
  } catch (error) {
    //console.error(`Error uploading image for ${userId}/${timestamp}: ${error.message}`);
    return '';
  }
}

async function seedData() {
  const NUM_PROFILES = 100;
  try {
    //console.log('Starting seedData...');
    if (!await waitForEmulator()) {
      //console.error('Failed to connect to Firestore emulator. Aborting seed.');
      return;
    }

    const profiles = [];
    const distances = Array.from({ length: Math.ceil(NUM_PROFILES / 5) }, (_, i) => (i + 1) * 5).slice(0, NUM_PROFILES);
    const centerLat = 32.8170382;
    const centerLon = -97.0900704;
    const tagsOptions = ['Journaling', 'Reading', 'Video Games', 'Hiking', 'Photography', 'Running'];
    const relationshipIntentOptions = ['Casual', 'Serious', 'Open'];
    const personalityOptions = ['none', 'INTP', 'ENTJ', 'ISFP', 'ESTP'];
    const childrenOptions = ['I have children', 'no children'];
    const heightOptions = [
      "4' 0\"", "4' 1\"", "4' 2\"", "4' 3\"", "4' 4\"", "4' 5\"", "4' 6\"", "4' 7\"", "4' 8\"", "4' 9\"", "4' 10\"", "4' 11\"",
      "5' 0\"", "5' 1\"", "5' 2\"", "5' 3\"", "5' 4\"", "5' 5\"", "5' 6\"", "5' 7\"", "5' 8\"", "5' 9\"", "5' 10\"", "5' 11\"",
      "6' 0\"", "6' 1\"", "6' 2\"", "6' 3\"", "6' 4\"", "6' 5\"", "6' 6\"", "6' 7\"", "6' 8\"", "6' 9\"", "6' 10\"", "6' 11\"",
      "7' 0\""
    ];

    for (let i = 0; i < NUM_PROFILES; i++) {
      //console.log(`Generating profile ${i}`);
      const userId = `testUser${i}`;
      const phoneNumber = `+1234567890${i}`;
      const distance = distances[i % distances.length] || 5;
      const { latitude, longitude } = generateRandomCoordinates(centerLat, centerLon, distance);
      const timestamp = Date.now() + i * 1000;
      const imageUrl1 = await uploadImage(phoneNumber, `${timestamp}_1`);
      const imageUrl2 = await uploadImage(phoneNumber, `${timestamp}_2`);
      const imageUrl3 = await uploadImage(phoneNumber, `${timestamp}_3`);
      //console.log(`Image URLs for profile ${i}: ${[imageUrl1, imageUrl2, imageUrl3]}`);
      
      // Calculate geohash using geofire-common
      const geohash = geohashForLocation([latitude, longitude]);
      
      const profile = {
        children: faker.helpers.arrayElement(childrenOptions),
        created_at: new Date().toUTCString(),
        email: faker.internet.email(),
        geohash: geohash, // Use calculated geohash
        height: faker.helpers.arrayElement(heightOptions),
        imageUrls: [imageUrl1, imageUrl2, imageUrl3, '', '', ''],
        intro: faker.lorem.sentence({ min: 5, max: 15 }),
        latitude: latitude,
        longitude: longitude,
        personality: faker.helpers.arrayElement(personalityOptions),
        phone: phoneNumber,
        position: {
          geohash: geohash, // Use calculated geohash
          geopoint: new admin.firestore.GeoPoint(latitude, longitude)
        },
        provider: 'phone',
        relationship_intent: faker.helpers.arrayElements(relationshipIntentOptions, { min: 0, max: 2 }),
        tags: faker.helpers.arrayElements(tagsOptions, { min: 0, max: 3 }),
        uid: userId,
        updated_at: timestamp,
        verified: faker.datatype.boolean()
      };
      profiles.push({ phoneNumber, profile });
    }

    //console.log('Committing batch...');
    const batch = db.batch();
    profiles.forEach(({ phoneNumber, profile }) => {
      const ref = db.collection('user_ids').doc(phoneNumber);
      batch.set(ref, profile);
    });
    await batch.commit();
    //console.log(`Seeded ${NUM_PROFILES} profiles successfully in user_ids collection`);
  } catch (error) {
    //console.error('Error seeding data:', error);
    if (error.name === 'SigningError') {
      //console.error('Credential error detected. Ensure emulator mode is active or set GOOGLE_APPLICATION_CREDENTIALS.');
    }
    process.exit(1);
  }
}

seedData(); */