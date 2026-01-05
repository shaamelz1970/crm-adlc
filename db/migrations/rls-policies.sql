-- =====================================================
-- CRM-ADLC Row-Level Security (RLS) Policies
-- Multi-Tenant Security with Role-Based Access Control
-- =====================================================

-- =====================================================
-- HELPER FUNCTIONS FOR RLS
-- =====================================================

-- Function to get current user's tenant_id
CREATE OR REPLACE FUNCTION crm.current_user_tenant_id()
RETURNS UUID AS $$
DECLARE
    tenant_uuid UUID;
BEGIN
    -- Get tenant_id from the user's JWT claims or from crm.users table
    -- For development, we'll use a query based on auth.uid()
    SELECT tenant_id INTO tenant_uuid
    FROM crm.users
    WHERE auth_user_id = auth.uid()
    LIMIT 1;
    
    RETURN tenant_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user has a specific role
CREATE OR REPLACE FUNCTION crm.current_user_has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM crm.users
    WHERE auth_user_id = auth.uid()
    LIMIT 1;
    
    RETURN user_role = required_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is admin
CREATE OR REPLACE FUNCTION crm.current_user_is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crm.current_user_has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is BDM
CREATE OR REPLACE FUNCTION crm.current_user_is_bdm()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crm.current_user_has_role('bdm');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is reviewer
CREATE OR REPLACE FUNCTION crm.current_user_is_reviewer()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crm.current_user_has_role('reviewer');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is student
CREATE OR REPLACE FUNCTION crm.current_user_is_student()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crm.current_user_has_role('student');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current user's ID
CREATE OR REPLACE FUNCTION crm.current_user_id()
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    SELECT id INTO user_uuid
    FROM crm.users
    WHERE auth_user_id = auth.uid()
    LIMIT 1;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can write (admin, bdm, or reviewer)
CREATE OR REPLACE FUNCTION crm.current_user_can_write()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crm.current_user_is_admin() 
        OR crm.current_user_is_bdm() 
        OR crm.current_user_is_reviewer();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE crm.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm.audit_log ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- TENANTS POLICIES
-- =====================================================

-- Admin can see all tenants
CREATE POLICY tenants_admin_all ON crm.tenants
    FOR ALL
    TO authenticated
    USING (crm.current_user_is_admin());

-- Users can see their own tenant
CREATE POLICY tenants_user_select ON crm.tenants
    FOR SELECT
    TO authenticated
    USING (id = crm.current_user_tenant_id());

-- =====================================================
-- USERS POLICIES
-- =====================================================

-- Admin can manage all users in their tenant
CREATE POLICY users_admin_all ON crm.users
    FOR ALL
    TO authenticated
    USING (
        crm.current_user_is_admin() 
        AND tenant_id = crm.current_user_tenant_id()
    );

-- Users can view other users in their tenant
CREATE POLICY users_tenant_select ON crm.users
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

-- Users can update their own profile
CREATE POLICY users_self_update ON crm.users
    FOR UPDATE
    TO authenticated
    USING (id = crm.current_user_id())
    WITH CHECK (id = crm.current_user_id());

-- =====================================================
-- COMPANIES POLICIES
-- =====================================================

-- Users can view companies in their tenant
CREATE POLICY companies_tenant_select ON crm.companies
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

-- Writers (admin/bdm/reviewer) can insert companies
CREATE POLICY companies_writer_insert ON crm.companies
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

-- Writers can update companies
CREATE POLICY companies_writer_update ON crm.companies
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

-- Only admin can delete companies
CREATE POLICY companies_admin_delete ON crm.companies
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- CONTACTS POLICIES
-- =====================================================

CREATE POLICY contacts_tenant_select ON crm.contacts
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

CREATE POLICY contacts_writer_insert ON crm.contacts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

CREATE POLICY contacts_writer_update ON crm.contacts
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

CREATE POLICY contacts_admin_delete ON crm.contacts
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- OPPORTUNITIES POLICIES
-- =====================================================

CREATE POLICY opportunities_tenant_select ON crm.opportunities
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

CREATE POLICY opportunities_writer_insert ON crm.opportunities
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

-- BDMs and reviewers can update opportunities they own or are assigned to
-- Admins can update any opportunity in their tenant
CREATE POLICY opportunities_writer_update ON crm.opportunities
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND (
            crm.current_user_is_admin()
            OR (crm.current_user_can_write() AND owner_id = crm.current_user_id())
        )
    );

CREATE POLICY opportunities_admin_delete ON crm.opportunities
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- ARTIFACTS POLICIES
-- =====================================================

CREATE POLICY artifacts_tenant_select ON crm.artifacts
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

CREATE POLICY artifacts_writer_insert ON crm.artifacts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

-- BDMs can update their own artifacts, reviewers can update any for review
CREATE POLICY artifacts_writer_update ON crm.artifacts
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND (
            crm.current_user_is_admin()
            OR crm.current_user_is_reviewer()
            OR (crm.current_user_is_bdm() AND created_by = crm.current_user_id())
        )
    );

CREATE POLICY artifacts_admin_delete ON crm.artifacts
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- TASKS POLICIES
-- =====================================================

CREATE POLICY tasks_tenant_select ON crm.tasks
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

CREATE POLICY tasks_writer_insert ON crm.tasks
    FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_can_write()
    );

-- Users can update tasks assigned to them, admins can update any
CREATE POLICY tasks_assignee_update ON crm.tasks
    FOR UPDATE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND (
            crm.current_user_is_admin()
            OR assigned_to = crm.current_user_id()
        )
    );

CREATE POLICY tasks_admin_delete ON crm.tasks
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- TRIGGERS POLICIES
-- =====================================================

CREATE POLICY triggers_tenant_select ON crm.triggers
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

-- Only admins can manage triggers
CREATE POLICY triggers_admin_all ON crm.triggers
    FOR ALL
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- AUDIT LOG POLICIES
-- =====================================================

-- Everyone can view audit logs in their tenant
CREATE POLICY audit_log_tenant_select ON crm.audit_log
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

-- System can insert audit logs (via service role or triggers)
CREATE POLICY audit_log_system_insert ON crm.audit_log
    FOR INSERT
    TO authenticated
    WITH CHECK (tenant_id = crm.current_user_tenant_id());

-- Only admins can delete audit logs
CREATE POLICY audit_log_admin_delete ON crm.audit_log
    FOR DELETE
    TO authenticated
    USING (
        tenant_id = crm.current_user_tenant_id()
        AND crm.current_user_is_admin()
    );

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA crm TO authenticated;
GRANT USAGE ON SCHEMA crm TO anon;

-- Grant permissions on all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA crm TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA crm TO anon;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA crm TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA crm TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA crm TO anon;

COMMENT ON FUNCTION crm.current_user_tenant_id() IS 'Returns the tenant_id of the currently authenticated user';
COMMENT ON FUNCTION crm.current_user_is_admin() IS 'Returns true if the current user has admin role';
COMMENT ON FUNCTION crm.current_user_is_bdm() IS 'Returns true if the current user has BDM role';
COMMENT ON FUNCTION crm.current_user_is_reviewer() IS 'Returns true if the current user has reviewer role';
COMMENT ON FUNCTION crm.current_user_is_student() IS 'Returns true if the current user has student role';
COMMENT ON FUNCTION crm.current_user_can_write() IS 'Returns true if the current user can write (admin, bdm, or reviewer)';
