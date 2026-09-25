import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config({ path: '../.env' }); // Load from root

export const app = express();

app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true,
}));
app.use(express.json());

import { supabase } from './config/supabase';

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Hospitals API
app.get('/api/hospitals', async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('hospitals')
      .select('*')
      .eq('is_active', true)
      .order('name');
      
    if (error) throw error;
    
    res.json({ hospitals: data });
  } catch (err) {
    next(err);
  }
});

// Basic Error Handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err);
  if (err instanceof z.ZodError) {
    return res.status(400).json({ error: 'Validation failed', details: err.errors });
  }
  res.status(500).json({ error: 'Internal server error' });
});
