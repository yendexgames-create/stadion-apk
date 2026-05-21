import { Telegraf, Markup } from "telegraf";
import { col } from "./db.js";
import { config } from "./config.js";
import { normalizePhone } from "./phone.js";

let botInstance;

const PLATFORM_ANDROID = "platform_android";
const PLATFORM_IOS = "platform_ios";

function platformKeyboard() {
  return Markup.inlineKeyboard([
    [Markup.button.callback("Android", PLATFORM_ANDROID), Markup.button.callback("iPhone (iOS)", PLATFORM_IOS)]
  ]);
}

function androidInstallText() {
  const parts = ["Android uchun ilovani yuklab oling.", "", "APK xavfsiz, bemalol ruxsat beravering.", ""];

  if (config.androidApkSha256) {
    parts.push(`APK SHA-256: ${config.androidApkSha256}`, "");
  }

  if (config.androidApkUrl) {
    parts.push("APK havolasi pastda.");
  } else {
    parts.push("APK havolasi hozircha sozlanmagan (admin ANDROID_APK_URL qo‘yishi kerak).");
  }

  return parts.join("\n");
}

function iosInstallText() {
  const parts = [
    "iPhone (iOS) uchun o‘rnatish.",
    "",
    "iOS’da APK kabi “oddiy yuklab olib o‘rnatish” yo‘q. Odatda TestFlight yoki App Store orqali o‘rnatiladi.",
    ""
  ];

  if (config.iosInstallUrl) {
    parts.push("TestFlight/App Store havolasi pastda.");
  } else {
    parts.push("iOS havolasi hozircha sozlanmagan (admin IOS_INSTALL_URL qo‘yishi kerak).");
  }

  return parts.join("\n");
}

async function sendPlatformChoice(ctx) {
  await ctx.reply("Qaysi telefonga yuklaysiz?", platformKeyboard());
}

export function createTelegramBot() {
  if (!config.telegramBotToken) return null;
  if (botInstance) return botInstance;

  const bot = new Telegraf(config.telegramBotToken);

  bot.start(async (ctx) => {
    await ctx.reply(
      "Telefon raqamingizni yuboring (Kontakt yuborish).",
      Markup.keyboard([Markup.button.contactRequest("Kontakt yuborish")]).resize()
    );
  });

  bot.command("download", async (ctx) => {
    await sendPlatformChoice(ctx);
  });

  bot.on("contact", async (ctx) => {
    const contact = ctx.message?.contact;
    const phone = normalizePhone(contact?.phone_number);
    if (!phone) return ctx.reply("Kontaktni qayta yuboring.");

    await col("users").updateOne(
      { phone },
      {
        $set: {
          phone,
          telegramChatId: ctx.chat.id,
          telegramUserId: ctx.from.id,
          updatedAt: new Date()
        },
        $setOnInsert: { createdAt: new Date() }
      },
      { upsert: true }
    );

    await ctx.reply("Rahmat. Endi platformani tanlang.", Markup.removeKeyboard());
    await sendPlatformChoice(ctx);
  });

  bot.action(PLATFORM_ANDROID, async (ctx) => {
    await ctx.answerCbQuery();
    await col("users").updateOne(
      { telegramChatId: ctx.chat?.id },
      { $set: { preferredPlatform: "android", updatedAt: new Date() }, $setOnInsert: { createdAt: new Date() } },
      { upsert: true }
    );

    const url = config.androidApkUrl;
    if (url) {
      try {
        await ctx.replyWithDocument({ url }, { caption: androidInstallText() });
        return;
      } catch {
        await ctx.reply(androidInstallText(), Markup.inlineKeyboard([[Markup.button.url("APKni yuklab olish", url)]]));
        return;
      }
    }
    await ctx.reply(androidInstallText());
  });

  bot.action(PLATFORM_IOS, async (ctx) => {
    await ctx.answerCbQuery();
    await col("users").updateOne(
      { telegramChatId: ctx.chat?.id },
      { $set: { preferredPlatform: "ios", updatedAt: new Date() }, $setOnInsert: { createdAt: new Date() } },
      { upsert: true }
    );

    const url = config.iosInstallUrl;
    if (url) {
      await ctx.reply(iosInstallText(), Markup.inlineKeyboard([[Markup.button.url("iOS havolasi", url)]]));
      return;
    }
    await ctx.reply(iosInstallText());
  });

  botInstance = bot;
  return botInstance;
}

export async function sendTelegramMessage(chatId, text) {
  const bot = createTelegramBot();
  if (!bot) throw new Error("Telegram bot is not configured");
  await bot.telegram.sendMessage(chatId, text);
}

export function telegramWebhookMiddleware(bot) {
  return async (req, res) => {
    try {
      await bot.handleUpdate(req.body, res);
    } catch {
      res.status(200).end();
    }
  };
}
