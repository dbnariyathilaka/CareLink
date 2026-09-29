/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  Sathkara — One-Time Reference-Document Cleanup Script
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *  WHAT IT DOES
 *  ────────────
 *  The "professional references" document-upload feature (a PDF/image a
 *  caregiver could optionally attach, which an admin then reviewed and
 *  counted via CaregiverService.setReferenceCount) has been removed from
 *  the app — it's no longer collected at onboarding, no longer shown in the
 *  admin verification queue, and no longer consumed by the matching
 *  algorithm. This script cleans up what existing accounts left behind:
 *
 *    1. Deletes the actual uploaded file from Cloudinary (the account's
 *       Admin API — this app only ever had an unsigned upload preset, which
 *       cannot delete), for every caregiverProfiles doc with a `referenceUrl`.
 *    2. Clears `referenceUrl`, `referenceCount`, and
 *       `documentReviews.reference` from that caregiver's Firestore document.
 *
 *  This does NOT touch the caregiver's reference *phone number*
 *  (`referencePhone`) — that's a separate, still-active field (a contact
 *  number collected at onboarding), not the document-upload feature.
 *
 *  SAFE-BY-DEFAULT
 *  ───────────────
 *  Runs in DRY-RUN mode by default — only prints what would change.
 *  Pass --delete to perform the actual deletions (and confirm at the prompt).
 *
 *  SETUP (tools/ already has firebase-admin + serviceAccountKey.json from
 *  the earlier cleanup_incomplete_accounts.js script)
 *  ──────────────────────────────────────────────────────────────────────
 *  1. cloudinaryConfig.json must exist in tools/ with:
 *       { "cloud_name": "...", "api_key": "...", "api_secret": "..." }
 *     (Cloudinary Console → Settings → API Keys). Gitignored — never commit it.
 *  2. node cleanup_reference_documents.js           (dry-run, safe)
 *  3. node cleanup_reference_documents.js --delete  (actual delete)
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */

const admin    = require('firebase-admin');
const path     = require('path');
const readline = require('readline');

// ── Configuration ────────────────────────────────────────────────────────────
const SERVICE_ACCOUNT_PATH  = path.join(__dirname, 'serviceAccountKey.json');
const CLOUDINARY_CONFIG_PATH = path.join(__dirname, 'cloudinaryConfig.json');
const DRY_RUN = !process.argv.includes('--delete');

// ── Initialise Firebase Admin ─────────────────────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require(SERVICE_ACCOUNT_PATH);
} catch {
  console.error(
    '\n❌  serviceAccountKey.json not found in the tools/ folder.\n' +
    '    Download it from: Firebase Console → Project settings → Service accounts.\n'
  );
  process.exit(1);
}

let cloudinaryConfig;
try {
  cloudinaryConfig = require(CLOUDINARY_CONFIG_PATH);
} catch {
  console.error(
    '\n❌  cloudinaryConfig.json not found in the tools/ folder.\n' +
    '    Create it with: { "cloud_name": "...", "api_key": "...", "api_secret": "..." }\n'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ── Cloudinary helpers ────────────────────────────────────────────────────────

/**
 * Derives { resourceType, publicId } from a Cloudinary secure_url, e.g.
 *   https://res.cloudinary.com/ov1bmnqf/raw/upload/v1712345678/caregivers/uid123/reference.pdf
 *   -> { resourceType: 'raw', publicId: 'caregivers/uid123/reference.pdf' }
 *   https://res.cloudinary.com/ov1bmnqf/image/upload/v1712345678/caregivers/uid123/reference.jpg
 *   -> { resourceType: 'image', publicId: 'caregivers/uid123/reference' }
 * (Cloudinary keeps the extension in the public ID for `raw` uploads, but
 * strips it for `image`/`video` uploads — this mirrors that exactly.)
 */
function parseCloudinaryUrl(url) {
  const match = url.match(/\/([a-z]+)\/upload\/(?:v\d+\/)?(.+)$/i);
  if (!match) return null;
  const resourceType = match[1];
  let publicId = match[2];
  if (resourceType !== 'raw') {
    const dot = publicId.lastIndexOf('.');
    if (dot !== -1) publicId = publicId.substring(0, dot);
  }
  return { resourceType, publicId };
}

async function deleteFromCloudinary(url) {
  const parsed = parseCloudinaryUrl(url);
  if (!parsed) {
    return { ok: false, reason: 'Could not parse Cloudinary URL' };
  }
  const { resourceType, publicId } = parsed;
  const authHeader = 'Basic ' + Buffer.from(
    `${cloudinaryConfig.api_key}:${cloudinaryConfig.api_secret}`
  ).toString('base64');

  const deleteUrl = `https://api.cloudinary.com/v1_1/${cloudinaryConfig.cloud_name}` +
    `/resources/${resourceType}/upload?public_ids[]=${encodeURIComponent(publicId)}`;

  try {
    const res = await fetch(deleteUrl, {
      method: 'DELETE',
      headers: { Authorization: authHeader },
    });
    const body = await res.json();
    const result = body.deleted && body.deleted[publicId];
    if (result === 'deleted' || result === 'not_found') {
      return { ok: true, result };
    }
    return { ok: false, reason: JSON.stringify(body) };
  } catch (err) {
    return { ok: false, reason: err.message };
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n' + '═'.repeat(70));
  console.log('  Sathkara — Reference-Document Cleanup');
  console.log('  Mode: ' + (DRY_RUN
    ? '⚠️  DRY RUN (no changes will be made)'
    : '🔥 LIVE DELETE'));
  console.log('═'.repeat(70) + '\n');

  console.log('⏳  Reading caregiverProfiles collection from Firestore...');
  const snap = await db.collection('caregiverProfiles').get();
  console.log(`    Found ${snap.docs.length} caregiver profile(s).\n`);

  const targets = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const referenceUrl = data.referenceUrl;
    const referenceCount = data.referenceCount;
    const referenceReview = data.documentReviews && data.documentReviews.reference;
    if (!referenceUrl && referenceCount === undefined && !referenceReview) continue;
    targets.push({ uid: doc.id, ref: doc.ref, referenceUrl, referenceCount, referenceReview });
  }

  console.log('─'.repeat(70));
  if (targets.length === 0) {
    console.log('✅  No leftover reference-document data found. Database is clean!');
    console.log('─'.repeat(70) + '\n');
    process.exit(0);
  }

  console.log(`⚠️   Found ${targets.length} caregiver(s) with leftover reference-document data:\n`);
  targets.forEach((t, i) => {
    console.log(`  ${String(i + 1).padStart(3)}.  UID   : ${t.uid}`);
    console.log(`        URL   : ${t.referenceUrl || '(none)'}`);
    console.log(`        Count : ${t.referenceCount ?? '(none)'}`);
    console.log(`        Review: ${t.referenceReview ? JSON.stringify(t.referenceReview) : '(none)'}`);
    console.log();
  });
  console.log('─'.repeat(70));

  if (DRY_RUN) {
    console.log('\n💡  This was a DRY RUN. Nothing was deleted or changed.');
    console.log('    To permanently delete these files and fields, run:\n');
    console.log('      node cleanup_reference_documents.js --delete\n');
    process.exit(0);
  }

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = await new Promise(resolve => {
    rl.question(
      `\n🚨  You are about to PERMANENTLY DELETE ${targets.length} Cloudinary file(s) and\n` +
      '    clear the matching Firestore fields. This cannot be undone. Continue? (y/N): ',
      resolve
    );
  });
  rl.close();
  if (answer.trim().toLowerCase() !== 'y') {
    console.log('\n❌  Aborted. Nothing was deleted or changed.\n');
    process.exit(0);
  }

  console.log('\n🗑️   Cleaning up...\n');
  let filesDeleted = 0;
  let fileErrors = 0;
  let docsUpdated = 0;

  for (const t of targets) {
    process.stdout.write(`  ${t.uid}: `);

    if (t.referenceUrl) {
      const result = await deleteFromCloudinary(t.referenceUrl);
      if (result.ok) {
        process.stdout.write(`file ${result.result === 'not_found' ? '(already gone)' : 'deleted'} ✅  `);
        filesDeleted++;
      } else {
        process.stdout.write(`file delete FAILED (${result.reason}) ❌  `);
        fileErrors++;
      }
    }

    try {
      await t.ref.update({
        referenceUrl: FieldValue.delete(),
        referenceCount: FieldValue.delete(),
        'documentReviews.reference': FieldValue.delete(),
      });
      console.log('fields cleared ✅');
      docsUpdated++;
    } catch (err) {
      console.log(`fields FAILED (${err.message}) ❌`);
    }
  }

  console.log('\n' + '═'.repeat(70));
  console.log('  Cleanup complete.');
  console.log(`  ✅  Cloudinary files deleted : ${filesDeleted}`);
  if (fileErrors > 0) console.log(`  ❌  Cloudinary file errors    : ${fileErrors}`);
  console.log(`  ✅  Firestore docs updated   : ${docsUpdated} / ${targets.length}`);
  console.log('═'.repeat(70) + '\n');
}

main().catch(err => {
  console.error('\n❌  Fatal error:', err.message);
  process.exit(1);
});
