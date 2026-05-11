<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$aboutFile = 'about.md';

if (file_exists($aboutFile)) {
    $content = file_get_contents($aboutFile);
    echo json_encode([
        'success' => true,
        'content' => $content
    ]);
} else {
    echo json_encode([
        'success' => false,
        'error' => 'About file not found'
    ]);
}
?>