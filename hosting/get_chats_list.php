<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

$stmt = $pdo->prepare("
    SELECT 
        CASE WHEN from_user_id = ? THEN to_user_id ELSE from_user_id END AS chat_id,
        MAX(created_at) AS last_message_time,
        SUM(CASE WHEN to_user_id = ? AND is_read = 0 THEN 1 ELSE 0 END) AS unread_count
    FROM messages
    WHERE from_user_id = ? OR to_user_id = ?
    GROUP BY chat_id
    ORDER BY last_message_time DESC
");
$stmt->execute([$user_id, $user_id, $user_id, $user_id]);
$raw = $stmt->fetchAll();

$chats = [];
foreach ($raw as $row) {
    $other_id = (int)$row['chat_id'];
    $u = $pdo->prepare("SELECT display_name, username FROM users WHERE id = ?");
    $u->execute([$other_id]);
    $user = $u->fetch();
    $display = $user ? ($user['display_name'] ?? $user['username']) : 'User';

    $last = $pdo->prepare("
        SELECT message_text
        FROM messages
        WHERE ((from_user_id = ? AND to_user_id = ?) OR (from_user_id = ? AND to_user_id = ?))
        ORDER BY created_at DESC LIMIT 1
    ");
    $last->execute([$user_id, $other_id, $other_id, $user_id]);
    $lastMsg = $last->fetchColumn();

    $chats[] = [
        'chat_id' => $other_id,
        'display_name' => $display,
        'last_message' => $lastMsg ?: '',
        'last_message_time' => $row['last_message_time'],
        'unread_count' => (int)$row['unread_count']
    ];
}

echo json_encode(['success' => true, 'chats' => $chats]);
?>