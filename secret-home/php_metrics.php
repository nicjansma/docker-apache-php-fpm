<?php

// don't cache
header("Content-Type: text/plain");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");

//
// APC
//
if (function_exists('apcu_sma_info')) {
    $mem = apcu_sma_info();

    print("php_apcu{version=\"" . phpversion('apcu') . "\"} 1\n");

    print("php_apcu_segment_size " . $mem['seg_size'] . "\n");
    print("php_apcu_available_memory " . $mem['avail_mem'] . "\n");
    print("php_apcu_used_memory " . ($mem['seg_size'] - $mem['avail_mem']) . "\n");

    $cache = apcu_cache_info(true);

    print("php_apcu_hits " . $cache['num_hits'] . "\n");
    print("php_apcu_misses " . $cache['num_misses'] . "\n");
    print("php_apcu_inserts " . $cache['num_inserts'] . "\n");
    print("php_apcu_entries " . $cache['num_entries'] . "\n");
    print("php_apcu_expunges " . $cache['expunges'] . "\n");
} else {
    print("php_apcu 0\n");
}

print("\n");

//
// OpCache
//
if (function_exists('opcache_get_configuration')) {
    $config = opcache_get_configuration();
    $status = opcache_get_status();

    print("php_opcache{version=\"" . $config['version']['version'] . "\"} 1\n");
    
    print("php_opcache_used_memory " . $status['memory_usage']['used_memory'] . "\n");
    print("php_opcache_free_memory " . $status['memory_usage']['free_memory'] . "\n");
    print("php_opcache_wasted_memory " . $status['memory_usage']['wasted_memory'] . "\n");

    print("php_opcache_interned_strings_number " . $status['interned_strings_usage']['number_of_strings'] . "\n");
    print("php_opcache_interned_strings_buffer_size " . $status['interned_strings_usage']['buffer_size'] . "\n");
    print("php_opcache_interned_strings_used_memory " . $status['interned_strings_usage']['used_memory'] . "\n");
    print("php_opcache_interned_strings_free_memory " . $status['interned_strings_usage']['free_memory'] . "\n");

    print("php_opcache_num_cached_scripts " . $status['opcache_statistics']['num_cached_scripts'] . "\n");
    print("php_opcache_num_cached_keys " . $status['opcache_statistics']['num_cached_keys'] . "\n");
    print("php_opcache_max_cached_keys " . $status['opcache_statistics']['max_cached_keys'] . "\n");
    print("php_opcache_hits " . $status['opcache_statistics']['hits'] . "\n");
    print("php_opcache_misses " . $status['opcache_statistics']['misses'] . "\n");
    print("php_opcache_hit_rate " . $status['opcache_statistics']['opcache_hit_rate'] . "\n");
} else {
    print("php_opcache 0\n");
}
