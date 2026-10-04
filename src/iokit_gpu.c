#include <stdio.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOKitKeys.h>
#include <CoreFoundation/CoreFoundation.h>
#include "iokit_gpu.h"

static void print_cf_string(
    CFDictionaryRef dictionary,
    const char *key
)
{
    CFTypeRef value = CFDictionaryGetValue(
        dictionary,
        CFSTR("IOClass")
    );

    if (value == NULL)
    {
        return;
    }

    if (CFGetTypeID(value) != CFStringGetTypeID())
    {
        return;
    }

    char buffer[256];

    if (CFStringGetCString(
        (CFStringRef)value,
        buffer,
        sizeof(buffer),
        kCFStringEncodingUTF8
    ))
    {
        printf("[INFO] %s: %s\n", key, buffer);
    }
}


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
        printf("[ERR] IOKit : %d\n", result);
        return;
    }
    io_service_t service;
    int found = 0;


    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL)
    {
        found = 1;

        printf("\n[INFO] GPU service found!\n");


        CFMutableDictionaryRef properties = NULL;

        kern_return_t property_result;

        property_result = IORegistryEntryCreateCFProperties(
            service,
            &properties,
            kCFAllocatorDefault,
            0
        );


        if (property_result == KERN_SUCCESS && properties)
        {
            CFTypeRef value = CFDictionaryGetValue(
                properties,
                CFSTR("IOClass")
            );


            if (value != NULL &&
                CFGetTypeID(value) == CFStringGetTypeID())
            {
                char buffer[256];

                if (CFStringGetCString(
                    (CFStringRef)value,
                    buffer,
                    sizeof(buffer),
                    kCFStringEncodingUTF8
                ))
                {
                    printf(
                        "[INFO] IOClass: %s\n",
                        buffer
                    );
                }
            }

            value = CFDictionaryGetValue(
                properties,
                CFSTR("IONameMatched")
            );


            if (value != NULL &&
                CFGetTypeID(value) == CFStringGetTypeID())
            {
                char buffer[256];

                if (CFStringGetCString(
                    (CFStringRef)value,
                    buffer,
                    sizeof(buffer),
                    kCFStringEncodingUTF8
                ))
                {
                    printf(
                        "[INFO] IONameMatched: %s\n",
                        buffer
                    );
                }
            }


            /*
             * Récupération de IOProviderClass.
             */
            value = CFDictionaryGetValue(
                properties,
                CFSTR("IOProviderClass")
            );


            if (value != NULL &&
                CFGetTypeID(value) == CFStringGetTypeID())
            {
                char buffer[256];

                if (CFStringGetCString(
                    (CFStringRef)value,
                    buffer,
                    sizeof(buffer),
                    kCFStringEncodingUTF8
                ))
                {
                    printf(
                        "[INFO] IOProviderClass: %s\n",
                        buffer
                    );
                }
            }



            CFRelease(properties);
        }
        else
        {
            printf(
                "[ERR] Unable to read GPU properties: %d\n",
                property_result
            );
        }


        IOObjectRelease(service);
    }


    if (!found)
    {
        printf("[INFO] GPU services not found.\n");
    }


    IOObjectRelease(iterator);
}