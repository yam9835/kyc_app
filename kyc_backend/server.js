const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const multer = require("multer");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());                            // allow Flutter web to call this
app.use(bodyParser.json({ limit: "10mb" })); // parse JSON bodies
app.use("/uploads", express.static(path.join(__dirname, "uploads"))); // serve files

// --- tiny JSON "database" ---
const DB_FILE = path.join(__dirname, "kyc_data.json");
if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, JSON.stringify({ users: {} }, null, 2));
const loadDb = () => JSON.parse(fs.readFileSync(DB_FILE));
const saveDb = (data) => fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));

// --- storage for file uploads ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads"),
  filename: (req, file, cb) => {
    const safePhone = (req.body.phone || "unknown").replace(/[^\d+]/g, "");
    const stamp = Date.now();
    const ext = path.extname(file.originalname || "") || ".bin";
    cb(null, `${safePhone}_${file.fieldname}_${stamp}${ext}`);
  },
});
const upload = multer({ storage });

// --- health check ---
app.get("/health", (_req, res) => res.json({ ok: true, service: "kyc_backend" }));

// --- start KYC (register phone) ---
app.post("/kyc/start", (req, res) => {
  const { phone } = req.body || {};
  if (!phone) return res.status(400).json({ error: "phone required" });

  const db = loadDb();
  if (!db.users[phone]) {
    db.users[phone] = {
      phone,
      status: "Pending",
      createdAt: new Date().toISOString(),
      docType: null,
      docUrl: null,
      selfieUrl: null,
      logs: [],
    };
  }
  db.users[phone].logs.push({ at: new Date().toISOString(), event: "KYC_STARTED" });
  saveDb(db);
  res.json({ message: "KYC started", user: db.users[phone] });
});

// --- upload KYC (multipart) ---
/*
Fields expected:
- phone (text)
- docType (text) -> one of: aadhaar | pan | voterid | dl
- docFile (file) -> the ID image/file
- selfieFile (file) -> selfie image
*/
app.post("/kyc/upload", upload.fields([{ name: "docFile" }, { name: "selfieFile" }]), (req, res) => {
  const { phone, docType } = req.body || {};
  if (!phone || !docType) return res.status(400).json({ error: "phone and docType required" });

  const doc = req.files?.docFile?.[0];
  const selfie = req.files?.selfieFile?.[0];
  if (!doc || !selfie) return res.status(400).json({ error: "docFile and selfieFile required" });

  const db = loadDb();
  if (!db.users[phone]) return res.status(404).json({ error: "user not found. Call /kyc/start first." });

  db.users[phone].docType = docType;
  db.users[phone].docUrl = `/uploads/${doc.filename}`;
  db.users[phone].selfieUrl = `/uploads/${selfie.filename}`;
  db.users[phone].status = "Under Review"; // pretend a reviewer/ML will verify
  db.users[phone].logs.push({ at: new Date().toISOString(), event: "FILES_UPLOADED", docType });
  saveDb(db);

  res.json({
    message: "Files uploaded",
    user: db.users[phone],
  });
});

// --- check status ---
app.get("/kyc/status/:phone", (req, res) => {
  const phone = req.params.phone;
  const db = loadDb();
  const user = db.users[phone];
  if (!user) return res.status(404).json({ error: "user not found" });
  res.json({ status: user.status, user });
});

// --- (optional) simulate verification toggle ---
app.post("/kyc/admin/verify", (req, res) => {
  const { phone, status } = req.body || {};
  if (!phone || !status) return res.status(400).json({ error: "phone and status required" });
  const allowed = ["Pending", "Under Review", "Verified", "Rejected"];
  if (!allowed.includes(status)) return res.status(400).json({ error: "invalid status" });

  const db = loadDb();
  if (!db.users[phone]) return res.status(404).json({ error: "user not found" });

  db.users[phone].status = status;
  db.users[phone].logs.push({ at: new Date().toISOString(), event: "STATUS_UPDATE", to: status });
  saveDb(db);

  res.json({ message: "status updated", user: db.users[phone] });
});

const PORT = 5000;
app.listen(PORT, () => console.log(`✅ KYC backend running at http://localhost:${PORT}`));
