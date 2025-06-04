#include <stdio.h>
#include <PR/ultratypes.h>
#include "nds_rom.h"
#include "nds_include.h"

FILE* blob;
u8* assetsCache;

extern u8 _assetsSegmentRomEnd[];

bool nds_open_rom() {
    bool ok = nitroFSInit(NULL);
    if (!ok) {
        consoleDemoInit();
        printf("Failed to init NitroFS!\n\nNitroFS access is required for the game to load its assets.");
        for(;;);
    }

    blob = fopen("nitro:/blob.bin", "r");
    if (!blob) {
        consoleDemoInit();
        printf("Could not load the segments blob from NitroFS.");
        for(;;);
    }

    // On DSi the whole game fits in memory, so we just cache the whole thing for a small performance improvement
    if (isDSiMode()) {
        u32 size = _assetsSegmentRomEnd;// - _assetsSegmentRomStart;
        fseek(blob, 0, SEEK_SET);
        assetsCache = malloc(size);
        fread(assetsCache, size, 1, blob);
        fclose(blob);
    } else {
        nitroFSInitLookupCache(32768);
    }

    return true;
}

void nds_read_rom(const u32 start, const u32 end, void* dest) {
    if (isDSiMode()) {//&& start >= (u32) _assetsSegmentRomStart && start < (u32) _assetsSegmentRomEnd) {
        memcpy(dest, assetsCache + start /*- (u32) _assetsSegmentRomStart*/, end - start);
    } else {
        fseek(blob, start, SEEK_SET);
        fread(dest, end - start, 1, blob);
    }
}

void* nds_get_cached_segment(u32 addr) {
    if (isDSiMode())
        return assetsCache + addr;
    else
        return NULL;
}