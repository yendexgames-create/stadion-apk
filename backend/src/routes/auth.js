import { Router } from "express";
import bcrypt from "bcryptjs";
import { col } from "../db.js";
import { normalizePhone } from "../phone.js";
import { sendTelegramMessage } from "../telegram.js";
import { signJwt } from "../security.js";

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

export const authRouter = Router();

authRouter.post("/request-otp", async (req, res) => {
  const phone = normalizePhone(req.body?.phone);
  const name = String(req.body?.name || "").trim();
  if (!phone) return res.status(400).json({ error: "INVALID_PHONE" });
  if (!name) return res.status(400).json({ error: "INVALID_NAME" });

  const user = await col("users").findOne({ phone });
  if (!user?.telegramChatId) return res.status(400).json({ error: "TELEGRAM_NOT_LINKED" });

  const code = generateOtp();
  const hash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

  await col("otp_requests").insertOne({
    phone,
    hash,
    expiresAt,
    createdAt: new Date()
  });

  await col("users").updateOne(
    { phone },
    { $set: { name, updatedAt: new Date() }, $setOnInsert: { createdAt: new Date() } },
    { upsert: true }
  );

  await sendTelegramMessage(user.telegramChatId, `Kirish kodi: ${code}`);

  res.json({ ok: true });
});

authRouter.post("/verify-otp", async (req, res) => {
  const phone = normalizePhone(req.body?.phone);
  const code = String(req.body?.code || "").trim();
  const fcmToken = String(req.body?.fcmToken || "").trim();
  if (!phone) return res.status(400).json({ error: "INVALID_PHONE" });
  if (!/^\d{6}$/.test(code)) return res.status(400).json({ error: "INVALID_CODE" });

  const otp = await col("otp_requests").find({ phone }).sort({ createdAt: -1 }).limit(1).next();
  if (!otp) return res.status(400).json({ error: "CODE_EXPIRED" });

  const ok = await bcrypt.compare(code, otp.hash);
  if (!ok) return res.status(400).json({ error: "WRONG_CODE" });

  await col("otp_requests").deleteMany({ phone });

  const update = { $set: { updatedAt: new Date() }, $setOnInsert: { phone, createdAt: new Date() } };
  if (fcmToken) update.$addToSet = { fcmTokens: fcmToken };

  await col("users").updateOne({ phone }, update, { upsert: true });
  const user = await col("users").findOne({ phone });
  if (!user) return res.status(500).json({ error: "INTERNAL_ERROR" });

  const token = signJwt({ role: "user", userId: String(user._id), phone });

  res.json({
    token,
    user: { id: String(user._id), phone: user.phone, name: user.name || "" }
  });
});
