<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$data = json_decode(file_get_contents('php://input'), true);
$adminId = isset($data['admin_id']) ? (int)$data['admin_id'] : 0;
$action = isset($data['action']) ? $data['action'] : '';
$targetType = isset($data['target_type']) ? $data['target_type'] : '';
$targetId = isset($data['target_id']) ? (int)$data['target_id'] : 0;

// Проверка админа
$stmt = $pdo->prepare("SELECT admin FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$isAdmin = $stmt->fetchColumn();

if (!$isAdmin) {
    echo json_encode(['error' => 'Access denied']);
    exit;
}

try {
    switch ($action) {
        // Действия с постами
        case 'delete_post':
            $stmt = $pdo->prepare("DELETE FROM memes WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'Post deleted']);
            break;
            
        // Действия с пользователями
        case 'ban_user':
            $stmt = $pdo->prepare("UPDATE users SET banned = 1 WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'User banned']);
            break;
            
        case 'unban_user':
            $stmt = $pdo->prepare("UPDATE users SET banned = 0 WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'User unbanned']);
            break;
            
        case 'delete_user':
            $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'User deleted']);
            break;
            
        // Действия с сообществами
        case 'delete_community':
            $stmt = $pdo->prepare("DELETE FROM communities WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'Community deleted']);
            break;
            
        // Действия с жалобами на посты
        case 'skip_report':
        case 'skip_post_report':
            $stmt = $pdo->prepare("DELETE FROM reports_posts WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'Report skipped']);
            break;
            
        case 'delete_reported_post':
            $stmt = $pdo->prepare("SELECT post_id FROM reports_posts WHERE id = ?");
            $stmt->execute([$targetId]);
            $postId = $stmt->fetchColumn();
            if ($postId) {
                $stmt = $pdo->prepare("DELETE FROM memes WHERE id = ?");
                $stmt->execute([$postId]);
                $stmt = $pdo->prepare("DELETE FROM reports_posts WHERE id = ?");
                $stmt->execute([$targetId]);
                echo json_encode(['success' => true, 'message' => 'Reported post deleted']);
            } else {
                echo json_encode(['error' => 'Post not found']);
            }
            break;
            
        // Действия с жалобами на сообщения
        case 'skip_message_report':
            $stmt = $pdo->prepare("DELETE FROM reports_messages WHERE id = ?");
            $stmt->execute([$targetId]);
            echo json_encode(['success' => true, 'message' => 'Report skipped']);
            break;
            
        case 'delete_reported_message':
            $stmt = $pdo->prepare("SELECT message_id FROM reports_messages WHERE id = ?");
            $stmt->execute([$targetId]);
            $messageId = $stmt->fetchColumn();
            if ($messageId) {
                $stmt = $pdo->prepare("DELETE FROM messages WHERE id = ?");
                $stmt->execute([$messageId]);
                $stmt = $pdo->prepare("DELETE FROM reports_messages WHERE id = ?");
                $stmt->execute([$targetId]);
                echo json_encode(['success' => true, 'message' => 'Reported message deleted']);
            } else {
                echo json_encode(['error' => 'Message not found']);
            }
            break;
            
        default:
            echo json_encode(['error' => 'Unknown action: ' . $action]);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>