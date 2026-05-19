import { Router } from "express";
import { ObjectId } from "mongodb";
import { col } from "../db.js";
import { addDaysYmd, hmAdd1Hour, isValidHm, isValidYmd, slotTimes, todayYmd, weekdayOfYmd } from "../time.js";

const PENALTY_AMOUNT = 100000;

export const bookingsRouter = Router();

bookingsRouter.get("/my", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const daily = await col("bookings")
    .find(
      { userId: new ObjectId(userId), type: "daily", canceledAt: { $exists: false } },
      { sort: { date: 1, startTime: 1 } }
    )
    .toArray();

  const weeklySeries = await col("weekly_series")
    .find({ userId: new ObjectId(userId), canceledAt: { $exists: false } }, { sort: { createdAt: -1 } })
    .toArray();

  res.json({
    daily: daily.map((b) => ({ id: String(b._id), date: b.date, startTime: b.startTime, endTime: b.endTime })),
    weekly: weeklySeries.map((s) => ({
      id: String(s._id),
      startDate: s.startDate,
      endDate: s.endDate,
      weekday: s.weekday,
      startTime: s.startTime,
      endTime: s.endTime
    }))
  });
});

bookingsRouter.post("/daily", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const date = String(req.body?.date || "");
  const startTime = String(req.body?.startTime || "");
  if (!isValidYmd(date)) return res.status(400).json({ error: "INVALID_DATE" });
  if (!isValidHm(startTime) || !slotTimes().includes(startTime)) return res.status(400).json({ error: "INVALID_TIME" });

  const doc = {
    type: "daily",
    slotKey: `${date}_${startTime}`,
    userId: new ObjectId(userId),
    date,
    startTime,
    endTime: hmAdd1Hour(startTime),
    createdAt: new Date()
  };

  try {
    const r = await col("bookings").insertOne(doc);
    res.json({ id: String(r.insertedId) });
  } catch {
    res.status(409).json({ error: "SLOT_BUSY" });
  }
});

bookingsRouter.post("/weekly", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const startDate = String(req.body?.startDate || "");
  const startTime = String(req.body?.startTime || "");
  if (!isValidYmd(startDate)) return res.status(400).json({ error: "INVALID_DATE" });
  if (!isValidHm(startTime) || !slotTimes().includes(startTime)) return res.status(400).json({ error: "INVALID_TIME" });

  const dates = [];
  for (let i = 0; i < 6; i++) dates.push(addDaysYmd(startDate, i * 7));

  const conflicts = await col("bookings")
    .find({ date: { $in: dates }, startTime, canceledAt: { $exists: false } }, { projection: { date: 1 } })
    .toArray();

  if (conflicts.length) return res.status(409).json({ error: "SLOT_BUSY", conflicts: conflicts.map((c) => c.date) });

  const seriesDoc = {
    userId: new ObjectId(userId),
    startDate,
    endDate: dates[dates.length - 1],
    weekday: weekdayOfYmd(startDate),
    startTime,
    endTime: hmAdd1Hour(startTime),
    weeks: 6,
    createdAt: new Date()
  };

  const seriesInsert = await col("weekly_series").insertOne(seriesDoc);

  const bookingDocs = dates.map((date, idx) => ({
    type: "weekly",
    slotKey: `${date}_${startTime}`,
    seriesId: seriesInsert.insertedId,
    weekIndex: idx,
    userId: new ObjectId(userId),
    date,
    startTime,
    endTime: hmAdd1Hour(startTime),
    createdAt: new Date()
  }));

  try {
    await col("bookings").insertMany(bookingDocs, { ordered: true });
  } catch {
    await col("weekly_series").deleteOne({ _id: seriesInsert.insertedId });
    await col("bookings").deleteMany({ seriesId: seriesInsert.insertedId });
    return res.status(409).json({ error: "SLOT_BUSY" });
  }

  res.json({ seriesId: String(seriesInsert.insertedId) });
});

bookingsRouter.delete("/weekly-series/:id", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const id = String(req.params.id || "");
  if (!ObjectId.isValid(id)) return res.status(400).json({ error: "INVALID_ID" });

  const series = await col("weekly_series").findOne({ _id: new ObjectId(id) });
  if (!series) return res.status(404).json({ error: "NOT_FOUND" });
  if (String(series.userId) !== String(userId)) return res.status(403).json({ error: "FORBIDDEN" });
  if (series.canceledAt) return res.json({ ok: true });

  const now = new Date();
  const today = todayYmd();

  await col("weekly_series").updateOne({ _id: series._id }, { $set: { canceledAt: now } });
  await col("bookings").updateMany(
    { seriesId: series._id, canceledAt: { $exists: false }, date: { $gte: today } },
    { $set: { canceledAt: now }, $unset: { slotKey: "" } }
  );

  const hadToday = await col("bookings").findOne({
    seriesId: series._id,
    date: today,
    startTime: series.startTime,
    canceledAt: now
  });

  if (hadToday) {
    await col("penalties").insertOne({
      userId: series.userId,
      seriesId: series._id,
      amount: PENALTY_AMOUNT,
      date: today,
      startTime: series.startTime,
      createdAt: now
    });
  }

  res.json({ ok: true });
});

bookingsRouter.delete("/:id", async (req, res) => {
  const userId = req.auth?.userId;
  if (!userId) return res.status(401).json({ error: "UNAUTHORIZED" });

  const id = String(req.params.id || "");
  if (!ObjectId.isValid(id)) return res.status(400).json({ error: "INVALID_ID" });

  const booking = await col("bookings").findOne({ _id: new ObjectId(id) });
  if (!booking) return res.status(404).json({ error: "NOT_FOUND" });
  if (String(booking.userId) !== String(userId)) return res.status(403).json({ error: "FORBIDDEN" });
  if (booking.canceledAt) return res.json({ ok: true });
  if (booking.type !== "daily") return res.status(400).json({ error: "USE_WEEKLY_CANCEL" });

  const now = new Date();
  await col("bookings").updateOne({ _id: booking._id }, { $set: { canceledAt: now }, $unset: { slotKey: "" } });

  if (booking.date === todayYmd()) {
    await col("penalties").insertOne({
      userId: booking.userId,
      bookingId: booking._id,
      amount: PENALTY_AMOUNT,
      date: booking.date,
      startTime: booking.startTime,
      createdAt: now
    });
    await col("bookings").updateOne({ _id: booking._id }, { $set: { penaltyApplied: true } });
  }

  res.json({ ok: true });
});
