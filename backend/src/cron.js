import cron from "node-cron";
import { col } from "./db.js";
import { addDaysYmd, todayYmd } from "./time.js";
import { sendPush } from "./fcm.js";

export function startCron() {
  cron.schedule("0 * * * *", async () => {
    const today = todayYmd();
    const in1Day = addDaysYmd(today, 1);

    const expiring = await col("weekly_series")
      .find({
        canceledAt: { $exists: false },
        notifiedAt: { $exists: false },
        endDate: { $gte: today, $lte: in1Day }
      })
      .toArray();

    for (const s of expiring) {
      const user = await col("users").findOne({ _id: s.userId });
      const tokens = user?.fcmTokens || [];
      if (!tokens.length) continue;

      try {
        await sendPush(tokens, {
          notification: { title: "Haftalik bron", body: "Sizning haftalik broningiz tugayapti." },
          data: { type: "weekly_expiring", seriesId: String(s._id) }
        });
        await col("weekly_series").updateOne({ _id: s._id }, { $set: { notifiedAt: new Date() } });
      } catch {}
    }
  });
}
