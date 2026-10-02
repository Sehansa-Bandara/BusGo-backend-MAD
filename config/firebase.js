const admin = require('firebase-admin');

let firebaseApp = null;

try {
  if (!admin.apps.length) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
      : undefined;

    if (projectId && clientEmail && privateKey && !clientEmail.includes('your_firebase')) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      console.log('Firebase Admin SDK initialized with service account certificate');
    } else {
      // Default initialization
      firebaseApp = admin.initializeApp({
        projectId: projectId && !projectId.includes('your_firebase') ? projectId : 'busgo-app',
      });
      console.log('Firebase Admin SDK initialized in default mode');
    }
  } else {
    firebaseApp = admin.app();
  }
} catch (error) {
  console.warn('Firebase Admin SDK initialization warning:', error.message);
}

module.exports = admin;
