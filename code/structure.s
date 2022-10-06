# 目的: 在文件中对结构体数据进行读写修改等操作
# 结构体数据偏移量
.equ RECORD_FIRSTNAME, 0
.equ RECORD_LASTNAME, 40
.equ RECORD_ADDRESS, 80
.equ RECORD_AGE, 320
.equ RECORD_SIZE, 324

# 系统调用号
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_BRK, 45
# 标准输入输出
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2
# 系统调用中断号
.equ LINUX_SYSCALL, 0x80
# 读文件返回值, 文件结束
.equ END_OF_FILE, 0

.section .data
file_name:
    .ascii "test.dat\0" # 文件名
# 定义结构体数据
record1:
    .ascii "Ren\0"
    .rept 36 # 填充40bytes里剩余空间
    .byte 0 # 用0填充
    .endr

    .ascii "Barret\0"
    .rept 33
    .byte 0
    .endr

    .ascii "china qd 203\0"
    .rept 229
    .byte 0
    .endr

    .long 45

.section .bss
.lcomm record_buffer, RECORD_SIZE

.section .text
.globl _start
# 函数: 从文件中读结构体.
# 输入: 文件描述符, 缓冲区
# 输出: 覆写缓冲区, 返回状态码
.type read_record, @function
read_record:
pushl %ebp
movl %esp, %ebp
# 获取输入参数
movl 12(%ebp), %ebx # 文件描述符
movl 8(%ebp), %ecx # 缓冲区, 直接读取, 不用管结构体结构
movl $RECORD_SIZE, %edx
# 调用read
movl $SYS_READ, %eax
int $LINUX_SYSCALL

movl %ebp, %esp
popl %ebp
ret

# 函数: 写结构体到文件.
# 输入: 文件描述符, 缓冲区
# 输出: 返回状态码
.type write_record, @function
write_record:
pushl %ebp
movl %esp, %ebp
# 获取输入参数
movl 12(%ebp), %ebx # 文件描述符
movl 8(%ebp), %ecx # 缓冲区
movl $RECORD_SIZE, %edx
# 调用read
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL

movl %ebp, %esp
popl %ebp
ret

# 主函数
_start:
movl %esp, %ebp
subl $8, %esp # 文件描述符栈空间

# 打开文件
movl $SYS_OPEN, %eax
movl $file_name, %ebx
movl $03101, %ecx
movl $0666, %edx
int $LINUX_SYSCALL
movl %eax, -4(%ebp) # 保存文件描述符
# 写入记录
pushl -4(%ebp)
pushl $record1
call write_record
addl $8, %esp
# 关闭文件描述符
movl $SYS_CLOSE, %eax
movl -4(%ebp), %ebx
int $LINUX_SYSCALL

# 读取文件内容， 显示在STDOUT上
movl $SYS_OPEN, %eax
movl $file_name, %ebx
movl $0, %ecx # 读模式
movl $0666, %edx
int $LINUX_SYSCALL
movl %eax, -4(%ebp) # 保存文件描述符
movl $STDOUT, -8(%ebp)
record_read_loop:
    pushl -4(%ebp)
    push $record_buffer
    call read_record
    addl $8, %esp
    # 判断读到的字节数
    cmpl $RECORD_SIZE, %eax
    jne finish_read
    # 读到有效数据， 打印address
    movl $240, %edx
    movl $SYS_WRITE, %eax
    movl -8(%ebp), %ebx
    # 这里+表示让指针移动到address的起始位置，汇编程序会自动相加得到一个新的地址
    movl $RECORD_ADDRESS+record_buffer, %ecx
    int $LINUX_SYSCALL
    jmp record_read_loop

finish_read:
movl $SYS_CLOSE, %eax
movl -4(%ebp), %ebx
int $LINUX_SYSCALL

# 退出程序
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL
