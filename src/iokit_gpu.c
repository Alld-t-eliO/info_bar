#include <stdio.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOKitKeys.h>
#include "iokit_gpu.h"

void find_gpu_services(void)
{
    io_iterator_t iterator;

    kern_return_t result;

    result = IOServiceGetMatchingServices(
        kIOMainPortDefault,
        IOServiceMatching("IOAccelerator"),
        &iterator
    );

    if (result != KERN_SUCCESS)
    {
        printf("[ERR]IOKit : %d\n", result);
        return;
    }

    printf("[INFO] GPU services not found:\n");

    io_service_t service;

    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL)
    {
        printf("[INFO] GPU services found !\n");

        IOObjectRelease(service);
    }

    IOObjectRelease(iterator);
}