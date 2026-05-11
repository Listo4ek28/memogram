<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username']) || !isset($data['email']) || !isset($data['password'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$password_hash = password_hash($data['password'], PASSWORD_DEFAULT);
$display_name = $data['username']; // По умолчанию display_name = username

try {
    $stmt = $pdo->prepare("INSERT INTO users (username, display_name, email, password_hash, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->execute([$data['username'], $display_name, $data['email'], $password_hash]);
    echo json_encode(['success' => true, 'message' => 'User registered']);
} catch(PDOException $e) {
    echo json_encode(['error' => 'Username or email exists']);
}
?>