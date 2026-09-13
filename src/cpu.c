#include <mach/mach.h>
#include <mach/mach_host.h>
#include <stdio.h>
#include "cpu.h"

double get_cpu_usage(void) {
    host_cpu_load_info_data_t cpu_info;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    
    kern_return_t result = host_statistics(
        mach_host_self(),
        HOST_CPU_LOAD_INFO,
        (host_info_t)&cpu_info,
        &count
    );
    if (result != KERN_SUCCESS) 
    {
        return -1.0; 
    }
    return 0.0;
}