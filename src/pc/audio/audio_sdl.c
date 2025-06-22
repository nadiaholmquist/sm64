#if !defined(_WIN32) && !defined(_WIN64)

#include <stdio.h>

#ifdef __MINGW32__
#include "SDL.h"
#else
#include <SDL3/SDL.h>
#endif

#include "audio_api.h"

static SDL_AudioStream* stream;

static bool audio_sdl_init(void) {
    if (!SDL_Init(SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "SDL init error: %s\n", SDL_GetError());
        return false;
    }

    SDL_AudioSpec want = { SDL_AUDIO_S16, 2, 32000 };
    stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &want, 0, 0);
    if (stream == NULL) {
        fprintf(stderr, "SDL_OpenAudioDeviceStream error: %s\n", SDL_GetError());
        return false;
    }

    SDL_ResumeAudioDevice(SDL_GetAudioStreamDevice(stream));
    return true;
}

static int audio_sdl_buffered(void) {
    return SDL_GetAudioStreamQueued(stream) / 4;
}

static int audio_sdl_get_desired_buffered(void) {
    return 1100;
}

static void audio_sdl_play(const uint8_t *buf, size_t len) {
    if (audio_sdl_buffered() < 6000) {
        // Don't fill the audio buffer too much in case this happens
        SDL_PutAudioStreamData(stream, buf, len);
    }
}

struct AudioAPI audio_sdl = {
    audio_sdl_init,
    audio_sdl_buffered,
    audio_sdl_get_desired_buffered,
    audio_sdl_play
};

#endif
