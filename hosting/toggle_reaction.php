<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['message_id']) || !isset($data['user_id']) || !isset($data['action'])) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

if ($data['action'] == 'add') {
    // Проверяем, ставил ли пользователь уже реакцию
    $stmt = $pdo->prepare("SELECT id FROM user_reactions WHERE user_id = ? AND meme_id = ?");
    $stmt->execute([$data['user_id'], $data['message_id']]);
    if ($stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Already reacted']);
        exit;
    }
    
    // Добавляем реакцию
    $stmt = $pdo->prepare("INSERT INTO user_reactions (user_id, meme_id, reaction_type) VALUES (?, ?, 'like')");
    $stmt->execute([$data['user_id'], $data['message_id']]);
    
    // Обновляем счетчик в таблице memes
    $stmt = $pdo->prepare("UPDATE memes SET reactions = reactions + 1 WHERE id = ?");
    $stmt->execute([$data['message_id']]);
    
} else if ($data['action'] == 'remove') {
    // Удаляем реакцию
    $stmt = $pdo->prepare("DELETE FROM user_reactions WHERE user_id = ? AND meme_id = ?");
    $stmt->execute([$data['user_id'], $data['message_id']]);
    
    // Обновляем счетчик в таблице memes
    $stmt = $pdo->prepare("UPDATE memes SET reactions = reactions - 1 WHERE id = ? AND reactions > 0");
    $stmt->execute([$data['message_id']]);
}

echo json_encode(['success' => true]);
?>