# 目的：退出并向内核返回程序退出状态码
# 变量：
#   %eax保存系统调用号
#   %ebx保存返回状态
.section .data
.section .text
.globl _start

_start:
movl $1, %eax # 1写入通用寄存器eax，1表示系统调用exit
movl $0, %ebx # 0写入ebx，表示exit的参数
int $0x80 #引发linux内核中断
