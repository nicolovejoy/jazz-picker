import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "***REMOVED***",
  authDomain: "jazz-picker.firebaseapp.com",
  projectId: "jazz-picker",
  storageBucket: "jazz-picker.firebasestorage.app",
  messagingSenderId: "1038351022908",
  appId: "1:1038351022908:web:1f990ae4300661a606bc39",
  measurementId: "G-W2WF4BPNRD"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export default app;
