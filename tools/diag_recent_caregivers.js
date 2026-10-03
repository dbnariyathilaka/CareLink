// Read-only diagnostic: dumps every caregiverProfiles doc (small collection
// expected) so we can see exactly what fields each one actually has.
const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

function render(v) {
  if (v && typeof v === 'object' && typeof v._seconds === 'number') {
    return new Date(v._seconds * 1000).toISOString();
  }
  return v;
}

async function main() {
  const snap = await db.collection('caregiverProfiles').get();
  console.log('Total caregiverProfiles docs:', snap.size);

  for (const doc of snap.docs) {
    const d = doc.data();
    console.log('='.repeat(70));
    console.log('doc id:', doc.id);
    console.log(JSON.stringify(d, (k, v) => render(v), 2));
  }
}

main().catch(err => { console.error(err); process.exit(1); });
