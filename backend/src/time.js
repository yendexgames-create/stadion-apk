import { config } from "./config.js";

export function nowInTz() {
  return new Date(Date.now() + config.tzOffsetMinutes * 60 * 1000);
}

export function todayYmd() {
  const d = nowInTz();
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function nowHm() {
  const d = nowInTz();
  const h = String(d.getUTCHours()).padStart(2, "0");
  const m = String(d.getUTCMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}

export function isValidYmd(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

export function isValidHm(value) {
  return typeof value === "string" && /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value);
}

export function addDaysYmd(ymd, days) {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + days);
  const yy = dt.getUTCFullYear();
  const mm = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(dt.getUTCDate()).padStart(2, "0");
  return `${yy}-${mm}-${dd}`;
}

export function weekdayOfYmd(ymd) {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCDay();
}

export function slotTimes() {
  const times = [];
  for (let h = 19; h <= 23; h++) times.push(`${String(h).padStart(2, "0")}:00`);
  return times;
}

export function hmAdd1Hour(hm) {
  const [h, m] = hm.split(":").map(Number);
  const hh = (h + 1) % 24;
  return `${String(hh).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}
