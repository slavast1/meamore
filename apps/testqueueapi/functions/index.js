/**
 * Firebase Cloud Function proxy for getBusinessAppointments
 * - Solves CORS for Flutter Web by calling the target endpoint server-to-server
 * - Hardcodes the x-api-key ONLY in the server function (not in the browser)
 *
 * Deploy:
 *   firebase deploy --only functions:proxyBusinessAppointments
 *
 * Call from Flutter:
 *   https://<region>-<project>.cloudfunctions.net/proxyBusinessAppointments?dueDate=YYYY-MM-DD
 */

const { onRequest } = require("firebase-functions/v2/https");

// ? Hardcoded API key (server-side). Do NOT hardcode this in Flutter Web.
const API_KEY = "PASTE_YOUR_KEY_HERE";

exports.proxyBusinessAppointments = onRequest(async (req, res) => {
  // ----- CORS -----
  // For production, replace "*" with your real web origin, e.g. "https://yourapp.web.app"
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // Preflight request
  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  // Only allow GET
  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // Validate query
  const dueDate = req.query.dueDate;
  if (!dueDate) {
    return res.status(400).json({ error: "Missing dueDate query param" });
  }

  // Build target URL
  const targetUrl =
    "https://us-central1-digi-tor.cloudfunctions.net/getBusinessAppointments" +
    `?dueDate=${encodeURIComponent(String(dueDate))}`;

  try {
    // Server-to-server call (no browser CORS here)
    const r = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "x-api-key": API_KEY,
      },
    });

    const bodyText = await r.text();

    // Pass-through status and content-type
    res.status(r.status);
    res.set("Content-Type", r.headers.get("content-type") || "application/json");

    // Optional: cache control
    // res.set("Cache-Control", "no-store");

    return res.send(bodyText);
  } catch (e) {
    return res.status(500).json({
      error: "Proxy call failed",
      details: String(e),
    });
  }
});
