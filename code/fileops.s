# 目的: 读取文件中所有的字母转换为大写字母, 并输出到输出文件
# 处理过程:
#   1 打开输入文件
#   2 打开输出文件
#   3 如果未到达文件结尾
#       a 将部分文件读取缓冲区
#       b 读取缓冲器的每个字节, 如果是小写字母则转换为大写
#       c 缓冲区写入输出文件
.section .data
# 使用.equ指令定义数字的别名
# 系统调用号
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
# 文件打开模式
.equ O_RDONLLY, 0
.equ O_CREAT_WRONLY_TRUNC,03101
# 标准输入输出
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2
# 系统调用中断号
.equ LINUX_SYSCALL, 0x80
# 读文件返回值, 文件结束
.equ END_OF_FILE, 0
# 程序参数个数
.equ NUMBER_ARGUMENTS, 2

.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text
# 栈帧位置相关别名
.equ ST_SIZE_RESERVE, 8 #新增的栈空间给两个文件描述符
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0 # 参数个数
.equ ST_ARGV_0, 4 # 程序名
.equ ST_ARGV_1, 8 # 输入文件名
.equ ST_ARGV_2, 12 # 输出文件名

.globl _start
_start:
movl %esp, %ebp # 保存栈指针
subl $ST_SIZE_RESERVE, %esp # 新增栈空间

openfiles:
open_fd_in:
# 调用open系统调用， 设置各个参数
movl $SYS_OPEN, %eax
movl ST_ARGV_1(%ebp), %ebx
movl $O_RDONLLY, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

store_fd_in:
movl %eax, ST_FD_IN(%ebp) # 保存文件描述符到栈空间

open_fd_out:
# 调用open系统调用， 设置各个参数
movl $SYS_OPEN, %eax
movl ST_ARGV_2(%ebp), %ebx
movl $O_CREAT_WRONLY_TRUNC, %ecx
movl $0666, %edx
int $LINUX_SYSCALL

store_fd_out:
movl %eax, ST_FD_OUT(%ebp) # 保存文件描述符到栈空间

# read输入文件， 循环开始
read_loop_begin:
# 调用read系统调用， 读取部分内容到缓冲区
movl $SYS_READ, %eax
movl ST_FD_IN(%ebp), %ebx
movl $BUFFER_DATA, %ecx
movl $BUFFER_SIZE, %edx
int $LINUX_SYSCALL
# 判断read返回值， 是否出现错误
cmpl $END_OF_FILE, %eax
jle end_loop # 返回值小于等于0， 结束循环

continue_read_loop:
# 调用函数转换字符为大写
pushl $BUFFER_DATA
pushl %eax # read的字符个数
call convert_to_upper
popl %eax
addl $4, %esp # 恢复栈
#将转换后字符写入文件
movl %eax, %edx
movl $SYS_WRITE, %eax
movl ST_FD_OUT(%ebp), %ebx
movl $BUFFER_DATA, %ecx
int $LINUX_SYSCALL
# 继续循环
jmp read_loop_begin

end_loop:
# 循环结束， 关闭文件
movl $SYS_CLOSE, %eax
movl ST_FD_IN(%ebp), %ebx
int $LINUX_SYSCALL

movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx
int $LINUX_SYSCALL
# 退出程序
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

# 函数，转换为大写字母
# 输入参数: 缓冲区地址, 缓冲区大小
# 输出: 覆写后的缓冲区
.equ LOWERCASE_A, 'a'
.equ LOWERCASE_Z, 'z'
.equ UPPER_CONVERSION, 'A' - 'a'
.type convert_to_upper, @function
convert_to_upper:
pushl %ebp
movl %esp, %ebp

# 获取输入参数
movl 8(%ebp), %ebx # 缓存区大小
movl 12(%ebp), %eax # 缓冲器
movl $0, %edi

# 判断缓冲区大小是否为0
cmpl $0, %ebx
je end_func

# 循环遍历缓冲区
convert_loop:
movb (%eax, %edi, 1), %cl
# 判断是否需要转换
cmpb $LOWERCASE_A, %cl
jl next_byte
cmpb $LOWERCASE_Z, %cl
jg next_byte

# 转换
addb $UPPER_CONVERSION, %cl
movb %cl, (%eax, %edi, 1)

next_byte:
incl %edi # 增加index
cmpl %ebx, %edi
jle convert_loop

end_func:
movl %ebp, %esp
popl %ebp
ret
