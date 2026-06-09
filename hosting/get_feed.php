<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 7;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

try {
    // Получаем ID пользователей, на которых подписан текущий пользователь
    $followStmt = $pdo->prepare("
        SELECT follow_id FROM follows 
        WHERE user_id = ? AND status = 'accepted'
    ");
    $followStmt->execute([$user_id]);
    $following = $followStmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Добавляем самого пользователя, чтобы видеть свои посты
    $following[] = $user_id;
    
    // Формируем плейсхолдеры для IN
    $placeholders = rtrim(str_repeat('?,', count($following)), ',');
    
    // Сначала получаем общее количество постов
    $countSql = "
        SELECT COUNT(DISTINCT m.id)
        FROM memes m
        LEFT JOIN communities c ON m.community_id = c.id
        WHERE 
            m.community_id IN (
                SELECT community_id 
                FROM community_subscriptions 
                WHERE user_id = ?
            )
            OR
            (m.user_id IN ($placeholders))
    ";
    $countParams = array_merge([$user_id], $following);
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($countParams);
    $total = $countStmt->fetchColumn();
    
    // Получаем посты с пагинацией
    $sql = "
        SELECT DISTINCT
            m.id,
            m.user_id,
            m.community_id,
            m.meme_text,
            m.meme_image,
            m.reactions,
            m.views_count,
            m.created_at,
            u.username,
            u.display_name,
            u.avatar as user_avatar,
            c.name as community_name
        FROM memes m
        JOIN users u ON m.user_id = u.id
        LEFT JOIN communities c ON m.community_id = c.id
        WHERE 
            m.community_id IN (
                SELECT community_id 
                FROM community_subscriptions 
                WHERE user_id = ?
            )
            OR
            (m.user_id IN ($placeholders))
        ORDER BY m.created_at DESC
        LIMIT $limit OFFSET $offset
    ";
    
    $params = array_merge([$user_id], $following);
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $memes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Проверяем избранное для каждого мема
    foreach ($memes as &$meme) {
        $favStmt = $pdo->prepare("SELECT id FROM favorites WHERE user_id = ? AND meme_id = ?");
        $favStmt->execute([$user_id, $meme['id']]);
        $meme['is_favorite'] = $favStmt->fetchColumn() ? true : false;
    }
    
    echo json_encode([
        'success' => true,
        'memes' => $memes,
        'total' => (int)$total
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>