import { Router } from "express";
import { ObjectId } from "mongodb";
import { col } from "../db.js";
import { addDaysYmd, hmAdd1Hour, isValidYmd, slotTimes } from "../time.js";

export const adminScheduleRouter = Router();

// Admin uchun 1 haftalik jadval: 7 kun × slotlar.
// GET /admin/schedule?startDate=YYYY-MM-DD  (startDate odatda dushanba)
adminScheduleRouter.get("/", async (req, res) => {
  const startDate = String(req.query?.startDate || "");
  if (!isValidYmd(startDate)) return res.status(400).json({ error: "INVALID_DATE" });

  const dates = [];
  for (let i = 0; i < 7; i++) dates.push(addDaysYmd(startDate, i));

  const bookings = await col("bookings")
    .find(
      { date: { $in: dates }, canceledAt: { $exists: false } },
      { projection: { userId: 1, date: 1, startTime: 1, endTime: 1, type: 1, seriesId: 1 } }
    )
    .toArray();

  const userIds = [...new Set(bookings.map((b) => String(b.userId)))].filter((x) => ObjectId.isValid(x));
  const users = await col("users")
    .find({ _id: { $in: userIds.map((id) => new ObjectId(id)) } }, { projection: { name: 1, phone: 1 } })
    .toArray();
  const userMap = new Map(users.map((u) => [String(u._id), u]));

  const byKey = new Map();
  for (const b of bookings) {
    byKey.set(`${b.date}_${b.startTime}`, b);
  }

  const times = slotTimes();
  const days = dates.map((date) => {
    const slots = times.map((startTime) => {
      const key = `${date}_${startTime}`;
      const b = byKey.get(key);
      if (!b) {
        return { startTime, endTime: hmAdd1Hour(startTime), status: "free" };
      }
      const u = userMap.get(String(b.userId));
      return {
        startTime,
        endTime: b.endTime || hmAdd1Hour(startTime),
        status: "busy",
        bookingType: b.type || null,
        user: u ? { name: u.name || "", phone: u.phone } : null
      };
    });
    return { date, slots };
  });

  res.json({ startDate, days });
});

