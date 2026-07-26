// Firebase Cloud Messaging background notifications for the Flutter web app.
// Firebase's public web configuration is safe to expose in client code.
importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyDkFHfACTB0Hozt8mwpspZ068GOMaH7BbY',
  appId: '1:433193562880:web:db4819985d4e39da50b9e5',
  messagingSenderId: '433193562880',
  projectId: 'herbaformix',
  authDomain: 'herbaformix.firebaseapp.com',
  storageBucket: 'herbaformix.firebasestorage.app',
});

// Creating the Messaging instance registers the background message handler
// used by the Firebase SDK to display notification payloads.
firebase.messaging();
