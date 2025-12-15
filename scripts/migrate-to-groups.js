/**
 * Migration script: Create Legacy Band group and assign all users/setlists to it.
 *
 * Prerequisites:
 * 1. Download service account key from Firebase Console:
 *    Project Settings > Service accounts > Generate new private key
 * 2. Save as scripts/service-account.json (gitignored)
 *
 * Run:
 *   node scripts/migrate-to-groups.js
 */

const admin = require('firebase-admin');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'service-account.json');

// Initialize Firebase Admin
const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const LEGACY_GROUP_NAME = 'Legacy Band';
const LEGACY_GROUP_CODE = 'legacy-band-migration';

async function createLegacyGroup() {
  // Check if legacy group already exists
  const existing = await db
    .collection('groups')
    .where('code', '==', LEGACY_GROUP_CODE)
    .get();

  if (!existing.empty) {
    console.log('Legacy group already exists, using existing group');
    return existing.docs[0].id;
  }

  // Create the legacy group
  const groupRef = db.collection('groups').doc();
  await groupRef.set({
    name: LEGACY_GROUP_NAME,
    code: LEGACY_GROUP_CODE,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Created legacy group: ${groupRef.id}`);
  return groupRef.id;
}

async function migrateUsers(legacyGroupId) {
  const errors = [];
  let count = 0;

  const usersSnapshot = await db.collection('users').get();
  console.log(`Found ${usersSnapshot.size} users to migrate`);

  let batch = db.batch();
  let batchCount = 0;
  const MAX_BATCH_SIZE = 500;

  for (const userDoc of usersSnapshot.docs) {
    try {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Skip if already in groups
      if (userData.groups && userData.groups.length > 0) {
        console.log(`  Skipping user ${userId} (already has groups)`);
        continue;
      }

      // Add user as admin in legacy group's members subcollection
      const memberRef = db
        .collection('groups')
        .doc(legacyGroupId)
        .collection('members')
        .doc(userId);

      batch.set(memberRef, {
        role: 'admin',
        joinedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user's groups array
      batch.update(userDoc.ref, {
        groups: admin.firestore.FieldValue.arrayUnion(legacyGroupId),
        lastUsedGroupId: legacyGroupId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      count++;
      batchCount += 2; // Two operations per user

      // Commit batch if approaching limit
      if (batchCount >= MAX_BATCH_SIZE - 10) {
        await batch.commit();
        console.log(`  Committed batch of ${batchCount} operations`);
        batch = db.batch();
        batchCount = 0;
      }
    } catch (err) {
      const msg = `Failed to migrate user ${userDoc.id}: ${err}`;
      console.error(`  ${msg}`);
      errors.push(msg);
    }
  }

  // Commit remaining operations
  if (batchCount > 0) {
    await batch.commit();
    console.log(`  Committed final batch of ${batchCount} operations`);
  }

  return { count, errors };
}

async function migrateSetlists(legacyGroupId) {
  const errors = [];
  let count = 0;

  const setlistsSnapshot = await db.collection('setlists').get();
  console.log(`Found ${setlistsSnapshot.size} setlists to migrate`);

  let batch = db.batch();
  let batchCount = 0;
  const MAX_BATCH_SIZE = 500;

  for (const setlistDoc of setlistsSnapshot.docs) {
    try {
      const data = setlistDoc.data();

      // Skip if already has groupId
      if (data.groupId) {
        console.log(`  Skipping setlist ${setlistDoc.id} (already has groupId)`);
        continue;
      }

      batch.update(setlistDoc.ref, {
        groupId: legacyGroupId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      count++;
      batchCount++;

      if (batchCount >= MAX_BATCH_SIZE) {
        await batch.commit();
        console.log(`  Committed batch of ${batchCount} setlist updates`);
        batch = db.batch();
        batchCount = 0;
      }
    } catch (err) {
      const msg = `Failed to migrate setlist ${setlistDoc.id}: ${err}`;
      console.error(`  ${msg}`);
      errors.push(msg);
    }
  }

  if (batchCount > 0) {
    await batch.commit();
    console.log(`  Committed final batch of ${batchCount} setlist updates`);
  }

  return { count, errors };
}

async function migrate() {
  console.log('Starting migration to groups...\n');

  // Step 1: Create legacy group
  console.log('Step 1: Creating legacy group...');
  const legacyGroupId = await createLegacyGroup();

  // Step 2: Migrate users
  console.log('\nStep 2: Migrating users...');
  const userResult = await migrateUsers(legacyGroupId);

  // Step 3: Migrate setlists
  console.log('\nStep 3: Migrating setlists...');
  const setlistResult = await migrateSetlists(legacyGroupId);

  console.log('\n=== Migration Complete ===');
  console.log(`Legacy Group ID: ${legacyGroupId}`);
  console.log(`Users updated: ${userResult.count}`);
  console.log(`Setlists updated: ${setlistResult.count}`);

  const allErrors = [...userResult.errors, ...setlistResult.errors];
  if (allErrors.length > 0) {
    console.log(`Errors: ${allErrors.length}`);
    allErrors.forEach((e) => console.log(`  - ${e}`));
  }
}

// Run migration
migrate()
  .then(() => {
    console.log('\nMigration finished successfully');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\nMigration failed:', err);
    process.exit(1);
  });
