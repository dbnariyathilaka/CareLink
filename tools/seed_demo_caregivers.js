/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  Sathkara — Demo Caregiver Seeder (matching-algorithm verification data)
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *  WHAT IT DOES
 *  ────────────
 *  Writes 23 synthetic `caregiverProfiles` documents (ids "demo-cg-01" ..
 *  "demo-cg-20", plus 3 "demo-cg-2X-control" docs) straight into Firestore via
 *  the Admin SDK, deliberately spread across a wide range of the matching
 *  algorithm's inputs (proximity, experience, NVQ certification, rating) so
 *  that running either matching screen against them produces a readable
 *  spread of match percentages instead of one cluster of similar scores.
 *
 *  Docs 1-20 are all ELIGIBLE for a demo patient request of:
 *    careType: 'Elder care', schedule: 'Full-time', requiredSkills: ['Mobility
 *    assistance'], city: 'Colombo', gender preference: No preference.
 *  Their predicted advanced-match / onboarding-match percentages (computed by
 *  hand from matching_service.dart / onboarding_matching_service.dart's own
 *  published formulas) are stamped onto each doc as `_expectedAdvancedPct` /
 *  `_expectedOnboardingPct` purely for your own reference — the app never
 *  reads those fields.
 *
 *  Docs 21-23 ("control" profiles) are otherwise top-tier caregivers that
 *  each deliberately fail exactly ONE Stage-1 hard filter (wrong care
 *  category / missing required skill / wrong schedule) — seed them to see
 *  that a caregiver who would score ~97% never appears at all once they fail
 *  a hard filter, which is a different failure mode than "scored low."
 *
 *  Each caregiver whose rating tier isn't "Absent" also gets 8 documents
 *  written to the `reviews` collection (so ReviewService.stampAdjustedRatings
 *  picks them up for real) — ratings chosen so the review average lands on
 *  a clean number (5.0 / ~4.25 / 3.0 / 1.5).
 *
 *  The same 23-row table (with predicted scores) is also at
 *  docs/demo_caregivers.csv — open it in Excel/Sheets for a spreadsheet view.
 *
 *  SAFE-BY-DEFAULT
 *  ───────────────
 *  Runs in DRY-RUN mode by default — only prints what would be written.
 *  Pass --seed to actually write. Pass --cleanup (optionally with --seed's
 *  absence) to delete every doc this script created, by the exact ids below —
 *  nothing else in your database is touched.
 *
 *  SETUP (same as the other scripts in this folder)
 *  ──────────────────────────────────────────────────
 *  1. cd "d:\SANKALPA\Documents\Sound recordings\Care_Match\tools"
 *  2. npm install   (firebase-admin is already a dependency here)
 *  3. serviceAccountKey.json must already be in this folder (it is, for the
 *     existing cleanup scripts) — Firebase Console → Project settings →
 *     Service accounts → Generate new private key.
 *  4. node seed_demo_caregivers.js            (dry-run, safe, prints a plan)
 *  5. node seed_demo_caregivers.js --seed      (actually writes everything)
 *  6. node seed_demo_caregivers.js --cleanup   (dry-run of the cleanup)
 *  7. node seed_demo_caregivers.js --cleanup --seed   (actually deletes)
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */

const admin = require('firebase-admin');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const DO_WRITE = process.argv.includes('--seed');
const CLEANUP = process.argv.includes('--cleanup');

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

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── The 23 demo caregivers ───────────────────────────────────────────────────
// prox/exp/edu scores and the two "_expected*Pct" fields are reference-only
// annotations computed off matching_service.dart's own published formulas —
// the app itself never reads them.
const CAREGIVERS = [
  { docId: 'demo-cg-01', name: 'Nimal Perera', gender: 'Male', age: 34, city: 'Colombo', yearsExperience: 10, nvqLevel: 6, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: 96.7, expectedOnboardingPct: 94.2 },
  { docId: 'demo-cg-02', name: 'Kumari Jayasinghe', gender: 'Female', age: 41, city: 'Colombo', yearsExperience: 7, nvqLevel: 5, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English','Tamil'], reviewStars: [5,5,4,4,4,4,4,4], expectedAdvancedPct: 90.8, expectedOnboardingPct: 89.6 },
  { docId: 'demo-cg-03', name: 'Suresh Fernando', gender: 'Male', age: 29, city: 'Nugegoda', yearsExperience: 8, nvqLevel: 6, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Tamil','English'], reviewStars: [], expectedAdvancedPct: 89.9, expectedOnboardingPct: 75.1 },
  { docId: 'demo-cg-04', name: 'Anusha Wickramasinghe', gender: 'Female', age: 37, city: 'Nugegoda', yearsExperience: 5, nvqLevel: 4, skills: ['Mobility assistance','Medication management'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','Tamil'], reviewStars: [3,3,3,3,3,3,3,3], expectedAdvancedPct: 68.6, expectedOnboardingPct: 69.5 },
  { docId: 'demo-cg-05', name: 'Ravi Gunawardena', gender: 'Male', age: 45, city: 'Kaduwela', yearsExperience: 9, nvqLevel: null, skills: ['Mobility assistance','Basic first aid'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [5,5,4,4,4,4,4,4], expectedAdvancedPct: 74.5, expectedOnboardingPct: 67.0 },
  { docId: 'demo-cg-06', name: 'Chamari Rathnayake', gender: 'Female', age: 26, city: 'Kaduwela', yearsExperience: 2, nvqLevel: 5, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala'], reviewStars: [], expectedAdvancedPct: 56.5, expectedOnboardingPct: 54.8 },
  { docId: 'demo-cg-07', name: 'Dilshan Bandara', gender: 'Male', age: 52, city: 'Maharagama', yearsExperience: 6, nvqLevel: 4, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English','Tamil'], reviewStars: [2,2,1,1,2,2,1,1], expectedAdvancedPct: 59.5, expectedOnboardingPct: 53.7 },
  { docId: 'demo-cg-08', name: 'Priyanka De Silva', gender: 'Female', age: 33, city: 'Maharagama', yearsExperience: 0.5, nvqLevel: null, skills: ['Mobility assistance','Medication management'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Tamil','English'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: 52.4, expectedOnboardingPct: 75.2 },
  { docId: 'demo-cg-09', name: 'Ashan Wijesinghe', gender: 'Male', age: 23, city: 'Moratuwa', yearsExperience: 4, nvqLevel: 3, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','Tamil'], reviewStars: [3,3,3,3,3,3,3,3], expectedAdvancedPct: 55.9, expectedOnboardingPct: 53.2 },
  { docId: 'demo-cg-10', name: 'Malini Karunaratne', gender: 'Female', age: 48, city: 'Moratuwa', yearsExperience: 1, nvqLevel: null, skills: ['Mobility assistance','Basic first aid'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [], expectedAdvancedPct: 42.4, expectedOnboardingPct: 42.4 },
  { docId: 'demo-cg-11', name: 'Sampath Weerasinghe', gender: 'Male', age: 39, city: 'Homagama', yearsExperience: 7, nvqLevel: null, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala'], reviewStars: [3,3,3,3,3,3,3,3], expectedAdvancedPct: 65.9, expectedOnboardingPct: 52.1 },
  { docId: 'demo-cg-12', name: 'Nadeeka Abeysekera', gender: 'Female', age: 31, city: 'Homagama', yearsExperience: 3, nvqLevel: 6, skills: ['Mobility assistance','Personal hygiene assistance','Medication management'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English','Tamil'], reviewStars: [2,2,1,1,2,2,1,1], expectedAdvancedPct: 52.3, expectedOnboardingPct: 42.9 },
  { docId: 'demo-cg-13', name: 'Tharindu Senanayake', gender: 'Male', age: 27, city: 'Gampaha', yearsExperience: 10, nvqLevel: 5, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Tamil','English'], reviewStars: [5,5,4,4,4,4,4,4], expectedAdvancedPct: 67.9, expectedOnboardingPct: 50.0 },
  { docId: 'demo-cg-14', name: 'Dilani Herath', gender: 'Female', age: 44, city: 'Gampaha', yearsExperience: 2, nvqLevel: null, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','Tamil'], reviewStars: [], expectedAdvancedPct: 33.6, expectedOnboardingPct: 20.7 },
  { docId: 'demo-cg-15', name: 'Chaminda Rajapaksa', gender: 'Male', age: 36, city: 'Negombo', yearsExperience: 9, nvqLevel: 6, skills: ['Mobility assistance','Personal hygiene assistance','Basic first aid'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: 67.9, expectedOnboardingPct: 44.3 },
  { docId: 'demo-cg-16', name: 'Shanika Amarasinghe', gender: 'Female', age: 28, city: 'Negombo', yearsExperience: 0.5, nvqLevel: 3, skills: ['Mobility assistance','Medication management'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala'], reviewStars: [], expectedAdvancedPct: 14.9, expectedOnboardingPct: 0.0 },
  { docId: 'demo-cg-17', name: 'Lasantha Dissanayake', gender: 'Male', age: 50, city: 'Kandy', yearsExperience: 8, nvqLevel: 5, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English','Tamil'], reviewStars: [5,5,4,4,4,4,4,4], expectedAdvancedPct: 62.0, expectedOnboardingPct: 39.7 },
  { docId: 'demo-cg-18', name: 'Hiruni Gamage', gender: 'Female', age: 24, city: 'Kandy', yearsExperience: 1, nvqLevel: null, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Tamil','English'], reviewStars: [], expectedAdvancedPct: 25.2, expectedOnboardingPct: 0.0 },
  { docId: 'demo-cg-19', name: 'Buddhika Ekanayake', gender: 'Male', age: 42, city: 'Galle', yearsExperience: 6, nvqLevel: 4, skills: ['Mobility assistance'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','Tamil'], reviewStars: [3,3,3,3,3,3,3,3], expectedAdvancedPct: 46.9, expectedOnboardingPct: 32.0 },
  { docId: 'demo-cg-20', name: 'Ishara Madushani', gender: 'Female', age: 30, city: 'Galle', yearsExperience: 0.5, nvqLevel: null, skills: ['Mobility assistance','Medication management','Basic first aid'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [2,2,1,1,2,2,1,1], expectedAdvancedPct: 22.1, expectedOnboardingPct: 22.7 },

  // ── Control profiles — otherwise top-tier, each fails exactly one hard filter ──
  { docId: 'demo-cg-21-control', name: 'Rangika Jayawardena', gender: 'Female', age: 35, city: 'Colombo', yearsExperience: 10, nvqLevel: 6, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Child care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: null, expectedOnboardingPct: null, note: "careCategory='Child care' != patient's 'Elder care' -> excluded by _careCategoryEligible" },
  { docId: 'demo-cg-22-control', name: 'Chathura Ranasinghe', gender: 'Male', age: 38, city: 'Colombo', yearsExperience: 10, nvqLevel: 6, skills: ['Feeding assistance','Basic first aid'], careCategory: 'Elder care', careTypes: ['Full-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: null, expectedOnboardingPct: null, note: "no 'Mobility assistance' in skills -> excluded by _requiredSkillsEligible" },
  { docId: 'demo-cg-23-control', name: 'Vindya Perera', gender: 'Female', age: 32, city: 'Colombo', yearsExperience: 10, nvqLevel: 6, skills: ['Mobility assistance','Personal hygiene assistance'], careCategory: 'Elder care', careTypes: ['Part-time'], languagesSpoken: ['Sinhala','English'], reviewStars: [5,5,5,5,5,5,5,5], expectedAdvancedPct: null, expectedOnboardingPct: null, note: "careTypes=['Part-time'] != patient's 'Full-time' -> excluded by _scheduleEligible" },
];

const DEMO_PATIENT_UID = 'demo-seed-patient';

async function main() {
  console.log('\n' + '='.repeat(78));
  console.log('  Sathkara \u2014 Demo Caregiver Seeder');
  console.log('  Mode: ' + (CLEANUP
    ? (DO_WRITE ? 'CLEANUP (LIVE DELETE)' : 'CLEANUP (dry-run)')
    : (DO_WRITE ? 'SEED (LIVE WRITE)' : 'SEED (dry-run)')));
  console.log('='.repeat(78) + '\n');

  if (CLEANUP) {
    return runCleanup();
  }
  return runSeed();
}

async function runSeed() {
  let batch = db.batch();
  let ops = 0;
  let reviewCount = 0;

  async function commitIfNeeded() {
    if (ops >= 400) {
      if (DO_WRITE) await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }

  for (const cg of CAREGIVERS) {
    const ref = db.collection('caregiverProfiles').doc(cg.docId);
    const data = {
      name: cg.name,
      gender: cg.gender,
      age: cg.age,
      city: cg.city,
      yearsExperience: cg.yearsExperience,
      formalTraining: cg.nvqLevel != null,
      skills: cg.skills,
      careCategory: cg.careCategory,
      careTypes: cg.careTypes,
      languagesSpoken: cg.languagesSpoken,
      nicVerified: true,
      available: true,
      jobsDone: 0,
      bio: 'Demo caregiver profile seeded for matching-algorithm verification.',
      isDemoData: true,
      _expectedAdvancedPct: cg.expectedAdvancedPct,
      _expectedOnboardingPct: cg.expectedOnboardingPct,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (cg.nvqLevel != null) data.nvqLevel = cg.nvqLevel;
    if (cg.note) data._note = cg.note;

    console.log(`  caregiverProfiles/${cg.docId}  (${cg.name}, ${cg.city}, ${cg.yearsExperience}yr, ` +
      `NVQ${cg.nvqLevel ?? '-'}, ${cg.reviewStars.length} reviews)` +
      (cg.note ? `  [CONTROL: ${cg.note}]` : ''));

    if (DO_WRITE) batch.set(ref, data);
    ops++;
    await commitIfNeeded();

    for (let i = 0; i < cg.reviewStars.length; i++) {
      const reviewRef = db.collection('reviews').doc();
      const reviewData = {
        caregiverId: cg.docId,
        patientUid: DEMO_PATIENT_UID,
        rating: cg.reviewStars[i],
        tags: [],
        text: 'Demo seed review for matching verification.',
        mediaUrls: [],
        isDemoData: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (DO_WRITE) batch.set(reviewRef, reviewData);
      ops++;
      reviewCount++;
      await commitIfNeeded();
    }
  }

  if (DO_WRITE) await batch.commit();

  console.log('\n' + '-'.repeat(78));
  console.log(`  ${CAREGIVERS.length} caregiverProfiles doc(s), ${reviewCount} reviews doc(s) ` +
    (DO_WRITE ? 'written.' : 'WOULD be written (dry-run).'));
  if (!DO_WRITE) {
    console.log('\n  This was a DRY RUN. Nothing was written.');
    console.log('  To actually seed the data, run:\n');
    console.log('    node seed_demo_caregivers.js --seed\n');
  } else {
    console.log('\n  Done. Open the app, set your demo patient\'s care type to "Elder care",');
    console.log('  schedule to "Full-time", required skill to "Mobility assistance", and');
    console.log('  city to "Colombo", then check Match (onboarding) and the advanced-match');
    console.log('  wizard to see these 23 profiles ranked.\n');
  }
  console.log('='.repeat(78) + '\n');
}

async function runCleanup() {
  let batch = db.batch();
  let ops = 0;
  let deleted = 0;

  async function commitIfNeeded() {
    if (ops >= 400) {
      if (DO_WRITE) await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }

  for (const cg of CAREGIVERS) {
    console.log(`  Deleting caregiverProfiles/${cg.docId}...`);
    const ref = db.collection('caregiverProfiles').doc(cg.docId);
    if (DO_WRITE) batch.delete(ref);
    ops++;
    deleted++;
    await commitIfNeeded();
  }

  // Reviews don't have predictable ids (auto-generated) — find them by
  // querying isDemoData, which only this script's writes ever set.
  const reviewsSnap = await db.collection('reviews').where('isDemoData', '==', true).get();
  console.log(`  Found ${reviewsSnap.size} demo review doc(s) to delete.`);
  for (const doc of reviewsSnap.docs) {
    if (DO_WRITE) batch.delete(doc.ref);
    ops++;
    deleted++;
    await commitIfNeeded();
  }

  if (DO_WRITE) await batch.commit();

  console.log('\n' + '-'.repeat(78));
  console.log(`  ${deleted} doc(s) ` + (DO_WRITE ? 'deleted.' : 'WOULD be deleted (dry-run).'));
  if (!DO_WRITE) {
    console.log('\n  This was a DRY RUN. Nothing was deleted.');
    console.log('  To actually delete, run:\n');
    console.log('    node seed_demo_caregivers.js --cleanup --seed\n');
  }
  console.log('='.repeat(78) + '\n');
}

main().catch(err => {
  console.error('\n\u274C  Fatal error:', err.message);
  process.exit(1);
});
