-- CRM-ADLC Base Schema
-- Multi-tenant CRM with opportunity management
-- Run this migration first in Supabase SQL Editor

-- Create the crm schema
CREATE SCHEMA IF NOT EXISTS crm;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION crm.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TENANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE
);

CREATE TRIGGER tenants_update_timestamp
    BEFORE UPDATE ON crm.tenants
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'bdm', 'reviewer', 'student')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE,
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant ON crm.users(tenant_id);
CREATE INDEX idx_users_email ON crm.users(email);

CREATE TRIGGER users_update_timestamp
    BEFORE UPDATE ON crm.users
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- COMPANIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    size VARCHAR(50),
    website VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_companies_tenant ON crm.companies(tenant_id);

CREATE TRIGGER companies_update_timestamp
    BEFORE UPDATE ON crm.companies
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- CONTACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    company_id UUID REFERENCES crm.companies(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    title VARCHAR(100),
    role VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_contacts_tenant ON crm.contacts(tenant_id);
CREATE INDEX idx_contacts_company ON crm.contacts(company_id);

CREATE TRIGGER contacts_update_timestamp
    BEFORE UPDATE ON crm.contacts
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- OPPORTUNITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES crm.companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    stage VARCHAR(50) NOT NULL CHECK (stage IN ('pre_qualify', 'medpicc_qualification', 'solutioning', 'closed_won', 'closed_lost')),
    value DECIMAL(15, 2),
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    expected_close_date DATE,
    
    -- Pre-qualification fields
    budget_range VARCHAR(50),
    timeline VARCHAR(100),
    decision_maker VARCHAR(255),
    pain_points TEXT,
    initial_interest_level VARCHAR(50),
    
    -- Owner and tracking
    owner_id UUID NOT NULL REFERENCES crm.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_opportunities_tenant ON crm.opportunities(tenant_id);
CREATE INDEX idx_opportunities_company ON crm.opportunities(company_id);
CREATE INDEX idx_opportunities_owner ON crm.opportunities(owner_id);
CREATE INDEX idx_opportunities_stage ON crm.opportunities(stage);

CREATE TRIGGER opportunities_update_timestamp
    BEFORE UPDATE ON crm.opportunities
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- ARTIFACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.artifacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL CHECK (type IN (
        'intent_brief', 'mvp_spec', 'architecture', 'ux_flow', 
        'build_plan', 'test_plan', 'demo_script', 'deployment_checklist'
    )),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_artifacts_tenant ON crm.artifacts(tenant_id);
CREATE INDEX idx_artifacts_opportunity ON crm.artifacts(opportunity_id);
CREATE INDEX idx_artifacts_type ON crm.artifacts(type);
CREATE INDEX idx_artifacts_status ON crm.artifacts(status);

CREATE TRIGGER artifacts_update_timestamp
    BEFORE UPDATE ON crm.artifacts
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- ARTIFACT REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.artifact_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    artifact_id UUID NOT NULL REFERENCES crm.artifacts(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES crm.users(id),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'needs_revision')),
    comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_artifact_reviews_tenant ON crm.artifact_reviews(tenant_id);
CREATE INDEX idx_artifact_reviews_artifact ON crm.artifact_reviews(artifact_id);
CREATE INDEX idx_artifact_reviews_reviewer ON crm.artifact_reviews(reviewer_id);

CREATE TRIGGER artifact_reviews_update_timestamp
    BEFORE UPDATE ON crm.artifact_reviews
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- TASKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS crm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(50) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    due_date DATE,
    assigned_to UUID REFERENCES crm.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_tasks_tenant ON crm.tasks(tenant_id);
CREATE INDEX idx_tasks_opportunity ON crm.tasks(opportunity_id);
CREATE INDEX idx_tasks_assigned_to ON crm.tasks(assigned_to);
CREATE INDEX idx_tasks_status ON crm.tasks(status);

CREATE TRIGGER tasks_update_timestamp
    BEFORE UPDATE ON crm.tasks
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_timestamp();

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON SCHEMA crm IS 'Multi-tenant CRM schema with ADLC integration';
COMMENT ON TABLE crm.tenants IS 'Tenant/organization definitions for multi-tenancy';
COMMENT ON TABLE crm.users IS 'User accounts with role-based access (admin, bdm, reviewer, student)';
COMMENT ON TABLE crm.companies IS 'Customer companies in the CRM';
COMMENT ON TABLE crm.contacts IS 'Individual contacts at companies';
COMMENT ON TABLE crm.opportunities IS 'Sales opportunities with pre-qualification and MEDPICC tracking';
COMMENT ON TABLE crm.artifacts IS 'ADLC artifacts (Intent Brief, MVP Spec, etc.) attached to opportunities';
COMMENT ON TABLE crm.artifact_reviews IS 'Reviews and approvals for artifacts';
COMMENT ON TABLE crm.tasks IS 'Action items and follow-up tasks';
