CREATE TABLE `comments` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `communities` (
  `id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `avatar` longtext,
  `created_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `community_subscriptions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `community_id` int NOT NULL,
  `subscribed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `exchanges` (
  `id` int NOT NULL,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `from_meme_id` int NOT NULL,
  `to_meme_id` int NOT NULL,
  `exchanged_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `favorites` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `follows` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `follow_id` int NOT NULL,
  `status` enum('pending','accepted','blocked') DEFAULT 'accepted',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `friends` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `friend_id` int NOT NULL,
  `status` enum('pending','accepted','blocked') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `memes` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `community_id` int DEFAULT NULL,
  `meme_text` text,
  `meme_image` varchar(255) DEFAULT NULL,
  `repost_from` int DEFAULT NULL,
  `reactions` int DEFAULT '0',
  `views_count` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `messages` (
  `id` int NOT NULL,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `message_text` text,
  `message_image` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `reports_messages` (
  `id` int NOT NULL,
  `message_id` int NOT NULL,
  `reporter_id` int NOT NULL,
  `reason` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `reports_posts` (
  `id` int NOT NULL,
  `post_id` int NOT NULL,
  `reporter_id` int NOT NULL,
  `reason` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `display_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `avatar` longtext,
  `bio` text,
  `memes_viewed` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `banned` tinyint NOT NULL DEFAULT '0',
  `admin` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_reactions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `reaction_type` varchar(20) DEFAULT 'like',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `view_history` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `meme_id` int NOT NULL,
  `viewed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `meme_id` (`meme_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_comments_meme` (`meme_id`),
  ADD KEY `idx_comments_user` (`user_id`);

ALTER TABLE `communities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `created_by` (`created_by`);

ALTER TABLE `community_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_subscription` (`user_id`,`community_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `community_id` (`community_id`);

ALTER TABLE `exchanges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `from_user_id` (`from_user_id`),
  ADD KEY `to_user_id` (`to_user_id`),
  ADD KEY `from_meme_id` (`from_meme_id`),
  ADD KEY `to_meme_id` (`to_meme_id`);

ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_favorite` (`user_id`,`meme_id`),
  ADD KEY `meme_id` (`meme_id`),
  ADD KEY `idx_favorites_user` (`user_id`);

ALTER TABLE `follows`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_follow` (`user_id`,`follow_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `follow_id` (`follow_id`);

ALTER TABLE `friends`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_friendship` (`user_id`,`friend_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `friend_id` (`friend_id`);

ALTER TABLE `memes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `community_id` (`community_id`),
  ADD KEY `repost_from` (`repost_from`),
  ADD KEY `idx_memes_user` (`user_id`),
  ADD KEY `idx_memes_created` (`created_at` DESC),
  ADD KEY `idx_memes_community` (`community_id`);

ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `from_user_id` (`from_user_id`),
  ADD KEY `to_user_id` (`to_user_id`),
  ADD KEY `idx_chat_users` (`from_user_id`,`to_user_id`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_messages_from` (`from_user_id`),
  ADD KEY `idx_messages_to` (`to_user_id`),
  ADD KEY `idx_messages_created` (`created_at` DESC);

ALTER TABLE `reports_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_message_id` (`message_id`),
  ADD KEY `idx_reporter_id` (`reporter_id`),
  ADD KEY `idx_created_at` (`created_at`);

ALTER TABLE `reports_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_post_id` (`post_id`),
  ADD KEY `idx_reporter_id` (`reporter_id`),
  ADD KEY `idx_created_at` (`created_at`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

ALTER TABLE `user_reactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_meme` (`user_id`,`meme_id`),
  ADD KEY `meme_id` (`meme_id`),
  ADD KEY `idx_reactions_user` (`user_id`),
  ADD KEY `idx_reactions_meme` (`meme_id`);

ALTER TABLE `view_history`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_meme` (`user_id`,`meme_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `meme_id` (`meme_id`),
  ADD KEY `idx_vh_user` (`user_id`),
  ADD KEY `idx_vh_meme` (`meme_id`);

ALTER TABLE `comments`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

ALTER TABLE `communities`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

ALTER TABLE `community_subscriptions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

ALTER TABLE `exchanges`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `favorites`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `follows`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

ALTER TABLE `friends`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

ALTER TABLE `memes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

ALTER TABLE `messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

ALTER TABLE `reports_messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

ALTER TABLE `reports_posts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

ALTER TABLE `user_reactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

ALTER TABLE `view_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3577;

--
-- Ограничения внешнего ключа таблицы `comments`
--
ALTER TABLE `comments`
  ADD CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `communities`
--
ALTER TABLE `communities`
  ADD CONSTRAINT `communities_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `community_subscriptions`
--
ALTER TABLE `community_subscriptions`
  ADD CONSTRAINT `community_subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `community_subscriptions_ibfk_2` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `follows`
--
ALTER TABLE `follows`
  ADD CONSTRAINT `follows_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `follows_ibfk_2` FOREIGN KEY (`follow_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `friends`
--
ALTER TABLE `friends`
  ADD CONSTRAINT `friends_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `friends_ibfk_2` FOREIGN KEY (`friend_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `memes`
--
ALTER TABLE `memes`
  ADD CONSTRAINT `memes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `memes_ibfk_2` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `memes_ibfk_3` FOREIGN KEY (`repost_from`) REFERENCES `memes` (`id`) ON DELETE SET NULL;

--
-- Ограничения внешнего ключа таблицы `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `reports_messages`
--
ALTER TABLE `reports_messages`
  ADD CONSTRAINT `reports_messages_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reports_messages_ibfk_2` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `reports_posts`
--
ALTER TABLE `reports_posts`
  ADD CONSTRAINT `reports_posts_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reports_posts_ibfk_2` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `user_reactions`
--
ALTER TABLE `user_reactions`
  ADD CONSTRAINT `user_reactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_reactions_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE;

--
-- Ограничения внешнего ключа таблицы `view_history`
--
ALTER TABLE `view_history`
  ADD CONSTRAINT `view_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `view_history_ibfk_2` FOREIGN KEY (`meme_id`) REFERENCES `memes` (`id`) ON DELETE CASCADE;
COMMIT;