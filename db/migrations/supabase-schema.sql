-- =====================================================
-- CRM-ADLC Multi-Tenant Schema
-- Supabase PostgreSQL Schema with Multi-Tenant Support
-- =====================================================

-- Create the crm schema
CREATE SCHEMA IF NOT EXISTS crm;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TENANTS TABLE
-- =====================================================
CREATE TABLE crm.tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE crm.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    auth_user_id UUID, -- References auth.users in Supabase
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'bdm', 'reviewer', 'student')),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant_id ON crm.users(tenant_id);
CREATE INDEX idx_users_auth_user_id ON crm.users(auth_user_id);
CREATE INDEX idx_users_role ON crm.users(role);

-- =====================================================
-- COMPANIES TABLE
-- =====================================================
CREATE TABLE crm.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    size VARCHAR(50),
    website VARCHAR(255),
    description TEXT,
    address JSONB,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES crm.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_companies_tenant_id ON crm.companies(tenant_id);
CREATE INDEX idx_companies_name ON crm.companies(name);

-- =====================================================
-- CONTACTS TABLE
-- =====================================================
CREATE TABLE crm.contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    company_id UUID REFERENCES crm.companies(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    title VARCHAR(100),
    role VARCHAR(100),
    is_economic_buyer BOOLEAN DEFAULT false,
    is_champion BOOLEAN DEFAULT false,
    is_decision_maker BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES crm.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contacts_tenant_id ON crm.contacts(tenant_id);
CREATE INDEX idx_contacts_company_id ON crm.contacts(company_id);
CREATE INDEX idx_contacts_email ON crm.contacts(email);

-- =====================================================
-- OPPORTUNITIES TABLE
-- =====================================================
CREATE TABLE crm.opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    company_id UUID REFERENCES crm.companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    stage VARCHAR(50) NOT NULL DEFAULT 'pre_qualify' 
        CHECK (stage IN ('pre_qualify', 'medpicc_qualification', 'solutioning', 'proposal', 'negotiation', 'closed_won', 'closed_lost')),
    value DECIMAL(15, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    expected_close_date DATE,
    
    -- MEDPICC Fields (to be enhanced in medpicc-schema-updates.sql)
    metrics_score INTEGER CHECK (metrics_score >= 0 AND metrics_score <= 100),
    economic_buyer_id UUID REFERENCES crm.contacts(id),
    decision_criteria TEXT,
    decision_process TEXT,
    identify_pain TEXT,
    champion_id UUID REFERENCES crm.contacts(id),
    competition TEXT,
    
    -- Ownership
    owner_id UUID REFERENCES crm.users(id),
    created_by UUID REFERENCES crm.users(id),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

CREATE INDEX idx_opportunities_tenant_id ON crm.opportunities(tenant_id);
CREATE INDEX idx_opportunities_company_id ON crm.opportunities(company_id);
CREATE INDEX idx_opportunities_stage ON crm.opportunities(stage);
CREATE INDEX idx_opportunities_owner_id ON crm.opportunities(owner_id);
CREATE INDEX idx_opportunities_priority ON crm.opportunities(priority);

-- =====================================================
-- ARTIFACTS TABLE (ADLC)
-- =====================================================
CREATE TABLE crm.artifacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    artifact_type VARCHAR(50) NOT NULL 
        CHECK (artifact_type IN ('intent_brief', 'mvp_spec', 'architecture', 'ux_design', 'build_plan', 'test_plan', 'demo_script', 'deployment_checklist')),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    version INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'approved', 'rejected')),
    
    -- Review tracking
    reviewed_by UUID REFERENCES crm.users(id),
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- Ownership
    created_by UUID REFERENCES crm.users(id),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_artifacts_tenant_id ON crm.artifacts(tenant_id);
CREATE INDEX idx_artifacts_opportunity_id ON crm.artifacts(opportunity_id);
CREATE INDEX idx_artifacts_type ON crm.artifacts(artifact_type);
CREATE INDEX idx_artifacts_status ON crm.artifacts(status);

-- =====================================================
-- TASKS TABLE
-- =====================================================
CREATE TABLE crm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    artifact_id UUID REFERENCES crm.artifacts(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    due_date DATE,
    
    -- Assignment
    assigned_to UUID REFERENCES crm.users(id),
    created_by UUID REFERENCES crm.users(id),
    
    -- Completion tracking
    completed_at TIMESTAMPTZ,
    completed_by UUID REFERENCES crm.users(id),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_tenant_id ON crm.tasks(tenant_id);
CREATE INDEX idx_tasks_opportunity_id ON crm.tasks(opportunity_id);
CREATE INDEX idx_tasks_assigned_to ON crm.tasks(assigned_to);
CREATE INDEX idx_tasks_status ON crm.tasks(status);
CREATE INDEX idx_tasks_due_date ON crm.tasks(due_date);

-- =====================================================
-- TRIGGERS TABLE (Workflow Automation)
-- =====================================================
CREATE TABLE crm.triggers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL 
        CHECK (event_type IN ('stage_change', 'artifact_approved', 'task_completed', 'score_change')),
    conditions JSONB DEFAULT '{}'::jsonb,
    actions JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    
    created_by UUID REFERENCES crm.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_triggers_tenant_id ON crm.triggers(tenant_id);
CREATE INDEX idx_triggers_event_type ON crm.triggers(event_type);
CREATE INDEX idx_triggers_is_active ON crm.triggers(is_active);

-- =====================================================
-- AUDIT LOG TABLE (Optional but recommended)
-- =====================================================
CREATE TABLE crm.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES crm.users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    changes JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_log_tenant_id ON crm.audit_log(tenant_id);
CREATE INDEX idx_audit_log_user_id ON crm.audit_log(user_id);
CREATE INDEX idx_audit_log_entity ON crm.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_created_at ON crm.audit_log(created_at);

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION crm.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON crm.tenants
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON crm.users
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON crm.companies
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON crm.contacts
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_opportunities_updated_at BEFORE UPDATE ON crm.opportunities
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_artifacts_updated_at BEFORE UPDATE ON crm.artifacts
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON crm.tasks
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

CREATE TRIGGER update_triggers_updated_at BEFORE UPDATE ON crm.triggers
    FOR EACH ROW EXECUTE FUNCTION crm.update_updated_at_column();

-- =====================================================
-- SAMPLE DATA (for testing)
-- =====================================================

-- Insert a default tenant
INSERT INTO crm.tenants (id, name, slug) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Default Tenant', 'default')
ON CONFLICT (id) DO NOTHING;

-- Insert sample users
INSERT INTO crm.users (tenant_id, email, full_name, role)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'admin@example.com', 'Admin User', 'admin'),
    ('00000000-0000-0000-0000-000000000001', 'bdm@example.com', 'BDM User', 'bdm'),
    ('00000000-0000-0000-0000-000000000001', 'reviewer@example.com', 'Reviewer User', 'reviewer')
ON CONFLICT (tenant_id, email) DO NOTHING;

-- Insert sample company
INSERT INTO crm.companies (tenant_id, name, industry, size, website)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Acme Corp', 'Technology', 'Enterprise', 'https://acme.example.com'),
    ('00000000-0000-0000-0000-000000000001', 'TechStart Inc', 'Software', 'Mid-Market', 'https://techstart.example.com')
ON CONFLICT DO NOTHING;

COMMENT ON SCHEMA crm IS 'CRM-ADLC multi-tenant schema for opportunity management with MEDPICC and ADLC methodology';
