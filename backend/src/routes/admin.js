import { Router } from "express";
import { col } from "../db.js";
import { normalizePhone } from "../phone.js";
import { signJwt, verifyPassword } from "../security.js";

export const adminRouter = Router();

adminRouter.post("/login", async (req, res) => {
  const phone = normalizePhone(req.body?.phone);
  const password = String(req.body?.password || "");
  if (!phone) return res.status(400).json({ error: "INVALID_PHONE" });
  if (!password) return res.status(400).json({ error: "INVALID_PASSWORD" });

  const admin = await col("admins").findOne({ phone });
  if (!admin) return res.status(400).json({ error: "WRONG_CREDENTIALS" });

  const ok = await verifyPassword(password, admin.passwordHash);
  if (!ok) return res.status(400).json({ error: "WRONG_CREDENTIALS" });

  const token = signJwt({ role: "admin", adminId: String(admin._id), phone });
  res.json({ token, admin: { id: String(admin._id), phone: admin.phone, name: admin.name || "" } });
});
