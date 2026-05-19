import { Router } from "express";
import { ObjectId } from "mongodb";
import { col } from "../db.js";

export const penaltiesRouter = Router();

penaltiesRouter.get("/", async (req, res) => {
  const items = await col("penalties")
    .find({}, { sort: { createdAt: -1 }, limit: 200 })
    .toArray();

  const userIds = [...new Set(items.map((p) => String(p.userId)))].filter((x) => ObjectId.isValid(x));
  const users = await col("users")
    .find({ _id: { $in: userIds.map((id) => new ObjectId(id)) } }, { projection: { name: 1, phone: 1 } })
    .toArray();
  const userMap = new Map(users.map((u) => [String(u._id), u]));

  res.json(
    items.map((p) => {
      const u = userMap.get(String(p.userId));
      return {
        id: String(p._id),
        amount: p.amount,
        date: p.date,
        startTime: p.startTime,
        createdAt: p.createdAt,
        user: u ? { name: u.name || "", phone: u.phone } : null
      };
    })
  );
});
