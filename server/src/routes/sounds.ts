import { Hono } from "hono";
import { storage } from "edgespark";
import { sounds as soundsBucket } from "../defs/storage_schema";

const sounds = new Hono();

// Serve the notification sound from EdgeSpark storage
sounds.get("/notification.mp3", async (c) => {
  try {
    const file = await storage.from(soundsBucket).get("notification.mp3");
    if (file) {
      c.header("Content-Type", "audio/mpeg");
      c.header("Cache-Control", "public, max-age=86400");
      c.header("Access-Control-Allow-Origin", "*");
      return c.body(file.body);
    }
  } catch(e) {}
  
  return c.json({ error: "Sound not available" }, 404);
});

// Upload the notification sound (called once)
sounds.post("/upload", async (c) => {
  try {
    const body = await c.req.json();
    const { base64 } = body;
    if (!base64) return c.json({ error: "No base64 data" }, 400);
    
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    
    await storage.from(soundsBucket).put("notification.mp3", bytes.buffer, { 
      contentType: "audio/mpeg",
      cacheControl: "public, max-age=86400"
    });
    
    return c.json({ ok: true, size: bytes.length });
  } catch(e: any) {
    return c.json({ error: e.message }, 500);
  }
});

export default sounds;
