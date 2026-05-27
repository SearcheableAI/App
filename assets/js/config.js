// ============================================================
// SUPABASE CONFIGURATION
// Replace these values with your actual Supabase project details
// Found in: Supabase Dashboard → Settings → API
// ============================================================

const SUPABASE_URL = 'sb_publishable_LGNarenY_aJL7TNun2-OLw_NFYtKe41';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0Y29zbG1lZGduaW12eWVhZ2twIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NTIwMjYsImV4cCI6MjA5NTQyODAyNn0.3mnQWNyOX3uAGn5e_-IbFgKOqvbIiqFCeflISZRJ2p4';

// Initialize Supabase client
const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============================================================
// APP CONSTANTS
// ============================================================

const APP_NAME = 'AIScope';
const APP_TAGLINE = 'The AI Solutions Directory';

const SOLUTION_CATEGORIES = [
  { name: 'Lead Generation',      slug: 'lead-generation',    icon: '🎯', description: 'AI-powered prospecting & sales' },
  { name: 'Voice Agents',         slug: 'voice-agents',       icon: '📞', description: 'AI receptionists & phone automation' },
  { name: 'Customer Support',     slug: 'customer-support',   icon: '💬', description: 'Chatbots & helpdesk automation' },
  { name: 'CRM Automation',       slug: 'crm-automation',     icon: '🔄', description: 'Pipeline & data automation' },
  { name: 'Appointment Booking',  slug: 'appointment-booking',icon: '📅', description: 'AI scheduling & calendar systems' },
  { name: 'Marketing Automation', slug: 'marketing-automation',icon: '📣', description: 'Content, email & social AI' },
  { name: 'Internal Operations',  slug: 'internal-operations',icon: '⚙️', description: 'Workflow & document automation' },
];

const LISTING_TYPES = {
  agency:     'AI Agency',
  saas:       'AI SaaS',
  consulting: 'AI Consulting',
  other:      'AI Company',
};

const TEAM_SIZES = ['1', '2-10', '11-50', '51-200', '201-500', '500+'];

const PRICING_MODELS = [
  { value: 'free',         label: 'Free' },
  { value: 'freemium',     label: 'Freemium' },
  { value: 'subscription', label: 'Subscription' },
  { value: 'project-based',label: 'Project-Based' },
  { value: 'retainer',     label: 'Retainer' },
  { value: 'custom',       label: 'Custom Pricing' },
  { value: 'contact',      label: 'Contact for Pricing' },
];
