#include <stdio.h>

#include "nds_include.h"
#include <fat.h>

#include "audio/data.h"
#include "audio/external.h"
#include "audio/load.h"
#include "audio/seqplayer.h"
#include "game/game_init.h"
#include "nds_renderer.h"
#include "nds_rom.h"

u8 nds_audio_state;
static u8 audio_step;
static u8 fps;

void exec_display_list(struct SPTask *spTask) {
    draw_frame((Gfx*)spTask->task.t.data_ptr);
    fps++;
}

struct SampleCacheEntry {
    void* romPos;
    void* allocPos;
    u32 lastUsedTick;
};

struct SampleCacheEntry sample_cache[32] = {};
static u32 audioTick = 0;

u8 get_cached_sample(struct Note* note) {
    u8 lastUsed = -1;
    u32 lastUsedTick = audioTick - 1;
    struct AudioBankSample* sample = note->sound->sample;

    for (int i = 0; i < 32; i++) {
        if (sample_cache[i].romPos == sample->sampleAddr)
            return i;

        if (sample_cache[i].romPos == NULL) {
            lastUsed = i;
            break;
        }

        if (sample_cache[i].lastUsedTick < lastUsedTick)
            lastUsed = i;
    }

    struct SampleCacheEntry* last = &sample_cache[lastUsed];
    if (last->allocPos != NULL) free(last->allocPos);
    void* alloc = malloc(sample->loop->end + (sample->loop->end / 2));
    nds_read_rom((u32) sample->sampleAddr, ((u32) sample->sampleAddr) + sample->loop->end + (sample->loop->end / 2), alloc);

    last->romPos = sample->sampleAddr;
    last->allocPos = alloc;
    last->lastUsedTick = audioTick;

    DC_FlushRange(alloc, sample->loop->end);
    DC_FlushRange(last, sizeof(struct SampleCacheEntry));

    return lastUsed;
}

static void update_audio(void) {
#if defined(VERSION_JP) || defined(VERSION_US)
    audioTick++;

    // Update audio at the ARM7's request
    if (nds_audio_state == 0) {
        // Update the sequences at 240 Hz
        process_sequences(0);

        for (int i = 0; i < gMaxSimultaneousNotes; i++) {
            struct Note* note = &gNotes[i];
            if (note->needsInit)
                note->sampleDmaIndex = 0;

            if (note->sound == NULL || note->sound->sample == NULL || note->sound->sample->sampleAddr == NULL)
                continue;

            if (note->sampleDmaIndex == 0) {
                note->sampleDmaIndex = get_cached_sample(note) + 1;
            } else {
                sample_cache[note->sampleDmaIndex - 1].lastUsedTick = audioTick;
            }
        }
    } else if (nds_audio_state == 1) {
        // Disable audio
        for (int i = 0; i < 16; i++) {
            gNotes[i].enabled = false;
        }
        nds_audio_state = 2;
    }

    fifoSendValue32(FIFO_USER_01, 0);

    // Update the audio logic at 30 Hz
    if (nds_audio_state == 0 && (audio_step = (audio_step + 1) & 7) == 0) {
        update_game_sound();
        gAudioFrameCount += 2;
        gAudioRandom = ((gAudioRandom + gAudioFrameCount) * gAudioFrameCount);
    }

    // Tell the ARM7 it can go ahead
#endif
}

static void update_fps(void) {
    // Draw and reset the FPS counter
    consoleClear();
    printf("FPS: %d\n", fps);
    fps = 0;
}

int main(void) {
    static u64 pool[0x165000 / sizeof(u64)];
    main_pool_init(pool, pool + sizeof(pool) / sizeof(pool[0]));
    gEffectsMemoryPool = mem_pool_init(0x4000, MEMORY_POOL_LEFT);

    defaultExceptionHandler();

    nds_open_rom();

    consoleDemoInit();
    consoleDebugInit(DebugDevice_NOCASH);

    // Initialize various components
    fatInitDefault();

    renderer_init();
    audio_init();
    sound_init();

    // Set up audio on the ARM9 side
    timerStart(1, ClockDivider_64, TIMER_FREQ_64(240), update_audio);

    // Give the ARM7 a pointer to the audio data and sample cache
    fifoSendValue32(FIFO_USER_01, (u32)gNotes);
    fifoSendValue32(FIFO_USER_01, (u32)&sample_cache);

#ifdef ENABLE_FPS
    // Update the FPS counter every second
    timerStart(0, ClockDivider_1024, TIMER_FREQ_1024(1), update_fps);
#endif

    // Run the game
    thread5_game_loop(NULL);

    return 0;
}
