#ifndef NDS_AUDIO_H
#define NDS_AUDIO_H

#include "audio/load.h"

struct SampleCacheEntry {
    void* romPos;
    void* allocPos;
    u32 lastUsedTick;
};

extern void play_notes(struct Note *notes);

#endif // NDS_AUDIO_H
