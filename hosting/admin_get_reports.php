<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$type = isset($_GET['type']) ? $_GET['type'] : 'posts';
$search = isset($_GET['search']) ? $_GET['search'] : '';

// Проверка админа
$stmt = $pdo->prepare("SELECT admin FROM users WHERE id = ?");
$stmt->execute([$userId]);
$isAdmin = $stmt->fetchColumn();

if (!$isAdmin) {
    echo json_encode(['error' => 'Access denied']);
    exit;
}

try {
    if ($type == 'posts') {
        $sql = "
            SELECT 
                r.id as report_id,
                r.reason,
                r.created_at as reported_at,
                m.id as meme_id,
                m.meme_text,
                m.meme_image,
                u.id as user_id,
                u.username,
                u.display_name,
                c.id as community_id,
                c.name as community_name,
                u2.id as reporter_id,
                u2.username as reporter_username
            FROM reports_posts r
            JOIN memes m ON r.post_id = m.id
            JOIN users u ON m.user_id = u.id
            LEFT JOIN communities c ON m.community_id = c.id
            JOIN users u2 ON r.reporter_id = u2.id
        ";
        
        if (!empty($search)) {
            $sql .= " WHERE u.username LIKE :search OR u.display_name LIKE :search OR m.meme_text LIKE :search OR c.name LIKE :search";
            $stmt = $pdo->prepare($sql . " ORDER BY r.created_at DESC");
            $stmt->execute(['search' => "%$search%"]);
        } else {
            $stmt = $pdo->prepare($sql . " ORDER BY r.created_at DESC");
            $stmt->execute();
        }
        
        $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($reports as &$report) {
            $report['meme_image_url'] = $report['meme_image'] ? 'https://listo4ek.tech/' . $report['meme_image'] : null;
            $report['reason'] = $report['reason'] ?? 'other';
            $report['community_name'] = $report['community_name'] ?? null;
            $report['meme_text'] = $report['meme_text'] ?? '[No text]';
        }
        
        echo json_encode([
            'success' => true,
            'reports' => $reports,
            'type' => 'posts'
        ]);
    } else {
        $sql = "
            SELECT 
                r.id as report_id,
                r.reason,
                r.created_at as reported_at,
                msg.id as message_id,
                msg.message_text,
                msg.message_image,
                u.id as user_id,
                u.username,
                u.display_name,
                u2.id as receiver_id,
                u2.username as receiver_username,
                u3.id as reporter_id,
                u3.username as reporter_username
            FROM reports_messages r
            JOIN messages msg ON r.message_id = msg.id
            JOIN users u ON msg.from_user_id = u.id
            JOIN users u2 ON msg.to_user_id = u2.id
            JOIN users u3 ON r.reporter_id = u3.id
        ";
        
        if (!empty($search)) {
            $sql .= " WHERE u.username LIKE :search OR u.display_name LIKE :search OR msg.message_text LIKE :search";
            $stmt = $pdo->prepare($sql . " ORDER BY r.created_at DESC");
            $stmt->execute(['search' => "%$search%"]);
        } else {
            $stmt = $pdo->prepare($sql . " ORDER BY r.created_at DESC");
            $stmt->execute();
        }
        
        $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($reports as &$report) {
            $report['message_image_url'] = $report['message_image'] ? 'https://listo4ek.tech/' . $report['message_image'] : null;
            $report['reason'] = $report['reason'] ?? 'other';
            $report['message_text'] = $report['message_text'] ?? '[No text]';
        }
        
        echo json_encode([
            'success' => true,
            'reports' => $reports,
            'type' => 'messages'
        ]);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>