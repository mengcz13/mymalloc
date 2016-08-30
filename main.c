#include "mymalloc.h"
#include "pptmalloc.h"
#include <stdio.h>
#include <sys/time.h>
#define N 10000
#define BLOCK 100

//#define MYMALLOC
#define PPTMALLOC

#ifdef MYMALLOC
#define meminit my_mem_init
#define memallo my_mem_allocator
#define memfree my_mem_free
#endif

#ifdef PPTMALLOC
#define meminit allocate_init
#define memallo allocate
#define memfree deallocate
#endif

int main() {
    meminit();
    void* parray[N] = {0};
    int i = 0;
    void* addr1, *addrn;
    struct timeval tpstart, tpend;
    double timeuse;
    gettimeofday(&tpstart, NULL);
    // N blocks
    for (i = 0; i < N; ++i) {
        parray[i] = memallo(BLOCK);
    }
    addr1 = parray[0];
    for (i = 0; i < N; i += 4) {
        memfree(parray[i]);
        parray[i] = 0;
        memfree(parray[i + 1]);
        parray[i + 1] = 0;
    }
    addrn = 0;
    for (i = 0; i < N; i += 4) {
        parray[i] = memallo(2*BLOCK);
        if (parray[i] > addrn)
            addrn = parray[i];
    }
    gettimeofday(&tpend, NULL);
    timeuse = 1000000*(tpend.tv_sec-tpstart.tv_sec)+tpend.tv_usec-tpstart.tv_usec;
    printf("actual size: %d Byte\n", N * BLOCK);
    printf("used size: %d Byte\n", addrn - addr1 + BLOCK);
    printf("used time: %lf us\n", timeuse);
    return 0;
}
