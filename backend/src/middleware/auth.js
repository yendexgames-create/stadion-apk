import { verifyJwt } from "../security.js";

export function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "UNAUTHORIZED" });
  try {
    const payload = verifyJwt(token);
    req.auth = payload;
    next();
  } catch {
    return res.status(401).json({ error: "UNAUTHORIZED" });
  }
}

export function requireAdmin(req, res, next) {
  if (!req.auth) return res.status(401).json({ error: "UNAUTHORIZED" });
  if (req.auth.role !== "admin") return res.status(403).json({ error: "FORBIDDEN" });
  next();
}
