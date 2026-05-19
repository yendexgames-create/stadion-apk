import { Router } from "express";
import { ObjectId } from "mongodb";
import { col } from "../db.js";
import { hmAdd1Hour, isValidYmd, slotTimes } from "../time.js";

export const slotsRouter = Router();

slotsRouter.get("/", async (req, res) => {
  const date = String(req.query?.date || "");
  if (!isValidYmd(date)) return res.status(400).json({ error: "INVALID_DATE" });

  const userId = req.auth?.userId;
  const myId = userId ? new ObjectId(userId) : null;

  const bookings = await col("bookings")
    .find({ date, canceledAt: { $exists: false } }, { projection: { userId: 1, startTime: 1, type: 1 } })
    .toArray();

  const byStart = new Map(bookings.map((b) => [b.startTime, b]));
  const result = [];

  for (const startTime of slotTimes()) {
    const b = byStart.get(startTime);
    if (!b) {
      result.push({ startTime, endTime: hmAdd1Hour(startTime), status: "free" });
      continue;
    }

    const mine = myId ? String(b.userId) === String(myId) : false;
    result.push({
      startTime,
      endTime: hmAdd1Hour(startTime),
      status: "busy",
      mine,
      bookingType: b.type,
      bookingId: String(b._id)
    });
  }

  res.json({ date, slots: result });
});
