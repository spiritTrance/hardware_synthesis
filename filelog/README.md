# hardware_synthesis

- 替换step_into_mips_lab4_rtl下的文件

# 工作日志（？）

## 2023/1/1

- TODO：逻辑运算指令，把controller整合进datapath中
- 需要用到的资料：计组实验四的数据通路图，视频所给的参考代码，vivado下的README，硬综文档

错误记录：

1.在做逻辑移位运算时，修改后仿真波形图不能读取指令。经过排查，发现一个控制信号为高阻态Z，怀疑是某个地方未连线，于是按照连接逻辑添加波形，最后发现是一个触发器的flop在复位时就是高阻态，发现是触发器前面的可选参数位宽#()未更改，但ALU控制信号从计组的两位扩展到五位，导致没有连上。

## 2023/1/2

- 加入逻辑运算指令和移位指令（8+6）
- 看了HI和LO相关的数据移动指令，以及乘除法相关原理
- 将控制模块整合进datapath，mips模块相当于datapath的wrappper

错误记录：

在做算术移位时，使用>>>仍然没有做到有符号扩展。经过查阅资料，发现需要用系统函数$signed()表明相应数为有符号数。

## 2023/1/3

- 完成数据移位指令
  - 存在的疑问是，hiloreg前面的控制信号应该放在哪？这里采用的是E阶段的控制信号，原因是，如果用M的，那么相当于插了一级的流水线，时序可能出现问题，但不知道有没有bug，会不会是关键路径，先留着看看
- 加入运算指令
  - 但是没加成功，发现乘法不对，排查后发现是操作数因为前面停后面不停，加上前推逻辑导致跳变的问题。改为流水线一停全停的逻辑，发现还是有跳变，排查后发现是某个控制信号在跳变，经过检查，发现是controller还有部分流水线没有改。
  - 现在还有的问题是hi和lo没改，数据移位指令貌似在regfile里面写入了不该写的东西，然后除法还有问题？明天再看
  - 刚写完发现div模块用得不对，改出来了，但是HI和LO还是有问题，而且写进regfile了，明天再看

## 2023/1/4

考虑以下序列，是否会发生冒险：

```
# case 1
mfhi $2
mthi $2
mfhi $2
# case 2
mul $zero, $1, $2
mfhi $1
div $2, $1
```

在后期可能会引发bug，以及在原来的前推逻辑中，会不会引发错误的前推？会的，主要是mfxx指令引发的，解决方案是把hilo信号写进alu中，由aluoutM送出来，这样就可以不用更改之前的hazard逻辑。但现在的话，alu需要大改= =

改完了，然后没写进hilo的原因是发现写使能漏了乘除法，加了后就对了

JAL，JALR复用ex阶段的alu的好处是hazard不用改.

好了，报错了，寄了

## 2023/1/5

改出来发现分支指令别忘记signed有符号！！！然后j的话，是因为冲刷了延迟槽指令造成的，done。

突然想到个问题，延迟槽情况下，branch接branch怎么办？你觉得会出现这种情况吗？不会出现！延迟槽就是 把前面应该执行的指令，拿到后面来，不会出现这种情况

做个log：sw，lw，div有例外，记住

艹，字节写使能错了，以为永远是低两位

## 2023/1/6

一切都是片选信号的锅！！！注意访存地址以字节为单位，反映到波形图上仍然适用！！！

至此完成52条指令加成，相应代码在mips_cpu.zip下，因为涉及到datapath端口的修改（连接sram，在此做保存，目前最新的为连接sram的）

参考了视频里提供的代码，mycpu_top

好，分支跳转，像jr啥的有hazard，原来是没有的！！查出来了好起来了

hazard主要是stallD = stall F = flushE漏掉了jumpstallD和branchstallD

## 2023/1/7

继续，冒险！

```
bfc455d8:	3c08bd59 	lui	t0,0xbd59
bfc455dc:	350872d1 	ori	t0,t0,0x72d1
bfc455e0:	01000011 	mthi	t0
```

这个冒险好像有点逆天，但是原有逻辑解决了？？？还好，前两条冒险前推算出正确结果，然后mthi也是正确输入，结果是输入前的mux用了srcaE，用错信号了（没有数据前推）

然后卡到了52,0x10寄存器是23，0x08 800d0000 0x10 00000034

改出来的bug是：sxxv用的32位的扩展，但是只能有5位！！！

还是冒险

```
bfc051b8:	00800013 	mtlo	a0
bfc051bc:	0109001a 	div	zero,t0,t1
bfc051c0:	0000b012 	mflo	s6
```

找到问题了，修改后实际是wb才写hilo了，但是是有问题的！mflo前推不对，明天再改

半夜睡不着早上很早爬起来，随手把hilo改回来发现过了？？？？

## 57条整理

BadVAddr：更新：在MEM的lw，sw指令检测，IF阶段判断pcF的最低两位

Count：每两个时钟周期自增1，和compare寄存器相等时会除法时钟中断

Status：课读写，有字段，字段有含义

- bit = 15 - 8:每一位控制一个外部中断，有8位，1en，0屏蔽
- bit = 1：1例外，0正常，例外开启时，软硬件中断被屏蔽，EPC和CauseBD不更新
- bit = 0：0屏蔽所有中断，1使能中断

Cause：31：标识例外对应指令是否在延迟槽中；30：计时器中断；15-10：9-8：中断flag，6：2例外编码

EPC：指令读写。触发例外的指令位于延迟槽时，保存前一条指令地址，causeBD置为1，否则写入例外处理完成后继续执行的指令地址

## 指令

ERET没有延迟槽！！！刷掉pcF

细节问题：出现异常的指令不能访存，写HILO和寄存器堆！！

总体要做的：syscall和break类似，lw，sw，add，pcF有异常要处理，会涉及到改cause，mfc0和mtc0有hazard要处理，pc的跳转：发生异常到0xbfc00380，然后回来用EPC，注意eret没有延迟槽，这个是最特殊的一个哟，要flushD，刷掉后面跟上来的指令

统一到MEM阶段处理，注意HILO、dataMEM和regfile的写

溢出的判断：

注意MEM阶段后，flushW要有

## 2023/1/8

找到一个小细节：pcF例外也要保存pc的addr！

卡在第77个测试点，好像是时钟中断没做导致寄了

小细节：软中断直接写cp0，然后软中断的epc是mtc0的下一条指令。

硬中断和compare==count没接

## 2023/1/9

逆天，sram-like的握手信号，用的addr是addr_ok拉高期间的值

写很久的X发现是逻辑环路= =

又改了很久，好不容易改对点，发现要四个状态，剩下一个是流水线是否阻塞，阻塞就不发新的req

## 2023/1/11

改用verilator改错，主要是sram_to_sram_like写错了，mealy型状态机的always参数列表要加入输入，毕竟是mealy型状态机

最后的一点在于软中断那里，写使能要根据stallM来写

然后中间还改了很多，比较关键的是，前面的流水线stall了，后面的流水线大多数情况不能flush（其实这里搞的真的很头昏脑胀）

## 2023/1/12

axi阶段，vivado上不了板，报告是有组合逻辑环路，相当麻，verilator没报，但是vivado检测出来了。从报错信息除了组合逻辑环路根本得不到提示。只得自行梳理逻辑，首先从stall入手，这个因为都是组合逻辑描述，到处连线最容易出现环路。结果发现环路如下：

```verilog
sram_to_sram_like：stall

hazard：instInnerStallFlush =  ((lwstallD | branchstallD | jumpstallD) ~stallD) | isMulOrDivComputingE | haveExceptionE; 
	assign stallD = stallE | ((lwstallD | branchstallD | jumpstallD) & ~flushD);
	assign stallE = stallM;
	assign stallM = stallW;
	assign stallW = extStall | isMulOrDivComputingE;
```

注意到extStall就是sram_to_sram_like的stall，而stall的变化又取决于instInnerFlush的变化，因此出现了组合环路，尝试删掉instInnerStallFlush后，组合逻辑环路报告消失，可以产生比特流上版了，可以可以
