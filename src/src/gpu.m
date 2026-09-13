#import <Metal/Metal.h>
#include <stdio.h>

int main(void) 
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil)
    {
        printf("No Metal GPU found. \n");
        return 1;
    }

    printf("GPU: %s\n",  device.name.UTF8String);
    return 0; 
}