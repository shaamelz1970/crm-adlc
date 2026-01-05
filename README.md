# CRM-ADLC

A multi-tenant CRM system for managing BDM (Business Development Manager) leads with ADLC (Artifact-Driven Lifecycle) methodology and MEDPICC qualification framework.

## Features

- **Multi-tenant architecture** with Row-Level Security (RLS) in Supabase
- **MEDPICC qualification framework** for opportunity scoring
- **ADLC methodology** with stage-gated artifact management
- **FastAPI backend** with server-side rendered Jinja2 templates
- **Role-based access control**: Admin, BDM, Reviewer, Student

## Tech Stack

- **Backend**: Python 3.9+ with FastAPI
- **Database**: Supabase (PostgreSQL with RLS)
- **Templates**: Jinja2
- **Frontend**: Server-rendered HTML with minimal JavaScript

## Quick Start

### Prerequisites

- Python 3.9 or higher
- A Supabase project (free tier works)
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/shaamelz1970/crm-adlc.git
cd crm-adlc
```

### 2. Set Up Python Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Note your project reference (URL) and API keys from Project Settings > API
3. Copy `.env.example` to `.env` and update with your Supabase credentials:

```bash
cp .env.example .env
# Edit .env with your actual Supabase credentials
```

### 4. Run Database Migrations

In your Supabase project dashboard:

1. Go to **SQL Editor** (left sidebar)
2. Create a new query
3. Run the migrations in this order:

   a. **Base Schema**: Copy and execute `db/migrations/supabase-schema.sql`
   
   b. **RLS Policies**: Copy and execute `db/migrations/rls-policies.sql`
   
   c. **MEDPICC Scoring**: Copy and execute `db/migrations/medpicc-schema-updates.sql`

4. Verify tables are created under **Database** > **Tables**

### 5. Run the Application

```bash
# Start the FastAPI development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The application will be available at: http://localhost:8000

### 6. Access the Dashboard

- **Dashboard**: http://localhost:8000/
- **Opportunity Detail**: http://localhost:8000/opportunity/{opportunity_id}

## Project Structure

```
crm-adlc/
├── app/
│   └── main.py                 # FastAPI application with routes
├── db/
│   └── migrations/
│       ├── supabase-schema.sql        # Base multi-tenant schema
│       ├── rls-policies.sql           # Row-Level Security policies
│       └── medpicc-schema-updates.sql # MEDPICC scoring schema
├── docs/
│   ├── adlc-artifact-templates.md     # Artifact templates
│   └── crm-stage-mapping.md           # Stage gating rules
├── static/                     # Static assets (CSS, JS, images)
├── templates/
│   ├── dashboard.html          # Opportunities listing
│   └── opportunity.html        # Opportunity detail page
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
└── requirements.txt            # Python dependencies
```

## Database Schema

The multi-tenant schema includes:

- **tenants**: Organization/tenant management
- **users**: User accounts with tenant association
- **companies**: Customer companies
- **contacts**: Contact persons at companies
- **opportunities**: Sales opportunities with MEDPICC scoring
- **artifacts**: ADLC artifacts (specs, plans, etc.)
- **tasks**: Task management
- **triggers**: Automated workflow triggers
- **medpicc_scores_history**: Historical MEDPICC score snapshots

## MEDPICC Framework

The system implements the MEDPICC qualification methodology:

- **M**etrics: Quantifiable business value
- **E**conomic Buyer: Decision maker with budget authority
- **D**ecision Criteria: Evaluation criteria
- **D**ecision Process: Procurement process
- **I**dentify Pain: Business pain points
- **C**hampion: Internal advocate
- **C**ompetition: Competitive landscape

Each opportunity gets a MEDPICC score (0-100) with historical tracking.

## ADLC Methodology

Opportunities progress through stages with artifact requirements:

1. **Pre-Qualification** → requires Intent Brief
2. **MEDPICC Qualification** → requires MEDPICC completion
3. **Solutioning** → requires MVP Spec, Architecture, UX, Build Plan, Test Plan, Demo Script, Deployment Checklist

See `docs/crm-stage-mapping.md` for detailed gating rules.

## Development

### Running in Development Mode

```bash
# With auto-reload
uvicorn app.main:app --reload --port 8000
```

### Testing Database Queries

Use the Supabase SQL Editor or connect directly with psql:

```bash
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
```

## Roles and Permissions

- **Admin**: Full access to all tenants and data
- **BDM**: Create/edit opportunities, manage artifacts
- **Reviewer**: Review and approve stage transitions
- **Student**: Read-only access for learning

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions, please use the GitHub issue tracker.
