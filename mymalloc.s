.section .data
# points to the memory after head block
heap_begin:
.long 0
# points to the memory before tail block
current_break:
.long 0
# points to the first address of free memory blocks' list
free_mem_head:
.long 0

.equ HEADER_SIZE, 12
.equ HDR_OFFSET, 0
.equ SIZE_MASK, 0xFFFFFFF8
.equ FRONT_AVAIL_MASK, 0x2
.equ THIS_AVAIL_MASK, 0x1
.equ HDR_PRED_ADDR_OFFSET, 4
.equ HDR_SUCC_ADDR_OFFSET, 8
.equ FRONT_FTR_OFFSET, -4

.equ UNAVAILABLE, 0
.equ AVAILABLE, 1
.equ SYS_BRK, 45
.equ LINUX_SYSCALL, 0x80

.equ CHUNKSIZE, 0x1000

# mymalloc.s
.section .text

.globl my_mem_init
.type my_mem_init, @function
my_mem_init:
    pushl %ebp
    movl %esp, %ebp

    movl $SYS_BRK, %eax
    pushl %ebx
    movl $0, %ebx
    int $LINUX_SYSCALL
    pushl %esi
    movl %eax, free_mem_head
    movl %eax, %esi
    movl $SYS_BRK, %eax
    movl %esi, %ebx
    addl $0x1018, %ebx
    int $LINUX_SYSCALL
    movl %esi, %eax
    leal 16(%eax), %eax
    leal -8(%ebx), %ebx
    movl $0x1001, (%eax)
    movl %esi, HDR_PRED_ADDR_OFFSET(%eax)
    movl %ebx, HDR_SUCC_ADDR_OFFSET(%eax)
    movl (%eax), %edx
    movl %edx, FRONT_FTR_OFFSET(%ebx)
    movl %eax, HDR_SUCC_ADDR_OFFSET(%esi)
    movl %eax, HDR_PRED_ADDR_OFFSET(%ebx)
    movl $0x10, (%esi)
    movl $0xa, (%ebx)
    movl %eax, heap_begin
    movl %ebx, current_break
    # movl %eax, free_mem_head

    popl %esi
    popl %ebx
    movl %ebp, %esp
    popl %ebp
    ret

.globl my_mem_allocator
.type my_mem_allocator, @function
.equ ST_MEM_SIZE, 8
my_mem_allocator:
    pushl %ebp
    movl %esp, %ebp

    movl ST_MEM_SIZE(%ebp), %ecx # get parameter size
    addl $4, %ecx # block in use only need first-4-byte header
    movl %ecx, %edx
    andl $0x7, %ecx
    je .MATCH
    andl $SIZE_MASK, %edx
    addl $0x8, %edx
  .MATCH:
    # actual size in %edx
    movl free_mem_head, %eax
    jmp .CONTINUE
  .LOOP:
    movl (%eax), %ecx
    andl $SIZE_MASK, %ecx
    cmpl %ecx, %edx
    jg .CONTINUE
    # allocate here
    pushl %ebx
    pushl %esi
    pushl %edi
    movl %ecx, %edi
    movl %edx, %esi
    subl %edx, %ecx
    # break the free link
    movl HDR_PRED_ADDR_OFFSET(%eax), %ebx
    movl HDR_SUCC_ADDR_OFFSET(%eax), %edx
    movl %ebx, HDR_PRED_ADDR_OFFSET(%edx)
    movl %edx, HDR_SUCC_ADDR_OFFSET(%ebx)
    # seperate if necessary
    cmpl $16, %ecx
    jl .NO_SEP
    movl %esi, (%eax)
    leal (%eax, %esi), %ebx
    movl %ecx, (%ebx)
    addl $1, (%ebx)
    movl (%ebx), %edx
    movl %edx, FRONT_FTR_OFFSET(%ebx, %ecx)
    movl free_mem_head, %edx
    movl HDR_SUCC_ADDR_OFFSET(%edx), %ecx
    movl %ebx, HDR_SUCC_ADDR_OFFSET(%edx)
    movl %ebx, HDR_PRED_ADDR_OFFSET(%ecx)
    movl %edx, HDR_PRED_ADDR_OFFSET(%ebx)
    movl %ecx, HDR_SUCC_ADDR_OFFSET(%ebx)
    jmp .GET_RT_ADDR

  .NO_SEP:
    andl $0xFFFFFFF8, (%eax)
    andl $0xFFFFFFF8, (%eax, %edi)
  .GET_RT_ADDR:  
    leal 4(%eax), %eax
    popl %edi
    popl %esi
    popl %ebx
    jmp .RETURN
  .CONTINUE:  
    movl HDR_SUCC_ADDR_OFFSET(%eax), %eax
  .CHECK_IF_END:
    cmpl current_break, %eax
    jne .LOOP

    # ask for new space
    pushl %ebx
    pushl %esi
    pushl %edi
    movl (%eax), %ecx
    andl $FRONT_AVAIL_MASK, %ecx
    je .NEW_BRK
    movl FRONT_FTR_OFFSET(%eax), %ecx
    andl $SIZE_MASK, %ecx
    subl %ecx, %eax
  .NEW_BRK:
    leal (%eax, %edx), %ebx
    movl current_break, %ecx
    leal CHUNKSIZE(%ecx), %ecx
    cmpl %ebx, %ecx
    cmovg %ecx, %ebx
    leal 8(%ebx), %ebx
    pushl %eax
    movl $SYS_BRK, %eax
    int $LINUX_SYSCALL
    popl %eax
    leal -8(%ebx), %ebx
    movl current_break, %ecx
    movl (%ecx), %ecx
    movl %ecx, (%ebx)
    movl current_break, %ecx
    movl 4(%ecx), %ecx
    movl %ecx, 4(%ebx)
    movl HDR_PRED_ADDR_OFFSET(%ebx), %ecx
    movl %ebx, HDR_SUCC_ADDR_OFFSET(%ecx)
    movl %ebx, current_break
    movl %ebx, %ecx
    subl %eax, %ecx
    movl %ecx, (%eax)
    movl free_mem_head, %ecx
    movl HDR_SUCC_ADDR_OFFSET(%ecx), %ebx
    movl %ecx, HDR_PRED_ADDR_OFFSET(%eax)
    movl %ebx, HDR_SUCC_ADDR_OFFSET(%eax)
    movl %eax, HDR_SUCC_ADDR_OFFSET(%ecx)
    movl %eax, HDR_PRED_ADDR_OFFSET(%ebx)
    popl %edi
    popl %esi
    popl %ebx
    jmp .LOOP

  .RETURN:
    movl %ebp, %esp
    popl %ebp
    ret
