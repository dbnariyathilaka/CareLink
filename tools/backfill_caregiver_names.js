/**
 * One-time backfill: caregiverProfiles/{uid}.name was never actually set at
 * registration or onboarding-completion time (see app_state.dart /
 * register_screen.dart / caregiver_onboarding7_screen.dart fix alongside
 * this script) — it only ever got written if the caregiver happened to
 * later visit and save Edit Profile. Any caregiver who registered and
 * completed onboarding without ever touching Edit Profile has a
 * caregiverProfiles doc with no `name` field (or an empty one), which shows
 * up everywhere in the app as "Unnamed caregiver".
 *
 * This copies `users/{uid}.name` into `caregiverProfiles/{uid}.name` for
 * every caregiver doc that's missing it or has it empty. Only touches docs
 * with a missing/empty name, so it's safe to re-run.
 *
 * Usage (same convention as the other scripts in this folder):
 *   node backfill_caregiver_names.js            dry-run, safe
 *   node backfill_caregiver_names.js --write     actually writes
 */
const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
const DO_WRITE = process.argv.includes('--write');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  console.log('Mode:', DO_WRITE ? 'LIVE WRITE' : 'DRY RUN');
  const cgSnap = await db.collection('caregiverProfiles').get();
  const missing = cgSnap.docs.filter(d => !((d.data().name || '').trim()));
  console.log(`Found ${missing.length} caregiverProfiles doc(s) with no (or empty) name.\n`);

  let fixed = 0;
  let noUserName = 0;
  const batch = db.batch();

  for (const doc of missing) {
    const userSnap = await db.collection('users').doc(doc.id).get();
    const userName = (userSnap.data()?.name || '').trim();
    if (!userName) {
      console.log(`  SKIP ${doc.id} — users/${doc.id}.name is also empty/missing, nothing to copy.`);
      noUserName++;
      continue;
    }
    console.log(`  ${doc.id}  ->  "${userName}"`);
    if (DO_WRITE) batch.update(doc.ref, { name: userName });
    fixed++;
  }

  if (DO_WRITE && fixed > 0) await batch.commit();

  console.log('\n' + '-'.repeat(60));
  console.log(`${fixed} doc(s) ${DO_WRITE ? 'fixed.' : 'would be fixed (dry-run).'}`);
  if (noUserName > 0) console.log(`${noUserName} doc(s) skipped — no name on their users/ doc either.`);
  if (!DO_WRITE) console.log('\nRun again with --write to actually apply these changes.');
}

main().catch(err => { console.error(err); process.exit(1); });
