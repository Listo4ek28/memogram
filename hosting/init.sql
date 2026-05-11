-- MySQL dump 10.13
-- ------------------------------------------------------

-- Таблица пользователей (НЕ МЕНЯЕТСЯ)
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `display_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `avatar` longtext,
  `bio` text,
  `memes_viewed` int DEFAULT 0,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
);

-- Таблица сообществ
CREATE TABLE IF NOT EXISTS `communities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text,
  `avatar` longtext,
  `created_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `communities_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

-- ============================================================
-- ТАБЛИЦА МЕМОВ (посты в ленте/сообществах)
-- meme_image теперь хранит путь к файлу (varchar 255)
-- ============================================================
CREATE TABLE IF NOT EXISTS `memes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `community_id` int DEFAULT NULL,
  `meme_text` text,
  `meme_image` varchar(255) DEFAULT NULL,
  `repost_from` int DEFAULT NULL,
  `reactions` int DEFAULT 0,
  `views_count` int DEFAULT 0,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `community_id` (`community_id`),
  KEY `repost_from` (`repost_from`),
  CONSTRAINT `memes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `memes_ibfk_2` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `memes_ibfk_3` FOREIGN KEY (`repost_from`) REFERENCES `memes` (`id`) ON DELETE SET NULL
);

-- ============================================================
-- ТАБЛИЦА ЛИЧНЫХ СООБЩЕНИЙ (чат 1-на-1)
-- message_image теперь хранит путь к файлу (varchar 255)
-- ============================================================
CREATE TABLE IF NOT EXISTS `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `message_text` text,
  `message_image` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `from_user_id` (`from_user_id`),
  KEY `to_user_id` (`to_user_id`),
  KEY `idx_chat_users` (`from_user_id`, `to_user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

-- ============================================================
-- ТАБЛИЦА КОММЕНТАРИЕВ (к мемам)
-- ============================================================
CREATE TABLE IF NOT EXISTS `comments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `meme_id` (`meme_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE
);

-- ============================================================
-- ОСТАЛЬНЫЕ ТАБЛИЦЫ
-- ============================================================

-- Таблица обменов (старая, можно оставить для совместимости)
CREATE TABLE IF NOT EXISTS `exchanges` (
  `id` int NOT NULL AUTO_INCREMENT,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `from_meme_id` int NOT NULL,
  `to_meme_id` int NOT NULL,
  `exchanged_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `from_user_id` (`from_user_id`),
  KEY `to_user_id` (`to_user_id`),
  KEY `from_meme_id` (`from_meme_id`),
  KEY `to_meme_id` (`to_meme_id`)
);

-- Таблица подписок на сообщества
CREATE TABLE IF NOT EXISTS `community_subscriptions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `community_id` int NOT NULL,
  `subscribed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_subscription` (`user_id`,`community_id`),
  KEY `user_id` (`user_id`),
  KEY `community_id` (`community_id`),
  CONSTRAINT `community_subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `community_subscriptions_ibfk_2` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE CASCADE
);

-- Таблица друзей
CREATE TABLE IF NOT EXISTS `friends` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `friend_id` int NOT NULL,
  `status` enum('pending','accepted','blocked') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_friendship` (`user_id`,`friend_id`),
  KEY `user_id` (`user_id`),
  KEY `friend_id` (`friend_id`),
  CONSTRAINT `friends_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `friends_ibfk_2` FOREIGN KEY (`friend_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

-- Таблица реакций на мемы
CREATE TABLE IF NOT EXISTS `user_reactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `reaction_type` varchar(20) DEFAULT 'like',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_meme` (`user_id`,`meme_id`),
  KEY `meme_id` (`meme_id`),
  CONSTRAINT `user_reactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_reactions_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE
);

-- Таблица избранного
CREATE TABLE IF NOT EXISTS `favorites` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_favorite` (`user_id`,`meme_id`),
  KEY `meme_id` (`meme_id`),
  CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE
);

-- Таблица жалоб
CREATE TABLE IF NOT EXISTS `reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `meme_id` int NOT NULL,
  `user_id` int NOT NULL,
  `reason` varchar(50) NOT NULL,
  `reported_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `meme_id` (`meme_id`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE
);

-- Таблица истории просмотров
CREATE TABLE IF NOT EXISTS `view_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `viewed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_meme` (`user_id`,`meme_id`),
  KEY `user_id` (`user_id`),
  KEY `meme_id` (`meme_id`),
  CONSTRAINT `view_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `view_history_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE
);

-- ============================================================
-- ИНДЕКСЫ
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS add_index_if_not_exists //

CREATE PROCEDURE add_index_if_not_exists(
    IN tbl_name VARCHAR(64),
    IN idx_name VARCHAR(64),
    IN idx_columns VARCHAR(255)
)
BEGIN
    DECLARE idx_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO idx_exists
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = tbl_name
      AND index_name = idx_name;
    
    IF idx_exists = 0 THEN
        SET @sql = CONCAT('ALTER TABLE ', tbl_name, ' ADD INDEX ', idx_name, ' (', idx_columns, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //

DELIMITER ;

CALL add_index_if_not_exists('memes', 'idx_memes_user', 'user_id');
CALL add_index_if_not_exists('memes', 'idx_memes_created', 'created_at DESC');
CALL add_index_if_not_exists('memes', 'idx_memes_community', 'community_id');
CALL add_index_if_not_exists('messages', 'idx_messages_from', 'from_user_id');
CALL add_index_if_not_exists('messages', 'idx_messages_to', 'to_user_id');
CALL add_index_if_not_exists('messages', 'idx_messages_created', 'created_at DESC');
CALL add_index_if_not_exists('comments', 'idx_comments_meme', 'meme_id');
CALL add_index_if_not_exists('comments', 'idx_comments_user', 'user_id');
CALL add_index_if_not_exists('favorites', 'idx_favorites_user', 'user_id');
CALL add_index_if_not_exists('user_reactions', 'idx_reactions_user', 'user_id');
CALL add_index_if_not_exists('user_reactions', 'idx_reactions_meme', 'meme_id');
CALL add_index_if_not_exists('reports', 'idx_reports_meme', 'meme_id');
CALL add_index_if_not_exists('view_history', 'idx_vh_user', 'user_id');
CALL add_index_if_not_exists('view_history', 'idx_vh_meme', 'meme_id');

DROP PROCEDURE IF EXISTS add_index_if_not_exists;