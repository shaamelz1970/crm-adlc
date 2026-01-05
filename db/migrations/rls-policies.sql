-- Row-Level Security (RLS) Policies
-- Multi-tenant security policies and role-based access control
-- Run this migration after medpicc-schema-updates.sql

-- Enable Row Level Security on all tables
ALTER TABLE crm.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.artifact_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.medpicc_scores_history ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Helper Functions for RLS
-- ============================================

-- Function to get current user's role
CREATE OR REPLACE FUNCTION crm.get_user_role(p_user_id UUID, p_tenant_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    user_role VARCHAR;
BEGIN
    SELECT role INTO user_role
    FROM crm.users
    WHERE id = p_user_id AND tenant_id = p_tenant_id AND active = TRUE;
    
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION crm.get_user_role IS 'Returns the role of a user within a specific tenant';

-- Function to check if user belongs to tenant
CREATE OR REPLACE FUNCTION crm.user_in_tenant(p_user_id UUID, p_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM crm.users 
        WHERE id = p_user_id 
          AND tenant_id = p_tenant_id 
          AND active = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION crm.user_in_tenant IS 'Checks if a user belongs to a specific tenant';

-- ============================================
-- RLS Policies for TENANTS
-- ============================================

-- Users can only see their own tenant
CREATE POLICY tenants_select_policy ON crm.tenants
    FOR SELECT
    USING (
        id IN (
            SELECT tenant_id FROM crm.users WHERE id = auth.uid()
        )
    );

-- Only admins can insert/update/delete tenants
CREATE POLICY tenants_modify_policy ON crm.tenants
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM crm.users 
            WHERE id = auth.uid() 
              AND tenant_id = crm.tenants.id 
              AND role = 'admin'
        )
    );

-- ============================================
-- RLS Policies for USERS
-- ============================================

-- Users can see other users in their tenant
CREATE POLICY users_select_policy ON crm.users
    FOR SELECT
    USING (
        tenant_id IN (
            SELECT tenant_id FROM crm.users WHERE id = auth.uid()
        )
    );

-- Only admins can manage users
CREATE POLICY users_modify_policy ON crm.users
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM crm.users u
            WHERE u.id = auth.uid() 
              AND u.tenant_id = crm.users.tenant_id 
              AND u.role = 'admin'
        )
    );

-- ============================================
-- RLS Policies for COMPANIES
-- ============================================

-- All authenticated users in tenant can view companies
CREATE POLICY companies_select_policy ON crm.companies
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- BDMs and admins can insert companies
CREATE POLICY companies_insert_policy ON crm.companies
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- BDMs and admins can update companies
CREATE POLICY companies_update_policy ON crm.companies
    FOR UPDATE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Only admins can delete companies
CREATE POLICY companies_delete_policy ON crm.companies
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for CONTACTS
-- ============================================

-- All authenticated users in tenant can view contacts
CREATE POLICY contacts_select_policy ON crm.contacts
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- BDMs and admins can insert contacts
CREATE POLICY contacts_insert_policy ON crm.contacts
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- BDMs and admins can update contacts
CREATE POLICY contacts_update_policy ON crm.contacts
    FOR UPDATE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Only admins can delete contacts
CREATE POLICY contacts_delete_policy ON crm.contacts
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for OPPORTUNITIES
-- ============================================

-- All authenticated users in tenant can view opportunities
CREATE POLICY opportunities_select_policy ON crm.opportunities
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- BDMs and admins can insert opportunities
CREATE POLICY opportunities_insert_policy ON crm.opportunities
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Opportunity owners, BDMs, and admins can update opportunities
CREATE POLICY opportunities_update_policy ON crm.opportunities
    FOR UPDATE
    USING (
        owner_id = auth.uid() OR
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Only admins can delete opportunities
CREATE POLICY opportunities_delete_policy ON crm.opportunities
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for ARTIFACTS
-- ============================================

-- All authenticated users in tenant can view artifacts
CREATE POLICY artifacts_select_policy ON crm.artifacts
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- BDMs and opportunity owners can insert artifacts
CREATE POLICY artifacts_insert_policy ON crm.artifacts
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm') OR
        EXISTS (
            SELECT 1 FROM crm.opportunities 
            WHERE id = opportunity_id AND owner_id = auth.uid()
        )
    );

-- Artifact creators, reviewers, and admins can update artifacts
CREATE POLICY artifacts_update_policy ON crm.artifacts
    FOR UPDATE
    USING (
        created_by = auth.uid() OR
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'reviewer')
    );

-- Only admins and artifact creators can delete artifacts
CREATE POLICY artifacts_delete_policy ON crm.artifacts
    FOR DELETE
    USING (
        created_by = auth.uid() OR
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for ARTIFACT_REVIEWS
-- ============================================

-- All authenticated users in tenant can view reviews
CREATE POLICY artifact_reviews_select_policy ON crm.artifact_reviews
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- Reviewers and admins can insert reviews
CREATE POLICY artifact_reviews_insert_policy ON crm.artifact_reviews
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'reviewer')
    );

-- Review creators and admins can update reviews
CREATE POLICY artifact_reviews_update_policy ON crm.artifact_reviews
    FOR UPDATE
    USING (
        reviewer_id = auth.uid() OR
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- Only admins can delete reviews
CREATE POLICY artifact_reviews_delete_policy ON crm.artifact_reviews
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for TASKS
-- ============================================

-- All authenticated users in tenant can view tasks
CREATE POLICY tasks_select_policy ON crm.tasks
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- BDMs and admins can insert tasks
CREATE POLICY tasks_insert_policy ON crm.tasks
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Task assignees and admins can update tasks
CREATE POLICY tasks_update_policy ON crm.tasks
    FOR UPDATE
    USING (
        assigned_to = auth.uid() OR
        crm.get_user_role(auth.uid(), tenant_id) IN ('admin', 'bdm')
    );

-- Only admins can delete tasks
CREATE POLICY tasks_delete_policy ON crm.tasks
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- RLS Policies for MEDPICC_SCORES_HISTORY
-- ============================================

-- All authenticated users in tenant can view history
CREATE POLICY medpicc_history_select_policy ON crm.medpicc_scores_history
    FOR SELECT
    USING (
        crm.user_in_tenant(auth.uid(), tenant_id)
    );

-- History is only inserted by triggers, but allow admins to insert manually if needed
CREATE POLICY medpicc_history_insert_policy ON crm.medpicc_scores_history
    FOR INSERT
    WITH CHECK (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- Only admins can delete history
CREATE POLICY medpicc_history_delete_policy ON crm.medpicc_scores_history
    FOR DELETE
    USING (
        crm.get_user_role(auth.uid(), tenant_id) = 'admin'
    );

-- ============================================
-- GRANTS
-- ============================================

-- Grant usage on schema to authenticated users
GRANT USAGE ON SCHEMA crm TO authenticated;

-- Grant SELECT on all tables to authenticated users (RLS will restrict)
GRANT SELECT ON ALL TABLES IN SCHEMA crm TO authenticated;

-- Grant INSERT, UPDATE, DELETE on all tables to authenticated users (RLS will restrict)
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA crm TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION crm.get_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION crm.user_in_tenant TO authenticated;
GRANT EXECUTE ON FUNCTION crm.compute_medpicc_score TO authenticated;

COMMENT ON SCHEMA crm IS 'Multi-tenant CRM with RLS policies enforcing tenant isolation and role-based access';
