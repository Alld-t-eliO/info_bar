#ifndef RAM_H
#define RAM_H

typedef struct
{
    unsigned long long total;   /* octets */
    unsigned long long used;    /* octets */
    unsigned long long free;    /* octets */
    double percent_used;
} RAMInfo;

RAMInfo get_ram_info(void);

#endif
