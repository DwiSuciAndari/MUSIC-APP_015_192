import 'dotenv/config';
import express from 'express';
import { GoogleGenAI } from '@google/genai';

const app = express();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY
});

app.use(express.json());

app.post('/api/chat', async (req, res) => {
  const userMsg = req.body.message;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: userMsg, 
    });

    const text =
      response.text ||
      response.candidates?.[0]?.content?.parts?.[0]?.text;

    res.json({
      result: text || "Coba tanya lagi ya 😅"
    });

  } catch (error) {
    console.log("ERROR:", error.message);

    if (error.message.includes("503")) {
      return res.json({
        result: "AI lagi rame 😭 coba lagi bentar ya"
      });
    }

    res.json({
      result: `AI error: ${error.message}`
    });
  }
});
app.listen(3000, '0.0.0.0', () => {
  console.log("Server running at http://172.20.10.2:3000/api/chat");
});