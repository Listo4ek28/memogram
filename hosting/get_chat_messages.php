<?php
require_once 'config.php';

if (!isset($_GET['user_id']) || !isset($_GET['chat_id'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$user_id = (int)$_GET['user_id'];
$chat_id = (int)$_GET['chat_id'];

try {
    $query = "
        SELECT 
            m.id as message_id,
            CASE 
                WHEN m.from_user_id = ? THEN 'sent'
                ELSE 'received'
            END as type,
            m.message_text as text,
            CONCAT('https://listo4ek.tech/', m.message_image) as image,
            m.from_user_id as from_user,
            m.created_at as time,
            u.display_name
        FROM messages m
        LEFT JOIN users u ON m.from_user_id = u.id
        WHERE ((m.from_user_id = ? AND m.to_user_id = ?) OR (m.from_user_id = ? AND m.to_user_id = ?))
        ORDER BY m.created_at ASC
        LIMIT 100
    ";

    $stmt = $pdo->prepare($query);
    $stmt->execute([$user_id, $user_id, $chat_id, $chat_id, $user_id]);
    $messages = $stmt->fetchAll();

    // Отмечаем как прочитанные
    $stmt = $pdo->prepare("UPDATE messages SET is_read = 1 WHERE to_user_id = ? AND from_user_id = ? AND is_read = 0");
    $stmt->execute([$user_id, $chat_id]);

    echo json_encode(['success' => true, 'messages' => $messages]);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>