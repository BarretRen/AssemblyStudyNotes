# 目的: 讲一个整数转换为十进制字符串, 打印到屏幕
.section .data
tmp_buffer:
  .ascii "\0\0\0\0\0\0\0\0\0\0\0"

.section .text
.globl int2str
.globl _start

# 目的: 将一个整数转换为适合显示的十进制字符串
# 输入参数: 存放结果的缓冲区, 待转换的整数
# 输出参数: 覆写缓冲区
# 变量:
#   %eax: 当前值
#   %ecx: 保存已处理的字符数
#   %edi: 保存基数10
.type int2str, @function
.equ ST_VALUE, 8
.equ ST_BUFFER, 12
int2str:
pushl %ebp
movl %esp, %ebp

movl $0, %ecx # 初始化当前已处理字符数
movl ST_VALUE(%ebp), %eax # 初始当前值为输入参数
movl $10, %edi # 基数10

convert_loop:
movl $0, %edx
# 使用divl作为除法, divl默认将%edx:%eax作为被除数
# 商保存在%eax, 余数保存在%edx
divl %edi

addl $'0', %edx # 将余数转换为可显示数字的ASCII码
pushl %edx # 放入栈中, 因为最后要倒序作为正确的顺序

incl %ecx
cmpl $0, %eax
je end_loop # 已经除尽, 结束循环

jmp convert_loop

end_loop:
movl ST_BUFFER(%ebp), %edx # 获取缓冲区

copy_result_loop:
popl %eax
movb %al, (%edx) # ASCII码只有8bit, 所以只需要ba%eax的低位%al放到缓冲区即可

decl %ecx
incl %edx

cmpl $0, %ecx
je end_copy_loop # 检查所有结果是否处理完成
jmp copy_result_loop

end_copy_loop:
movb $0, (%edx)

movl %ebp, %esp
popl %ebp
ret

_start:
movl %esp, %ebp

pushl $tmp_buffer
push $824
call int2str
addl $8, %esp

# 写入STDOUT, 打印到屏幕
movl $4, %eax
movl $1, %ebx # STDOUT
movl $tmp_buffer, %ecx
movl $3, %edx # hardcode 4
int $0x80

movl $1, %eax # 系统调用exit
movl $0, %ebx
int $0x80
