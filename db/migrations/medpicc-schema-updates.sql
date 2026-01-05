-- MEDPICC Schema Updates
-- Adds MEDPICC qualification fields and scoring functionality
-- Run this migration after supabase-schema.sql

-- ============================================
-- Add MEDPICC fields to opportunities table
-- ============================================
ALTER TABLE crm.opportunities 
ADD COLUMN IF NOT EXISTS metrics TEXT,
ADD COLUMN IF NOT EXISTS economic_buyer VARCHAR(255),
ADD COLUMN IF NOT EXISTS decision_criteria TEXT,
ADD COLUMN IF NOT EXISTS decision_process TEXT,
ADD COLUMN IF NOT EXISTS identify_pain TEXT,
ADD COLUMN IF NOT EXISTS champion VARCHAR(255),
ADD COLUMN IF NOT EXISTS medpicc_score INTEGER DEFAULT 0 CHECK (medpicc_score >= 0 AND medpicc_score <= 100);

-- ============================================
-- MEDPICC Scores History Table
-- ============================================
CREATE TABLE IF NOT EXISTS crm.medpicc_scores_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES crm.tenants(id) ON DELETE CASCADE,
    opportunity_id UUID NOT NULL REFERENCES crm.opportunities(id) ON DELETE CASCADE,
    stage VARCHAR(50) NOT NULL,
    medpicc_score INTEGER NOT NULL,
    metrics TEXT,
    economic_buyer VARCHAR(255),
    decision_criteria TEXT,
    decision_process TEXT,
    identify_pain TEXT,
    champion VARCHAR(255),
    snapshot_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES crm.users(id)
);

CREATE INDEX idx_medpicc_history_tenant ON crm.medpicc_scores_history(tenant_id);
CREATE INDEX idx_medpicc_history_opportunity ON crm.medpicc_scores_history(opportunity_id);
CREATE INDEX idx_medpicc_history_date ON crm.medpicc_scores_history(snapshot_date);

COMMENT ON TABLE crm.medpicc_scores_history IS 'Historical snapshots of MEDPICC scores when stage changes';

-- ============================================
-- Function: Compute MEDPICC Score
-- ============================================
CREATE OR REPLACE FUNCTION crm.compute_medpicc_score(
    p_metrics TEXT,
    p_economic_buyer VARCHAR,
    p_decision_criteria TEXT,
    p_decision_process TEXT,
    p_identify_pain TEXT,
    p_champion VARCHAR
)
RETURNS INTEGER AS $$
DECLARE
    score INTEGER := 0;
    component_weight INTEGER := 16; -- 100 / 6 components ≈ 16-17 points each
BEGIN
    -- Metrics: 17 points
    IF p_metrics IS NOT NULL AND LENGTH(TRIM(p_metrics)) > 0 THEN
        score := score + 17;
    END IF;
    
    -- Economic Buyer: 17 points
    IF p_economic_buyer IS NOT NULL AND LENGTH(TRIM(p_economic_buyer)) > 0 THEN
        score := score + 17;
    END IF;
    
    -- Decision Criteria: 17 points
    IF p_decision_criteria IS NOT NULL AND LENGTH(TRIM(p_decision_criteria)) > 0 THEN
        score := score + 17;
    END IF;
    
    -- Decision Process: 17 points
    IF p_decision_process IS NOT NULL AND LENGTH(TRIM(p_decision_process)) > 0 THEN
        score := score + 17;
    END IF;
    
    -- Identify Pain: 16 points
    IF p_identify_pain IS NOT NULL AND LENGTH(TRIM(p_identify_pain)) > 0 THEN
        score := score + 16;
    END IF;
    
    -- Champion: 16 points
    IF p_champion IS NOT NULL AND LENGTH(TRIM(p_champion)) > 0 THEN
        score := score + 16;
    END IF;
    
    RETURN score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION crm.compute_medpicc_score IS 'Computes MEDPICC score (0-100) based on completion of six components';

-- ============================================
-- Trigger: Update MEDPICC score on opportunity changes
-- ============================================
CREATE OR REPLACE FUNCTION crm.update_medpicc_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.medpicc_score := crm.compute_medpicc_score(
        NEW.metrics,
        NEW.economic_buyer,
        NEW.decision_criteria,
        NEW.decision_process,
        NEW.identify_pain,
        NEW.champion
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS opportunities_update_medpicc_score ON crm.opportunities;
CREATE TRIGGER opportunities_update_medpicc_score
    BEFORE INSERT OR UPDATE OF metrics, economic_buyer, decision_criteria, decision_process, identify_pain, champion
    ON crm.opportunities
    FOR EACH ROW
    EXECUTE FUNCTION crm.update_medpicc_score();

-- ============================================
-- Trigger: Snapshot MEDPICC scores on stage advancement
-- ============================================
CREATE OR REPLACE FUNCTION crm.snapshot_medpicc_on_stage_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only snapshot when stage actually changes
    IF (TG_OP = 'UPDATE' AND OLD.stage IS DISTINCT FROM NEW.stage) THEN
        INSERT INTO crm.medpicc_scores_history (
            tenant_id,
            opportunity_id,
            stage,
            medpicc_score,
            metrics,
            economic_buyer,
            decision_criteria,
            decision_process,
            identify_pain,
            champion,
            snapshot_date,
            created_by
        ) VALUES (
            NEW.tenant_id,
            NEW.id,
            NEW.stage,
            NEW.medpicc_score,
            NEW.metrics,
            NEW.economic_buyer,
            NEW.decision_criteria,
            NEW.decision_process,
            NEW.identify_pain,
            NEW.champion,
            NOW(),
            NEW.updated_at -- Using updated_at as proxy for who made the change
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS opportunities_snapshot_medpicc ON crm.opportunities;
CREATE TRIGGER opportunities_snapshot_medpicc
    AFTER INSERT OR UPDATE OF stage
    ON crm.opportunities
    FOR EACH ROW
    EXECUTE FUNCTION crm.snapshot_medpicc_on_stage_change();

COMMENT ON FUNCTION crm.update_medpicc_score IS 'Automatically updates medpicc_score when MEDPICC fields change';
COMMENT ON FUNCTION crm.snapshot_medpicc_on_stage_change IS 'Creates historical snapshot when opportunity stage advances';
