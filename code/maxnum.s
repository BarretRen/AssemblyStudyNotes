# 目的： 寻找数组中的最大值
# 变量：
#   %edi: 保存数组当前index
#   %ebx: 保存已找到的最大值
#   %eax: 数组当前值
# 使用以下内存位置:
# nums: 0表示数据结束
.section .data
nums: # 数组
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,0

.section .text
.globl _start
_start:
movl $0, %edi # 默认index 0
movl nums(, %edi, 4), %eax
movl %eax, %ebx # 最大值默认数组第一个元素

# 循环开始
start_loop:
cmpl $0, %eax # 判断是否到达数组结尾
je _exit # je, 值相等则跳转
incl %edi # 自增index
movl nums(, %edi, 4), %eax
cmpl %ebx, %eax
jle start_loop # 第二个值小于等于第一个值则跳转下一次循环
movl %eax, %ebx # eax大, 赋值为ebx
jmp start_loop

_exit:
movl $1, %eax # 系统调用exit, 参数在%ebx中
int $0x80
