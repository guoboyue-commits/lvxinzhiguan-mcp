-- CaseRun MCP current schema baseline.
--
-- This public, idempotent migration contains only the database objects required
-- by the CaseRun MCP integration. Apply it after the private application base
-- schema is installed. Never put production data or secrets in this file.

-- BEGIN current baseline section: MCP tokens and audit
-- ============================================================
-- CaseRun MCP personal token + audit log
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `caserun_mcp_token` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'AI 工具连接',
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

-- END current baseline section: MCP tokens and audit


-- BEGIN current baseline section: MCP permission groups
-- ============================================================
-- CaseRun MCP: token permission groups + per-tool operation permissions
-- Safe to run more than once on MySQL/MariaDB.
-- ============================================================

SET NAMES utf8mb4;

SET @caserun_mcp_permission_column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'caserun_mcp_token'
    AND COLUMN_NAME = 'permission_group'
);

SET @caserun_mcp_permission_column_sql := IF(
  @caserun_mcp_permission_column_exists = 0,
  'ALTER TABLE `caserun_mcp_token` ADD COLUMN `permission_group` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT ''draft_confirm'' AFTER `name`',
  'SELECT ''caserun_mcp_token.permission_group already exists'''
);

PREPARE caserun_mcp_permission_column_stmt FROM @caserun_mcp_permission_column_sql;
EXECUTE caserun_mcp_permission_column_stmt;
DEALLOCATE PREPARE caserun_mcp_permission_column_stmt;

UPDATE `caserun_mcp_token`
SET `permission_group` = 'draft_confirm'
WHERE `permission_group` IS NULL OR `permission_group` = '';

SET @caserun_mcp_permission_index_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'caserun_mcp_token'
    AND INDEX_NAME = 'idx_caserun_mcp_token_permission'
);

SET @caserun_mcp_permission_index_sql := IF(
  @caserun_mcp_permission_index_exists = 0,
  'CREATE INDEX `idx_caserun_mcp_token_permission` ON `caserun_mcp_token` (`permission_group`)',
  'SELECT ''idx_caserun_mcp_token_permission already exists'''
);

PREPARE caserun_mcp_permission_index_stmt FROM @caserun_mcp_permission_index_sql;
EXECUTE caserun_mcp_permission_index_stmt;
DEALLOCATE PREPARE caserun_mcp_permission_index_stmt;

SET @caserun_mcp_tool_permission_column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'caserun_mcp_token'
    AND COLUMN_NAME = 'tool_permissions'
);

SET @caserun_mcp_tool_permission_column_sql := IF(
  @caserun_mcp_tool_permission_column_exists = 0,
  'ALTER TABLE `caserun_mcp_token` ADD COLUMN `tool_permissions` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL COMMENT ''Per MCP tool write permission map: disabled|confirm_draft|auto_write|high_risk_confirm'' AFTER `permission_group`',
  'SELECT ''caserun_mcp_token.tool_permissions already exists'''
);

PREPARE caserun_mcp_tool_permission_column_stmt FROM @caserun_mcp_tool_permission_column_sql;
EXECUTE caserun_mcp_tool_permission_column_stmt;
DEALLOCATE PREPARE caserun_mcp_tool_permission_column_stmt;

-- END current baseline section: MCP permission groups


-- BEGIN current baseline section: uploaded skills
-- ============================================================
-- CaseRun uploaded skills: lawyer-owned orchestration library
-- Safe to run more than once on MySQL/MariaDB.
-- ============================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `caserun_uploaded_skill` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT '',
  `version` varchar(40) DEFAULT '',
  `source` mediumtext NOT NULL,
  `manifest_json` mediumtext NOT NULL,
  `plan_json` mediumtext NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `last_validated_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_caserun_uploaded_skill_user_status` (`user_id`, `status`),
  KEY `idx_caserun_uploaded_skill_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- END current baseline section: uploaded skills
