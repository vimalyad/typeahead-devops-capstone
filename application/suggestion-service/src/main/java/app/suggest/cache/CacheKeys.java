package app.suggest.cache;

import java.util.UUID;

/**
 * Cache keys embed the process namespace and build generation. On rebuild the
 * generation bumps, so every old key is instantly orphaned (no deletes — they age out via TTL)
 * and the first read under the new generation re-populates from the fresh trie.
 */
public final class CacheKeys {
    // Replicas rebuild independently. Isolate their generations so one pod cannot read
    // another pod's older snapshot under an identically numbered generation.
    private static final String PROCESS = UUID.randomUUID().toString();

    public static String suggest(int generation, String prefix) {
        return "suggest:" + PROCESS + ":v" + generation + ":" + prefix;
    }

    private CacheKeys() {
    }
}
