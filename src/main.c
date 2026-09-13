#include <stdio.h>
#include "gpu.h"

int main(void)
{
    GPUInfo gpu = get_gpu_info();

    printf("GPU Information\n");
    printf("-------------------------\n");
    printf("Name: %s\n", gpu.name);
    printf("Mem: %llu bytes\n", gpu.memory);

    return 0;
}