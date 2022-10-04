# 目的: 声明函数并调用, 计算2^3+5^2
# 主程序所有内容都保存在寄存器中, 不选数据段
# 32位程序, as和ld需要按32bit编译
.section .data

.section .text
.globl _start
_start:
# 计算2^3, 首先将两个函数参数入栈
pushl $3
pushl $2
call power # 调用power函数计算
addl $8, %esp #将_start的栈指针向栈底移动, 回到两个pushl之前的状态
pushl %eax # 将power的返回值入栈, 即2^3的结果

# 计算5^2
pushl $2
pushl $5
call power
addl $8, %esp #将_start的栈指针向栈底移动, 回到两个pushl之前的状态

popl %ebx # 取出2^3的结果
addl %eax, %ebx # 计算两个结果, 保存在%ebx中
# 调用系统调用exit, 退出程序
movl $1, %eax
int $0x80

# power函数定义, 计算一个数的幂
# 变量:
#   %ebx: 保存底数
#   %ecx: 保存指数
#   -4(%ebp): 保存当前结果
#   %eax: 暂存返回结果
.type power, @function
power:
pushl %ebp # 保存之前的基址指针
movl %esp, %ebp # 将基址指针设置为当前的栈指针
subl $4, %esp # 栈向下移动, 留出局部变量空间
# 将两个函数参数取出
movl 8(%ebp), %ebx
movl 12(%ebp), %ecx

movl %ebx, -4(%ebp) # 存储当前结果到局部变量

# 循环计算幂
_loop_start:
cmpl $1, %ecx # 比较指数, 如果是1则不需要再计算了
je end_power
movl -4(%ebp), %eax
imull %ebx, %eax # 当前结果与底数相乘
movl %eax, -4(%ebp) # 当前结果再保存到局部变量
decl %ecx # 指数-1
jmp _loop_start # 继续循环

end_power:
movl -4(%ebp), %eax # 最终结果存入%eax
movl %ebp, %esp # 恢复栈指针
popl %ebp # 恢复基址指针
ret
