# 目的: 给定一个数字, 调用函数计算其阶乘
#      4的阶乘4x3x2x1=24
#      递归实现阶乘计算
.section .data # 无全局数据

.section .text
.globl _start
.globl factorial # 计算阶乘函数为global, 可供其他程序链接调用

_start:
pushl $4
call factorial # 调用函数
addl $4, %esp # 恢复栈帧
movl %eax, %ebx # 将函数返回值复制到%ebx
# 调用exit系统调用
movl $1, %eax
int $0x80

# 递归函数, 返回阶乘结果
.type factorial, @function
factorial:
pushl %ebp # 保存旧的基址指针
movl %esp, %ebp # 基址指针指向当前栈顶
movl 8(%ebp), %eax # 获取输入参数

# 判断输入参数是否为1
cmpl $1, %eax
je end_factorial

# 递归调用n-1的阶乘
decl %eax
pushl %eax
call factorial

# 计算n*(n-1的阶乘)
movl 8(%ebp), %ebx
imull %ebx, %eax

end_factorial:
movl %ebp, %esp
popl %ebp
ret
