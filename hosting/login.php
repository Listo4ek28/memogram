<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username']) || !isset($data['password'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$stmt = $pdo->prepare("SELECT id, username, display_name, password_hash FROM users WHERE username = ?");
$stmt->execute([$data['username']]);
$user = $stmt->fetch();

if ($user) {
    $isValid = false;
    if (password_get_info($user['password_hash'])['algo']) {
        $isValid = password_verify($data['password'], $user['password_hash']);
    } else {
        $isValid = ($user['password_hash'] == $data['password']);
    }
    
    if ($isValid) {
        echo json_encode([
            'success' => true, 
            'user_id' => (int)$user['id'], 
            'username' => $user['username'],
            'display_name' => $user['display_name']
        ]);
    } else {
        echo json_encode(['error' => 'Invalid password']);
    }
} else {
    echo json_encode(['error' => 'User not found']);
}
?>