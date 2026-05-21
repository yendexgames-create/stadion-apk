import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: Number(process.env.PORT || 8080),
  mongodbUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  publicBaseUrl: process.env.PUBLIC_BASE_URL,
  tzOffsetMinutes: Number(process.env.TZ_OFFSET_MINUTES || 300),
  telegramBotToken: process.env.TELEGRAM_BOT_TOKEN,
  telegramWebhookSecret: process.env.TELEGRAM_WEBHOOK_SECRET,
  androidApkUrl: process.env.ANDROID_APK_URL,
  androidApkSha256: process.env.ANDROID_APK_SHA256,
  iosInstallUrl: process.env.IOS_INSTALL_URL,
  androidLatestVersionName: process.env.ANDROID_LATEST_VERSION_NAME,
  androidLatestVersionCode: Number(process.env.ANDROID_LATEST_VERSION_CODE || 0),
  iosLatestVersionName: process.env.IOS_LATEST_VERSION_NAME,
  iosLatestVersionCode: Number(process.env.IOS_LATEST_VERSION_CODE || 0),
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n")
  }
};

export function assertConfig() {
  const required = ["mongodbUri", "jwtSecret", "publicBaseUrl"];
  for (const k of required) {
    if (!config[k]) throw new Error(`Missing env: ${k}`);
  }
}
