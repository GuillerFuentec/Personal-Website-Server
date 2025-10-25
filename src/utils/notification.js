// lib/notificationapi.ts
import notificationapi from 'notificationapi-node-server-sdk';

let initilized = false;

export const initializeNotificationAPI = () => {
  if (!initilized) {
    notificationapi.init({
      apiKey: process.env.NOTIFICATION_API_KEY,
      apiSecret: process.env.NOTIFICATION_API_SECRET,
      baseUrl: process.env.NOTIFICATION_API_BASE_URL,
    });
    initilized = true;
  }
  return notificationapi;
}
