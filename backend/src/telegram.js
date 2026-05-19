import { Telegraf, Markup } from "telegraf";
import { col } from "./db.js";
import { config } from "./config.js";
import { normalizePhone } from "./phone.js";

let botInstance;

export function createTelegramBot() {
  if (!config.telegramBotToken) return null;
  if (botInstance) return botInstance;

  const bot = new Telegraf(config.telegramBotToken);

  bot.start(async (ctx) => {
    await ctx.reply(
      "Telefon raqamingizni yuboring.",
      Markup.keyboard([Markup.button.contactRequest("Kontakt yuborish")]).resize()
    );
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

    await ctx.reply("Rahmat. Endi ilovaga qaytib kodni so‘rashingiz mumkin.", Markup.removeKeyboard());
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
