# 目的: 使用libc库的printf函数打印字符
# 编译是需要引用libc库:
#   as hello-lib.s -o he.o
#   ld  -I /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 -lc he.o -o run
.section .data
helloworld:
.ascii "hello world\n\0"

.section .text
.globl _start
_start:
pushl $helloworld
call printf

pushl $0
call exit
