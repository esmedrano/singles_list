/* const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');
const fs = require('fs').promises;
const path = require('path');
const { geohashForLocation } = require('geofire-common');
const crypto = require('crypto');

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

const imageFiles = ['opposites.jpg', 'through the dome.webp'];

// Upload image to Storage emulator
async function uploadImage(phoneNumber, fileName, filePath) {
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

    // Use unique file name to avoid overwriting
    const uniqueFileName = `${path.basename(fileName, extension)}_${index}${extension}`;
    const storageRef = storage.file(`profile_images/${phoneNumber}/${uniqueFileName}`);
    await storageRef.save(fileBuffer, {
      metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    });

    return `profile_images/${phoneNumber}/${fileName}`;
  } catch (error) {
    return '';
  }
}

// Phone number hashing function
function generatePhoneHash(phoneNumber) {
  // Validate input
  if (typeof phoneNumber !== 'string' || phoneNumber.trim() === '') {
    throw new Error('Phone number must be a non-empty string');
  }

  // Normalize phone number: remove non-digit characters
  const normalizedPhone = phoneNumber.replace(/[^0-9]/g, '');

  if (normalizedPhone === '') {
    throw new Error('Phone number contains no digits');
  }

  // For test data, use last 10 digits if sequential and unique
  if (normalizedPhone.startsWith('123456789')) {
    return normalizedPhone.slice(-10); // e.g., "1234567890" for test data
  }

  // General case: SHA-256 hash, take first 8 bytes (64 bits), encode to base62
  const crypto = require('crypto');
  const fullHash = crypto.createHash('sha256').update(normalizedPhone).digest();
  const truncated = fullHash.slice(0, 8); // First 8 bytes (64 bits)

  const base62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  let num = BigInt('0x' + truncated.toString('hex'));
  let result = '';
  while (num > 0) {
    result = base62[Number(num % 62n)] + result;
    num /= 62n;
  }
  // Pad or truncate to ~10-12 characters
  return result.padStart(11, '0').slice(0, 11);
}

async function seedData() {
  const NUM_PROFILES = 2500;
  try {
    if (!await waitForEmulator()) {
      return;
    }

    const profiles = [];
    const distances = Array.from({ length: 4 }, (_, i) => (i + 1) * 5).concat(1); // [1, 5, 10]
    const centerLat = 32.7366245;
    const centerLon = -97.1076209;
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
    //const imageFile = 'through the dome.webp';
    
    for (let i = 0; i < NUM_PROFILES; i++) {
      const name = i == 9 ? 'Elijah Medrano' : `Test User${i}`;
      const phoneNumber = `+1234567890${i.toString().padStart(2, '0')}`;
      const hashedId = generatePhoneHash(phoneNumber); // Generate hash for phone number

      // Cycle through distances
      const distanceIndex = i % distances.length;
      const maxDistance = distances[distanceIndex];
      const { latitude, longitude } = generateRandomCoordinates(centerLat, centerLon, maxDistance);
      const timestamp = Date.now() + i * 1000;
      const imagePaths = [];

      // for (let j = 1; j <= 6; j++) {
      //   const fileName = imageFile;
      //   const filePath = path.join(__dirname, 'assets_not', imageFile);
      //   const imageUrl = await uploadImage(phoneNumber, fileName, filePath);
      //   if (imageUrl) imagePaths.push(imageUrl);
      // }

      // Upload 6 images, alternating between opposites.jpg and through the dome.webp
      for (let j = 0; j < 6; j++) {
        const fileName = imageFiles[j % 2]; // Alternate: 0->opposites.jpg, 1->through the dome.webp, 2->opposites.jpg, etc.
        const filePath = path.join(__dirname, 'assets_not', fileName);
        const imageUrl = await uploadImage(phoneNumber, fileName, filePath, j);
        if (imageUrl) {
          imagePaths.push(imageUrl);
        }
      }

      const geohash = geohashForLocation([latitude, longitude], 6);

      const profile = {
        hashedId: hashedId,
        children: faker.helpers.arrayElement(childrenOptions),
        email: faker.internet.email(),
        age: 18 + (i % 48),
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
        name: name,
        updated_at: timestamp,
        verified: faker.datatype.boolean(),
      };
      profiles.push({ hashedId, profile });
    }

    const batch = db.batch();
    profiles.forEach(({ hashedId, profile }) => {
      const ref = db.collection('user_ids').doc(hashedId);
      batch.set(ref, profile);
    });
    await batch.commit();
  } catch (error) {
    console.error('Seeding failed:', error.message, error.stack);
    process.exit(1);
  }
}

seedData(); */

const admin = require('firebase-admin');
const { faker } = require('@faker-js/faker');
const fs = require('fs').promises;
const path = require('path');
const { geohashForLocation } = require('geofire-common');
const crypto = require('crypto');

process.env.FIRESTORE_EMULATOR_HOST = '192.168.1.153:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '192.168.1.153:9199';

admin.initializeApp({
  projectId: 'integridate',
  storageBucket: 'integridate.firebasestorage.app',
});

const db = admin.firestore();
const storage = admin.storage().bucket('integridate.firebasestorage.app');

// Wait for emulator readiness (Firestore and Storage)
async function waitForEmulator(maxAttempts = 20, interval = 3000) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // Check Firestore
      await db.collection('test').doc('test').get();
      // Check Storage
      await storage.getFiles({ maxResults: 1 });
      console.log('Emulators ready');
      return true;
    } catch (error) {
      console.warn(`Attempt ${attempt}: ${error.message}`);
      if (attempt === maxAttempts) {
        console.error('Failed to connect to emulators');
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

  const actualDistance = calculateDistance(lat, lon, newLat, newLon);
  if (actualDistance > maxRadiusMiles) {
    return generateRandomCoordinates(lat, lon, maxRadiusMiles);
  }

  return { latitude: parseFloat(newLat.toFixed(7)), longitude: parseFloat(newLon.toFixed(7)) };
}

const imageFiles = ['oposites.jpg', 'through the dome.webp'];

// Upload image to Storage emulator
async function uploadImage(hashedId, fileName, filePath, index) {
  try {
    await fs.access(filePath); // Verify file exists
    const fileBuffer = await fs.readFile(filePath);
    const extension = path.extname(fileName).toLowerCase();
    const contentType = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
    }[extension] || 'application/octet-stream';

    const uniqueFileName = `${path.basename(fileName, extension)}_${index}${extension}`;
    const storageRef = storage.file(`profile_images/${hashedId}/${uniqueFileName}`);
    await storageRef.save(fileBuffer, {
      metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    });

    return `profile_images/${hashedId}/${uniqueFileName}`;
  } catch (error) {
    console.error(`Upload failed for ${fileName} (index ${index}): ${error.message}`);
    return '';
  }
}

// Phone number hashing function
function generatePhoneHash(phoneNumber) {
  if (typeof phoneNumber !== 'string' || phoneNumber.trim() === '') {
    throw new Error('Phone number must be a non-empty string');
  }

  const normalizedPhone = phoneNumber.replace(/[^0-9]/g, '');
  if (normalizedPhone === '') {
    throw new Error('Phone number contains no digits');
  }

  if (normalizedPhone.startsWith('123456789')) {
    return normalizedPhone.slice(-10);
  }

  const fullHash = crypto.createHash('sha256').update(normalizedPhone).digest();
  const truncated = fullHash.slice(0, 8);
  const base62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  let num = BigInt('0x' + truncated.toString('hex'));
  let result = '';
  while (num > 0) {
    result = base62[Number(num % 62n)] + result;
    num /= 62n;
  }
  return result.padStart(11, '0').slice(0, 11);
}

async function seedData() {
  const NUM_PROFILES = 2500;
  try {
    if (!await waitForEmulator()) {
      console.error('Emulator not ready');
      process.exit(1);
    }

    const profiles = [];
    const distances = Array.from({ length: 4 }, (_, i) => (i + 1) * 5).concat(1); // [1, 5, 10, 15, 20]
    const centerLat = 32.7366245;
    const centerLon = -97.1076209;
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
      const name = i === 9 ? 'Elijah Medrano' : `Test User${i}`;
      const phoneNumber = `+1234567890${i.toString().padStart(2, '0')}`;
      const hashedId = generatePhoneHash(phoneNumber);

      const distanceIndex = i % distances.length;
      const maxDistance = distances[distanceIndex];
      const { latitude, longitude } = generateRandomCoordinates(centerLat, centerLon, maxDistance);
      const timestamp = Date.now() + i * 1000;
      const imagePaths = [];

      // Upload 6 images, alternating between opposites.jpg and through the dome.webp
      for (let j = 0; j < 6; j++) {
        let fileName = imageFiles[j % 2]; // Alternate between the two files
        let filePath = path.join(__dirname, 'assets_not', fileName);
        let imageUrl = await uploadImage(hashedId, fileName, filePath, j);
        if (!imageUrl) {
          // Fallback: Try the other file if upload fails
          fileName = imageFiles[(j % 2) === 0 ? 1 : 0];
          filePath = path.join(__dirname, 'assets_not', fileName);
          imageUrl = await uploadImage(hashedId, fileName, filePath, j);
        }
        if (imageUrl) {
          imagePaths.push(imageUrl);
        }
      }

      // Warn if fewer than 6 images
      if (imagePaths.length < 6) {
        console.warn(`Profile ${name} has only ${imagePaths.length} images`);
      }

      const geohash = geohashForLocation([latitude, longitude], 6);

      const profile = {
        hashedId: hashedId,
        children: faker.helpers.arrayElement(childrenOptions),
        email: faker.internet.email(),
        age: 18 + (i % 48),
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
        name: name,
        updated_at: timestamp,
        verified: faker.datatype.boolean(),
      };
      profiles.push({ hashedId, profile });
    }

    const batch = db.batch();
    profiles.forEach(({ hashedId, profile }) => {
      const ref = db.collection('user_ids').doc(hashedId);
      batch.set(ref, profile);
    });
    await batch.commit();
    console.log('Seeding complete');
  } catch (error) {
    console.error('Seeding failed:', error.message, error.stack);
    process.exit(1);
  }
}

seedData();