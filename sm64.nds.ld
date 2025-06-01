/*MEMORY {
    fakerom (r)  : ORIGIN = 0x0, LENGTH = 16M
    segment (rw) : ORIGIN = 0x00000000, LENGTH = 16M * 32
}*/

MEMORY {
    fakerom     : ORIGIN = 0x0, LENGTH = 16M
    segment     : ORIGIN = 0x0, LENGTH = 512M
}

#define BEGIN_SEG(name, addr) \
    _##name##SegmentStart = ADDR(.sm64.name); \
    _##name##SegmentRomStart = LOADADDR(.sm64.name); \
    .sm64.name (addr) : 

#define END_SEG(name) \
    > segment AT> ewram  \
    _##name##SegmentEnd = ADDR(.sm64.name) + SIZEOF(.sm64.name); \
    _##name##SegmentRomEnd = LOADADDR(.sm64.name) + SIZEOF(.sm64.name);

#define BEGIN_NOLOAD(name) \
    _##name##SegmentNoloadStart = ADDR(.name.noload); \
    .name.noload (NOLOAD) :

#define END_NOLOAD(name) \
    > rdram \
    _##name##SegmentNoloadEnd = ADDR(.name.noload) + SIZEOF(.name.noload);

#define MIO0_SEG(name, segAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        KEEP(BUILD_DIR/bin/name.o(.data* .rodata*)); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0)

#define MIO0_EU_SEG(name, segAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        KEEP(BUILD_DIR/bin/eu/name.o(.data* .rodata*)); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0)

#define STANDARD_LEVEL(name) \
    BEGIN_SEG(name##_segment_7, 0x07000000) \
    { \
        KEEP(BUILD_DIR/levels/name/leveldata.o(.data* .rodata*)); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_segment_7) \
    BEGIN_SEG(name, 0x0E000000) \
    { \
        BUILD_DIR/levels/name/script.o(.data* .rodata*); \
        BUILD_DIR/levels/name/geo.o(.data* .rodata*); \
    } \
    END_SEG(name)

#define STANDARD_OBJECTS(name, segAddr, geoAddr) \
    BEGIN_SEG(name##_mio0, segAddr) \
    { \
        KEEP(BUILD_DIR/actors/name.o(.data* .rodata*)); \
        . = ALIGN(0x10); \
    } \
    END_SEG(name##_mio0) \
    BEGIN_SEG(name##_geo, geoAddr) \
    { \
        BUILD_DIR/actors/name##_geo.o(.data* .rodata*); \
    } \
    END_SEG(name##_geo)

#define CREATE_LO_HI_PAIR(name, value) \
    name##Hi = (value) >> 16; \
    name##Lo = (value) & 0xffff;

_goddardSegmentStart = 0;
_goddardSegmentEnd = 0;
_goddardSegmentNoloadStart = 0;
_goddardSegmentNoloadEnd = 0;
_goddardSegmentRomStart = 0;
_goddardSegmentRomEnd = 0;

SECTIONS
{
    /* Start of memory segments */
    /*_poolStart = _framebuffersSegmentNoloadEnd;
    _poolEnd   = ORIGIN(rdram) + LENGTH(rdram);*/

    BEGIN_SEG(entry, 0x10000000)
    {
        BUILD_DIR/levels/entry.o(.data* .rodata*);
    }
    END_SEG(entry)

    /*
     * On DS, segment 2 is rather part of the main binary.
     * This is because passing non-segmented memory addresses through segmented_to_virtual needs to return the same address,
     * and having a segment 2 will confuse real addresses with ones in segment 2.
     */
    /* MIO0_SEG(segment2, 0x02000000) */

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
        BUILD_DIR/data/behavior_data.o(.data* .rodata*);
    }
    END_SEG(behavior)

    /* 0x268020 0x268020-0 [0] */
    BEGIN_SEG(intro, 0x14000000)
    {
        BUILD_DIR/levels/intro/script.o(.data* .rodata*);
        BUILD_DIR/levels/intro/geo.o(.data* .rodata*);
    }
    END_SEG(intro)
    BEGIN_SEG(intro_segment_7, 0x07000000)
    {
        KEEP(BUILD_DIR/levels/intro/leveldata.o(.data* .rodata*));
        . = ALIGN(0x10);
    }
    END_SEG(intro_segment_7)

    MIO0_SEG(debug_level_select, 0x07000000)
    MIO0_SEG(title_screen_bg, 0x0A000000)

#if 0
    /* 271B20-2A42A0 [32780] */
    BEGIN_SEG(gd_dynlists, 0x04000000)
    {
        BUILD_DIR/libgoddard.a:dynlist_*(.data* .rodata*);
        BUILD_DIR/libgoddard.a:anim_*(.data* .rodata*);
        BUILD_DIR/libgoddard.a:*.o(.data* .rodata*);
        BUILD_DIR/libgoddard.a:*.o(.rodata*);
    }
    END_SEG(gd_dynlists)
#endif

    BEGIN_SEG(menu, 0x14000000)
    {
        BUILD_DIR/levels/menu/script.o(.data* .rodata*);
        BUILD_DIR/levels/menu/geo.o(.data* .rodata*);
    }
    END_SEG(menu)
    BEGIN_SEG(menu_segment_7, 0x07000000)
    {
        KEEP(BUILD_DIR/levels/menu/leveldata.o(.data* .rodata*));
        . = ALIGN(0x10);
    }
    END_SEG(menu_segment_7)

    BEGIN_SEG(scripts, 0x15000000)
    {
        BUILD_DIR/levels/scripts.o(.data* .rodata*);
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

    BEGIN_SEG(assets, )
    {
        BUILD_DIR/assets/mario_anim_data.o(.data*);
        BUILD_DIR/assets/mario_anim_data.o(.rodata*);
        BUILD_DIR/assets/demo_data.o(.data*);
        BUILD_DIR/sound/sound_data.o(.data*);
    } > ewram AT> ewram

    /* Discard everything not specifically mentioned above. */
    /*/DISCARD/ :
    {
        *(*);
    }*/

}
