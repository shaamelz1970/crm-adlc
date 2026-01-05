# CRM-ADLC

A multi-tenant CRM system for Business Development Managers (BDM) with integrated Artifact-Driven Lifecycle (ADLC) methodology. This project combines opportunity management with MEDPICC qualification and stage-gated artifact workflows.

## Overview

CRM-ADLC provides:
- **Multi-tenant CRM**: Manage companies, contacts, and opportunities with role-based access
- **MEDPICC Qualification**: Track Metrics, Economic Buyer, Decision Criteria, Decision Process, Identify Pain, and Champion
- **ADLC Integration**: Stage-gated artifact management (Intent Brief, MVP Spec, Architecture, UX Flow, Build Plan, Test Plan, Demo Script, Deployment Checklist)
- **Priority Computation**: Automated priority scoring based on opportunity characteristics
- **Stage Management**: Controlled advancement through pre-qualification → MEDPICC qualification → solutioning

## Architecture

- **Backend**: Python FastAPI with Jinja2 templates
- **Database**: Supabase (PostgreSQL) with Row-Level Security (RLS)
- **Multi-tenancy**: Tenant-based data isolation with role-based access control (admin, bdm, reviewer, student)

## Quick Start

### Prerequisites

- Python 3.9+
- Supabase account and project

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/shaamelz1970/crm-adlc.git
   cd crm-adlc
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**
   
   Copy `.env.example` to `.env` and update with your Supabase credentials:
   ```bash
   cp .env.example .env
   ```
   
   Update the following in `.env`:
   - `SUPABASE_URL`: Your Supabase project URL (format: `https://YOUR-PROJECT-REF.supabase.co`)
   - `SUPABASE_ANON_KEY`: Your Supabase anon/public key
   - `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key (for admin operations)
   - `SECRET_KEY`: Generate a random secret for session management

4. **Run database migrations**
   
   In your Supabase project dashboard:
   - Navigate to SQL Editor
   - Run the migrations in order:
     1. `db/migrations/supabase-schema.sql` - Creates base schema and tables
     2. `db/migrations/medpicc-schema-updates.sql` - Adds MEDPICC scoring
     3. `db/migrations/rls-policies.sql` - Applies row-level security policies

5. **Run the application**
   ```bash
   uvicorn app.main:app --reload
   ```
   
   The application will be available at `http://localhost:8000`

## Project Structure

```
crm-adlc/
├── app/
│   └── main.py                 # FastAPI application with routes
├── db/
│   └── migrations/
│       ├── supabase-schema.sql          # Base schema and tables
│       ├── medpicc-schema-updates.sql   # MEDPICC functionality
│       └── rls-policies.sql             # Row-level security
├── docs/
│   ├── adlc-artifact-templates.md  # ADLC artifact definitions
│   └── crm-stage-mapping.md        # Stage progression rules
├── templates/
│   ├── dashboard.html          # Opportunities dashboard
│   └── opportunity.html        # Opportunity detail view
├── static/                     # Static assets (CSS, JS, images)
├── .env.example               # Environment variables template
├── .gitignore                 # Git ignore rules
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

## Usage

### Dashboard
Access the main dashboard at `http://localhost:8000/` to view all opportunities.

### Opportunity Details
Click on any opportunity to view details including MEDPICC scores and required artifacts.

### Stage Advancement
Use the stage change form on opportunity detail pages to advance opportunities through the workflow. The system enforces gating rules based on required artifacts.

## Multi-tenant Roles

- **admin**: Full access to all tenant data
- **bdm**: Business Development Manager - manage opportunities and contacts
- **reviewer**: Review artifacts and provide feedback
- **student**: Read-only access for training purposes

## Database Schema

The database uses a `crm` schema with the following main tables:
- `tenants`: Organization/tenant definitions
- `users`: User accounts linked to tenants
- `companies`: Customer companies
- `contacts`: Individual contacts
- `opportunities`: Sales opportunities with MEDPICC fields
- `artifacts`: ADLC artifacts attached to opportunities
- `artifact_reviews`: Reviews and feedback on artifacts
- `tasks`: Action items and follow-ups
- `medpicc_scores_history`: Historical MEDPICC score snapshots

## Documentation

- [ADLC Artifact Templates](docs/adlc-artifact-templates.md) - Detailed artifact templates for each stage
- [CRM Stage Mapping](docs/crm-stage-mapping.md) - Stage progression and gating rules

## Development

Run in development mode with auto-reload:
```bash
uvicorn app.main:app --reload --port 8000
```

## License

MIT License

## Support

For issues and questions, please open an issue on GitHub.
