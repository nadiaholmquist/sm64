#if !defined(_WIN32) && !defined(_WIN64)

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>

#include <SDL3/SDL.h>

#include <ultra64.h>

#include "controller_api.h"

#define DEADZONE 4960

static bool init_ok;
static SDL_Gamepad *sdl_cntrl;

static void controller_sdl_init(void) {
    if (!SDL_Init(SDL_INIT_GAMEPAD) != 0) {
        fprintf(stderr, "SDL init error: %s\n", SDL_GetError());
        return;
    }

    init_ok = true;
}

static void controller_sdl_read(OSContPad *pad) {
    if (!init_ok) {
        return;
    }

    SDL_UpdateGamepads();

    if (sdl_cntrl != NULL && !SDL_GamepadConnected(sdl_cntrl)) {
        SDL_CloseGamepad(sdl_cntrl);
        sdl_cntrl = NULL;
    }
    if (sdl_cntrl == NULL) {
        int gamepad_count;
        SDL_JoystickID* gamepads = SDL_GetGamepads(&gamepad_count);
        for (int i = 0; i < gamepad_count; i++) {
            sdl_cntrl = SDL_OpenGamepad(gamepads[i]);
            if (sdl_cntrl != NULL)
                break;
            if (i == gamepad_count - 1)
                return;
        }
    }

    if (SDL_GetGamepadButton(sdl_cntrl, SDL_GAMEPAD_BUTTON_START)) pad->button |= START_BUTTON;
    if (SDL_GetGamepadButton(sdl_cntrl, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER)) pad->button |= Z_TRIG;
    if (SDL_GetGamepadButton(sdl_cntrl, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER)) pad->button |= R_TRIG;
    if (SDL_GetGamepadButton(sdl_cntrl, SDL_GAMEPAD_BUTTON_SOUTH)) pad->button |= A_BUTTON;
    if (SDL_GetGamepadButton(sdl_cntrl, SDL_GAMEPAD_BUTTON_WEST)) pad->button |= B_BUTTON;

    int16_t leftx = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_LEFTX);
    int16_t lefty = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_LEFTY);
    int16_t rightx = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_RIGHTX);
    int16_t righty = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_RIGHTY);

    int16_t ltrig = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_LEFT_TRIGGER);
    int16_t rtrig = SDL_GetGamepadAxis(sdl_cntrl, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER);

#ifdef TARGET_WEB
    // Firefox has a bug: https://bugzilla.mozilla.org/show_bug.cgi?id=1606562
    // It sets down y to 32768.0f / 32767.0f, which is greater than the allowed 1.0f,
    // which SDL then converts to a int16_t by multiplying by 32767.0f, which overflows into -32768.
    // Maximum up will hence never become -32768 with the current version of SDL2,
    // so this workaround should be safe in compliant browsers.
    if (lefty == -32768) {
        lefty = 32767;
    }
    if (righty == -32768) {
        righty = 32767;
    }
#endif

    if (rightx < -0x4000) pad->button |= L_CBUTTONS;
    if (rightx > 0x4000) pad->button |= R_CBUTTONS;
    if (righty < -0x4000) pad->button |= U_CBUTTONS;
    if (righty > 0x4000) pad->button |= D_CBUTTONS;

    if (ltrig > 30 * 256) pad->button |= Z_TRIG;
    if (rtrig > 30 * 256) pad->button |= R_TRIG;

    uint32_t magnitude_sq = (uint32_t)(leftx * leftx) + (uint32_t)(lefty * lefty);
    if (magnitude_sq > (uint32_t)(DEADZONE * DEADZONE)) {
        // Game expects stick coordinates within -80..80
        // 32768 / 409 = ~80
        pad->stick_x = leftx / 409;
        pad->stick_y = -lefty / 409;
    }
}

struct ControllerAPI controller_sdl = {
    controller_sdl_init,
    controller_sdl_read
};

#endif
