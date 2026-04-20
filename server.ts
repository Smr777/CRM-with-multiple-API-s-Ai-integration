import express from "express";
import { createServer as createViteServer } from "vite";
import path from "path";
import { fileURLToPath } from "url";
import nodemailer from "nodemailer";
import dotenv from "dotenv";
import multer from "multer";
import fs from "fs";
import axios from "axios";

dotenv.config({ path: [".env.local", ".env"] });

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer for file storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ 
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const isPdf = file.mimetype === "application/pdf" || file.mimetype === "application/x-pdf";
    const isImage = file.mimetype.startsWith("image/");
    
    if (isPdf || isImage) {
      cb(null, true);
    } else {
      console.error(`Rejected file upload: ${file.originalname}, mimetype: ${file.mimetype}`);
      cb(new Error("Only PDFs and images are allowed"));
    }
  }
});

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());
  
  // Serve uploads statically
  app.use("/uploads", express.static(uploadsDir));

  // API routes
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok" });
  });

  app.get("/api/debug-env", (req, res) => {
    res.json({ 
      VITE_APP_URL: process.env.VITE_APP_URL || "Not Set",
      NODE_ENV: process.env.NODE_ENV
    });
  });

  app.post("/api/upload", upload.single("file"), (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const fileUrl = `/uploads/${req.file.filename}`;
    res.json({ url: fileUrl });
  });

  app.post("/api/send-invite", async (req, res) => {
    const { name, email, clientType, origin } = req.body;

    if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
      return res.status(500).json({ 
        error: "Email configuration missing. Please set GMAIL_USER and GMAIL_APP_PASSWORD in environment variables." 
      });
    }

    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });

    const protocol = req.headers["x-forwarded-proto"] || "http";
    const host = req.headers["x-forwarded-host"] || req.get("host");
    
    // Try to get the base URL from referer if host is aistudio.google.com
    let detectedUrl = `${protocol}://${host}`;
    if (host?.includes('aistudio.google.com') && req.headers.referer) {
      const refererUrl = new URL(req.headers.referer);
      detectedUrl = `${refererUrl.protocol}//${refererUrl.host}`;
    }

    const appUrl = process.env.VITE_APP_URL || origin || detectedUrl;
    console.log(`[Invite] Using App URL: ${appUrl} (Origin: ${origin}, Detected: ${detectedUrl}, Env: ${process.env.VITE_APP_URL})`);

    const mailOptions = {
      from: `"ART Consulting" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: `Invitation to join ART Consulting - ${name}`,
      html: `
        <div style="font-family: serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e5e5; border-radius: 8px;">
          <h1 style="color: #1a1a1a; border-bottom: 1px solid #f0f0f0; padding-bottom: 10px;">ART Consulting</h1>
          <p style="font-size: 16px; color: #444;">Dear ${name},</p>
          <p style="font-size: 16px; color: #444;">
            You have been invited to join <strong>ART Consulting</strong> as a <strong>${clientType}</strong> client.
          </p>
          <p style="font-size: 16px; color: #444;">
            Our platform provides premium client oversight and strategic management services tailored to your needs.
          </p>
          <div style="margin: 30px 0; text-align: center;">
            <a href="${appUrl}/login?invite=${encodeURIComponent(email)}" 
               style="background-color: #1a1a1a; color: white; padding: 12px 24px; text-decoration: none; border-radius: 50px; font-weight: bold;">
              Accept Invitation
            </a>
          </div>
          <p style="font-size: 14px; color: #888; margin-top: 40px; border-top: 1px solid #f0f0f0; padding-top: 20px;">
            Best regards,<br>
            The ART Consulting Team
          </p>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      res.json({ success: true, message: "Email sent successfully" });
    } catch (error) {
      console.error("Error sending email:", error);
      res.status(500).json({ error: "Failed to send email" });
    }
  });

  app.post("/api/bulk-email", async (req, res) => {
    const { recipients, subject, body } = req.body;

    if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
      return res.status(500).json({ 
        error: "Email configuration missing." 
      });
    }

    if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({ error: "No recipients provided" });
    }

    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });

    const mailOptions = {
      from: `"ART Consulting" <${process.env.GMAIL_USER}>`,
      bcc: recipients.join(","), // Use BCC for bulk emails
      subject: subject,
      html: `
        <div style="font-family: serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e5e5; border-radius: 8px;">
          <h1 style="color: #1a1a1a; border-bottom: 1px solid #f0f0f0; padding-bottom: 10px;">ART Consulting</h1>
          <div style="font-size: 16px; color: #444; line-height: 1.6;">
            ${body.replace(/\n/g, "<br>")}
          </div>
          <p style="font-size: 14px; color: #888; margin-top: 40px; border-top: 1px solid #f0f0f0; padding-top: 20px;">
            Best regards,<br>
            The ART Consulting Team
          </p>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      res.json({ success: true, message: `Email sent to ${recipients.length} recipients` });
    } catch (error) {
      console.error("Error sending bulk email:", error);
      res.status(500).json({ error: "Failed to send bulk email" });
    }
  });

  app.get("/api/proxy-download", async (req, res) => {
    const { url, filename } = req.query;

    if (!url || typeof url !== "string") {
      return res.status(400).json({ error: "URL is required" });
    }

    try {
      // Check if it's a local file path
      if (url.includes("/uploads/")) {
        const fileName = url.split("/uploads/")[1];
        const filePath = path.join(uploadsDir, fileName);
        
        if (fs.existsSync(filePath)) {
          res.setHeader("Content-Disposition", `attachment; filename="${filename || fileName}"`);
          // Determine content type based on extension
          const ext = path.extname(fileName).toLowerCase();
          const mimeTypes: Record<string, string> = {
            '.pdf': 'application/pdf',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.webp': 'image/webp'
          };
          res.setHeader("Content-Type", mimeTypes[ext] || "application/octet-stream");
          return fs.createReadStream(filePath).pipe(res);
        }
      }

      // Otherwise fetch from external URL
      const response = await axios({
        method: "get",
        url: url,
        responseType: "stream",
        timeout: 10000,
      });

      res.setHeader("Content-Disposition", `attachment; filename="${filename || "download.pdf"}"`);
      res.setHeader("Content-Type", response.headers["content-type"] || "application/octet-stream");
      response.data.pipe(res);
    } catch (error) {
      console.error("Proxy download failed:", error);
      // If it fails, don't return JSON (which gets saved as PDF), return a proper error status
      res.status(500).end();
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
