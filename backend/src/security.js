import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { config } from "./config.js";

export function signJwt(payload) {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: "30d" });
}

export function verifyJwt(token) {
  return jwt.verify(token, config.jwtSecret);
}

export async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

export async function verifyPassword(password, hash) {
  return bcrypt.compare(password, hash);
}
