// Read-only diagnostic: dump patientProfiles + users, to find the test
// patient account and see exactly what careType/careLevel/requiredSkills/
// preferredCaregiverGender/city it has on file.
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
  const snap = await db.collection('patientProfiles').get();
  console.log('Total patientProfiles docs:', snap.size);
  for (const doc of snap.docs) {
    console.log('='.repeat(70));
    console.log('doc id:', doc.id);
    console.log(JSON.stringify(doc.data(), (k, v) => render(v), 2));
  }
}

main().catch(err => { console.error(err); process.exit(1); });
