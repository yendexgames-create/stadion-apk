import express from "express";
import { assertConfig, config } from "./config.js";
import { connectDb } from "./db.js";
import { authRouter } from "./routes/auth.js";
import { adminRouter } from "./routes/admin.js";
import { appRouter } from "./routes/app.js";
import { meRouter } from "./routes/me.js";
import { slotsRouter } from "./routes/slots.js";
import { bookingsRouter } from "./routes/bookings.js";
import { penaltiesRouter } from "./routes/penalties.js";
import { adminScheduleRouter } from "./routes/admin_schedule.js";
import { requireAdmin, requireAuth } from "./middleware/auth.js";
import { createTelegramBot, telegramWebhookMiddleware } from "./telegram.js";
import { startCron } from "./cron.js";

async function main() {
  assertConfig();
  await connectDb();

  const app = express();
  app.use(express.json({ limit: "1mb" }));

  app.get("/health", (req, res) => res.json({ ok: true }));

  app.use("/app", appRouter);
  app.use("/auth", authRouter);
  app.use("/admin", adminRouter);
  app.use("/me", requireAuth, meRouter);
  app.use("/slots", requireAuth, slotsRouter);
  app.use("/bookings", requireAuth, bookingsRouter);
  app.use("/admin/penalties", requireAuth, requireAdmin, penaltiesRouter);
  app.use("/admin/schedule", requireAuth, requireAdmin, adminScheduleRouter);

  const bot = createTelegramBot();
  if (bot) {
    try {
      const isLocal = config.publicBaseUrl.includes("localhost") || config.publicBaseUrl.includes("127.0.0.1");
      if (isLocal) {
        await bot.launch();
      } else {
        if (config.telegramWebhookSecret) {
          app.post("/telegram/webhook", (req, res, next) => {
            const secret = req.header("x-telegram-bot-api-secret-token");
            if (secret !== config.telegramWebhookSecret) return res.status(403).end();
            next();
          });
        }

        app.post("/telegram/webhook", telegramWebhookMiddleware(bot));

        await bot.telegram.setWebhook(`${config.publicBaseUrl}/telegram/webhook`, {
          secret_token: config.telegramWebhookSecret || undefined
        });
      }
    } catch (e) {
      process.stderr.write(`${e?.message || e}\n`);
    }
  }

  startCron();

  // LAN/telefon/emulator’dan ham kirish uchun barcha interfeyslarda tinglaymiz.
  app.listen(config.port, "0.0.0.0", () => {
    process.stdout.write(`listening ${config.port}\n`);
  });
}

main();
