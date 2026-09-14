#include <mach/mach.h>
#include <mach/mach_host.h>
#include <stdio.h>
#include "cpu.h"

double get_cpu_usage(void)
{
    static host_cpu_load_info_data_t previous_info;
    static int has_previous = 0;

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

    /*
     * Le CPU ne peut pas être mesuré instantanément : il faut comparer
     * deux relevés de ticks. Au premier appel, on n'a rien à comparer.
     */
    if (!has_previous)
    {
        previous_info = cpu_info;
        has_previous = 1;
        return 0.0;
    }

    unsigned long long user_delta =
        cpu_info.cpu_ticks[CPU_STATE_USER] - previous_info.cpu_ticks[CPU_STATE_USER];
    unsigned long long system_delta =
        cpu_info.cpu_ticks[CPU_STATE_SYSTEM] - previous_info.cpu_ticks[CPU_STATE_SYSTEM];
    unsigned long long nice_delta =
        cpu_info.cpu_ticks[CPU_STATE_NICE] - previous_info.cpu_ticks[CPU_STATE_NICE];
    unsigned long long idle_delta =
        cpu_info.cpu_ticks[CPU_STATE_IDLE] - previous_info.cpu_ticks[CPU_STATE_IDLE];

    unsigned long long total_delta = user_delta + system_delta + nice_delta + idle_delta;

    previous_info = cpu_info;

    if (total_delta == 0)
    {
        return 0.0;
    }

    double usage = (double)(user_delta + system_delta + nice_delta) / (double)total_delta * 100.0;

    return usage;
}
