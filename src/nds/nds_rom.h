#ifndef NDS_ROM_H
#define NDS_ROM_H

#include "nds_include.h"

bool nds_open_rom();
void nds_read_rom(const u32 start, const u32 end, void* dest);
void* nds_get_cached_segment(u32 addr);

#endif // NDS_ROM_H