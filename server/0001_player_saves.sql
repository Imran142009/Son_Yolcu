CREATE TABLE IF NOT EXISTS `son_player_saves` (
  `user_id` int NOT NULL,
  `revision` int unsigned NOT NULL DEFAULT 1,
  `snapshot` longtext CHARACTER SET utf8mb4 NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) CHARACTER SET utf8mb4;
