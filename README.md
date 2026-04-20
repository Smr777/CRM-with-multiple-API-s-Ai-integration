# ART CRM Local Setup

This repo runs the frontend and backend together through a single Express + Vite development server.

## Prerequisites

- Node.js 20 or newer
- npm
- A Supabase project for auth/data
- A Gemini API key if you want AI feedback analysis
- A Gmail app password if you want invite and bulk email features

## Initialize The Project

1. Install dependencies:
   `npm install`
2. Create a local env file:
   `Copy-Item .env.example .env.local`
3. Fill in `.env.local` with your real values:
   - `GEMINI_API_KEY`
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `GMAIL_USER` and `GMAIL_APP_PASSWORD` if you want email features
   - `VITE_APP_URL=http://localhost:3000` for local development
4. Start the app:
   `npm run dev`
5. Open:
   `http://localhost:3000`

## Database Setup
Used SupaBase For scalable Database and high bandwith client usage and load which is routing through api channels connecting the backend and frontend as one complete future proof business solution.

If your Supabase project is empty, run [`supabase_schema.sql`](./supabase_schema.sql) in the Supabase SQL editor before signing in.

## Notes

- The Express server listens on port `3000`.
- In development, Vite is mounted inside the Express server, so you do not need a separate frontend command.
- Email endpoints will return an error until Gmail credentials are configured.
