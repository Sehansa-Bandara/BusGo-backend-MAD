const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

let app;

if (getApps().length === 0) {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    app = initializeApp({
      credential: cert(serviceAccount),
    });
  } else {
    app = initializeApp();
  }
} else {
  app = getApps()[0];
}

const db = getFirestore(app);

// Provide backward compatible admin object with messaging() method
const admin = {
  app,
  messaging: () => getMessaging(app),
};

module.exports = {
  admin,
  db,
};
