#ifndef ZBUFFER_H
#define ZBUFFER_H

#include <PR/ultratypes.h>

#include "config.h"
#include "macros.h"

#ifdef TARGET_NDS
extern u16 gZBuffer[0];
extern s32 gZBufferEnd;
#else
extern u16 gZBuffer[SCREEN_WIDTH * SCREEN_HEIGHT];
extern s32 gZBufferEnd;
#endif

#endif // ZBUFFER_H
