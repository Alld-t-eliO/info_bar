#ifndef GPU_H
#define GPU_H

typedef struct 
{
    const char *name;
    unsigned long long memory;
} GPUInfo;

GPUInfo get_gpu_info(void);

#endif