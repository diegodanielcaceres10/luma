// Service worker for Firebase Cloud Messaging (web push).
//
// The placeholders below are replaced at build time by
// scripts/configure_web_push.sh (see README). Do not hardcode values here.

// Registered before the SDK loads so it runs first: the SDK does nothing on
// click when the message has no link.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windows) => {
        if (windows.length > 0) return windows[0].focus();
        return self.clients.openWindow('/');
      }),
  );
});

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: '__FIREBASE_WEB_API_KEY__',
  appId: '__FIREBASE_WEB_APP_ID__',
  messagingSenderId: '__FIREBASE_MESSAGING_SENDER_ID__',
  projectId: '__FIREBASE_PROJECT_ID__',
});

// Messages with a "notification" payload are shown by the SDK while the app
// is closed or in the background.
firebase.messaging();
