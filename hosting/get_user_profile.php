<?php
require_once 'config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = (int)$_GET['user_id'];

try {
    $stmt = $pdo->prepare("SELECT id, username, display_name, email, avatar, bio, memes_viewed, created_at, admin, banned FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'display_name' => $user['display_name'] ?? $user['username'],
                'email' => $user['email'],
                'avatar' => $user['avatar'],
                'bio' => $user['bio'],
                'memes_viewed' => (int)$user['memes_viewed'],
                'created_at' => $user['created_at'],
                'is_admin' => (int)$user['admin'] === 1,
                'is_banned' => (int)$user['banned'] === 1
            ]
        ]);
    } else {
        echo json_encode(['error' => 'User not found']);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>