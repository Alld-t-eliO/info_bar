#import <Metal/Metal.h>
#include "gpu.h"

GPUInfo get_gpu_info(void)
{
    GPUInfo info;

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    if (device == nil)
    {
        info.name = "Unknown";
        info.memory = 0;

        return info;
    }

    info.name = device.name.UTF8String;
    info.memory = device.recommendedMaxWorkingSetSize;

    return info;
}