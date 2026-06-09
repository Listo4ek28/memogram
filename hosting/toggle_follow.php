<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['follow_id']) || !isset($data['action'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit;
}

$userId = (int)$data['user_id'];
$followId = (int)$data['follow_id'];
$action = $data['action'];

try {
    if ($action == 'follow') {
        // Проверяем, существует ли уже запись
        $stmt = $pdo->prepare("SELECT id FROM follows WHERE user_id = ? AND follow_id = ?");
        $stmt->execute([$userId, $followId]);
        $existing = $stmt->fetchColumn();
        
        if ($existing) {
            // Обновляем статус
            $stmt = $pdo->prepare("UPDATE follows SET status = 'accepted' WHERE user_id = ? AND follow_id = ?");
            $stmt->execute([$userId, $followId]);
        } else {
            // Создаём новую подписку
            $stmt = $pdo->prepare("INSERT INTO follows (user_id, follow_id, status) VALUES (?, ?, 'accepted')");
            $stmt->execute([$userId, $followId]);
        }
        echo json_encode(['success' => true, 'message' => 'Followed']);
    } else if ($action == 'unfollow') {
        $stmt = $pdo->prepare("DELETE FROM follows WHERE user_id = ? AND follow_id = ?");
        $stmt->execute([$userId, $followId]);
        echo json_encode(['success' => true, 'message' => 'Unfollowed']);
    } else {
        echo json_encode(['error' => 'Invalid action']);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>