/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  CareLink — One-Time Incomplete Account Cleanup Script
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *  WHAT IT DOES
 *  ────────────
 *  Scans every document in the `users` Firestore collection and flags accounts
 *  that never finished onboarding:
 *    • Caregiver: no `caregiverProfiles/{uid}` document OR
 *                 `onboardingComplete !== true` in that document.
 *    • Patient  : no `patientProfiles/{uid}` document.
 *    • No-role  : account was created but role was never chosen.
 *
 *  For each incomplete account it:
 *    1. Deletes the Firebase Auth user.
 *    2. Deletes the `users/{uid}` Firestore document.
 *    3. Deletes `caregiverProfiles/{uid}` or `patientProfiles/{uid}` if present.
 *    4. Deletes the `registeredEmails/{email}` lookup document.
 *
 *  SAFE-BY-DEFAULT
 *  ───────────────
 *  Runs in DRY-RUN mode by default — only prints what would be deleted.
 *  Pass --delete to perform the actual deletions (and confirm at the prompt).
 *
 *  SETUP (run once in the tools/ folder)
 *  ──────────────────────────────────────
 *  1. Install Node.js 18+ if not already installed.
 *  2. cd "d:\SANKALPA\Documents\Sound recordings\Care_Match\tools"
 *  3. npm init -y
 *  4. npm install firebase-admin
 *  5. Firebase Console → Project settings → Service accounts →
 *     "Generate new private key" → save as serviceAccountKey.json in tools/.
 *  6. node cleanup_incomplete_accounts.js           (dry-run, safe)
 *  7. node cleanup_incomplete_accounts.js --delete  (actual delete)
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */

const admin    = require('firebase-admin');
const path     = require('path');
const readline = require('readline');

// ── Configuration ────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const DRY_RUN = !process.argv.includes('--delete');

// ── Initialise Firebase Admin ─────────────────────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require(SERVICE_ACCOUNT_PATH);
} catch {
  console.error(
    '\n\u274C  serviceAccountKey.json not found in the tools/ folder.\n' +
    '    Download it from: Firebase Console \u2192 Project settings \u2192 Service accounts.\n'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db   = admin.firestore();
const auth = admin.auth();

// ── Helpers ───────────────────────────────────────────────────────────────────
function emailKey(email) {
  return email.trim().toLowerCase();
}

async function confirm(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer.trim().toLowerCase() === 'y');
    });
  });
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n' + '\u2550'.repeat(70));
  console.log('  CareLink \u2014 Incomplete Account Cleanup');
  console.log('  Mode: ' + (DRY_RUN
    ? '\u26A0\uFE0F  DRY RUN (no changes will be made)'
    : '\uD83D\uDD25 LIVE DELETE'));
  console.log('\u2550'.repeat(70) + '\n');

  // 1. Load all user documents from Firestore.
  console.log('\u23F3  Reading users collection from Firestore...');
  const usersSnap = await db.collection('users').get();
  const allUsers  = usersSnap.docs.map(d => ({ uid: d.id, ...d.data() }));
  console.log(`    Found ${allUsers.length} user document(s).\n`);

  const incomplete = [];

  // 2. Check each user for completeness.
  for (const user of allUsers) {
    const { uid, role, email = '' } = user;

    if (role === 'caregiver') {
      const cgSnap = await db.collection('caregiverProfiles').doc(uid).get();
      const complete = cgSnap.exists && cgSnap.data()?.onboardingComplete === true;
      if (!complete) {
        incomplete.push({
          uid,
          role,
          email,
          reason: cgSnap.exists
            ? 'caregiverProfiles exists but onboardingComplete !== true'
            : 'no caregiverProfiles document found',
          profileCollection: 'caregiverProfiles',
        });
      }

    } else if (role === 'patient') {
      const ptSnap = await db.collection('patientProfiles').doc(uid).get();
      if (!ptSnap.exists) {
        incomplete.push({
          uid,
          role,
          email,
          reason: 'no patientProfiles document found (onboarding abandoned)',
          profileCollection: 'patientProfiles',
        });
      }

    } else {
      // No role set — account was created but never reached onboarding.
      incomplete.push({
        uid,
        role: role ?? '(none)',
        email,
        reason: 'role field missing — never completed role selection',
        profileCollection: null,
      });
    }
  }

  // 3. Print report.
  console.log('\u2500'.repeat(70));
  if (incomplete.length === 0) {
    console.log('\u2705  No incomplete accounts found. Database is clean!');
    console.log('\u2500'.repeat(70) + '\n');
    process.exit(0);
  }

  console.log(`\u26A0\uFE0F   Found ${incomplete.length} incomplete account(s):\n`);
  incomplete.forEach((u, i) => {
    console.log(`  ${String(i + 1).padStart(3)}.  UID   : ${u.uid}`);
    console.log(`        Role  : ${u.role}`);
    console.log(`        Email : ${u.email || '(unknown)'}`);
    console.log(`        Issue : ${u.reason}`);
    console.log();
  });
  console.log('\u2500'.repeat(70));

  if (DRY_RUN) {
    console.log('\n\uD83D\uDCA1  This was a DRY RUN. Nothing was deleted.');
    console.log('    To permanently delete these accounts, run:\n');
    console.log('      node cleanup_incomplete_accounts.js --delete\n');
    process.exit(0);
  }

  // 4. Confirm before deleting.
  const ok = await confirm(
    `\n\uD83D\uDEA8  You are about to PERMANENTLY DELETE ${incomplete.length} account(s).\n` +
    '    This cannot be undone. Continue? (y/N): '
  );
  if (!ok) {
    console.log('\n\u274C  Aborted. No accounts were deleted.\n');
    process.exit(0);
  }

  // 5. Delete each incomplete account.
  console.log('\n\uD83D\uDDD1\uFE0F   Deleting incomplete accounts...\n');
  let deleted = 0;
  let errors  = 0;

  for (const u of incomplete) {
    process.stdout.write(`  Deleting ${u.uid} (${u.email || 'no email'})... `);
    try {
      // a. Delete Firebase Auth user.
      try {
        await auth.deleteUser(u.uid);
      } catch (authErr) {
        if (authErr.code !== 'auth/user-not-found') throw authErr;
      }

      // b. Delete users/{uid}.
      await db.collection('users').doc(u.uid).delete();

      // c. Delete role-specific profile doc (if any).
      if (u.profileCollection) {
        await db.collection(u.profileCollection).doc(u.uid).delete();
      }

      // d. Delete registeredEmails lookup entry.
      if (u.email) {
        await db.collection('registeredEmails').doc(emailKey(u.email)).delete();
      }

      console.log('\u2705  done');
      deleted++;
    } catch (err) {
      console.log(`\u274C  ERROR: ${err.message}`);
      errors++;
    }
  }

  // 6. Summary.
  console.log('\n' + '\u2550'.repeat(70));
  console.log('  Cleanup complete.');
  console.log(`  \u2705  Deleted : ${deleted}`);
  if (errors > 0) {
    console.log(`  \u274C  Errors  : ${errors}  (see output above for details)`);
  }
  console.log('\u2550'.repeat(70) + '\n');
}

main().catch(err => {
  console.error('\n\u274C  Fatal error:', err.message);
  process.exit(1);
});
