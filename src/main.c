#include <stdio.h>

#include "iokit_gpu.h"

int main(void)
{
    printf("Recherche des GPU...\n");

    find_gpu_services();

    return 0;
}