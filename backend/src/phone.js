export function normalizePhone(phone) {
  const p = String(phone || "").replace(/[^\d+]/g, "");
  if (!p) return null;
  if (p.startsWith("+")) return p;
  if (p.startsWith("998")) return `+${p}`;
  if (p.startsWith("0")) return `+998${p.slice(1)}`;
  return `+${p}`;
}
