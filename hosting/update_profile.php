<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id'])) {
    echo json_encode(['error' => 'Missing user_id']);
    exit;
}

$user_id = $data['user_id'];
$display_name = $data['display_name'] ?? null;
$username = $data['username'] ?? null;
$email = $data['email'] ?? null;
$bio = $data['bio'] ?? null;
$avatar = $data['avatar'] ?? null;

try {
    $updates = [];
    $params = [];
    
    if ($display_name !== null) {
        $updates[] = "display_name = ?";
        $params[] = $display_name;
    }
    
    if ($username !== null) {
        // Проверяем, не занят ли username другим пользователем
        $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
        $stmt->execute([$username, $user_id]);
        if ($stmt->fetch()) {
            echo json_encode(['error' => 'Username already taken']);
            exit;
        }
        $updates[] = "username = ?";
        $params[] = $username;
    }
    
    if ($email !== null) {
        // Проверяем, не занят ли email другим пользователем
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $stmt->execute([$email, $user_id]);
        if ($stmt->fetch()) {
            echo json_encode(['error' => 'Email already taken']);
            exit;
        }
        $updates[] = "email = ?";
        $params[] = $email;
    }
    
    if ($bio !== null) {
        $updates[] = "bio = ?";
        $params[] = $bio;
    }
    
    if ($avatar !== null) {
        $updates[] = "avatar = ?";
        $params[] = $avatar;
    }
    
    if (empty($updates)) {
        echo json_encode(['error' => 'No fields to update']);
        exit;
    }
    
    $params[] = $user_id;
    $query = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    
    // Получаем обновлённые данные пользователя
    $stmt = $pdo->prepare("SELECT id, username, display_name, email, avatar, bio, memes_viewed, created_at FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'user' => [
            'id' => $user['id'],
            'username' => $user['username'],
            'display_name' => $user['display_name'],
            'email' => $user['email'],
            'avatar' => $user['avatar'],
            'bio' => $user['bio'],
            'memes_viewed' => (int)$user['memes_viewed'],
            'created_at' => $user['created_at']
        ]
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>