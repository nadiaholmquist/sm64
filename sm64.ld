OUTPUT_ARCH (mips)

/* include/segments.h defines SEG_POOL_START, SEG_POOL_END, SEG_BUFFERS,
 * SEG_GODDARD, SEG_ENGINE, SEG_FRAMEBUFFERS */
#include "segments.h"
#include "config.h"

#ifndef USE_EXT_RAM
#define ADDR_OR_ALIGN(addr) (addr)
#else
#define ADDR_OR_ALIGN(addr) ALIGN(0x1000)
#endif

#define BEGIN_SEG(name, addr) \
    _##name##SegmentStart = ADDR(.name); \
    _##name##SegmentRomStart = __romPos; \
    .name (addr) : AT(__romPos)

#define END_SEG(name) \
    _##name##SegmentEnd = ADDR(.name) + SIZEOF(.name); \
    _##name##SegmentRomEnd = __romPos + SIZEOF(.name); \
    __romPos += SIZEOF(.name);

#define BEGIN_NOLOAD(name) \
    _##name##SegmentNoloadStart = ADDR(.name.noload); \
    .name.noload (NOLOAD) :

#define END_NOLOAD(name) \
    _##name##SegmentNoloadEnd = ADDR(.name.noload) + SIZEOF(.name.noload);

#define MIO0_SEG(name, segAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        BUILD_DIR/bin/name.mio0.o(.data*); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0)

#define MIO0_EU_SEG(name, segAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        BUILD_DIR/bin/eu/name.mio0.o(.data*); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0)

#define STANDARD_LEVEL(name) \
    BEGIN_SEG(name##_segment_7, 0x07000000) \
    { \
        BUILD_DIR/levels/name/leveldata.mio0.o(.data*); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_segment_7) \
    BEGIN_SEG(name, 0x0E000000) \
    { \
        BUILD_DIR/levels/name/script.o(.data*); \
        BUILD_DIR/levels/name/geo.o(.data*); \
    } \
    END_SEG(name)

#define STANDARD_OBJECTS(name, segAddr, geoAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        BUILD_DIR/actors/name.mio0.o(.data*); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0) \
    BEGIN_SEG(name##_geo, geoAddr) \
    { \
        BUILD_DIR/actors/name##_geo.o(.data*); \
    } \
    END_SEG(name##_geo)

#define CREATE_LO_HI_PAIR(name, value) \
    name##Hi = (value) >> 16; \
    name##Lo = (value) & 0xffff;

SECTIONS
{
    __romPos = 0;

    BEGIN_SEG(boot, 0x04000000)
    {
        BUILD_DIR/asm/rom_header.o(.text*);
        BUILD_DIR/asm/boot.o(.text*);
        BUILD_DIR/asm/ipl3_font.o(.text*);
    }
    END_SEG(boot)

    . = 0x80000400;
    BEGIN_NOLOAD(zbuffer) {
        BUILD_DIR/src/buffers/zbuffer.o(.bss*);
    }

#ifdef VERSION_CN
    gZBufferEnd = .;
#endif

    . = SEG_BUFFERS;
    BEGIN_NOLOAD(buffers)
    {
        BUILD_DIR/src/buffers/buffers.o(.bss*);
#if defined(VERSION_SH) || defined(VERSION_CN)
        BUILD_DIR/src/audio/port_sh.o(.bss*);
#else
        BUILD_DIR/src/audio/globals_start.o(.bss*);
        BUILD_DIR/src/audio/synthesis.o(.bss*);
        BUILD_DIR/src/audio/heap.o(.bss*);
        BUILD_DIR/src/audio/load.o(.bss*);
        BUILD_DIR/src/audio/data.o(.bss*);
#endif

#ifdef VERSION_EU
        . = ALIGN(0x200);
#else
        . = ALIGN(0x1000);
#endif
#if defined(VERSION_SH) || defined(VERSION_CN)
        . += 0xB000;
#endif
        BUILD_DIR/src/buffers/gfx_output_buffer.o(.bss*);
    }
    END_NOLOAD(buffers)

    /* lib/src/__osDevMgrMain.c and lib/src/osCreateViManager.c contain infinite
     * loops compiled without -g, which cause the return statements and the .o
     * files themselves to be aligned to 32-byte boundaries. But the linker
     * Nintendo used did not respect .o file alignment, and aligned the files
     * only to 16 bytes, in some cases misaligning them. We force the same to
     * happen using the SUBALIGN directive. This is harmless; the alignment is
     * just an optimization. */
    BEGIN_SEG(main, ) SUBALIGN(16)
    {
        BUILD_DIR/asm/entry.o(.text*);
        BUILD_DIR/asm/decompress.o(.text*);

        BUILD_DIR/src/game*.o(.text*);
        BUILD_DIR/src/audio*.o(.text*);
        BUILD_DIR/lib/rsp.o(.text*);
        BUILD_DIR/libultra.a:*.o(.text*);

        /* data */
        BUILD_DIR/src/game*.o(.data*);
        BUILD_DIR/src/audio*.o(.data*);
        BUILD_DIR/libultra.a:*.o(.data*);

        /* rodata */
        BUILD_DIR/src/game*.o(.rodata*);
        BUILD_DIR/src/audio*.o(.rodata*);
        BUILD_DIR/libultra.a:*.o(.rodata*);
        BUILD_DIR/lib/rsp.o(.rodata*);
    }
    END_SEG(main)

    BEGIN_NOLOAD(main)
    {
        BUILD_DIR/src/game*.o(.bss*);
        BUILD_DIR/src/audio*o(.bss*);

        BUILD_DIR/libultra.a:*.o(.bss*);

        BUILD_DIR/src/game/cn_common_syms_2.o(.bss*);

        . = ALIGN(0x8);
    }
    END_NOLOAD(main)

#ifdef VERSION_CN
    // Hack for CN to make asm/entry.s match, since we aren't using
    // the original assembler and so can't get lui/ori from la pseudo
    CREATE_LO_HI_PAIR(_mainSegmentNoloadStart, ADDR (.main.noload))
    CREATE_LO_HI_PAIR(gIdleThreadStack, gIdleThreadStack)
    CREATE_LO_HI_PAIR(main_func, main_func)
#endif

    CREATE_LO_HI_PAIR(_mainSegmentNoloadSize, SIZEOF (.main.noload))

    BEGIN_SEG(engine, ADDR_OR_ALIGN(SEG_ENGINE))
    {
        BUILD_DIR/src/engine*.o(.text*);
        /* data */
        BUILD_DIR/src/engine*.o(.data*);

        /* rodata */
        BUILD_DIR/src/engine*.o(.rodata*);
    }
    END_SEG(engine)

    BEGIN_NOLOAD(engine)
    {
        BUILD_DIR/src/engine*.o(.bss*);
    }
    END_NOLOAD(engine)

    . = ADDR_OR_ALIGN(SEG_FRAMEBUFFERS);
    BEGIN_NOLOAD(framebuffers)
    {
        BUILD_DIR/src/buffers/framebuffers.o(.bss*);
    }
    END_NOLOAD(framebuffers)

    BEGIN_SEG(entry, 0x10000000)
    {
        BUILD_DIR/levels/entry.o(.data*);
    }
    END_SEG(entry)

    /* load MIO0 and level data */
    MIO0_SEG(segment2, 0x02000000)
#ifdef VERSION_EU
    MIO0_EU_SEG(translation_en, 0x19000000)
    MIO0_EU_SEG(translation_fr, 0x19000000)
    MIO0_EU_SEG(translation_de, 0x19000000)
#endif

    /* mario actor group */
    STANDARD_OBJECTS(group0,  0x04000000, 0x17000000)

    /* load the other actor groups */
    STANDARD_OBJECTS(group1,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group2,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group3,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group4,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group5,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group6,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group7,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group8,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group9,  0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group10, 0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group11, 0x05000000, 0x0C000000)
    STANDARD_OBJECTS(group12, 0x06000000, 0x0D000000)
    STANDARD_OBJECTS(group13, 0x06000000, 0x0D000000)
    STANDARD_OBJECTS(group14, 0x06000000, 0x0D000000)
    STANDARD_OBJECTS(group15, 0x06000000, 0x0D000000)
    STANDARD_OBJECTS(group16, 0x06000000, 0x0D000000)
    STANDARD_OBJECTS(group17, 0x06000000, 0x0D000000)

    /* load the common actor groups */
    STANDARD_OBJECTS(common0, 0x08000000, 0x0F000000)
    STANDARD_OBJECTS(common1, 0x03000000, 0x16000000)

    /* use segmented addressing for behaviors */
    BEGIN_SEG(behavior, 0x13000000)
    {
        BUILD_DIR/data/behavior_data.o(.data*);
    }
    END_SEG(behavior)

    /* 0x8016F000 21D7D0-255EC0 [386F0] */
    BEGIN_SEG(goddard, SEG_GODDARD)
    {
        BUILD_DIR/src/menu*.o(.text*);
        BUILD_DIR/libgoddard.a:*.o(.text*);
        /* data, rodata, per file */
        BUILD_DIR/src/menu*.o(.data*);
        BUILD_DIR/src/menu*.o(.rodata*);
        /* goddard subsystem data */
        BUILD_DIR/libgoddard.a:gd_main.o(.data*);
        BUILD_DIR/libgoddard.a:draw_objects.o(.data*);
        BUILD_DIR/libgoddard.a:objects.o(.data*);
        BUILD_DIR/libgoddard.a:particles.o(.data*);
        BUILD_DIR/libgoddard.a:dynlist_proc.o(.data*);
        BUILD_DIR/libgoddard.a:debug_utils.o(.data*);
        BUILD_DIR/libgoddard.a:joints.o(.data*);
        BUILD_DIR/libgoddard.a:shape_helper.o(.data*);
        BUILD_DIR/libgoddard.a:renderer.o(.data*);
        /* goddard subsystem rodata */
        BUILD_DIR/libgoddard.a:gd_main.o(.rodata*);
        BUILD_DIR/libgoddard.a:gd_memory.o(.rodata*);
        BUILD_DIR/libgoddard.a:draw_objects.o(.rodata*);
        BUILD_DIR/libgoddard.a:objects.o(.rodata*);
        BUILD_DIR/libgoddard.a:skin_movement.o(.rodata*);
        BUILD_DIR/libgoddard.a:particles.o(.rodata*);
        BUILD_DIR/libgoddard.a:dynlist_proc.o(.rodata*);
        BUILD_DIR/libgoddard.a:old_menu.o(.rodata*);
        BUILD_DIR/libgoddard.a:debug_utils.o(.rodata*);
        BUILD_DIR/libgoddard.a:joints.o(.rodata*);
        BUILD_DIR/libgoddard.a:skin.o(.rodata*);
        BUILD_DIR/libgoddard.a:gd_math.o(.rodata*);
        BUILD_DIR/libgoddard.a:shape_helper.o(.rodata*);
        BUILD_DIR/libgoddard.a:renderer.o(.rodata*);
    }
    END_SEG(goddard)
    BEGIN_NOLOAD(goddard)
    {
        BUILD_DIR/src/menu*.o(.bss*);
        BUILD_DIR/libgoddard.a:*.o(.bss*);
    }
    END_NOLOAD(goddard)

    /* 0x268020 0x268020-0 [0] */
    BEGIN_SEG(intro, 0x14000000)
    {
        BUILD_DIR/levels/intro/script.o(.data*);
        BUILD_DIR/levels/intro/geo.o(.data*);
    }
    END_SEG(intro)
    BEGIN_SEG(intro_segment_7, 0x07000000)
    {
        BUILD_DIR/levels/intro/leveldata.mio0.o(.data*);
        . = ALIGN(0x10);
    }
    END_SEG(intro_segment_7)

    MIO0_SEG(debug_level_select, 0x07000000)
    MIO0_SEG(title_screen_bg, 0x0A000000)

    /* 271B20-2A42A0 [32780] */
    BEGIN_SEG(gd_dynlists, 0x04000000)
    {
        BUILD_DIR/libgoddard.a:dynlist_test_cube.o(.data*);
        BUILD_DIR/libgoddard.a:dynlist_unused.o(.data*);
        BUILD_DIR/libgoddard.a:dynlist_mario_face.o(.data*);
        BUILD_DIR/libgoddard.a:dynlists_mario_eyes.o(.data*);
        BUILD_DIR/libgoddard.a:dynlists_mario_eyebrows_mustache.o(.data*);
        BUILD_DIR/libgoddard.a:dynlist_mario_master.o(.data*);
        BUILD_DIR/libgoddard.a:anim_mario_mustache_right.o(.data*);
        BUILD_DIR/libgoddard.a:anim_mario_mustache_left.o(.data*);
        BUILD_DIR/libgoddard.a:anim_mario_lips_1.o(.data*);
        BUILD_DIR/libgoddard.a:anim_mario_lips_2.o(.data*);
        BUILD_DIR/libgoddard.a:anim_mario_eyebrows_1.o(.data*);
        BUILD_DIR/libgoddard.a:anim_group_1.o(.data*);
        BUILD_DIR/libgoddard.a:anim_group_2.o(.data*);
        BUILD_DIR/libgoddard.a:dynlist_test_cube.o(.rodata*);
        BUILD_DIR/libgoddard.a:dynlist_unused.o(.rodata*);
        BUILD_DIR/libgoddard.a:*.o(.data*);
        BUILD_DIR/libgoddard.a:*.o(.rodata*);
    }
    END_SEG(gd_dynlists)

    gMainLevels = __romPos;

    BEGIN_SEG(menu, 0x14000000)
    {
        BUILD_DIR/levels/menu/script.o(.data*);
        BUILD_DIR/levels/menu/geo.o(.data*);
    }
    END_SEG(menu)
    BEGIN_SEG(menu_segment_7, 0x07000000)
    {
        BUILD_DIR/levels/menu/leveldata.mio0.o(.data*);
        . = ALIGN(0x10);
    }
    END_SEG(menu_segment_7)

    BEGIN_SEG(scripts, 0x15000000)
    {
        BUILD_DIR/levels/scripts.o(.data*);
    }
    END_SEG(scripts)

    MIO0_SEG(water_skybox, 0x0A000000)
    MIO0_SEG(ccm_skybox, 0x0A000000)
    MIO0_SEG(clouds_skybox, 0x0A000000)
    MIO0_SEG(bitfs_skybox, 0x0A000000)
    MIO0_SEG(wdw_skybox, 0x0A000000)
    MIO0_SEG(cloud_floor_skybox, 0x0A000000)
    MIO0_SEG(ssl_skybox, 0x0A000000)
    MIO0_SEG(bbh_skybox, 0x0A000000)
    MIO0_SEG(bidw_skybox, 0x0A000000)
    MIO0_SEG(bits_skybox, 0x0A000000)

    // Texture bins
    MIO0_SEG(fire, 0x09000000)
    MIO0_SEG(spooky, 0x09000000)
    MIO0_SEG(generic, 0x09000000)
    MIO0_SEG(water, 0x09000000)
    MIO0_SEG(sky, 0x09000000)
    MIO0_SEG(snow, 0x09000000)
    MIO0_SEG(cave, 0x09000000)
    MIO0_SEG(machine, 0x09000000)
    MIO0_SEG(mountain, 0x09000000)
    MIO0_SEG(grass, 0x09000000)
    MIO0_SEG(outside, 0x09000000)
    MIO0_SEG(inside, 0x09000000)
    MIO0_SEG(effect, 0x0B000000)

#define STUB_LEVEL(_0, _1, _2, _3, _4, _5, _6, _7, _8)
#define DEFINE_LEVEL(_0, _1, _2, folder, _4, _5, _6, _7, _8, _9, _10) STANDARD_LEVEL(folder)

    #include "levels/level_defines.h"

#undef STUB_LEVEL
#undef DEFINE_LEVEL

    /* 4E9FA0-? [?] */
    BEGIN_SEG(assets, __romPos)
    {
        BUILD_DIR/assets/mario_anim_data.o(.data*);
        BUILD_DIR/assets/mario_anim_data.o(.rodata*);
        BUILD_DIR/assets/demo_data.o(.data*);
        BUILD_DIR/sound/sound_data.o(.data*);
    }
    END_SEG(assets)

    /* Discard everything not specifically mentioned above. */
    /DISCARD/ :
    {
        *(*);
    }

    ASSERT((_goddardSegmentNoloadEnd <= SEG_POOL_END), "Error: menu segment extended past pool end")
    ASSERT((_mainSegmentNoloadEnd <= _engineSegmentStart), "Error: main segment extended into engine.")
    ASSERT((_engineSegmentNoloadEnd <= _framebuffersSegmentNoloadStart), "Error: engine segment extended into framebuffers.")
    ASSERT((_framebuffersSegmentNoloadEnd <= RDRAM_END), "Error: framebuffers segment extended past RDRAM end")
}
