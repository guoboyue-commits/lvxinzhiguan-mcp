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
