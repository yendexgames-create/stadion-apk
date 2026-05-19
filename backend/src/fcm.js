import admin from "firebase-admin";
import { config } from "./config.js";

let initialized = false;

export function initFcm() {
  if (initialized) return true;
  if (!config.firebase.projectId || !config.firebase.clientEmail || !config.firebase.privateKey) return false;

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: config.firebase.projectId,
      clientEmail: config.firebase.clientEmail,
      privateKey: config.firebase.privateKey
    })
  });
  initialized = true;
  return true;
}

export async function sendPush(tokens, payload) {
  if (!tokens?.length) return { successCount: 0, failureCount: 0 };
  if (!initFcm()) throw new Error("FCM not configured");
  return admin.messaging().sendEachForMulticast({ tokens, ...payload });
}
