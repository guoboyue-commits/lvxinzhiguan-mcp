-- ============================================================
-- CaseRun MCP v1: personal token + audit log
-- Execute once on the target lvxinzhiguan database.
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `caserun_mcp_token` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'AI 工具连接',
  `permission_group` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'draft_confirm',
  `tool_permissions` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL COMMENT 'Per MCP tool write permission map: disabled|confirm_draft|auto_write|high_risk_confirm',
  `token_prefix` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'active',
  `last_used_at` datetime(3) NULL DEFAULT NULL,
  `expires_at` datetime(3) NULL DEFAULT NULL,
  `revoked_at` datetime(3) NULL DEFAULT NULL,
  `created_at` datetime(3) NULL DEFAULT NULL,
  `updated_at` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_caserun_mcp_token_hash` (`token_hash`) USING BTREE,
  INDEX `idx_caserun_mcp_token_user_status` (`user_id`, `status`) USING BTREE,
  INDEX `idx_caserun_mcp_token_permission` (`permission_group`) USING BTREE,
  INDEX `idx_caserun_mcp_token_last_used` (`last_used_at`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'CaseRun MCP personal access token' ROW_FORMAT = Dynamic;

CREATE TABLE IF NOT EXISTS `caserun_mcp_audit` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_id` bigint(20) UNSIGNED NULL DEFAULT NULL,
  `auth_source` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'unknown',
  `tool` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `case_id` bigint(20) UNSIGNED NULL DEFAULT NULL,
  `status` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'unknown',
  `error_code` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `pending_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `duration_ms` bigint(20) NOT NULL DEFAULT 0,
  `created_at` datetime(3) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_caserun_mcp_audit_user_time` (`user_id`, `created_at`) USING BTREE,
  INDEX `idx_caserun_mcp_audit_token_time` (`token_id`, `created_at`) USING BTREE,
  INDEX `idx_caserun_mcp_audit_tool_status` (`tool`, `status`) USING BTREE,
  INDEX `idx_caserun_mcp_audit_case` (`case_id`) USING BTREE,
  INDEX `idx_caserun_mcp_audit_pending` (`pending_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'CaseRun MCP audit log' ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
