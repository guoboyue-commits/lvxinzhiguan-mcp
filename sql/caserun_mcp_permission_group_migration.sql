-- ============================================================
-- CaseRun MCP: token permission groups
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
