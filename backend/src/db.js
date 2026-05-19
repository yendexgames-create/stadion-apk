import { MongoClient } from "mongodb";
import { config } from "./config.js";

let client;
let db;

export async function connectDb() {
  client = new MongoClient(config.mongodbUri);
  await client.connect();
  db = client.db();
  await ensureIndexes();
  return db;
}

export function getDb() {
  if (!db) throw new Error("DB not connected");
  return db;
}

export function col(name) {
  return getDb().collection(name);
}

async function ensureIndexes() {
  const users = client.db().collection("users");
  const admins = client.db().collection("admins");
  const otp = client.db().collection("otp_requests");
  const bookings = client.db().collection("bookings");
  const weekly = client.db().collection("weekly_series");
  const penalties = client.db().collection("penalties");

  await Promise.all([
    users.createIndex({ phone: 1 }, { unique: true }),
    users.createIndex({ telegramChatId: 1 }, { sparse: true }),
    admins.createIndex({ phone: 1 }, { unique: true }),
    otp.createIndex({ phone: 1 }),
    otp.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    bookings.createIndex({ slotKey: 1 }, { unique: true, sparse: true }),
    bookings.createIndex({ date: 1, startTime: 1 }),
    bookings.createIndex({ userId: 1, date: 1 }),
    weekly.createIndex({ userId: 1 }),
    weekly.createIndex({ startDate: 1, endDate: 1 }),
    penalties.createIndex({ createdAt: 1 })
  ]);
}

export async function closeDb() {
  if (client) await client.close();
}
