// Initialization
void my_mem_init();

// allocator
void* my_mem_allocator(unsigned int size);

// free
void my_mem_free(void* p);

#include <stdio.h>
#define N 20
#define BLOCK 1024
int main() {
    my_mem_init();
    int* parray[N] = {0};
    for (int i = 0; i < N; ++i) {
        parray[i] = my_mem_allocator(100* sizeof(int));
        printf("0x%8.x\n", parray[i]);
    }
    my_mem_free(parray[2]);
    my_mem_free(parray[0]);
    my_mem_free(parray[1]);
    my_mem_free(parray[5]);
    int* n1 = my_mem_allocator(300*sizeof(int));
    int* n2 = my_mem_allocator(50*sizeof(int));
    printf("0x%8.x\n", n1);
    printf("0x%8.x\n", n2);
    return 0;
}
