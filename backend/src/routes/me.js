import { Router } from "express";
import { ObjectId } from "mongodb";
import { col } from "../db.js";
import { nowHm, todayYmd } from "../time.js";

export const meRouter = Router();

meRouter.get("/", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const user = await col("users").findOne({ _id: new ObjectId(userId) });
  if (!user) return res.status(404).json({ error: "NOT_FOUND" });

  const today = todayYmd();
  const hm = nowHm();

  const completed = await col("bookings").countDocuments({
    userId: new ObjectId(userId),
    canceledAt: { $exists: false },
    $or: [{ date: { $lt: today } }, { date: today, endTime: { $lte: hm } }]
  });

  res.json({
    id: String(user._id),
    phone: user.phone,
    name: user.name || "",
    gamesCount: completed
  });
});
