#ifndef GPU_H
#define GPU_H

typedef struct
{
    const char *name;
    unsigned long long memory;      /* VRAM recommandée max (octets) */
    unsigned long long usedMemory;  /* VRAM actuellement allouée (octets) */
} GPUInfo;

GPUInfo get_gpu_info(void);

#endif
