import { connectDb, col, closeDb } from "../db.js";
import { assertConfig } from "../config.js";
import { normalizePhone } from "../phone.js";
import { hashPassword } from "../security.js";

async function main() {
  assertConfig();
  await connectDb();

  const phone = normalizePhone(process.argv[2]);
  const name = String(process.argv[3] || "Admin");
  const password = String(process.argv[4] || "");

  if (!phone || !password) {
    throw new Error("Usage: npm run seed:admin -- +998901234567 \"Admin\" \"password\"");
  }

  const passwordHash = await hashPassword(password);

  await col("admins").updateOne(
    { phone },
    { $set: { phone, name, passwordHash, updatedAt: new Date() }, $setOnInsert: { createdAt: new Date() } },
    { upsert: true }
  );

  await closeDb();
}

main().catch(async (e) => {
  console.error(e.message || e);
  process.exitCode = 1;
  try {
    await closeDb();
  } catch {}
});
