importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAxfpREcSLwxjOcdinp-aYvsHFlIChNXec',
  appId: '1:344927444374:web:e68763f96111d6185851b7',
  messagingSenderId: '344927444374',
  projectId: 'people-management-tool',
  authDomain: 'people-management-tool.firebaseapp.com',
  storageBucket: 'people-management-tool.firebasestorage.app',
});

firebase.messaging();
