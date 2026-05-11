<?php
require_once 'config.php';
if (!isset($_GET['user_id'], $_GET['meme_id'])) {
    echo json_encode(['has_reacted' => false]); exit;
}
$stmt = $pdo->prepare("SELECT COUNT(*) FROM user_reactions WHERE user_id=? AND meme_id=?");
$stmt->execute([(int)$_GET['user_id'], (int)$_GET['meme_id']]);
echo json_encode(['success' => true, 'has_reacted' => $stmt->fetchColumn() > 0]);