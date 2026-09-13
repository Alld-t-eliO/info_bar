#import <Metal/Metal.h>

const char *get_gpu_name(void) 
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        return "No Metal GPU found";
    }
    return device.name.UTF8String; 
}