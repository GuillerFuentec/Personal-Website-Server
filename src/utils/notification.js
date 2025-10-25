// lib/notificationapi.ts
import notificationapi from 'notificationapi-node-server-sdk';

let initialized = false;

export const initializeNotificationAPI = () => {
  if (!initialized) {
    const {
      NOTIFICATION_API_CLIENT_ID: apiKey,
      NOTIFICATION_API_CLIENT_SECRET: apiSecret,
      NOTIFICATION_API_BASE_URL: baseURL,
    } = process.env;

    if (!apiKey || !apiSecret) {
      throw new Error(
        "Notification API credentials not found. Define NOTIFICATION_API_CLIENT_ID and NOTIFICATION_API_CLIENT_SECRET."
      );
    }

    notificationapi.init(apiKey, apiSecret, baseURL ? { baseURL } : undefined);
    initialized = true;
  }

  return notificationapi;
};
