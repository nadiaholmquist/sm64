#include "../nds_include.h"

#include "nds_audio.h"

struct Note *gNotes;
struct SampleCacheEntry (*sample_cache)[32];
static bool running;

static void send_input(void) {
    inputGetAndSend();
}

#if defined(VERSION_JP) || defined(VERSION_US)
static void update_audio(UNUSED long unsigned value32, UNUSED void* userdata) {
    // Play the current notes
    play_notes(gNotes);
}
#endif

static void power_down(void) {
    running = false;
}

int main(void) {
    irqInit();
    fifoInit();
    touchInit();

    readUserSettings();
    installSystemFIFO();
    setPowerButtonCB(power_down);

    SetYtrigger(80);
    irqSet(IRQ_VCOUNT, send_input);
    irqEnable(IRQ_VCOUNT | IRQ_IPC_SYNC);

#if defined(VERSION_JP) || defined(VERSION_US)
    // Get a pointer to the audio data from the ARM9
    while (!fifoCheckValue32(FIFO_USER_01));
    gNotes = (struct Note*)fifoGetValue32(FIFO_USER_01);
    sample_cache = (struct SampleCacheEntry(*)[32]) fifoGetValue32(FIFO_USER_01);

    // Prepare to update the audio at 240 Hz
    enableSound();
    //timerStart(0, ClockDivider_64, TIMER_FREQ_64(240), update_audio);
    fifoSetValue32Handler(FIFO_USER_01, update_audio, NULL);
#endif
    running = true;

    // Wait idly for interrupts
    while (running) {
        swiWaitForVBlank();
    }

    return 0;
}
