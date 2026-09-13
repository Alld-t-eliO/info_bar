#include <stdio.h>
#include "gpu.h"
#include "cpu.h"
#include "memory.h"

int main(void) 
{
    const char *gpu = get_gpu_name();
    printf("GPU: %s\n", gpu);
    return 0;

    const char *cpu_name = get_cpu_name();
    printf("CPU: %s\n", cpu_name);

    const char *memory_name = get_memory_name();
    printf("Memory: %s\n", memory_name);
}