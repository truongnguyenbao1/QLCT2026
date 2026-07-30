importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD91uuHDDMlaX8r2MN9cCKmedcOTqO8D8E",
  authDomain: "qlct2026.firebaseapp.com",
  projectId: "qlct2026",
  storageBucket: "qlct2026.firebasestorage.app",
  messagingSenderId: "1017215910567",
  appId: "1:1017215910567:web:c403fc8aaf4b70624b9182",
  measurementId: "G-EMJXP6NX8F"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Cấu hình thông báo tùy chỉnh nếu cần thiết
});
