<?php
require_once 'config.php';
$data = json_decode(file_get_contents('php://input'), true);
if (!isset($data['user_id'], $data['friend_id'])) {
    echo json_encode(['error' => 'Missing fields']); exit;
}
$uid = (int)$data['user_id'];
$fid = (int)$data['friend_id'];
if ($uid == $fid) { echo json_encode(['error' => 'Same user']); exit; }
$stmt = $pdo->prepare("SELECT id FROM friends WHERE (user_id=? AND friend_id=?) OR (user_id=? AND friend_id=?)");
$stmt->execute([$uid, $fid, $fid, $uid]);
if ($stmt->fetch()) { echo json_encode(['success' => false, 'error' => 'Already exists']); exit; }
$stmt = $pdo->prepare("INSERT INTO friends (user_id, friend_id, status) VALUES (?, ?, 'pending')");
$stmt->execute([$uid, $fid]);
echo json_encode(['success' => true]);