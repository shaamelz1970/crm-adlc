-- =====================================================
-- MEDPICC Schema Updates
-- MEDPICC Scoring System with Historical Tracking
-- =====================================================

-- =====================================================
-- MEDPICC SCORES HISTORY TABLE
-- =====================================================

CREATE TABLE crm.medpicc_scores_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    
    -- Individual MEDPICC component scores (0-100)
    metrics_score INTEGER CHECK (metrics_score >= 0 AND metrics_score <= 100),
    economic_buyer_score INTEGER CHECK (economic_buyer_score >= 0 AND economic_buyer_score <= 100),
    decision_criteria_score INTEGER CHECK (decision_criteria_score >= 0 AND decision_criteria_score <= 100),
    decision_process_score INTEGER CHECK (decision_process_score >= 0 AND decision_process_score <= 100),
    identify_pain_score INTEGER CHECK (identify_pain_score >= 0 AND identify_pain_score <= 100),
    champion_score INTEGER CHECK (champion_score >= 0 AND champion_score <= 100),
    competition_score INTEGER CHECK (competition_score >= 0 AND competition_score <= 100),
    
    -- Overall MEDPICC score
    overall_score INTEGER CHECK (overall_score >= 0 AND overall_score <= 100),
    
    -- Snapshot metadata
    snapshot_reason VARCHAR(100), -- 'stage_change', 'manual_update', 'periodic_snapshot'
    stage_at_snapshot VARCHAR(50),
    
    created_by UUID REFERENCES crm.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_medpicc_history_tenant_id ON crm.medpicc_scores_history(tenant_id);
CREATE INDEX idx_medpicc_history_opportunity_id ON crm.medpicc_scores_history(opportunity_id);
CREATE INDEX idx_medpicc_history_created_at ON crm.medpicc_scores_history(created_at);

-- Enable RLS on medpicc_scores_history
ALTER TABLE crm.medpicc_scores_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy for medpicc_scores_history
CREATE POLICY medpicc_history_tenant_select ON crm.medpicc_scores_history
    FOR SELECT
    TO authenticated
    USING (tenant_id = crm.current_user_tenant_id());

CREATE POLICY medpicc_history_system_insert ON crm.medpicc_scores_history
    FOR INSERT
    TO authenticated
    WITH CHECK (tenant_id = crm.current_user_tenant_id());

-- =====================================================
-- MEDPICC SCORING FUNCTION
-- =====================================================

-- Function to calculate MEDPICC score for an opportunity
CREATE OR REPLACE FUNCTION crm.calculate_medpicc_score(opp_id UUID)
RETURNS TABLE(
    metrics_score INTEGER,
    economic_buyer_score INTEGER,
    decision_criteria_score INTEGER,
    decision_process_score INTEGER,
    identify_pain_score INTEGER,
    champion_score INTEGER,
    competition_score INTEGER,
    overall_score INTEGER
) AS $$
DECLARE
    opp RECORD;
    m_score INTEGER := 0;
    e_score INTEGER := 0;
    dc_score INTEGER := 0;
    dp_score INTEGER := 0;
    ip_score INTEGER := 0;
    ch_score INTEGER := 0;
    co_score INTEGER := 0;
    total_score INTEGER := 0;
BEGIN
    -- Get opportunity details
    SELECT * INTO opp FROM crm.opportunities WHERE id = opp_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Opportunity not found: %', opp_id;
    END IF;
    
    -- Metrics (M): Check if metrics/value is defined
    IF opp.value IS NOT NULL AND opp.value > 0 THEN
        m_score := COALESCE(opp.metrics_score, 50); -- Use stored score or default
    ELSE
        m_score := 0;
    END IF;
    
    -- Economic Buyer (E): Check if economic buyer is identified
    IF opp.economic_buyer_id IS NOT NULL THEN
        -- Check if the contact is marked as economic buyer
        IF EXISTS (
            SELECT 1 FROM crm.contacts 
            WHERE id = opp.economic_buyer_id 
            AND is_economic_buyer = true
        ) THEN
            e_score := 100;
        ELSE
            e_score := 50;
        END IF;
    ELSE
        e_score := 0;
    END IF;
    
    -- Decision Criteria (D): Check if decision criteria is documented
    IF opp.decision_criteria IS NOT NULL AND LENGTH(TRIM(opp.decision_criteria)) > 20 THEN
        dc_score := 100;
    ELSIF opp.decision_criteria IS NOT NULL AND LENGTH(TRIM(opp.decision_criteria)) > 0 THEN
        dc_score := 50;
    ELSE
        dc_score := 0;
    END IF;
    
    -- Decision Process (D): Check if decision process is documented
    IF opp.decision_process IS NOT NULL AND LENGTH(TRIM(opp.decision_process)) > 20 THEN
        dp_score := 100;
    ELSIF opp.decision_process IS NOT NULL AND LENGTH(TRIM(opp.decision_process)) > 0 THEN
        dp_score := 50;
    ELSE
        dp_score := 0;
    END IF;
    
    -- Identify Pain (I): Check if pain points are documented
    IF opp.identify_pain IS NOT NULL AND LENGTH(TRIM(opp.identify_pain)) > 20 THEN
        ip_score := 100;
    ELSIF opp.identify_pain IS NOT NULL AND LENGTH(TRIM(opp.identify_pain)) > 0 THEN
        ip_score := 50;
    ELSE
        ip_score := 0;
    END IF;
    
    -- Champion (C): Check if champion is identified
    IF opp.champion_id IS NOT NULL THEN
        -- Check if the contact is marked as champion
        IF EXISTS (
            SELECT 1 FROM crm.contacts 
            WHERE id = opp.champion_id 
            AND is_champion = true
        ) THEN
            ch_score := 100;
        ELSE
            ch_score := 50;
        END IF;
    ELSE
        ch_score := 0;
    END IF;
    
    -- Competition (C): Check if competitive landscape is documented
    IF opp.competition IS NOT NULL AND LENGTH(TRIM(opp.competition)) > 20 THEN
        co_score := 100;
    ELSIF opp.competition IS NOT NULL AND LENGTH(TRIM(opp.competition)) > 0 THEN
        co_score := 50;
    ELSE
        co_score := 0;
    END IF;
    
    -- Calculate overall score (average of all components)
    total_score := (m_score + e_score + dc_score + dp_score + ip_score + ch_score + co_score) / 7;
    
    -- Return scores
    RETURN QUERY SELECT m_score, e_score, dc_score, dp_score, ip_score, ch_score, co_score, total_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER TO SNAPSHOT MEDPICC SCORES
-- =====================================================

-- Function to create MEDPICC score snapshot
CREATE OR REPLACE FUNCTION crm.snapshot_medpicc_score()
RETURNS TRIGGER AS $$
DECLARE
    scores RECORD;
BEGIN
    -- Calculate current MEDPICC scores
    SELECT * INTO scores FROM crm.calculate_medpicc_score(NEW.id);
    
    -- Determine snapshot reason
    DECLARE
        reason VARCHAR(100) := 'manual_update';
    BEGIN
        IF TG_OP = 'INSERT' THEN
            reason := 'opportunity_created';
        ELSIF OLD.stage IS DISTINCT FROM NEW.stage THEN
            reason := 'stage_change';
        END IF;
        
        -- Insert snapshot into history
        INSERT INTO crm.medpicc_scores_history (
            tenant_id,
            opportunity_id,
            metrics_score,
            economic_buyer_score,
            decision_criteria_score,
            decision_process_score,
            identify_pain_score,
            champion_score,
            competition_score,
            overall_score,
            snapshot_reason,
            stage_at_snapshot,
            created_by
        ) VALUES (
            NEW.tenant_id,
            NEW.id,
            scores.metrics_score,
            scores.economic_buyer_score,
            scores.decision_criteria_score,
            scores.decision_process_score,
            scores.identify_pain_score,
            scores.champion_score,
            scores.competition_score,
            scores.overall_score,
            reason,
            NEW.stage,
            crm.current_user_id()
        );
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on opportunities table
CREATE TRIGGER snapshot_medpicc_on_opportunity_change
    AFTER INSERT OR UPDATE OF 
        metrics_score, 
        economic_buyer_id, 
        decision_criteria, 
        decision_process, 
        identify_pain, 
        champion_id, 
        competition,
        stage
    ON crm.opportunities
    FOR EACH ROW
    EXECUTE FUNCTION crm.snapshot_medpicc_score();

-- =====================================================
-- VIEW FOR CURRENT MEDPICC SCORES
-- =====================================================

-- View to get the latest MEDPICC score for each opportunity
CREATE OR REPLACE VIEW crm.opportunity_medpicc_scores AS
SELECT DISTINCT ON (opportunity_id)
    opportunity_id,
    metrics_score,
    economic_buyer_score,
    decision_criteria_score,
    decision_process_score,
    identify_pain_score,
    champion_score,
    competition_score,
    overall_score,
    snapshot_reason,
    stage_at_snapshot,
    created_at as score_updated_at
FROM crm.medpicc_scores_history
ORDER BY opportunity_id, created_at DESC;

-- Grant permissions on the view
GRANT SELECT ON crm.opportunity_medpicc_scores TO authenticated;

-- =====================================================
-- HELPER FUNCTION TO GET OPPORTUNITY WITH MEDPICC
-- =====================================================

-- Function to get opportunity details with current MEDPICC scores
CREATE OR REPLACE FUNCTION crm.get_opportunity_with_medpicc(opp_id UUID)
RETURNS TABLE(
    opportunity_id UUID,
    opportunity_name VARCHAR,
    stage VARCHAR,
    value DECIMAL,
    metrics_score INTEGER,
    economic_buyer_score INTEGER,
    decision_criteria_score INTEGER,
    decision_process_score INTEGER,
    identify_pain_score INTEGER,
    champion_score INTEGER,
    competition_score INTEGER,
    overall_score INTEGER,
    last_updated TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.name,
        o.stage,
        o.value,
        s.metrics_score,
        s.economic_buyer_score,
        s.decision_criteria_score,
        s.decision_process_score,
        s.identify_pain_score,
        s.champion_score,
        s.competition_score,
        s.overall_score,
        s.score_updated_at
    FROM crm.opportunities o
    LEFT JOIN crm.opportunity_medpicc_scores s ON s.opportunity_id = o.id
    WHERE o.id = opp_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION crm.calculate_medpicc_score(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION crm.get_opportunity_with_medpicc(UUID) TO authenticated;

COMMENT ON TABLE crm.medpicc_scores_history IS 'Historical snapshots of MEDPICC scores for opportunities';
COMMENT ON FUNCTION crm.calculate_medpicc_score(UUID) IS 'Calculate MEDPICC component and overall scores for an opportunity';
COMMENT ON FUNCTION crm.snapshot_medpicc_score() IS 'Trigger function to automatically snapshot MEDPICC scores on opportunity changes';
COMMENT ON VIEW crm.opportunity_medpicc_scores IS 'View showing the latest MEDPICC scores for each opportunity';
