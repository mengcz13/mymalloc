// Initialization
void my_mem_init();

// allocator
void* my_mem_allocator(size_t size);

// free 
void my_mem_free(void* pointer);

// interface
void* my_malloc(size_t size) {
    static bool inited = false;
    if (!inited) {
        my_mem_init();
        inited = true;
    }
    return my_mem_allocator(size);
}

void my_free(void* pointer) {
    my_mem_free(pointer);
}
