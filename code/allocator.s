# 目的：内存管理器， 按需分配和释放内存
# 内存样式如下，在实际内存前加上available标记和内存大小
# #############################################
# #Available标记#内存大小#实际内存位置#
# #############################################
#                      ^返回指针指向此处
.section .data
# 全局变量
heap_begin: # heap内存的起始处
  .long 0

current_break: # heap内存之后的一个内存位置
  .long 0

# 结构信息
.equ HEADER_SIZE, 8 # 内存块header大小
.equ HDR_AVAILABLE_OFFSET, 0 # available标记位置
.equ HDR_SIZE_OFFSET, 4 # 内存大小的位置

# 常量
.equ UNAVAILABLE, 0
.equ AVAILABLE, 1
.equ SYS_BRK, 45 # 系统调用号, 增加heap内存用
.equ LINUX_SYSCALL, 0x80

.section .text
# 初始化函数, 设置heap_begin和current_break
.globl allocate_init
.type allocate_init, @function
allocate_init:
pushl %ebp
movl %esp, %ebp
# brk系统调用, 参数0表示返回最后的有效内存地址, 不申请新的内存
movl $SYS_BRK, %eax
movl $0, %ebx
int $LINUX_SYSCALL

incl %eax # 加1之后时有效地址之后的内存位置
movl %eax, current_break
movl %eax, heap_begin # 当前位置就是heap的起始位置, 从内存布局图可知

movl %ebp, %esp
popl %ebp
ret

# alloc函数, 获取一段内存. 先检查是否有可用的内存块; 如不存在, 向Linux请求
# 输入参数: 申请内存块大小
# 返回值: 返回内存地址到%eax. 如申请失败返回0
# 用到的变量
#    %ecx: 保存请求的内存大小
#    %eax: 当前内存区
#    %ebx: 当前中断点位置
#    %edx: 当前内存区大小
# 思路: 检测每个以heap_begin开始的内存块, 查看每个块的大小和是否被使用.
#      如果某内存块大小>=要申请的大小, 且可用, 就返回该内存块.
#      如果没有合适的内存块, 旧向Linux申请, 并向前移动current_break
.globl allocate
.type allocate, @function
.equ ST_MEM_SIZE, 8 # 输入参数的栈帧位置
allocate:
pushl %ebp
movl %esp, %ebp

movl ST_MEM_SIZE(%ebp), %ecx # 获取输入参数
movl heap_begin, %eax
movl current_break, %ebx
# 循环每个内存块
alloca_loop_begin:
cmpl %ebx, %eax
je move_break # 当前搜索位置和当前中断点相等, 说明没有内存块, 需要向Linux申请

movl HDR_SIZE_OFFSET(%eax), %edx
cmpl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax)
je next_location # 当前内存块不可用, 继续搜索下一块

cmpl %edx, %ecx
jle allocate_here # 大小合适, 选择此内存块返回

next_location:
addl $HEADER_SIZE, %eax
addl %edx, %eax
jmp alloca_loop_begin # 偏移到下一个内存块, 偏移量为header和内存大小之和

allocate_here:
movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax)
addl $HEADER_SIZE, %eax # 返回内存块实际位置
movl %ebp, %esp
popl %ebp
ret

move_break:
# %ebx时当前中断点位置, 加上header和要申请的大小就是想要有效内存结束的位置
addl $HEADER_SIZE, %ebx
addl %ecx, %ebx
# 保存一下当前变量
pushl %eax
pushl %ecx
# brk系统调用, 申请重置中断点位置
pushl %ebx
movl $SYS_BRK, %eax
int $LINUX_SYSCALL
# 检查返回值
cmpl $0, %eax
je error # 返回0, 调用失败

popl %ebx
popl %ecx
popl %eax
# 设置当前内存块
movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax)
movl %ecx, HDR_SIZE_OFFSET(%eax)
addl $HEADER_SIZE, %eax # eax指向实际内存位置

movl %ebx, current_break # 更新中断点
movl %ebp, %esp
popl %ebp
ret

error:
movl $0, %eax
movl %ebp, %esp
popl %ebp
ret

# dealloca函数, 将内存返回内存池
# 输入参数: 要释放的内存地址
# 返回值: 无
# 思路: 输入的内存地址回退header的长度就是内存块的起始位置, 之后修改available标记
.globl deallocate
.type deallocate, @function
.equ ST_MEM_ADDR, 4 # 输入参数的栈帧位置
deallocate:
movl ST_MEM_ADDR(%esp), %eax
# 获取内存块起始地址
subl $HEADER_SIZE, %eax
# 标记为可用
movl $AVAILABLE, HDR_AVAILABLE_OFFSET(%eax)
ret
