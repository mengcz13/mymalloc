// Initialization
void my_mem_init();

// allocator
void* my_mem_allocator(unsigned int size);

#include <stdio.h>

int main() {
    my_mem_init();
    int* p1 = (int*)my_mem_allocator(8192*sizeof(int));
    int i = 0;
    for (i = 0; i < 8192; ++i) {
        p1[i] = i + 1;
    }
    for (i = 0; i < 8192; ++i) {
        printf("%d\n", p1[i]);
    }
    return 0;
}
