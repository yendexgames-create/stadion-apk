import { Router } from "express";
import { config } from "../config.js";

export const appRouter = Router();

appRouter.get("/latest", async (req, res) => {
  const platform = String(req.query?.platform || "").toLowerCase();
  if (platform !== "android" && platform !== "ios") return res.status(400).json({ error: "INVALID_PLATFORM" });

  if (platform === "android") {
    return res.json({
      platform,
      versionName: config.androidLatestVersionName || "",
      versionCode: Number(config.androidLatestVersionCode || 0),
      url: config.androidApkUrl || "",
      sha256: config.androidApkSha256 || ""
    });
  }

  return res.json({
    platform,
    versionName: config.iosLatestVersionName || "",
    versionCode: Number(config.iosLatestVersionCode || 0),
    url: config.iosInstallUrl || "",
    sha256: ""
  });
});

