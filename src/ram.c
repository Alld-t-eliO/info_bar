#include <stdio.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <sys/sysctl.h>
#include "ram.h"

RAMInfo get_ram_info(void)
{
    RAMInfo info = {0};

    /*
     * RAM physique totale, via sysctl.
     */
    uint64_t total_memory = 0;
    size_t size = sizeof(total_memory);

    if (sysctlbyname("hw.memsize", &total_memory, &size, NULL, 0) != 0)
    {
        printf("[ERR] Impossible de lire hw.memsize\n");
        return info;
    }

    vm_size_t page_size = 0;
    host_page_size(mach_host_self(), &page_size);

    vm_statistics64_data_t vm_stats;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;

    kern_return_t result = host_statistics64(
        mach_host_self(),
        HOST_VM_INFO64,
        (host_info64_t)&vm_stats,
        &count
    );

    info.total = total_memory;

    if (result != KERN_SUCCESS)
    {
        printf("[ERR] Impossible de lire les stats VM\n");
        return info;
    }

    /*
     * "Utilisé" au sens Activity Monitor : mémoire active + wired +
     * compressée. Le reste (inactive, free, speculative) est récupérable.
     */
    unsigned long long used_memory =
        ((unsigned long long)vm_stats.active_count +
         (unsigned long long)vm_stats.wire_count +
         (unsigned long long)vm_stats.compressor_page_count) * page_size;

    if (used_memory > total_memory)
    {
        used_memory = total_memory;
    }

    info.used = used_memory;
    info.free = total_memory - used_memory;

    if (total_memory > 0)
    {
        info.percent_used = (double)used_memory / (double)total_memory * 100.0;
    }

    return info;
}
