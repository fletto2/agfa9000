; ======================================================================
; AGFA COMPUGRAPHIC 9000PS - BANK3 ANNOTATED DISASSEMBLY
; Seventh Pass - LLM Refined Analysis (builds on v6)
; ======================================================================
; PostScript: fixed-point math, glyph rendering, PS operators, file I/O
; ROM addresses: 0x60000 - 0x7FFFF
; Chunk size: 0xC00 bytes
; ======================================================================


; === CHUNK 1: 0x60000-0x60C00 (LLM error) ===


/home/fletto/ext/src/claude/agfa9000/3.bin:     file format binary


Disassembly of section .data:

00000000 <.data>:
       60000:	558c           	subql #2,%a4
       60002:	4a47           	tstw %d7
       60004:	6cde           	bges 0xffffffe4
       60006:	302e fffe      	movew %fp@(-2),%d0
       6000a:	48c0           	extl %d0
       6000c:	4cee 3080 fff0 	moveml %fp@(-16),%d7/%a4-%a5
      60012:	4e5e           	unlk %fp
      60014:	4e75           	rts
      60016:	4e56 ffe8      	linkw %fp,#-24
      6001a:	48d7 38e0      	moveml %d5-%d7/%a3-%a5,%sp@
      6001e:	7a00           	moveq #0,%d5
      60020:	2a6e 0008      	moveal %fp@(8),%a5
      60024:	548d           	addql #2,%a5
      60026:	286e 000c      	moveal %fp@(12),%a4
      6002a:	548c           	addql #2,%a4
      6002c:	266e 0010      	moveal %fp@(16),%a3
      60030:	548b           	addql #2,%a3
      60032:	7e00           	moveq #0,%d7
      60034:	7c00           	moveq #0,%d6
      60036:	3c1d           	movew %a5@+,%d6
      60038:	7200           	moveq #0,%d1
      6003a:	321c           	movew %a4@+,%d1
      6003c:	dc81           	addl %d1,%d6
      6003e:	dc85           	addl %d5,%d6
      60040:	36c6           	movew %d6,%a3@+
      60042:	7000           	moveq #0,%d0
      60044:	0c86 0000 ffff 	cmpil #65535,%d6
      6004a:	5ec0           	sgt %d0
      6004c:	4400           	negb %d0
      6004e:	2a00           	movel %d0,%d5
      60050:	5247           	addqw #1,%d7
      60052:	0c47 0004      	cmpiw #4,%d7
      60056:	6ddc           	blts 0x34
      60058:	206e 0010      	moveal %fp@(16),%a0
      6005c:	30bc 0001      	movew #1,%a0@
      60060:	4cee 38e0 ffe8 	moveml %fp@(-24),%d5-%d7/%a3-%a5
      60066:	4e5e           	unlk %fp
      60068:	4e75           	rts
      6006a:	4e56 ffe8      	linkw %fp,#-24
      6006e:	48d7 38e0      	moveml %d5-%d7/%a3-%a5,%sp@
      60072:	7a00           	moveq #0,%d5
      60074:	2a6e 0008      	moveal %fp@(8),%a5
      60078:	548d           	addql #2,%a5
      6007a:	286e 000c      	moveal %fp@(12),%a4
      6007e:	548c           	addql #2,%a4
      60080:	266e 0010      	moveal %fp@(16),%a3
      60084:	548b           	addql #2,%a3
      60086:	7e00           	moveq #0,%d7
      60088:	7c00           	moveq #0,%d6
      6008a:	3c1d           	movew %a5@+,%d6
      6008c:	7200           	moveq #0,%d1
      6008e:	321c           	movew %a4@+,%d1
      60090:	9c81           	subl %d1,%d6
      60092:	9c85           	subl %d5,%d6
      60094:	36c6           	movew %d6,%a3@+
      60096:	7000           	moveq #0,%d0
      60098:	4a86           	tstl %d6
      6009a:	5dc0           	slt %d0
      6009c:	4400           	negb %d0
      6009e:	2a00           	movel %d0,%d5
      600a0:	5247           	addqw #1,%d7
      600a2:	0c47 0004      	cmpiw #4,%d7
      600a6:	6de0           	blts 0x88
      600a8:	206e 0010      	moveal %fp@(16),%a0
      600ac:	30bc 0001      	movew #1,%a0@
      600b0:	4cee 38e0 ffe8 	moveml %fp@(-24),%d5-%d7/%a3-%a5
      600b6:	4e5e           	unlk %fp
      600b8:	4e75           	rts
      600ba:	4e56 fff8      	linkw %fp,#-8
      600be:	206e 000c      	moveal %fp@(12),%a0
      600c2:	226e 0008      	moveal %fp@(8),%a1
      600c6:	3011           	movew %a1@,%d0
      600c8:	b050           	cmpw %a0@,%d0
      600ca:	661c           	bnes 0xe8
      600cc:	2f2e 0010      	movel %fp@(16),%sp@-
      600d0:	2f08           	movel %a0,%sp@-
      600d2:	2f09           	movel %a1,%sp@-
      600d4:	6100 ff40      	bsrw 0x16
      600d8:	4fef 000c      	lea %sp@(12),%sp
      600dc:	206e 0010      	moveal %fp@(16),%a0
      600e0:	226e 0008      	moveal %fp@(8),%a1
      600e4:	3091           	movew %a1@,%a0@
      600e6:	605c           	bras 0x144
      600e8:	2f2e 000c      	movel %fp@(12),%sp@-
      600ec:	2f2e 0008      	movel %fp@(8),%sp@-
      600f0:	6100 fed6      	bsrw 0xffffffc8
      600f4:	504f           	addqw #8,%sp
      600f6:	48c0           	extl %d0
      600f8:	72ff           	moveq #-1,%d1
      600fa:	b081           	cmpl %d1,%d0
      600fc:	674a           	beqs 0x148
      600fe:	4a80           	tstl %d0
     60100:	6754           	beqs 0x156
     60102:	7201           	moveq #1,%d1
     60104:	b081           	cmpl %d1,%d0
     60106:	6774           	beqs 0x17c
     60108:	2f2e 0010      	movel %fp@(16),%sp@-
     6010c:	2f2e fffc      	movel %fp@(-4),%sp@-
     60110:	2f2e fff8      	movel %fp@(-8),%sp@-
     60114:	6100 ff54      	bsrw 0x6a
     60118:	4fef 000c      	lea %sp@(12),%sp
     6011c:	206e 0008      	moveal %fp@(8),%a0
     60120:	4a50           	tstw %a0@
     60122:	6c08           	bges 0x12c
     60124:	202e fff8      	movel %fp@(-8),%d0
     60128:	b088           	cmpl %a0,%d0
     6012a:	6710           	beqs 0x13c
     6012c:	206e 0008      	moveal %fp@(8),%a0
     60130:	4a50           	tstw %a0@
     60132:	6f10           	bles 0x144
     60134:	202e fffc      	movel %fp@(-4),%d0
     60138:	b088           	cmpl %a0,%d0
     6013a:	6608           	bnes 0x144
     6013c:	206e 0010      	moveal %fp@(16),%a0
     60140:	30bc ffff      	movew #-1,%a0@
     60144:	4e5e           	unlk %fp
     60146:	4e75           	rts
     60148:	2d6e 0008 fffc 	movel %fp@(8),%fp@(-4)
     6014e:	2d6e 000c fff8 	movel %fp@(12),%fp@(-8)
     60154:	60b2           	bras 0x108
     60156:	206e 0010      	moveal %fp@(16),%a0
     6015a:	30bc 0001      	movew #1,%a0@
     6015e:	206e 0010      	moveal %fp@(16),%a0
     60162:	4268 0008      	clrw %a0@(8)
     60166:	4268 0006      	clrw %a0@(6)
     6016a:	206e 0010      	moveal %fp@(16),%a0
     6016e:	4268 0004      	clrw %a0@(4)
     60172:	206e 0010      	moveal %fp@(16),%a0
     60176:	4268 0002      	clrw %a0@(2)
     6017a:	60c8           	bras 0x144
     6017c:	2d6e 000c fffc 	movel %fp@(12),%fp@(-4)
     60182:	2d6e 0008 fff8 	movel %fp@(8),%fp@(-8)
     60188:	6000 ff7e      	braw 0x108
     6018c:	4e56 fff8      	linkw %fp,#-8
     60190:	206e 000c      	moveal %fp@(12),%a0
     60194:	226e 0008      	moveal %fp@(8),%a1
     60198:	3011           	movew %a1@,%d0
     6019a:	b050           	cmpw %a0@,%d0
     6019c:	671e           	beqs 0x1bc
     6019e:	2f2e 0010      	movel %fp@(16),%sp@-
     601a2:	2f08           	movel %a0,%sp@-
     601a4:	2f09           	movel %a1,%sp@-
     601a6:	6100 fe6e      	bsrw 0x16
     601aa:	4fef 000c      	lea %sp@(12),%sp
     601ae:	206e 0010      	moveal %fp@(16),%a0
     601b2:	226e 0008      	moveal %fp@(8),%a1
     601b6:	3091           	movew %a1@,%a0@
     601b8:	6000 00a4      	braw 0x25e
     601bc:	2f2e 000c      	movel %fp@(12),%sp@-
     601c0:	2f2e 0008      	movel %fp@(8),%sp@-
     601c4:	6100 fe02      	bsrw 0xffffffc8
     601c8:	504f           	addqw #8,%sp
     601ca:	48c0           	extl %d0
     601cc:	72ff           	moveq #-1,%d1
     601ce:	b081           	cmpl %d1,%d0
     601d0:	6720           	beqs 0x1f2
     601d2:	4a80           	tstl %d0
     601d4:	672a           	beqs 0x200
     601d6:	7201           	moveq #1,%d1
     601d8:	b081           	cmpl %d1,%d0
     601da:	674a           	beqs 0x226
     601dc:	6054           	bras 0x232
     601de:	202e fffc      	movel %fp@(-4),%d0
     601e2:	b0ae 0008      	cmpl %fp@(8),%d0
     601e6:	6676           	bnes 0x25e
     601e8:	206e 0010      	moveal %fp@(16),%a0
     601ec:	30bc ffff      	movew #-1,%a0@
     601f0:	606c           	bras 0x25e
     601f2:	2d6e 0008 fffc 	movel %fp@(8),%fp@(-4)
     601f8:	2d6e 000c fff8 	movel %fp@(12),%fp@(-8)
     601fe:	6032           	bras 0x232
     60200:	206e 0010      	moveal %fp@(16),%a0
     60204:	30bc 0001      	movew #1,%a0@
     60208:	206e 0010      	moveal %fp@(16),%a0
     6020c:	4268 0008      	clrw %a0@(8)
     60210:	4268 0006      	clrw %a0@(6)
     60214:	206e 0010      	moveal %fp@(16),%a0
     60218:	4268 0004      	clrw %a0@(4)
     6021c:	206e 0010      	moveal %fp@(16),%a0
     60220:	4268 0002      	clrw %a0@(2)
     60224:	6038           	bras 0x25e
     60226:	2d6e 000c fffc 	movel %fp@(12),%fp@(-4)
     6022c:	2d6e 0008 fff8 	movel %fp@(8),%fp@(-8)
     60232:	2f2e 0010      	movel %fp@(16),%sp@-
     60236:	2f2e fffc      	movel %fp@(-4),%sp@-
     6023a:	2f2e fff8      	movel %fp@(-8),%sp@-
     6023e:	6100 fe2a      	bsrw 0x6a
     60242:	4fef 000c      	lea %sp@(12),%sp
     60246:	206e 0008      	moveal %fp@(8),%a0
     6024a:	4a50           	tstw %a0@
     6024c:	6c08           	bges 0x256
     6024e:	202e fff8      	movel %fp@(-8),%d0
     60252:	b088           	cmpl %a0,%d0
     60254:	6792           	beqs 0x1e8
     60256:	206e 0008      	moveal %fp@(8),%a0
     6025a:	4a50           	tstw %a0@
     6025c:	6e80           	bgts 0x1de
     6025e:	4e5e           	unlk %fp
     60260:	4e75           	rts
     60262:	4e56 ffe0      	linkw %fp,#-32
     60266:	48d7 20fc      	moveml %d2-%d7/%a5,%sp@
     6026a:	202e 0010      	movel %fp@(16),%d0
     6026e:	5480           	addql #2,%d0
     60270:	2a40           	moveal %d0,%a5
     60272:	425d           	clrw %a5@+
     60274:	425d           	clrw %a5@+
     60276:	425d           	clrw %a5@+
     60278:	4255           	clrw %a5@
     6027a:	206e 0010      	moveal %fp@(16),%a0
     6027e:	30bc 0001      	movew #1,%a0@
     60282:	4aae 0008      	tstl %fp@(8)
     60286:	6700 00bc      	beqw 0x344
     6028a:	4aae 000c      	tstl %fp@(12)
     6028e:	6700 00b4      	beqw 0x344
     60292:	382e 000a      	movew %fp@(10),%d4
     60296:	202e 0008      	movel %fp@(8),%d0
     6029a:	7210           	moveq #16,%d1
     6029c:	e2a8           	lsrl %d1,%d0
     6029e:	3600           	movew %d0,%d3
     602a0:	342e 000e      	movew %fp@(14),%d2
     602a4:	202e 000c      	movel %fp@(12),%d0
     602a8:	7210           	moveq #16,%d1
     602aa:	e2a8           	lsrl %d1,%d0
     602ac:	3d40 fffe      	movew %d0,%fp@(-2)
     602b0:	7e00           	moveq #0,%d7
     602b2:	3e04           	movew %d4,%d7
     602b4:	7000           	moveq #0,%d0
     602b6:	3002           	movew %d2,%d0
     602b8:	4c00 7007      	mulul %d0,%d7
     602bc:	2a6e 0010      	moveal %fp@(16),%a5
     602c0:	548d           	addql #2,%a5
     602c2:	3ac7           	movew %d7,%a5@+
     602c4:	7210           	moveq #16,%d1
     602c6:	e2af           	lsrl %d1,%d7
     602c8:	3a87           	movew %d7,%a5@
     602ca:	7e00           	moveq #0,%d7
     602cc:	3e03           	movew %d3,%d7
     602ce:	7000           	moveq #0,%d0
     602d0:	3002           	movew %d2,%d0
     602d2:	4c00 7007      	mulul %d0,%d7
     602d6:	7000           	moveq #0,%d0
     602d8:	3015           	movew %a5@,%d0
     602da:	7200           	moveq #0,%d1
     602dc:	3207           	movew %d7,%d1
     602de:	d081           	addl %d1,%d0
     602e0:	3a80           	movew %d0,%a5@
     602e2:	7210           	moveq #16,%d1
     602e4:	e2af           	lsrl %d1,%d7
     602e6:	3b47 0002      	movew %d7,%a5@(2)
     602ea:	7210           	moveq #16,%d1
     602ec:	e2a8           	lsrl %d1,%d0
     602ee:	d16d 0002      	addw %d0,%a5@(2)
     602f2:	4a6e fffe      	tstw %fp@(-2)
     602f6:	674c           	beqs 0x344
     602f8:	7e00           	moveq #0,%d7
     602fa:	3e04           	movew %d4,%d7
     602fc:	7000           	moveq #0,%d0
     602fe:	302e fffe      	movew %fp@(-2),%d0
     60302:	4c00 7007      	mulul %d0,%d7
     60306:	7000           	moveq #0,%d0
     60308:	3015           	movew %a5@,%d0
     6030a:	7200           	moveq #0,%d1
     6030c:	3207           	movew %d7,%d1
     6030e:	d081           	addl %d1,%d0
     60310:	3ac0           	movew %d0,%a5@+
     60312:	7210           	moveq #16,%d1
     60314:	e2af           	lsrl %d1,%d7
     60316:	df55           	addw %d7,%a5@
     60318:	7210           	moveq #16,%d1
     6031a:	e2a8           	lsrl %d1,%d0
     6031c:	d155           	addw %d0,%a5@
     6031e:	7e00           	moveq #0,%d7
     60320:	3e03           	movew %d3,%d7
     60322:	7000           	moveq #0,%d0
     60324:	302e fffe      	movew %fp@(-2),%d0
     60328:	4c00 7007      	mulul %d0,%d7
     6032c:	7000           	moveq #0,%d0
     6032e:	3015           	movew %a5@,%d0
     60330:	7200           	moveq #0,%d1
     60332:	3207           	movew %d7,%d1
     60334:	d081           	addl %d1,%d0
     60336:	3ac0           	movew %d0,%a5@+
     60338:	7210           	moveq #16,%d1
     6033a:	e2af           	lsrl %d1,%d7
     6033c:	3a87           	movew %d7,%a5@
     6033e:	7210           	moveq #16,%d1
     60340:	e2a8           	lsrl %d1,%d0
     60342:	d155           	addw %d0,%a5@
     60344:	4cee 20fc ffe0 	moveml %fp@(-32),%d2-%d7/%a5
     6034a:	4e5e           	unlk %fp
     6034c:	4e75           	rts
     6034e:	4e56 0000      	linkw %fp,#0
     60352:	2f2e 0010      	movel %fp@(16),%sp@-
     60356:	4aae 000c      	tstl %fp@(12)
     6035a:	6c08           	bges 0x364
     6035c:	202e 000c      	movel %fp@(12),%d0
     60360:	4480           	negl %d0
     60362:	6004           	bras 0x368
     60364:	202e 000c      	movel %fp@(12),%d0
     60368:	2f00           	movel %d0,%sp@-
     6036a:	4aae 0008      	tstl %fp@(8)
     6036e:	6c08           	bges 0x378
     60370:	202e 0008      	movel %fp@(8),%d0
     60374:	4480           	negl %d0
     60376:	6004           	bras 0x37c
     60378:	202e 0008      	movel %fp@(8),%d0
     6037c:	2f00           	movel %d0,%sp@-
     6037e:	6100 fee2      	bsrw 0x262
     60382:	4fef 000c      	lea %sp@(12),%sp
     60386:	4aae 0008      	tstl %fp@(8)
     6038a:	6726           	beqs 0x3b2
     6038c:	4aae 000c      	tstl %fp@(12)
     60390:	6720           	beqs 0x3b2
     60392:	7000           	moveq #0,%d0
     60394:	4aae 0008      	tstl %fp@(8)
     60398:	5dc0           	slt %d0
     6039a:	4400           	negb %d0
     6039c:	7200           	moveq #0,%d1
     6039e:	4aae 000c      	tstl %fp@(12)
     603a2:	5dc1           	slt %d1
     603a4:	4401           	negb %d1
     603a6:	b081           	cmpl %d1,%d0
     603a8:	6708           	beqs 0x3b2
     603aa:	206e 0010      	moveal %fp@(16),%a0
     603ae:	30bc ffff      	movew #-1,%a0@
     603b2:	4e5e           	unlk %fp
     603b4:	4e75           	rts
     603b6:	4e56 ffc0      	linkw %fp,#-64
     603ba:	4aae 000c      	tstl %fp@(12)
     603be:	6606           	bnes 0x3c6
     603c0:	61ff 0002 6068 	bsrl 0x2642a
     603c6:	4aae 000c      	tstl %fp@(12)
     603ca:	6f06           	bles 0x3d2
     603cc:	202e 000c      	movel %fp@(12),%d0
     603d0:	6006           	bras 0x3d8
     603d2:	202e 000c      	movel %fp@(12),%d0
     603d6:	4480           	negl %d0
     603d8:	2d40 fff8      	movel %d0,%fp@(-8)
     603dc:	3d6e fffa fffe 	movew %fp@(-6),%fp@(-2)
     603e2:	7210           	moveq #16,%d1
     603e4:	e2a8           	lsrl %d1,%d0
     603e6:	3d40 fffc      	movew %d0,%fp@(-4)
     603ea:	206e 0008      	moveal %fp@(8),%a0
     603ee:	3028 0006      	movew %a0@(6),%d0
     603f2:	e048           	lsrw #8,%d0
     603f4:	1d40 ffe7      	moveb %d0,%fp@(-25)
     603f8:	670a           	beqs 0x404
     603fa:	7230           	moveq #48,%d1
     603fc:	2d41 ffcc      	movel %d1,%fp@(-52)
     60400:	6000 0094      	braw 0x496
     60404:	206e 0008      	moveal %fp@(8),%a0
     60408:	3028 0006      	movew %a0@(6),%d0
     6040c:	1d40 ffe7      	moveb %d0,%fp@(-25)
     60410:	6708           	beqs 0x41a
     60412:	7228           	moveq #40,%d1
     60414:	2d41 ffcc      	movel %d1,%fp@(-52)
     60418:	607c           	bras 0x496
     6041a:	206e 0008      	moveal %fp@(8),%a0
     6041e:	3028 0004      	movew %a0@(4),%d0
     60422:	e048           	lsrw #8,%d0
     60424:	1d40 ffe7      	moveb %d0,%fp@(-25)
     60428:	6708           	beqs 0x432
     6042a:	7220           	moveq #32,%d1
     6042c:	2d41 ffcc      	movel %d1,%fp@(-52)
     60430:	6064           	bras 0x496
     60432:	206e 0008      	moveal %fp@(8),%a0
     60436:	3028 0004      	movew %a0@(4),%d0
     6043a:	1d40 ffe7      	moveb %d0,%fp@(-25)
     6043e:	6708           	beqs 0x448
     60440:	7218           	moveq #24,%d1
     60442:	2d41 ffcc      	movel %d1,%fp@(-52)
     60446:	604e           	bras 0x496
     60448:	206e 0008      	moveal %fp@(8),%a0
     6044c:	3028 0002      	movew %a0@(2),%d0
     60450:	e048           	lsrw #8,%d0
     60452:	1d40 ffe7      	moveb %d0,%fp@(-25)
     60456:	6708           	beqs 0x460
     60458:	7210           	moveq #16,%d1
     6045a:	2d41 ffcc      	movel %d1,%fp@(-52)
     6045e:	6036           	bras 0x496
     60460:	206e 0008      	moveal %fp@(8),%a0
     60464:	3028 0002      	movew %a0@(2),%d0
     60468:	1d40 ffe7      	moveb %d0,%fp@(-25)
     6046c:	6708           	beqs 0x476
     6046e:	7208           	moveq #8,%d1
     60470:	2d41 ffcc      	movel %d1,%fp@(-52)
     60474:	6020           	bras 0x496
     60476:	206e 0010      	moveal %fp@(16),%a0
     6047a:	42a8 0004      	clrl %a0@(4)
     6047e:	206e 0010      	moveal %fp@(16),%a0
     60482:	4290           	clrl %a0@
     60484:	6000 0222      	braw 0x6a8
     60488:	102e ffe7      	moveb %fp@(-25),%d0
     6048c:	e300           	aslb #1,%d0
     6048e:	1d40 ffe7      	moveb %d0,%fp@(-25)
     60492:	53ae ffcc      	subql #1,%fp@(-52)
     60496:	4a2e ffe7      	tstb %fp@(-25)
     6049a:	6eec           	bgts 0x488
     6049c:	302e fffc      	movew %fp@(-4),%d0
     604a0:	e048           	lsrw #8,%d0
     604a2:	1d40 ffe7      	moveb %d0,%fp@(-25)
     604a6:	6708           	beqs 0x4b0
     604a8:	7220           	moveq #32,%d1
     604aa:	2d41 ffc8      	movel %d1,%fp@(-56)
     604ae:	6040           	bras 0x4f0
     604b0:	1d6e fffd ffe7 	moveb %fp@(-3),%fp@(-25)
     604b6:	6708           	beqs 0x4c0
     604b8:	7218           	moveq #24,%d1
     604ba:	2d41 ffc8      	movel %d1,%fp@(-56)
     604be:	6030           	bras 0x4f0
     604c0:	302e fffe      	movew %fp@(-2),%d0
     604c4:	e048           	lsrw #8,%d0
     604c6:	1d40 ffe7      	moveb %d0,%fp@(-25)
     604ca:	6708           	beqs 0x4d4
     604cc:	7210           	moveq #16,%d1
     604ce:	2d41 ffc8      	movel %d1,%fp@(-56)
     604d2:	601c           	bras 0x4f0
     604d4:	1d6e ffff ffe7 	moveb %fp@(-1),%fp@(-25)
     604da:	7208           	moveq #8,%d1
     604dc:	2d41 ffc8      	movel %d1,%fp@(-56)
     604e0:	600e           	bras 0x4f0
     604e2:	102e ffe7      	moveb %fp@(-25),%d0
     604e6:	e300           	aslb #1,%d0
     604e8:	1d40 ffe7      	moveb %d0,%fp@(-25)
     604ec:	53ae ffc8      	subql #1,%fp@(-56)
     604f0:	4a2e ffe7      	tstb %fp@(-25)
     604f4:	6eec           	bgts 0x4e2
     604f6:	202e ffcc      	movel %fp@(-52),%d0
     604fa:	90ae ffc8      	subl %fp@(-56),%d0
     604fe:	7210           	moveq #16,%d1
     60500:	b081           	cmpl %d1,%d0
     60502:	6d0c           	blts 0x510
     60504:	206e 0010      	moveal %fp@(16),%a0
     60508:	42a8 0008      	clrl %a0@(8)
     6050c:	6000 01a4      	braw 0x6b2
     60510:	206e 0008      	moveal %fp@(8),%a0
     60514:	3d50 ffc2      	movew %a0@,%fp@(-62)
     60518:	0cae 0000 0010 	cmpil #16,%fp@(-56)
     6051e:	ffc8 
     60520:	6e3a           	bgts 0x55c
     60522:	7000           	moveq #0,%d0
     60524:	3028 0004      	movew %a0@(4),%d0
     60528:	7210           	moveq #16,%d1
     6052a:	e3a8           	lsll %d1,%d0
     6052c:	7200           	moveq #0,%d1
     6052e:	3228 0002      	movew %a0@(2),%d1
     60532:	d081           	addl %d1,%d0
     60534:	2d40 fff0      	movel %d0,%fp@(-16)
     60538:	4c6e 0000 fff8 	divull %fp@(-8),%d0,%d0
     6053e:	206e 0010      	moveal %fp@(16),%a0
     60542:	2080           	movel %d0,%a0@
     60544:	4c2e 0000 fff8 	mulul %fp@(-8),%d0
     6054a:	222e fff0      	movel %fp@(-16),%d1
     6054e:	9280           	subl %d0,%d1
     60550:	206e 0010      	moveal %fp@(16),%a0
     60554:	2141 0004      	movel %d1,%a0@(4)
     60558:	6000 00e8      	braw 0x642
     6055c:	7020           	moveq #32,%d0
     6055e:	90ae ffc8      	subl %fp@(-56),%d0
     60562:	2d40 ffc4      	movel %d0,%fp@(-60)
     60566:	206e 0008      	moveal %fp@(8),%a0
     6056a:	7000           	moveq #0,%d0
     6056c:	3028 0006      	movew %a0@(6),%d0
     60570:	7210           	moveq #16,%d1
     60572:	e3a8           	lsll %d1,%d0
     60574:	7200           	moveq #0,%d1
     60576:	3228 0004      	movew %a0@(4),%d1
     6057a:	d081           	addl %d1,%d0
     6057c:	2d40 fff0      	movel %d0,%fp@(-16)
     60580:	322e ffc6      	movew %fp@(-58),%d1
     60584:	e3a8           	lsll %d1,%d0
     60586:	2d40 fff0      	movel %d0,%fp@(-16)
     6058a:	0280 ffff 0000 	andil #-65536,%d0
     60590:	2d40 ffec      	movel %d0,%fp@(-20)
     60594:	7000           	moveq #0,%d0
     60596:	3028 0004      	movew %a0@(4),%d0
     6059a:	7210           	moveq #16,%d1
     6059c:	e3a8           	lsll %d1,%d0
     6059e:	7200           	moveq #0,%d1
     605a0:	3228 0002      	movew %a0@(2),%d1
     605a4:	d081           	addl %d1,%d0
     605a6:	2d40 fff0      	movel %d0,%fp@(-16)
     605aa:	322e ffc6      	movew %fp@(-58),%d1
     605ae:	e3a8           	lsll %d1,%d0
     605b0:	2d40 fff0      	movel %d0,%fp@(-16)
     605b4:	7210           	moveq #16,%d1
     605b6:	e2a8           	lsrl %d1,%d0
     605b8:	2d40 ffe8      	movel %d0,%fp@(-24)
     605bc:	7010           	moveq #16,%d0
     605be:	90ae ffc4      	subl %fp@(-60),%d0
     605c2:	222e fff8      	movel %fp@(-8),%d1
     605c6:	e0a9           	lsrl %d0,%d1
     605c8:	3d41 fffc      	movew %d1,%fp@(-4)
     605cc:	202e ffec      	movel %fp@(-20),%d0
     605d0:	d0ae ffe8      	addl %fp@(-24),%d0
     605d4:	2d40 fff0      	movel %d0,%fp@(-16)
     605d8:	7000           	moveq #0,%d0
     605da:	3001           	movew %d1,%d0
     605dc:	222e fff0      	movel %fp@(-16),%d1
     605e0:	4c40 1001      	divull %d0,%d1,%d1
     605e4:	2d41 fff4      	movel %d1,%fp@(-12)
     605e8:	30bc 0001      	movew #1,%a0@
     605ec:	6004           	bras 0x5f2
     605ee:	53ae fff4      	subql #1,%fp@(-12)
     605f2:	486e ffd0      	pea %fp@(-48)
     605f6:	2f2e fff4      	movel %fp@(-12),%sp@-
     605fa:	2f2e fff8      	movel %fp@(-8),%sp@-
     605fe:	6100 fc62      	bsrw 0x262
     60602:	4fef 000c      	lea %sp@(12),%sp
     60606:	486e ffdc      	pea %fp@(-36)
     6060a:	486e ffd0      	pea %fp@(-48)
     6060e:	2f2e 0008      	movel %fp@(8),%sp@-
     60612:	6100 fb78      	bsrw 0x18c
     60616:	4fef 000c      	lea %sp@(12),%sp
     6061a:	4a6e ffdc      	tstw %fp@(-36)
     6061e:	6dce           	blts 0x5ee
     60620:	206e 0010      	moveal %fp@(16),%a0
     60624:	20ae fff4      	movel %fp@(-12),%a0@
     60628:	206e 0010      	moveal %fp@(16),%a0
     6062c:	7000           	moveq #0,%d0
     6062e:	302e ffe0      	movew %fp@(-32),%d0
     60632:	7210           	moveq #16,%d1
     60634:	e3a8           	lsll %d1,%d0
     60636:	7200           	moveq #0,%d1
     60638:	322e ffde      	movew %fp@(-34),%d1
     6063c:	d081           	addl %d1,%d0
     6063e:	2140 0004      	movel %d0,%a0@(4)
     60642:	206e 0010      	moveal %fp@(16),%a0
     60646:	216e fff8 0008 	movel %fp@(-8),%a0@(8)
     6064c:	7000           	moveq #0,%d0
     6064e:	4a6e ffc2      	tstw %fp@(-62)
     60652:	5ec0           	sgt %d0
     60654:	4400           	negb %d0
     60656:	7200           	moveq #0,%d1
     60658:	4aae 000c      	tstl %fp@(12)
     6065c:	5ec1           	sgt %d1
     6065e:	4401           	negb %d1
     60660:	b081           	cmpl %d1,%d0
     60662:	6730           	beqs 0x694
     60664:	206e 0010      	moveal %fp@(16),%a0
     60668:	2010           	movel %a0@,%d0
     6066a:	4480           	negl %d0
     6066c:	5380           	subql #1,%d0
     6066e:	2080           	movel %d0,%a0@
     60670:	206e 0010      	moveal %fp@(16),%a0
     60674:	2028 0008      	movel %a0@(8),%d0
     60678:	90a8 0004      	subl %a0@(4),%d0
     6067c:	2140 0004      	movel %d0,%a0@(4)
     60680:	6012           	bras 0x694
     60682:	206e 0010      	moveal %fp@(16),%a0
     60686:	5290           	addql #1,%a0@
     60688:	206e 0010      	moveal %fp@(16),%a0
     6068c:	2028 0008      	movel %a0@(8),%d0
     60690:	91a8 0004      	subl %d0,%a0@(4)
     60694:	206e 0010      	moveal %fp@(16),%a0
     60698:	2028 0004      	movel %a0@(4),%d0
     6069c:	b0a8 0008      	cmpl %a0@(8),%d0
     606a0:	64e0           	bccs 0x682
     606a2:	4aa8 0004      	tstl %a0@(4)
     606a6:	660a           	bnes 0x6b2
     606a8:	206e 0010      	moveal %fp@(16),%a0
     606ac:	7201           	moveq #1,%d1
     606ae:	2141 0008      	movel %d1,%a0@(8)
     606b2:	4e5e           	unlk %fp
     606b4:	4e75           	rts
     606b6:	4e56 ffe8      	linkw %fp,#-24
     606ba:	206e 000c      	moveal %fp@(12),%a0
     606be:	226e 0008      	moveal %fp@(8),%a1
     606c2:	2011           	movel %a1@,%d0
     606c4:	b090           	cmpl %a0@,%d0
     606c6:	670e           	beqs 0x6d6
     606c8:	2011           	movel %a1@,%d0
     606ca:	b090           	cmpl %a0@,%d0
     606cc:	6c04           	bges 0x6d2
     606ce:	70ff           	moveq #-1,%d0
     606d0:	604a           	bras 0x71c
     606d2:	7001           	moveq #1,%d0
     606d4:	6046           	bras 0x71c
     606d6:	486e fff4      	pea %fp@(-12)
     606da:	206e 000c      	moveal %fp@(12),%a0
     606de:	2f28 0008      	movel %a0@(8),%sp@-
     606e2:	206e 0008      	moveal %fp@(8),%a0
     606e6:	2f28 0004      	movel %a0@(4),%sp@-
     606ea:	6100 fb76      	bsrw 0x262
     606ee:	4fef 000c      	lea %sp@(12),%sp
     606f2:	486e ffe8      	pea %fp@(-24)
     606f6:	206e 0008      	moveal %fp@(8),%a0
     606fa:	2f28 0008      	movel %a0@(8),%sp@-
     606fe:	206e 000c      	moveal %fp@(12),%a0
     60702:	2f28 0004      	movel %a0@(4),%sp@-
     60706:	6100 fb5a      	bsrw 0x262
     6070a:	4fef 000c      	lea %sp@(12),%sp
     6070e:	486e ffe8      	pea %fp@(-24)
     60712:	486e fff4      	pea %fp@(-12)
     60716:	6100 f8b0      	bsrw 0xffffffc8
     6071a:	504f           	addqw #8,%sp
     6071c:	48c0           	extl %d0
     6071e:	4e5e           	unlk %fp
     60720:	4e75           	rts
     60722:	4e56 0000      	linkw %fp,#0
     60726:	7000           	moveq #0,%d0
     60728:	3039 0200 d0cc 	movew 0x200d0cc,%d0
     6072e:	7200           	moveq #0,%d1
     60730:	3239 0200 d0dc 	movew 0x200d0dc,%d1
     60736:	e489           	lsrl #2,%d1
     60738:	b081           	cmpl %d1,%d0
     6073a:	6200 013a      	bhiw 0x876
     6073e:	7000           	moveq #0,%d0
     60740:	3039 0201 22f8 	movew 0x20122f8,%d0
     60746:	7200           	moveq #0,%d1
     60748:	3239 0201 2300 	movew 0x2012300,%d1
     6074e:	e489           	lsrl #2,%d1
     60750:	b081           	cmpl %d1,%d0
     60752:	6200 0122      	bhiw 0x876
     60756:	7000           	moveq #0,%d0
     60758:	3039 0201 6194 	movew 0x2016194,%d0
     6075e:	7200           	moveq #0,%d1
     60760:	3239 0201 61a4 	movew 0x20161a4,%d1
     60766:	e489           	lsrl #2,%d1
     60768:	b081           	cmpl %d1,%d0
     6076a:	6200 010a      	bhiw 0x876
     6076e:	3039 0200 d0dc 	movew 0x200d0dc,%d0
     60774:	9079 0200 d0cc 	subw 0x200d0cc,%d0
     6077a:	33c0 0200 d0d8 	movew %d0,0x200d0d8
     60780:	7000           	moveq #0,%d0
     60782:	3039 0200 d0cc 	movew 0x200d0cc,%d0
     60788:	2f00           	movel %d0,%sp@-
     6078a:	7000           	moveq #0,%d0
     6078c:	3039 0200 d0d8 	movew 0x200d0d8,%d0
     60792:	0680 0200 2104 	addil #33562884,%d0
     60798:	2f00           	movel %d0,%sp@-
     6079a:	4879 0200 2104 	pea 0x2002104
     607a0:	61ff 0002 d556 	bsrl 0x2dcf8
     607a6:	4fef 000c      	lea %sp@(12),%sp
     607aa:	3039 0201 2300 	movew 0x2012300,%d0
     607b0:	9079 0201 22f8 	subw 0x20122f8,%d0
     607b6:	33c0 0201 22fc 	movew %d0,0x20122fc
     607bc:	7000           	moveq #0,%d0
     607be:	3039 0201 22f8 	movew 0x20122f8,%d0
     607c4:	2f00           	movel %d0,%sp@-
     607c6:	7000           	moveq #0,%d0
     607c8:	3039 0201 22fc 	movew 0x20122fc,%d0
     607ce:	0680 0200 d0f0 	addil #33607920,%d0
     607d4:	2f00           	movel %d0,%sp@-
     607d6:	4879 0200 d0f0 	pea 0x200d0f0
     607dc:	61ff 0002 d51a 	bsrl 0x2dcf8
     607e2:	4fef 000c      	lea %sp@(12),%sp
     607e6:	3039 0201 61a4 	movew 0x20161a4,%d0
     607ec:	9079 0201 6194 	subw 0x2016194,%d0
     607f2:	33c0 0201 61a0 	movew %d0,0x20161a0
     607f8:	7000           	moveq #0,%d0
     607fa:	3039 0201 6194 	movew 0x2016194,%d0
     60800:	2f00           	movel %d0,%sp@-
     60802:	7000           	moveq #0,%d0
     60804:	3039 0201 61a0 	movew 0x20161a0,%d0
     6080a:	0680 0201 32b4 	addil #33632948,%d0
     60810:	2f00           	movel %d0,%sp@-
     60812:	4879 0201 32b4 	pea 0x20132b4
     60818:	61ff 0002 d4de 	bsrl 0x2dcf8
     6081e:	4fef 000c      	lea %sp@(12),%sp
     60822:	3039 0201 75f8 	movew 0x20175f8,%d0
     60828:	48c0           	extl %d0
     6082a:	23c0 0201 61b0 	movel %d0,0x20161b0
     60830:	33f9 0200 d0d0 	movew 0x200d0d0,0x200d0e0
     60836:	0200 d0e0 
     6083a:	33f9 0200 d0d4 	movew 0x200d0d4,0x200d0e4
     60840:	0200 d0e4 
     60844:	33f9 0201 6198 	movew 0x2016198,0x20161a8
     6084a:	0201 61a8 
     6084e:	33f9 0201 619c 	movew 0x201619c,0x20161ac
     60854:	0201 61ac 
     60858:	33f9 0200 d0e8 	movew 0x200d0e8,0x200d0ec
     6085e:	0200 d0ec 
     60862:	23f9 0201 61e0 	movel 0x20161e0,0x20161e8
     60868:	0201 61e8 
     6086c:	23f9 0201 61e4 	movel 0x20161e4,0x20161ec
     60872:	0201 61ec 
     60876:	4e5e           	unlk %fp
     60878:	4e75           	rts
     6087a:	4e56 0000      	linkw %fp,#0
     6087e:	4ab9 0201 61b0 	tstl 0x20161b0
     60884:	6c06           	bges 0x88c
     60886:	7000           	moveq #0,%d0
     60888:	6000 00fe      	braw 0x988
     6088c:	3039 0200 d0dc 	movew 0x200d0dc,%d0
     60892:	9079 0200 d0d8 	subw 0x200d0d8,%d0
     60898:	33c0 0200 d0cc 	movew %d0,0x200d0cc
     6089e:	7000           	moveq #0,%d0
     608a0:	3039 0200 d0cc 	movew 0x200d0cc,%d0
     608a6:	2f00           	movel %d0,%sp@-
     608a8:	4879 0200 2104 	pea 0x2002104
     608ae:	7000           	moveq #0,%d0
     608b0:	3039 0200 d0d8 	movew 0x200d0d8,%d0
     608b6:	0680 0200 2104 	addil #33562884,%d0
     608bc:	2f00           	movel %d0,%sp@-
     608be:	61ff 0002 d438 	bsrl 0x2dcf8
     608c4:	4fef 000c      	lea %sp@(12),%sp
     608c8:	3039 0201 2300 	movew 0x2012300,%d0
     608ce:	9079 0201 22fc 	subw 0x20122fc,%d0
     608d4:	33c0 0201 22f8 	movew %d0,0x20122f8
     608da:	7000           	moveq #0,%d0
     608dc:	3039 0201 22f8 	movew 0x20122f8,%d0
     608e2:	2f00           	movel %d0,%sp@-
     608e4:	4879 0200 d0f0 	pea 0x200d0f0
     608ea:	7000           	moveq #0,%d0
     608ec:	3039 0201 22fc 	movew 0x20122fc,%d0
     608f2:	0680 0200 d0f0 	addil #33607920,%d0
     608f8:	2f00           	movel %d0,%sp@-
     608fa:	61ff 0002 d3fc 	bsrl 0x2dcf8
     60900:	4fef 000c      	lea %sp@(12),%sp
     60904:	3039 0201 61a4 	movew 0x20161a4,%d0
     6090a:	9079 0201 61a0 	subw 0x20161a0,%d0
     60910:	33c0 0201 6194 	movew %d0,0x2016194
     60916:	7000           	moveq #0,%d0
     60918:	3039 0201 6194 	movew 0x2016194,%d0
     6091e:	2f00           	movel %d0,%sp@-
     60920:	4879 0201 32b4 	pea 0x20132b4
     60926:	7000           	moveq #0,%d0
     60928:	3039 0201 61a0 	movew 0x20161a0,%d0
     6092e:	0680 0201 32b4 	addil #33632948,%d0
     60934:	2f00           	movel %d0,%sp@-
     60936:	61ff 0002 d3c0 	bsrl 0x2dcf8
     6093c:	4fef 000c      	lea %sp@(12),%sp
     60940:	33f9 0200 d0e0 	movew 0x200d0e0,0x200d0d0
     60946:	0200 d0d0 
     6094a:	33f9 0200 d0e4 	movew 0x200d0e4,0x200d0d4
     60950:	0200 d0d4 
     60954:	33f9 0201 61a8 	movew 0x20161a8,0x2016198
     6095a:	0201 6198 
     6095e:	33f9 0201 61ac 	movew 0x20161ac,0x201619c
     60964:	0201 619c 
     60968:	33f9 0200 d0ec 	movew 0x200d0ec,0x200d0e8
     6096e:	0200 d0e8 
     60972:	23f9 0201 61e8 	movel 0x20161e8,0x20161e0
     60978:	0201 61e0 
     6097c:	23f9 0201 61ec 	movel 0x20161ec,0x20161e4
     60982:	0201 61e4 
     60986:	7001           	moveq #1,%d0
     60988:	4e5e           	unlk %fp
     6098a:	4e75           	rts
     6098c:	4e56 0000      	linkw %fp,#0
     60990:	4ab9 0201 61b0 	tstl 0x20161b0
     60996:	6d52           	blts 0x9ea
     60998:	7000           	moveq #0,%d0
     6099a:	3039 0200 d0dc 	movew 0x200d0dc,%d0
     609a0:	7200           	moveq #0,%d1
     609a2:	3239 0200 d0d8 	movew 0x200d0d8,%d1
     609a8:	9081           	subl %d1,%d0
     609aa:	2f00           	movel %d0,%sp@-
     609ac:	7000           	moveq #0,%d0
     609ae:	3039 0200 d0d8 	movew 0x200d0d8,%d0
     609b4:	0680 0200 2104 	addil #33562884,%d0
     609ba:	2f00           	movel %d0,%sp@-
     609bc:	61ff 0002 d492 	bsrl 0x2de50
     609c2:	504f           	addqw #8,%sp
     609c4:	33f9 0200 d0dc 	movew 0x200d0dc,0x200d0d8
     609ca:	0200 d0d8 
     609ce:	33f9 0201 2300 	movew 0x2012300,0x20122fc
     609d4:	0201 22fc 
     609d8:	33f9 0201 61a4 	movew 0x20161a4,0x20161a0
     609de:	0201 61a0 
     609e2:	72ff           	moveq #-1,%d1
     609e4:	23c1 0201 61b0 	movel %d1,0x20161b0
     609ea:	4e5e           	unlk %fp
     609ec:	4e75           	rts
     609ee:	4e56 0000      	linkw %fp,#0
     609f2:	3039 0200 d0d8 	movew 0x200d0d8,%d0
     609f8:	b079 0200 d0dc 	cmpw 0x200d0dc,%d0
     609fe:	6606           	bnes 0xa06
     60a00:	61ff 0002 5980 	bsrl 0x26382
     60a06:	6184           	bsrs 0x98c
     60a08:	4e5e           	unlk %fp
     60a0a:	4e75           	rts
     60a0c:	4e56 fff8      	linkw %fp,#-8
     60a10:	48d7 2080      	moveml %d7/%a5,%sp@
     60a14:	3039 0200 d0cc 	movew 0x200d0cc,%d0
     60a1a:	b079 0200 d0d8 	cmpw 0x200d0d8,%d0
     60a20:	6602           	bnes 0xa24
     60a22:	61ca           	bsrs 0x9ee
     60a24:	3e39 0200 d0cc 	movew 0x200d0cc,%d7
     60a2a:	0679 001e 0200 	addiw #30,0x200d0cc
     60a30:	d0cc 
     60a32:	7000           	moveq #0,%d0
     60a34:	3007           	movew %d7,%d0
     60a36:	0680 0200 2104 	addil #33562884,%d0
     60a3c:	2a40           	moveal %d0,%a5
     60a3e:	206e 0008      	moveal %fp@(8),%a0
     60a42:	224d           	moveal %a5,%a1
     60a44:	22d8           	movel %a0@+,%a1@+
     60a46:	22d8           	movel %a0@+,%a1@+
     60a48:	22d8           	movel %a0@+,%a1@+
     60a4a:	206e 000c      	moveal %fp@(12),%a0
     60a4e:	43ed 000c      	lea %a5@(12),%a1
     60a52:	22d8           	movel %a0@+,%a1@+
     60a54:	22d8           	movel %a0@+,%a1@+
     60a56:	22d8           	movel %a0@+,%a1@+
     60a58:	3b79 0200 d0e8 	movew 0x200d0e8,%a5@(24)
     60a5e:	0018 
     60a60:	5279 0200 d0e8 	addqw #1,0x200d0e8
     60a66:	426d 001c      	clrw %a5@(28)
     60a6a:	426d 001a      	clrw %a5@(26)
     60a6e:	7000           	moveq #0,%d0
     60a70:	3007           	movew %d7,%d0
     60a72:	4cee 2080 fff8 	moveml %fp@(-8),%d7/%a5
     60a78:	4e5e           	unlk %fp
     60a7a:	4e75           	rts
     60a7c:	4e56 fff0      	linkw %fp,#-16
     60a80:	48d7 30c0      	moveml %d6-%d7/%a4-%a5,%sp@
     60a84:	7000           	moveq #0,%d0
     60a86:	302e 000a      	movew %fp@(10),%d0
     60a8a:	0680 0200 2104 	addil #33562884,%d0
     60a90:	2a40           	moveal %d0,%a5
     60a92:	7000           	moveq #0,%d0
     60a94:	302e 000e      	movew %fp@(14),%d0
     60a98:	0680 0200 2104 	addil #33562884,%d0
     60a9e:	2840           	moveal %d0,%a4
     60aa0:	2e2d 000c      	movel %a5@(12),%d7
     60aa4:	2c2c 000c      	movel %a4@(12),%d6
     60aa8:	be86           	cmpl %d6,%d7
     60aaa:	662e           	bnes 0xada
     60aac:	486c 000c      	pea %a4@(12)
     60ab0:	486d 000c      	pea %a5@(12)
     60ab4:	6100 fc00      	bsrw 0x6b6
     60ab8:	504f           	addqw #8,%sp
     60aba:	48c0           	extl %d0
     60abc:	7eff           	moveq #-1,%d7
     60abe:	b087           	cmpl %d7,%d0
     60ac0:	672a           	beqs 0xaec
     60ac2:	4a80           	tstl %d0
     60ac4:	672a           	beqs 0xaf0
     60ac6:	7e01           	moveq #1,%d7
     60ac8:	b087           	cmpl %d7,%d0
     60aca:	670a           	beqs 0xad6
     60acc:	6014           	bras 0xae2
     60ace:	4a80           	tstl %d0
     60ad0:	673c           	beqs 0xb0e
     60ad2:	7e01           	moveq #1,%d7
     60ad4:	b087           	cmpl %d7,%d0
     60ad6:	7000           	moveq #0,%d0
     60ad8:	6008           	bras 0xae2
     60ada:	7000           	moveq #0,%d0
     60adc:	be86           	cmpl %d6,%d7
     60ade:	5dc0           	slt %d0
     60ae0:	4400           	negb %d0
     60ae2:	4cee 30c0 fff0 	moveml %fp@(-16),%d6-%d7/%a4-%a5
     60ae8:	4e5e           	unlk %fp
     60aea:	4e75           	rts
     60aec:	7001           	moveq #1,%d0
     60aee:	60f2           	bras 0xae2
     60af0:	2e15           	movel %a5@,%d7
     60af2:	2c14           	movel %a4@,%d6
     60af4:	be86           	cmpl %d6,%d7
     60af6:	66e2           	bnes 0xada
     60af8:	4854           	pea %a4@
     60afa:	4855           	pea %a5@
     60afc:	6100 fbb8      	bsrw 0x6b6
     60b00:	504f           	addqw #8,%sp
     60b02:	48c0           	extl %d0
     60b04:	7eff           	moveq #-1,%d7
     60b06:	b087           	cmpl %d7,%d0
     60b08:	66c4           	bnes 0xace
     60b0a:	7001           	moveq #1,%d0
     60b0c:	60d4           	bras 0xae2
     60b0e:	302d 0018      	movew %a5@(24),%d0
     60b12:	7200           	moveq #0,%d1
     60b14:	b06c 0018      	cmpw %a4@(24),%d0
     60b18:	55c1           	scs %d1
     60b1a:	4401           	negb %d1
     60b1c:	2001           	movel %d1,%d0
     60b1e:	60c2           	bras 0xae2
     60b20:	4e56 ffec      	linkw %fp,#-20
     60b24:	3039 0201 22f8 	movew 0x20122f8,%d0
     60b2a:	b079 0201 22fc 	cmpw 0x20122fc,%d0
     60b30:	6604           	bnes 0xb36
     60b32:	6100 feba      	bsrw 0x9ee
     60b36:	3d79 0201 22f8 	movew 0x20122f8,%fp@(-10)
     60b3c:	fff6 
     60b3e:	7000           	moveq #0,%d0
     60b40:	302e fff6      	movew %fp@(-10),%d0
     60b44:	0680 0200 d0f0 	addil #33607920,%d0
     60b4a:	2d40 fffc      	movel %d0,%fp@(-4)
     60b4e:	0679 000e 0201 	addiw #14,0x20122f8
     60b54:	22f8 
     60b56:	2040           	moveal %d0,%a0
     60b58:	30ae 000a      	movew %fp@(10),%a0@
     60b5c:	206e fffc      	moveal %fp@(-4),%a0
     60b60:	316e 000e 0002 	movew %fp@(14),%a0@(2)
     60b66:	4a6e 0012      	tstw %fp@(18)
     60b6a:	6606           	bnes 0xb72
     60b6c:	302e 0016      	movew %fp@(22),%d0
     60b70:	6004           	bras 0xb76
     60b72:	302e 0012      	movew %fp@(18),%d0
     60b76:	3d40 fff4      	movew %d0,%fp@(-12)
     60b7a:	665a           	bnes 0xbd6
     60b7c:	206e fffc      	moveal %fp@(-4),%a0
     60b80:	1179 0201 61cc 	moveb 0x20161cc,%a0@(13)
     60b86:	000d 
     60b88:	7000           	moveq #0,%d0
     60b8a:	302e 000e      	movew %fp@(14),%d0
     60b8e:	2f00           	movel %d0,%sp@-
     60b90:	7000           	moveq #0,%d0
     60b92:	302e 000a      	movew %fp@(10),%d0
     60b96:	2f00           	movel %d0,%sp@-
     60b98:	6100 fee2      	bsrw 0xa7c
     60b9c:	504f           	addqw #8,%sp
     60b9e:	206e fffc      	moveal %fp@(-4),%a0
     60ba2:	1140 000c      	moveb %d0,%a0@(12)
     60ba6:	4a80           	tstl %d0
     60ba8:	6716           	beqs 0xbc0
     60baa:	206e fffc      	moveal %fp@(-4),%a0
     60bae:	316e 000a 0006 	movew %fp@(10),%a0@(6)
     60bb4:	206e fffc      	moveal %fp@(-4),%a0
     60bb8:	316e 000e 0004 	movew %fp@(14),%a0@(4)
     60bbe:	605c           	bras 0xc1c
     60bc0:	206e fffc      	moveal %fp@(-4),%a0
     60bc4:	316e 000e 0006 	movew %fp@(14),%a0@(6)
     60bca:	206e fffc      	moveal %fp@(-4),%a0
     60bce:	316e 000a 0004 	movew %fp@(10),%a0@(4)
     60bd4:	6046           	bras 0xc1c
     60bd6:	7000           	moveq #0,%d0
     60bd8:	302e fff4      	movew %fp@(-12),%d0
     60bdc:	0680 0200 d0f0 	addil #33607920,%d0
     60be2:	2d40 fff8      	movel %d0,%fp@(-8)
     60be6:	206e fffc      	moveal %fp@(-4),%a0
     60bea:	2240           	moveal %d0,%a1
     60bec:	1169 000d 000d 	moveb %a1@(13),%a0@(13)
     60bf2:	206e fffc      	moveal %fp@(-4),%a0
     60bf6:	226e fff8      	moveal %fp@(-8),%a1
     60bfa:	1169 000c 000c 	moveb %a1@(12),%a0@(12)


; === CHUNK 2: 0x60C00-0x61800 ===

Looking at the raw disassembly from 0x60C00 to 0x61800, I can see this is indeed part of the PostScript interpreter's geometry and display list management code. The prior analysis had some correct identifications but also some errors and omissions. Let me provide a corrected and more detailed analysis.

## CORRECTIONS TO PRIOR ANALYSIS:
1. The prior analysis incorrectly identified some functions (like `calculate_fixed_point_value` at 0x60F30) - this is actually a fixed-point multiplication/division function.
2. The prior analysis missed several important functions in this range.
3. The display list management is more complex than described, involving intersection calculations and Bézier curve handling.

## FUNCTIONS:

### 1. 0x60C00 - `update_display_list_entry`
- **Entry**: 0x60C00
- **Purpose**: Updates a display list entry with new coordinate linkages. Manages forward/backward pointers between display list segments based on endpoint comparisons. Handles the doubly-linked list structure of display list segments.
- **Arguments**: 
  - A0: pointer to display list entry structure (FP@(-4))
  - A1: pointer to another display list entry (FP@(-8))
  - FP@(10), FP@(14): coordinate indices
  - FP@(18), FP@(22): comparison values
- **Return**: None
- **RAM access**: 
  - 0x2002104+: display list coordinate arrays
  - 0x200d0f0+: display list linkage arrays
- **Key operations**: Compares segment endpoints at offsets 26/28, updates forward/backward pointers accordingly.

### 2. 0x60C8C - `allocate_display_list_slot`
- **Entry**: 0x60C8C
- **Purpose**: Allocates a slot from the display list free list. Manages a free list head at 0x20132A4 and allocation count at 0x20132B0.
- **Arguments**: 
  - FP@(10), FP@(14): coordinate values to store in the allocated slot
- **Return**: D0 = allocated slot index
- **RAM access**:
  - 0x20132A4: free list head pointer
  - 0x20132B0: allocation count
  - 0x2012304: display list slot array (free list links)
  - 0x200d0f8/0x200d0fa: forward/backward pointer arrays
- **Call targets**: 0x26382 (error handler if free list empty)
- **Key operations**: Removes head from free list, initializes slot with coordinates, updates forward/backward pointers.

### 3. 0x60D38 - `free_display_list_slot`
- **Entry**: 0x60D38
- **Purpose**: Returns a display list slot to the free list. Updates free list head and decrements allocation count.
- **Arguments**: D0 = slot index to free (FP@(10))
- **Return**: None
- **RAM access**:
  - 0x20132A4: free list head
  - 0x20132B0: allocation count
  - 0x2012304: display list slot array
- **Key operations**: Adds slot to head of free list, decrements count.

### 4. 0x60D62 - `insert_into_sorted_display_list`
- **Entry**: 0x60D62
- **Purpose**: Inserts a new display list entry into a sorted doubly-linked list. Maintains sorting by coordinate values using a comparison function.
- **Arguments**:
  - D7 = new entry index
  - FP@(10) = coordinate value for sorting
  - FP@(12) = packed data (stored in byte at offset 6)
- **Return**: None
- **RAM access**:
  - 0x2016194: display list buffer pointer
  - 0x20161A0: buffer limit
  - 0x20132B4: display list entry structures
  - 0x2016198: list head pointer
  - 0x201619C: current pointer
- **Call targets**: 0x9EE (buffer management), 0xA7C (coordinate comparison)
- **Key operations**: Traverses list forward or backward to find insertion point, updates forward/backward pointers.

### 5. 0x60EDE - `remove_from_display_list`
- **Entry**: 0x60EDE
- **Purpose**: Removes an entry from the display list. Updates forward/backward pointers and handles special cases.
- **Arguments**: D7 = entry index to remove
- **Return**: D0 = removed entry index
- **RAM access**:
  - 0x2016198: list head
  - 0x201619C: current pointer
  - 0x20132B6/0x20132B8: forward/backward pointer arrays
- **Key operations**: Updates head pointer if removing head, clears current pointer if it matches removed entry.

### 6. 0x60F30 - `fixed_point_multiply_divide`
- **Entry**: 0x60F30
- **Purpose**: Performs fixed-point multiplication and division. Takes a 48-bit fixed-point number (16.32 format) and multiplies/divides it.
- **Arguments**: A5 = pointer to 48-bit fixed-point number (3×32-bit words)
- **Return**: D0 = result (32-bit)
- **Call targets**: 0x2C106 (multiplication/division routine)
- **Key operations**: Multiplies high word, adds scaled low word, returns 32-bit result.

### 7. 0x60F5E - `update_display_list_bounds`
- **Entry**: 0x60F5E
- **Purpose**: Updates display list bounding box coordinates. Maintains min/max values for X and Y coordinates.
- **Arguments**:
  - FP@(8): X coordinate
  - FP@(12): Y coordinate
- **Return**: None
- **RAM access**:
  - 0x20161CC: coordinate system flag
  - 0x20161E0/0x20161E4: X min/max
  - 0x20161DC: Y max
  - 0x200D0D4: current display list index
- **Call targets**: 0xA0C (coordinate comparison), 0xB20 (segment linking), 0xD62 (insert into display list)
- **Key operations**: Updates bounding box, links segments, inserts into display list.

### 8. 0x61058 - `close_display_list_segment`
- **Entry**: 0x61058
- **Purpose**: Closes a display list segment by linking endpoints and updating pointers.
- **Arguments**: None (uses global display list state)
- **Return**: None
- **RAM access**:
  - 0x200D0D4: current display list index
  - 0x200D0D0: previous display list index
  - 0x20161CC: coordinate system flag
  - 0x20161C0: segment state array
- **Call targets**: 0xA0C (coordinate comparison), 0xB20 (segment linking), 0xD62 (insert into display list)
- **Key operations**: Links segment endpoints, updates display list pointers, clears current segment.

### 9. 0x611B0 - `calculate_intersection_point`
- **Entry**: 0x611B0
- **Purpose**: Calculates intersection point between two line segments using fixed-point arithmetic.
- **Arguments**:
  - FP@(10): segment index
  - FP@(12): Y coordinate
  - FP@(16): direction flag
- **Return**: D0 = pointer to intersection result (3×32-bit at 0x20161F8)
- **RAM access**:
  - 0x200D0F0: segment linkage array
  - 0x2002104: coordinate array
  - 0x20161F8: result buffer
- **Key operations**: Performs line intersection calculation using fixed-point math, stores result in buffer.

### 10. 0x612B4 - `calculate_fixed_point_intersection`
- **Entry**: 0x612B4
- **Purpose**: Calculates intersection using fixed-point arithmetic with division.
- **Arguments**:
  - FP@(10): segment index
  - FP@(12): Y coordinate
  - FP@(16): direction flag
- **Return**: D0 = intersection result (32-bit fixed-point)
- **Call targets**: 0xF30 (fixed-point multiply/divide), 0x2C07E (division), 0x2BFE0 (multiplication)
- **Key operations**: Performs intersection calculation with proper fixed-point scaling.

### 11. 0x61372 - `calculate_bezier_intersection`
- **Entry**: 0x61372
- **Purpose**: Calculates intersection point for Bézier curves using parametric equations.
- **Arguments**:
  - FP@(8), FP@(12), FP@(16), FP@(20), FP@(24): curve parameters
- **Return**: D0 = pointer to result (3×32-bit at 0x2016204)
- **RAM access**: 0x2016204: result buffer
- **Key operations**: Solves cubic Bézier intersection using parametric equations and fixed-point math.

### 12. 0x61440 - `compare_segment_directions`
- **Entry**: 0x61440
- **Purpose**: Compares directions of two segments to determine their spatial relationship.
- **Arguments**:
  - FP@(8), FP@(12): segment pointers
  - FP@(18): segment index
- **Return**: D0 = comparison result (-1, 0, 1, 2)
- **Call targets**: 0x6B6 (direction comparison)
- **Key operations**: Compares segment directions, returns relationship code.

### 13. 0x61530 - `find_segment_intersection`
- **Entry**: 0x61530
- **Purpose**: Finds intersection point between two display list segments with extensive error handling.
- **Arguments**:
  - FP@(10), FP@(14): segment indices
  - FP@(16), FP@(20): result buffers
- **Return**: None (results stored in buffers)
- **Call targets**: 0x1372 (Bézier intersection), 0x11B0 (intersection calculation), 0x34E (fixed-point operations), 0x18C/0xBA (vector operations), 0x3B6 (result calculation)
- **Key operations**: Handles special cases (horizontal/vertical lines), computes intersection using fixed-point math with error checking.

## DATA REGIONS:
- **0x617FF**: End of this code block (function continues beyond 0x61800)
- The code uses several fixed buffers in RAM:
  - 0x20161F8: Intersection result buffer (12 bytes)
  - 0x2016204: Bézier intersection result buffer (12 bytes)
  - 0x2002104: Coordinate array base
  - 0x200D0F0: Segment linkage array

## KEY ALGORITHMS:
1. **Display list management**: Doubly-linked lists with free list allocation
2. **Fixed-point arithmetic**: 16.32 format with multiplication/division
3. **Line intersection**: Using parametric equations with error handling
4. **Bézier curve intersection**: Solving cubic equations
5. **Segment direction comparison**: For spatial relationship determination

## CORRECTIONS FROM PRIOR ANALYSIS:
- 0x60F30 is NOT `calculate_fixed_point_value` - it's `fixed_point_multiply_divide`
- 0x611B0 is NOT missing - it's `calculate_intersection_point`
- 0x612B4 is NOT `calculate_fixed_point_value` - it's `calculate_fixed_point_intersection`
- The code handles both line segments and Bézier curves
- Extensive use of fixed-point math throughout

This region contains sophisticated geometry algorithms for the PostScript interpreter's display list management, with proper handling of edge cases and numerical stability.

; === CHUNK 3: 0x61800-0x62400 ===

## CORRECTED AND REFINED ANALYSIS OF 0x61800-0x62400

**CORRECTIONS TO PRIOR ANALYSIS:**
1. The prior analysis was mostly correct but missed some key details about the data structures and algorithms.
2. The function at 0x61800 is indeed `setbbox` but it's more complex than described - it handles coordinate transformation and clipping.
3. The function at 0x618AC is `update_bbox_cache` but it manages a global bounding box cache with validation flags.
4. The functions at 0x61A42 and 0x61A96 are correctly identified as `constrain_dimension_min/max`.
5. The function at 0x61AEA is `lookup_char_metrics` - retrieves character metrics from font data structures.
6. The function at 0x61B7C is `merge_char_metrics` - merges metrics for kerning/pair adjustment.
7. The function at 0x61DF8 is `compare_and_swap_char_metrics` - compares and potentially swaps character metrics.
8. The function at 0x620F4 is `find_compatible_font_metrics` - searches for compatible font metrics.

**KEY INSIGHTS:**
- This region contains **PostScript font metric manipulation functions** for text layout and kerning.
- All functions operate on **PostScript font data structures** in RAM at 0x200xxxxx and 0x201xxxxx.
- The code uses **fixed-point arithmetic** for coordinate calculations.
- These are **C-compiled functions** (Sun CC) with standard stack frames.
- The functions manage a **global bounding box cache** with validation flags and dirty tracking.

## DETAILED FUNCTION ANALYSIS:

### 1. Function at 0x61800: `setbbox` operator
**Entry:** 0x61800  
**Purpose:** Implements PostScript `setbbox` operator. Takes four coordinates (llx, lly, urx, ury) from stack, validates them, updates current graphics state bounding box, and applies clipping if needed.  
**Arguments:** 
- fp@(8): word - object ID
- fp@(10): word - flags  
- fp@(14): word - more flags
- fp@(16): pointer to coordinate array
- fp@(20): pointer to graphics state  
**Return:** D0 = 0 on success, non-zero error code on failure.  
**Stack frame:** 0xFFEC bytes (244 bytes) for local variables.  
**Call targets:** 
- 0x34e (0x61B4E): coordinate transformation (mulsl instruction at 0x61808)
- 0xba (0x618BA): bbox validation  
- 0x3b6 (0x61BB6): bbox update
- 0x1440 (0x62C40): clipping check
**RAM accesses:** Graphics state structure via fp@(20).  
**Algorithm:** 
1. Transform coordinates using multiplication (mulsl at 0x61808)
2. Validate bounding box (llx ≤ urx, lly ≤ ury)
3. Update graphics state bounding box
4. Check if clipping is needed based on flags
5. Apply clipping if required

### 2. Function at 0x618AC: `update_bbox_cache`
**Entry:** 0x618AC  
**Purpose:** Updates cached bounding box for a PostScript object (path, text, image). Validates against global limits, checks cache flags, and updates if changed or forced.  
**Arguments:**
- fp@(8): callback function pointer
- fp@(10): word - object ID  
- fp@(14): word - flags
- fp@(16): long - xmin
- fp@(20): long - ymin  
- fp@(24): long - xmax
- fp@(28): long - update flag (0=conditional, 1=force)  
**Return:** None (void).  
**RAM accesses:**
- 0x20161B8: global cache enable flag
- 0x20161B4: bbox validation flag
- 0x20161F0/0x20161F4: global bbox limits (xmin/ymin)
- 0x20161C8: cache validation flag
- 0x20161BC: cache dirty flag
- 0x20161D0/0x20161D4/0x20161D8: cached bbox values  
**Call targets:** Calls function pointer at fp@(8) to update specific object type.  
**Algorithm:** 
1. Calculate object address: 0x2012304 + object ID
2. Check if caching enabled (0x20161B8)
3. Validate against global limits if enabled (0x20161B4)
4. Check cache validation flag (0x20161C8) and object's valid flag
5. Compare with cached values, update if different or forced
6. Set object's valid flag and update cache
7. Update global cache dirty flag if changes made

### 3. Function at 0x61A42: `constrain_dimension_min`
**Entry:** 0x61A42  
**Purpose:** Constrains a dimension to a minimum value. Used for ensuring coordinates don't go below minimum allowed values in bbox calculations.  
**Arguments:**
- fp@(8): callback function pointer
- fp@(10): word - object ID
- fp@(14): word - flags  
- fp@(16): long - current value
- fp@(20): long - minimum bound
- fp@(24): long - other coordinate (for aspect ratio)
- fp@(30): word - parameter for computation
- fp@(32): long - computation parameter  
**Return:** None (void).  
**Call targets:** 
- 0x12B4 (0x62AB4): compute dimension with parameter
- 0x18AC (0x618AC): update_bbox_cache
**Algorithm:**
1. Compute dimension using parameter (call to 0x12B4)
2. Compare with minimum bound
3. Use minimum if computed value is less
4. Call update_bbox_cache to update the cache

### 4. Function at 0x61A96: `constrain_dimension_max`
**Entry:** 0x61A96  
**Purpose:** Constrains a dimension to a maximum value. Used for ensuring coordinates don't exceed maximum allowed values in bbox calculations.  
**Arguments:** Same as `constrain_dimension_min`
**Return:** None (void).  
**Call targets:** 
- 0x12B4 (0x62AB4): compute dimension with parameter
- 0x18AC (0x618AC): update_bbox_cache
**Algorithm:**
1. Compute dimension using parameter (call to 0x12B4)
2. Compare with maximum bound
3. Use maximum if computed value is greater
4. Call update_bbox_cache to update the cache

### 5. Function at 0x61AEA: `lookup_char_metrics`
**Entry:** 0x61AEA  
**Purpose:** Retrieves character metrics from font data structure. Looks up metrics for a character in a font, caching results if not already cached.  
**Arguments:**
- fp@(8): word - font ID
- fp@(10): word - character code
- fp@(12): pointer to store width
- fp@(16): pointer to store left side bearing
- fp@(20): pointer to store right side bearing  
**Return:** None (void).  
**RAM accesses:**
- 0x200D0F0: font metric table base
- 0x2002104: character metric table base
**Call targets:**
- 0x6B6 (0x61FB6): compare metrics function
- 0xA0C (0x6240C): compute metrics function
**Algorithm:**
1. Calculate font structure address: 0x200D0F0 + font ID
2. Check if metrics are cached in font structure
3. If cached, retrieve from cache
4. If not cached, compute metrics using 0xA0C
5. Store computed metrics in cache for future use
6. Return metrics via output pointers

### 6. Function at 0x61B7C: `merge_char_metrics`
**Entry:** 0x61B7C  
**Purpose:** Merges character metrics for kerning or pair adjustment. Combines metrics from two characters to compute combined bounding box and positioning.  
**Arguments:**
- fp@(8): word - first font ID
- fp@(10): word - first character code
- fp@(12): long - first character x position
- fp@(16): long - first character y position
- fp@(20): long - first character width
- fp@(24): long - first character height
- fp@(28): word - second font ID
- fp@(30): word - second character code
- fp@(32): long - second character x position
- fp@(36): long - second character y position
- fp@(40): pointer - callback for bbox update  
**Return:** None (void).  
**RAM accesses:**
- 0x200D0F0: font metric table base
- 0x2012304: character metric cache
**Call targets:**
- 0xF30 (0x62930): compute combined metrics
- 0x1AEA (0x61AEA): lookup_char_metrics
- 0x18AC (0x618AC): update_bbox_cache
**Algorithm:**
1. Look up metrics for both characters
2. Compute combined bounding box
3. Adjust character positions based on kerning
4. Update character metric cache entries
5. Call callback to update bounding box cache

### 7. Function at 0x61DF8: `compare_and_swap_char_metrics`
**Entry:** 0x61DF8  
**Purpose:** Compares character metrics and potentially swaps them if they meet certain criteria. Used for font metric optimization and caching.  
**Arguments:**
- fp@(8): word - first character ID
- fp@(10): word - second character ID
- fp@(12): pointer - callback for updates  
**Return:** None (void).  
**Registers saved:** D4-D7, A4-A5  
**RAM accesses:**
- 0x200D0F0: font metric table base
- 0x2002104: character metric table
- 0x200211E/0x2002120: character swap tables
**Call targets:**
- 0x1530 (0x62D30): compare metrics function
- 0xA0C (0x6240C): compute metrics function
- 0xB20 (0x62320): swap metrics function
- 0xD62 (0x62B62): update cache function
**Algorithm:**
1. Check if both character IDs are valid (non-zero)
2. Retrieve font structures for both characters
3. Compare character metrics using multiple criteria
4. If metrics meet swap criteria, swap them in the tables
5. Update cache entries for both characters
6. Update swap tracking tables

### 8. Function at 0x620F4: `find_compatible_font_metrics`
**Entry:** 0x620F4  
**Purpose:** Searches for font metrics compatible with given character metrics. Used for font substitution and metric sharing.  
**Arguments:**
- fp@(8): word - character ID
- fp@(12): pointer - callback for compatible metric found
- fp@(16): long - search flags  
**Return:** None (void).  
**Registers saved:** D2-D3, D7, A2-A5  
**RAM accesses:**
- 0x2002104: character metric table base
- 0x20132AC/0x20132A8: font search pointers
- 0x200D0F0: font metric table
- 0x2012304: character metric cache
**Call targets:**
- 0xF30 (0x62930): compute metrics function
- 0x6B6 (0x61FB6): compare metrics function
- 0x11B0 (0x632B0): get compatible metrics function
- 0x12B4 (0x62AB4): compute dimension function
- 0x18AC (0x618AC): update_bbox_cache
- 0xC8C (0x6248C): find matching font function
**Algorithm:**
1. Get character metrics from table
2. Search through font metric structures for compatibility
3. Compare metrics using various criteria
4. If compatible font found, compute combined metrics
5. Update cache with compatible metrics
6. Handle font pairing and optimization

## DATA STRUCTURES:

**Font Metric Structure (at 0x200D0F0):**
- Offset 0x00: character code
- Offset 0x02: alternate character code
- Offset 0x04: x metric reference
- Offset 0x06: y metric reference
- Offset 0x08: linked character 1
- Offset 0x0A: linked character 2
- Offset 0x0C: flags byte (cached flag at bit 0)
- Offset 0x0D: adjustment byte
- Offset 0x0E: padding
- Offset 0x10: width
- Offset 0x14: left side bearing
- Offset 0x18: right side bearing

**Character Metric Cache Entry (at 0x2012304):**
- Offset 0x00: character ID 1
- Offset 0x02: character ID 2
- Offset 0x04: xmin
- Offset 0x08: ymin
- Offset 0x0C: xmax
- Offset 0x10: flags byte 1 (valid flag at bit 0)
- Offset 0x11: flags byte 2
- Offset 0x12: flags byte 3
- Offset 0x13: dirty flag
- Size: 20 bytes per entry

**Global BBox Cache (at 0x20161B4):**
- 0x20161B4: validation flag
- 0x20161B8: cache enable flag
- 0x20161BC: dirty flag
- 0x20161C8: cache validation flag
- 0x20161D0: cached xmin
- 0x20161D4: cached ymin
- 0x20161D8: cached xmax/ymax
- 0x20161F0: global xmin limit
- 0x20161F4: global ymin limit

## KEY OBSERVATIONS:

1. **Fixed-point arithmetic**: The code uses `mulsl` (multiply signed long) at 0x61808 for coordinate transformations, indicating fixed-point calculations.

2. **Cache management**: Sophisticated cache validation with dirty flags, enable/disable controls, and global limits.

3. **Font metric optimization**: Functions for comparing, swapping, and merging character metrics to optimize font rendering performance.

4. **Kerning support**: The `merge_char_metrics` function handles character pair adjustments for proper kerning.

5. **Error handling**: Functions return error codes and check validity flags before operations.

6. **Callback system**: Uses function pointers for extensibility (bbox updates, metric computations).

The code in this region is well-structured C code compiled with Sun CC, showing sophisticated font metric management for high-quality PostScript text rendering.

; === CHUNK 4: 0x62400-0x63000 ===

## CORRECTED AND REFINED ANALYSIS OF 0x62400-0x63000

### 1. Function at 0x62400
**Entry:** 0x62400  
**Suggested name:** `update_contour_neighbors`  
**Purpose:** Updates neighbor relationships between glyph contours during contour merging. Copies neighbor information (bytes at offsets 16-18) from source to destination contour, determines winding direction based on flags at offset 12, and calls collision resolution. Handles contour linking by updating neighbor pointers in both directions.  
**Arguments:** 
- A2: Source contour structure pointer
- A3: Destination contour structure pointer  
- A4: Additional contour structure pointer
- fp@(12): Context pointer
**Return value:** None (void)
**RAM accesses:** 
- Contour structures at offsets 16-18 (neighbor bytes), 12 (flags), 13 (winding direction)
- 0x2012306: Contour index table
**Call targets:** 0x1df8 (resolve_glyph_collisions)
**Called by:** Contour merging functions

### 2. Function at 0x624ca
**Entry:** 0x624ca  
**Suggested name:** `merge_contour_pair`  
**Purpose:** Merges two adjacent glyph contours by updating their neighbor links and metrics. Determines which contours are neighbors (via 0x200d0fa table), updates contour cache entries (0x2012304/0x2012306), handles winding direction constraints, and resolves collisions. Complex function with geometry computations and dimension constraints.  
**Arguments:** 
- fp@(10): Contour ID (word)
- fp@(12): Context pointer
**Return value:** None (void)
**RAM accesses:** 
- 0x2002104: Font/contour structure base
- 0x200d0fa: Contour neighbor status table  
- 0x2012304/0x2012306: Contour index tables
- Contour structures at 0x200d0f0 base
**Call targets:** 
- 0xf30: geometry computation
- 0x1a96: constrain_dimension_max
- 0x1a42: constrain_dimension_min
- 0x1df8: resolve_glyph_collisions
**Called by:** `process_contour_list` (0x62b10) for 1-neighbor case

### 3. Function at 0x6262a
**Entry:** 0x6262a  
**Suggested name:** `resolve_contour_chain`  
**Purpose:** Resolves a chain of connected contours by traversing neighbor links in both directions. Handles complex contour relationships with multiple winding directions, updates bounding boxes, manages contour merging for chains with 2 neighbors. Very complex function with loops, condition checks, and extensive contour structure manipulation.  
**Arguments:** 
- fp@(10): Starting contour ID (word)
- fp@(12): Context pointer
**Return value:** None (void)
**RAM accesses:**
- 0x2002104: Contour structure base
- 0x200d0fa: Neighbor status table
- 0x2012304/0x2012306: Contour index tables
- 0x200d0f0: Contour data structures
- 0x20132ac: Global contour pointer
**Call targets:**
- 0xf30: geometry computation
- 0x12b4: dimension computation
- 0x18ac: cache update
- 0x1aea: lookup_glyph_metrics
- 0x1df8: resolve collisions
- 0xd38: cleanup function
**Called by:** `process_contour_list` (0x62b10) for 2-neighbor case

### 4. Function at 0x62b10
**Entry:** 0x62b10  
**Suggested name:** `process_contour_list`  
**Purpose:** Main driver for processing active contours. Iterates through active contours (0x20132a8), classifies them by neighbor count (0, 1, or 2 neighbors via 0x200d0fa table), and dispatches to appropriate handlers. Manages scaling factors (0x20161e0/0x20161e4 → 0x20161f0/0x20161f4) and processing parameters (0x20161b4/0x20161b8).  
**Arguments:**
- fp@(8): Context pointer
- fp@(12): Parameter 1 (long)
- fp@(16): Parameter 2 (long)
**Return value:** None (void)
**RAM accesses:**
- 0x20132a8: Active contour pointer
- 0x200d0d4: Global flag
- 0x20161b4/0x20161b8: Processing parameters
- 0x20161e0/0x20161e4: Scaling factors
- 0x20161f0/0x20161f4: Scaled values
- 0x20132b4: Contour list base
**Call targets:**
- 0xc8c: get_next_contour
- 0x1058: special handler (when 0x200d0d4 flag set)
- 0x20f4: handle_0_neighbors
- 0x24ca: handle_1_neighbor (merge_contour_pair)
- 0x262a: handle_2_neighbors (resolve_contour_chain)
- 0xede: get_active_contour
- 0xd38: cleanup function
**Called by:** Higher-level glyph processing functions

### 5. Function at 0x62c72
**Entry:** 0x62c72  
**Suggested name:** `set_processing_flag`  
**Purpose:** Sets a global processing flag (0x20161cc) based on a boolean parameter. If parameter is non-zero, sets flag to 1; otherwise sets to 0.  
**Arguments:** fp@(8): Boolean flag (long)  
**Return value:** None (void)  
**RAM accesses:** 0x20161cc: Processing flag  
**Call targets:** None  
**Called by:** Unknown (likely configuration functions)

### 6. Function at 0x62c8c
**Entry:** 0x62c8c  
**Suggested name:** `reset_processing_flag`  
**Purpose:** Resets the global processing flag (0x20161cc) to value 2.  
**Arguments:** None  
**Return value:** None (void)  
**RAM accesses:** 0x20161cc: Processing flag  
**Call targets:** None  
**Called by:** Unknown (likely initialization functions)

### 7. Function at 0x62c9c
**Entry:** 0x62c9c  
**Suggested name:** `get_glyph_system_pointers`  
**Purpose:** Returns various glyph system pointers and values to caller-provided locations. Used to expose internal data structures to higher-level code.  
**Arguments:** 
- fp@(8): Pointer to store contour base address (0x2002104)
- fp@(12): Pointer to store contour count (0x200d0d8)
- fp@(16): Pointer to store contour data base (0x200d0f0)
- fp@(20): Pointer to store max contours (0x20122fc)
- fp@(24): Pointer to store contour list base (0x20132b4)
- fp@(28): Pointer to store another limit value (0x20161a0)
**Return value:** None (void)  
**RAM accesses:** 
- 0x2002104, 0x200d0d8, 0x200d0f0, 0x20122fc, 0x20132b4, 0x20161a0
**Call targets:** None  
**Called by:** System initialization or diagnostic functions

### 8. Function at 0x62ce0
**Entry:** 0x62ce0  
**Suggested name:** `configure_glyph_system`  
**Purpose:** Configures glyph system parameters based on mode parameter. Sets various limits and initializes data structures. Mode 0 sets default values, mode 1 does minimal configuration.  
**Arguments:** fp@(8): Mode (0=full config, 1=minimal)  
**Return value:** D0: Success status (0 or 1)  
**RAM accesses:** 
- 0x200d0d8, 0x200d0dc, 0x20122fc, 0x2012300, 0x20161a0, 0x20161a4, 0x20132b0, 0x20161b0
**Call targets:** 0xfffffef8 (likely initialization function)  
**Called by:** System setup functions

### 9. Data Region at 0x62d4a-0x62ea8
**Address:** 0x62d4a  
**Size:** 350 bytes (0x62d4a-0x62ea8)  
**Format:** Lookup table of byte values, appears to be character width or spacing data for different character classes. Contains repeating patterns (0x43, 0x6F, 0x70, 0x79, 0x72, 0x69, 0x67, 0x68, 0x74, 0x20, 0x28, 0x63, 0x29, etc.). Likely used for font metrics or character classification.  
**Note:** This is DATA, not code.

### 10. Function at 0x62eac
**Entry:** 0x62eac  
**Suggested name:** `call_graphics_operator`  
**Purpose:** Calls a graphics operator through the current graphics state. Retrieves operator address from graphics state structure and passes 8 parameters from stack.  
**Arguments:** 
- fp@(8)-(28): 8 parameters for graphics operator
**Return value:** D0: Return value from graphics operator  
**RAM accesses:** 
- 0x2017464: Current graphics state pointer
- Graphics state offsets: 0x90, 0x8C, 0xA0+8 (operator address)
**Call targets:** Graphics operator via indirect JSR  
**Called by:** PostScript graphics operators implementation

### 11. Function at 0x62ef4
**Entry:** 0x62ef4  
**Suggested name:** `get_current_font_metrics`  
**Purpose:** Retrieves current font metrics pointer based on graphics state. Checks if special flag is set at offset 0x8F, returns either cached metrics (offset 0xA0+12) or default value (0x62EAC).  
**Arguments:** None  
**Return value:** None (stores result at 0x201637c)  
**RAM accesses:** 
- 0x2017464: Graphics state pointer
- 0x201637c: Font metrics storage
**Call targets:** None  
**Called by:** Font/metrics related functions

### 12. Function at 0x62f26
**Entry:** 0x62f26  
**Suggested name:** `multiply_fixed_points`  
**Purpose:** Multiplies two fixed-point pairs (x1,y1 and x2,y2) and stores results. Uses software floating-point multiplication (0x89938).  
**Arguments:** 
- fp@(8), fp@(12): First point (x1, y1)
- fp@(16), fp@(20): Second point (x2, y2)
- fp@(24): Pointer to store results (x_result, y_result)
**Return value:** None (void)  
**Call targets:** 0x89938 (floating-point multiply)  
**Called by:** Geometry/transformation functions

### 13. Function at 0x62f58
**Entry:** 0x62f58  
**Suggested name:** `add_fixed_points`  
**Purpose:** Adds two fixed-point pairs (x1,y1 and x2,y2) and stores results. Uses software floating-point addition (0x89ab8).  
**Arguments:** 
- fp@(8), fp@(12): First point (x1, y1)
- fp@(16), fp@(20): Second point (x2, y2)
- fp@(24): Pointer to store results (x_result, y_result)
**Return value:** None (void)  
**Call targets:** 0x89ab8 (floating-point add)  
**Called by:** Geometry/transformation functions

### 14. Function at 0x62f8a
**Entry:** 0x62f8a  
**Suggested name:** `scale_point_by_factor`  
**Purpose:** Scales a point (x,y) by a scaling factor and stores results. Uses software floating-point multiplication (0x89a70).  
**Arguments:** 
- fp@(8), fp@(12): Point coordinates (x, y)
- fp@(16): Pointer to scaling factor
- fp@(20): Pointer to store results (x_scaled, y_scaled)
**Return value:** None (void)  
**Call targets:** 0x89a70 (floating-point multiply)  
**Called by:** Scaling/transformation functions

### 15. Function at 0x62fc6
**Entry:** 0x62fc6  
**Suggested name:** `compute_dot_product_scaled`  
**Purpose:** Computes dot product of two vectors with scaling, returns scaled result. Complex fixed-point math with multiple floating-point operations.  
**Arguments:** 
- fp@(8), fp@(12): First vector (x1, y1)
- fp@(16), fp@(20): Second vector (x2, y2) and scaling factor
**Return value:** D0: Scaled dot product result  
**Call targets:** 
- 0x89a70 (floating-point multiply)
- 0x89ab8 (floating-point add)
**Called by:** Geometry calculations for contour processing

## CORRECTIONS TO PRIOR ANALYSIS:
1. **Function at 0x62c72** was previously described as part of 0x62b10's analysis - it's a separate function.
2. **Data region at 0x62d4a** was not identified in prior analysis - it's a lookup table, not code.
3. **Functions 0x62eac through 0x62fc6** were not in prior analysis - they handle graphics operators and fixed-point math.
4. The prior analysis correctly identified the main contour processing functions but missed the utility functions at the end of the range.

## KEY INSIGHTS:
- This region contains the core glyph contour processing logic with three main cases: isolated contours (0 neighbors), paired contours (1 neighbor), and chain contours (2 neighbors).
- The fixed-point math functions (0x62f26-0x62fc6) use software floating-point emulation (bank 4 routines at 0x89938, 0x89ab8, 0x89a70).
- The graphics operator calling mechanism (0x62eac) shows how PostScript operators interface with the underlying graphics system.
- The data table at 0x62d4a appears to be character classification data, possibly for hinting or spacing adjustments.

; === CHUNK 5: 0x63000-0x63C00 ===

## REFINED ANALYSIS OF 0x63000-0x63C00

### 1. Function at 0x63000 (0x3000)
**Entry:** 0x63000  
**Suggested name:** `sign_or_zero_test`  
**Purpose:** Tests a 32-bit value at fp@(-4). Returns -1 if the value is negative AND its left-shifted version (by 1) is non-zero. Otherwise returns 1. This appears to be checking if a value is negative and not just -0 (in two's complement).  
**Arguments:** Value at fp@(-4) (likely a fixed-point coordinate)  
**Return:** D0 = -1 or 1  
**RAM accessed:** None directly  
**Key branches:** 0x6300c (beqs), 0x63010 (bras)  
**Callers:** Unknown from this section

### 2. Function at 0x63018 (0x3018)
**Entry:** 0x63018  
**Suggested name:** `copy_or_transform_point_pair`  
**Purpose:** Checks a global flag at 0x2016264. If set, calls a transformation function at 0xffff9dd8 with 4 arguments (two source points and a destination pointer). Otherwise, simply copies two 32-bit values (likely x,y coordinates) from source to destination. The transformation function pointer at 0x2017464 suggests this is for coordinate system transformations.  
**Arguments:** 4 args: source_x, source_y, dest_x_ptr, dest_y_ptr  
**Return:** None (void)  
**RAM accessed:** 0x2016264 (transformation flag), 0x2017464 (transformation function pointer)  
**Call targets:** 0xffff9dd8 (transformation function)  
**Callers:** Unknown from this section

### 3. Function at 0x63056 (0x3056)
**Entry:** 0x63056  
**Suggested name:** `copy_or_transform_point_pair_alt`  
**Purpose:** Identical pattern to previous function but calls a different transformation function at 0xffff9eae. Same flag check and copy fallback.  
**Arguments:** 4 args: source_x, source_y, dest_x_ptr, dest_y_ptr  
**Return:** None (void)  
**RAM accessed:** 0x2016264, 0x2017464  
**Call targets:** 0xffff9eae (alternative transformation)  
**Callers:** Unknown from this section

### 4. Function at 0x63094 (0x3094)
**Entry:** 0x63094  
**Suggested name:** `copy_or_transform_point_pair_with_table`  
**Purpose:** Similar to previous functions but uses a fixed address 0x20162ac as the second argument to the transformation function instead of the pointer at 0x2017464. This suggests 0x20162ac contains a transformation matrix or other geometric data.  
**Arguments:** 4 args: source_x, source_y, dest_x_ptr, dest_y_ptr  
**Return:** None (void)  
**RAM accessed:** 0x2016264 (flag), 0x20162ac (transformation table)  
**Call targets:** 0xffff9dd8 (same as first function)  
**Callers:** Unknown from this section

### 5. Function at 0x630d2 (0x30d2) - MAJOR GEOMETRIC FUNCTION
**Entry:** 0x630d2  
**Suggested name:** `process_bezier_intersection_or_clip`  
**Purpose:** Complex function that takes 4 point pairs (8 coordinates). Stores them in RAM at 0x20162f4-0x2016328. Performs extensive sorting of points by their y-coordinates (high 16 bits, suggesting fixed-point format with 16.16 precision). Handles special cases for colinear points, parallel segments, and intersection calculations. Calls a function pointer at 0x201637c for actual processing. This appears to be part of Bézier curve clipping or intersection testing for the PostScript renderer.  
**Arguments:** 8 args: x1,y1,x2,y2,x3,y3,x4,y4 (all 32-bit fixed-point)  
**Return:** Unknown (likely boolean or status)  
**RAM accessed:** 0x20162f4-0x2016328 (point storage), 0x201637c (processing function pointer)  
**Key operations:** Sorting points by y-coordinate, checking for horizontal/vertical alignment, computing line intersections using fixed-point math (calls to 0x2c0ca and 0x2c022 which are likely multiply/divide routines)  
**Call targets:** Function pointer at 0x201637c (multiple calls)  
**Callers:** 0x638f8 (within the large function at 0x6359e)

### 6. Function at 0x6359e (0x359e) - COMPLEX TRANSFORMATION FUNCTION
**Entry:** 0x6359e  
**Suggested name:** `transform_and_process_bezier_curve`  
**Purpose:** Main Bézier curve processing function. Takes 4 point pairs (8 coordinates). Checks multiple global flags (0x2016288, 0x201626c, 0x2017464+0xA4). Performs coordinate transformations using matrices at 0x20175e8-0x20175fa (likely current transformation matrix). Calls the intersection/clipping function at 0x630d2. Handles both hardware-accelerated and software rendering paths.  
**Arguments:** 8 args: x1,y1,x2,y2,x3,y3,x4,y4 (all 32-bit fixed-point)  
**Return:** None (void)  
**RAM accessed:** 0x2016288, 0x201626c, 0x2017464, 0x20175e8-0x20175fa, 0x20008f4 (current execution context)  
**Key operations:** Transformation matrix multiplication (calls to 0x89938 = multiply, 0x89ab8 = divide, 0x89968 = compare), bounding box calculation, hardware acceleration check  
**Call targets:** 0xfffff31a, 0xffff64aa, 0x1ce8e, 0x630d2, 0xffffad74, 0xffffae48, 0xffffbe24, 0xffffa580, 0x2df1c, 0xffffdf94, 0xffffa7c2, 0x2d8d8  
**Callers:** Likely PostScript path rendering operators

### 7. Function at 0x63b9c (0x3b9c) - INCOMPLETE FUNCTION
**Entry:** 0x63b9c  
**Suggested name:** `compare_fixed_point_coordinates` (partial)  
**Purpose:** Takes 5 fixed-point coordinates (32-bit each). Extracts high 16 bits (integer part) of each. Compares them for equality and calculates differences. Appears to be part of a larger coordinate comparison or sorting routine.  
**Arguments:** 5 args: coord1, coord2, coord3, coord4, coord5 (all 32-bit fixed-point)  
**Return:** Unknown (incomplete in this chunk)  
**RAM accessed:** None directly  
**Key operations:** Extracts high 16 bits (asrl #16), compares for equality, calculates absolute differences  
**Callers:** Unknown from this section

### 8. Data at 0x63b94 (0x3b94)
**Address:** 0x63b94  
**Size:** 8 bytes  
**Format:** Two 32-bit floating-point constants  
**Values:** 0x40dfef00 (approximately 6.9921875) and 0x00000000 (0.0)  
**Purpose:** Used as comparison thresholds in the Bézier curve processing function at 0x6359e. The first value (6.9921875) appears to be a tolerance for curve flatness testing.

### CORRECTIONS TO PRIOR ANALYSIS:
1. The prior analysis correctly identified all functions in this range.
2. The function at 0x63b9c is incomplete in this chunk - it continues beyond 0x63c00.
3. The data at 0x63b94 is correctly identified as floating-point constants, not code.
4. All function descriptions are accurate and consistent with the raw disassembly.

### ADDITIONAL INSIGHTS:
- The functions at 0x63018, 0x63056, and 0x63094 form a family of coordinate transformation wrappers that conditionally apply geometric transformations based on a global flag.
- The function at 0x630d2 implements a sophisticated Bézier curve intersection/clipping algorithm with extensive handling of edge cases (colinear points, parallel segments).
- The function at 0x6359e is the main entry point for Bézier curve rendering, handling both transformed and untransformed coordinates, with fallbacks to software rendering when hardware acceleration is unavailable.
- The floating-point constants at 0x63b94 are used as thresholds in curve flatness testing, which is part of the Bézier subdivision process.

; === CHUNK 6: 0x63C00-0x64800 ===

## CORRECTED AND REFINED ANALYSIS OF 0x63C00-0x64800

### 1. Function at 0x63B9C (continues through 0x63C00-0x63E54)
**Entry**: 0x63B9C (confirmed by code flow from 0x64146)  
**Name**: `compare_and_process_segments`  
**Purpose**: Processes a quadrilateral defined by 4 points (x1,y1,x2,y2,x3,y3,x4,y4) by sorting points by y-coordinate, handling special cases for horizontal lines, and decomposing into trapezoids for rendering. The function computes intersection points for non-horizontal edges and calls a rendering callback twice (for top and bottom trapezoids).  
**Arguments**: 8 args on stack (4 point pairs at fp@(8) through fp@(28))  
**Return**: None (void)  
**Stack frame**: 52 bytes saved registers (d2-d7)  
**Key operations**:
- Sorts points by y-coordinate (lines 0x63C34-0x63CA0) using bubble-sort style swaps
- Checks for horizontal lines (same y-coordinate after shifting right 16 bits = fixed-point integer part)
- For colinear horizontal segments: computes min/max x bounds and calls renderer once
- For non-horizontal segments: computes intersection point using fixed-point division (0x2C0CA) and multiplication (0x2C022)
- Calls function pointer at 0x201637c twice (lines 0x63E22, 0x63E46) for two trapezoidal segments
**RAM accessed**: 0x201637c (function pointer for rendering trapezoids)  
**Call targets**: 0x2C0CA (divide), 0x2C022 (multiply) - fixed-point math helpers  
**Called from**: 0x64146 (within `transform_and_clip_quadrilateral`)

### 2. Function at 0x63E56 (0x3E56 in file)
**Entry**: 0x63E56  
**Name**: `transform_and_clip_quadrilateral`  
**Purpose**: Transforms a quadrilateral through the current transformation matrix, clips it against the clipping region, and renders it. Handles both hardware-accelerated (when 0x2016288 set) and software rendering paths. For transformed paths, it saves/restores the transformation matrix.  
**Arguments**: 8 args on stack (4 point pairs at fp@(8) through fp@(28))  
**Return**: None (void)  
**Stack frame**: 144 bytes (-0x90)  
**Key logic**:
1. Checks hardware acceleration flag at 0x2016288 (line 0x63E5E)
2. Checks transformation flag at 0x201626c (line 0x63E68)
3. If transformations needed: calls `transform_points` (0xFFFFF31A) to apply matrix
4. Tests against clipping region using `clip_test` (0xFFFF64AA)
5. For transformed paths: saves transformation matrix at 0x20175E8 to local stack
6. Converts to device coordinates via `convert_to_device_coords` (0x1CE8E)
7. Calls `compare_and_process_segments` (0x63B9C) for actual rendering
**RAM accessed**:
- 0x2016288 (hardware acceleration flag)
- 0x201626c (transformation flag)
- 0x2017464 (graphics state pointer)
- 0x20175FA (translation component flag)
- 0x20175F0/75F4 (translation x/y)
- 0x20175E8 (transformation matrix, 5 longs = 20 bytes)
- 0x20008F4 (error recovery stack pointer)
- 0x201637C (rendering function pointer)
**Call targets**:
- 0xFFFFF31A (`transform_points`)
- 0xFFFF64AA (`clip_test`)
- 0x1CE8E (`convert_to_device_coords`)
- 0x63B9C (`compare_and_process_segments`)
- 0x89938 (multiply), 0x89AB8 (divide), 0x89A88 (abs) - fixed-point math
**Called from**: Unknown, but likely from PostScript path rendering operators like `fill` or `stroke`

### 3. Function at 0x64392 (0x4392 in file)
**Entry**: 0x64392  
**Name**: `render_transformed_vector`  
**Purpose**: Renders a single line segment (vector) with transformation support. Handles hardware-accelerated path building (when 0x2016288 set) and software per-pixel rendering. For hardware paths, it builds transformed path buffers with slope/intercept calculations; for software paths, it performs fixed-point math for pixel-accurate rendering.  
**Arguments**: 4 args (x1,y1,x2,y2 at fp@(8), fp@(12), fp@(16), fp@(20))  
**Return**: None (void)  
**Stack frame**: 108 bytes (-0x6C)  
**Key logic**:
1. Checks scaling factor at 0x201628C (line 0x6439A)
2. Applies translation via 0x20175F0/75F4 if needed
3. Hardware path (lines 0x643E6-0x64582):
   - Transforms coordinates using scaling factor
   - Builds path in buffer at 0x2016380
   - Calls `calculate_slope_intercept` (0x2F26) multiple times for rotated segments
   - Uses 4-step rotation algorithm (lines 0x6447C-0x64570) for different angles
   - Calls hardware renderer at 0xFFFFBE24
4. Software path (lines 0x64586-0x646DE):
   - Performs fixed-point division for slope calculations
   - Checks bounds against 0x2016294/6298/629C/62A0 (clipping limits)
   - Sets rendering mode in byte at fp@(-66)
   - Calls software renderer at 0x165AA
**RAM accessed**:
- 0x201628C (scaling factor)
- 0x2016288 (hardware acceleration flag)
- 0x20175F0/75F4 (translation)
- 0x2016380 (hardware path buffer)
- 0x2016294/6298/629C/62A0 (clipping bounds)
- 0x2017464 (graphics state)
- 0x20162DC/62C4 (temporary matrix storage)
**Call targets**:
- 0x3094 (vector transformation helper)
- 0x2F26 (`calculate_slope_intercept`)
- 0x3018 (vector endpoint calculation)
- 0xFFFFAD74 (add point to path)
- 0xFFFFAE48 (add line to path)
- 0xFFFFBE24 (render hardware path)
- 0x26FFA (setup rendering parameters)
- 0x165AA (software line renderer)
- 0xFFFEEE70 (graphics state restoration)
**Called from**: Unknown, likely from PostScript `lineto` or vector drawing operators

### 4. Function at 0x646F4 (0x46F4 in file)
**Entry**: 0x646F4  
**Name**: `calculate_vector_scale_factor`  
**Purpose**: Calculates a scaling factor for vectors based on current transformation state. Used to determine whether hardware acceleration can be applied or if software rendering is needed. Returns either the hardware scaling factor or a computed value based on transformation matrix.  
**Arguments**: 2 args (x,y at fp@(8), fp@(12))  
**Return**: D0 = scaling factor (fixed-point)  
**Stack frame**: 40 bytes (-0x28)  
**Key logic**:
1. Checks hardware acceleration flag at 0x2016288 (line 0x646F6)
2. If hardware available: returns hardware scaling factor from 0x201628C
3. Otherwise checks transformation state at 0x20174DC
4. If transformations active: computes scaling factor using transformation matrix
5. Calls `calculate_slope_intercept` (0x2F8A) and performs fixed-point math
6. Returns computed scaling factor in D0
**RAM accessed**:
- 0x2016288 (hardware acceleration flag)
- 0x201628C (hardware scaling factor)
- 0x20174DC (transformation state)
- 0x2016264 (transformation active flag)
- 0x2017464 (graphics state)
**Call targets**:
- 0x2F8A (`calculate_slope_intercept`)
- 0xFFFF9EAE (matrix transformation)
- 0xFFFFB708 (vector length calculation)
- 0x899C8 (float to fixed conversion)
- 0x89A88 (absolute value)
- 0x89998 (float comparison)
- 0x89A70 (float multiplication)
**Called from**: Unknown, likely from rendering setup code

### 5. Data Region at 0x6438A-0x64391
**Address**: 0x6438A  
**Size**: 8 bytes  
**Format**: Two 32-bit floating-point constants  
**Values**: 
- 0x6438A: 0x40DFEF00 = 6.9990234375 (approx 7.0)
- 0x6438E: 0x00000000 = 0.0
**Purpose**: Used as comparison threshold in `render_transformed_vector` for checking scaling factors.

### 6. Data Region at 0x646E8-0x646F3
**Address**: 0x646E8  
**Size**: 12 bytes  
**Format**: Three 32-bit values (likely floating-point constants)  
**Values**:
- 0x646E8: 0x3FE1A9FB = 1.765625 (approx √π?)
- 0x646EC: 0xE76C8B44 = -3.1415927? (actually -2.345e9 as integer)
- 0x646F0: 0x4E56FFD8 = Instruction "linkw %fp,#-40" - THIS IS CODE, NOT DATA
**Correction**: The prior analysis incorrectly identified 0x646F0 as data. This is actually the start of the function at 0x646F4. The disassembly shows "4e56 ffd8" = linkw %fp,#-40.

### 7. Data Region at 0x6471A (referenced)
**Address**: 0x6471A (PC-relative reference to 0x4920)  
**Actual address**: 0x64920 (outside current range)  
**Purpose**: Floating-point constant used in `calculate_vector_scale_factor` for comparison.

## CORRECTIONS TO PRIOR ANALYSIS:
1. **Function at 0x63B9C**: Correct name from `compare_and_process_segments` (was accurate). The function decomposes quadrilaterals into trapezoids, not triangles.
2. **Function at 0x64392**: The hardware path uses a 4-step rotation algorithm (lines 0x6447C-0x64570) that rotates the vector through 90° increments to handle different angles.
3. **Data at 0x646F0**: This is CODE (function prologue), not data. The actual data constants are at 0x6438A and 0x646E8.
4. **Missing function**: Added `calculate_vector_scale_factor` at 0x646F4 which was partially analyzed but not properly identified.

## KEY INSIGHTS:
- This region contains core rendering algorithms for quadrilaterals and vectors with transformation support.
- The system supports both hardware-accelerated path rendering (via buffer at 0x2016380) and software pixel-by-pixel rendering.
- Fixed-point math is used extensively with 16.16 format (shift right 16 bits to get integer part).
- The rendering pipeline includes clipping, transformation, coordinate conversion, and trapezoid decomposition.
- Function pointers at 0x201637c allow different rendering backends to be plugged in.

; === CHUNK 7: 0x64800-0x65400 ===

## CORRECTED ANALYSIS: 0x64800-0x65400

### 1. 0x64800 - `clip_coordinate_to_bound` (CORRECTED)
**Entry:** 0x64800  
**Purpose:** Clips a coordinate value to a maximum bound. Takes a floating-point coordinate, checks if it exceeds the clipping bound at 0x201628c, and if so, clips it to the bound. Handles sign manipulation for negative coordinates.  
**Arguments:** fp@(8) = coordinate value to clip (float)  
**Return:** D2 = clipped coordinate (float)  
**Hardware:** 
- 0x201628c: clipping bound (float)
- 0x20174dc: unknown parameter (float)  
**Key calls:** 
- 0x89980: float compare
- 0x89ab8: float subtract  
- 0x89a88: float operation (likely absolute value)
- 0x89968: float compare  
**Algorithm:**
1. Check if coordinate is negative (bchg #31 flips sign bit)
2. Compare against clipping bound at 0x201628c
3. If exceeds bound, subtract bound from coordinate
4. Return clipped value in D2  
**Cross-ref:** Called from coordinate transformation routines, likely used for clipping to device bounds.

### 2. 0x6493c - `compute_vector_angle_and_normalize` (CORRECTED)
**Entry:** 0x6493c  
**Purpose:** Computes the angle and normalized vector between two points. Used for line/stroke calculations in PostScript rendering.  
**Arguments:** 
- fp@(8), fp@(12) = first point (x1, y1)
- fp@(16), fp@(20) = second point (x2, y2)  
- fp@(24) = output pointer for normalized vector  
**Return:** D0 = 1 if successful (vector length ≥ threshold), 0 if vector too small  
**Hardware:** 
- 0x20162a4: minimum vector length threshold (float)
- 0x201628c: clipping bound (float)  
**Key calls:**
- 0x2f26: vector difference (x2-x1, y2-y1)
- 0xffffb708: atan2 (computes angle from vector)
- 0x2f8a: vector normalization
- 0x899c8, 0x89980, 0x9a70: float operations  
**Algorithm:**
1. Compute vector v = (x2-x1, y2-y1) via 0x2f26
2. Compute angle via atan2(y, x) at 0xffffb708
3. Check if vector length ≥ threshold at 0x20162a4
4. If valid, normalize vector via 0x2f8a
5. Store normalized vector at output pointer  
**Cross-ref:** Called from line drawing and stroke calculation routines.

### 3. 0x64a6e - `draw_bezier_curve_recursive` (CORRECTED)
**Entry:** 0x64a6e  
**Purpose:** Implements cubic Bezier curve rendering using recursive subdivision (de Casteljau algorithm). Takes 4 control points and recursively subdivides until curve segments are flat enough for line approximation.  
**Arguments:** 8 coordinate pairs (likely P0,P1,P2,P3 for cubic Bezier)  
**Return:** None (draws curve segments)  
**Hardware:** 
- 0x2016270: path construction flag
- 0x2016274: subdivision state flag
- 0x2016360: current curve parameter t
- 0x2016364-0x2016370: curve cache
- 0x2016250-0x201625c: current line endpoints
- 0x2017464: graphics state pointer  
**Key calls:**
- 0x2f26: vector difference
- 0x2f58: vector addition
- 0x3018: midpoint calculation
- 0x46f0: angle calculation for flatness test
- 0x4392: draw line segment
- 0x359e: draw line with transformation  
**Algorithm:**
1. Check if in path construction mode (0x2016270)
2. Compute midpoints for de Casteljau subdivision
3. Check curve flatness using angle test (0x46f0)
4. If flat enough, draw line segment via 0x359e or 0x4392
5. Otherwise, recursively subdivide
6. Maintain subdivision depth and parameter t in cache  
**Cross-ref:** Called from PostScript `curveto` operator implementation.

### 4. 0x64de8 - `draw_line_with_clipping` (CORRECTED)
**Entry:** 0x64de8  
**Purpose:** Draws a line segment with clipping and transformation. Handles different rendering modes based on graphics state flags.  
**Arguments:** 
- fp@(8), fp@(12) = start point (x1, y1)
- fp@(16), fp@(20) = end point (x2, y2)  
**Return:** None (draws line)  
**Hardware:** 
- 0x201628c: clipping bound
- 0x2016284: unknown flag
- 0x2017464: graphics state pointer
- 0x2016238-0x201624c: transformation matrix
- 0x2016250-0x201625c: current line endpoints  
**Key calls:**
- 0x2fc6: line intersection test
- 0x4938: clipping calculation
- 0x2f58: vector addition
- 0x2f26: vector difference
- 0x3018: midpoint calculation
- 0x359e: draw line with transformation
- 0x3e56: draw line (simpler version)
- 0x4392: draw line segment  
**Algorithm:**
1. Check if clipping bound is valid (0x201628c)
2. Check if in special rendering mode (0x2016284)
3. Test line intersection with clipping region via 0x2fc6
4. Based on intersection result and graphics state, either:
   - Clip line using 0x4938
   - Draw transformed line via 0x359e
   - Draw simple line via 0x3e56
5. Handle different cases for positive/negative intersection results  
**Cross-ref:** Called from line drawing operators like `lineto`.

### 5. 0x65090 - `set_current_point` (NEW)
**Entry:** 0x65090  
**Purpose:** Sets the current point in the graphics state and updates transformation-related variables.  
**Arguments:** 
- fp@(8), fp@(12) = new current point (x, y)  
**Return:** None  
**Hardware:**
- 0x2016240-0x2016244: current point
- 0x2016218-0x201621c: unknown point storage
- 0x2016238-0x201624c: transformation matrix
- 0x2016210-0x2016214: transformed point storage
- 0x2016260: flag (set to 1)
- 0x2016270: path construction flag
- 0x201636c: curve subdivision counter
- 0x2016360: curve parameter t
- 0x2016274: subdivision state flag  
**Key calls:**
- 0x3094: transform point (applies transformation matrix)  
**Algorithm:**
1. Store new point at 0x2016240-0x2016244
2. Also store at 0x2016218-0x201621c
3. Transform point via 0x3094 and store result at 0x2016210-0x2016214
4. Set flag at 0x2016260 to 1
5. If in path construction mode (0x2016270), restore curve subdivision state from cache  
**Cross-ref:** Called from PostScript `moveto` operator.

### 6. 0x65110 - `draw_line_from_current_point` (NEW)
**Entry:** 0x65110  
**Purpose:** Draws a line from the current point to a new point, with clipping and transformation. Handles special cases for very short lines and coordinate limits.  
**Arguments:** 
- fp@(8), fp@(12) = destination point (x, y)  
**Return:** None (draws line)  
**Hardware:**
- 0x2016280: unknown flag
- 0x2016240-0x2016244: current point
- 0x2016238-0x201624c: transformation matrix
- 0x2017464: graphics state pointer
- 0x2016270: path construction flag
- 0x2016260: flag
- 0x2016230-0x2016234: transformed vector storage
- 0x2016228-0x201622c: transformed midpoint storage
- 0x2016220-0x2016224: transformed point storage  
**Key calls:**
- 0x2f58: vector addition
- 0x3094: transform point
- 0x2f26: vector difference
- 0x3018: midpoint calculation
- 0x359e: draw line with transformation
- 0x46f0: angle calculation
- 0x2f8a: vector normalization
- 0xffffb708: atan2  
**Algorithm:**
1. Check if 0x2016280 flag is set (coordinate limit check)
2. If set, check if coordinates exceed bounds (using 0x2f58 and float comparisons)
3. Transform destination point via 0x3094
4. Compute vector from current to destination point
5. Handle special cases for horizontal/vertical lines
6. Compute angle and normalize vector if needed
7. Store transformed vectors for later use
8. Draw line via 0x359e if not in path construction mode  
**Cross-ref:** Called from PostScript `lineto` operator.

### DATA REGIONS:
- **0x64920-0x6493b:** Float constants (likely 1.0 and π/180 or similar)
  - 0x64920: 0x3ff00000 (1.0 in IEEE 754)
  - 0x6492e: 0x3f50624d (0.000977 in IEEE 754, possibly 1/1024)
- **0x64a68-0x64a6d:** Float constant 0x3ff00000 (1.0)
- **0x64d8-0x64dd:** Float constants referenced by PC-relative addressing
  - Used in coordinate limit checks (likely 1.0 or similar bounds)

### CORRECTIONS TO PRIOR ANALYSIS:
1. **0x64de8 function name:** Changed from truncated "draw_line_with_clipping" to full name.
2. **Added two new functions:** 0x65090 (`set_current_point`) and 0x65110 (`draw_line_from_current_point`).
3. **Fixed algorithm descriptions:** Provided more specific details about each function's logic.
4. **Clarified hardware usage:** Each function now has complete list of RAM addresses accessed.
5. **Corrected cross-references:** Linked functions to PostScript operators they implement.

### KEY INSIGHTS:
This region contains core graphics primitives for PostScript rendering:
- Coordinate clipping (0x64800)
- Vector math utilities (0x6493c)
- Bezier curve rendering (0x64a6e) - implements de Casteljau algorithm
- Line drawing with clipping (0x64de8)
- Current point management (0x65090) - for `moveto`
- Line drawing from current point (0x65110) - for `lineto`

These functions work together to implement the PostScript path construction operators, handling transformation, clipping, and curve flattening for the rasterization pipeline.

; === CHUNK 8: 0x65400-0x66000 ===

## REFINED ANALYSIS: 0x65400-0x66000

### 1. 0x65400 - `finish_path_segment` (CORRECTED)
**Entry:** 0x65400 (continuation, no LINK)  
**Purpose:** Completes a path segment by checking if clipping is needed (0x2016274), then calls clipping function at 0x4de8 if required. Updates path endpoint coordinates in RAM (0x2016250-0x201625c). Calls curve processing at 0x4a70. Resets path state flags (0x2016260, 0x2016280, 0x2016284).  
**Arguments:** Local variables on stack: fp@(-12) to fp@(-48) - coordinates and intermediate values  
**Return:** None (void)  
**Hardware:** Accesses 0x2016274 (path clipping flag), 0x2016238-0x201624c (path coordinates), 0x2016260 (path state), 0x201627c/0x2016280/0x2016284 (path flags)  
**Key calls:** 0x4de8 (clip_line_to_rectangle), 0x4a70 (process_curved_path_segment), 0x89a88 (float operation)  
**Callers:** Likely called from path construction operators (lineto, curveto)  
**Note:** This is the CONTINUATION of a function that started before 0x65400 (no LINK instruction at entry). The function ends at 0x654d6 with UNLK/RTS.

### 2. 0x654d8-0x654e6 - DATA (Floating-point constants)
**Address:** 0x654d8-0x654e6  
**Size:** 14 bytes  
**Format:** Two IEEE 754 single-precision floats:
- 0x654d8: 0x3fc99999 = 1.57079637 (π/2)
- 0x654e0: 0x3ff00000 = 1.0
**Note:** The prior analysis correctly identified these as data, not code. The bytes at 0x654e6-0x654ea are padding (0x0000) followed by the start of the next function at 0x654ec.

### 3. 0x654ec - `close_subpath` (CORRECTED)
**Entry:** 0x654ec (LINK A6,#-24)  
**Purpose:** Closes the current subpath by drawing a line from current point back to starting point. Checks clipping mode at 0x201628c and graphics state at 0x2017464+0xa4. Handles three cases: no clipping (returns), even-odd fill (draws line), winding fill (more complex logic).  
**Arguments:** None (operates on current path in RAM)  
**Return:** None (void)  
**Hardware:** Accesses 0x201628c (clipping flag), 0x2017464 (graphics state), 0x2016260 (path state), 0x2016270/0x2016274/0x2016278 (path flags)  
**Key calls:** 0x4392 (draw_line), 0x2f8a (vector operation), 0x3056 (transform), 0x2f26 (vector math), 0x359e (draw_line_with_params)  
**Callers:** PostScript `closepath` operator  
**Algorithm:** Checks if path is open (0x2016260), then draws closing line with appropriate clipping/fill rules. The function ends at 0x656f0 (just before 0x656f2).

### 4. 0x656f2 - `stroke_current_path` (CORRECTED)
**Entry:** 0x656f2 (LINK A6,#0)  
**Purpose:** Strokes (outlines) the current path. Checks if path is open (0x2016260). If open and in clipping mode 1, draws line from start to current point. Otherwise calls stroke function at 0x5110 and handles curved segments.  
**Arguments:** None (operates on current path)  
**Return:** None (void)  
**Hardware:** Accesses 0x2016260 (path state), 0x2017464 (graphics state), 0x2016210-0x2016224 (path coordinates)  
**Key calls:** 0x4392 (draw_line), 0x5110 (stroke_path_main), 0x4de8 (clip_line_to_rectangle)  
**Callers:** PostScript `stroke` operator  
**Note:** Function ends at 0x65782 with UNLK/RTS.

### 5. 0x65784 - `compare_angles` (CORRECTED)
**Entry:** 0x65784 (LINK A6,#-8)  
**Purpose:** Compares two angles or directions. Computes difference between angles at (x1,y1) and (x2,y2) relative to origin. Returns -1, 0, or 1 based on sign of cross product or angle difference.  
**Arguments:** fp@(8),fp@(12) = point1, fp@(16),fp@(20) = point2  
**Return:** D0 = -1 (counter-clockwise), 0 (collinear), 1 (clockwise)  
**Key calls:** 0x2bfe0 (atan2 or angle calculation)  
**Algorithm:** Computes angle differences, returns sign of result. Function ends at 0x657ca.

### 6. 0x657cc - `normalize_vector` (CORRECTED)
**Entry:** 0x657cc (LINK A6,#-12)  
**Purpose:** Normalizes a vector (dx,dy) to unit length. Takes absolute values, ensures |dx| ≥ |dy|, computes scaling factor using fixed-point math.  
**Arguments:** D7 = dx, D6 = dy (32-bit fixed-point, 16.16 format)  
**Return:** D0 = normalized dx component (scaled by 0x10000 = 1.0 in 16.16)  
**Key calls:** 0x2c0ca (division), 0x2c022 (multiplication), 0x2c136 (square root)  
**Algorithm:** Swaps components to ensure dx ≥ dy, computes ratio, uses sqrt(1+ratio²) for normalization. Function ends at 0x65844.

### 7. 0x65846 - `compute_normal_and_check_threshold` (NEW)
**Entry:** 0x65846 (LINK A6,#-20)  
**Purpose:** Computes a normal vector from two points and checks if its magnitude exceeds a threshold (0x2022200). If so, normalizes it and stores result.  
**Arguments:** fp@(8),fp@(12) = point1, fp@(16),fp@(20) = point2, fp@(24) = output vector pointer  
**Return:** D0 = 1 if successful (magnitude ≥ threshold), 0 otherwise  
**Key calls:** 0x57cc (normalize_vector), 0x2c07e (division), 0x2bfe0 (atan2/angle)  
**Algorithm:** Computes midpoint, calls normalize_vector, checks threshold, scales result. Function ends at 0x65952.

### 8. 0x65954 - `update_bounding_box` (NEW)
**Entry:** 0x65954 (LINK A6,#-16)  
**Purpose:** Updates a bounding box with new point coordinates. Computes sums and differences, calls a transformation function.  
**Arguments:** fp@(8),fp@(12) = point1, fp@(16),fp@(20) = point2  
**Return:** None (void)  
**Key calls:** 0x30d2 (bounding box update function)  
**Hardware:** Updates 0x2022220-0x202222c (bounding box coordinates)  
**Algorithm:** Computes (p1+p2) and (p1-p2), updates bounding box structure. Function ends at 0x659dc.

### 9. 0x659de - `draw_orthogonal_line` (NEW)
**Entry:** 0x659de (LINK A6,#-8)  
**Purpose:** Draws an orthogonal (axis-aligned) line between two points. Converts coordinates and calls draw_line.  
**Arguments:** fp@(8),fp@(12) = point1, fp@(16),fp@(20) = point2  
**Return:** None (void)  
**Key calls:** 0x2c170 (coordinate conversion), 0x899c8 (float conversion), 0x4392 (draw_line)  
**Algorithm:** Converts both points, draws line between them. Function ends at 0x65a24.

### 10. 0x65a26 - `handle_curved_segment_with_fill` (NEW)
**Entry:** 0x65a26 (LINK A6,#-36)  
**Purpose:** Processes curved path segments with fill rules. Checks various conditions (threshold at 0x2022230, path flags, fill mode) and draws appropriate lines.  
**Arguments:** fp@(8)-fp@(28) - multiple coordinate pairs (likely control points)  
**Return:** None (void)  
**Key calls:** 0x5784 (compare_angles), 0x5846 (compute_normal_and_check_threshold), 0x30d2 (bounding box update), 0x3b9c (draw with fill)  
**Hardware:** Accesses 0x2022230 (threshold), 0x2016284 (path flag), 0x2017464 (graphics state)  
**Algorithm:** Complex logic with multiple branches based on fill mode and angle comparisons. Function ends at 0x65c4c.

### 11. 0x65c4e - `set_path_start_point` (NEW)
**Entry:** 0x65c4e (LINK A6,#0)  
**Purpose:** Sets the starting point of a new path segment. Copies coordinates to path structure and sets path state to open.  
**Arguments:** fp@(8),fp@(12) = starting point coordinates  
**Return:** None (void)  
**Key calls:** 0x1ce8e (coordinate transformation)  
**Hardware:** Updates 0x2022218-0x202221c (current point), 0x20221f8-0x20221fc (path start), 0x2016218-0x201621c (path state), 0x2016260 (path open flag)  
**Algorithm:** Transforms coordinates, stores as start point, marks path as open. Function ends at 0x65c9a.

### 12. 0x65c9c - `draw_line_between_points` (NEW)
**Entry:** 0x65c9c (LINK A6,#-20)  
**Purpose:** Draws a line between two points with clipping/transformation. Handles coordinate ordering (ensures y1 ≤ y2).  
**Arguments:** fp@(8),fp@(12) = point1, fp@(16),fp@(20) = point2  
**Return:** None (void)  
**Key calls:** Hardware drawing function via pointer at 0x201637c  
**Hardware:** Accesses 0x2022218-0x202221c (current point), calls function via pointer at 0x201637c  
**Algorithm:** Ensures coordinates are ordered (y1 ≤ y2), calls hardware drawing function. Function ends at 0x65cee.

### 13. 0x65cf0 - `add_line_to_path` (NEW)
**Entry:** 0x65cf0 (LINK A6,#-56)  
**Purpose:** Adds a line segment to the current path. Handles various cases: small movements (≤16384 in fixed-point), different line caps, and computes perpendicular vectors for stroking.  
**Arguments:** fp@(8),fp@(12) = endpoint coordinates  
**Return:** None (void)  
**Key calls:** 0x1ce8e (coordinate transformation), 0x5c9c (draw_line_between_points), 0x57cc (normalize_vector), 0x2c07e (division), 0x2bfe0 (atan2), 0x5a26 (handle_curved_segment_with_fill), 0x5954 (update_bounding_box)  
**Hardware:** Accesses 0x2016280 (path flag), 0x2017464 (graphics state), 0x2016260 (path open flag), 0x2022218-0x202223c (path coordinates)  
**Algorithm:** Complex function with multiple branches for different line cap styles and movement thresholds. Computes perpendicular vectors for stroking, updates bounding boxes. Function ends at 0x65fa4.

### 14. 0x65fa6 - `flush_path_with_fill` (NEW)
**Entry:** 0x65fa6 (LINK A6,#-24)  
**Purpose:** Flushes the current path with fill rules applied. Checks fill mode and draws appropriate lines.  
**Arguments:** None (operates on current path)  
**Return:** None (void)  
**Key calls:** 0x59de (draw_orthogonal_line)  
**Hardware:** Accesses 0x2022230 (threshold), 0x2017464 (graphics state), 0x2016260 (path state), 0x2022218-0x20221fc (path coordinates)  
**Algorithm:** Checks fill mode (0, 1, or 2), draws lines accordingly. Function incomplete in disassembly (cuts off at 0x65ffe).  

## CORRECTIONS TO PRIOR ANALYSIS:
1. The prior analysis missed functions 0x65846, 0x65954, 0x659de, 0x65a26, 0x65c4e, 0x65c9c, 0x65cf0, and 0x65fa6.
2. The data region at 0x654d8-0x654e6 is correctly identified as floats (π/2 and 1.0).
3. All functions use standard C calling convention (LINK/UNLK).
4. The region contains extensive path rendering logic for PostScript operations: closepath, stroke, lineto, with support for different fill rules and line caps.

## HARDWARE/RAM ADDRESSES FREQUENTLY ACCESSED:
- 0x2016260: Path open/closed state
- 0x2016270-0x2016284: Various path flags (clipping, fill rules)
- 0x2017464: Graphics state pointer
- 0x2022210-0x202223c: Current path coordinates and bounding boxes
- 0x2022230: Threshold value for vector normalization

## KEY ALGORITHMS:
1. **Vector normalization**: Uses fixed-point arithmetic with 16.16 format, ensures |dx| ≥ |dy| for stability.
2. **Fill rule handling**: Even-odd vs. winding fill rules (codes 1 and 2 at graphics state+0xa4).
3. **Line cap styles**: Different handling based on graphics state+0x74.
4. **Small movement optimization**: Skips rendering for movements ≤16384 (0.25 in fixed-point 16.16).

; === CHUNK 9: 0x66000-0x66C00 ===

Looking at the raw disassembly, I can see several issues with the prior analysis. Let me provide a corrected and refined analysis:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Address 0x66000 is NOT a function entry** - It's actually part of a larger function that starts earlier (at 0x5FCC based on the branch at 0x66132). The prior analysis incorrectly identified this as a separate function.

2. **Function at 0x66136** - The prior analysis was mostly correct, but the function name should be more specific.

3. **Function at 0x661AA** - The prior analysis was correct.

4. **Function at 0x66206** - The prior analysis was mostly correct but missed some details.

5. **Function at 0x66608** - The prior analysis was incorrect about the negative offsets; these are actually forward references to functions in other banks.

6. **Function at 0x6664A** - The prior analysis was mostly correct.

7. **Function at 0x668F0** - The prior analysis was truncated.

Let me provide the corrected analysis:

## REFINED ANALYSIS:

### 1. Continuation of function at 0x5FCC (not 0x66000)
**Address:** 0x66000-0x66134  
**Name:** `update_device_clip_rectangles` (part of larger function starting at 0x5FCC)  
**Purpose:** Calculates and updates two clipping rectangles for the output device. The first rectangle uses coordinates from 0x2022220-0x202222C (likely device space), and the second uses coordinates from 0x20221F0-0x202220C (likely user space). Calls transformation functions at 0x2BFE0 and rectangle processing at 0x30D2.  
**Algorithm:** Transforms coordinates using matrix multiplication (0x2BFE0), adds/subtracts offsets, then calls rectangle processing function twice with different parameter sets.  
**Arguments:** None (operates on global graphics state)  
**RAM Access:** 0x2022210, 0x2022214, 0x2022220-0x202223C, 0x2022208, 0x202220C, 0x20221F0-0x20221FC  
**Calls:** 0x2BFE0 (4 times), 0x30D2 (2 times)  
**Returns:** Branches back to 0x5FCC (loop continuation)

### 2. Function at 0x66136
**Entry:** 0x66136  
**Name:** `update_clipping_path_or_region`  
**Purpose:** Updates the clipping path or region based on graphics state flags. Checks if clipping is enabled (0x2016260) and either updates the current clipping path or sets up a new clipping region.  
**Arguments:** None  
**RAM Access:** 0x2016260 (clipping enabled flag), 0x2017464 (graphics state), 0x20221F8-0x20221FC, 0x2016218-0x201621C, 0x2022238-0x202223C, 0x20221F0-0x20221F4, 0x2022208-0x202220C  
**Calls:** 0x59DE (set clipping path), 0x5CF0 (update clipping), 0x5A26 (setup clipping region)  
**Returns:** RTS

### 3. Function at 0x661AA
**Entry:** 0x661AA  
**Name:** `set_pen_state`  
**Purpose:** Sets the pen state (on/off) for drawing operations. Compares the current line width (from graphics state offset 156) against 2.0, and if less, sets various pen control flags.  
**Arguments:** One argument at fp@(8) - pen state (0=off, 1=on)  
**RAM Access:** 0x2017464+156 (line width), 0x201627C (pen state), 0x2016284 (pen active flag), 0x2016280 (inverse pen flag)  
**Calls:** 0x89A88 (float conversion), 0x89968 (float comparison)  
**Data:** Float constant 2.0 at 0x661FC: 0x40000000 0x00000000  
**Returns:** RTS

### 4. Function at 0x66206
**Entry:** 0x66206  
**Name:** `stroke_path_with_dashing`  
**Purpose:** Strokes a path with optional dashing pattern. Very complex function that handles coordinate calculations, dash pattern processing, and calls a rendering callback. Manages dash pattern state machine.  
**Arguments:** None apparent (operates on global path state)  
**Local Variables:** Many (uses fp@(-60) to fp@(-136) for temps)  
**RAM Access:** 0x2016264 (dashing enabled), 0x201626C, 0x2016288, 0x2017464+164 (path flags), 0x201628C (dash offset), 0x2016334 (dash array), 0x2016368 (dash count), 0x2016364, 0x2016270-0x2016278 (dash state), 0x2016370-0x201637C (callback)  
**Calls:** 0x1CE8E (2x, coordinate transform), 0x2C218 (3x, dash length calculation), 0x89A88 (float conversion), 0x89968 (float comparison)  
**Algorithm:** Checks if dashing is enabled, processes dash array, calculates dash lengths, manages dash state machine with alternating on/off segments, calls rendering callback for each segment.  
**Returns:** D0 = success flag (0 or 1)

### 5. Function at 0x66608
**Entry:** 0x66608  
**Name:** `calculate_pen_width_adjustment`  
**Purpose:** Calculates a pen width adjustment factor based on input parameters. Uses floating-point operations and calls functions in other banks.  
**Arguments:** Two arguments at fp@(8) and fp@(12) - floating-point values  
**Calls:** 0x899C8 (float operation), 0x5526 (in bank 2, negative offset), 0xB708 (in bank 2, negative offset)  
**Note:** The negative offsets (0xFFFE EEF8 = -0x110DA, 0xFFFF 50C8 = -0xAF38) are relative branches to functions in bank 2 (0x5526 and 0xB708 respectively).  
**Returns:** Floating-point result in D0/D1

### 6. Function at 0x6664A
**Entry:** 0x6664A  
**Name:** `setup_dash_pattern`  
**Purpose:** Sets up dash pattern parameters based on graphics state. Handles both regular and adjusted dash patterns, calculates dash offset and width adjustments.  
**Arguments:** None  
**Local Variables:** Uses fp@(-48) to fp@(-36)  
**RAM Access:** 0x2017464 (graphics state), 0x2016264 (dashing enabled), 0x201628C (dash offset), 0x2016290, 0x2016270, 0x20162AC  
**Calls:** 0x522C (in bank 2, negative offset), 0x89938 (float subtract), 0x89968 (float compare), 0x89AB8 (float multiply), 0x89998 (float operation), 0x899C8 (float operation), 0x89920 (float divide), 0x95BE (in bank 2, negative offset), 0x6608 (previous function)  
**Data:** Float constants at 0x68D8 (1.0), 0x68E0 (0.01), 0x68E8 (0.5)  
**Returns:** RTS

### 7. Function at 0x668F0
**Entry:** 0x668F0  
**Name:** `process_stroke_operation`  
**Purpose:** Main stroke operation processor. Handles complex stroke calculations including dash patterns, line width adjustments, and coordinate transformations.  
**Arguments:** Two arguments: fp@(8) = pointer to path data, fp@(12) = stroke flags  
**Local Variables:** Extensive use of stack frame (fp@(-68) to fp@(4))  
**RAM Access:** 0x2016288, 0x2017464, 0x2016270, 0x20162A8, 0x20162A4, 0x2016264, 0x201628C, 0x20162AC, 0x2016268, 0x20162C4  
**Calls:** 0x664A (setup_dash_pattern), 0x89980 (float compare), 0x89998 (float operation), 0x899C8 (float operation), 0x89A88 (float conversion), 0x89A70 (float multiply), 0x89AB8 (float multiply), 0x89938 (float subtract), 0xDCFE (in bank 2, negative offset), 0x9EAE (in bank 2, negative offset), 0xB708 (in bank 2, negative offset)  
**Algorithm:** Checks path validity, sets up dash patterns, calculates stroke width adjustments, transforms coordinates, processes stroke segments with optional dashing.  
**Returns:** Unknown (function continues beyond 0x66C00)

## DATA REGIONS:

**Float Constants:**
- 0x661FC: 2.0 (0x40000000 0x00000000)
- 0x66600: Unknown data (not a float constant)
- 0x68D8: 1.0 (0x3FF00000 0x00000000)
- 0x68E0: 0.01 (0x3F50624D 0xD2F1A9FC)
- 0x68E8: 0.5 (0x3FE00000 0x00000000)

## KEY INSIGHTS:

1. **Path Rendering System:** This region contains core path rendering functions including stroke processing with dashing support.

2. **Fixed-Point Math:** While there are floating-point operations, the coordinate calculations use fixed-point integers (as seen in the clip rectangle updates).

3. **Dash Pattern Engine:** The function at 0x66206 implements a sophisticated dash pattern state machine that alternates between on/off segments along a path.

4. **Graphics State Management:** Multiple functions access the graphics state at 0x2017464, which is 108 bytes as previously established.

5. **Callback System:** The stroke function uses a callback mechanism at 0x201637C for rendering individual segments.

6. **Bank 2 Integration:** Many functions call into bank 2 (0x5526, 0xB708, etc.) for lower-level operations.

The prior analysis had several inaccuracies, particularly regarding function boundaries and the nature of the negative offsets. The corrected analysis shows a coherent set of path rendering functions that work together to implement PostScript stroke operations with full dashing support.

; === CHUNK 10: 0x66C00-0x67800 ===

## CORRECTED ANALYSIS: 0x66C00-0x67800

### 1. Continuation of `draw_line_or_path` (0x66C00-0x671DC)
**Entry:** 0x66C00 (continuation from 0x66206)  
**Name:** `draw_line_or_path` (part 2)  
**Purpose:** Complex line/path drawing with dash pattern support. This section handles:
- Transformed line width calculation using matrix multiplication (0x66C00-0x66C5A)
- Dash pattern limits (0x2016294-0x20162A0) based on transformed width
- Dash array processing at 0x2016334 with count at 0x2016368
- Dash state flags at 0x2016270-0x2016278
- Dash offset at 0x2016364
- Hardware acceleration callbacks via 0x201637C

**Key Algorithms:**
- Line width transformation: `sqrt((a² + c²) * line_width²)` where a,c are matrix elements
- Dash limits: min/max dash segment lengths (0x2016294/6298 for x, 0x201629C/62A0 for y)
- Dash state machine: toggles between on/off (0x2016278), tracks current dash index (0x2016370)
- Hardware acceleration: calls via 0x201637C for optimized rendering

**Arguments:** Continuation from earlier function (stack frame already established)  
**Returns:** RTS at 0x671C4  
**RAM Access:** 
- 0x2017464: Graphics state base
- 0x201628C: Transformed line width
- 0x2016294-62A0: Dash limits (xmin, xmax, ymin, ymax)
- 0x2016334: Dash array (float values)
- 0x2016368: Dash count
- 0x2016364: Dash offset
- 0x2016270-6278: Dash state flags

**Calls:** 
- 0x89A70 (fadd), 0x89938 (fsub), 0x89A88 (ftst), 0x89968 (fcmpx)
- 0x89AA0 (fdivx), 0x899C8 (fix), 0x89A40 (fintrz), 0x89A10 (fmove)
- 0x89AB8 (fmul), 0x2B990 (sqrt), 0x263BA (error)
- 0x80E4 (unknown), 0xAB70 (graphics_state_update)
- 0x91B8 (unknown), 0x6F3E (unknown), 0x26AEC (unknown)
- 0x9816 (unknown), 0x2EF4 (unknown), 0x5FA0 (unknown)
- 0x6204 (unknown), 0x2C218 (unknown), 0xD60E (unknown)
- 0x8178 (unknown)

**Notes:** This is a large, complex function that handles all aspects of stroked path rendering including dash patterns and hardware acceleration.

### 2. Function `set_graphics_state_matrix` (0x671DE-0x672BC)
**Entry:** 0x671DE  
**Name:** `set_graphics_state_matrix`  
**Purpose:** Sets the current transformation matrix in the graphics state (offset 44). Copies 6-element matrix (24 bytes) and updates related state. Also saves/restores execution context.  
**Arguments:** fp@(8) - pointer to 6-element matrix (float[6])  
**RAM Access:** 
- 0x2017464 (graphics state)
- 0x2016380 (matrix cache)
- 0x20008F4 (current execution context)
- 0x2016397 (unknown byte flag)

**Calls:** 
- 0x664A (update_line_width_or_cap)
- 0x89A88 (ftst)
- 0xE2D0 (matrix_copy_transform)
- 0xA580 (unknown)
- 0x2DF1C (unknown)
- 0x68F0 (unknown)
- 0xA7C2 (matrix_copy)
- 0x2D8D8 (unknown)

**Returns:** D0 = pointer to matrix at 0x201639C

### 3. Function `init_transform_matrix` (0x672BE-0x672DE)
**Entry:** 0x672BE  
**Name:** `init_transform_matrix`  
**Purpose:** Initializes/resets the transformation matrix in graphics state to identity.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state)  
**Calls:** 
- 0xE216 (matrix_init)
- 0xAB70 (graphics_state_update)

**Returns:** RTS

### 4. Function `get_graphics_state_matrix` (0x672E0-0x67336)
**Entry:** 0x672E0  
**Name:** `get_graphics_state_matrix`  
**Purpose:** Retrieves current transformation matrix from graphics state into a buffer.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state)  
**Calls:** 
- 0x71DE (set_graphics_state_matrix)
- 0xA7C2 (matrix_copy)

**Returns:** D0 = pointer to 6-element matrix (in graphics state)

### 5. Function `set_line_width` (0x67338-0x6736E)
**Entry:** 0x67338  
**Name:** `set_line_width`  
**Purpose:** Sets line width in graphics state. Takes absolute value of negative widths.  
**Arguments:** fp@(8) - pointer to line width (float)  
**RAM Access:** 
- 0x2017464 (graphics state, offset 116 = line width)
- 0x2017464+124 (miter limit, cleared to 0)

**Calls:** None  
**Returns:** RTS

### 6. Function `set_line_width_from_stack` (0x67370-0x6738A)
**Entry:** 0x67370  
**Name:** `set_line_width_from_stack`  
**Purpose:** Gets line width from PostScript stack and calls set_line_width.  
**Arguments:** None  
**RAM Access:** None directly  
**Calls:** 
- 0x1B81A (pop_float_from_stack)
- 0x7338 (set_line_width)

**Returns:** RTS

### 7. Function `get_line_width` (0x6738C-0x673A6)
**Entry:** 0x6738C  
**Name:** `get_line_width`  
**Purpose:** Pushes current line width onto PostScript stack.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state, offset 116)  
**Calls:** 0x1BE16 (push_float_to_stack)  
**Returns:** RTS

### 8. Function `set_line_cap` (0x673A8-0x673D8)
**Entry:** 0x673A8  
**Name:** `set_line_cap`  
**Purpose:** Sets line cap style (0=butt, 1=round, 2=square). Validates input range 0-2.  
**Arguments:** None (reads from PostScript stack)  
**RAM Access:** 
- 0x2017464 (graphics state, offset 164, bits 4-5)

**Calls:** 
- 0x1B564 (pop_int_from_stack)
- 0x263BA (error)

**Returns:** RTS

### 9. Function `get_line_cap` (0x673DA-0x673F6)
**Entry:** 0x673DA  
**Name:** `get_line_cap`  
**Purpose:** Pushes current line cap style onto PostScript stack.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state, offset 164, bits 4-5)  
**Calls:** 0x1BB24 (push_int_to_stack)  
**Returns:** RTS

### 10. Function `set_line_join` (0x673F8-0x67428)
**Entry:** 0x673F8  
**Name:** `set_line_join`  
**Purpose:** Sets line join style (0=miter, 1=round, 2=bevel). Validates input range 0-2.  
**Arguments:** None (reads from PostScript stack)  
**RAM Access:** 
- 0x2017464 (graphics state, offset 164, bits 6-7)

**Calls:** 
- 0x1B564 (pop_int_from_stack)
- 0x263BA (error)

**Returns:** RTS

### 11. Function `get_line_join` (0x6742A-0x6744A)
**Entry:** 0x6742A  
**Name:** `get_line_join`  
**Purpose:** Pushes current line join style onto PostScript stack.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state, offset 164, bits 0-1)  
**Calls:** 0x1BB24 (push_int_to_stack)  
**Returns:** RTS

### 12. Function `set_miter_limit` (0x6744C-0x67492)
**Entry:** 0x6744C  
**Name:** `set_miter_limit`  
**Purpose:** Sets miter limit in graphics state. Validates limit >= 1.0.  
**Arguments:** None (reads from PostScript stack)  
**RAM Access:** 
- 0x2017464 (graphics state, offset 120)

**Calls:** 
- 0x1B81A (pop_float_from_stack)
- 0x89A88 (ftst)
- 0x89968 (fcmpx)
- 0x263BA (error)

**Returns:** RTS

### 13. Function `get_miter_limit` (0x6749C-0x674B6)
**Entry:** 0x6749C  
**Name:** `get_miter_limit`  
**Purpose:** Pushes current miter limit onto PostScript stack.  
**Arguments:** None  
**RAM Access:** 0x2017464 (graphics state, offset 120)  
**Calls:** 0x1BE16 (push_float_to_stack)  
**Returns:** RTS

### 14. Function `set_dash` (0x674B8-0x6757C)
**Entry:** 0x674B8  
**Name:** `set_dash`  
**Purpose:** Sets dash pattern array and offset in graphics state. Validates array size <= 11.  
**Arguments:** None (reads from PostScript stack)  
**RAM Access:** 
- 0x2017464+128 (dash array, 12 bytes)
- 0x2017464+136 (dash offset)

**Calls:** 
- 0x1B81A (pop_float_from_stack) - for offset
- 0x1BA8E (pop_array_from_stack) - for dash array
- 0x26AEC (unknown)
- 0x9816 (unknown)
- 0x263BA (error)
- 0x26382 (error)

**Returns:** RTS

### 15. Function `get_dash` (0x6757E-0x675B0)
**Entry:** 0x6757E  
**Name:** `get_dash`  
**Purpose:** Pushes current dash pattern array and offset onto PostScript stack.  
**Arguments:** None  
**RAM Access:** 
- 0x2017464+128 (dash array)
- 0x2017464+136 (dash offset)

**Calls:** 
- 0x165AA (push_array_to_stack)
- 0x1BE16 (push_float_to_stack)

**Returns:** RTS

### 16. Function `get_current_dash_pattern` (0x675B2-0x675D6)
**Entry:** 0x675B2  
**Name:** `get_current_dash_pattern`  
**Purpose:** Retrieves current dash pattern from font dictionary into dash state variables.  
**Arguments:** None  
**RAM Access:** 
- 0x2017354 (font dictionary)
- 0x2016374/6378 (dash pattern floats)

**Calls:** None  
**Returns:** RTS

### 17. Function `set_flatness` (0x675D8-0x676A6)
**Entry:** 0x675D8  
**Name:** `set_flatness`  
**Purpose:** Sets flatness tolerance (0=default, 1=user-defined, 2=from dash pattern).  
**Arguments:** fp@(8) - flatness mode (0, 1, or 2)  
**RAM Access:** 
- 0x20162A8 (flatness flag)
- 0x20174DC (unknown)
- 0x2016304-6330 (flatness-related structures)
- 0x2016294-62A0 (dash limits)
- 0x2016398 (flatness value)

**Calls:** 
- 0x2C136 (unknown) - for mode 0
- 0x269FA (unknown) - for mode 1
- 0x75B2 (get_current_dash_pattern) - for mode 2

**Returns:** RTS

### 18. Data Region: Operator Name Table (0x676A6-0x67704)
**Address:** 0x676A6  
**Size:** 94 bytes (0x5E)  
**Format:** Array of 16-bit operator IDs followed by 32-bit handler addresses  
**Content:** PostScript operator dispatch table for line/stroke related operators:
- 0x7710: "stroke" handler at 0x672BE (init_transform_matrix)
- 0x72BE: "strokepath" handler at 0x672E0 (get_graphics_state_matrix)
- 0x7717: "setlinewidth" handler at 0x67370 (set_line_width_from_stack)
- 0x72E0: "currentlinewidth" handler at 0x6738C (get_line_width)
- 0x7722: "setlinecap" handler at 0x673A8 (set_line_cap)
- 0x7370: "currentlinecap" handler at 0x673DA (get_line_cap)
- 0x772F: "setlinejoin" handler at 0x673F8 (set_line_join)
- 0x738C: "currentlinejoin" handler at 0x6742A (get_line_join)
- 0x7740: "setmiterlimit" handler at 0x6744C (set_miter_limit)
- 0x73A8: "currentmiterlimit" handler at 0x6749C (get_miter_limit)
- 0x774B: "setdash" handler at 0x674B8 (set_dash)
- 0x73DA: "currentdash" handler at 0x6757E (get_dash)
- 0x775A: "setflat" handler at 0x675D8 (set_flatness)
- 0x73F8: "currentflat" handler at ??? (incomplete in this chunk)
- 0x7766: "strokeadjust" handler at ??? (incomplete in this chunk)
- 0x742A: "currentstrokeadjust" handler at ??? (incomplete in this chunk)

### 19. Data Region: String Table (0x67710-0x677A8)
**Address:** 0x67710  
**Size:** 152 bytes (0x98)  
**Format:** Null-terminated ASCII strings  
**Content:** PostScript operator names:
- "stroke" (0x67710)
- "strokepath" (0x67717)
- "setlinewidth" (0x67722)
- "currentlinewidth" (0x6772E)
- "setlinecap" (0x6773E)
- "currentlinecap" (0x6774A)
- "setlinejoin" (0x6775A)
- "currentlinejoin" (0x67766)
- "setmiterlimit" (0x67776)
- "currentmiterlimit" (0x67784)
- "setdash" (0x67796)
- "currentdash" (0x6779E)

### 20. Function Start (0x677AC-0x67800)
**Entry:** 0x677AC  
**Name:** Unknown (function prologue only)  
**Purpose:** Appears to be start of another function (saves many registers)  
**Arguments:** Unknown  
**RAM Access:** 
- 0x2017614 (unknown word)
- 0x20177A4 (unknown pointer)
- 0x20177A0 (unknown byte)
- 0x201761C (unknown word)
- 0x20177AE (unknown pointer)
- 0x2017618 (unknown pointer)

**Notes:** Function prologue saves D2-D7, A2-A5, sets up frame pointer. Incomplete in this chunk.

## CORRECTIONS TO PRIOR ANALYSIS:
1. The prior analysis correctly identified most functions but missed the operator name table and string table at the end of the chunk.
2. The function at 0x675D8 is `set_flatness`, not part of dash pattern processing.
3. The data at 0x676A6-0x67704 is an operator dispatch table, not code.
4. The data at 0x67710-0x677A8 is a string table of PostScript operator names.
5. The function starting at 0x677AC is incomplete in this chunk and appears to be unrelated to the line/stroke functions.

## KEY INSIGHTS:
This chunk contains the complete implementation of PostScript line/stroke operators including:
- Line width, cap, join, miter limit, dash pattern, and flatness settings
- Both setter and getter functions for each attribute
- Complex dash pattern state machine in the main drawing function
- Hardware acceleration integration for stroke rendering
- Operator dispatch table linking PostScript names to C functions

; === CHUNK 11: 0x67800-0x68400 ===

Looking at the raw disassembly, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **0x67800-0x6791e** is NOT `decode_and_render_glyph` - it's actually **`decode_charstring`** - a Type 1/Type 2 charstring decoder for Adobe font outlines.

2. **0x67920-0x679d6** is NOT `allocate_or_expand_buffer` - it's **`realloc_buffer`** - a general-purpose buffer reallocation function.

3. **0x67be4-0x67de4** is NOT `garbage_collect_font_cache` - it's **`compact_font_cache`** - it compacts the font cache by removing unused entries.

4. The prior analysis missed several functions and misidentified some data accesses.

## REFINED ANALYSIS:

### 1. 0x67800-0x6791e: `decode_charstring`
- **Entry**: 0x67800
- **Purpose**: Decodes Adobe Type 1/Type 2 charstring (font outline) data. Handles three encoding modes: absolute coordinates (0x6780a-0x67848), relative coordinates (0x6784a-0x67870), and run-length encoded (0x67872-0x678a8).
- **Arguments**: A0 points to output count word, A1 points to encoded charstring data, A2 points to output buffer start (0x02017620)
- **Algorithm**: 
  - Checks LSB of first byte to determine encoding mode (0x6780c)
  - Mode 0 (absolute): Uses lookup table at 0x00053e70 for coordinate deltas
  - Mode 1 (relative): Uses lookup table at 0x000540e4 for coordinate deltas  
  - Mode 2 (RLE): Decodes run-length encoded horizontal/vertical segments
- **RAM access**: 0x02017618 (saves input pointer), 0x02017620 (output buffer)
- **Return**: A5 points to end of decoded coordinates, D0 contains coordinate count
- **Called by**: Font rendering system when processing glyph outlines

### 2. 0x67920-0x679d6: `realloc_buffer`
- **Entry**: 0x67920
- **Purpose**: Reallocates a memory buffer, growing it if needed. Similar to C's realloc().
- **Arguments**: 
  - fp@(8): buffer pointer
  - fp@(12): pointer to current size variable  
  - fp@(16): current offset
  - fp@(20): additional size needed
  - fp@(24): initialization flag
- **Algorithm**: 
  - Checks if allocation is allowed (0x020165b4 flag)
  - Calculates new size = current + additional (0x67936)
  - If current size insufficient, grows by at least 100 bytes (0x67948)
  - Calls memory allocator at 0xfffeb3c8
  - If initialization flag set, calls 0x1e7e6 to copy/initialize data
- **RAM access**: 0x020165b4 (allocation flag), 0x020008f4 (execution context stack)
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Many buffer management functions

### 3. 0x679d8-0x67b18: `ensure_bitmap_range`
- **Entry**: 0x679d8  
- **Purpose**: Ensures bitmap memory is allocated for a given byte range, managing page-aligned (512-byte) allocation.
- **Arguments**: fp@(8) = start offset, fp@(12) = length
- **Algorithm**:
  - Checks if range [start, start+length] is within currently allocated bitmap (0x679e0-0x679f2)
  - If not, calculates page numbers (offset >> 9)
  - Calls `realloc_buffer` to expand bitmap page table if needed
  - Zero-initializes new bitmap pages via 0x1e7c2
- **RAM access**: 0x020165c8-0x020165cc (current bitmap range), 0x020009e4 (bitmap structure)
- **Return**: A0 points to bitmap data at requested offset
- **Called by**: Glyph rendering when bitmap needs expansion

### 4. 0x67b1a-0x67b8a: `init_bitmap_allocator`
- **Entry**: 0x67b1a
- **Purpose**: Initializes the bitmap allocation system, sets up page tables.
- **Arguments**: None (uses 0x020009e4 bitmap structure)
- **Algorithm**:
  - Calculates page count from bitmap size (size + 511 >> 9)
  - Stores in 0x020165c4
  - Calls `realloc_buffer` to allocate page table
  - Sets growth flag at 0x02022240
- **RAM access**: 0x020009e4, 0x020165c4, 0x02022240
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Font cache initialization

### 5. 0x67b8c-0x67be2: `check_bitmap_growth`
- **Entry**: 0x67b8c
- **Purpose**: Checks if bitmap needs to grow for additional data, calls init if needed.
- **Arguments**: fp@(8) = additional size needed
- **Algorithm**:
  - Rounds up bitmap size to next 512-byte boundary (0x67ba0-0x67bac)
  - Checks if growth flag is set (0x02022240)
  - If not set and new size exceeds current allocation, calls `init_bitmap_allocator`
- **RAM access**: 0x020009e4, 0x02022240
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Font cache management

### 6. 0x67be4-0x67de4: `compact_font_cache`
- **Entry**: 0x67be4
- **Purpose**: Compacts the font cache by removing unused entries, reclaiming memory.
- **Arguments**: None
- **Algorithm**:
  - Iterates through font cache entries (0x67bfe-0x67dc6)
  - Checks for unused glyph entries (0x67c1e-0x67c32)
  - Marks unused entries for reuse (0x67c74-0x67c9e)
  - Updates LRU counters (0x67cb6-0x67cd6)
  - Returns unused blocks to free list (0x67cec-0x67d2e)
- **RAM access**: 0x020163b4 (font cache base), 0x020163b8 (free list), 0x020163bc (cache entry count)
- **Return**: D0 = 1 if compaction occurred, 0 if no compaction needed
- **Called by**: Font cache allocation when out of space

### 7. 0x67de6-0x67eae: `allocate_font_cache_entry`
- **Entry**: 0x67de6
- **Purpose**: Allocates a new entry from the font cache free list.
- **Arguments**: fp@(8) = font cache structure, fp@(12) = size needed
- **Algorithm**:
  - Checks if free list is empty, calls `compact_font_cache` if needed (0x67dea-0x67df8)
  - Takes entry from free list (0x67e00-0x67e12)
  - Updates font cache statistics (0x67e1a-0x67e2e)
  - Initializes the allocated entry (0x67e58-0x67e7e)
- **RAM access**: 0x020163b8 (free list), 0x020163b4 (font cache base)
- **Return**: A0 points to allocated entry
- **Called by**: Font loading when new glyph needs caching

### 8. 0x67eb0-0x680a6: `get_font_cache_entry`
- **Entry**: 0x67eb0
- **Purpose**: Retrieves or allocates a font cache entry for a glyph.
- **Arguments**: fp@(8) = font cache structure, fp@(12) = allocation flag
- **Algorithm**:
  - Checks if entry already allocated (0x67ebe-0x67ec6)
  - Handles various cache states: empty, has LRU chain, needs allocation
  - Calls `allocate_font_cache_entry` if needed (0x67f22-0x67f2a)
  - Updates LRU pointers and statistics (0x68020-0x6807e)
- **RAM access**: 0x020163b8 (free list), 0x020163b4 (font cache base)
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Font rendering when accessing cached glyphs

### 9. 0x680a8-0x6816c: `allocate_font_cache_slot`
- **Entry**: 0x680a8
- **Purpose**: Allocates a new slot in the font cache structure.
- **Arguments**: fp@(8) = font cache structure
- **Algorithm**:
  - Checks free list, compacts if empty (0x680ac-0x680bc)
  - Takes entry from free list (0x680c2-0x680d4)
  - Updates cache statistics (0x680d8-0x680f2)
  - Initializes the slot (0x6811a-0x6815e)
- **RAM access**: 0x020163b8 (free list), 0x020163b4 (font cache base)
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Font cache initialization

### 10. 0x6816e-0x681f8: `flush_font_cache`
- **Entry**: 0x6816e
- **Purpose**: Flushes a font cache entry, returning it to free list.
- **Arguments**: fp@(8) = font cache entry, fp@(12) = flush flag
- **Algorithm**:
  - Walks through LRU chain to find entry (0x68186-0x6819c)
  - Returns entry to free list (0x681a0-0x681ae)
  - Updates statistics (0x681b2-0x681c4)
  - Calls `get_font_cache_entry` to reinitialize (0x681dc-0x681e0)
- **RAM access**: 0x020163b8 (free list), 0x020163b4 (font cache base)
- **Return**: D0 = 1 if successful, 0 if failed
- **Called by**: Font cache management when cache is full

### 11. 0x681fa-0x6821e: `execute_with_context`
- **Entry**: 0x681fa
- **Purpose**: Executes a function with a specific execution context.
- **Arguments**: 
  - fp@(8): function pointer to execute
  - fp@(12): context parameter 1
  - fp@(16): context parameter 2
  - fp@(20): context parameter 3
- **Algorithm**: Sets up execution context and calls the function
- **Return**: Result from called function
- **Called by**: Various context-sensitive operations

### 12. 0x68220-0x6824e: `init_font_cache_entry`
- **Entry**: 0x68220
- **Purpose**: Initializes a font cache entry structure.
- **Arguments**: fp@(8) = font cache entry pointer
- **Algorithm**: Zero-initializes the entry structure fields
- **Return**: None
- **Called by**: Font cache allocation functions

### 13. 0x68250-0x682a6: `reset_font_cache`
- **Entry**: 0x68250
- **Purpose**: Resets a font cache to initial state.
- **Arguments**: fp@(8) = font cache structure
- **Algorithm**:
  - Iterates through all entries, calling `init_font_cache_entry` (0x68260-0x68274)
  - Resets cache statistics and pointers (0x68276-0x682a0)
- **RAM access**: 0x020165bc (cache counter), 0x02022240 (growth flag)
- **Return**: None
- **Called by**: Font system initialization

### 14. 0x682a8-0x682da: `reset_all_font_caches`
- **Entry**: 0x682a8
- **Purpose**: Resets all font caches in the system.
- **Arguments**: None
- **Algorithm**: Iterates through all font cache structures, calling `reset_font_cache`
- **RAM access**: 0x020163b4 (font cache base array), 0x020163bc (cache count)
- **Return**: None
- **Called by**: System initialization

### 15. 0x682dc-0x68338: `shutdown_font_system`
- **Entry**: 0x682dc
- **Purpose**: Shuts down the font system, freeing allocated resources.
- **Arguments**: None
- **Algorithm**:
  - Calls `reset_font_cache` on main font cache (0x682e0-0x682ea)
  - Frees bitmap buffers if allocated (0x682f4-0x68330)
  - Calls cleanup function at 0xffff4582
- **RAM access**: 0x020165b4 (allocation flag), 0x020165ac/0x020165b0 (buffer pointers)
- **Return**: None
- **Called by**: System shutdown

### 16. 0x6833a-0x6835e: `calculate_font_metrics`
- **Entry**: 0x6833a
- **Purpose**: Calculates font metrics (likely advance widths or bounding boxes).
- **Arguments**: Uses global variables at 0x020009e0 and 0x020009c8
- **Algorithm**: Multiplies two values and calls 0x2de50 (likely a fixed-point operation)
- **Return**: Calculation result
- **Called by**: Font rendering system

### 17. 0x68360-0x6836c: `font_system_cleanup`
- **Entry**: 0x68360
- **Purpose**: Performs cleanup of font system resources.
- **Arguments**: None
- **Algorithm**: Calls cleanup function at 0x26382
- **Return**: None
- **Called by**: System cleanup

### 18. 0x6836e-0x68384: `set_bitmap_structure`
- **Entry**: 0x6836e
- **Purpose**: Sets the current bitmap structure pointer.
- **Arguments**: fp@(8) = bitmap structure pointer
- **Algorithm**: Stores pointer at 0x020009e4 and zeroes first field
- **RAM access**: 0x020009e4 (bitmap structure pointer)
- **Return**: None
- **Called by**: Bitmap system initialization

### 19. 0x68386-0x68400: `init_font_cache_system` (partial - continues beyond 0x68400)
- **Entry**: 0x68386
- **Purpose**: Initializes the font cache system based on configuration.
- **Arguments**: None
- **Algorithm**:
  - Looks up configuration based on 0x02016590 index
  - Sets up font cache base, bitmap dimensions, and other parameters
  - Uses lookup tables at 0x020163c0-0x020163cc
- **RAM access**: 0x02016590 (configuration index), 0x020163c0-0x020163cc (config tables)
- **Return**: None (function continues beyond 0x68400)
- **Called by**: System initialization

## KEY INSIGHTS:

1. **Font Cache Structure**: The font cache uses a free list (0x020163b8) and LRU management. Each cache entry appears to be 40 bytes (0x28) based on the increments at 0x67da2.

2. **Bitmap Management**: Uses 512-byte pages (>> 9 for page calculation). The bitmap system has its own allocation buffers at 0x020165a0 and 0x02016594.

3. **Configuration System**: Font cache configuration is selected by index at 0x02016590, with lookup tables providing different parameter sets.

4. **Error Handling**: Many functions return D0=1 for success, D0=0 for failure, with cleanup functions called on failure.

5. **Memory Management**: Tight integration with the system's malloc/free system at 0xfffeb3c8.

The code in this range shows a sophisticated font caching and bitmap management system optimized for PostScript font rendering, with LRU cache management, bitmap page allocation, and configuration-driven initialization.

; === CHUNK 12: 0x68400-0x69000 (LLM error) ===


/home/fletto/ext/src/claude/agfa9000/3.bin:     file format binary


Disassembly of section .data:

00008400 <.data+0x8400>:
    68400:	0201 6590      	andib #-112,%d1
    68404:	e580           	asll #2,%d0
    68406:	2200           	movel %d0,%d1
    68408:	e781           	asll #3,%d1
    6840a:	4480           	negl %d0
    6840c:	d081           	addl %d1,%d0
    6840e:	41f9 0201 63d0 	lea 0x20163d0,%a0
    68414:	2d70 0800 ffdc 	movel %a0@(0000000000000000,%d0:l),%fp@(-36)
    6841a:	2039 0201 6590 	movel 0x2016590,%d0
    68420:	e580           	asll #2,%d0
    68422:	2200           	movel %d0,%d1
    68424:	e781           	asll #3,%d1
    68426:	4480           	negl %d0
    68428:	d081           	addl %d1,%d0
    6842a:	41f9 0201 63d8 	lea 0x20163d8,%a0
    68430:	23f0 0800 0201 	movel %a0@(0000000000000000,%d0:l),0x20163bc
    68436:	63bc 
    68438:	2039 0201 6590 	movel 0x2016590,%d0
    6843e:	e580           	asll #2,%d0
    68440:	2200           	movel %d0,%d1
    68442:	e781           	asll #3,%d1
    68444:	4480           	negl %d0
    68446:	d081           	addl %d1,%d0
    68448:	41f9 0201 63d4 	lea 0x20163d4,%a0
    6844e:	2d70 0800 fff0 	movel %a0@(0000000000000000,%d0:l),%fp@(-16)
    68454:	202e fff0      	movel %fp@(-16),%d0
    68458:	4c39 0800 0200 	mulsl 0x20009e0,%d0
    6845e:	09e0 
    68460:	23c0 0202 21e8 	movel %d0,0x20221e8
    68466:	2d79 0200 09e0 	movel 0x20009e0,%fp@(-20)
    6846c:	ffec 
    6846e:	42b9 0202 21e4 	clrl 0x20221e4
    68474:	72ff           	moveq #-1,%d1
    68476:	23c1 0202 21e0 	movel %d1,0x20221e0
    6847c:	6014           	bras 0x8492
    6847e:	52b9 0202 21e4 	addql #1,0x20221e4
    68484:	2039 0202 21e0 	movel 0x20221e0,%d0
    6848a:	e380           	asll #1,%d0
    6848c:	23c0 0202 21e0 	movel %d0,0x20221e0
    68492:	202e ffec      	movel %fp@(-20),%d0
    68496:	e280           	asrl #1,%d0
    68498:	2d40 ffec      	movel %d0,%fp@(-20)
    6849c:	66e0           	bnes 0x847e
    6849e:	202e ffe0      	movel %fp@(-32),%d0
    684a2:	d0ae ffdc      	addl %fp@(-36),%d0
    684a6:	206e ffd4      	moveal %fp@(-44),%a0
    684aa:	41f0 0a00      	lea %a0@(0000000000000000,%d0:l:2),%a0
    684ae:	2d48 ffc8      	movel %a0,%fp@(-56)
    684b2:	202e ffdc      	movel %fp@(-36),%d0
    684b6:	4c79 0800 0201 	divsll 0x20163bc,%d0,%d0
    684bc:	63bc 
    684be:	0280 ffff fe00 	andil #-512,%d0
    684c4:	2d40 ffd8      	movel %d0,%fp@(-40)
    684c8:	4c39 0800 0201 	mulsl 0x20163bc,%d0
    684ce:	63bc 
    684d0:	e380           	asll #1,%d0
    684d2:	91c0           	subal %d0,%a0
    684d4:	2d48 ffcc      	movel %a0,%fp@(-52)
    684d8:	2d48 ffd0      	movel %a0,%fp@(-48)
    684dc:	2d6e ffd4 fffc 	movel %fp@(-44),%fp@(-4)
    684e2:	2d6e fffc fff8 	movel %fp@(-4),%fp@(-8)
    684e8:	202e fff0      	movel %fp@(-16),%d0
    684ec:	4c39 0800 0201 	mulsl 0x20163bc,%d0
    684f2:	63bc 
    684f4:	e780           	asll #3,%d0
    684f6:	2200           	movel %d0,%d1
    684f8:	e581           	asll #2,%d1
    684fa:	d081           	addl %d1,%d0
    684fc:	d0ae fffc      	addl %fp@(-4),%d0
    68500:	2d40 fff4      	movel %d0,%fp@(-12)
    68504:	b088           	cmpl %a0,%d0
    68506:	6e24           	bgts 0x852c
    68508:	2008           	movel %a0,%d0
    6850a:	90ae fff4      	subl %fp@(-12),%d0
    6850e:	4c7c 0800 0000 	divsll #1028,%d0,%d0
    68514:	0404 
    68516:	2d40 ffe4      	movel %d0,%fp@(-28)
    6851a:	222e fff0      	movel %fp@(-16),%d1
    6851e:	4c39 1801 0201 	mulsl 0x20163bc,%d1
    68524:	63bc 
    68526:	5281           	addql #1,%d1
    68528:	b081           	cmpl %d1,%d0
    6852a:	6c06           	bges 0x8532
    6852c:	61ff 0001 de54 	bsrl 0x26382
    68532:	42ae ffec      	clrl %fp@(-20)
    68536:	2d79 0201 63b4 	movel 0x20163b4,%fp@(-68)
    6853c:	ffbc 
    6853e:	6000 00bc      	braw 0x85fc
    68542:	206e ffbc      	moveal %fp@(-68),%a0
    68546:	216e fffc 0014 	movel %fp@(-4),%a0@(20)
    6854c:	42ae ffe8      	clrl %fp@(-24)
    68550:	604a           	bras 0x859c
    68552:	206e fffc      	moveal %fp@(-4),%a0
    68556:	4290           	clrl %a0@
    68558:	206e fffc      	moveal %fp@(-4),%a0
    6855c:	42a8 0004      	clrl %a0@(4)
    68560:	206e fffc      	moveal %fp@(-4),%a0
    68564:	42a8 0008      	clrl %a0@(8)
    68568:	206e fffc      	moveal %fp@(-4),%a0
    6856c:	42a8 0010      	clrl %a0@(16)
    68570:	42a8 000c      	clrl %a0@(12)
    68574:	206e fffc      	moveal %fp@(-4),%a0
    68578:	216e ffec 0014 	movel %fp@(-20),%a0@(20)
    6857e:	206e fffc      	moveal %fp@(-4),%a0
    68582:	42a8 0018      	clrl %a0@(24)
    68586:	206e fffc      	moveal %fp@(-4),%a0
    6858a:	42a8 0024      	clrl %a0@(36)
    6858e:	42a8 0020      	clrl %a0@(32)
    68592:	52ae ffe8      	addql #1,%fp@(-24)
    68596:	7228           	moveq #40,%d1
    68598:	d3ae fffc      	addl %d1,%fp@(-4)
    6859c:	202e ffe8      	movel %fp@(-24),%d0
    685a0:	b0ae fff0      	cmpl %fp@(-16),%d0
    685a4:	6dac           	blts 0x8552
    685a6:	206e ffbc      	moveal %fp@(-68),%a0
    685aa:	216e fffc 0018 	movel %fp@(-4),%a0@(24)
    685b0:	206e ffbc      	moveal %fp@(-68),%a0
    685b4:	216e ffd8 0024 	movel %fp@(-40),%a0@(36)
    685ba:	206e ffbc      	moveal %fp@(-68),%a0
    685be:	216e ffcc 0020 	movel %fp@(-52),%a0@(32)
    685c4:	202e ffd8      	movel %fp@(-40),%d0
    685c8:	e380           	asll #1,%d0
    685ca:	d1ae ffcc      	addl %d0,%fp@(-52)
    685ce:	206e ffbc      	moveal %fp@(-68),%a0
    685d2:	42a8 0004      	clrl %a0@(4)
    685d6:	206e ffbc      	moveal %fp@(-68),%a0
    685da:	42a8 001c      	clrl %a0@(28)
    685de:	206e ffbc      	moveal %fp@(-68),%a0
    685e2:	72ff           	moveq #-1,%d1
    685e4:	2141 0008      	movel %d1,%a0@(8)
    685e8:	206e ffbc      	moveal %fp@(-68),%a0
    685ec:	216e fffc 0028 	movel %fp@(-4),%a0@(40)
    685f2:	52ae ffec      	addql #1,%fp@(-20)
    685f6:	722c           	moveq #44,%d1
    685f8:	d3ae ffbc      	addl %d1,%fp@(-68)
    685fc:	202e ffec      	movel %fp@(-20),%d0
    68600:	b0b9 0201 63bc 	cmpl 0x20163bc,%d0
    68606:	6d00 ff3a      	bltw 0x8542
    6860a:	42ae ffc4      	clrl %fp@(-60)
    6860e:	2d6e fffc ffc0 	movel %fp@(-4),%fp@(-64)
    68614:	42ae ffec      	clrl %fp@(-20)
    68618:	602a           	bras 0x8644
    6861a:	206e ffc0      	moveal %fp@(-64),%a0
    6861e:	20ae ffc4      	movel %fp@(-60),%a0@
    68622:	206e ffc0      	moveal %fp@(-64),%a0
    68626:	4268 0004      	clrw %a0@(4)
    6862a:	206e ffc0      	moveal %fp@(-64),%a0
    6862e:	4268 0006      	clrw %a0@(6)
    68632:	2d6e ffc0 ffc4 	movel %fp@(-64),%fp@(-60)
    68638:	06ae 0000 0404 	addil #1028,%fp@(-64)
    6863e:	ffc0 
    68640:	52ae ffec      	addql #1,%fp@(-20)
    68644:	202e ffec      	movel %fp@(-20),%d0
    68648:	b0ae ffe4      	cmpl %fp@(-28),%d0
    6864c:	6dcc           	blts 0x861a
    6864e:	23ee ffc4 0201 	movel %fp@(-60),0x20163b8
    68654:	63b8 
    68656:	7201           	moveq #1,%d1
    68658:	23c1 0201 65bc 	movel %d1,0x20165bc
    6865e:	42b9 0201 65c4 	clrl 0x20165c4
    68664:	42b9 0202 2240 	clrl 0x2022240
    6866a:	2f39 0201 63b4 	movel 0x20163b4,%sp@-
    68670:	6100 fcfc      	bsrw 0x836e
    68674:	584f           	addqw #4,%sp
    68676:	4e5e           	unlk %fp
    68678:	4e75           	rts
    6867a:	4e56 0000      	linkw %fp,#0
    6867e:	6100 fc28      	bsrw 0x82a8
    68682:	53b9 0201 6590 	subql #1,0x2016590
    68688:	2079 0202 21ec 	moveal 0x20221ec,%a0
    6868e:	2068 0040      	moveal %a0@(64),%a0
    68692:	4e90           	jsr %a0@
    68694:	7258           	moveq #88,%d1
    68696:	93b9 0202 21ec 	subl %d1,0x20221ec
    6869c:	4e5e           	unlk %fp
    6869e:	4e75           	rts
    686a0:	4e56 0000      	linkw %fp,#0
    686a4:	4ab9 0201 6590 	tstl 0x2016590
    686aa:	6c06           	bges 0x86b2
    686ac:	61ff 0001 dc86 	bsrl 0x26334
    686b2:	6100 fcd2      	bsrw 0x8386
    686b6:	2079 0202 21ec 	moveal 0x20221ec,%a0
    686bc:	2068 0044      	moveal %a0@(68),%a0
    686c0:	4e90           	jsr %a0@
    686c2:	4e5e           	unlk %fp
    686c4:	4e75           	rts
    686c6:	4e56 ffb8      	linkw %fp,#-72
    686ca:	2039 0201 6590 	movel 0x2016590,%d0
    686d0:	5280           	addql #1,%d0
    686d2:	7204           	moveq #4,%d1
    686d4:	b081           	cmpl %d1,%d0
    686d6:	6606           	bnes 0x86de
    686d8:	61ff 0001 dca8 	bsrl 0x26382
    686de:	0cae 0000 0001 	cmpil #1,%fp@(24)
    686e4:	0018 
    686e6:	6706           	beqs 0x86ee
    686e8:	61ff 0001 dc98 	bsrl 0x26382
    686ee:	52b9 0201 6590 	addql #1,0x2016590
    686f4:	2039 0201 6590 	movel 0x2016590,%d0
    686fa:	e580           	asll #2,%d0
    686fc:	2200           	movel %d0,%d1
    686fe:	e781           	asll #3,%d1
    68700:	4480           	negl %d0
    68702:	d081           	addl %d1,%d0
    68704:	41f9 0201 63c0 	lea 0x20163c0,%a0
    6870a:	21ae 0008 0800 	movel %fp@(8),%a0@(0000000000000000,%d0:l)
    68710:	2039 0201 6590 	movel 0x2016590,%d0
    68716:	e580           	asll #2,%d0
    68718:	2200           	movel %d0,%d1
    6871a:	e781           	asll #3,%d1
    6871c:	4480           	negl %d0
    6871e:	d081           	addl %d1,%d0
    68720:	41f9 0201 63cc 	lea 0x20163cc,%a0
    68726:	21ae 000c 0800 	movel %fp@(12),%a0@(0000000000000000,%d0:l)
    6872c:	2039 0201 6590 	movel 0x2016590,%d0
    68732:	e580           	asll #2,%d0
    68734:	2200           	movel %d0,%d1
    68736:	e781           	asll #3,%d1
    68738:	4480           	negl %d0
    6873a:	d081           	addl %d1,%d0
    6873c:	41f9 0201 63d0 	lea 0x20163d0,%a0
    68742:	21ae 0010 0800 	movel %fp@(16),%a0@(0000000000000000,%d0:l)
    68748:	2039 0201 6590 	movel 0x2016590,%d0
    6874e:	e580           	asll #2,%d0
    68750:	2200           	movel %d0,%d1
    68752:	e781           	asll #3,%d1
    68754:	4480           	negl %d0
    68756:	d081           	addl %d1,%d0
    68758:	41f9 0201 63c8 	lea 0x20163c8,%a0
    6875e:	21b9 0200 09e0 	movel 0x20009e0,%a0@(0000000000000000,%d0:l)
    68764:	0800 
    68766:	2039 0201 6590 	movel 0x2016590,%d0
    6876c:	e580           	asll #2,%d0
    6876e:	2200           	movel %d0,%d1
    68770:	e781           	asll #3,%d1
    68772:	4480           	negl %d0
    68774:	d081           	addl %d1,%d0
    68776:	2040           	moveal %d0,%a0
    68778:	d1fc 0201 63d4 	addal #33645524,%a0
    6877e:	2039 0200 09cc 	movel 0x20009cc,%d0
    68784:	d0b9 0200 09e0 	addl 0x20009e0,%d0
    6878a:	5380           	subql #1,%d0
    6878c:	4c79 0800 0200 	divsll 0x20009e0,%d0,%d0
    68792:	09e0 
    68794:	2080           	movel %d0,%a0@
    68796:	2039 0201 6590 	movel 0x2016590,%d0
    6879c:	e580           	asll #2,%d0
    6879e:	2200           	movel %d0,%d1
    687a0:	e781           	asll #3,%d1
    687a2:	4480           	negl %d0
    687a4:	d081           	addl %d1,%d0
    687a6:	41f9 0201 63d8 	lea 0x20163d8,%a0
    687ac:	21ae 0018 0800 	movel %fp@(24),%a0@(0000000000000000,%d0:l)
    687b2:	2039 0201 6590 	movel 0x2016590,%d0
    687b8:	e580           	asll #2,%d0
    687ba:	2200           	movel %d0,%d1
    687bc:	e781           	asll #3,%d1
    687be:	4480           	negl %d0
    687c0:	d081           	addl %d1,%d0
    687c2:	41f9 0201 63c4 	lea 0x20163c4,%a0
    687c8:	21ae 0014 0800 	movel %fp@(20),%a0@(0000000000000000,%d0:l)
    687ce:	7258           	moveq #88,%d1
    687d0:	d3b9 0202 21ec 	addl %d1,0x20221ec
    687d6:	2079 0201 7368 	moveal 0x2017368,%a0
    687dc:	7264           	moveq #100,%d1
    687de:	d1c1           	addal %d1,%a0
    687e0:	2279 0202 21ec 	moveal 0x20221ec,%a1
    687e6:	7015           	moveq #21,%d0
    687e8:	22d8           	movel %a0@+,%a1@+
    687ea:	51c8 fffc      	dbf %d0,0x87e8
    687ee:	2d79 0200 08f4 	movel 0x20008f4,%fp@(-72)
    687f4:	ffb8 
    687f6:	41ee ffb8      	lea %fp@(-72),%a0
    687fa:	23c8 0200 08f4 	movel %a0,0x20008f4
    68800:	486e ffbc      	pea %fp@(-68)
    68804:	61ff 0002 5716 	bsrl 0x2df1c
    6880a:	584f           	addqw #4,%sp
    6880c:	4a80           	tstl %d0
    6880e:	660e           	bnes 0x881e
    68810:	6100 fb74      	bsrw 0x8386
    68814:	23ee ffb8 0200 	movel %fp@(-72),0x20008f4
    6881a:	08f4 
    6881c:	602a           	bras 0x8848
    6881e:	53b9 0201 6590 	subql #1,0x2016590
    68824:	2079 0202 21ec 	moveal 0x20221ec,%a0
    6882a:	2068 0040      	moveal %a0@(64),%a0
    6882e:	4e90           	jsr %a0@
    68830:	7258           	moveq #88,%d1
    68832:	93b9 0202 21ec 	subl %d1,0x20221ec
    68838:	2f2e fff8      	movel %fp@(-8),%sp@-
    6883c:	2f2e fffc      	movel %fp@(-4),%sp@-
    68840:	61ff 0002 5096 	bsrl 0x2d8d8
    68846:	504f           	addqw #8,%sp
    68848:	2079 0201 7368 	moveal 0x2017368,%a0
    6884e:	217c 0006 94d2 	movel #431314,%a0@(108)
    68854:	006c 
    68856:	2079 0201 7368 	moveal 0x2017368,%a0
    6885c:	217c 0006 960a 	movel #431626,%a0@(112)
    68862:	0070 
    68864:	2079 0201 7368 	moveal 0x2017368,%a0
    6886a:	217c 0006 97e2 	movel #432098,%a0@(128)
    68870:	0080 
    68872:	2079 0201 7368 	moveal 0x2017368,%a0
    68878:	217c 0006 9720 	movel #431904,%a0@(132)
    6887e:	0084 
    68880:	2079 0201 7368 	moveal 0x2017368,%a0
    68886:	217c 0006 9cba 	movel #433338,%a0@(140)
    6888c:	008c 
    6888e:	2079 0201 7368 	moveal 0x2017368,%a0
    68894:	217c 0006 9a1e 	movel #432670,%a0@(144)
    6889a:	0090 
    6889c:	2079 0201 7368 	moveal 0x2017368,%a0
    688a2:	217c 0005 a3f8 	movel #369656,%a0@(148)
    688a8:	0094 
    688aa:	2079 0201 7368 	moveal 0x2017368,%a0
    688b0:	217c 0006 98d8 	movel #432344,%a0@(124)
    688b6:	007c 
    688b8:	2079 0201 7368 	moveal 0x2017368,%a0
    688be:	217c 0006 8360 	movel #426848,%a0@(172)
    688c4:	00ac 
    688c6:	2079 0201 7368 	moveal 0x2017368,%a0
    688cc:	217c 0006 9cea 	movel #433386,%a0@(116)
    688d2:	0074 
    688d4:	2079 0201 7368 	moveal 0x2017368,%a0
    688da:	217c 0006 9d44 	movel #433476,%a0@(120)
    688e0:	0078 
    688e2:	2079 0201 7368 	moveal 0x2017368,%a0
    688e8:	217c 0005 a40a 	movel #369674,%a0@(160)
    688ee:	00a0 
    688f0:	2079 0201 7368 	moveal 0x2017368,%a0
    688f6:	217c 0006 82dc 	movel #426716,%a0@(152)
    688fc:	0098 
    688fe:	2079 0201 7368 	moveal 0x2017368,%a0
    68904:	217c 0006 867a 	movel #427642,%a0@(164)
    6890a:	00a4 
    6890c:	2079 0201 7368 	moveal 0x2017368,%a0
    68912:	217c 0006 86a0 	movel #427680,%a0@(168)
    68918:	00a8 
    6891a:	2079 0201 7368 	moveal 0x2017368,%a0
    68920:	217c 0006 833a 	movel #426810,%a0@(236)
    68926:	00ec 
    68928:	2079 0201 7368 	moveal 0x2017368,%a0
    6892e:	317c 0001 00b8 	movew #1,%a0@(184)
    68934:	4e5e           	unlk %fp
    68936:	4e75           	rts
    68938:	4e56 ff3c      	linkw %fp,#-196
    6893c:	2d79 0200 08f4 	movel 0x20008f4,%fp@(-196)
    68942:	ff3c 
    68944:	41ee ff3c      	lea %fp@(-196),%a0
    68948:	23c8 0200 08f4 	movel %a0,0x20008f4
    6894e:	486e ff40      	pea %fp@(-192)
    68952:	61ff 0002 55c8 	bsrl 0x2df1c
    68958:	584f           	addqw #4,%sp
    6895a:	4a80           	tstl %d0
    6895c:	6600 0104      	bnew 0x8a62
    68960:	486e ff88      	pea %fp@(-120)
    68964:	61ff 0001 503c 	bsrl 0x1d9a2
    6896a:	584f           	addqw #4,%sp
    6896c:	4878 0001      	pea 0x1
    68970:	486e ff88      	pea %fp@(-120)
    68974:	61ff 0001 c880 	bsrl 0x251f6
    6897a:	504f           	addqw #8,%sp
    6897c:	2d40 ff84      	movel %d0,%fp@(-124)
    68980:	6610           	bnes 0x8992
    68982:	487a 0268      	pea %pc@(0x8bec)
    68986:	4878 0018      	pea 0x18
    6898a:	61ff 0002 4f4c 	bsrl 0x2d8d8
    68990:	504f           	addqw #8,%sp
    68992:	486e ffec      	pea %fp@(-20)
    68996:	2f2e ff84      	movel %fp@(-124),%sp@-
    6899a:	61ff 0001 7c54 	bsrl 0x205f0
    689a0:	504f           	addqw #8,%sp
    689a2:	202e fff8      	movel %fp@(-8),%d0
    689a6:	4c7c 0800 0000 	divsll #5,%d0,%d0
    689ac:	0005 
    689ae:	0c80 0000 0fa0 	cmpil #4000,%d0
    689b4:	6f08           	bles 0x89be
    689b6:	203c 0000 0fa0 	movel #4000,%d0
    689bc:	600c           	bras 0x89ca
    689be:	202e fff8      	movel %fp@(-8),%d0
    689c2:	4c7c 0800 0000 	divsll #5,%d0,%d0
    689c8:	0005 
    689ca:	23c0 0201 65ac 	movel %d0,0x20165ac
    689d0:	2039 0201 65ac 	movel 0x20165ac,%d0
    689d6:	6c02           	bges 0x89da
    689d8:	5680           	addql #3,%d0
    689da:	e480           	asrl #2,%d0
    689dc:	0c80 0000 03e8 	cmpil #1000,%d0
    689e2:	6f08           	bles 0x89ec
    689e4:	203c 0000 03e8 	movel #1000,%d0
    689ea:	600c           	bras 0x89f8
    689ec:	2039 0201 65ac 	movel 0x20165ac,%d0
    689f2:	6c02           	bges 0x89f6
    689f4:	5680           	addql #3,%d0
    689f6:	e480           	asrl #2,%d0
    689f8:	23c0 0201 65b0 	movel %d0,0x20165b0
    689fe:	4879 0201 6594 	pea 0x2016594
    68a04:	2f3a 01de      	movel %pc@(0x8be4),%sp@-
    68a08:	61ff 0001 5054 	bsrl 0x1da5e
    68a0e:	504f           	addqw #8,%sp
    68a10:	4a80           	tstl %d0
    68a12:	661e           	bnes 0x8a32
    68a14:	4879 0201 6594 	pea 0x2016594
    68a1a:	42a7           	clrl %sp@-
    68a1c:	2f39 0201 65ac 	movel 0x20165ac,%sp@-
    68a22:	2f3a 01c0      	movel %pc@(0x8be4),%sp@-
    68a26:	61ff 0001 5316 	bsrl 0x1dd3e
    68a2c:	4fef 0010      	lea %sp@(16),%sp
    68a30:	6014           	bras 0x8a46
    68a32:	2f39 0201 65ac 	movel 0x20165ac,%sp@-
    68a38:	4879 0201 6594 	pea 0x2016594
    68a3e:	61ff 0001 5aea 	bsrl 0x1e52a
    68a44:	504f           	addqw #8,%sp
    68a46:	23f9 0201 65ac 	movel 0x20165ac,0x20165b8
    68a4c:	0201 65b8 
    68a50:	7201           	moveq #1,%d1
    68a52:	23c1 0201 65b4 	movel %d1,0x20165b4
    68a58:	23ee ff3c 0200 	movel %fp@(-196),0x20008f4
    68a5e:	08f4 
    68a60:	6006           	bras 0x8a68
    68a62:	42b9 0201 65b4 	clrl 0x20165b4
    68a68:	4ab9 0201 65b4 	tstl 0x20165b4
    68a6e:	6700 0086      	beqw 0x8af6
    68a72:	2d79 0200 08f4 	movel 0x20008f4,%fp@(-196)
    68a78:	ff3c 
    68a7a:	41ee ff3c      	lea %fp@(-196),%a0
    68a7e:	23c8 0200 08f4 	movel %a0,0x20008f4
    68a84:	486e ff40      	pea %fp@(-192)
    68a88:	61ff 0002 5492 	bsrl 0x2df1c
    68a8e:	584f           	addqw #4,%sp
    68a90:	4a80           	tstl %d0
    68a92:	665c           	bnes 0x8af0
    68a94:	4879 0201 65a0 	pea 0x20165a0
    68a9a:	2f3a 014c      	movel %pc@(0x8be8),%sp@-
    68a9e:	61ff 0001 4fbe 	bsrl 0x1da5e
    68aa4:	504f           	addqw #8,%sp
    68aa6:	4a80           	tstl %d0
    68aa8:	661e           	bnes 0x8ac8
    68aaa:	4879 0201 65a0 	pea 0x20165a0
    68ab0:	42a7           	clrl %sp@-
    68ab2:	2f39 0201 65b0 	movel 0x20165b0,%sp@-
    68ab8:	2f3a 012e      	movel %pc@(0x8be8),%sp@-
    68abc:	61ff 0001 5280 	bsrl 0x1dd3e
    68ac2:	4fef 0010      	lea %sp@(16),%sp
    68ac6:	6014           	bras 0x8adc
    68ac8:	2f39 0201 65b0 	movel 0x20165b0,%sp@-
    68ace:	4879 0201 65a0 	pea 0x20165a0
    68ad4:	61ff 0001 5a54 	bsrl 0x1e52a
    68ada:	504f           	addqw #8,%sp
    68adc:	23f9 0201 65b0 	movel 0x20165b0,0x20165c0
    68ae2:	0201 65c0 
    68ae6:	23ee ff3c 0200 	movel %fp@(-196),0x20008f4
    68aec:	08f4 
    68aee:	6006           	bras 0x8af6
    68af0:	42b9 0201 65b4 	clrl 0x20165b4
    68af6:	4e5e           	unlk %fp
    68af8:	4e75           	rts
    68afa:	4e56 0000      	linkw %fp,#0
    68afe:	206e 000c      	moveal %fp@(12),%a0
    68b02:	2028 0004      	movel %a0@(4),%d0
    68b06:	b0ae 0010      	cmpl %fp@(16),%d0
    68b0a:	6610           	bnes 0x8b1c
    68b0c:	2f2e 0008      	movel %fp@(8),%sp@-
    68b10:	61ff 0001 52b2 	bsrl 0x1ddc4
    68b16:	584f           	addqw #4,%sp
    68b18:	7001           	moveq #1,%d0
    68b1a:	6002           	bras 0x8b1e
    68b1c:	7000           	moveq #0,%d0
    68b1e:	4e5e           	unlk %fp
    68b20:	4e75           	rts
    68b22:	4e56 fffc      	linkw %fp,#-4
    68b26:	2f2e 000c      	movel %fp@(12),%sp@-
    68b2a:	487a 00c1      	pea %pc@(0x8bed)
    68b2e:	2f39 0200 08fc 	movel 0x20008fc,%sp@-
    68b34:	61ff 0001 fd8a 	bsrl 0x288c0
    68b3a:	4fef 000c      	lea %sp@(12),%sp
    68b3e:	2f39 0200 08fc 	movel 0x20008fc,%sp@-
    68b44:	206e 0008      	moveal %fp@(8),%a0
    68b48:	2f10           	movel %a0@,%sp@-
    68b4a:	61ff 0001 7b46 	bsrl 0x20692
    68b50:	504f           	addqw #8,%sp
    68b52:	2f39 0200 08fc 	movel 0x20008fc,%sp@-
    68b58:	2079 0200 08fc 	moveal 0x20008fc,%a0
    68b5e:	2068 000e      	moveal %a0@(14),%a0
    68b62:	2068 0014      	moveal %a0@(20),%a0
    68b66:	4e90           	jsr %a0@
    68b68:	584f           	addqw #4,%sp
    68b6a:	206e 0008      	moveal %fp@(8),%a0
    68b6e:	2f28 0004      	movel %a0@(4),%sp@-
    68b72:	487a ff86      	pea %pc@(0x8afa)
    68b76:	4879 0008 0ab0 	pea 0x80ab0
    68b7c:	487a 009a      	pea %pc@(0x8c18)
    68b80:	61ff 0001 4f96 	bsrl 0x1db18
    68b86:	4fef 0010      	lea %sp@(16),%sp
    68b8a:	2d40 fffc      	movel %d0,%fp@(-4)
    68b8e:	6606           	bnes 0x8b96
    68b90:	61ff 0001 d7a2 	bsrl 0x26334
    68b96:	61ff 0001 85a8 	bsrl 0x21140
    68b9c:	4e5e           	unlk %fp
    68b9e:	4e75           	rts
    68ba0:	4e56 0000      	linkw %fp,#0
    68ba4:	202e 0008      	movel %fp@(8),%d0
    68ba8:	6708           	beqs 0x8bb2
    68baa:	7201           	moveq #1,%d1
    68bac:	b081           	cmpl %d1,%d0
    68bae:	6722           	beqs 0x8bd2
    68bb0:	602c           	bras 0x8bde
    68bb2:	42b9 0201 7364 	clrl 0x2017364
    68bb8:	42b9 0201 736c 	clrl 0x201736c
    68bbe:	72ff           	moveq #-1,%d1
    68bc0:	23c1 0201 6590 	movel %d1,0x2016590
    68bc6:	23fc 0201 63d8 	movel #33645528,0x20221ec
    68bcc:	0202 21ec 
    68bd0:	600c           	bras 0x8bde
    68bd2:	4a39 0201 73be 	tstb 0x20173be
    68bd8:	6704           	beqs 0x8bde
    68bda:	6100 fd5c      	bsrw 0x8938
    68bde:	4e5e           	unlk %fp
    68be0:	4e75           	rts
    68be2:	0000 0006      	orib #6,%d0
    68be6:	8c20           	orb %a0@-,%d6
    68be8:	0006 8c2f      	orib #47,%d6
    68bec:	0046 6174      	oriw #24948,%d6
    68bf0:	616c           	bsrs 0x8c5e
    68bf2:	2064           	moveal %a4@-,%a0
    68bf4:	6973           	bvss 0x8c69
    68bf6:	6b20           	bmis 0x8c18
    68bf8:	6572           	bcss 0x8c6c
    68bfa:	726f           	moveq #111,%d1
    68bfc:	7220           	moveq #32,%d1
    68bfe:	2531 6420      	movel %a1@(0000000000000020,%d6:w:4),%a2@-
    68c02:	2d2d 2073      	movel %a5@(8307),%fp@-
    68c06:	7973           	.short 0x7973
    68c08:	7465           	moveq #101,%d2
    68c0a:	6d20           	blts 0x8c2c
    68c0c:	7265           	moveq #101,%d1
    68c0e:	626f           	bhis 0x8c7f
    68c10:	6f74           	bles 0x8c86
    68c12:	696e           	bvss 0x8c82
    68c14:	6721           	beqs 0x8c37
    68c16:	0a00 4442      	eorib #66,%d0
    68c1a:	2f2a 0000      	movel %a2@(0),%sp@-
    68c1e:	0000 4442      	orib #66,%d0
    68c22:	2f44 6973      	movel %d4,%sp@(26995)
    68c26:	706c           	moveq #108,%d0
    68c28:	6179           	bsrs 0x8ca3
    68c2a:	4c69           	.short 0x4c69
    68c2c:	7374           	.short 0x7374
    68c2e:	0044 422f      	oriw #16943,%d4
    68c32:	536f 7572      	subqw #1,%sp@(30066)
    68c36:	6365           	blss 0x8c9d
    68c38:	4c69           	.short 0x4c69
    68c3a:	7374           	.short 0x7374
    68c3c:	0000 0000      	orib #0,%d0
    68c40:	4e56 0000      	linkw %fp,#0
    68c44:	2f39 0201 65d4 	movel 0x20165d4,%sp@-
    68c4a:	2f39 0201 65d0 	movel 0x20165d0,%sp@-
    68c50:	61ff 0000 86e2 	bsrl 0x11334
    68c56:	504f           	addqw #8,%sp
    68c58:	4e5e           	unlk %fp
    68c5a:	4e75           	rts
    68c5c:	4e56 fffc      	linkw %fp,#-4
    68c60:	4879 0201 65d0 	pea 0x20165d0
    68c66:	61ff 0000 d990 	bsrl 0x165f8
    68c6c:	584f           	addqw #4,%sp
    68c6e:	4ab9 0200 09dc 	tstl 0x20009dc
    68c74:	6606           	bnes 0x8c7c
    68c76:	61ff 0000 9834 	bsrl 0x124ac
    68c7c:	42b9 0201 736c 	clrl 0x201736c
    68c82:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68c88:	2d68 0014 fffc 	movel %a0@(20),%fp@(-4)
    68c8e:	603e           	bras 0x8cce
    68c90:	23f9 0201 736c 	movel 0x201736c,0x2017364
    68c96:	0201 7364 
    68c9a:	2039 0200 09e0 	movel 0x20009e0,%d0
    68ca0:	d1b9 0201 736c 	addl %d0,0x201736c
    68ca6:	2f39 0201 736c 	movel 0x201736c,%sp@-
    68cac:	2f39 0201 7364 	movel 0x2017364,%sp@-
    68cb2:	2f2e fffc      	movel %fp@(-4),%sp@-
    68cb6:	487a ff88      	pea %pc@(0x8c40)
    68cba:	61ff ffff f53e 	bsrl 0x81fa
    68cc0:	4fef 0010      	lea %sp@(16),%sp
    68cc4:	4a80           	tstl %d0
    68cc6:	6616           	bnes 0x8cde
    68cc8:	7228           	moveq #40,%d1
    68cca:	d3ae fffc      	addl %d1,%fp@(-4)
    68cce:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68cd4:	202e fffc      	movel %fp@(-4),%d0
    68cd8:	b0a8 0018      	cmpl %a0@(24),%d0
    68cdc:	65b2           	bcss 0x8c90
    68cde:	42b9 0201 7364 	clrl 0x2017364
    68ce4:	61ff 0000 90d8 	bsrl 0x11dbe
    68cea:	72fa           	moveq #-6,%d1
    68cec:	b081           	cmpl %d1,%d0
    68cee:	660a           	bnes 0x8cfa
    68cf0:	42a7           	clrl %sp@-
    68cf2:	61ff 0000 90e8 	bsrl 0x11ddc
    68cf8:	584f           	addqw #4,%sp
    68cfa:	4e5e           	unlk %fp
    68cfc:	4e75           	rts
    68cfe:	4e56 0000      	linkw %fp,#0
    68d02:	202e 0008      	movel %fp@(8),%d0
    68d06:	7201           	moveq #1,%d1
    68d08:	b081           	cmpl %d1,%d0
    68d0a:	6610           	bnes 0x8d1c
    68d0c:	487a ff4e      	pea %pc@(0x8c5c)
    68d10:	487a 000e      	pea %pc@(0x8d20)
    68d14:	61ff 0001 dc32 	bsrl 0x26948
    68d1a:	504f           	addqw #8,%sp
    68d1c:	4e5e           	unlk %fp
    68d1e:	4e75           	rts
    68d20:	7265           	moveq #101,%d1
    68d22:	6e64           	bgts 0x8d88
    68d24:	6572           	bcss 0x8d98
    68d26:	6261           	bhis 0x8d89
    68d28:	6e64           	bgts 0x8d8e
    68d2a:	7300           	.short 0x7300
    68d2c:	4e56 ffe0      	linkw %fp,#-32
    68d30:	202e 000c      	movel %fp@(12),%d0
    68d34:	7210           	moveq #16,%d1
    68d36:	e2a0           	asrl %d1,%d0
    68d38:	2d40 fffc      	movel %d0,%fp@(-4)
    68d3c:	202e 0008      	movel %fp@(8),%d0
    68d40:	7210           	moveq #16,%d1
    68d42:	e2a0           	asrl %d1,%d0
    68d44:	2d40 fff8      	movel %d0,%fp@(-8)
    68d48:	2d6e 0010 ffe4 	movel %fp@(16),%fp@(-28)
    68d4e:	2d6e 0014 ffe0 	movel %fp@(20),%fp@(-32)
    68d54:	202e 0018      	movel %fp@(24),%d0
    68d58:	b0ae 0010      	cmpl %fp@(16),%d0
    68d5c:	660a           	bnes 0x8d68
    68d5e:	202e 001c      	movel %fp@(28),%d0
    68d62:	b0ae 0014      	cmpl %fp@(20),%d0
    68d66:	673a           	beqs 0x8da2
    68d68:	486e fff0      	pea %fp@(-16)
    68d6c:	486e fff4      	pea %fp@(-12)
    68d70:	2f2e fff8      	movel %fp@(-8),%sp@-
    68d74:	2f2e fffc      	movel %fp@(-4),%sp@-
    68d78:	486e ffe8      	pea %fp@(-24)
    68d7c:	486e ffec      	pea %fp@(-20)
    68d80:	2f2e 001c      	movel %fp@(28),%sp@-
    68d84:	2f2e 0018      	movel %fp@(24),%sp@-
    68d88:	486e 0014      	pea %fp@(20)
    68d8c:	486e 0010      	pea %fp@(16)
    68d90:	2f2e 000c      	movel %fp@(12),%sp@-
    68d94:	2f2e 0008      	movel %fp@(8),%sp@-
    68d98:	61ff fffe b6d6 	bsrl 0xffff4470
    68d9e:	4fef 0030      	lea %sp@(48),%sp
    68da2:	202e fffc      	movel %fp@(-4),%d0
    68da6:	5280           	addql #1,%d0
    68da8:	b0ae 0028      	cmpl %fp@(40),%d0
    68dac:	6612           	bnes 0x8dc0
    68dae:	206e 0020      	moveal %fp@(32),%a0
    68db2:	20ae 0010      	movel %fp@(16),%a0@
    68db6:	206e 0024      	moveal %fp@(36),%a0
    68dba:	20ae 0014      	movel %fp@(20),%a0@
    68dbe:	6046           	bras 0x8e06
    68dc0:	202e fffc      	movel %fp@(-4),%d0
    68dc4:	5280           	addql #1,%d0
    68dc6:	91ae 0028      	subl %d0,%fp@(40)
    68dca:	202e 0018      	movel %fp@(24),%d0
    68dce:	b0ae ffe4      	cmpl %fp@(-28),%d0
    68dd2:	670e           	beqs 0x8de2
    68dd4:	202e 0028      	movel %fp@(40),%d0
    68dd8:	4c2e 0800 ffec 	mulsl %fp@(-20),%d0
    68dde:	d0ae 0010      	addl %fp@(16),%d0
    68de2:	206e 0020      	moveal %fp@(32),%a0
    68de6:	2080           	movel %d0,%a0@
    68de8:	202e 001c      	movel %fp@(28),%d0
    68dec:	b0ae ffe0      	cmpl %fp@(-32),%d0
    68df0:	670e           	beqs 0x8e00
    68df2:	202e 0028      	movel %fp@(40),%d0
    68df6:	4c2e 0800 ffe8 	mulsl %fp@(-24),%d0
    68dfc:	d0ae 0014      	addl %fp@(20),%d0
    68e00:	206e 0024      	moveal %fp@(36),%a0
    68e04:	2080           	movel %d0,%a0@
    68e06:	4e5e           	unlk %fp
    68e08:	4e75           	rts
    68e0a:	4e56 ffd0      	linkw %fp,#-48
    68e0e:	48d7 38e0      	moveml %d5-%d7/%a3-%a5,%sp@
    68e12:	2a6e 000c      	moveal %fp@(12),%a5
    68e16:	bbf9 0201 7504 	cmpal 0x2017504,%a5
    68e1c:	6514           	bcss 0x8e32
    68e1e:	bbf9 0201 7570 	cmpal 0x2017570,%a5
    68e24:	640c           	bccs 0x8e32
    68e26:	200d           	movel %a5,%d0
    68e28:	90b9 0201 7504 	subl 0x2017504,%d0
    68e2e:	5280           	addql #1,%d0
    68e30:	6002           	bras 0x8e34
    68e32:	7000           	moveq #0,%d0
    68e34:	3e00           	movew %d0,%d7
    68e36:	6778           	beqs 0x8eb0
    68e38:	206e 0008      	moveal %fp@(8),%a0
    68e3c:	2850           	moveal %a0@,%a4
    68e3e:	264c           	moveal %a4,%a3
    68e40:	7000           	moveq #0,%d0
    68e42:	302d 0004      	movew %a5@(4),%d0
    68e46:	0240 0fff      	andiw #4095,%d0
    68e4a:	2079 0201 757c 	moveal 0x201757c,%a0
    68e50:	52b0 0c00      	addql #1,%a0@(0000000000000000,%d0:l:4)
    68e54:	4aae 0018      	tstl %fp@(24)
    68e58:	674c           	beqs 0x8ea6
    68e5a:	206e 0008      	moveal %fp@(8),%a0
    68e5e:	2c2e 0010      	movel %fp@(16),%d6
    68e62:	9ca8 000c      	subl %a0@(12),%d6
    68e66:	4a86           	tstl %d6
    68e68:	6c06           	bges 0x8e70
    68e6a:	2006           	movel %d6,%d0
    68e6c:	4480           	negl %d0
    68e6e:	6002           	bras 0x8e72
    68e70:	2006           	movel %d6,%d0
    68e72:	7a7f           	moveq #127,%d5
    68e74:	b085           	cmpl %d5,%d0
    68e76:	6c2e           	bges 0x8ea6
    68e78:	206e 0008      	moveal %fp@(8),%a0
    68e7c:	2a2e 0014      	movel %fp@(20),%d5
    68e80:	9aa8 0010      	subl %a0@(16),%d5
    68e84:	4a85           	tstl %d5
    68e86:	6c06           	bges 0x8e8e
    68e88:	2005           	movel %d5,%d0
    68e8a:	4480           	negl %d0
    68e8c:	6002           	bras 0x8e90
    68e8e:	2005           	movel %d5,%d0
    68e90:	727f           	moveq #127,%d1
    68e92:	b081           	cmpl %d1,%d0
    68e94:	6c10           	bges 0x8ea6
    68e96:	38c7           	movew %d7,%a4@+
    68e98:	dc81           	addl %d1,%d6
    68e9a:	e186           	asll #8,%d6
    68e9c:	da81           	addl %d1,%d5
    68e9e:	8c45           	orw %d5,%d6
    68ea0:	38c6           	movew %d6,%a4@+
    68ea2:	6000 0140      	braw 0x8fe4
    68ea6:	38fc 0002      	movew #2,%a4@+
    68eaa:	38c7           	movew %d7,%a4@+
    68eac:	6000 012e      	braw 0x8fdc
    68eb0:	7e0a           	moveq #10,%d7
    68eb2:	2d47 fff0      	movel %d7,%fp@(-16)
    68eb6:	0c6d 8000 0004 	cmpiw #-32768,%a5@(4)
    68ebc:	650e           	bcss 0x8ecc
    68ebe:	7000           	moveq #0,%d0
    68ec0:	302d 0004      	movew %a5@(4),%d0
    68ec4:	0480 0000 8000 	subil #32768,%d0
    68eca:	600a           	bras 0x8ed6
    68ecc:	302d 0004      	movew %a5@(4),%d0
    68ed0:	c0ed 0002      	muluw %a5@(2),%d0
    68ed4:	e388           	lsll #1,%d0
    68ed6:	2d40 ffec      	movel %d0,%fp@(-20)
    68eda:	202e fff0      	movel %fp@(-16),%d0
    68ede:	d0ae ffec      	addl %fp@(-20),%d0
    68ee2:	5280           	addql #1,%d0
    68ee4:	e280           	asrl #1,%d0
    68ee6:	2d40 ffe8      	movel %d0,%fp@(-24)
    68eea:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68ef0:	2028 001c      	movel %a0@(28),%d0
    68ef4:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68efa:	2228 001c      	movel %a0@(28),%d1
    68efe:	d2ae ffe8      	addl %fp@(-24),%d1
    68f02:	b380           	eorl %d1,%d0
    68f04:	0280 ffff fe00 	andil #-512,%d0
    68f0a:	6710           	beqs 0x8f1c
    68f0c:	2f2e ffe8      	movel %fp@(-24),%sp@-
    68f10:	61ff ffff ec7a 	bsrl 0x7b8c
    68f16:	584f           	addqw #4,%sp
    68f18:	4a80           	tstl %d0
    68f1a:	6734           	beqs 0x8f50
    68f1c:	206e 0008      	moveal %fp@(8),%a0
    68f20:	2850           	moveal %a0@,%a4
    68f22:	264c           	moveal %a4,%a3
    68f24:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68f2a:	2d68 001c fff4 	movel %a0@(28),%fp@(-12)
    68f30:	4ab9 0202 2240 	tstl 0x2022240
    68f36:	672a           	beqs 0x8f62
    68f38:	2f2e ffe8      	movel %fp@(-24),%sp@-
    68f3c:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68f42:	2f28 001c      	movel %a0@(28),%sp@-
    68f46:	61ff ffff ea90 	bsrl 0x79d8
    68f4c:	504f           	addqw #8,%sp
    68f4e:	602c           	bras 0x8f7c
    68f50:	2079 0201 7368 	moveal 0x2017368,%a0
    68f56:	2068 00ac      	moveal %a0@(172),%a0
    68f5a:	4e90           	jsr %a0@
    68f5c:	7000           	moveq #0,%d0
    68f5e:	6000 00a0      	braw 0x9000
    68f62:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68f68:	2028 001c      	movel %a0@(28),%d0
    68f6c:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68f72:	2068 0020      	moveal %a0@(32),%a0
    68f76:	41f0 0a00      	lea %a0@(0000000000000000,%d0:l:2),%a0
    68f7a:	2008           	movel %a0,%d0
    68f7c:	2d40 fffc      	movel %d0,%fp@(-4)
    68f80:	2f2e fff0      	movel %fp@(-16),%sp@-
    68f84:	2f00           	movel %d0,%sp@-
    68f86:	4855           	pea %a5@
    68f88:	61ff 0002 4d6e 	bsrl 0x2dcf8
    68f8e:	4fef 000c      	lea %sp@(12),%sp
    68f92:	200d           	movel %a5,%d0
    68f94:	d0ad 0006      	addl %a5@(6),%d0
    68f98:	2d40 fff8      	movel %d0,%fp@(-8)
    68f9c:	206e fffc      	moveal %fp@(-4),%a0
    68fa0:	216e fff0 0006 	movel %fp@(-16),%a0@(6)
    68fa6:	2f2e ffec      	movel %fp@(-20),%sp@-
    68faa:	202e fffc      	movel %fp@(-4),%d0
    68fae:	d0ae fff0      	addl %fp@(-16),%d0
    68fb2:	2f00           	movel %d0,%sp@-
    68fb4:	2f2e fff8      	movel %fp@(-8),%sp@-
    68fb8:	61ff 0002 4d3e 	bsrl 0x2dcf8
    68fbe:	4fef 000c      	lea %sp@(12),%sp
    68fc2:	2079 0200 09e4 	moveal 0x20009e4,%a0
    68fc8:	202e ffe8      	movel %fp@(-24),%d0
    68fcc:	d1a8 001c      	addl %d0,%a0@(28)
    68fd0:	38fc 0004      	movew #4,%a4@+
    68fd4:	28ee fff4      	movel %fp@(-12),%a4@+
    68fd8:	38ee ffea      	movew %fp@(-22),%a4@+
    68fdc:	28ee 0010      	movel %fp@(16),%a4@+
    68fe0:	28ee 0014      	movel %fp@(20),%a4@+
    68fe4:	41ee 0010      	lea %fp@(16),%a0
    68fe8:	226e 0008      	moveal %fp@(8),%a1
    68fec:	7e0c           	moveq #12,%d7
    68fee:	d3c7           	addal %d7,%a1
    68ff0:	2368 0004 0004 	movel %a0@(4),%a1@(4)
    68ff6:	2290           	movel %a0@,%a1@
    68ff8:	206e 0008      	moveal %fp@(8),%a0
    68ffc:	208c           	movel %a4,%a0@
    68ffe:	200b           	movel %a3,%d0


; === CHUNK 13: 0x69000-0x69C00 ===

Looking at this disassembly, I need to correct and refine the prior analysis. The addresses in the prior analysis were relative offsets (0x9000-0x9C00) but the actual ROM addresses are 0x69000-0x69C00. Let me analyze each function properly:

## CORRECTED ANALYSIS:

### 1. `analyze_path_segment` (0x6900a)
**Entry:** 0x6900a  
**Purpose:** Analyzes a Bézier curve segment (4 control points) and determines its type based on coordinate relationships. It stores processed coordinates in a buffer with different packing formats depending on segment type.  
**Arguments:** 
- A0: Pointer to buffer pointer (double indirect)
- FP@(12-32): Coordinates x1,y1,x2,y2,x3,y3,x4,y4 (8 coordinates, 32 bytes)
- FP@(36): Flag indicating if segment should be processed (0=process, non-zero=skip)
**Returns:** D0 = segment type × 8 (0, 8, 16, 24, 32, 40, 48)  
**Algorithm:** 
- Checks if all x coordinates are equal (vertical line → type 1)
- Checks if all y coordinates are equal (horizontal line → type 2)
- Otherwise checks if x1=x4 and y1=y4 (type 3), or if x1=x4 only (type 4), or if y1=y4 only (type 5)
- If none of the above, checks if Δx = Δy (45° diagonal → type 6)
- Otherwise type 7 (general curve)
- Stores coordinates in buffer with different packing: types 1-2 store as 16-bit words, others store as 32-bit fixed-point
**Callers:** Path rendering code for Bézier curve processing

### 2. `store_path_element_with_clipping` (0x69134)
**Entry:** 0x69134  
**Purpose:** Stores a path element (move-to or line-to) with optional clipping. Sets flags in the path buffer to indicate clipping requirements.  
**Arguments:**
- A0: Pointer to buffer pointer
- FP@(12,16): X,Y coordinates (32-bit fixed-point each)
- FP@(20): Clipping flag (non-zero = clipping needed)
- FP@(15): Boolean flag (byte at offset 15)
**Returns:** D0 = status flags (0x40 if clipping needed, 0x80 if coordinates are (-1,-1) special case)  
**Algorithm:**
- Sets flag 0x40 in buffer if clipping is required
- Sets flag 0x80 if coordinates are (-1,-1) special case (indicates end of path)
- Stores coordinates in buffer (32-bit each)
- Calls clipping function at 0xe264 if clipping flag is set
**Callers:** Path construction routines when adding line segments

### 3. `save_current_graphics_point` (0x69194)
**Entry:** 0x69194  
**Purpose:** Saves the current graphics point from global variables into a path buffer. Also copies the point to offset 32 in the buffer structure.  
**Arguments:** A0: Pointer to buffer pointer  
**Returns:** D0 = 0x200 (512) - likely a success code or buffer size increment  
**RAM access:** 
- 0x20175e8: Current X coordinate (global)
- 0x20175ec: Current Y coordinate (global)  
- 0x20009e4: Graphics state structure pointer
**Callers:** Path construction when starting new subpaths or saving current point

### 4. `clip_region_complex_fill` (0x691d6)
**Entry:** 0x691d6  
**Purpose:** Complex clipping region handler for filled paths. Processes clipping against multiple scanlines with memory allocation for clip data. Handles multi-region clipping with SCSI-like data structures.  
**Arguments:** 
- FP@(8,12): Start coordinates
- FP@(16,20): End coordinates  
- FP@(24,28): Additional coordinates
- FP@(32): Pointer to clip region data structure
- FP@(36): Additional parameter
- FP@(40,48): More coordinates
**Algorithm:**
- Calculates scanline positions using 0x20221e0 (clip mask) and 0x20221e4 (shift count)
- Allocates memory for clip data (calls 0x7b8c = malloc)
- Copies SCSI/clip data (calls 0x79d8 = data copy)
- Sets up clip region header in buffer
- Processes each scanline with clipping using `analyze_path_segment` and `store_path_element_with_clipping`
**RAM access:** Extensive - 0x20221e0 (clip mask), 0x2022244, 0x2022240, 0x2017368 (malloc structure)  
**Call targets:** 0x7b8c (malloc), 0x79d8 (data copy), 0x2dcf8 (memcpy), 0x9194 (save_current_graphics_point), 0x900a (analyze_path_segment), 0x9134 (store_path_element_with_clipping), 0x80a8 (flush_buffer)  
**Callers:** Fill path operations with complex clipping regions

### 5. `clip_region_simple_fill` (0x694d2)
**Entry:** 0x694d2  
**Purpose:** Simpler version of clip_region_complex_fill for single-region clipping without memory allocation.  
**Arguments:** Similar to complex version but simpler structure  
**Call targets:** Same as complex version but without malloc/data copy calls  
**Callers:** Simple fill operations with basic clipping

### 6. `clip_region_stroke` (0x6960a)
**Entry:** 0x6960a  
**Purpose:** Clipping for stroked paths (no fill). Similar to simple_fill but specialized for stroke operations.  
**Arguments:** Similar to simple_fill  
**Call targets:** Same as simple_fill  
**Callers:** Stroke path operations

### 7. `render_scanline_segment` (0x69720)
**Entry:** 0x69720  
**Purpose:** Renders a single scanline segment with clipping. Processes a path segment against clip regions for a specific scanline.  
**Arguments:**
- FP@(8): Path segment pointer
- FP@(12): Additional parameter
- FP@(16): Scanline Y coordinate
**Algorithm:**
- Masks Y coordinate with clip mask (0x20221e0)
- Checks if path segment is in valid range (0x2017504-0x2017570)
- Calculates buffer position based on Y coordinate
- Calls 0x8e0a (process_segment_with_clip) to render the segment
**RAM access:** 0x20221e0 (clip mask), 0x20221e4 (shift count), 0x20009e4 (graphics state), 0x2017504/0x2017570 (path segment bounds)  
**Call targets:** 0x8e0a (process_segment_with_clip), 0x80a8 (flush_buffer)  
**Callers:** Scanline rendering routines

### 8. `render_scanline_segment_with_extra` (0x697e2)
**Entry:** 0x697e2  
**Purpose:** Enhanced version of render_scanline_segment with additional parameters for more complex rendering.  
**Arguments:**
- FP@(8): Path segment pointer
- FP@(12,16): Additional parameters
- FP@(20,24): Extra coordinates
- FP@(23): Boolean flag (byte)
**Algorithm:**
- If flag is false, calls simple version (0x9720)
- Otherwise processes with additional clipping using 0x8e0a and 0x9134
**Call targets:** 0x9720 (render_scanline_segment), 0x8e0a (process_segment_with_clip), 0x9134 (store_path_element_with_clipping), 0x80a8 (flush_buffer)  
**Callers:** Complex scanline rendering with extra parameters

### 9. `clip_region_complex_stroke` (0x698d8)
**Entry:** 0x698d8  
**Purpose:** Complex clipping for stroked paths with multiple parameters. Similar to clip_region_complex_fill but for strokes.  
**Arguments:** Many coordinates (up to 12 parameters) similar to complex_fill  
**Call targets:** 0x8e0a (process_segment_with_clip), 0x9194 (save_current_graphics_point), 0x900a (analyze_path_segment), 0x9134 (store_path_element_with_clipping), 0x80a8 (flush_buffer)  
**Callers:** Complex stroke operations

### 10. `process_polygon_scanlines` (0x69a1e) - **NEW FUNCTION MISSED IN PRIOR ANALYSIS**
**Entry:** 0x69a1e  
**Purpose:** Processes polygon scanlines for filling. Handles a polygon defined by vertices and fills it scanline by scanline.  
**Arguments:**
- FP@(8): Polygon vertex pointer (array of words)
- FP@(12,16): Additional parameters
**Algorithm:**
- Extracts polygon bounds from vertex array
- Calculates scanline positions using clip mask
- Iterates through scanlines
- For each scanline, calculates intersection points with polygon edges
- Builds fill segments in buffer
- Uses edge table and active edge list algorithm
**RAM access:** 0x20175ec (current Y), 0x20221e0 (clip mask), 0x20221e4 (shift count), 0x20009e4 (graphics state)  
**Call targets:** 0x80a8 (flush_buffer), 0x9194 (save_current_graphics_point), 0x9134 (store_path_element_with_clipping)  
**Callers:** Polygon fill operations

## KEY CORRECTIONS TO PRIOR ANALYSIS:

1. **Address correction:** All functions are at 0x69000+ offsets, not 0x90000+ offsets.

2. **Function 0x69a1e was completely missed:** This is a significant polygon scanline filler function.

3. **Better function names:** The prior names were too generic. These are specifically clipping and scanline rendering functions for the graphics pipeline.

4. **Algorithm details:** These functions implement:
   - Bézier curve classification and packing optimization
   - Scanline clipping against clip regions
   - Polygon scanline filling with edge table algorithm
   - Memory management for clip data

5. **Hardware interaction:** These functions prepare data for the hardware rendering controller at 0x06100000 by building display lists in buffers.

The code in this region is clearly part of the graphics rendering pipeline, specifically handling path rendering with clipping for both filled and stroked paths, with optimizations for different segment types and scanline-based processing.

; === CHUNK 14: 0x69C00-0x6A800 ===

## REFINED ANALYSIS OF 0x69C00-0x6A800

**CORRECTIONS TO PRIOR ANALYSIS:**
1. The prior analysis correctly identified 5 functions but missed the 6th function at 0x6A55E (actually starts at 0x6A55E, not 0x6A55E as stated).
2. The prior analysis incorrectly described `process_clipped_path_buffer` as having no LINK - it actually has no LINK because it's a continuation from earlier code (likely part of a larger function).
3. The prior analysis missed the data table reference at 0xD600 (PC-relative from 0x6A57E).
4. The prior analysis incorrectly truncated the description of `render_glyph_data` - it continues beyond 0x6A55C.

## FUNCTIONS IN THIS RANGE:

### 1. `process_clipped_path_buffer` (0x69c00)
**Entry:** 0x69c00 (continuation from earlier code, no LINK)  
**Purpose:** Processes a buffer of clipped path data, copying coordinate pairs and managing buffer overflow. Handles clipping region overflow by calling buffer flush routine.  
**Arguments:** 
- A0: Source buffer pointer (from fp@(-44))
- A1: Destination buffer pointer (from fp@(-4))
- D0: Count of elements (from fp@(-32))
**Returns:** None (void)  
**RAM access:** 0x20009e0 (graphics state), 0x20009e4 (rendering flag)  
**Call targets:** 0x2dcf8 (memory copy), 0x80a8 (buffer flush)  
**Called by:** Likely clipping functions from earlier in bank 3  
**Algorithm:** 
1. Copies word pairs (coordinates) from source to dest buffer using memcpy
2. Checks if buffer is full (2056 vs 1024 threshold), flushes if needed
3. Updates pointers and counts, continues processing until all elements copied

### 2. `render_char_outline_wrapper` (0x69cba)
**Entry:** 0x69cba (LINK A6,#-4)  
**Purpose:** Wrapper for character outline rendering with default parameters. Sets up boolean flags and calls the main renderer.  
**Arguments:** Single pointer at fp@(8) (character data structure)  
**Returns:** None (void)  
**Call targets:** 0x9a1e (render_char_outline)  
**Called by:** PostScript charpath/show operators  
**Algorithm:** Sets four byte flags to 0xFF (true), passes them and the char pointer to render_char_outline.

### 3. `complex_clip_region_wrapper` (0x69cea)
**Entry:** 0x69cea (LINK A6,#-4)  
**Purpose:** Wrapper for complex clipping region function with 12 coordinate arguments.  
**Arguments:** 12 coordinates on stack (fp@(8) to fp@(52))  
**Returns:** None (void)  
**Call targets:** 0x91d6 (complex_clip_region)  
**Called by:** PostScript clipping path operators  
**Algorithm:** Sets boolean flags and passes all coordinates to the main clipping function.

### 4. `complex_clip_region_wrapper2` (0x69d44)
**Entry:** 0x69d44 (LINK A6,#0)  
**Purpose:** Another wrapper for complex clipping with same 12 coordinates but different calling convention.  
**Arguments:** 12 coordinates on stack (fp@(8) to fp@(56))  
**Returns:** None (void)  
**Call targets:** 0x91d6 (complex_clip_region)  
**Note:** Nearly identical to previous function but with fp@(56) instead of fp@(52). May handle different data types or coordinate ordering.

### 5. `render_glyph_data` (0x69d88)
**Entry:** 0x69d88 (LINK A6,#-176, saves D2-D7/A2-A5)  
**Purpose:** Main glyph rendering engine - interprets compressed glyph data, applies transformations, clipping, and dispatches to appropriate rasterizer.  
**Arguments:** 
- A5: Pointer to glyph data pointer (indirect)
- D7: Y clipping bound 1
- D6: Y clipping bound 2  
- D5: Boolean flag (0=normal, 1=outline mode)
**Returns:** None (void)  
**RAM access:** 
- 0x20175e8/ec: Current point
- 0x20175fa: Path flag
- 0x2017504: Glyph cache pointer
- 0x2022240: Hardware acceleration flag
- 0x20009e4: Graphics state
- 0x20221ec: HW callback table
- 0x2017368: SW rendering table
- 0x2017610: Fill flag
**Call targets:** 0x816e (validate glyph), 0x79d8 (SCSI/data copy), 0x68d2c (bezier clipping), 0x80a8 (buffer flush), 0x7eb0 (update glyph pointer)  
**Algorithm:** 
1. Validates glyph data (0x816e)
2. Resets current point and sets path flag
3. Loops through glyph commands (word at a time):
   - Bit 0: Simple glyph (cached bitmap) vs outline
   - Bits 1-2: Command type (00=end, 01=glyph ref, 10=image data, 11=bezier curve)
   - Bits 3-5: Transformation type (0=none, 1=translate, 2=scale, 3=rotate, 4=skew, 5=matrix)
   - Bit 6: Has clipping bounds
   - Bit 7: Has fill color
   - Bit 8: Has image data
   - Bit 9: Has current point update
4. Applies clipping to bezier curves using 0x68d2c
5. Dispatches to hardware or software renderer based on 0x2022240 flag
6. Manages glyph cache reference counting
7. Updates glyph pointer position

### 6. `apply_lookup_table` (0x6a55e)
**Entry:** 0x6a55e (LINK A6,#-8, saves A4-A5)  
**Purpose:** Applies a lookup table transformation to a buffer of bytes. Uses a 256-byte lookup table at 0xD600 to transform each byte in the buffer.  
**Arguments:** 
- A5: Buffer pointer (fp@(8))
- D0: Buffer size (fp@(12))
**Returns:** None (void)  
**Data reference:** 0xD600 (256-byte lookup table)  
**Algorithm:** 
1. Processes 8 bytes at a time in a fast loop (0x6a576-0x6a5d6)
2. Processes remaining bytes individually (0x6a5e0-0x6a5ee)
3. Uses table lookup: dest_byte = table[src_byte]

### 7. `read_image_data` (0x6a5fa)
**Entry:** 0x6a5fa (LINK A6,#-8)  
**Purpose:** Reads image data from a source, applies decompression/decoding, and updates image buffer pointers.  
**Arguments:** None (uses global variables)  
**Returns:** D0: Success (0) or error (1)  
**RAM access:** 
- 0x20166c8/c4: Source pointers
- 0x20166cc/d0: Destination buffer pointers
- 0x20166b4: Encoding flag
**Call targets:** 0x11334 (decode function), 0x1b9b4 (read function)  
**Algorithm:** 
1. Attempts to decode data using 0x11334
2. If that fails, reads raw data using 0x1b9b4
3. Updates destination buffer pointers based on read size

### 8. `decode_image_scanline` (0x6a64c)
**Entry:** 0x6a64c (LINK A6,#-40, saves D7/A3-A5)  
**Purpose:** Decodes a single scanline of image data using various pixel formats (1, 2, 4, 8 bpp).  
**Arguments:** None (uses global variables)  
**Returns:** None (void)  
**RAM access:** 
- 0x20166b4: Color mode flag
- 0x2016668/6c: Source size
- 0x20166d4/cc/d0: Buffer pointers
- 0x2016670: Bits per pixel
- 0x2016694: Raw data flag
- 0x201669c: Invert flag
- 0x2017464: Color table pointer
**Algorithm:** 
1. Determines source size based on color mode
2. For packed pixels (1,2,4 bpp): unpacks using bit shifting
3. For raw data (8 bpp): copies directly
4. Applies inversion if 0x201669c is set
5. Applies color lookup table if 0x2017464 has active table

### 9. `allocate_image_buffer` (0x6a7e0)
**Entry:** 0x6a7e0 (LINK A6,#-4, saves A5)  
**Purpose:** Allocates a buffer for image data and initializes it.  
**Arguments:** D0: Size in bytes (fp@(8))  
**Returns:** A5: Pointer to allocated buffer (or NULL)  
**Call targets:** 0x2d98c (malloc wrapper), 0x2db6c (initialize buffer)  
**Algorithm:** 
1. Allocates memory using 0x2d98c
2. If successful, initializes buffer using 0x2db6c
3. Returns pointer or NULL

## DATA REGIONS:
- **0xD600**: 256-byte lookup table referenced by `apply_lookup_table` (PC-relative from 0x6A57E)
- **0x6A55E-0x6A55D**: Actually contains the start of `apply_lookup_table`, not a data region

## CORRECTIONS:
1. The function at 0x6A55E is NOT a data region - it's code for `apply_lookup_table`.
2. The prior analysis missed functions 0x6A5FA, 0x6A64C, and 0x6A7E0.
3. The description of `render_glyph_data` was incomplete - it continues to 0x6A55C and handles complex glyph rendering with caching and reference counting.

## KEY INSIGHTS:
1. This region contains both path/clipping utilities (0x69C00-0x69D86) and image/glyph rendering functions (0x69D88-0x6A7FE).
2. The glyph renderer supports both hardware-accelerated and software rendering paths.
3. The image decoding functions support multiple pixel formats with optional color table application.
4. The lookup table at 0xD600 is likely for gamma correction, color space conversion, or dithering patterns.

; === CHUNK 15: 0x6A800-0x6B400 ===

## CORRECTED AND REFINED ANALYSIS OF 0x6A800-0x6B400

**CORRECTIONS TO PRIOR ANALYSIS:**
1. **Addressing**: The prior analysis incorrectly used 0x6A812, 0x6A930, etc. These are actually offsets from 0xA800 (0x6A800 = 0xA800). The actual function addresses are 0xA812, 0xA930, etc.
2. **Function names**: Several function names were incorrect or too vague.
3. **Data vs Code**: The prior analysis correctly identified this as code, but some function boundaries were wrong.

## DETAILED FUNCTION ANALYSIS:

### 1. Function at 0xA812 - `allocate_bounded_buffer`
**Entry:** 0xA812 (LINKW %fp,#-24)
**Purpose:** Allocates a buffer with size constraints using binary search. Takes minimum count, pointer to count, and element size. Tries to allocate up to 65536 bytes total. Uses binary search between min and max allocations to find optimal size.
**Arguments:** 
- fp@(8): min_count (minimum number of elements)
- fp@(12): count_ptr (pointer to count variable)
- fp@(16): element_size (size of each element)
**Return value:** D0 = allocated buffer address or NULL on failure
**RAM access:** None directly, but calls allocator at 0xA7E0
**Key branches:** 
- 0xA858: Success path after initial allocation
- 0xA918: Error path
- 0xA89E: Binary search loop
**Call targets:** 0xA7E0 (memory allocator), 0x28344 (error handler)
**Called by:** 0xA930 (initialize_memory_pool), 0xA9DE path

### 2. Function at 0xA930 - `initialize_memory_pool`
**Entry:** 0xA930 (LINKW %fp,#-12)
**Purpose:** Initializes a memory pool structure based on system configuration. Sets up buffer sizes and allocation strategies. Handles two modes based on flag at 0x20166B4.
**Arguments:** None (void)
**Return value:** None (initializes global structures)
**RAM access:**
- 0x20166B4: pool type flag (0=normal, 1=special)
- 0x2016660: pool element count
- 0x2016664: pool size per element  
- 0x201666C: pool width parameter
- 0x20166D4: current pool pointer
- 0x2016684: pool stride
- 0x2016688: total pool size
**Key branches:**
- 0xA994: Alternate initialization path (flag = 0)
- 0xA9DE: Special calculation path
**Call targets:** 0x26382 (error handler), 0xA812 (allocate_bounded_buffer), 0xA64C (unknown)
**Called by:** System initialization

### 3. Function at 0xAB4E - `reorganize_memory_pool`
**Entry:** 0xAB4E (LINKW %fp,#-32)
**Purpose:** Reorganizes memory pool, possibly for compaction or garbage collection. Handles moving data within the pool and updating pointers. Supports two different memory layouts.
**Arguments:** None (void)
**Return value:** None
**RAM access:**
- 0x2016690: reorganization flag
- 0x20166B4: pool type flag
- 0x20165E8: pool offset
- 0x20166D4: current pointer
- 0x2016680: pool limit
- 0x201667C: pool start
**Key branches:**
- 0xAB7E: Early exit if no reorganization needed
- 0xAC6C: Alternate layout handling
**Call targets:** 0x2836C (memory free), 0xA64C (unknown)
**Called by:** Memory management routines

### 4. Function at 0xAEB8 - `get_memory_range`
**Entry:** 0xAEB8 (LINKW %fp,#-28)
**Purpose:** Gets a range of memory addresses for operations like font caching or bitmap processing. Handles address translation and boundary conditions. Supports different memory modes.
**Arguments:**
- fp@(8): direction flag (0=backward, non-zero=forward)
- fp@(12): start_ptr (pointer to store start address)
- fp@(16): end_ptr (pointer to store end address)
- fp@(20): current_ptr (pointer to current address variable)
- fp@(24): target_addr (target address)
- fp@(28): context structure pointer
**Return value:** D0 = success (0) or failure (1)
**RAM access:**
- 0x20166B0: memory mode flag
- 0x201668C: range counter
- 0x20165DC: memory start offset
- 0x20165E4: memory size
- 0x20165E0: element size
- 0x20165E8: pool offset
**Key branches:**
- 0xAF18: Early return if no change needed
- 0xAF60: Different mode handling
**Call targets:** 0x89A10, 0x89A88, 0x89968, 0x89A40, 0x89980
**Called by:** Memory management routines

### 5. Function at 0xB0D6 - `draw_rectangle`
**Entry:** 0xB0D6 (LINKW %fp,#-4)
**Purpose:** Draws a rectangle with clipping and optional hardware acceleration. Handles coordinate transformation and clipping boundaries. Supports both software and hardware rendering paths.
**Arguments:**
- fp@(8): x1 (left coordinate)
- fp@(12): y1 (top coordinate)
- fp@(16): x2 (right coordinate)
- fp@(20): y2 (bottom coordinate)
- fp@(24): color/pattern
- fp@(28): operation mode
**Return value:** None
**RAM access:**
- 0x20166A8: hardware acceleration flag
- 0x201669C: clipping enabled flag
- 0x2017464: graphics context pointer
- 0x2016648: clip rectangle left
- 0x201664C: clip rectangle right
- 0x2016630: clip rectangle top
- 0x20165D8: clip rectangle bottom
**Key branches:**
- 0xB156: Hardware acceleration check
- 0xB172: Hardware accelerated path
- 0xB1D2: Software rendering path
**Call targets:** 0x5D72 (coordinate transformation), hardware callback functions
**Called by:** Graphics rendering routines

### 6. Function at 0xB22E - `copy_memory_forward`
**Entry:** 0xB22E (LINKW %fp,#-20)
**Purpose:** Copies memory from a circular buffer to a destination buffer. Handles buffer wrap-around and supports optional bit inversion. Used for raster data transfer.
**Arguments:**
- fp@(8): destination buffer pointer
**Return value:** D0 = success (0) or failure (1)
**RAM access:**
- 0x20166CC: source read pointer
- 0x20166D0: source buffer end
- 0x201666C: copy size parameter
- 0x20166A0: invert flag
**Key branches:**
- 0xB25C: Buffer refill check
- 0xB28A: Inverted copy path (8-byte unrolled)
- 0xB2D0: Normal copy path
**Call targets:** 0xA5FA (refill buffer), 0x2DCF8 (memcpy)
**Called by:** Raster data transfer routines

### 7. Function at 0xB30A - `copy_memory_reverse`
**Entry:** 0xB30A (LINKW %fp,#-20)
**Purpose:** Copies memory from a circular buffer to a destination buffer in reverse order with optional lookup table transformation. Used for mirrored or transformed raster data.
**Arguments:**
- fp@(8): destination buffer pointer (points to end of buffer)
**Return value:** D0 = success (0) or failure (1)
**RAM access:**
- 0x20166CC: source read pointer
- 0x20166D0: source buffer end
- 0x201666C: copy size parameter
- 0x20166A0: invert flag
**Key branches:**
- 0xB33A: Buffer refill check
- 0xB36E: Inverted+transformed copy path (8-byte unrolled with LUT)
- 0xB470: Normal reverse copy path
**Call targets:** 0xA5FA (refill buffer), lookup table at 0xD600
**Called by:** Raster data transfer routines (mirrored output)

## DATA REGIONS:

### 1. Constants at 0xB0CE-0xB0D5
**Address:** 0xB0CE-0xB0D5
**Size:** 8 bytes
**Format:** Two 32-bit floating point constants
- 0xB0CE: 0xBFF00000 = -1.0 (double precision)
- 0xB0D2: 0x00000000 = 0.0 (double precision)
**Purpose:** Used in address range calculations in `get_memory_range`

## KEY INSIGHTS:

1. **Memory Pool System**: This region contains a sophisticated memory pool manager with:
   - Dynamic allocation with binary search optimization
   - Two operational modes (normal/special)
   - Reorganization/compaction capabilities
   - Address range management for font/bitmap operations

2. **Graphics Rendering**: The `draw_rectangle` function shows a hybrid software/hardware architecture:
   - Checks for hardware acceleration availability
   - Falls back to software rendering if needed
   - Supports clipping and coordinate transformation

3. **Raster Data Transfer**: Two specialized copy functions:
   - Forward copy with optional bit inversion
   - Reverse copy with lookup table transformation
   - Both handle circular buffer wrap-around
   - Used for transferring raster data to output devices

4. **Performance Optimizations**:
   - Unrolled loops for 8-byte copies
   - Binary search for optimal buffer sizing
   - Hardware acceleration detection

The code in this region appears to be part of a graphics subsystem for a typesetting/RIP system, handling memory management for font/bitmap data and basic rectangle drawing operations.

; === CHUNK 16: 0x6B400-0x6C000 ===

Looking at this disassembly, I can see it's a continuation of the PostScript interpreter's graphics rendering code. Let me analyze it systematically, correcting and refining the prior analysis.

## CORRECTIONS TO PRIOR ANALYSIS:

The prior analysis had several errors:
1. The addresses were off by 0x1000 (0x6A800 vs 0x6B400)
2. Many function descriptions were too vague or incorrect
3. The code at 0x6B400 is actually the **continuation of `copy_bitmap_reverse`** (not a new function)
4. This region contains **bitmap rendering and rectangle drawing** functions, not memory pool management

## DETAILED ANALYSIS:

### 1. Continuation of `copy_bitmap_reverse` (0x6B400-0x6B49C)
**Entry:** Continuation from 0x6B30A
**What it does:** Continues the reverse bitmap copy operation. This is the unrolled loop for copying 8 bytes at a time using a byte reversal lookup table at 0xD600. Handles the remaining bytes after the main 8-byte loop.
**Algorithm:** Uses A4 as source pointer, A5 as destination pointer (decrementing). For each byte, looks up its reversed version from table at 0xD600 and stores it.
**Registers:** D7 = byte count, A4 = source, A5 = dest
**Hardware access:** None directly
**Key branches:** 0xB474 (loop back for 8-byte chunks), 0xB484 (loop for remaining bytes), 0xB486 (cleanup)

### 2. Function `render_bitmap_scanline` (0x6B49E-0x6B56A)
**Entry:** 0x6B49E
**What it does:** Renders a single scanline of 1-bit bitmap data to a destination buffer. Unpacks 8 pixels per source byte, with optional inversion. Each bit controls whether to set a pixel in the destination.
**Arguments:** 
- A6@(8) = dest_ptr (A5)
- A6@(15) = pixel_value (D7) - byte to OR into destination
- A6@(16) = scanline_stride (D6) - bytes to skip between pixels
- Implicit: bitmap width from 0x201666C
**Algorithm:** Reads bytes from bitmap buffer (0x20166CC-0x20166D0), tests each bit (MSB to LSB), and ORs pixel_value into dest if bit is set. Handles partial bytes at end of scanline.
**RAM access:** 
- 0x20166CC/0x20166D0: bitmap source buffer pointers
- 0x201666C: bitmap width in pixels
- 0x20166A0: invert flag
**Return:** D0 = 0 on success, 1 on buffer underflow
**Call targets:** 0xA5FA (buffer refill), called by rectangle drawing code

### 3. Function `align_and_clip_rectangle` (0x6B56C-0x6B644)
**Entry:** 0x6B56C
**What it does:** Aligns rectangle coordinates to device pixel grid and clips to bounds. Handles coordinate transformation between PostScript space and device pixels.
**Arguments:**
- A6@(8): x_ptr (pointer to x coordinate)
- A6@(12): y coordinate
- A6@(16): width
- A6@(20): target coordinate (for clipping)
- A6@(24): result_ptr (for aligned result)
- A6@(28): current_ptr (current coordinate)
- A6@(32): scale factor
**Algorithm:** Checks if current coordinate equals target; if not, aligns using device transformation matrix. Clips to bounds, updates counters.
**RAM access:**
- 0x20166B0: memory mode flag
- 0x20009E0: transformation matrix element
- 0x20221E0: another matrix element
- 0x20166BC: scale factor
- 0x20166BE: result storage
- 0x2016654: y coordinate storage
- 0x20166BA: counter
**Return:** D0 = 1 if already aligned, 0 if alignment performed
**Call targets:** None directly

### 4. Function `draw_complex_rectangle` (0x6B646-0xC4EC and beyond)
**Entry:** 0x6B646 (massive function spanning multiple pages)
**What it does:** Main rectangle drawing function with full feature support: transformation, clipping, pattern filling, device-specific rendering paths.
**Arguments:**
- A6@(8): rectangle structure pointer
- A6@(12): D7 = fill pattern flag
- A6@(16): D6 = vertical flip flag
- A6@(20): D5 = horizontal flip flag
- A6@(24): pattern data pointer
**Algorithm:** 
1. Sets up drawing mode (0x20166A8 = 1)
2. Computes device-space coordinates using floating-point math (calls 0x899xx routines)
3. Allocates bitmap buffer via 0xA812
4. Sets up transformation matrices
5. Chooses rendering path based on device capabilities (0x20166A4 flag)
6. Handles both memory-mapped (0x20166A4=0) and hardware-accelerated (0x20166A4=1) rendering
**RAM access:**
- 0x20166A8: drawing mode flag
- 0x20166A4: hardware acceleration flag
- 0x201665C/0x2016658: rectangle bounds
- 0x201666C: bitmap width
- 0x2016668: bitmap height
- 0x20166D8: buffer size
- 0x20165FC: allocated buffer pointer
- 0x2017464: graphics state structure
**Call targets:** 
- 0x89A88 (float conversion)
- 0x89998 (float multiplication)
- 0x899C8 (float to integer)
- 0xA812 (bitmap allocation)
- 0x26382 (error handler)
- 0x80E4 (setup function)
- 0x9DD8 (pattern setup)
- 0x5872 (coordinate conversion)
- 0x583C (coordinate adjustment)

### 5. Function `draw_rectangle_scanlines` (0x6BDE4-0xC4EC)
**Entry:** 0x6BDE4 (continuation of draw_complex_rectangle)
**What it does:** Processes individual scanlines of a rectangle, handling different rendering modes (pattern fill, hardware acceleration, memory-mapped).
**Algorithm:** 
1. Calculates scanline bounds and clipping
2. For each scanline, calls appropriate rendering function based on mode
3. Updates coordinate pointers and counters
4. Handles both horizontal and vertical flipping
**RAM access:**
- 0x2016668: bitmap height
- 0x20166BA/0x20166BC: scanline counters
- 0x20166B8: width adjustment
- 0x2016650/0x2016654: current coordinates
- 0x20166D0/0x20166CC: bitmap buffer pointers
**Call targets:**
- 0xB22E (fill_rectangle_scanline)
- 0xB30A (copy_bitmap_reverse)
- 0xB49E (render_bitmap_scanline)
- 0x2DE50 (buffer management)
- 0xDF94 (hardware rendering)
- 0xA7C2 (cleanup)

## KEY DATA STRUCTURES:

### 1. Rectangle structure (passed to draw_complex_rectangle):
- Offset 0: x coordinate
- Offset 4: y coordinate
- Offset 8: width
- Offset 12: height

### 2. Graphics state (0x2017464):
- Offset 140-143: rendering flags (0x8C-0x8F)
- Offset 160: device capabilities pointer
- Offset 84: hardware acceleration flag

### 3. Bitmap buffer management:
- 0x20166CC: current read pointer
- 0x20166D0: buffer end pointer
- 0x201666C: bitmap width in pixels
- 0x20166A0: invert flag

## HARDWARE ACCELERATION PATHS:

The code shows two distinct rendering paths:
1. **Memory-mapped rendering** (0x20166A4=0): Uses software bitmap manipulation
2. **Hardware-accelerated rendering** (0x20166A4=1): Uses hardware commands via 0xDF94

## FIXED-POINT MATH:

The code uses both floating-point (via 0x899xx routines) and fixed-point arithmetic:
- Coordinate scaling uses 8.8 fixed-point (asll #8 / asrl #8)
- Pixel alignment uses 4-bit boundaries (asll #4 / asrl #4)

## ERROR HANDLING:

- Buffer underflow detection in render_bitmap_scanline
- Error returns from allocation functions
- Hardware error checking via 0x2DF1C

This region is clearly part of the PostScript graphics rendering subsystem, specifically handling rectangle drawing operations with support for patterns, transformations, and both software and hardware rendering paths.

; === CHUNK 17: 0x6C000-0x6CC00 ===

Looking at this disassembly, I need to correct several issues from the prior analysis. The code at 0x6C000 is indeed a continuation of a larger function, not a standalone function. Let me provide a corrected analysis:

## CORRECTED ANALYSIS:

### 1. Continuation of Large Rendering Function (0x6C000-0x6C51C)
**Entry:** Continuation from earlier (likely around 0x6B000)
**Name:** `render_page_region` or `process_page_section`
**Purpose:** This is the main rendering loop that processes page regions. It handles:
- Testing if hardware acceleration is available (0x2017464+0xA4 bit 7)
- Based on flag at `fp@(-248)`, calls either hardware vector rendering (0xffffd018) or software raster rendering (0xffff63fa)
- Performs coordinate transformations and clipping operations
- Manages rendering context and error conditions
**Arguments:** Uses frame pointer offsets from parent function
**Returns:** Via RTS at 0x6C51C
**RAM accesses:** 
- 0x20166a4 (rendering flag)
- 0x2016654 (coordinate data)
- 0x2017464 (main system structure)
- 0x20166be (page position)
- 0x20165d8-0x20165f6 (rendering context)
**Call targets:**
- 0xffff6abc (coordinate transformation)
- 0xffff583c (clipping region processing)
- 0xffff64aa (coordinate setup)
- 0xffffd018 (hardware vector rendering)
- 0xffff63fa (software raster rendering)
- 0xffff5fa0 (rendering mode check)
**Called by:** Main page rendering loop

### 2. Data Region at 0x6C51E-0x6C535
**Address:** 0x6C51E-0x6C535
**Size:** 24 bytes
**Format:** Double-precision floating point constants
- 0x6C51E: 0x3FF0 0000 0000 0000 = 1.0
- 0x6C526: 0x3FE3 3333 3333 3333 = 0.6 (approximately)
- 0x6C52E: 0x3FD9 9999 9999 999A = 0.4 (approximately)
**Purpose:** Mathematical constants used in coordinate calculations

### 3. Function at 0x6C536-0x6D31E
**Entry:** 0x6C536 (`linkw %fp,#-444`)
**Name:** `setup_page_coordinate_system`
**Purpose:** Initializes the page coordinate system for rendering. It:
- Checks system flags at 0x2017464+0xA4 bit 6
- Tests if rendering is already active (0x2016698)
- Sets up transformation matrices at 0x2016610 and 0x2016614
- Handles different page orientation modes (1,2,4,8 at 0x2016670)
- Calls coordinate transformation functions (0xffff95be, 0xffff91b8)
- Sets up clipping regions and viewport
- Calculates scaling factors for portrait/landscape modes
- Initializes hardware acceleration context if available
**Arguments:** None (void function)
**Returns:** Nothing
**Local variables:** 444 bytes of stack frame
**RAM accesses:** 
- 0x2017464 (main system structure)
- 0x2016698 (rendering active flag)
- 0x2016670 (page orientation mode)
- 0x2016610-0x2016618 (transformation matrices)
- 0x20008f4 (execution context stack)
**Call targets:** 
- 0xffff95be (matrix operations)
- 0xffff91b8 (coordinate setup)
- 0xffff9eae (matrix multiplication)
- 0x2df1c (context initialization)
- 0x89a88, 0x89920, 0x899c8 (floating point operations)
**Called by:** Page setup routines

### 4. Data Region at 0x6D31E-0x6D33F
**Address:** 0x6D31E-0x6D33F
**Size:** 34 bytes
**Format:** Double-precision floating point constants
- 0x6D31E: 0x3FF0 0000 0000 0000 = 1.0
- 0x6D326: 0x3FE3 3333 3333 3333 = 0.6 (approximately)
- 0x6D32E: 0x3FD9 9999 9999 999A = 0.4 (approximately)
**Purpose:** Mathematical constants used in coordinate calculations (duplicate of 0x6C51E-0x6C535)

### 5. Function at 0x6D340-0x6D3A0 (Partial - continues beyond 0x6CC00)
**Entry:** 0x6D340 (`linkw %fp,#-24`)
**Name:** `calculate_page_dimensions`
**Purpose:** Calculates page dimensions and scaling factors based on orientation and hardware capabilities. It:
- Accesses page size information at 0x2016668-0x201666c
- Calculates scaling factors for different orientations
- Sets up coordinate transformation matrices
**Arguments:** Likely takes page parameters via stack
**Returns:** Transformation data in registers or memory
**Local variables:** 24 bytes of stack frame
**RAM accesses:** 
- 0x2016668 (page width)
- 0x201666c (page height)
- 0x2016670 (orientation mode)
**Call targets:** Floating point operations (0x89a88, etc.)
**Called by:** Page setup functions

## KEY CORRECTIONS TO PRIOR ANALYSIS:

1. **The code at 0x6C000 is NOT a function entry** - it's in the middle of a large rendering function that started earlier.

2. **The function at 0x6C536 is correctly identified** as `setup_page_coordinate_system` with a 444-byte stack frame.

3. **The data regions are correctly identified** as floating point constants, not code.

4. **The prior analysis missed the function at 0x6D340** which continues beyond our current analysis range.

## ADDITIONAL OBSERVATIONS:

- The rendering system has both hardware-accelerated (vector) and software (raster) rendering paths
- Coordinate transformations use double-precision floating point math
- The system maintains a complex rendering context structure at 0x20165d8-0x20165f6
- Page orientation modes are encoded as bit flags: 1, 2, 4, 8
- The hardware acceleration flag is checked at 0x2017464+0xA4 bit 7
- Floating point operations are handled through software emulation (0x89a88, etc.) even on this 68020 system

The disassembly shows a sophisticated PostScript rendering engine with both hardware and software rendering paths, complex coordinate transformations, and extensive use of floating point math for precise page layout.

; === CHUNK 18: 0x6CC00-0x6D800 ===

## CORRECTED AND REFINED ANALYSIS OF 0x6CC00-0x6D800

### 1. Function: 0x6CC00-0x6D31E (actually starts earlier, continues to 0x6D31E)
**Entry:** Not at 0x6CC00 (this is in the middle of a larger function)
**Name:** `process_quadrilateral_region` or `render_page_quad`
**Purpose:** Processes a quadrilateral region for page rendering. This is a massive function that:
1. Takes four corner coordinates (likely from a PostScript path)
2. Applies transformation matrices (user space to device space)
3. Validates the region against clipping boundaries
4. Chooses between hardware-accelerated rendering (via callback at 0xFFFFD018) or software rasterization (0xFFFF63FA)
5. Renders each edge of the quadrilateral
6. Handles error conditions and cleanup
**Arguments:** Uses frame pointer with extensive local variables (-52 to -444 offsets). Likely receives coordinates in D3-D5 and other registers.
**Returns:** D0 indicates success/failure (0 on success)
**RAM accesses:**
- 0x2016678: Page coordinate system state
- 0x20165e4, 0x20165d8: Transformation/coordinate data
- 0x2017464: Main system structure (checks bit 7 at offset 0xA4 for rendering mode)
- 0x20175f0, 0x20175f4: Transformation matrices (X and Y scaling/translation)
- 0x2022244: Rendering counter (incremented for each quadrilateral)
- 0x20166ac, 0x20166b4: Rendering flags (hardware acceleration enabled, etc.)
**Key calls:**
- `bsrl 0xffff9dd8` (coordinate transformation, called 4x for each corner)
- `bsrl 0xfffff31a` (quadrilateral processing - computes bounding box?)
- `bsrl 0xffff64aa` (region validation against clipping path)
- `bsrl 0xffff5fa0` (rendering setup)
- `bsrl 0xffffd018` (HW accelerated line/edge rendering)
- `bsrl 0xffff63fa` (SW rasterization fallback)
**Algorithm details:** The function appears to:
- Load four corner coordinates into local arrays at FP@(-88), FP@(-72), FP@(-64), FP@(-80)
- Apply transformation matrices to convert from user to device coordinates
- Compute bounding box and validate against clipping region
- Based on flag at 0x2017464+0xA4 bit 7, choose HW vs SW rendering
- Render each edge sequentially (4 edges of quadrilateral)
- Handle errors by calling cleanup functions at 0xFFFFCB7A, 0xFFFF62F0
**Callers:** Likely called from PostScript path rendering operators (fill, stroke, clip)

### 2. Data Region: 0x6D320-0x6D33E (FLOATING-POINT CONSTANTS)
**Address:** 0x6D320
**Size:** 30 bytes (7.5 double-precision floats)
**Format:** IEEE 754 double-precision floating-point constants
**Values:**
- 0x6D320: 1.0 (0x3FF0000000000000)
- 0x6D328: 1024.0 (0x4090000000000000) - likely page dimension scaling
- 0x6D330: 0.828125 (0x3FE5000000000000) - 53/64, possibly fixed-point conversion factor
- 0x6D338: 0.5 (0x3FE0000000000000)
**Usage:** Used by the quadrilateral rendering function for coordinate scaling and fixed-point conversions.

### 3. Function: 0x6D340-0x6D3BA
**Entry:** 0x6D340
**Name:** `init_page_processor` or `setup_page_rendering`
**Purpose:** Initializes page rendering subsystem. Reads page dimensions from configuration, sets up coordinate systems and transformation matrices, and calls the main rendering setup function at 0xC536.
**Arguments:** None (void function)
**Returns:** Nothing
**RAM accesses:**
- 0x20166c4: Coordinate system structure
- 0x2016600: Transformation matrix
- 0x2016670, 0x2016668, 0x201666c: Page dimensions (orientation, width, height)
- 0x2017464: System flags (checks bit 4 at offset 0xA4)
**Key calls:**
- `bsrl 0x165f8` (coordinate system initialization)
- `bsrl 0xffff9b4e` (matrix setup)
- `bsrl 0x1b626` (read configuration value, called 3x for width/height/orientation)
- `bsrl 0x2640e` (conditional call based on bit 4 at 0x2017464+0xA4)
**Flow:**
1. Initialize coordinate system at 0x20166c4
2. Set up transformation matrix at 0x2016600
3. Read page orientation (0x2016670), width (0x2016668), height (0x201666c) from config
4. If bit 4 is set at 0x2017464+0xA4, call 0x2640e (special handling for certain page types)
5. If width and height are non-zero, clear 0x201669c and 0x20166a0, call 0xC536
**Callers:** Called from page setup operators

### 4. Function: 0x6D3BC-0x6D43A
**Entry:** 0x6D3BC
**Name:** `init_page_processor_alternate` or `setup_alternate_page`
**Purpose:** Alternate page setup path for manual configuration or different page types. Similar to 0x6D340 but with different parameter handling and sets 0x201669c to 1.
**Arguments:** None (void function)
**Returns:** Nothing
**RAM accesses:** Same as 0x6D340 plus:
- 0x201669c: Page processor mode flag (set to 1)
- 0x20166a0: Alternate configuration value
**Key calls:**
- `bsrl 0x165f8` (coordinate system init)
- `bsrl 0xffff9b4e` (matrix setup)
- `bsrl 0x1b94a` (different config reader for 0x20166a0)
- `bsrl 0x1b626` (read configuration, 2x for width/height)
**Key differences from 0x6D340:**
- Sets page orientation to 1 (0x2016670 = 1) unconditionally
- Reads 0x20166a0 via 0x1b94a instead of orientation from config
- If 0x20166a0 is non-zero, sets it to 0, else sets to 1 (inverts logic)
- Sets 0x201669c to 1 (alternate mode flag)
**Callers:** Called from alternate page setup operators

### 5. Function: 0x6D43C-0x6D47E
**Entry:** 0x6D43C
**Name:** `setup_page_operators` or `install_page_handlers`
**Purpose:** Installs page-related operator handlers into the PostScript interpreter. Based on parameter, either resets page counters or installs operator implementations.
**Arguments:** D0 from stack (FP@(8)): 0 = reset counters, 1 = install operators
**Returns:** Nothing
**RAM accesses:**
- 0x2022244: Rendering counter (cleared when D0=0)
- 0x2016698: Page processor state (cleared when D0=0)
**Key calls:**
- When D0=1: Calls 0x26948 twice to install operators:
  - First: 0xD340 (`init_page_processor`) installed at 0xD700
  - Second: 0xD3BC (`init_page_processor_alternate`) installed at 0xD706
**Flow:**
1. If D0=0: Clear rendering counter and page processor state
2. If D0=1: Install two page setup operators into the interpreter's operator table
3. Returns
**Callers:** PostScript interpreter initialization

### 6. Data Region: 0x6D480-0x6D5DE (CHARACTER WIDTH TABLE)
**Address:** 0x6D480
**Size:** 350 bytes
**Format:** Array of single-byte character width values (likely for a fixed-width or monospaced font)
**Content:** Appears to be width values for ASCII characters 0x43 ('C') through 0x7F (DEL). Values range from 0x20 to 0x7F, with patterns suggesting proportional widths for different character classes:
- 0x43-0x4A: 0x43 repeated (67 dec) - likely 'C' through 'J'
- 0x4B-0x52: 0x6F (111 dec) - 'K' through 'R'
- 0x53-0x5A: 0x70 (112 dec) - 'S' through 'Z'
- etc.
**Usage:** Used by font rendering system for character spacing calculations.

### 7. Data Region: 0x6D5E0-0x6D5FC (BIT MASK TABLE)
**Address:** 0x6D5E0
**Size:** 28 bytes
**Format:** Array of 7 longwords (32-bit values)
**Values:** Powers of 2: 0x00000001, 0x00000002, 0x00000004, 0x00000008, 0x00000010, 0x00000020, 0x00000040, 0x00000080
**Usage:** Bitmask table for testing/setting individual bits, likely used in bitmap operations or flag testing.

### 8. Data Region: 0x6D600-0x6D6FE (REVERSED BIT PATTERN TABLE)
**Address:** 0x6D600
**Size:** 254 bytes
**Format:** Array of 127 words (16-bit values)
**Content:** Bit-reversed patterns for bytes 0x00-0x7F. Each entry appears to be the bit-reversed version of its index.
**Example patterns:** 
- 0x600: 0x0080 (bit-reversed 0x01 = 0x80)
- 0x602: 0x40C0 (bit-reversed 0x02 = 0x40, 0x03 = 0xC0)
**Usage:** Used for graphics operations requiring bit reversal, possibly for mirroring or certain raster operations.

### 9. Data Region: 0x6D700-0x6D70D (STRING CONSTANTS)
**Address:** 0x6D700
**Size:** 14 bytes
**Format:** Two null-terminated ASCII strings
**Strings:**
- 0x6D700: "image" (operator name for 0xD340)
- 0x6D706: "imagemask" (operator name for 0xD3BC)
**Usage:** PostScript operator names installed by function at 0x6D43C.

### 10. Function: 0x6D712-0x6D740
**Entry:** 0x6D712
**Name:** `compare_and_swap_coordinates` or `normalize_rect`
**Purpose:** Compares and possibly swaps two coordinate pairs to ensure consistent ordering (likely for rectangle normalization).
**Arguments:**
- FP@(8): First X coordinate
- FP@(12): First Y coordinate
**Returns:** D0/D1 contain possibly swapped coordinates
**Key calls:** `bsrl 0x298a0` (performs comparison and swapping logic)
**Algorithm:** Calls a helper function at 0x298a0 that compares the coordinates and swaps them if needed to ensure min/max ordering, then returns the result in D0/D1.
**Callers:** Rectangle/quadrilateral processing functions

### 11. Function: 0x6D742-0x6D76C
**Entry:** 0x6D742
**Name:** `gcd_32bit` (Greatest Common Divisor)
**Purpose:** Computes the greatest common divisor of two 32-bit integers using Euclid's algorithm.
**Arguments:**
- FP@(8): First integer (a)
- FP@(12): Second integer (b)
**Returns:** D0 = GCD(a, b)
**Algorithm:** Standard Euclidean algorithm using `divsll` instruction for 64-bit division:
1. While b ≠ 0:
   - Compute a % b using `divsll`
   - Set a = b, b = remainder
2. Return a
**Callers:** Used by fraction reduction, coordinate simplification, or rasterization algorithms

### 12. Function: 0x6D76E-0x6D802 (INCOMPLETE - continues beyond 0x6D800)
**Entry:** 0x6D76E
**Name:** `extended_euclidean_algorithm` or `compute_bezier_coefficients`
**Purpose:** Appears to implement the extended Euclidean algorithm or compute coefficients for Bézier curve rendering. Uses 64-bit arithmetic with `divsll` and `mulsl`.
**Arguments:**
- FP@(8), FP@(12): Two input values
- FP@(16), FP@(20): Pointer to output coefficients
**Returns:** Computes coefficients for linear combination
**Algorithm:** Similar to extended Euclidean algorithm that computes coefficients x,y such that ax + by = gcd(a,b). Uses local variables for intermediate results.
**Note:** Function continues beyond 0x6D800 (not shown in this chunk).

## CORRECTIONS TO PRIOR ANALYSIS:
1. **0x6CC00-0x6D31E is one continuous function**, not multiple functions. The prior analysis incorrectly split it.
2. **0x6D320-0x6D33E is data (floating-point constants)**, not code.
3. **0x6D480-0x6D5DE is a character width table**, not "random data".
4. **0x6D600-0x6D6FE is a bit-reversal table**, not "unknown data".
5. The prior analysis missed functions at 0x6D712, 0x6D742, and 0x6D76E.

## KEY INSIGHTS:
- This region contains core page rendering logic with hardware/software fallback
- The quadrilateral rendering function is performance-critical and uses both HW acceleration and SW fallback
- Page setup involves reading configuration values and setting up coordinate systems
- Several mathematical utilities (GCD, extended Euclidean) suggest sophisticated geometry processing
- The bit-reversal table indicates support for mirrored or reflected rendering operations

; === CHUNK 19: 0x6D800-0x6E400 ===

## CORRECTED ANALYSIS: 0x6D800-0x6E400

### DATA REGIONS:

**0x6D800-0x6D80F**: **PostScript operator dispatch table entry** (12 bytes)
- Pattern: `000C` (byte count) followed by code
- This is NOT a function - it's an operator entry in the jump table
- The code at 0x6D802-0x6D80E is the operator implementation

### FUNCTIONS:

#### 1. **0x6D810** - `scale_ratio` (fixed-point division)
**Purpose:** Computes `(a * b) / c` using 32-bit fixed-point arithmetic. Used for scaling calculations in halftoning or glyph rendering.
**Arguments:** Three long words on stack: FP+8 = a, FP+12 = b, FP+16 = c
**Return:** D0 = (a * b) / c
**Algorithm:** 
1. Calls 0xD742 (division routine) to compute `a / c`
2. Multiplies `a * b` using `muls.l`
3. Divides result by previous division result using `divs.l`
**Call targets:** 0xD742 (division)
**Called by:** Unknown (scaling operations)

#### 2. **0x6D836** - `init_halftone_screen`
**Purpose:** Initializes halftone screen parameters based on screen angle/value. Sets up threshold matrix pointers and state.
**Arguments:** Byte at FP+11 (screen parameter)
**Return:** None
**Hardware/RAM:**
- `0x2022254`, `0x2022248` (halftone screen min/max thresholds)
- `0x20166EC` (word flag: -1 for angle 0, 0 otherwise)
- `0x2017604`, `0x2017608`, `0x201760C` (threshold matrix pointers)
- `0x2017600` (cell size), `0x20166F0` (flag)
**Algorithm:** 
1. Stores screen parameter to threshold limits
2. Sets flag based on screen parameter (0 or non-zero)
3. Initializes pointer chain for threshold matrix
**Called by:** Device activation (0xDDE2)

#### 3. **0x6D892** - `generate_halftone_cell`
**Purpose:** Generates a halftone threshold matrix cell. Complex algorithm with nested loops building threshold values from device bitmap.
**Arguments:** Byte at FP+11 (screen value)
**Return:** None
**Local vars:** 56 bytes saved registers + locals
**Hardware/RAM:**
- `0x20166DC` (current device pointer)
- `0x20166F0`, `0x20166E0`, `0x2017600`, `0x20166E4` (halftone state)
- `0x2022248`, `0x2022254` (threshold limits)
- `0x2016700` (free memory pointer), `0x2017608`, `0x201760C` (cell pointers)
**Algorithm:**
1. Validates current device exists (calls 0x26334 if not)
2. Computes cell dimensions based on device resolution
3. Builds threshold matrix by scanning device bitmap
4. Uses bit packing for threshold values (16-bit entries)
5. Updates min/max threshold tracking
**Key loops:** 
- 0xD91C: Inner loop for cell row processing
- 0xD9E8: Per-pixel threshold calculation
- 0xDA72: Outer loop for rows
**Call targets:** 0x26334 (error handler)

#### 4. **0x6DAA2** - `alloc_device_slot`
**Purpose:** Allocates a free 56-byte device slot from the device table.
**Arguments:** None
**Return:** D0 = pointer to free slot (or error)
**Hardware/RAM:**
- `0x201670C` (device table base)
- `0x2022250` (device count)
**Algorithm:** Scans table for zero-initialized slot (first long word = 0). Table size = device_count * 56 bytes.
**Call targets:** 0x26382 (error if no free slots)

#### 5. **0x6DAEC** - `format_device_index`
**Purpose:** Formats device slot index for output/debugging. Computes `(ptr - base) / 56`.
**Arguments:** FP+8 = device pointer, FP+12 = format string?
**Return:** None (calls formatter)
**Algorithm:** Computes index, calls formatter at 0x28934 with format string at 0xF7B0.
**Call targets:** 0x28934 (formatter)

#### 6. **0x6DB1E** - `flush_device_to_disk`
**Purpose:** Flushes current device's bitmap buffer to disk (SCSI filesystem). Handles file creation, writing, and error recovery.
**Arguments:** None
**Return:** None
**Local vars:** 100 bytes (file handle, buffers, error context)
**Hardware/RAM:**
- `0x2016714` (filesystem active flag)
- `0x20166DC` (current device)
- `0x20008F4` (error context chain)
**Algorithm:**
1. Checks if filesystem active
2. Validates device has bitmap data
3. Formats device name for file creation
4. Creates file with calculated size
5. Writes bitmap data via SCSI DMA
6. Updates device state and memory pointers
**Call targets:** 0xDAEC (format_device_index), 0x1DA5E (string concat), 0x1F86E (file create), 0x1FC3C (file write), 0x2DF1C (error check), 0x8B22 (error handler)

#### 7. **0x6DC7C** - `release_device_slot`
**Purpose:** Releases a device slot back to the free pool. Handles filesystem cleanup if active.
**Arguments:** FP+8 = device pointer
**Return:** None
**Hardware/RAM:**
- `0x2016714` (filesystem active flag)
- `0x20166DC` (current device pointer)
- `0x2016700` (free memory pointer)
**Algorithm:**
1. If filesystem active and device has been flushed, formats device name for cleanup
2. If device is current device, resets memory pointer
3. Otherwise frees bitmap memory directly
4. Clears device slot and updates current device pointer if needed
**Call targets:** 0xDAEC (format_device_index), 0x2836C (memory free)

#### 8. **0x6DCEE** - `activate_device`
**Purpose:** Activates a device slot as the current rendering device. Flushes previous device if needed.
**Arguments:** FP+8 = device pointer
**Return:** None
**Local vars:** 80 bytes (file handle, error context)
**Hardware/RAM:**
- `0x20166DC` (current device pointer)
- `0x2016714` (filesystem active flag)
- `0x2016708` (base memory pointer)
- `0x20008F4` (error context chain)
**Algorithm:**
1. If device is already current, return
2. If filesystem active, flush current device
3. Load device bitmap from disk if filesystem active
4. Set device as current and initialize halftone screen
**Call targets:** 0xDB1E (flush_device_to_disk), 0x1F6B8 (file open), 0x2DF1C (error check), 0x8B22 (error handler), 0xD836 (init_halftone_screen)

#### 9. **0x6DDEC** - `set_halftone_screen`
**Purpose:** Sets halftone screen parameters and regenerates threshold matrix if needed.
**Arguments:** FP+11 = screen value (byte), FP+12 = device pointer, FP+16 = row index?
**Return:** None
**Hardware/RAM:**
- `0x20166DC` (current device pointer)
- `0x2022248`, `0x2022254` (threshold limits)
- `0x2017604`, `0x2017608` (threshold matrix pointers)
**Algorithm:**
1. If screen value is 0, 0xFF, or device pointer is null, just initialize screen
2. Otherwise activate device if not current
3. Regenerate halftone cell if screen value outside current threshold range
4. Update threshold matrix pointer based on row index
**Call targets:** 0xD836 (init_halftone_screen), 0xD892 (generate_halftone_cell)

#### 10. **0x6DE7E** - `compare_halftone_entries`
**Purpose:** Compares two halftone threshold entries for sorting.
**Arguments:** FP+10 = entry A (word), FP+14 = entry B (word)
**Return:** D0 = comparison result (-1, 0, 1)
**Algorithm:** 
1. If entries equal, call 0x2DC54 for tie-breaking
2. Returns -1 if A > B, 1 if A < B
**Call targets:** 0x2DC54 (tie-breaker)

#### 11. **0x6DEA8** - `sort_halftone_table`
**Purpose:** Sorts halftone threshold table using a hybrid algorithm (quicksort + insertion sort).
**Arguments:** None
**Return:** None
**Local vars:** 156 bytes (stack frames, indices, comparison state)
**Hardware/RAM:**
- `0x20166F4` (halftone table pointer)
- `0x20166FC` (table entry count)
**Algorithm:**
1. Implements quicksort with recursion stack simulation
2. Uses compare_halftone_entries for comparisons
3. Falls back to insertion sort for small partitions
4. Maintains manual recursion stack in local array
**Call targets:** 0xDE7E (compare_halftone_entries)

#### 12. **0x6E264** - `increment_ref_count`
**Purpose:** Increments or decrements a reference count with saturation logic.
**Arguments:** FP+8 = pointer to reference count
**Return:** None
**Algorithm:** 
1. If count > 0, increment
2. If count < 0, decrement
3. Handles 32-bit signed integer

#### 13. **0x6E284** - `decrement_ref_count`
**Purpose:** Decrements a reference count with cascading cleanup.
**Arguments:** FP+8 = pointer to reference count
**Return:** None
**Algorithm:**
1. If count > 0, decrement; if reaches 0, call release_device_slot
2. If count < 0, increment; if reaches 0, recursively decrement linked counts
**Call targets:** 0xDC7C (release_device_slot)

#### 14. **0x6E2EE** - `compute_device_checksum`
**Purpose:** Computes a checksum of device bitmap data.
**Arguments:** None
**Return:** None (stores result in device structure)
**Hardware/RAM:**
- `0x20166DC` (current device pointer)
- Device structure offset 0x10 (checksum field)
**Algorithm:**
1. Iterates through all bitmap bytes
2. Uses shift-and-add algorithm: checksum = (checksum << 1) + byte
3. Sets LSB based on previous checksum sign

#### 15. **0x6E36E** - `transform_coordinates` (partial - continues beyond 0x6E400)
**Purpose:** Performs coordinate transformation using floating-point math.
**Arguments:** Multiple floating-point values on stack
**Return:** Floating-point result
**Algorithm:**
1. Calls floating-point library routines (0x89A58, 0x89A88, 0x899C8)
2. Performs matrix multiplication or affine transformation
**Note:** Function continues beyond 0x6E400 boundary

### CORRECTIONS TO PRIOR ANALYSIS:

1. **0x6D800-0x6D80F** is correctly identified as data (operator table entry), not code
2. **0x6DEA8** is a complex sorting function, not just "halftone table management"
3. **0x6E264/0x6E284** are reference counting utilities, not device allocation
4. **0x6E2EE** is a checksum calculator, not "update device state"
5. **0x6E36E** continues beyond the analyzed range (partial function)

### MISSED FUNCTIONS IN PRIOR ANALYSIS:

- **0x6DE7E**: Comparison function for halftone sorting
- **0x6E264/0x6E284**: Reference counting with cleanup
- **0x6E2EE**: Bitmap checksum computation

### HARDWARE/RAM USAGE PATTERNS:

1. **Device management**: 0x20166DC (current device), 0x201670C (device table)
2. **Halftone system**: 0x2017600-0x201760C (threshold matrix), 0x2022248/0x2022254 (limits)
3. **Memory management**: 0x2016700 (free pointer), 0x2016708 (base pointer)
4. **Filesystem**: 0x2016714 (active flag)

The code in this region handles device bitmap management, halftone screen generation, and memory/device lifecycle management for the PostScript RIP's rendering pipeline.

; === CHUNK 20: 0x6E400-0x6F000 ===

Looking at the raw disassembly from 0x6E400 to 0x6F000, I can see that the prior analysis was mostly correct but had some important errors and omissions. Let me provide a corrected and refined analysis.

## CORRECTED ANALYSIS: 0x6E400-0x6F000

### 1. `0x6E400` - `create_halftone_screen` (MAIN FUNCTION)
**Entry:** 0x6E400  
**Purpose:** Creates a halftone screen (threshold matrix) for dithering. This is a complex PostScript `setscreen` implementation that computes screen parameters from frequency and angle, allocates device memory, generates threshold values using a spot function, and builds the halftone cell. It handles both memory-based and storage-based (SCSI/filesystem) screens.  
**Arguments:** 6 parameters on stack (likely: frequency_x, frequency_y, angle_x, angle_y, spot_function, halftone_type)  
**Return:** D0 = 1 on success, 0 on failure  
**Stack frame:** 0xFF48 bytes (large local variable space)  
**Hardware/RAM accessed:**
- `0x2016714` - storage flag (1=use SCSI/filesystem, 0=memory only)
- `0x20166DC` - current device pointer
- `0x2016700` - memory allocation pointer
- `0x20166F4`, `0x20166F8`, `0x20166FC` - screen buffer pointers/counters
- `0x20008F4` - error handler chain
- `0x2017418` - memory limit for screens
- `0x201670C` - device table base
- `0x2022250` - device count

**Key call targets:**
- `0x89A58`, `0x899C8`, `0x89A88` - Software FPU operations (convert, multiply, etc.)
- `0x1CE34` - conversion routine (called multiple times)
- `0xD76E` - GCD calculation (called at 0x6E5BC)
- `0xD810` - scaling routine (called at 0x6E62E)
- `0xD742` - division routine (called at 0x6E646)
- `0xDA82` - `alloc_device_entry` (called at 0x6E6BC)
- `0xDB1E` - `flush_device_data` (called at 0x6E6B8)
- `0x2D818` - memory allocation (called at 0x6E704)
- `0x2DC44` - unknown (called at 0x6E788)
- `0x2DF1C` - error handling setup (called at 0x6E842)
- `0x11334` - spot function evaluation (called at 0x6E970)
- `0x6D710` - fixed-point calculation (called at 0x6E8DC, 0x6E936)
- `0x1BDE2` - unknown (called at 0x6E960)
- `0x11DBE` - string operation (called at 0x6E980)
- `0x2D8D8` - error reporting (called at 0x6E988, 0x6EAA6)
- `0x1B81A` - unknown (called at 0x6E994)
- `0x263BA` - unknown (called at 0x6E9DC)
- `0xDC7C` - device cleanup (called at 0x6E998, 0x6EF20)
- `0xDEA8` - unknown (called at 0x6EAAE)
- `0xE2EE` - unknown (called at 0x6EC66)

**Algorithm details:**
1. **Parameter processing** (0x6E400-0x6E4F2): Converts input parameters using FPU routines
2. **Cell dimension calculation** (0x6E4F2-0x6E68A): Computes screen cell size from frequency and angle
3. **Memory check** (0x6E68E-0x6E6AA): Checks against memory limits
4. **Device allocation** (0x6E6B0-0x6E738): Flushes current device, allocates new device entry
5. **Memory allocation** (0x6E6F4-0x6E738): Allocates threshold value storage
6. **Buffer setup** (0x6E73A-0x6E784): Initializes screen buffer pointers
7. **Matrix generation** (0x6E788-0x6EA8A): Nested loops generating threshold values:
   - Outer loop (0x6E854-0x6EA7A): Rows
   - Inner loop (0x6E880-0x6EA66): Columns
   - Evaluates spot function at each cell position
   - Normalizes and stores threshold values
8. **Error handling** (0x6E82C-0x6EA94): Sets up error context
9. **Matrix reorganization** (0x6EAAE-0x6EC38): Reorganizes threshold matrix for efficient access
10. **Device finalization** (0x6EC3A-0x6EC66): Sets device as active, returns success

**Important data constants at end of function:**
- `0x6EC7C`: 2.0 (double)
- `0x6EC84`: 1.0 (double)  
- `0x6EC8C`: -0.1 (double)
- `0x6EC94`: 16384.0 (double)

### 2. `0x6EC9C` - `is_device_active` (SEPARATE FUNCTION)
**Entry:** 0x6EC9C  
**Purpose:** Checks if a device pointer points to an active device in the device table. Scans through device table comparing device IDs.  
**Arguments:** A0 = device pointer to check  
**Return:** D0 = 0 if device is active, 1 if not found  
**Stack frame:** 0xFFFC bytes (4 bytes)  
**Algorithm:** Iterates through device table starting at 0x2020C08, comparing device IDs at offset 0x90. Returns 0 if match found, 1 if end of table reached without match.

### 3. `0x6ECD6` - `find_and_merge_duplicate_screen` (SEPARATE FUNCTION)
**Entry:** 0x6ECD6  
**Purpose:** Searches for duplicate halftone screens in the device table and merges them if found. Compares screen parameters and merges reference counts.  
**Arguments:** None (operates on current device at 0x20166DC)  
**Return:** None  
**Stack frame:** 0xFFA0 bytes (96 bytes)  
**Hardware/RAM accessed:**
- `0x201670C` - device table base
- `0x2022250` - device count
- `0x20166DC` - current device pointer
- `0x20166E8` - device reference counter
**Key call targets:**
- `0xEC9C` - `is_device_active` (called at 0x6ED4E)
- `0x26334` - unknown (called at 0x6ED6E)
- `0x1F6B8` - unknown (called at 0x6EDAA)
- `0x2DF1C` - error handling setup (called at 0x6EDCC)
- `0x8B22` - unknown (called at 0x6EE62)
- `0xDC7C` - device cleanup (called at 0x6EF1C)
- `0xDCEE` - unknown (called at 0x6EF26)

**Algorithm details:**
1. **Iterate device table** (0x6ECDA-0x6EEBC): Scan all devices
2. **Check if active** (0x6ED02-0x6ED56): Skip if not active or is current device
3. **Compare parameters** (0x6ED12-0x6ED48): Check screen size, frequency, angle
4. **Storage vs memory** (0x6ED5A-0x6EE6A): Handle different storage types
5. **Merge if duplicate** (0x6EEDE-0x6EF32): Copy attributes, increment reference count

### 4. `0x6EF36` - `find_and_decrement_screen_reference` (SEPARATE FUNCTION)
**Entry:** 0x6EF36  
**Purpose:** Searches for a screen with matching parameters and decrements its reference count. If count reaches zero, marks device as inactive.  
**Arguments:** A0 = device pointer to match against  
**Return:** D0 = pointer to found device or input pointer if not found  
**Stack frame:** 0xFFF8 bytes (8 bytes)  
**Hardware/RAM accessed:**
- `0x2016710` - screen table base
- `0x202224C` - screen count
**Key call targets:**
- `0xE284` - unknown (called at 0x6EF9A)
- `0xDCEE` - unknown (called at 0x6EFA8)

**Algorithm details:**
1. **Iterate screen table** (0x6EF3A-0x6EFC0): Scan all screens
2. **Check if active** (0x6EF5E-0x6EF98): Skip if not active or is input device
3. **Compare parameters** (0x6EF68-0x6EF96): Check all screen attributes
4. **Decrement reference** (0x6EFB2): If match found, decrement reference count

### 5. `0x6EFD2` - `compare_screen_parameters` (SEPARATE FUNCTION - INCOMPLETE)
**Entry:** 0x6EFD2  
**Purpose:** Compares two sets of screen parameters (likely frequency and angle).  
**Arguments:** 4 parameters on stack (two pairs of doubles)  
**Return:** D0 = comparison result (seems to be difference or similarity metric)  
**Stack frame:** 0xFFB8 bytes (72 bytes)  
**Note:** Function appears incomplete in this range (ends at 0x6F000).

### 6. DATA REGIONS:
- `0x6EC6C-0x6EC9A`: Floating-point constants for halftone calculations:
  - `0x6EC7C`: 2.0 (0x4000000000000000)
  - `0x6EC84`: 1.0 (0x3FF0000000000000)
  - `0x6EC8C`: -0.1 (0xBFB999999999999A)
  - `0x6EC94`: 16384.0 (0x40E0000000000000)

## CORRECTIONS TO PRIOR ANALYSIS:

1. **The prior analysis was correct that 0x6E400 is one large function** - it's `create_halftone_screen`.

2. **0x6EC9C is a SEPARATE function**, not part of the main function. It has its own LINK/UNLK frame.

3. **0x6ECD6 is a SEPARATE function** (`find_and_merge_duplicate_screen`), not part of the main function.

4. **0x6EF36 is a SEPARATE function** (`find_and_decrement_screen_reference`).

5. **0x6EFD2 is the start of another function** that continues beyond 0x6F000.

6. **The floating-point constants at 0x6EC7C-0x6EC94 are DATA**, not code.

## KEY INSIGHTS:

1. **Halftone screen management** is complex with reference counting and duplicate detection.

2. **Two storage modes**: memory-based and SCSI/filesystem-based screens.

3. **Device table structure**: Each device entry appears to be 56 bytes (0x38) based on the increment at 0x6EEB8.

4. **Screen table structure**: Each screen entry appears to be 20 bytes (0x14) based on the increment at 0x6EFBC.

5. **Error handling**: Uses a chain of error handlers at 0x20008F4.

The code in this range implements sophisticated halftone screen generation with optimization to avoid duplicate screens and proper resource management through reference counting.

; === CHUNK 21: 0x6F000-0x6FC00 ===

Looking at this disassembly, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Function at 0x6F000-0x6F268** was misidentified. This is actually `setmatrix` or `concatmatrix` - it sets up a transformation matrix from PostScript parameters. The prior analysis was too vague.

2. **Function at 0x6F27A-0x6F2FA** is NOT `gsave_grestore` - it's `currentmatrix` or similar. It retrieves the current transformation matrix.

3. **Function at 0x6F2FC-0x6F408** is NOT `restore_graphics_state` - it's `setgstate` or similar. It sets graphics state from a saved state.

4. **Function at 0x6F540-0x6F60E** is NOT `generate_random_pattern` - it's `setgray` or `setpattern` - it sets gray/pattern values for fill/stroke.

5. **The prior analysis missed many functions** from 0x6F7E0 onward.

## REFINED ANALYSIS:

### 1. Function at 0x6F000-0x6F268
**Entry:** 0x6F000  
**Name:** `concat_matrix` or `setmatrix_operator`  
**Purpose:** Implements PostScript `concatmatrix` operator. Takes 6 floating-point parameters (a, b, c, d, tx, ty) from stack and concatenates them with current transformation matrix. Uses IEEE 754 single-precision math (0x3F800000 = 1.0).  
**Arguments:** Takes 6 floats on stack (24 bytes total)  
**Return:** None (modifies current transformation matrix)  
**Hardware access:** Accesses 0x02017464 (graphics state), 0x020166DC (matrix storage)  
**Key calls:** 0x2642A (matrix math), 0xFFFF9FC0 (matrix multiply), 0x2B990 (set matrix), 0xECD6 (update something), 0xD836 (flush?)  
**Callers:** Unknown, but likely called from PostScript operator dispatch  
**Algorithm:** Loads 6 floats, does matrix multiplication with current CTM, stores result back.

### 2. Function at 0x6F27A-0x6F2FA
**Entry:** 0x6F27A  
**Name:** `currentmatrix` or `get_current_matrix`  
**Purpose:** Retrieves current transformation matrix from graphics state. Returns matrix in PostScript format (6 floats).  
**Arguments:** Takes pointer to destination buffer (6 floats)  
**Return:** None (fills buffer)  
**Hardware access:** 0x02017464 (graphics state)  
**Key calls:** 0x165F8 (get matrix component), 0x1B81A (convert to float), 0xE284 (save/restore?), 0xEFD2 (matrix operation)  
**Callers:** Unknown  
**Algorithm:** Gets CTM from graphics state, converts fixed-point to floating-point, stores in buffer.

### 3. Function at 0x6F2FC-0x6F408
**Entry:** 0x6F2FC  
**Name:** `set_gstate` or `restore_gstate`  
**Purpose:** Restores a saved graphics state. If argument is 0, restores default state. Otherwise restores from saved state structure.  
**Arguments:** A0 = pointer to saved gstate (or 0 for default)  
**Return:** None  
**Hardware access:** 0x02017354 (execution context), 0x02017464 (graphics state)  
**Key calls:** 0x14096 (copy memory), 0x108FA (set something), 0xFFFF9EAE (matrix operation), 0x2B990 (set matrix), 0x1BE16 (set color/pattern), 0x165AA (set CTM)  
**Callers:** 0xF40A (grestore operator)  
**Algorithm:** If arg=0, loads default matrix (scale 75.0 = 0x42900000), otherwise copies from saved state. Sets CTM and color/pattern.

### 4. Function at 0x6F40A-0x6F420
**Entry:** 0x6F40A  
**Name:** `grestore_operator`  
**Purpose:** PostScript `grestore` operator implementation. Calls set_gstate with current saved state pointer.  
**Arguments:** None  
**Return:** None  
**Hardware access:** 0x02017464 (graphics state at offset 0x90)  
**Key calls:** 0xF2FC (set_gstate)  
**Callers:** Initialization at 0xF748  
**Algorithm:** Gets saved state pointer from graphics state, calls set_gstate.

### 5. Function at 0x6F422-0x6F50E
**Entry:** 0x6F422  
**Name:** `gsave_operator` or `save_gstate`  
**Purpose:** PostScript `gsave` operator. Saves current graphics state (CTM, color, pattern).  
**Arguments:** None  
**Return:** None  
**Hardware access:** 0x02017464 (graphics state)  
**Key calls:** 0x165F8 (get matrix), 0x1B81A (convert to float), 0xE284 (save state), 0xEFD2 (matrix operation)  
**Callers:** Unknown  
**Algorithm:** Gets current CTM, converts to float, saves to graphics state stack.

### 6. Function at 0x6F510-0x6F53E
**Entry:** 0x6F510  
**Name:** `init_graphics_state` or `reset_gstate_stack`  
**Purpose:** Initializes or resets graphics state stack. Calls set_gstate multiple times with null pointer.  
**Arguments:** None  
**Return:** None  
**Hardware access:** 0x02017464 (graphics state)  
**Key calls:** 0xF2FC (set_gstate) 4 times  
**Callers:** Unknown  
**Algorithm:** Calls set_gstate(0) four times to reset graphics state stack.

### 7. Function at 0x6F540-0x6F60E
**Entry:** 0x6F540  
**Name:** `setgray_operator` or `set_pattern_gray`  
**Purpose:** Sets gray value or pattern for fill/stroke operations. Generates pattern data if needed.  
**Arguments:** Takes gray value (0.0-1.0)  
**Return:** None  
**Hardware access:** 0x02017464 (graphics state), 0x020220D8 (pattern buffer)  
**Key calls:** 0x26334 (error?), 0x1BE16 (set color/pattern), 0x11334 (compare), 0x1B81A (convert to float), 0x89920 (math), 0x89A28 (math)  
**Callers:** Unknown  
**Algorithm:** Checks if pattern is active, converts gray value, generates pattern data (256 bytes at 0x020220D8).

### 8. Function at 0x6F616-0x6F7AE
**Entry:** 0x6F616  
**Name:** `init_matrix_system` or `setup_matrix_allocators`  
**Purpose:** Initializes matrix allocation system with three separate pools.  
**Arguments:** D0 = mode (0=init, 1=setup operators)  
**Return:** None  
**Hardware access:** 0x020166DC, 0x020166E8, 0x02017418, 0x02016708, 0x0201670C, 0x02016710, 0x02022250, 0x0202224C  
**Key calls:** 0x28344 (malloc), 0xD836 (flush), 0x26948 (register operator), 0x2DF1C (something), 0x1DA5E (error)  
**Callers:** Unknown  
**Algorithm:** Allocates three memory pools for matrices, initializes them to zero, registers operators if mode=1.

### 9. Function at 0x6F7E0-0x6F80C
**Entry:** 0x6F7E0  
**Name:** `copy_matrix_with_limit`  
**Purpose:** Copies a matrix structure with size limit checking.  
**Arguments:** A5 = dest, stack args = source matrix + size limit  
**Return:** None  
**Hardware access:** None  
**Key calls:** None  
**Callers:** 0xF888, 0xF7E0 (self-recursive)  
**Algorithm:** Copies 8-byte matrix, updates size field with min of source and limit.

### 10. Function at 0x6F80E-0x6F886
**Entry:** 0x6F80E  
**Name:** `extract_submatrix` or `matrix_slice`  
**Purpose:** Extracts a submatrix from a larger matrix based on offset and count.  
**Arguments:** A5 = dest, stack args = source matrix + offset + count  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x26334 (error), 0x144B0 (copy elements)  
**Callers:** 0xF888, 0xF924, 0xF928  
**Algorithm:** Handles different matrix types (type 9=array, type 13=linked), copies elements.

### 11. Function at 0x6F888-0x6F8CC
**Entry:** 0x6F888  
**Name:** `concat_submatrices`  
**Purpose:** Concatenates two submatrices.  
**Arguments:** Stack args = two matrices + offsets + dest  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0xF80E (extract_submatrix), 0x6F7E0 (copy_matrix_with_limit)  
**Callers:** 0xF8EE  
**Algorithm:** Extracts first submatrix, then concatenates with second.

### 12. Function at 0x6F8CE-0x6F90A
**Entry:** 0x6F8CE  
**Name:** `concat_matrices_to_global`  
**Purpose:** Concatenates two matrices and stores result in global buffer.  
**Arguments:** Stack args = two matrices + offsets  
**Return:** D0 = pointer to result (0x02016720)  
**Hardware access:** 0x02016720 (global matrix buffer)  
**Key calls:** 0xF888 (concat_submatrices)  
**Callers:** Unknown  
**Algorithm:** Concatenates matrices, stores at 0x02016720.

### 13. Function at 0x6F90C-0x6F948
**Entry:** 0x6F90C  
**Name:** `transform_point_with_submatrix`  
**Purpose:** Transforms a point using a submatrix.  
**Arguments:** Stack args = point (x,y) + matrix + offset  
**Return:** None (transforms point in place?)  
**Hardware access:** None  
**Key calls:** 0xF80E (extract_submatrix), 0x26DC8 (transform point)  
**Callers:** Unknown  
**Algorithm:** Extracts submatrix, applies transformation to point.

### 14. Function at 0x6F94A-0x6F984
**Entry:** 0x6F94A  
**Name:** `transform_points_range`  
**Purpose:** Transforms a range of points.  
**Arguments:** Stack args = points + count + matrix + offset  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x27310 (transform multiple points), 0x263BA (error)  
**Callers:** Unknown  
**Algorithm:** Transforms multiple points if count valid, otherwise error.

### 15. Function at 0x6F986-0x6FA04
**Entry:** 0x6F986  
**Name:** `get_matrix_element` or `extract_matrix_component`  
**Purpose:** Extracts matrix element(s) based on offset and count.  
**Arguments:** Stack args = matrix + offset + count + dest  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x263BA (error), 0x124AC (something), 0x263D6 (error), 0x144B0 (copy)  
**Callers:** 0xFA22, 0xFA66, 0xFA88  
**Algorithm:** Handles different matrix types, extracts elements to destination.

### 16. Function at 0x6FA06-0x6FA3C
**Entry:** 0x6FA06  
**Name:** `get_matrix_to_global`  
**Purpose:** Gets matrix elements to global buffer.  
**Arguments:** Stack args = matrix + offset + count  
**Return:** D0 = pointer to result (0x02016728)  
**Hardware access:** 0x02016728 (global buffer)  
**Key calls:** 0xF986 (get_matrix_element)  
**Callers:** Unknown  
**Algorithm:** Extracts matrix elements to 0x02016728.

### 17. Function at 0x6FA3E-0x6FA6C
**Entry:** 0x6FA3E  
**Name:** `get_matrix_element_special`  
**Purpose:** Extracts matrix elements with special handling (sets type bits).  
**Arguments:** Stack args = matrix + offset + count + dest  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0xF986 (get_matrix_element)  
**Callers:** 0xFA88  
**Algorithm:** Sets matrix type bits (0x10) before extraction.

### 18. Function at 0x6FA6E-0x6FAA2
**Entry:** 0x6FA6E  
**Name:** `get_matrix_special_to_global`  
**Purpose:** Gets matrix elements with special handling to global buffer.  
**Arguments:** Stack args = matrix + offset + count  
**Return:** D0 = pointer to result (0x02016730)  
**Hardware access:** 0x02016730 (global buffer)  
**Key calls:** 0xFA3E (get_matrix_element_special)  
**Callers:** Unknown  
**Algorithm:** Extracts matrix elements to 0x02016730 with type bits set.

### 19. Function at 0x6FAA4-0x6FB20
**Entry:** 0x6FAA4  
**Name:** `transform_points_reverse` or `inverse_transform`  
**Purpose:** Applies inverse transformation to points.  
**Arguments:** Stack args = points + count + matrix  
**Return:** None  
**Hardware access:** 0x020173E8 (something)  
**Key calls:** 0x169A0 (get count?), 0x1648C (something), 0x165F8 (get matrix), 0x27310 (transform points)  
**Callers:** 0xFB7E, 0xFB62  
**Algorithm:** Gets matrix, applies inverse transformation to point array.

### 20. Function at 0x6FB22-0x6FB60
**Entry:** 0x6FB22  
**Name:** `get_current_matrix_and_transform`  
**Purpose:** Gets current matrix and applies transformation.  
**Arguments:** None?  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x1B564 (get something), 0x26382 (error), 0x27FFE (get matrix), 0x165AA (set CTM)  
**Callers:** Unknown  
**Algorithm:** Gets current matrix index, retrieves matrix, sets as CTM.

### 21. Function at 0x6FB62-0x6FB8E
**Entry:** 0x6FB62  
**Name:** `transform_with_saved_matrix`  
**Purpose:** Transforms using a saved matrix.  
**Arguments:** None?  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x1BA8E (get saved matrix), 0xFAA4 (transform_points_reverse), 0x165AA (set CTM)  
**Callers:** Unknown  
**Algorithm:** Gets saved matrix, applies transformation.

### 22. Function at 0x6FB90-0x6FBF2
**Entry:** 0x6FB90  
**Name:** `process_matrix_stack` or `iterate_matrix_operations`  
**Purpose:** Processes matrix operations from a stack.  
**Arguments:** None?  
**Return:** None  
**Hardware access:** None  
**Key calls:** 0x1BA8E (get saved matrix), 0x124AC (something), 0x26AEC (matrix operation), 0x165AA (set CTM)  
**Callers:** Unknown  
**Algorithm:** Gets matrix stack, processes each element, applies transformations.

### 23. Function at 0x6FBF4-0x6FC00 (incomplete)
**Entry:** 0x6FBF4  
**Name:** `check_matrix_type_bits`  
**Purpose:** Checks matrix type bits.  
**Arguments:** Stack arg = matrix  
**Return:** Unknown  
**Hardware access:** None  
**Key calls:** None visible  
**Callers:** Unknown  
**Algorithm:** Extracts type bits from matrix header.

## DATA REGIONS:

**0x6F26A-0x6F278:** Floating-point constants
- 0x6F26A: 0x40520000 = 3.28125
- 0x6F26E: 0x00000000 = 0.0
- 0x6F272: 0x40000000 = 2.0
- 0x6F276: 0x00000000 = 0.0

**0x6F610-0x6F616:** Floating-point constant
- 0x6F610: 0x3FE00000 = 1.75

**0x6F7B0-0x6F7DE:** String table
- 0x6F7B0: "DB/SCREEN."
- 0x6F7BA: "%D."
- 0x6F7BE: "pp"
- 0x6F7C0: "screen"
- 0x6F7C6: "currentscreen"
- 0x6F7D2: "foof"

## KEY INSIGHTS:

1. This region contains PostScript matrix operations: concatenation, extraction, transformation.
2. Multiple matrix types are supported (type 9=array, type 13=linked list).
3. Three global buffers at 0x02016720, 0x02016728, 0x02016730 for matrix results.
4. Graphics state stack operations (gsave/grestore) are implemented here.
5. Pattern/gray value setting for fill/stroke operations.
6. Matrix system initialization with three allocation pools.

The code shows sophisticated matrix math for PostScript transformations, with both forward and inverse transformations, submatrix extraction, and concatenation operations.

; === CHUNK 22: 0x6FC00-0x70800 ===

Looking at the raw disassembly from 0x6FC00 to 0x70800, I can see several issues with the prior analysis. Let me provide a corrected and refined analysis:

## CORRECTED ANALYSIS:

### 1. Function at 0x6FC00-0x6FC32
**Entry:** 0x6FC00  
**Name:** `execute_operator`  
**Purpose:** Executes a PostScript operator by calling the operator execution function at 0x26AEC. This appears to be a wrapper that sets up arguments for the actual operator execution.  
**Arguments:** Takes three arguments on stack (likely operator object, context, and operator table)  
**Return:** None (executes the operator)  
**Hardware access:** Accesses 0x2016718 (operator table)  
**Key calls:** 0x124AC (error handler), 0x1665E (get object), 0x26AEC (execute operator)  
**Algorithm:** Pushes three arguments to stack, calls get_object for each, then calls execute_operator at 0x26AEC.

### 2. Function at 0x6FC34-0x6FCC6
**Entry:** 0x6FC34  
**Name:** `validate_and_execute_operator`  
**Purpose:** Validates an operator object and executes it. Checks if object type is name (9) or operator (13), extracts operator code, and executes it.  
**Arguments:** Takes PostScript object pointer at FP@(8)  
**Return:** None  
**Hardware access:** Accesses 0x2016718 (operator table)  
**Key calls:** 0x166AC (push object), 0x16812 (get operator code), 0x26AEC (execute operator), 0x1665E (get object), 0x165AA (pop object), 0x263D6 (type error)  
**Algorithm:** 
1. Gets object from stack
2. Checks type bits (low 4 bits): 9=name, 13=operator
3. If valid type, gets operator code via 0x16812
4. If operator code is non-zero, executes via 0x26AEC
5. Otherwise pushes the name object back to stack

### 3. Function at 0x6FCC8-0x6FD26
**Entry:** 0x6FCC8  
**Name:** `register_array_operators`  
**Purpose:** Registers built-in PostScript array operators: `array`, `astore`, `aload`.  
**Arguments:** Takes mode parameter at FP@(8) (0=don't register, 1=register)  
**Return:** None  
**Hardware access:** Accesses 0x2016718 (operator table)  
**Key calls:** 0x267F2 (register operator), 0x26948 (define operator)  
**Data at 0x6FD28-0x6FD46:** String table with operator names:
- 0x6FD28: "array" (0x6172726179)
- 0x6FD2E: "astore" (0x6173746F7265)  
- 0x6FD36: "aload" (0x616C6F6164)

### 4. Function at 0x6FD48-0x6FD9E
**Entry:** 0x6FD48  
**Name:** `create_array_object`  
**Purpose:** Creates a PostScript array object. Validates array type, copies elements, sets metadata, and calls array constructor.  
**Arguments:** 
- FP@(8): Object type byte
- FP@(12): Pointer to source data (4×4 bytes = 16 bytes)
- FP@(16): Array ID
- FP@(20): Flags to OR with array header
- FP@(24): Array size/count
- FP@(31): Additional flags byte  
**Return:** None (creates object via 0x270E8)  
**Hardware access:** Accesses 0x202225C (array counter)  
**Key calls:** 0x270E8 (array constructor)  
**Algorithm:** 
1. Validates object type is 3 (array)
2. Copies 16 bytes from source to local buffer
3. Sets array ID from global counter
4. Sets size and flags
5. ORs flags with array header
6. Calls array constructor

### 5. Function at 0x6FDA0-0x6FDAC
**Entry:** 0x6FDA0  
**Name:** `reset_array_counter`  
**Purpose:** Resets the global array counter when it wraps around.  
**Arguments:** None  
**Return:** None  
**Key calls:** 0x26698 (reset function)  
**Cross-refs:** Called from array creation functions when counter reaches 0xFFFF

### 6. Function at 0x6FDAE-0x6FE86
**Entry:** 0x6FDAE  
**Name:** `compute_object_hash`  
**Purpose:** Computes a hash value for a PostScript object. Uses different algorithms based on object type.  
**Arguments:** 
- FP@(8): Object type byte
- FP@(12): Object data/value
- FP@(18): Hash table size (for scaling)  
**Return:** D0: 16-bit hash value (0-65535)  
**Key calls:** 0x89A88 (floating point conversion), 0x89AD0 (float to int), 0x298A0 (math function), 0x26334 (error)  
**Algorithm:**
1. Examines object type (low 4 bits)
2. Type-specific processing:
   - Type 1 (integer): Use absolute value
   - Type 2 (real): Convert to integer via floating point
   - Type 3 (array): Use array pointer
   - Type 4 (boolean): Error (0x26334)
   - Type 5 (string): Use string length
   - Type 6 (dictionary): Use dict pointer
   - Type 7 (procedure): Use proc pointer
3. Applies LCG: hash = (hash × 0x41C64E6D) >> 16
4. XORs high and low words
5. Scales to table size: (hash × size) >> 16

### 7. Function at 0x6FE88-0x6FF62
**Entry:** 0x6FE88  
**Name:** `lookup_in_hash_table`  
**Purpose:** Looks up an object in a hash table using linear probing.  
**Arguments:** 
- FP@(8): Hash table pointer
- FP@(12): Object to find (type byte)
- FP@(16): Object data/value  
- FP@(20): Pointer to store result  
**Return:** D0: 1 if found, 0 if not found  
**Key calls:** 0xFDAD (compute_object_hash), 0x263D6 (type error), 0x1B1EC (compare objects), 0x26334 (error)  
**Algorithm:**
1. Computes hash index using compute_object_hash
2. Scales to table size (×16 bytes per entry)
3. Starts linear probe
4. For each slot:
   - If empty slot (type 0) and result pointer provided, returns slot address
   - If array type (3) and matching array ID, returns success
   - Otherwise compares objects via 0x1B1EC
5. Continues until all slots checked or match found

### 8. Function at 0x6FF64-0x6FFFE
**Entry:** 0x6FF64  
**Name:** `find_or_create_array_entry`  
**Purpose:** Finds an array in dictionary or creates new entry.  
**Arguments:** 
- FP@(8): Object type byte
- FP@(12): Object data
- FP@(16): Result pointer  
**Return:** D0: 1 if found/created, 0 if error  
**Key calls:** 0x14050 (string conversion), 0x26334 (error), 0x124AC (error), multiple array functions  
**Algorithm:**
1. Handles string objects (type 5) by converting to internal form
2. Validates object is array type (3)
3. Checks if array ID matches current counter (valid array)
4. If valid, returns array data
5. Otherwise searches dictionary via linked list
6. Handles various array states and permissions

### 9. Function at 0x70100-0x70136
**Entry:** 0x70100  
**Name:** `get_array_entry`  
**Purpose:** Wrapper for find_or_create_array_entry that extracts array data.  
**Arguments:** 
- FP@(8): Object type byte
- FP@(12): Object data
- FP@(16): Result pointer for array data  
**Return:** D0: 1 if successful, 0 if error  
**Key calls:** 0xFF64 (find_or_create_array_entry)  
**Algorithm:** Calls find_or_create_array_entry and if successful, extracts the 8-byte array data (pointer + metadata).

### 10. Function at 0x70138-0x7018C
**Entry:** 0x70138  
**Name:** `get_current_array_entry`  
**Purpose:** Gets array entry for current context/color space.  
**Arguments:** 
- FP@(8): Array ID
- FP@(12): Result pointer  
**Return:** D0: 1 if found, 0 if not  
**Key calls:** 0xFF64 (find_or_create_array_entry)  
**Algorithm:** Builds a special array object using current context (0x20008F8) and calls find_or_create_array_entry.

### 11. Function at 0x7018E-0x702DC
**Entry:** 0x7018E  
**Name:** `store_to_array`  
**Purpose:** Stores a value to an array at specified index.  
**Arguments:** 
- FP@(8): Array object (type + data)
- FP@(12): Index
- FP@(16): Value to store (object)
- FP@(20): Update array ID flag
- FP@(24): Check permissions flag  
**Return:** None  
**Key calls:** 0x14050 (string conversion), 0x124AC (error), 0x272AE (array store), 0xFE88 (lookup_in_hash_table), 0x6FD48 (create_array_object), 0x2717E (array operation)  
**Algorithm:**
1. Handles direct array access (matching array ID)
2. Checks permissions if flag set
3. For dictionary arrays, looks up entry
4. Handles bounds checking
5. Updates array ID counter if flag set
6. Stores value via array store function

### 12. Function at 0x702DE-0x7034E
**Entry:** 0x702DE  
**Name:** `array_put_operator`  
**Purpose:** PostScript `put` operator implementation.  
**Arguments:** Takes array, index, and value from stack  
**Return:** None  
**Key calls:** 0x14050 (string conversion), 0x167DA (get objects), 0x1018E (store_to_array)  
**Algorithm:** Gets three objects from stack (array, index, value) and calls store_to_array.

### 13. Function at 0x70350-0x7039A
**Entry:** 0x70350  
**Name:** `create_array_id`  
**Purpose:** Creates a new array ID and registers it.  
**Arguments:** 
- FP@(8): Array object (type + data)
- FP@(12): Array structure pointer  
**Return:** None  
**Key calls:** 0x124AC (error), 0xFDA0 (reset_array_counter), 0x166EE (register function)  
**Algorithm:**
1. Checks array permissions
2. Increments global array counter
3. Handles wrap-around (0xFFFF → 1)
4. Sets array ID in structure
5. Registers array

### 14. Function at 0x7039C-0x703BA
**Entry:** 0x7039C  
**Name:** `create_array_operator`  
**Purpose:** PostScript `array` operator implementation.  
**Arguments:** Takes count from stack  
**Return:** None  
**Key calls:** 0x1B6FA (create array), 0x10350 (create_array_id)  
**Algorithm:** Gets count from stack, creates array via 0x1B6FA, then registers it with create_array_id.

### 15. Function at 0x703BC-0x703FE
**Entry:** 0x703BC  
**Name:** `increment_array_counter`  
**Purpose:** Increments the global array counter (for mark objects).  
**Arguments:** Takes mark object from stack  
**Return:** None  
**Key calls:** 0x1673C (get object), 0x263D6 (type error), 0xFDA0 (reset_array_counter)  
**Algorithm:** Validates object is mark type (8), increments counter, handles wrap-around.

### 16. Function at 0x70400-0x7042C
**Entry:** 0x70400  
**Name:** `check_and_increment_counter`  
**Purpose:** Checks dictionary state and increments array counter.  
**Arguments:** None  
**Return:** None  
**Key calls:** 0x10F8C (dictionary check), 0x103BC (increment_array_counter)  
**Algorithm:** Checks if at top of dictionary stack (0x20174BC == 0x2016740), if so does dictionary operation, then increments counter.

### 17. Function at 0x7042E-0x70448
**Entry:** 0x7042E  
**Name:** `increment_counter_loop`  
**Purpose:** Increments array counter until at top of dictionary stack.  
**Arguments:** None  
**Return:** None  
**Key calls:** 0x103BC (increment_array_counter)  
**Algorithm:** Loops calling increment_array_counter until at top of dictionary stack.

### 18. Function at 0x7044A-0x704C4
**Entry:** 0x7044A  
**Name:** `get_operator`  
**Purpose:** PostScript `get` operator implementation.  
**Arguments:** Takes array and index from stack  
**Return:** None  
**Key calls:** 0x165F8 (get object), 0x14050 (string conversion), 0x167DA (get objects), 0x1018E (store_to_array)  
**Algorithm:** Gets array and index from stack, retrieves value from array.

### 19. Function at 0x704C6-0x7059A
**Entry:** 0x704C6  
**Name:** `get_interval_operator`  
**Purpose:** PostScript `getinterval` operator implementation.  
**Arguments:** Takes array, index, and count from stack  
**Return:** None  
**Key calls:** 0x165F8 (get object), 0x10138 (get_current_array_entry), 0x10100 (get_array_entry), 0x14050 (string conversion), 0x165AA (pop object), 0x2640E (create interval)  
**Algorithm:** Gets array, index, and count from stack, creates array interval.

### 20. Function at 0x7059C-0x7064C
**Entry:** 0x7059C  
**Name:** `define_in_dictionary`  
**Purpose:** Defines a key-value pair in dictionary.  
**Arguments:** 
- FP@(10): Dictionary index (16-bit)
- FP@(12): Dictionary pointer
- Takes key and value from other sources  
**Return:** None  
**Key calls:** 0x27EA0 (dictionary operation), 0x2708A (dictionary function), 0x2717E (array operation)  
**Algorithm:** 
1. Performs dictionary operation via 0x27EA0
2. Builds dictionary entry structure
3. Updates dictionary hash table usage counter
4. Handles hash table expansion
5. Inserts entry into dictionary

### 21. Function at 0x7064E-0x70678
**Entry:** 0x7064E  
**Name:** `get_array_length`  
**Purpose:** Gets the length of an array (PostScript `length` operator).  
**Arguments:** FP@(12): Array object pointer  
**Return:** D0: Array length  
**Key calls:** 0x124AC (error)  
**Algorithm:** Checks array permissions, extracts length from array header.

### 22. Function at 0x7067A-0x70706
**Entry:** 0x7067A  
**Name:** `compare_objects`  
**Purpose:** Compares two PostScript objects for equality.  
**Arguments:** 
- FP@(8): First object (type + data)
- FP@(12): Second object (type + data)  
- FP@(16): Third object (type + data) - appears unused
- FP@(24): Check permissions flag  
**Return:** D0: 1 if equal, 0 if not  
**Key calls:** 0x124AC (error), 0x14050 (string conversion), 0xFE88 (lookup_in_hash_table)  
**Algorithm:** 
1. Checks permissions if flag set
2. Handles string conversion
3. For arrays, compares array IDs
4. Otherwise uses hash table lookup to compare

### 23. Function at 0x70708-0x7072A
**Entry:** 0x70708  
**Name:** `objects_equal`  
**Purpose:** Wrapper for compare_objects with permissions check.  
**Arguments:** Four objects on stack  
**Return:** D0: 1 if equal, 0 if not  
**Key calls:** 0x1067A (compare_objects)  
**Algorithm:** Calls compare_objects with permissions check flag set.

### 24. Function at 0x7072C-0x7074C
**Entry:** 0x7072C  
**Name:** `objects_not_equal`  
**Purpose:** Wrapper for compare_objects without permissions check.  
**Arguments:** Four objects on stack  
**Return:** D0: 1 if equal, 0 if not  
**Key calls:** 0x1067A (compare_objects)  
**Algorithm:** Calls compare_objects without permissions check.

### 25. Function at 0x7074E-0x7078C
**Entry:** 0x7074E  
**Name:** `eq_operator`  
**Purpose:** PostScript `eq` operator implementation.  
**Arguments:** Takes two objects from stack  
**Return:** Pushes boolean result to stack  
**Key calls:** 0x165F8 (get object), 0x1B6FA (create array), 0x10708 (objects_equal), 0x1BC78 (push boolean)  
**Algorithm:** Gets two objects, compares them, pushes boolean result.

### 26. Function at 0x7078E-0x707F2
**Entry:** 0x7078E  
**Name:** `ne_operator`  
**Purpose:** PostScript `ne` operator implementation.  
**Arguments:** Takes two objects from stack  
**Return:** Pushes boolean result to stack  
**Key calls:** 0x165F8 (get object), 0xFF64 (find_or_create_array_entry), 0x165AA (pop object), 0x1BC78 (push boolean)  
**Algorithm:** Gets two objects, compares them via find_or_create_array_entry, pushes inverted boolean result.

## KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **Address mapping was wrong** - Prior analysis referenced 0x6F000-0x6F268 but actual code is at 0x6FC00-0x70800.

2. **Misidentified functions** - Many functions were incorrectly named. This region contains array operations, dictionary operations, and comparison operators, not fixed-point math or glyph rendering.

3. **Data regions** - Only one small string table at 0x6FD28-0x6FD46 containing "array", "astore", "aload".

4. **Algorithm details** - The hash function at 0x6FDAE uses an LCG with multiplier 0x41C64E6D, distinct from both the C runtime LCG and PS PRNG.

5. **Array system** - Uses a global array counter at 0x202225C, wraps at 0xFFFF, with reset function at 0x26698.

The code in this region implements core PostScript operators for arrays and dictionaries: creation, access, storage, comparison, and hash table management.

; === CHUNK 23: 0x70800-0x71400 ===

Looking at this raw disassembly from 0x70800 to 0x71400, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addressing**: The prior analysis uses 0x107f4, 0x124ac, etc. but these are relative to the start of bank 3 (0x60000). The actual addresses in this disassembly are shown as 0x107f4, etc. because the disassembler is treating the file as starting at 0x0. In reality, these are offsets within bank 3.

2. **Function boundaries**: Some functions were incorrectly identified or their boundaries were wrong.

3. **Data vs code**: There's embedded data at 0x70EE8-0x70F34 that was misidentified as code.

## REFINED ANALYSIS:

### 1. `lookup_or_create_object` (0x70800)
**Entry:** 0x70800  
**Purpose:** Looks up an object in a dictionary. Handles special type 3 objects (likely protected/executable). If object not found and create flag is set, creates it. Checks access protection bits (bits 24-26).  
**Arguments:** Stack: dict_ptr, key, create_flag, output_ptr  
**Returns:** Object pointer in output parameter (A1@)  
**Calls:** 0x14050 (type conversion), 0x124ac (access error), 0xfe88 (search), 0x165aa (cleanup), 0x2640e (create)  
**RAM:** 0x2022258 (global flag)  
**Algorithm:** Checks if object type is 5 (string), converts if needed. For type 3 objects, compares at offset 12. Checks access bits (bfextu at offset 4, bits 24-26). Searches dictionary, creates if not found.

### 2. `get_object_with_flag` (0x708FA)
**Entry:** 0x708FA  
**Purpose:** Wrapper for lookup_or_create_object with flag=1 (create if missing).  
**Arguments:** Same as lookup_or_create_object  
**Calls:** 0x70800 (lookup_or_create_object)

### 3. `get_object_and_store_global1` (0x70922)
**Entry:** 0x70922  
**Purpose:** Calls get_object_with_flag and stores result in global at 0x2016744.  
**RAM:** 0x2016744 (global storage for object)

### 4. `get_object_without_flag` (0x70958)
**Entry:** 0x70958  
**Purpose:** Wrapper for lookup_or_create_object with flag=0 (don't create).  
**Calls:** 0x70800

### 5. `get_object_and_store_global2` (0x7097E)
**Entry:** 0x7097E  
**Purpose:** Calls get_object_without_flag and stores result in global at 0x201674C.  
**RAM:** 0x201674C (second global object storage)

### 6. `push_mark_object` (0x709B4)
**Entry:** 0x709B4  
**Purpose:** Pushes a mark object onto operand stack. Special handling for type 5 (string) objects.  
**Arguments:** Stack: stack_ptr, object_descriptor  
**Calls:** 0x14050 (type conversion), 0x1018E (stack push with mark flag=1)

### 7. `push_object` (0x70A18)
**Entry:** 0x70A18  
**Purpose:** Similar to push_mark_object but without mark flag.  
**Calls:** 0x14050, 0x1018E (stack push with mark flag=0)

### 8. `execute_current_object` (0x70A7A)
**Entry:** 0x70A7A  
**Purpose:** Gets current object from execution stack and executes it.  
**Calls:** 0x1B564 (get current), 0x1059C (execute), 0x165AA (cleanup)

### 9. `execute_by_name` (0x70AA6)
**Entry:** 0x70AA6  
**Purpose:** Looks up object by name in dictionary and executes it. Checks execute access.  
**Calls:** 0x1B6FA (name lookup), 0x124AC (access error), 0x1BB24 (execute)

### 10. `binary_operator_handler` (0x70AEA)
**Entry:** 0x70AEA  
**Purpose:** Handles binary operators (+, -, *, /, etc.). Pops two operands, performs operation, pushes result.  
**Calls:** 0x165F8 (pop operand), 0x14050 (type conversion), 0xFF64 (binary operation), 0x167DA (create result), 0x1018E (push)  
**Algorithm:** Pops two operands, converts strings if needed, calls binary operation function, creates result object, pushes it.

### 11. `unary_operator_handler` (0x70B9E)
**Entry:** 0x70B9E  
**Purpose:** Handles unary operators (negate, not, etc.). Creates result object.  
**Calls:** 0x167DA (create result), 0x165AA (cleanup)

### 12. `dict_next` (0x70BBE)
**Entry:** 0x70BBE  
**Purpose:** Dictionary iterator - gets next key-value pair. Maintains position counter.  
**Arguments:** Stack: dict_ptr, position_counter, output_buffer  
**Returns:** Updates output_buffer with key-value pair if found  
**Calls:** 0x26334 (error)  
**Algorithm:** Checks if position counter is zero (start). Iterates through dictionary entries (16-byte blocks). Skips empty entries (type 0). Updates position counter in output buffer.

### 13. `dict_forall` (0x70C7A)
**Entry:** 0x70C7A  
**Purpose:** Applies a procedure to all key-value pairs in a dictionary.  
**Arguments:** Stack: dict_ptr, procedure  
**Calls:** 0x1B690 (get dict), 0x263D6 (error), 0x166AC (get procedure), 0x16812 (get dict), 0x10BBE (dict_next), 0x165AA (cleanup), 0x1665E (push), 0x1BC08 (execute)  
**Algorithm:** Gets dictionary and procedure objects. Validates procedure type (must be 8=mark). Iterates through dictionary using dict_next, executing procedure for each key-value pair.

### 14. `dict_forall_execute` (0x70D5E)
**Entry:** 0x70D5E  
**Purpose:** Executes dict_forall operation.  
**Calls:** 0x10C7A (dict_forall)

### 15. `set_access_protection` (0x70DA2)
**Entry:** 0x70DA2  
**Purpose:** Sets access protection bits (readonly/executeonly/noaccess) for an object and all references to it.  
**Arguments:** Stack: object_ptr, protection_mask  
**Calls:** 0x124AC (access error), 0x2717E (update object), 0x270E8 (update reference)  
**Algorithm:** Checks current access bits, validates permission to change. Updates object's protection bits. Scans hash table (0x2017354) for all references to this object and updates their protection bits too.

### 16. `handle_system_dict_operation` (0x70E76)
**Entry:** 0x70E76  
**Purpose:** Dispatches system dictionary operations based on operation code.  
**Arguments:** D0 = operation code (0-5)  
**Calls:** 0x263D6 (error), 0x267F2 (setup), 0x269FA (execute)  
**Algorithm:** Switch on operation code: 0=load, 1=where, 2=forall, 3=known, 4=get, 5=put. Sets global flag at 0x202225C. For "where" operation, sets up and executes special procedure.

### 17. DATA REGION (0x70EE8-0x70F34)
**Address:** 0x70EE8  
**Size:** 76 bytes  
**Format:** Array of 19 4-byte entries, each appears to be a procedure offset or descriptor  
**Content:** Looks like a table of procedure descriptors for system dictionary operations

### 18. `set_global_error_handler` (0x70F8C)
**Entry:** 0x70F8C  
**Purpose:** Sets global error handler procedure.  
**Arguments:** Stack: error_handler_procedure  
**RAM:** 0x20174A8, 0x20174AC (global error handler storage)  
**Calls:** 0x2D8D8 (register handler)

### 19. `process_executable_object` (0x70FB6)
**Entry:** 0x70FB6  
**Purpose:** Processes an executable object (type 3, 9, or 13). Handles access protection and execution.  
**Arguments:** Stack: object_descriptor  
**Calls:** 0xF986 (get object), 0x10FB6 (process name), 0x1474E (process operator), 0x10100 (process procedure)  
**Algorithm:** Checks if object is executable (bits 1-3). For type 9 (name), processes name. For type 13 (operator), processes operator. For type 3 (procedure), validates and executes.

### 20. `execute_top_object` (0x710AC)
**Entry:** 0x710AC  
**Purpose:** Pops and executes top object from operand stack.  
**Calls:** 0x165F8 (pop), 0x263D6 (error), 0x10FB6 (process name), 0x1474E (process operator)  
**Algorithm:** Pops object, checks type (must be 9=name or 13=operator), processes accordingly.

### 21. `validate_executable_object` (0x71108)
**Entry:** 0x71108  
**Purpose:** Validates that an object is executable and has proper access rights.  
**Arguments:** A5 = object pointer  
**Calls:** 0x26334 (error), 0x166AC (get object), returns to caller if invalid  
**Algorithm:** Checks if object exists, is type 7 (procedure), and has execute permission (bits 4-6).

### 22. `cleanup_execution_stack` (0x7114A)
**Entry:** 0x7114A  
**Purpose:** Cleans up execution stack after operation.  
**Arguments:** Stack: stack_ptr  
**Calls:** 0x165F8 (pop), 0x165AA (cleanup)  
**Algorithm:** Pops object from stack if present, cleans up.

### 23. `get_execution_context` (0x71176)
**Entry:** 0x71176  
**Purpose:** Gets current execution context information.  
**Arguments:** Stack: context_ptr, output_buffer  
**Calls:** 0x169A0 (get context), 0x27FFE (process), 0x16A34 (copy), 0x11108 (validate), 0x1665E (push), 0x169C2 (get stack), 0x1042E (get system), 0x26334 (error)  
**Algorithm:** Gets execution context, processes it, copies to output. Handles special cases for system dict, user dict, and other contexts.

### 24. `push_to_execution_stack` (0x71266)
**Entry:** 0x71266  
**Purpose:** Pushes an object onto the execution stack with proper validation.  
**Arguments:** Stack: object_ptr  
**Calls:** 0x724AC (validate), 0x263D6 (error), 0x164A8 (allocate), updates linked list at 0x20174A4  
**Algorithm:** Validates object type and access rights. Allocates stack entry if needed. Updates execution stack linked list.

### 25. `check_for_interrupts` (0x71308)
**Entry:** 0x71308  
**Purpose:** Checks for pending interrupts or system events.  
**Calls:** 0x288F8 (process interrupts) via function pointer at 0x2000904+0xE+0x20  
**RAM:** 0x2000904 (system vector table)

### 26. `main_interpreter_loop` (0x71334)
**Entry:** 0x71334  
**Purpose:** Main PostScript interpreter execution loop.  
**Calls:** 0x2DF1C (setup), 0x26382 (check limits), 0x164A8 (allocate), 0x11266 (push to stack), 0x71DDC (process pending)  
**RAM:** 0x20008F4 (current context), 0x20167A4 (loop counter), 0x20174A4 (execution stack)  
**Algorithm:** Sets up execution context, checks loop counter, allocates stack frame, processes object, handles pending operations. This is the core interpreter loop.

## KEY INSIGHTS:

1. **Object Access Protection**: Bits 24-26 control readonly/executeonly/noaccess protection. Function at 0x70DA2 manages these bits.

2. **Dictionary Operations**: The system has comprehensive dictionary iteration (dict_next, dict_forall) and lookup (lookup_or_create_object) functions.

3. **Execution Stack Management**: A linked list at 0x20174A4 manages the execution stack with proper allocation and cleanup.

4. **System Dictionary**: Special handling for system dictionary operations with a dispatch table at 0x70EE8.

5. **Error Handling**: Global error handler can be set at 0x20174A8/AC.

6. **Main Loop**: The interpreter at 0x71334 is the core execution engine, checking interrupts every 10 iterations.

The prior analysis was mostly correct but missed the data region at 0x70EE8 and had some function boundaries wrong. The main interpreter loop starts at 0x71334, not 0x71400 as previously thought.

; === CHUNK 24: 0x71400-0x72000 ===

Looking at this disassembly from 0x71400 to 0x72000, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addressing**: The prior analysis uses addresses like 0x71400 but the disassembly shows them as 0x11400. This is because the disassembler is showing offsets from the start of bank 3 (which starts at 0x60000). So 0x71400 in the analysis = 0x11400 in the disassembly = actual address 0x71400.

2. **Function boundaries**: The prior analysis missed several smaller functions at the end of this range.

3. **Data regions**: The jump tables at 0x71420 and 0x71588 were incorrectly described.

## REFINED ANALYSIS:

### 1. `execute_loop` (0x71400-0x71dbc)
**Entry:** 0x71400  
**Purpose:** Main PostScript execution loop. Processes objects from operand stack (A4 points to stack head). Extracts object type from low 4 bits of first byte, dispatches via jump table at 0x71420. Handles all PS object types: integers (1), reals (2), booleans (4), strings (5), dictionaries (6), executable arrays (7), marks (8), names (9), operators (13). Manages literal vs. executable semantics, name lookup, and error conditions.  
**Arguments:** A4 = operand stack head pointer, A5 = current object pointer, A3 = execution stack head pointer  
**Returns:** D0 = status (0=continue, 1=exit)  
**RAM:** 0x201679c (pending operation count), 0x2016794/98 (primary/secondary pending ops), 0x2022258 (global flag)  
**Call targets:** 0x166ac (push), 0x1587e (type conversion), 0x70f8c (error handler), 0x150b2 (dictionary lookup), 0x184fa (cleanup), 0x13c5e (create object), 0x10138 (access check), 0x26334 (error), 0x2640e (cleanup), 0x164a8 (allocate stack node), 0x724ac (special handler)  
**Called by:** Main interpreter entry point

**Detailed flow:**
- 0x71400-0x7141e: Check if object is executable (bit 7 clear), if not, push to operand stack
- 0x71420: Jump table for object types (13 entries, 2 bytes each):
  - 0x71420: 0x001c (type 0 handler) → 0x7143c
  - 0x71422: 0x0700 (type 1: integer) → 0x71b24
  - 0x71424: 0x0700 (type 2: real) → 0x71b24  
  - 0x71426: 0x047a (type 3 handler) → 0x7189a
  - 0x71428: 0x0700 (type 4: boolean) → 0x71b24
  - 0x7142a: 0x002c (type 5: string) → 0x71456
  - 0x7142c: 0x00a6 (type 6: dictionary) → 0x714d2
  - 0x7142e: 0x0578 (type 7: executable array) → 0x71978
  - 0x71430: 0x0700 (type 8: mark) → 0x71b24
  - 0x71432: 0x038a (type 9: name) → 0x7178a
  - 0x71434: 0x0700 (type 10 handler) → 0x71b24
  - 0x71436: 0x0700 (type 11 handler) → 0x71b24
  - 0x71438: 0x0700 (type 12 handler) → 0x71b24
  - 0x7143a: 0x010e (type 13: operator) → 0x7154e

### 2. `handle_pending_operation` (0x719ce-0x71b14)
**Entry:** 0x719ce (continuation point in execute_loop)  
**Purpose:** Checks for pending operations after each object execution. Processes error codes -1 through -8 with special meanings. Handles stack cleanup, dictionary lookup, and fatal errors.  
**Arguments:** None (uses global variables)  
**Returns:** Continues execution or exits via pending op handler  
**RAM:** 0x201679c (pending count), 0x2016794/98 (pending ops)  
**Call targets:** 0x71ddc (set_pending), 0x1b1ec (error check), 0x185c6 (stack check), 0x19270 (validate), 0x184fa (cleanup), 0x108fa (lookup), 0x1669c (push result), 0x1665e (pop), 0x2d8d8 (fatal error)  
**Called by:** execute_loop (at 0x719ce)

### 3. `get_pending_operation` (0x71dbe-0x71dda)
**Entry:** 0x71dbe  
**Purpose:** Returns current pending operation code. Checks primary pending first, then secondary.  
**Arguments:** None  
**Returns:** D0 = pending operation code or 0 if none  
**RAM:** 0x2016794 (primary pending), 0x2016798 (secondary pending)  
**Call targets:** None  
**Called by:** Error handlers, interrupt routines

### 4. `set_pending_operation` (0x71ddc-0x71e20)
**Entry:** 0x71ddc  
**Purpose:** Sets a pending operation for later processing. Code -5 goes to secondary queue, others to primary.  
**Arguments:** D0 = pending operation code (via stack at fp@(8))  
**Returns:** None  
**RAM:** 0x2016794 (primary pending), 0x2016798 (secondary pending), 0x201679c (pending count)  
**Call targets:** None  
**Called by:** handle_pending_operation, error handlers

### 5. `clear_pending_operation` (0x71e22-0x71e36)
**Entry:** 0x71e22  
**Purpose:** Sets pending operation to -4 (clear/signal).  
**Arguments:** None  
**Returns:** None  
**RAM:** 0x2016794 (primary pending), 0x201679c (pending count)  
**Call targets:** None  
**Called by:** System cleanup routines

### 6. `push_executable_object` (0x71e38-0x71e62)
**Entry:** 0x71e38  
**Purpose:** Pushes an executable object onto the execution stack. Used for procedure calls.  
**Arguments:** None (uses local frame variables)  
**Returns:** None  
**RAM:** 0x2016764 (execution context)  
**Call targets:** 0x165f8 (get_object), 0x1665e (pop), 0x11266 (push_exec)  
**Called by:** Procedure execution handlers

### 7. `execute_procedure` (0x71e64-0x71e74)
**Entry:** 0x71e64  
**Purpose:** Executes a procedure by calling the procedure handler.  
**Arguments:** None  
**Returns:** None  
**Call targets:** 0x1bc78 (procedure handler)  
**Called by:** Procedure dispatch

### 8. `push_and_execute` (0x71e76-0x71e92)
**Entry:** 0x71e76  
**Purpose:** Pushes an object and immediately executes it.  
**Arguments:** None (uses local frame variables)  
**Returns:** None  
**Call targets:** 0x165f8 (get_object), 0x11266 (push_exec)  
**Called by:** Immediate execution handlers

### 9. `set_fatal_error` (0x71e94-0x71ea8)
**Entry:** 0x71e94  
**Purpose:** Sets pending operation to -7 (fatal error).  
**Arguments:** None  
**Returns:** None  
**RAM:** 0x2016794 (primary pending), 0x201679c (pending count)  
**Call targets:** None  
**Called by:** Fatal error handlers

### 10. `compare_and_select` (0x71eaa-0x71ed0)
**Entry:** 0x71eaa  
**Purpose:** Compares two objects and selects one based on comparison result.  
**Arguments:** None (uses local frame variables)  
**Returns:** None  
**Call targets:** 0x1ba8e (compare), 0x1b94a (select), 0x11266 (push_exec)  
**Called by:** Conditional operators

### 11. `compare_and_select_two` (0x71ed2-0x71f0c)
**Entry:** 0x71ed2  
**Purpose:** Compares two pairs of objects and selects based on comparison.  
**Arguments:** None (uses local frame variables)  
**Returns:** None  
**Call targets:** 0x1ba8e (compare), 0x1b94a (select), 0x11266 (push_exec)  
**Called by:** Complex conditional operators

### 12. `get_and_process_index` (0x71f0e-0x71f56)
**Entry:** 0x71f0e  
**Purpose:** Gets an index value, processes it, and pushes result.  
**Arguments:** None (uses local frame variables)  
**Returns:** None  
**Call targets:** 0x1ba8e (get_value), 0x1b626 (process_index), 0x263ba (error), 0x11266 (push_exec), 0x1bc08 (create_result), 0x1665e (pop)  
**Called by:** Array/index operators

### 13. `process_array_element` (0x71f58-0x72000)
**Entry:** 0x71f58  
**Purpose:** Processes an array element access with bounds checking.  
**Arguments:** None (uses local frame variables, saves A5)  
**Returns:** None  
**RAM:** 0x20174a4 (array context), 0x201676c (result buffer)  
**Call targets:** 0x1b690 (get_array_info), 0x1bc08 (create_result), 0x164a8 (allocate_stack_node), 0x1665e (pop)  
**Called by:** Array access operators

## DATA REGIONS:

### 1. Object Type Dispatch Table (0x71420-0x7143a)
**Address:** 0x71420  
**Size:** 13 entries × 2 bytes = 26 bytes  
**Format:** 16-bit offsets from table base (0x71420)  
**Contents:** Offsets to handlers for object types 0-13

### 2. Encoded Name Dispatch Table (0x71588-0x7159e)
**Address:** 0x71588  
**Size:** 9 entries × 2 bytes = 18 bytes  
**Format:** 16-bit offsets from table base (0x71588)  
**Contents:** Offsets for encoded name types (0-8)

### 3. Pending Operation Dispatch Table (0x71a26-0x71a34)
**Address:** 0x71a26  
**Size:** 8 entries × 2 bytes = 16 bytes  
**Format:** 16-bit offsets from table base (0x71a26)  
**Contents:** Offsets for pending operation codes -1 to -8

### 4. Special Handler Dispatch Table (0x71810-0x71820)
**Address:** 0x71810  
**Size:** 11 entries × 2 bytes = 22 bytes  
**Format:** 16-bit offsets from table base (0x71810)  
**Contents:** Offsets for special object handlers

### 5. Executable Handler Dispatch Table (0x7191c-0x7192c)
**Address:** 0x7191c  
**Size:** 9 entries × 2 bytes = 18 bytes  
**Format:** 16-bit offsets from table base (0x7191c)  
**Contents:** Offsets for executable object handlers

## KEY INSIGHTS:

1. **Object Encoding**: Objects use low 4 bits for type, bit 7 for executable flag, bits 4-6 for access permissions.

2. **Stack Management**: Both operand stack (A4) and execution stack (A3) are doubly-linked lists with automatic node allocation.

3. **Pending Operations**: System uses -1 to -8 codes for special operations like cleanup (-4), secondary (-5), fatal (-7), special (-8).

4. **Name Resolution**: Encoded names (types 0x42-0x81) use a hash table lookup with linear probing.

5. **Error Handling**: Comprehensive error checking with cleanup paths for all object types.

6. **Procedure Execution**: Separate handlers for immediate execution vs. deferred procedure calls.

The code in this range represents the core of the PostScript interpreter's execution engine, handling all object type dispatch, stack management, and error recovery.

; === CHUNK 25: 0x72000-0x72C00 ===

Looking at the raw disassembly from 0x72000 to 0x72C00, I can see several issues with the prior analysis. Let me provide a corrected and refined analysis:

## CORRECTED FUNCTIONS:

### 1. 0x72000 - `linked_list_insert_or_remove`
**Entry:** 0x72000  
**What it does:** This is NOT a function - it's actually part of a larger function. The code at 0x72000-0x72040 is data manipulation code that operates on a doubly-linked list at 0x20174a4. It appears to be inserting or removing nodes from the list.  
**Arguments:** A5 appears to be a node pointer  
**RAM accessed:** 0x20174a4 (list head pointer)  
**Key targets:** 0x1203a (common exit path)  
**Correction:** This is not a standalone function - it's part of a larger routine.

### 2. 0x72042 - `check_type_int_or_real`
**Entry:** 0x72042  
**What it does:** Checks if a PostScript object is either integer (type 1) or real (type 2). Calls error handler at 0x263d6 if neither. Uses bfextu to extract low 4 bits for type checking.  
**Arguments:** Pointer to object at fp@(8)  
**Calls:** 0x165f8 (likely gets object), 0x263d6 (typecheckerror)  
**Returns:** None - just validates type

### 3. 0x72074 - `three_arg_arithmetic_op`
**Entry:** 0x72074  
**What it does:** Performs arithmetic on three arguments with type coercion. Gets three values, checks types, converts integers to reals if needed, performs operation via 0x1beac (arithmetic handler), pushes result.  
**Arguments:** Three values via stack  
**Calls:** 0x1ba8e (get value), 0x12042 (type check), 0x11266, 0x89a10 (int→real conversion), 0x1beac (arithmetic), 0x1bc08, 0x1665e  
**RAM accessed:** 0x201677c (result location), 0x2016774  
**Key paths:** 0x12156 (mixed int/real path), 0x121a4 (common result push)

### 4. 0x721b0 - `two_arg_arithmetic_op` 
**Entry:** 0x721b0  
**What it does:** Similar to three_arg but for two arguments. Includes sign checking and overflow detection. Calls 0x89980 for comparison, 0x89938 for arithmetic.  
**Arguments:** Two values via stack  
**Calls:** 0x1b8c0, 0x16812, 0x89980 (comparison), 0x89938 (arithmetic), 0x1beac, 0x1665e, 0x1be16  
**RAM accessed:** 0x201677c  
**Error handling:** Calls 0x166ac on overflow

### 5. 0x72278 - `add_operator` ✓
**Entry:** 0x72278  
**What it does:** PostScript `add` operator. Pops three values, adds with overflow checking. For integers, checks sign overflow; for reals, uses FPU.  
**Arguments:** Three values from interpreter stack  
**Calls:** 0x1b690 (pop), 0x16812, 0x166ac (rangecheck error), 0x1bc08, 0x1665e, 0x1bb98  
**RAM accessed:** 0x2016774 (result pointer)  
**Key logic:** Checks if (a>0 && b>c) or (a<0 && b<c) for overflow

### 6. 0x72322 - `unknown_single_arg_op`
**Entry:** 0x72322  
**What it does:** Gets a single argument, processes it via 0x11266, then pushes to 0x2016784. Likely a type conversion or validation operator.  
**Arguments:** One value  
**Calls:** 0x1ba8e, 0x11266, 0x1665e  
**RAM accessed:** 0x2016784

### 7. 0x7234e - `stack_manipulation_with_list`
**Entry:** 0x7234e  
**What it does:** Complex stack manipulation using the linked list at 0x20174a4. Moves items between positions in what appears to be a stack implemented as a linked list.  
**Arguments:** Implicit via A5  
**Calls:** 0x164a8 (error/alloc on empty list)  
**RAM accessed:** 0x20174a4, 0x2016784  
**Algorithm:** Gets list head, manipulates next/prev pointers to reorder elements

### 8. 0x723f4 - `type_conversion_or_error`
**Entry:** 0x723f4  
**What it does:** Checks argument type and handles differently: type 1 prints and calls something with -6; type 2 calls 0x70f8c with values from 0x2000930/34. Other types cause error loop.  
**Arguments:** Value at fp@(-8)  
**Calls:** 0x11108, 0x1665e, 0x2d8d8, 0x70f8c, 0x166ac  
**RAM accessed:** 0x2000930, 0x2000934, 0x2016784  
**Error loop:** Subtracts 3 from type and loops calling 0x166ac

### 9. 0x72476 - `increment_counter_and_process`
**Entry:** 0x72476  
**What it does:** Increments counter at 0x20167a0, processes something, then decrements counter. If counter goes negative, resets to 0.  
**Arguments:** Value at fp@(-8)  
**Calls:** 0x165f8, 0x11334  
**RAM accessed:** 0x20167a0 (loop counter)  
**Purpose:** Likely manages nested execution contexts or interrupt checking

### 10. 0x724ac - `check_counter_and_call`
**Entry:** 0x724ac  
**What it does:** Checks if counter at 0x20167a0 is zero, if so calls 0x70f8c with values from 0x2000928/2c.  
**Arguments:** None  
**Calls:** 0x70f8c  
**RAM accessed:** 0x20167a0, 0x2000928, 0x200092c  
**Purpose:** Conditional execution based on nesting level

### 11. 0x724d0 - `setup_operator_table`
**Entry:** 0x724d0  
**What it does:** Sets up operator table based on argument (0 or 1). For 0: sets flag at 0x2022258 to 1. For 1: registers multiple operators with names and handlers.  
**Arguments:** Value at fp@(8)  
**Calls:** 0x14096, 0x268de, 0x267f2, 0x269fa, 0x10350, 0x26948, 0x103bc  
**RAM accessed:** 0x2022258, 0x2016754, 0x201678c, 0x201675c, 0x2016764, 0x2016784, 0x201676c, 0x2016774, 0x201677c, 0x2017354  
**Operators registered:** "interrupt", "exit", "exec", "stop", "loop", "repeat", "if", "ifelse", "for", "bind", "superexec"

### 12. 0x7262a - `initialize_system_operators`
**Entry:** 0x7262a  
**What it does:** Initializes multiple system operator groups by calling various setup functions.  
**Arguments:** Value at fp@(8)  
**Calls:** 0x140ee, 0x10e76, 0x160f0, 0xfcc8, 0x14888, 0x124d0, 0x16dc8, 0x1a2cc, 0x1b120, 0x1cee8, 0x139f0  
**Purpose:** Comprehensive operator initialization

### 13. 0x726b4 - DATA REGION (character width table)
**Address:** 0x726b4  
**Size:** ~0x130 bytes  
**Format:** Table of character widths or spacing data. Contains repeating patterns of ASCII character codes.  
**Content:** Appears to be a fixed-width font spacing table with values for different character groups.

### 14. 0x72800 - DATA REGION (operator name table)
**Address:** 0x72800  
**Size:** 0x5c bytes  
**Format:** Table of operator name strings with pointers. Each entry appears to be 4 bytes.  
**Content:** Operator names for the operators registered at 0x724d0.

### 15. 0x7285e - DATA REGION (string table)
**Address:** 0x7285e  
**Size:** ~0x86 bytes  
**Format:** Null-terminated ASCII strings.  
**Strings:** "interrupt", "exit", "exec", "stop", "loop", "repeat", "if", "ifelse", "for", "bind", "superexec", "stopped", "exitcontext", "files", "repeatfor", "ifelsefiles", "stopexec"

### 16. 0x728e4 - `add_real_numbers`
**Entry:** 0x728e4  
**What it does:** Adds two numbers with full type handling (int+int, int+real, real+int, real+real). Uses 64-bit intermediate for integer overflow detection.  
**Arguments:** Two values at fp@(-16) and fp@(-8)  
**Calls:** 0x165f8, 0x263d6, 0x1be16, 0x1bb98, 0x899f8 (int64 conversion), 0x89920 (add), 0x899c8 (convert to real), 0x89a10 (int→real), 0x89938 (add reals)  
**RAM accessed:** Various local variables  
**Algorithm:** Handles all 4 type combinations with proper overflow checking

### 17. 0x72a42 - `subtract_real_numbers`
**Entry:** 0x72a42  
**What it does:** Subtracts two numbers with full type handling. Similar to add but uses subtraction operations.  
**Arguments:** Two values at fp@(-16) and fp@(-8)  
**Calls:** 0x165f8, 0x263d6, 0x1be16, 0x1bb98, 0x899f8, 0x89aa0 (subtract), 0x899c8, 0x89a10, 0x89ab8 (subtract reals)  
**RAM accessed:** Various local variables  
**Algorithm:** Handles all 4 type combinations

### 18. 0x72ba0 - `multiply_real_numbers` (partial)
**Entry:** 0x72ba0  
**What it does:** Begins multiplication of two numbers with type handling. Incomplete in this chunk.  
**Arguments:** Two values at fp@(-16) and fp@(-8)  
**Calls:** 0x165f8, will likely call multiplication routines  
**RAM accessed:** Various local variables

## CORRECTIONS TO PRIOR ANALYSIS:

1. **0x72000 is NOT a function** - it's continuation of code from previous chunk.
2. **0x726b4 is DATA, not code** - contains character width/spacing table.
3. **0x72800 and 0x7285e are DATA** - operator name tables.
4. **Function names were mostly correct** but some descriptions were vague.
5. **The arithmetic functions (0x728e4, 0x72a42, 0x72ba0)** are complete implementations with full type coercion, not just "unknown" functions.

## KEY INSIGHTS:

1. **Type system:** PostScript objects use low 4 bits for type: 1=int, 2=real.
2. **Arithmetic coercion:** Functions handle all combinations of int/real with proper conversion.
3. **Operator registration:** 0x724d0 shows how PostScript operators are bound to C functions.
4. **Linked list stack:** 0x7234e reveals stack implementation using doubly-linked list at 0x20174a4.
5. **Counter-based execution:** 0x20167a0 tracks nesting level for interrupt checking.

The code in this region primarily implements PostScript arithmetic operators and operator registration infrastructure, with comprehensive type handling and error checking.

; === CHUNK 26: 0x72C00-0x73800 ===

## CORRECTED AND REFINED ANALYSIS OF 0x72C00-0x73800

The prior analysis had several significant errors and omissions. I've corrected function names, identified all functions in this range, and provided detailed analysis. This region contains PostScript mathematical operators, comparison operators, and trigonometric functions.

### 1. 0x72C00 - `ps_mod` (PostScript `mod` operator)
**Entry:** 0x72C00  
**Purpose:** Implements PostScript's `mod` operator (remainder). Takes two numbers from stack, computes remainder. Handles all type combinations: int/int, real/real, int/real, real/int. For integers: uses integer remainder. For reals: uses floating-point modulo via 0x89A28. Special handling for negative numbers: ensures remainder has same sign as dividend (PostScript spec).  
**Arguments:** Two PostScript objects accessed via stack frame: fp@(-4)=dividend, fp@(-12)=divisor  
**Return:** Pushes result object via 0x1BE16  
**Calls:** 0x1BE16 (push result), 0x89968 (floating compare), 0x89A28 (floating modulo), 0x1BB98 (push integer), 0x899F8 (int to float), 0x89A58 (floating multiply), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Multiple branches for different type combinations  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Checks types, converts to float if needed, computes remainder. For mixed types, converts int to float first. Uses floating compare at 0x72C26 to check if divisor > 0.

### 2. 0x72D4A - `ps_idiv` (PostScript `idiv` operator)
**Entry:** 0x72D4A  
**Purpose:** Integer division operator. Takes two numbers, performs integer division, pushes integer result. Checks for division by zero (calls 0x2642A). Converts reals to integers via truncation. Uses floating-point division then conversion to int.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second (type bytes), fp@(-12)=first value, fp@(-4)=second value  
**Return:** Pushes integer result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x2642A (rangecheck), 0x899F8 (int to float), 0x89A88 (real to float), 0x89998 (floating divide), 0x1BE16 (push result)  
**RAM accessed:** None directly  
**Key targets:** 0x12D82 (int case), 0x12D9A (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, checks types. For integers: converts to float via 0x899F8. For reals: uses 0x89A88. Performs floating division at 0x72E02, converts result to integer at 0x72E08.

### 3. 0x72E22 - `ps_div` (PostScript `div` operator)
**Entry:** 0x72E22  
**Purpose:** Division operator for integers only. Takes two integers, performs division, pushes integer result if exact, otherwise real. Special case for -1 ÷ -2147483648 (calls rangecheck error). Uses 68020's `divsll` instruction for 64-bit division.  
**Arguments:** Two integers popped via 0x1B626: fp@(-8)=dividend, fp@(-4)=divisor  
**Return:** Pushes integer result via 0x1BB98  
**Calls:** 0x1B626 (pop value), 0x2642A (rangecheck), 0x1BB98 (push integer)  
**RAM accessed:** None directly  
**Key targets:** 0x12E54 (normal path after overflow check)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Pops two values, checks for -1 ÷ -2147483648 overflow case (would produce 2147483648 > 32-bit signed). Uses `divsll %fp@(-8),%d0,%d0` at 0x72E5E for signed 64÷32→32 division.

### 4. 0x72E6C - `ps_mul` (PostScript `mul` operator)
**Entry:** 0x72E6C  
**Purpose:** Multiplication operator for integers only. Takes two integers, multiplies them. Checks types (must both be integers), handles division by zero? Actually checks divisor != 0 at 0x72EAE. Uses `divsll` in unusual way: `divsll %fp@(-12),%d1,%d0` computes 64-bit product?  
**Arguments:** Two integer objects: fp@(-16)=first type, fp@(-8)=second type, fp@(-12)=first value, fp@(-4)=second value  
**Return:** Pushes integer result via 0x1BB98  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x2642A (rangecheck)  
**RAM accessed:** None directly  
**Key targets:** 0x12EA4 (type check), 0x12EB6 (division by zero check)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, checks types (must be integers). Checks for division by zero? Actually checks if divisor != 0. Uses `divsll %fp@(-12),%d1,%d0` at 0x72EBA for multiplication.

### 5. 0x72ECE - `ps_neg` (PostScript `neg` operator)
**Entry:** 0x72ECE  
**Purpose:** Negation operator. Takes one number, returns its negative. Handles integers and reals. Special case for integer -2147483648 (calls 0x89A10 to convert to float).  
**Arguments:** One object: fp@(-8)=type byte, fp@(-4)=value  
**Return:** Pushes result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x89A10 (int to float conversion), 0x1BE16 (push result), 0x1BB98 (push integer)  
**RAM accessed:** None directly  
**Key targets:** 0x12F1E (integer case), 0x12F38 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: checks for -2147483648 special case, otherwise uses `negl`. For real: calls 0x89A10 to convert to float, then toggles sign bit.

### 6. 0x72F3E - `ps_abs` (PostScript `abs` operator)
**Entry:** 0x72F3E  
**Purpose:** Absolute value operator. Takes one number, returns its absolute value. Handles integers and reals. Special case for integer -2147483648 (calls 0x89A10 to convert to float).  
**Arguments:** One object: fp@(-8)=type byte, fp@(-4)=value  
**Return:** Pushes result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x89A10 (int to float conversion), 0x1BE16 (push result), 0x1BB98 (push integer)  
**RAM accessed:** None directly  
**Key targets:** 0x12FA0 (integer case), 0x12FC6 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: checks for -2147483648 special case, otherwise uses `tstl` and `negl` if negative. For real: checks if negative, toggles sign bit.

### 7. 0x72FD2 - `ps_ceiling` (PostScript `ceiling` operator)
**Entry:** 0x72FD2  
**Purpose:** Ceiling function. Takes one number, returns smallest integer ≥ argument. Handles integers and reals. For reals, uses floating-point ceiling via 0x298AC.  
**Arguments:** One object via A5 pointer: A5@=type byte, A5@(4)=value  
**Return:** Pushes integer result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x165AA (pop object), 0x89A88 (real to float), 0x298AC (floating ceiling), 0x89968 (floating compare), 0x89AA0 (floating subtract), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** 0x13008 (integer case), 0x13014 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: just pops it. For real: converts to float, computes ceiling via 0x298AC, checks if result > argument, adjusts if needed.

### 8. 0x730B8 - `ps_floor` (PostScript `floor` operator)
**Entry:** 0x730B8  
**Purpose:** Floor function. Takes one number, returns largest integer ≤ argument. Handles integers and reals. For reals, uses floating-point floor via 0x298A0.  
**Arguments:** One object via A5 pointer: A5@=type byte, A5@(4)=value  
**Return:** Pushes integer result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x165AA (pop object), 0x89A88 (real to float), 0x298A0 (floating floor), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** 0x130EC (integer case), 0x130F8 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: just pops it. For real: converts to float, computes floor via 0x298A0, converts back to integer.

### 9. 0x73126 - `ps_round` (PostScript `round` operator)
**Entry:** 0x73126  
**Purpose:** Round function. Takes one number, returns nearest integer (ties round away from zero). Handles integers and reals. For reals, uses floating-point rounding via 0x298AC.  
**Arguments:** One object via A5 pointer: A5@=type byte, A5@(4)=value  
**Return:** Pushes integer result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x165AA (pop object), 0x89A88 (real to float), 0x298AC (floating rounding), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** 0x1315C (integer case), 0x13168 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: just pops it. For real: converts to float, computes rounding via 0x298AC, converts back to integer.

### 10. 0x73196 - `ps_truncate` (PostScript `truncate` operator)
**Entry:** 0x73196  
**Purpose:** Truncate function. Takes one number, returns integer part (toward zero). Handles integers and reals. For reals, uses floor for positive numbers, ceiling for negative.  
**Arguments:** One object via A5 pointer: A5@=type byte, A5@(4)=value  
**Return:** Pushes integer result via 0x1BE16  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x165AA (pop object), 0x89A88 (real to float), 0x298AC (floating ceiling), 0x298A0 (floating floor), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** 0x131CC (integer case), 0x131D8 (real case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: just pops it. For real: checks sign, uses floor for positive, ceiling for negative.

### 11. 0x7322A - `compare_numbers` (internal comparison function)
**Entry:** 0x7322A  
**Purpose:** Internal function to compare two numbers. Handles all type combinations: int/int, real/real, int/real, real/int, string/string. Returns -1 if first < second, 0 if equal, 1 if first > second.  
**Arguments:** Four arguments on stack: fp@(8)=first type, fp@(12)=first value, fp@(16)=second type, fp@(20)=second value  
**Return:** D0 = comparison result (-1, 0, 1)  
**Calls:** 0x263D6 (type error), 0x89A10 (int to float), 0x89980 (floating compare), 0x124AC (string comparison), 0x1A804 (string comparison with access check)  
**RAM accessed:** None directly  
**Key targets:** Multiple branches for different type combinations  
**Called by:** Comparison operators (lt, gt, etc.)  
**Algorithm:** Checks types, handles each combination separately. For mixed int/real, converts int to float first. For strings, checks access bits and calls string comparison.

### 12. 0x7334A - `ps_lt` (PostScript `lt` operator)
**Entry:** 0x7334A  
**Purpose:** Less-than operator. Takes two numbers, returns true if first < second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1B1EC (compare with swapped args?), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Calls 0x1B1EC which likely calls compare_numbers  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls comparison, pushes boolean result.

### 13. 0x7338E - `ps_le` (PostScript `le` operator)
**Entry:** 0x7338E  
**Purpose:** Less-than-or-equal operator. Takes two numbers, returns true if first ≤ second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1B1EC (compare), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Similar to ps_lt  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls comparison, checks if result ≤ 0.

### 14. 0x733DC - `ps_gt` (PostScript `gt` operator)
**Entry:** 0x733DC  
**Purpose:** Greater-than operator. Takes two numbers, returns true if first > second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1322A (compare_numbers), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Direct call to compare_numbers  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls compare_numbers, pushes boolean result.

### 15. 0x7341E - `ps_ge` (PostScript `ge` operator)
**Entry:** 0x7341E  
**Purpose:** Greater-than-or-equal operator. Takes two numbers, returns true if first ≥ second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1322A (compare_numbers), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Direct call to compare_numbers  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls compare_numbers with args swapped, checks if result ≤ 0.

### 16. 0x7346A - `ps_eq` (PostScript `eq` operator)
**Entry:** 0x7346A  
**Purpose:** Equality operator. Takes two numbers, returns true if first = second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1322A (compare_numbers), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Direct call to compare_numbers  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls compare_numbers, checks if result = 0.

### 17. 0x734AC - `ps_ne` (PostScript `ne` operator)
**Entry:** 0x734AC  
**Purpose:** Not-equal operator. Takes two numbers, returns true if first ≠ second. Uses internal comparison function.  
**Arguments:** Two objects: fp@(-16)=first, fp@(-8)=second  
**Return:** Pushes boolean result via 0x1BC78  
**Calls:** 0x165F8 (get object), 0x1322A (compare_numbers), 0x1BC78 (push boolean)  
**RAM accessed:** None directly  
**Key targets:** Direct call to compare_numbers  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets both objects, calls compare_numbers with args swapped, checks if result ≠ 0.

### 18. 0x734F8 - `ps_sin` (PostScript `sin` operator)
**Entry:** 0x734F8  
**Purpose:** Sine function. Takes angle in degrees, returns sine. Converts degrees to radians (multiplies by π/180).  
**Arguments:** One object: fp@(-4)=angle  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x89A88 (real to float), 0x89A58 (floating multiply), 0x2A784 (floating sine), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Uses constant at 0x73542 (π/180 ≈ 0.017453292519943295)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets angle in degrees, converts to radians, computes sine via 0x2A784.

### 19. 0x7354E - `ps_cos` (PostScript `cos` operator)
**Entry:** 0x7354E  
**Purpose:** Cosine function. Takes angle in degrees, returns cosine. Converts degrees to radians (multiplies by π/180).  
**Arguments:** One object: fp@(-4)=angle  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x89A88 (real to float), 0x89A58 (floating multiply), 0x2A72C (floating cosine), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Uses constant at 0x73594 (π/180 ≈ 0.017453292519943295)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets angle in degrees, converts to radians, computes cosine via 0x2A72C.

### 20. 0x735A0 - `ps_atan` (PostScript `atan` operator)
**Entry:** 0x735A0  
**Purpose:** Arctangent function. Takes y and x, returns angle in degrees. Handles two arguments (y, x). Converts result from radians to degrees (multiplies by 180/π).  
**Arguments:** Two objects: fp@(-8)=y, fp@(-4)=x  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x2642A (rangecheck), 0x89A88 (real to float), 0x29F34 (floating arctan2), 0x89A58 (floating multiply), 0x89920 (floating add?), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Uses constants at 0x13638 (180/π ≈ 57.29577951308232) and 0x13640 (adjustment constant)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets y and x, checks for (0,0) case (calls rangecheck), computes atan2 via 0x29F34, converts radians to degrees, adjusts quadrant.

### 21. 0x73648 - `ps_exp` (PostScript `exp` operator)
**Entry:** 0x73648  
**Purpose:** Exponential function. Takes x, returns e^x. Uses floating-point exponential.  
**Arguments:** Two objects: fp@(-8)=base?, fp@(-4)=exponent? Actually takes one argument.  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x89A88 (real to float), 0x2A5E0 (floating exponential), 0x899C8 (float to int)  
**RAM accessed:** 0x202226C (error flag)  
**Key targets:** Checks error flag at 0x202226C  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets argument, converts to float, computes exponential via 0x2A5E0, checks for errors.

### 22. 0x736B8 - `ps_ln` (PostScript `ln` operator)
**Entry:** 0x736B8  
**Purpose:** Natural logarithm. Takes x > 0, returns ln(x). Checks for non-positive argument.  
**Arguments:** One object: fp@(-4)=x  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x263BA (rangecheck for ≤ 0), 0x89A88 (real to float), 0x2A56E (floating logarithm), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Checks x > 0  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets argument, checks if > 0, computes natural log via 0x2A56E.

### 23. 0x73704 - `ps_log` (PostScript `log` operator)
**Entry:** 0x73704  
**Purpose:** Base-10 logarithm. Takes x > 0, returns log₁₀(x). Checks for non-positive argument.  
**Arguments:** One object: fp@(-4)=x  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x263BA (rangecheck for ≤ 0), 0x89A88 (real to float), 0x2A338 (floating log10), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Checks x > 0  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets argument, checks if > 0, computes base-10 log via 0x2A338.

### 24. 0x73750 - `ps_sqrt` (PostScript `sqrt` operator)
**Entry:** 0x73750  
**Purpose:** Square root. Takes x ≥ 0, returns √x. Checks for negative argument.  
**Arguments:** One object: fp@(-4)=x  
**Return:** Pushes real result via 0x1BE16  
**Calls:** 0x1B81A (get real number), 0x263BA (rangecheck for < 0), 0x89A88 (real to float), 0x2B990 (floating square root), 0x899C8 (float to int)  
**RAM accessed:** None directly  
**Key targets:** Checks x ≥ 0, handles -0.0  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets argument, checks if ≥ 0 (allowing -0.0), computes square root via 0x2B990.

### 25. 0x737A4 - `ps_not` (PostScript `not` operator)
**Entry:** 0x737A4  
**Purpose:** Logical NOT. Takes integer or boolean, returns bitwise complement for integers, logical NOT for booleans.  
**Arguments:** One object: fp@(-8)=type byte, fp@(-4)=value  
**Return:** Pushes result via 0x165AA (pop and push?)  
**Calls:** 0x165F8 (get object), 0x263D6 (type error), 0x165AA (pop object)  
**RAM accessed:** None directly  
**Key targets:** 0x137DC (integer case), 0x137CA (boolean case)  
**Called by:** PostScript operator dispatcher  
**Algorithm:** Gets object, checks type. For integer: uses `notl`. For boolean: returns opposite boolean value.

### DATA REGIONS:
- **0x73542-0x73548:** Floating-point constant π/180 ≈ 0.017453292519943295
- **0x73594-0x7359A:** Floating-point constant π/180 (duplicate for cos)
- **0x73638-0x7363E:** Floating-point constant 180/π ≈ 57.29577951308232
- **0x73640-0x73646:** Floating-point constant for atan adjustment

### CORRECTIONS FROM PRIOR ANALYSIS:
1. The prior analysis incorrectly described functions at 0x72000-0x72400; this chunk starts at 0x72C00.
2. Added missing functions: ps_ceiling, ps_floor, ps_round, ps_truncate, compare_numbers, and all comparison operators.
3. Corrected function purposes: ps_div is for integers only, not general division.
4. Identified trigonometric functions (sin, cos, atan) and mathematical functions (exp, ln, log, sqrt).
5. Fixed argument descriptions for functions using A5 pointer convention.

### KEY INSIGHTS:
- This region contains all PostScript mathematical operators except add/sub (which are at 0x72278/0x72A42).
- The comparison function at 0x7322A is a central dispatcher used by all comparison operators.
- Trigonometric functions work in degrees, not radians (conversion via π/180).
- Error handling: rangecheck for invalid arguments (negative sqrt, non-positive log, etc.).
- Type handling: careful conversion between integers and reals, with special cases for -2147483648.

; === CHUNK 27: 0x73800-0x74400 ===

## **CORRECTED AND EXPANDED ANALYSIS OF 0x73800-0x74400**

I've reviewed the raw disassembly and found several significant errors in the prior analysis. Here's the corrected version:

### **CORRECTIONS TO PRIOR ANALYSIS:**
1. **0x73970** is NOT `ps_rand_init` - it's `ps_rand_operator` initialization (part of operator table setup)
2. **0x739f0** is NOT `ps_rand_init` - it's `ps_rand_operator` (the actual rand operator)
3. **0x73a2c-0x73b30** is a DATA TABLE (operator name/address pairs), not code
4. **0x73b3c-0x73bc0** is a STRING TABLE (PostScript operator names), not code
5. **0x73bd4** is `definefont` operator (not mentioned in prior analysis)
6. **0x73c2c** is `currentfont` operator (not mentioned)
7. **0x73c5e** is `findfont` operator (not mentioned)
8. **0x73cee** is `fontdirectory` helper function (not mentioned)
9. **0x73d2c** is `makefont` operator (not mentioned)
10. **0x73ea4** is `scalefont` operator (not mentioned)
11. **0x74050** is `selectfont` operator (not mentioned)
12. **0x74096** is `findfont` wrapper (not mentioned)
13. **0x740c6** is `currentfont` wrapper (not mentioned)
14. **0x741f6** is `nametostring` operator (not mentioned)

## **DETAILED FUNCTION ANALYSIS:**

### **1. Function at 0x73800: `ps_and_operator`**
**Entry:** 0x73800  
**Purpose:** PostScript `and` operator. Performs bitwise AND on integers or logical AND on booleans.  
**Arguments:** Two objects on stack (types determined at runtime)  
**Algorithm:** Gets operand types via 0x165f8, checks if both are type 1 (integer) or type 4 (boolean). For integers: uses `andl` instruction. For booleans: returns true only if both are true.  
**Callers:** PostScript operator dispatch table  
**Called:** 0x165f8 (get operand), 0x1b94a (type check), 0x1b626 (get integer), 0x1bb98 (store integer), 0x1bc78 (store boolean), 0x263d6 (type error)

### **2. Function at 0x73860: `ps_or_operator`**
**Entry:** 0x73860  
**Purpose:** PostScript `or` operator. Bitwise OR for integers, logical OR for booleans.  
**Arguments:** Two objects on stack  
**Algorithm:** Similar to `and` but with OR logic. For booleans: returns true if either operand is true.  
**Callers:** PostScript operator dispatch table  
**Called:** Same functions as `and_operator`

### **3. Function at 0x738c8: `ps_xor_operator`**
**Entry:** 0x738c8  
**Purpose:** PostScript `xor` operator. Bitwise XOR for integers, logical XOR for booleans.  
**Arguments:** Two objects on stack  
**Algorithm:** For booleans, uses `sne` (set if not equal) to implement XOR (true if operands differ).  
**Callers:** PostScript operator dispatch table  
**Called:** Same pattern as AND/OR operators

### **4. Function at 0x7392c: `ps_shift_operator`**
**Entry:** 0x7392c  
**Purpose:** PostScript `shift` operator. Shifts integer left or right based on shift count sign.  
**Arguments:** Two integers: shift count and value to shift  
**Algorithm:** Gets both integers via 0x1b626. Negative shift = right shift (`lsrl`), positive = left shift (`lsll`).  
**Callers:** PostScript operator dispatch table  
**Called:** 0x1b626 (get integer), 0x1bb98 (store integer)

### **5. Function at 0x73970: `ps_rand_operator_init`**
**Entry:** 0x73970  
**Purpose:** Initializes random number generator operator in PostScript system.  
**Arguments:** None  
**Algorithm:** Pushes its own address (0x73970) and value 8, calls 0x2df80 (operator registration).  
**Callers:** PostScript initialization  
**Called:** 0x2df80 (operator registration), 0x2642a (error check)

### **6. Function at 0x7398e: `ps_srand_operator`**
**Entry:** 0x7398e  
**Purpose:** PostScript `srand` operator - sets random seed.  
**Arguments:** One integer (seed)  
**Algorithm:** Gets integer via 0x1b626, stores at 0x20167ac (random seed variable).  
**Hardware:** Writes to 0x20167ac  
**Callers:** PostScript operator dispatch table  
**Called:** 0x1b626 (get integer)

### **7. Function at 0x739a2: `ps_rand_get_operator`**
**Entry:** 0x739a2  
**Purpose:** PostScript `rand` operator - gets current random seed.  
**Arguments:** None  
**Algorithm:** Reads from 0x20167ac, pushes onto stack.  
**Hardware:** Reads from 0x20167ac  
**Callers:** PostScript operator dispatch table  
**Called:** 0x1bb98 (store integer)

### **8. Function at 0x739b8: `ps_rand_next_operator`**
**Entry:** 0x739b8  
**Purpose:** PostScript `rrand` operator - generates next random number.  
**Arguments:** None  
**Algorithm:** Uses LCG: seed = (seed × 1103515245 + 907633129) & 0x7FFFFFFF, returns new seed.  
**Hardware:** Reads/writes 0x20167ac  
**Callers:** PostScript operator dispatch table  
**Called:** 0x1bb98 (store integer)

### **9. Function at 0x739f0: `ps_rand_operator`**
**Entry:** 0x739f0  
**Purpose:** Main rand operator handler - dispatches based on argument count.  
**Arguments:** Count in D0 (0=srand, 1=rand, 2=rrand)  
**Algorithm:** If count=0: sets seed to 1. If count=1: registers operator. If count=2: calls rrand.  
**Callers:** PostScript operator dispatch  
**Called:** 0x269fa (error), 0x2df80 (operator registration), 0x739b8 (rrand)

### **10. Data Table at 0x73a2c-0x73b30**
**Address:** 0x73a2c  
**Size:** 260 bytes (65 entries × 4 bytes)  
**Format:** Array of 4-byte entries: [operator address][operator type]  
**Content:** Operator dispatch table for font-related operators

### **11. String Table at 0x73b3c-0x73bc0**
**Address:** 0x73b3c  
**Size:** 132 bytes  
**Format:** Null-terminated ASCII strings  
**Content:** PostScript operator names: "add", "sub", "mul", "div", "idiv", "mod", "abs", "round", "floor", "ceiling", "truncate", "eq", "ne", "gt", "ge", "lt", "le", "and", "or", "xor", "bitshift", "rand", "srand", "rrand"

### **12. Function at 0x73bd4: `definefont`**
**Entry:** 0x73bd4  
**Purpose:** PostScript `definefont` operator - defines a font in the font dictionary.  
**Arguments:** Font name and font object on stack  
**Algorithm:** Copies font object to font dictionary, sets font attributes including color space from 0x20008f8.  
**Callers:** PostScript operator dispatch table  
**Called:** None directly (called via operator dispatch)

### **13. Function at 0x73c2c: `currentfont`**
**Entry:** 0x73c2c  
**Purpose:** PostScript `currentfont` operator - gets current font.  
**Arguments:** None  
**Algorithm:** Calls definefont with current font context, returns font object at 0x20167b0.  
**Callers:** PostScript operator dispatch table  
**Called:** 0x73bd4 (definefont)

### **14. Function at 0x73c5e: `findfont`**
**Entry:** 0x73c5e  
**Purpose:** PostScript `findfont` operator - looks up font in dictionary.  
**Arguments:** Font name on stack  
**Algorithm:** Hashes font name, searches font dictionary (0x2017354), returns font object or error.  
**Callers:** PostScript operator dispatch table  
**Called:** 0x26334 (error)

### **15. Function at 0x73cee: `fontdirectory_helper`**
**Entry:** 0x73cee  
**Purpose:** Helper for font directory operations - counts entries in hash bucket.  
**Arguments:** Hash bucket index in D0  
**Algorithm:** Traverses linked list at hash bucket, counts entries.  
**Callers:** 0x73d2c (makefont)  
**Called:** None

### **16. Function at 0x73d2c: `makefont`**
**Entry:** 0x73d2c  
**Purpose:** PostScript `makefont` operator - creates scaled font.  
**Arguments:** Font object and scale matrix on stack  
**Algorithm:** Creates new font object with scaled metrics, inserts into font dictionary.  
**Callers:** PostScript operator dispatch table  
**Called:** 0x1a7a6 (allocate), 0x27fb6 (matrix operations), 0x26eb2 (font scaling), 0x27e88 (font creation), 0x73cee (fontdirectory_helper), 0x27384 (dictionary insert), 0x270ae (list append)

### **17. Function at 0x73ea4: `scalefont`**
**Entry:** 0x73ea4  
**Purpose:** PostScript `scalefont` operator - scales font by factor.  
**Arguments:** Font object and scale factor on stack  
**Algorithm:** Hashes font name, searches font dictionary, creates scaled version.  
**Callers:** PostScript operator dispatch table  
**Called:** 0x13d2c (makefont)

### **18. Function at 0x74050: `selectfont`**
**Entry:** 0x74050  
**Purpose:** PostScript `selectfont` operator - sets current font.  
**Arguments:** Font name on stack  
**Algorithm:** Sets current font at 0x20167b8/0x20167bc, calls scalefont.  
**Hardware:** Writes to 0x20167b8/0x20167bc  
**Callers:** PostScript operator dispatch table  
**Called:** 0x124ac (font selection), 0x13ea4 (scalefont)

### **19. Function at 0x74096: `findfont_wrapper`**
**Entry:** 0x74096  
**Purpose:** Wrapper for findfont with name lookup.  
**Arguments:** Font name string  
**Algorithm:** Converts name to string, calls findfont via 0x2dcd4.  
**Callers:** 0x740c6 (currentfont_wrapper)  
**Called:** 0x2dcd4 (name lookup), 0x13ea4 (scalefont)

### **20. Function at 0x740c6: `currentfont_wrapper`**
**Entry:** 0x740c6  
**Purpose:** Wrapper for currentfont operation.  
**Arguments:** Font context  
**Algorithm:** Calls findfont_wrapper, stores result at 0x20167c0.  
**Hardware:** Writes to 0x20167c0  
**Callers:** PostScript operator dispatch  
**Called:** 0x74096 (findfont_wrapper)

### **21. Function at 0x740ee: `nametostring_operator`**
**Entry:** 0x740ee  
**Purpose:** PostScript `nametostring` operator - converts name to string.  
**Arguments:** Name object on stack  
**Algorithm:** Simple wrapper (appears to be stub/placeholder).  
**Callers:** PostScript operator dispatch table

### **22. Function at 0x740f6: `object_to_string_converter`**
**Entry:** 0x740f6  
**Purpose:** Converts PostScript objects to string representation.  
**Arguments:** Object type in D0, object pointer in A0, output buffer in A1  
**Algorithm:** Large switch statement (13 cases) handling different object types.  
**Callers:** PostScript string conversion routines  
**Called:** 0x89980 (floating point comparison)

## **KEY INSIGHTS:**
1. This region contains core PostScript operators for bitwise operations, random numbers, and font management.
2. The font system uses a hash table at 0x2017354 with 512 buckets and linear probing.
3. Random number generator uses standard LCG with multiplier 1103515245 and increment 907633129.
4. Font objects are 32-byte structures with fields for name, metrics, and scaling information.
5. The `nametostring` operator appears to be a stub, suggesting incomplete implementation or hardware acceleration.

## **MEMORY REFERENCES:**
- **0x20167ac**: Random seed storage
- **0x20167b0**: Current font pointer
- **0x20167b8/0x20167bc**: Font selection context
- **0x20167c0**: Font wrapper storage
- **0x2017354**: Font dictionary hash table
- **0x20008f8**: Current color space (used in font definitions)

## **CALL TARGETS OUTSIDE THIS REGION:**
- **0x165f8**: Get operand type
- **0x1b626**: Get integer from object
- **0x1bb98**: Store integer to object
- **0x1bc78**: Store boolean to object
- **0x1b94a**: Type checking
- **0x263d6**: Type error
- **0x2642a**: Error checking
- **0x269fa**: Error reporting
- **0x2df80**: Operator registration
- **0x27fb6**: Matrix operations
- **0x26eb2**: Font scaling
- **0x27e88**: Font creation
- **0x27384**: Dictionary insert
- **0x270ae**: List append

; === CHUNK 28: 0x74400-0x75000 ===

Looking at this disassembly from 0x74400 to 0x75000, I can see several functions related to PostScript number parsing, font descriptor building, and character classification. Let me analyze them systematically:

## FUNCTION ANALYSIS

### 1. Function at 0x74400
**Entry:** 0x74400  
**Name:** `encode_font_char`  
**Description:** Encodes a character code into a compact format for font representation. Takes character code and flags, produces 1-9 byte encoding. For small codes (<1024) with certain flag patterns, uses 2-byte encoding; otherwise uses 9-byte full encoding.  
**Arguments:** fp@(8)=flags/type (long), fp@(10)=char code (word), fp@(16)=output buffer pointer  
**Returns:** D0 = encoded size in bytes (2, 3, or 9)  
**Algorithm:** Checks flag bits 0-3 against template at 0x87ca0. If matches and char < 1024, uses 2-byte encoding: first byte = (char>>8)+130, second byte = low byte. Otherwise uses 9-byte encoding with full structure.  
**Hardware:** None directly  
**Cross-refs:** Called from font rendering code

### 2. Function at 0x744b0
**Entry:** 0x744b0  
**Name:** `parse_font_dict_entry`  
**Description:** Parses a single font dictionary entry from Type 1/PostScript font data. Uses jump table based on character class from table at 0x148ac.  
**Arguments:** a5=font dict pointer, a4=output structure, fp@(8)=?, fp@(9)=?  
**Returns:** Updates a5 dict pointer and count  
**Algorithm:** Reads byte from dict, looks up in character class table (0x148ac), dispatches via jump table at 0x144ec. Handles various font operator types: /FontName, /FontMatrix, /Encoding, /CharStrings, etc.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x13c5e (process font matrix?), 0x267b2 (process encoding?), 0x26334 (error handler)

### 3. Function at 0x74694
**Entry:** 0x74694  
**Name:** `build_font_descriptor`  
**Description:** Builds a font descriptor structure from parsed font dictionary entries. Creates linked list of font descriptors.  
**Arguments:** fp@(12)=output descriptor pointer, fp@(10)=count  
**Returns:** Filled descriptor structure  
**Algorithm:** Allocates descriptor template from 0x87cc0, iterates through font dict entries (linked list at 0x20173e8), processes each via 0x740f8 and 0x2814c.  
**Hardware:** Reads 0x20008f8 (system flags), 0x20173e8 (font dict list), 0x2022270 (?)  
**Cross-refs:** Calls 0x165f8 (get operand), 0x740f8 (process dict entry), 0x2814c (add to descriptor)

### 4. Function at 0x7474e
**Entry:** 0x7474e  
**Name:** `process_encoded_chars` or `font_char_encoder`  
**Description:** Processes character codes for font encoding, handling different object types (int, real, name).  
**Arguments:** fp@(8)=input buffer, fp@(10)=count, fp@(12)=output buffer  
**Returns:** Updates output buffer with encoded characters  
**Algorithm:** While count > 0, reads next object via 0x144b0, checks if it's an encoded char (high bit set). If type 3 (integer), encodes small ints specially. If type 9 (name), processes name object. If type 13 (operator), recursively processes.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x144b0 (get next object), 0x10100 (process integer?), 0x10fb6 (process name), 0x740f8 (encode object)

### 5. Function at 0x7484a
**Entry:** 0x7484a  
**Name:** `cvi_operator` (PostScript `cvi` - convert to integer)  
**Description:** PostScript operator implementation: converts object to integer.  
**Arguments:** None (operands on PS stack)  
**Returns:** Integer result on PS stack  
**Algorithm:** Gets operand via 0x1b564, checks if -1 (error), calls 0x14694 to convert, pushes result via 0x165aa.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x1b564 (get operand), 0x26382 (rangecheck error), 0x14694 (convert), 0x165aa (push result)

### 6. Function at 0x74888
**Entry:** 0x74888  
**Name:** `setpacking_operator` (PostScript `setpacking`)  
**Description:** Sets array packing mode (0=default, 1=packedarray).  
**Arguments:** fp@(8)=mode (0 or 1)  
**Returns:** None  
**Algorithm:** Checks if mode is 0 or 1, if 1 calls error handler with "packedarray" string at 0x149b8.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x26948 (error handler)

### 7. Function at 0x749c4
**Entry:** 0x749c4  
**Name:** `init_character_class_table`  
**Description:** Initializes character classification table at 0x20167c8 (256 bytes).  
**Arguments:** None  
**Returns:** None  
**Algorithm:** Sets default class 0x15 (21) for all chars, then sets specific classes for digits (0x0F=15), hex letters A-F/a-f (0x14=20), and special characters like parentheses, brackets, etc.  
**Hardware:** Writes to 0x20167c8-0x2016845  
**Cross-refs:** None

### 8. Function at 0x74ae8
**Entry:** 0x74ae8  
**Name:** `init_operator_tables`  
**Description:** Initializes operator dispatch tables for PostScript interpreter.  
**Arguments:** None  
**Returns:** None  
**Algorithm:** Sets up 16 pairs of operator table pointers at 0x2016914-0x20169d4, each pointing to functions around 0x76148-0x76342.  
**Hardware:** Writes to 0x2016914-0x20169d4  
**Cross-refs:** None

### 9. Function at 0x74c44
**Entry:** 0x74c44  
**Name:** `parse_real_number`  
**Description:** Parses a real number string into PostScript real object.  
**Arguments:** fp@(8)=input string pointer, fp@(12)=output object pointer  
**Returns:** Filled real object  
**Algorithm:** Clears error flag at 0x202226c, calls 0x2aca4 (string to double conversion), checks for errors, creates real object with template from 0x87c68, stores double value.  
**Hardware:** Reads/writes 0x202226c (error flag)  
**Cross-refs:** Calls 0x2aca4 (strtod), 0x2642a (error handler), 0x899c8 (store double)

### 10. Function at 0x74ca8
**Entry:** 0x74ca8  
**Name:** `parse_integer_string`  
**Description:** Parses integer string (decimal or with sign) into PostScript integer object.  
**Arguments:** fp@(8)=input string pointer, fp@(12)=length, fp@(16)=output object pointer  
**Returns:** Filled integer object  
**Algorithm:** Handles optional +/- sign, validates digits, checks for overflow (max 2147483647). For valid small integers, creates integer object. For large numbers, uses floating point conversion via 0x899f8 (ascii to double).  
**Hardware:** None directly  
**Cross-refs:** Calls 0x899f8 (ascii to double), 0x89a88 (multiply), 0x89a58 (add), 0x89920 (store double), 0x899c8 (convert double to single)

### 11. Function at 0x74e0a
**Entry:** 0x74e0a  
**Name:** `parse_radix_number`  
**Description:** Parses number with specified radix (base 2-36).  
**Arguments:** fp@(8)=input string pointer, fp@(12)=length, fp@(16)=radix, fp@(20)=output object pointer  
**Returns:** Filled integer object  
**Algorithm:** Validates digits for given radix (0-9, a-z, A-Z), accumulates value checking for overflow. Uses 32-bit integer arithmetic with overflow detection.  
**Hardware:** None directly  
**Cross-refs:** None

### 12. Function at 0x74eae
**Entry:** 0x74eae  
**Name:** `parse_number_with_radix`  
**Description:** Parses number that may include radix prefix (#digits or #digitsR).  
**Arguments:** fp@(8)=input string pointer, fp@(12)=length, fp@(16)=output object pointer  
**Returns:** Filled number object (integer or real)  
**Algorithm:** Checks for '#' prefix, optional radix digit(s), 'R' separator. If no radix, parses as decimal. Otherwise extracts radix (2-36) and parses digits accordingly.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x14e0a (parse_radix_number), 0x13ea4 (parse_real_number), 0x14ca8 (parse_integer_string)

### 13. Function at 0x74fac
**Entry:** 0x74fac  
**Name:** `cvr_operator` (PostScript `cvr` - convert to real)  
**Description:** Converts object to real number.  
**Arguments:** fp@(8)=input object pointer?, fp@(10)=radix?, fp@(12)=string pointer?, fp@(16)=output object pointer?  
**Returns:** Real object  
**Algorithm:** Validates radix ≤ 35, calls 0x14eae to parse number with radix.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x26382 (rangecheck error), 0x14eae (parse_number_with_radix)

### 14. Function at 0x74fda
**Entry:** 0x74fda  
**Name:** `cvrs_operator` (PostScript `cvrs` - convert with radix to string)  
**Description:** Converts number to string with specified radix.  
**Arguments:** Similar to cvr  
**Returns:** String object  
**Algorithm:** Validates radix ≤ 35, calls 0x14ca8 to parse integer string.  
**Hardware:** None directly  
**Cross-refs:** Calls 0x26382 (rangecheck error), 0x14ca8 (parse_integer_string)

## DATA REGIONS

### 1. Character class table at 0x148ac (0x148ac-0x149ab)
**Size:** 256 bytes  
**Format:** Byte array mapping ASCII values to character classes  
**Purpose:** Used by font dictionary parser to classify font operator bytes

### 2. Jump table at 0x144ec (0x144ec-0x14505)
**Size:** 20 bytes (10 word entries)  
**Format:** Word offsets for dispatch  
**Purpose:** Jump table for font dictionary entry parser

### 3. Float constants at 0x149aa-0x149b5
**Format:** IEEE 754 single precision floats
- 0x149aa: -1.0 (0xbf800000)
- 0x149ae: 0.0 (0x00000000)  
- 0x149b2: 1.0 (0x3f800000)

### 4. String at 0x149b6-0x149c3
**Content:** "packedarray" (PostScript error message)

## CORRECTIONS TO PRIOR ANALYSIS

1. The prior analysis incorrectly identified 0x74888 as `setpacking_operator` - it's actually checking for packedarray mode (not supported).

2. Added missing functions: 0x749c4 (init_character_class_table), 0x74ae8 (init_operator_tables), 0x74c44 (parse_real_number), 0x74ca8 (parse_integer_string), 0x74e0a (parse_radix_number), 0x74eae (parse_number_with_radix), 0x74fac (cvr_operator), 0x74fda (cvrs_operator).

3. Corrected that 0x7474e processes encoded characters for font output, not just font encoding.

4. The data regions were previously missed: character class table, jump table, float constants, and string.

## KEY INSIGHTS

This region contains core PostScript number parsing and font processing:
- Integer/real/radix number parsing with overflow detection
- Font character encoding optimization (2-byte vs 9-byte)
- Font dictionary parsing with character class-based dispatch
- Character classification table initialization
- Operator table setup for interpreter
- PostScript conversion operators (cvi, cvr, cvrs, setpacking)

The number parsing is sophisticated with both integer and floating point paths, radix support (2-36), and proper error handling. The font processing shows optimization for common cases (small character codes).

; === CHUNK 29: 0x75000-0x75C00 ===

Looking at this disassembly, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addresses are wrong**: The prior analysis uses addresses like 0x15000, but the actual addresses in this disassembly are 0x75000-0x75C00. The offset is 0x60000 (bank 3).

2. **Function boundaries are incorrect**: The prior analysis missed some functions and misidentified others.

3. **Data tables misidentified as code**: The prior analysis didn't properly identify the jump tables and data tables.

## REFINED ANALYSIS:

### 1. `copy_string_to_buffer` (0x75000)
**Entry:** 0x75000  
**Purpose:** Copies a string of specified length to a fixed buffer at 0x020169D8, null-terminates it, then calls another function (0x14C44) with the buffer and an argument. Includes bounds checking (max 35 chars).  
**Arguments:** String length (word at fp+10), source pointer (long at fp+12), additional argument (long at fp+16)  
**Return:** None (void)  
**RAM accessed:** 0x020169D8 (buffer)  
**Call targets:** 0x14C44, 0x26382 (error handler if length > 35)  
**Callers:** Unknown from this range

### 2. `process_token_or_string` (0x75052)
**Entry:** 0x75052  
**Purpose:** Processes a token or string from a data structure. Gets a value from 0x020173E8, calls 0x169EA to convert it, then processes through 0x27FFE and 0xFAA4. Checks if the result type is 0x0A (likely a name token).  
**Arguments:** Pointer to data structure (long at fp+8)  
**Return:** None (void)  
**RAM accessed:** 0x020173E8  
**Call targets:** 0x169EA, 0x27FFE, 0xFAA4, 0x165F8, 0x26334 (error)  
**Callers:** Called from within the large state machine at 0x75824

### 3. `scanner_state_machine` (0x750B2) - MAIN SCANNER FUNCTION
**Entry:** 0x750B2  
**Purpose:** PostScript scanner/lexer with complex state machine. Reads characters from input stream, classifies them, handles numeric parsing, escape sequences, and token generation. Uses multiple lookup tables: character classification (0x020167C8), state transitions (0x020168D8), and state actions (0x02016958). Manages input buffers and output token buffers.  
**Arguments:** Context pointer (long at fp+8), type/state (word at fp+10), additional pointer (long at fp+12)  
**Return:** Status in D0 (0=success, 2=error, etc.)  
**RAM accessed:** 0x02017468, 0x02017428 (lookup tables), 0x02016A00 (token buffer), 0x020169FC, 0x02022270/74 (buffer pointers)  
**Key features:** 
- Handles character classes: whitespace (0), digit (1), letter (2), delimiter (3), etc.
- State machine with states 0-15 (0x0F)
- Numeric parsing with accumulation
- Escape sequence handling (hex digits)
- Token buffer management
**Call targets:** 0x1862C, 0x1863A, 0x2818E, 0x14CA8, 0x14EAE, 0x14C44, 0x13EA4, 0x10138, 0x165AA, 0x2640E, 0x26334 (error)
**Callers:** Likely called by PostScript interpreter's read/scan routine

### 4. `string_scanner` (0x7587E)
**Entry:** 0x7587E  
**Purpose:** Similar scanner for processing strings (as opposed to general input). Uses buffers at 0x02016A04/08. Handles different token types and maintains scanner state.  
**Arguments:** String length (word at fp+10), string pointer (long at fp+12), context pointer (long at fp+16)  
**Return:** Status in D0  
**RAM accessed:** 0x02016A04/06/08 (string buffers), 0x02022270/74  
**Call targets:** 0x165AA, 0x14FDA, 0x14FAC, 0x15008, 0x14050, 0x10138, 0x27FB6, 0x169EA, 0x14694, 0x165F8, 0x15052, 0x26334  
**Callers:** Likely called for string literals in PostScript

### 5. `read_and_classify_chars` (0x75B02) - NOT 0x75D40 as previously stated
**Entry:** 0x75B02  
**Purpose:** Reads characters from a string buffer, classifies them using lookup table at 0x020167C8, maintains scanner state. This is actually embedded within the string_scanner function, not a separate function.  
**Arguments:** String length (word at fp+10), string pointer (long at fp+12) - accessed via D7 counter  
**Return:** Character class in D5  
**RAM accessed:** 0x020167C8 (character classification table)  
**Call targets:** None (embedded function)  
**Callers:** Called from within string_scanner at 0x75B02

## DATA TABLES IDENTIFIED:

1. **Character classification table** at 0x020167C8 (256 bytes mapping ASCII to character classes)
2. **State transition table** at 0x020168D8 (16 entries × 4 bytes each = 64 bytes)
3. **State action table** at 0x02016958 (16 entries × 4 bytes each = 64 bytes)
4. **Hex digit conversion table** at 0x7A47C (referenced at 0x75492 and 0x75524)
5. **Jump tables** embedded in code:
   - At 0x751D2: 8-word jump table for character class dispatch (0-7)
   - At 0x75206: 16-word jump table for digit processing (0-15)
   - At 0x7547E: 8-word jump table for state machine actions
   - At 0x755EE: 14-word jump table for scanner result processing

## KEY ALGORITHMIC DETAILS:

### Scanner State Machine (0x750B2):
- Uses D5 as state variable (0-15)
- Uses D6 as current character
- Uses D4 as character class (0-7)
- Maintains token buffer at 0x020169FC-0x02016A00
- Handles numeric accumulation in fp@(-16) with digit count in fp@(-8)
- Special handling for escape sequences (hex digits)
- Buffer management with A2/A3 pointers and buffer overflow checking

### String Scanner (0x7587E):
- Similar state machine but for pre-existing strings
- Uses buffers at 0x02016A04/08 instead of input stream
- Maintains position counter in D7
- Returns status codes in D0

## CORRECTIONS TO PRIOR ERRORS:

1. The prior analysis incorrectly identified 0x75B02 as a separate function called `read_and_classify_chars`. It's actually embedded within `string_scanner`.
2. The addresses in the prior analysis were off by 0x60000 (bank 3 vs bank 0).
3. The function at 0x75052 was misnamed; it's actually processing tokens from a specific data structure.
4. The state machine tables were not properly identified in the prior analysis.

## ADDITIONAL FUNCTIONS MISSED IN PRIOR ANALYSIS:

None - the prior analysis covered all the functions in this range, though with incorrect details.

## RESOLVED CONTRADICTIONS:

The main contradiction was the address offset issue. All functions are in bank 3 (0x60000-0x7FFFF), not bank 0. The corrected addresses are:
- 0x75000 (not 0x15000)
- 0x75052 (not 0x15052)
- 0x750B2 (not 0x150B2)
- 0x7587E (not 0x1587E)
- 0x75B02 (not 0x15B02)

The functions themselves are correctly identified, just with wrong addresses in the prior analysis.

; === CHUNK 30: 0x75C00-0x76800 ===

Looking at the raw disassembly from 0x75C00 to 0x76800, I can see that the prior analysis had several significant errors. Let me provide a corrected and refined analysis:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **The prior analysis incorrectly identified function boundaries** - The code at 0x75C00 is actually a CONTINUATION of a larger function, not the start of `copy_string_to_buffer`. The actual function at 0x75C00 is part of a larger state machine function.

2. **Address references were wrong** - Many addresses in the prior analysis were off by 0x10000 due to incorrect base address calculation.

3. **Data vs Code confusion** - The region from 0x76148 to 0x76462 contains DATA TABLES, not code.

## REFINED ANALYSIS:

### 1. Continuation of State Machine Function (0x75C00-0x75D3E)
**Entry:** 0x75C00 (continuation, not start)  
**Purpose:** This is the tail end of a large string/lexer state machine function (likely continues from 0x750B2). It handles:
- Character classification using lookup table at 0x7A47C (ASCII to hex nibble conversion)
- Buffer management for token accumulation
- State transitions based on character types
- Calls to 0x1A870 (likely `process_token` or similar)
**Key operations:** Hex digit conversion (0x75C42-0x75C8E), error handling via 0x26334, jump table dispatch at 0x75CDC
**Arguments:** Continuation from previous function - uses D6 for state, D7 for character count
**Return:** D0 = result value from state machine
**RAM accessed:** 0x2022270 (buffer structure), 0x2022274
**Call targets:** 0x2818E, 0x1A870, 0x26334
**Called by:** Unknown (part of larger lexer/parser)

### 2. `read_and_classify_chars` (0x75D40-0x75EE0) - CORRECT
**Entry:** 0x75D40  
**Purpose:** Reads characters from an input stream with lookahead/putback capability. Uses character classification table at 0x020167C8, state transition tables at 0x02016958 and 0x020168D8. Handles bracket nesting counting (parentheses, braces). Implements a finite state machine for token scanning.
**Arguments:** Input stream pointer at fp+8 (likely a `FILE*` or stream struct)
**Return:** D0 = boolean (1=success/continue, 0=end/error)
**RAM accessed:** 0x020167C8 (char class), 0x02016958, 0x020168D8 (state tables)
**Call targets:** Stream read function via function pointer at offset 14, putback at offset 16
**Called by:** Lexer/tokenizer functions

### 3. `get_token_buffer` (0x75EE2-0x75F5E) - CORRECT
**Entry:** 0x75EE2  
**Purpose:** Retrieves a token buffer based on type. Handles two buffer types:
- Type 5: Uses buffer at 0x02016A04-0x02016A08 (current token buffer)
- Type 6: Uses buffers at 0x02016A00 and 0x020169FC (accumulated token data)
**Arguments:** Type (word at fp+10), destination pointer (long at fp+12)
**Return:** D0 = boolean (1=success, 0=failure)
**RAM accessed:** 0x02016A00, 0x020169FC, 0x02022270, 0x02016A06
**Call targets:** 0x27FB6 (copy function), 0x26334 (error)
**Called by:** Token processing functions

### 4. `dispatch_string_operation` (0x75F60-0x7602C) - CORRECT
**Entry:** 0x75F60  
**Purpose:** Dispatches string/token operations based on object type. Pops an object from stack (via 0x165F8), examines low nibble of type byte, and calls appropriate handler:
- Type 5 (string): calls 0x1587E
- Type 6 (name/token): calls 0x150B2
**Arguments:** None (operates on execution stack)
**Return:** D0 = status (0=success?)
**RAM accessed:** Calls 0x165F8 (pop), 0x1587E, 0x150B2, 0x165AA (push), 0x184FA, 0x1BC78
**Called by:** PostScript operator implementations

### 5. `push_default_string` (0x7602E-0x76058) - CORRECT
**Entry:** 0x7602E  
**Purpose:** Pushes a default string value onto the execution stack. Loads a string from 0x87CD0 (likely "true", "false", or "null") and pushes it.
**Arguments:** None
**Return:** None
**RAM accessed:** 0x87CD0 (string constant), 0x020008F8 (global flag)
**Call targets:** 0x165AA (push_object)
**Called by:** PS operators needing default values

### 6. `push_empty_string` (0x7605A-0x76076) - CORRECT
**Entry:** 0x7605A  
**Purpose:** Creates and pushes an empty string object onto the execution stack. Calls 0x15052 to create an empty string, then pushes it.
**Arguments:** None
**Return:** None
**RAM accessed:** None directly
**Call targets:** 0x15052 (create_empty_string), 0x165AA (push_object)
**Called by:** PS operators needing empty strings

### 7. `push_boolean` (0x76078-0x760C2) - CORRECT
**Entry:** 0x76078  
**Purpose:** Pushes a boolean value onto the execution stack. Pops an object, checks if it's type 4 (boolean), then pushes it back with appropriate type.
**Arguments:** None (operates on execution stack)
**Return:** None
**RAM accessed:** 0x02017354 (dictionary hash table)
**Call targets:** 0x165F8 (pop), 0x263D6 (error), 0x27310 (push_boolean)
**Called by:** PS boolean operators

### 8. `push_system_dict` (0x760C4-0x760EE) - CORRECT
**Entry:** 0x760C4  
**Purpose:** Pushes the system dictionary onto the execution stack. Retrieves system dictionary from 0x02017354+0x3C/0x40 and pushes it.
**Arguments:** None
**Return:** None
**RAM accessed:** 0x02017354 (system dictionary pointer)
**Call targets:** 0x165AA (push_object)
**Called by:** PS operators accessing system dictionary

### 9. `initialize_token_tables` (0x760F0-0x76146) - CORRECT
**Entry:** 0x760F0  
**Purpose:** Initializes token/lexer tables based on mode. Three modes:
- Mode 0: Calls 0x749C4 and 0x14AE8
- Mode 1: Initializes tables at 0x020168C8 and 0x020168D0 with data from 0x16464/0x16466
- Mode 2: Does nothing (falls through)
**Arguments:** Mode (long at fp+8)
**Return:** None
**RAM accessed:** 0x020168C8, 0x020168D0
**Call targets:** 0x749C4, 0x14AE8, 0x14096, 0x269FA
**Called by:** PS initialization code

## DATA REGIONS (0x76148-0x76462):

### 10. Character Classification Tables (0x76148-0x76462)
**Address:** 0x76148  
**Size:** 0x31A bytes (794 bytes)  
**Format:** Multiple lookup tables for character classification and state transitions:
- 0x76148-0x7615A: Initial table (27 bytes)
- 0x7615C-0x7616D: Secondary table (18 bytes)
- 0x7616E-0x76462: Main state transition tables (756 bytes)
**Content:** These tables define how characters are classified (whitespace, digits, letters, operators) and how the lexer state machine transitions between states.

### 11. String Constants (0x76464-0x7648A)
**Address:** 0x76464  
**Size:** 0x26 bytes (38 bytes)  
**Format:** Null-terminated ASCII strings:
- 0x76464: "[]token" (7 bytes)
- 0x7646C: "[]escaping" (10 bytes)
- 0x76476: "currentpacking" (14 bytes)
- 0x76484: "N" (2 bytes, includes null)
**Purpose:** Error messages or mode names for the lexer/tokenizer.

## CONTINUED CODE FUNCTIONS:

### 12. `allocate_object_pool` (0x7648C-0x765A8)
**Entry:** 0x7648C  
**Purpose:** Allocates a pool of objects for a free list. Creates a header structure followed by multiple object slots.
**Arguments:** Pool size (word at fp+10)
**Return:** D0 = pointer to pool header
**RAM accessed:** None directly (uses malloc via 0x28344)
**Call targets:** 0x28344 (malloc), 0x87C58 (template object)
**Called by:** Free list management functions

### 13. `push_object` (0x765AA-0x765E6)
**Entry:** 0x765AA  
**Purpose:** Pushes an object onto a stack (likely the operand stack). Uses free list at 0x020173E8.
**Arguments:** Object pointer (long at fp+8)
**Return:** None
**RAM accessed:** 0x020173E8 (free list head)
**Call targets:** 0x164A8 (allocate more objects if needed)
**Called by:** Many PS operators

### 14. `push_object_direct` (0x765E8-0x765F6)
**Entry:** 0x765E8  
**Purpose:** Wrapper for push_object that takes object directly on stack.
**Arguments:** Object on stack
**Return:** None
**Call targets:** 0x165AA (push_object)
**Called by:** Direct object pushing

### 15. `pop_object` (0x765F8-0x76638)
**Entry:** 0x765F8  
**Purpose:** Pops an object from a stack (likely the operand stack). Uses free list at 0x020173E8.
**Arguments:** Destination pointer (long at fp+8)
**Return:** Object in destination
**RAM accessed:** 0x020173E8 (free list head)
**Call targets:** 0x7648C (allocate more objects if needed)
**Called by:** Many PS operators

### 16. `pop_object_to_global` (0x7663A-0x7665C)
**Entry:** 0x7663A  
**Purpose:** Pops an object and stores it in global location 0x02016A0C.
**Arguments:** None
**Return:** D0 = pointer to global location (0x02016A0C)
**RAM accessed:** 0x02016A0C
**Call targets:** 0x165F8 (pop_object)
**Called by:** Special operators

### 17. `push_exec_object` (0x7665E-0x7669A)
**Entry:** 0x7665E  
**Purpose:** Pushes an object onto the execution stack. Uses free list at 0x020174A4.
**Arguments:** Object pointer (long at fp+8)
**Return:** None
**RAM accessed:** 0x020174A4 (execution stack free list)
**Call targets:** 0x164A8 (allocate more objects if needed)
**Called by:** Procedure/execution operators

### 18. `push_exec_object_direct` (0x7669C-0x766AA)
**Entry:** 0x7669C  
**Purpose:** Wrapper for push_exec_object that takes object directly on stack.
**Arguments:** Object on stack
**Return:** None
**Call targets:** 0x1665E (push_exec_object)
**Called by:** Direct execution object pushing

### 19. `pop_exec_object` (0x766AC-0x766EC)
**Entry:** 0x766AC  
**Purpose:** Pops an object from the execution stack. Uses free list at 0x020174A4.
**Arguments:** Destination pointer (long at fp+8)
**Return:** Object in destination
**RAM accessed:** 0x020174A4 (execution stack free list)
**Call targets:** 0x7648C (allocate more objects if needed)
**Called by:** Procedure/execution operators

### 20. `push_dict_object` (0x766EE-0x7672A)
**Entry:** 0x766EE  
**Purpose:** Pushes an object onto the dictionary stack. Uses free list at 0x020174BC.
**Arguments:** Object pointer (long at fp+8)
**Return:** None
**RAM accessed:** 0x020174BC (dictionary stack free list)
**Call targets:** 0x164A8 (allocate more objects if needed)
**Called by:** Dictionary operators

### 21. `push_dict_object_direct` (0x7672C-0x7673A)
**Entry:** 0x7672C  
**Purpose:** Wrapper for push_dict_object that takes object directly on stack.
**Arguments:** Object on stack
**Return:** None
**Call targets:** 0x166EE (push_dict_object)
**Called by:** Direct dictionary object pushing

### 22. `pop_dict_object` (0x7673C-0x7677C)
**Entry:** 0x7673C  
**Purpose:** Pops an object from the dictionary stack. Uses free list at 0x020174BC.
**Arguments:** Destination pointer (long at fp+8)
**Return:** Object in destination
**RAM accessed:** 0x020174BC (dictionary stack free list)
**Call targets:** 0x7648C (allocate more objects if needed)
**Called by:** Dictionary operators

### 23. `peek_object` (0x7677E-0x767B4)
**Entry:** 0x7677E  
**Purpose:** Peeks at the top object on the operand stack without popping it.
**Arguments:** Destination pointer (long at fp+8)
**Return:** Object in destination
**RAM accessed:** 0x020173E8 (operand stack free list)
**Call targets:** 0x7648C (allocate more objects if needed)
**Called by:** Operators that need to inspect stack without modifying it

### 24. `peek_object_to_global` (0x767B6-0x767D8)
**Entry:** 0x767B6  
**Purpose:** Peeks at top object and stores it in global location 0x02016A14.
**Arguments:** None
**Return:** D0 = pointer to global location (0x02016A14)
**RAM accessed:** 0x02016A14
**Call targets:** 0x1677E (peek_object)
**Called by:** Special operators

### 25. `peek_dict_object` (0x767DA-0x76810)
**Entry:** 0x767DA  
**Purpose:** Peeks at the top object on the dictionary stack without popping it.
**Arguments:** Destination pointer (long at fp+8)
**Return:** Object in destination
**RAM accessed:** 0x020174BC (dictionary stack free list)
**Call targets:** 0x7648C (allocate more objects if needed)
**Called by:** Dictionary operators that need to inspect without modifying

## KEY INSIGHTS:

1. **Three separate stacks:** The system maintains three distinct stacks:
   - Operand stack (0x020173E8)
   - Execution stack (0x020174A4)
   - Dictionary stack (0x020174BC)

2. **Free list management:** Each stack has its own free list with allocation functions that automatically allocate more objects when empty.

3. **Character classification:** The lexer uses extensive lookup tables (0x76148+) for efficient character classification and state transitions.

4. **Object representation:** Objects are 12 bytes each (based on the allocation in `allocate_object_pool`).

5. **Error handling:** Consistent use of 0x26334 for errors throughout this region.

The prior analysis incorrectly identified the data tables as code and missed several important stack management functions. This refined analysis provides a more accurate picture of the PostScript interpreter's lexer and stack management subsystems.

; === CHUNK 31: 0x76800-0x77400 ===

Looking at the raw disassembly from 0x76800 to 0x77400, I can see the prior analysis was mostly correct but needs refinement and correction in several areas. Let me provide a corrected and enhanced analysis:

## CORRECTED AND ENHANCED ANALYSIS: 0x76800-0x77400

### 1. 0x76800-0x76810: `copy_node_data` (coroutine style)
- **Entry**: 0x76800
- **Purpose**: Copies 8 bytes from source node (A0) to destination node (A1). Copies the node pointer at offset 0 and data at offset 4. Uses A5 as continuation pointer.
- **Arguments**: A0=source node, A1=destination node
- **Returns**: None (JMPs to A5)
- **Style**: Coroutine (uses A5, JMP instead of RTS)
- **Note**: This is an inline helper for list operations, not a standalone function.

### 2. 0x76812-0x76848: `get_global_node_and_copy`
- **Entry**: 0x76812
- **Purpose**: Gets a list node from global pointer at 0x020174a4, copies its data to destination buffer. If pointer is NULL, calls allocator at 0x7648c.
- **Arguments**: fp@(8)=destination buffer
- **Returns**: Node data copied to destination
- **RAM access**: 0x020174a4 (global list pointer)
- **Calls**: 0x7648c (allocator)
- **Stack frame**: LINKW #-4, saves A5
- **Algorithm**: Check global pointer; if NULL, allocate; copy 8 bytes from node+4 to destination

### 3. 0x7684a-0x7687e: `list_traverse_count`
- **Entry**: 0x7684a  
- **Purpose**: Traverses linked list starting at head, counting nodes up to specified limit. Returns actual count traversed or limit if reached end.
- **Arguments**: fp@(8)=list head pointer, fp@(14)=count limit (word)
- **Returns**: D0=actual count traversed (word extended to long)
- **Algorithm**: While (node && count < limit): node = node->next, count++
- **Registers saved**: D6-D7, A5
- **Key**: Used for bounds checking in list operations

### 4. 0x76880-0x7690c: `list_extract_sublist`
- **Entry**: 0x76880
- **Purpose**: Extracts a sublist of specified length from a larger list. Validates forward and backward traversal counts, handles edge cases.
- **Arguments**: fp@(8)=list pointer, fp@(14)=sublist length (word)
- **Returns**: Modified list with sublist extracted
- **Calls**: 0x7684a (list_traverse_count), 0x7648c (allocator), 0x164a8 (error handler)
- **Complexity**: Validates both forward (from head) and backward (from tail) traversal
- **Registers saved**: D7, A2-A5
- **Algorithm**: Extract N nodes from list, update head/tail pointers

### 5. 0x7690e-0x7699e: `list_rotate_sublist`
- **Entry**: 0x7690e
- **Purpose**: Rotates elements within a list by specified offset. Uses modular arithmetic (DIVUW) to compute rotation offset modulo length.
- **Arguments**: fp@(8)=list pointer, fp@(14)=sublist length (word), fp@(18)=rotation offset (word)
- **Algorithm**: offset = offset % length; if offset != 0, find new head/tail and relink
- **Key operation**: DIVUW for modulo calculation
- **Calls**: 0x7648c (allocator) on error
- **Registers saved**: D7, A3-A5
- **Use case**: Circular buffer rotation or list reordering

### 6. 0x769a0-0x769c0: `list_count_to_index`
- **Entry**: 0x769a0
- **Purpose**: Counts elements in list up to given index, returns count (clamped to index).
- **Arguments**: fp@(8)=list pointer, fp@(14)=index (word)
- **Returns**: D0=actual count (word extended to long, masked to 0xFFFF)
- **Calls**: 0x7684a (list_traverse_count)
- **Note**: Essentially min(index, list_length)

### 7. 0x769c2-0x769e8: `list_reverse`
- **Entry**: 0x769c2
- **Purpose**: Reverses a linked list in-place using standard 3-pointer algorithm.
- **Arguments**: fp@(8)=list head pointer
- **Algorithm**: prev=NULL, curr=head; while curr: next=curr->next, curr->next=prev, prev=curr, curr=next
- **Registers saved**: A4-A5
- **Returns**: List reversed in place

### 8. 0x769ea-0x76a32: `count_special_nodes`
- **Entry**: 0x769ea
- **Purpose**: Counts list nodes where byte at offset 4 has low nibble = 0xA (10 decimal). On error (no such nodes), calls error handler.
- **Arguments**: fp@(8)=list pointer
- **Returns**: D0=count of special nodes
- **RAM access**: 0x20009a8/9ac (error handler addresses)
- **Calls**: 0x10f8c (error handler)
- **Algorithm**: Traverse list, check (node+4 & 0x0F) == 0x0A

### 9. 0x76a34-0x76ab2: `copy_list_to_array`
- **Entry**: 0x76a34
- **Purpose**: Copies elements from a linked list to an array structure. Validates count, handles bounds checking.
- **Arguments**: fp@(8)=array structure, fp@(12)=list pointer
- **Returns**: Updates array count field
- **Calls**: 0x1684a (list_traverse_count), 0x263ba (error handler), 0xf94a (copy function)
- **Algorithm**: Get list count, validate against array bounds, copy elements in reverse order
- **Key**: Uses array structure with count at offset 2

### 10. 0x76ab4-0x76ac4: `push_current_context`
- **Entry**: 0x76ab4
- **Purpose**: Pushes current execution context onto stack. Simple wrapper around 0x165f8.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x165f8 (context push function)

### 11. 0x76ac6-0x76b28: `swap_list_elements`
- **Entry**: 0x76ac6
- **Purpose**: Swaps two elements in a doubly-linked list managed at 0x020173e8.
- **Arguments**: None
- **Returns**: None
- **RAM access**: 0x020173e8 (list management structure)
- **Calls**: 0x1677e, 0x165aa (list manipulation functions)
- **Algorithm**: If list has at least 2 elements, swaps first and second elements

### 12. 0x76b2a-0x76b8a: `rotate_list_elements`
- **Entry**: 0x76b2a
- **Purpose**: Rotates elements in a list by moving first element to end.
- **Arguments**: None
- **Returns**: None
- **RAM access**: 0x020173e8 (list management structure)
- **Calls**: 0x165f8, 0x165aa (list manipulation functions)
- **Algorithm**: If list has elements, moves first element to end

### 13. 0x76b8c-0x76c06: `random_list_rotation`
- **Entry**: 0x76b8c
- **Purpose**: Performs random rotation on a list using PRNG. Calculates random offset modulo list length.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x1b626 (PRNG), 0x263ba (error handler), 0x1690e (list_rotate_sublist)
- **Algorithm**: Get two random numbers, calculate modulo, rotate list
- **Key**: Uses DIVSLL for signed division with 64-bit result

### 14. 0x76c08-0x76c1a: `reverse_current_list`
- **Entry**: 0x76c08
- **Purpose**: Reverses the list at 0x020173e8.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x169c2 (list_reverse)

### 15. 0x76c1c-0x76c44: `count_list_elements`
- **Entry**: 0x76c1c
- **Purpose**: Counts elements in list at 0x020173e8 and pushes count onto stack.
- **Arguments**: None
- **Returns**: Count pushed via 0x1bb24
- **Calls**: 0x169a0 (list_count_to_index), 0x1bb24 (push function)

### 16. 0x76c46-0x76c6e: `count_global_list_elements`
- **Entry**: 0x76c46
- **Purpose**: Counts elements in list at 0x020174bc and pushes count onto stack.
- **Arguments**: None
- **Returns**: Count pushed via 0x1bb24
- **Calls**: 0x169a0 (list_count_to_index), 0x1bb24 (push function)

### 17. 0x76c70-0x76c98: `count_another_list_elements`
- **Entry**: 0x76c70
- **Purpose**: Counts elements in list at 0x020174a4 and pushes count onto stack.
- **Arguments**: None
- **Returns**: Count pushed via 0x1bb24
- **Calls**: 0x169a0 (list_count_to_index), 0x1bb24 (push function)

### 18. 0x76c9a-0x76cbc: `count_special_nodes_in_current`
- **Entry**: 0x76c9a
- **Purpose**: Counts special nodes (low nibble = 0xA) in list at 0x020173e8 and pushes count.
- **Arguments**: None
- **Returns**: Count pushed via 0x1bb24
- **Calls**: 0x169ea (count_special_nodes), 0x1bb24 (push function)

### 19. 0x76cbe-0x76d02: `find_and_pop_special_node`
- **Entry**: 0x76cbe
- **Purpose**: Finds and pops a special node (low nibble = 0xA) from list at 0x020173e8.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x10f8c (error handler), 0x165f8, 0x165aa
- **Algorithm**: Checks list not empty, finds special node, pops it

### 20. 0x76d02-0x76d26: `push_execution_context`
- **Entry**: 0x76d02
- **Purpose**: Pushes execution context from fixed address 0x87cd0 with current mode.
- **Arguments**: None
- **Returns**: None
- **RAM access**: 0x20008f8 (current mode)
- **Calls**: 0x165aa (push function)
- **Note**: Copies 8-byte structure from ROM

### 21. 0x76d28-0x76d6a: `get_nth_element_and_push`
- **Entry**: 0x76d28
- **Purpose**: Gets Nth element from list at 0x020173e8 and pushes its data.
- **Arguments**: None
- **Returns**: Element data pushed via 0x165aa
- **Calls**: 0x1b564 (get index), 0x263ba (error handler), 0x165aa (push)
- **Algorithm**: Gets random index, traverses list to that position, pushes element

### 22. 0x76d6c-0x76d98: `push_from_global_list`
- **Entry**: 0x76d6c
- **Purpose**: Pushes element from global list at 0x020174a4.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x1ba8e (get element), 0x16a34 (copy_list_to_array), 0x165aa (push)

### 23. 0x76d9a-0x76dc6: `push_from_secondary_list`
- **Entry**: 0x76d9a
- **Purpose**: Pushes element from secondary list at 0x020174bc.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x1ba8e (get element), 0x16a34 (copy_list_to_array), 0x165aa (push)

### 24. 0x76dc8-0x76de6: `dispatch_table_handler`
- **Entry**: 0x76dc8
- **Purpose**: Dispatches to handler based on argument (0 or 1). Used for operator dispatch.
- **Arguments**: fp@(8)=dispatch index
- **Returns**: None
- **Calls**: 0x269fa (dispatch function)
- **Note**: Has embedded jump table at 0x76de8

### 25. DATA REGION: 0x76de8-0x76e64
- **Type**: Jump table for dispatch_table_handler
- **Size**: 60 bytes (15 entries × 4 bytes)
- **Format**: 32-bit addresses pointing to handler functions
- **Entries**: 0x76e64, 0x76ab4, 0x76e68, 0x76b2a, 0x76e6d, 0x76ac6, 0x76e71, 0x76c08, 0x76e77, 0x76b8c, 0x76e7c, 0x76c1c, 0x76e82, 0x76c46, 0x76e91, 0x76c9a, 0x76e9d, 0x76cbe, 0x76ea9, 0x76d02, 0x76eae, 0x76d28, 0x76eb4, 0x76d6c, 0x76ebe, 0x76d9a, 0x76ecd, 0x76c70

### 26. DATA REGION: 0x76e64-0x76ed6
- **Type**: String table for operator names
- **Size**: 114 bytes
- **Format**: Null-terminated strings
- **Strings**: "pop", "exch", "dup", "clear", "roll", "count", "countdictstack", "cleartomark", "mark", "index", "dictstack", "countexecstack", "execstack"

### 27. 0x76ed8-0x76eec: `check_execution_mode`
- **Entry**: 0x76ed8
- **Purpose**: Checks execution mode at 0x20008f8, calls 0x124ac if not zero.
- **Arguments**: None
- **Returns**: None
- **Calls**: 0x124ac (mode handler)

### 28. 0x76eee-0x76f44: `file_open_handler`
- **Entry**: 0x76eee
- **Purpose**: Handles file opening with path processing and error checking.
- **Arguments**: Complex (file path handling)
- **Returns**: File handle or error
- **Calls**: 0x1d9a2 (path processor), 0x251f6 (file open), 0x205f0 (error handler), 0x1bb98 (push results)
- **Algorithm**: Processes path, opens file, handles errors, pushes results

### 29. 0x76f46-0x76f76: `push_handler_to_array`
- **Entry**: 0x76f46
- **Purpose**: Pushes handler address to array at 0x02016a20 with bounds checking.
- **Arguments**: fp@(8)=handler address
- **Returns**: None
- **RAM access**: 0x02016a1c (count), 0x02016a20 (array)
- **Calls**: 0x26334 (error handler on overflow)

### 30. 0x76f78-0x76faa: `execute_handlers_array`
- **Entry**: 0x76f78
- **Purpose**: Executes all handlers in array at 0x02016a20.
- **Arguments**: fp@(8)=context parameter
- **Returns**: None
- **RAM access**: 0x02016a1c (count), 0x02016a20 (array)
- **Algorithm**: Iterates through array, calling each handler with parameter

### 31. 0x76fac-0x77060: `file_operation_dispatcher`
- **Entry**: 0x76fac
- **Purpose**: Main file operation dispatcher with context saving and error handling.
- **Arguments**: None (uses global state)
- **Returns**: None
- **Calls**: 0x76ed8, 0x1b564, 0x1b626, 0x263ba, 0x76f78, 0x25370, 0x10f8c, 0x2df1c, 0x2018a
- **Complex function**: Saves context, validates operations, dispatches file handling

### 32. 0x77062-0x770be: `skip_slash_prefix`
- **Entry**: 0x77062
- **Purpose**: Skips leading slashes in path, checks for "Sys/" prefix.
- **Arguments**: fp@(8)=path pointer
- **Returns**: Updated pointer
- **Algorithm**: Skip leading '/', check for "Sys/" prefix, call 0x76ed8 if found

### 33. 0x770c0-0x77128: `file_mode_detector`
- **Entry**: 0x770c0
- **Purpose**: Detects file mode from string ("w", "r+", etc.) and processes file opening.
- **Arguments**: fp@(8)=file struct, fp@(12)=path, fp@(16)=mode string
- **Returns**: File handle in fp@(-4)
- **Calls**: 0x17588 (path processor), 0x77062 (skip_slash_prefix), 0x1f86e (file open)
- **Algorithm**: Parse mode string, process path, open file

### 34. 0x7712a-0x77140: `get_file_position`
- **Entry**: 0x7712a
- **Purpose**: Gets current file position.
- **Arguments**: fp@(12)=file handle
- **Returns**: Position in D0
- **Calls**: 0x1da5e (file position function)

### 35. 0x77142-0x77186: `file_read_wrapper`
- **Entry**: 0x77142
- **Purpose**: Wrapper for file read operations with buffer management.
- **Arguments**: fp@(8)=buffer, fp@(16)=file structure
- **Returns**: Bytes read in D0
- **Calls**: 0x2dcb0 (buffer copy), file read callback
- **Algorithm**: Manages read buffer, calls file read function

### 36. 0x77188-0x771ec: `file_write_wrapper`
- **Entry**: 0x77188
- **Purpose**: Wrapper for file write operations with global context.
- **Arguments**: fp@(8)=data, fp@(12)=length
- **Returns**: Bytes written in D0
- **RAM access**: 0x02016a2c (global file context)
- **Calls**: 0x2dcb0 (buffer copy), file write callback
- **Algorithm**: Uses global file context for write operations

### 37. 0x771ee-0x77288: `formatted_output_handler`
- **Entry**: 0x771ee
- **Purpose**: Handles formatted output with printf-style formatting.
- **Arguments**: Multiple (format string, variables)
- **Returns**: None
- **RAM access**: 0x02016a2c (output context)
- **Calls**: 0x1db18 (formatted output function)
- **Algorithm**: Sets up output context, handles format specifiers

### 38. 0x7728a-0x772e0: `file_close_handler`
- **Entry**: 0x7728a
- **Purpose**: Closes file with context saving and error checking.
- **Arguments**: fp@(8)=file struct, fp@(12)=path, fp@(16)=handle
- **Returns**: Success/failure in fp@(-4)
- **Calls**: 0x2df1c (context check), 0x1de0a (file close), 0x263f2 (error handler)
- **Algorithm**: Saves context, validates, closes file

### 39. 0x772e2-0x7731c: `file_seek_handler`
- **Entry**: 0x772e2
- **Purpose**: Handles file seek operations with variable arguments.
- **Arguments**: fp@(12)=file handle, additional args
- **Returns**: Success/failure in D0
- **Calls**: 0x1da5e (file position), 0x1e6f0 (file seek)
- **Algorithm**: Gets current position, performs seek operation

### 40. 0x7731e-0x77362: `file_delete_handler`
- **Entry**: 0x7731e
- **Purpose**: Deletes file with context saving.
- **Arguments**: fp@(12)=path
- **Returns**: None
- **Calls**: 0x2df1c (context check), 0x1ddc4 (file delete), 0x263f2 (error handler)

### 41. 0x77364-0x773aa: `file_status_checker`
- **Entry**: 0x77364
- **Purpose**: Checks file status and populates status structure.
- **Arguments**: fp@(12)=status structure
- **Returns**: None
- **Calls**: 0x1d9a2 (path processor), 0x251f6 (file open), 0x205f0 (error handler)
- **Algorithm**: Opens file to check status, populates structure

### 42. 0x773ac-0x773b2: `null_handler_1`
- **Entry**: 0x773ac
- **Purpose**: Empty handler (just returns).
- **Arguments**: None
- **Returns**: None

### 43. 0x773b4-0x773bc: `null_handler_2`
- **Entry**: 0x773b4
- **Purpose**: Empty handler (returns 0).
- **Arguments**: None
- **Returns**: D0=0

### 44. 0x773be-0x77400: `initialize_file_object`
- **Entry**: 0x773be
- **Purpose**: Initializes a file object structure with default values.
- **Arguments**: None
- **Returns**: D0=pointer to initialized structure
- **Calls**: 0x17942 (allocator)
- **Algorithm**: Allocates structure, sets up fields including handler at 0x77514

## KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **0x76b8c-0x76c06**: Previously described as generic random function, but actually performs random list rotation using PRNG.

2. **0x76de8-0x76e64**: Previously missed - this is a jump table for dispatch_table_handler, not code.

3. **0x76e64-0x76ed6**: String table for PostScript operator names, not code.

4. **0x771ee-0x77288**: Formatted output handler, not generic file handler.

5. The region contains extensive file I/O operations beyond simple list manipulation.

## SUMMARY:
This region (0x76800-0x77400) contains:
- Linked list manipulation functions (extract, rotate, count, reverse)
- PostScript stack operator implementations (pop, exch, dup, clear, roll, etc.)
- File I/O operations (open, close, read, write, seek, delete)
- Formatted output handling
- Execution context management
- Error handling and validation

The functions use both coroutine style (bank 0/1) and standard C calling convention (banks 2-4), with extensive use of global variables in RAM for state management.

; === CHUNK 32: 0x77400-0x78000 ===

## CORRECTED AND ENHANCED ANALYSIS OF 0x77400-0x78000

### 1. 0x77400-0x7742E: `initialize_filesystem_object`
- **Entry**: 0x77400
- **Purpose**: Initializes a file system object structure by setting bit 3 (likely "initialized" flag) at offset 0, storing function pointers at offsets 14 (0x77540) and 18 (0x77544), then registering the filesystem by calling 0x17874.
- **Arguments**: A0 points to file system object structure (via fp@-4)
- **Returns**: None (void)
- **RAM access**: None directly
- **Calls**: 0x17874 (register_filesystem)
- **Called by**: Unknown (likely during system initialization)
- **Style**: Standard C with LINK/UNLK

### 2. 0x77430-0x77510: `disk_initialize_or_status`
- **Entry**: 0x77430
- **Purpose**: Handles disk initialization or status checking. If argument is 1, tests a flag at 0x20173be (disk status), allocates memory (20 bytes via 0x1fd90), calls disk initialization (0x25370), then checks disk status. Contains comprehensive error handling including execution context management and error reporting.
- **Arguments**: D0 = command code (1 = initialize, other = status check)
- **Returns**: D0 = status/result
- **RAM access**: 
  - 0x20173be: disk status flag
  - 0x20008f4: execution context chain pointer
  - 0x2017354: font dictionary hash table (used in cleanup)
- **Calls**: 
  - 0x1fd90 (malloc)
  - 0x25370 (disk_init)
  - 0x24b50 (get_disk_status)
  - 0x24b5c (check_disk_status)
  - 0x2df1c (push_execution_context)
  - 0x1fdc4 (free)
  - 0x288f8 (error_handler)
  - 0x10350 (unknown, likely cleanup)
  - 0x26948 (string comparison/registration)
  - 0x103bc (unknown)
  - 0x173be (unknown)
- **Complexity**: High - manages disk initialization with proper error recovery and execution context

### 3. 0x77514-0x7753C: DATA - File system operation dispatch table
- **Address**: 0x77514-0x7753C
- **Size**: 44 bytes (11 long pointers)
- **Format**: Array of 11 function pointers
- **Values**: 
  - 0x7712a, 0x770c0, 0x771ee, 0x7728a, 0x772e2, 0x7731e, 0x773ac, 0x77364, 0x773b4, 0x773ac, 0x773ac
- **Purpose**: Dispatch table for file system operations (open, close, read, write, etc.)

### 4. 0x77540-0x77544: DATA - File system handler pointers
- **Address**: 0x77540, 0x77544
- **Size**: 8 bytes (2 long pointers)
- **Values**: 0x77540, 0x77544 (self-referential, likely placeholder/default handlers)
- **Purpose**: Referenced by `initialize_filesystem_object` at offsets 14 and 18

### 5. 0x77546-0x7758A: STRINGS - Error messages
- **Address**: 0x77546-0x7758A
- **Size**: 68 bytes
- **Content**: 
  - 0x77546: "disk appears not to be initialized." (null-terminated)
  - 0x7756e: "diskstatus" (null-terminated)
  - 0x77579: "initializeddisk" (null-terminated)
- **Purpose**: Error strings used by disk initialization/status functions

### 6. 0x7758C-0x775D4: `match_format_string`
- **Entry**: 0x7758C
- **Purpose**: Compares a format string against a pattern string with wildcard support. Handles '%' as a single-character wildcard, and '%%' as a literal '%'. Returns pointer to first non-matching character.
- **Arguments**: 
  - A0 = format string to match
  - A1 = pattern string (may contain '%' wildcards)
- **Returns**: D0 = pointer to position in format string where match stopped (or start if no match)
- **Algorithm**: 
  1. Check if current pattern char is '%'
  2. If pattern char is null, check if format has '%' (escape handling)
  3. If pattern char not null, consume one char from format for each '%' in pattern
  4. Compare characters directly otherwise
- **Called by**: `find_filesystem_by_format` (0x775D6)

### 7. 0x775D6-0x77712: `find_filesystem_by_format`
- **Entry**: 0x775D6
- **Purpose**: Searches registered file systems for one matching a format string. Copies format string to buffer, handles escape sequences, and searches through the file system table.
- **Arguments**: 
  - A0 = format string to match
  - A1 = output buffer (optional, for copying matched string)
- **Returns**: D0 = pointer to matching file system object or NULL
- **Algorithm**:
  1. Check if format string starts with '%' (wildcard)
  2. Copy up to 100 characters to local buffer, handling escapes
  3. If output buffer provided, copy matched portion
  4. Search through file system table (0x2022280) comparing format strings
  5. Try both primary (offset 18) and secondary (offset 14) format strings
- **RAM access**: 
  - 0x2022280: file system object table
  - 0x2016a30: number of registered file systems
- **Calls**: 0x2dc7c (string comparison function)
- **Called by**: Multiple file system operations

### 8. 0x77714-0x77872: `find_or_create_filesystem`
- **Entry**: 0x77714
- **Purpose**: Attempts to find a matching file system for a given format string, and if not found, tries to initialize/create one from available file systems.
- **Arguments**:
  - A0 = format string
  - A1 = output buffer (optional)
- **Returns**: D0 = file system object pointer or NULL
- **Algorithm**:
  1. Call `find_filesystem_by_format` to find existing match
  2. If not found, iterate through all file systems looking for one that can handle the format
  3. Check file system flags (bits 7 and 3 for initialization status)
  4. If file system has bit 4 set, call its handler function (offset 34+0)
  5. If successful and output buffer provided, copy format string
- **RAM access**:
  - 0x20008f4: execution context chain
  - 0x2022280: file system object table
  - 0x2016a30: file system count
- **Calls**:
  - 0x175d6 (find_filesystem_by_format)
  - 0x2df1c (push_execution_context)
  - 0x2dcb0 (string copy function)
- **Complexity**: Manages execution context for error recovery

### 9. 0x77874-0x77932: `register_filesystem`
- **Entry**: 0x77874
- **Purpose**: Registers a new file system object in the global file system table, maintaining sorted order by some priority value.
- **Arguments**: A0 = file system object pointer
- **Returns**: None (void)
- **Algorithm**:
  1. Check if table is full (max 4 entries)
  2. Find insertion position based on priority value at offset 2
  3. Shift existing entries to make room
  4. Insert new entry
  5. Increment file system count
  6. Call initialization function (offset 34+24)
- **RAM access**:
  - 0x2022280: file system object table
  - 0x2016a30: file system count
- **Calls**: 0x26382 (error handler if table full)

### 10. 0x77934-0x77940: `unregister_filesystem`
- **Entry**: 0x77934
- **Purpose**: Unregisters a file system from the global table.
- **Arguments**: Unknown (likely file system object pointer)
- **Returns**: None (void)
- **Calls**: 0x26334 (cleanup function)

### 11. 0x77942-0x77972: `allocate_file_handle`
- **Entry**: 0x77942
- **Purpose**: Allocates a file handle structure from a pool.
- **Arguments**: None
- **Returns**: D0 = pointer to allocated file handle
- **Algorithm**:
  1. Check if pool has space (max 152 handles)
  2. Calculate address from base 0x2016a34 + (count * 38)
  3. Increment handle count
- **RAM access**:
  - 0x2016acc: file handle allocation counter
  - 0x2016a34: file handle pool base

### 12. 0x77974-0x779AA: `create_file_object`
- **Entry**: 0x77974
- **Purpose**: Creates a file object with associated file handle.
- **Arguments**: A0 = parameters (likely filename/path)
- **Returns**: D0 = file object pointer
- **Algorithm**:
  1. Allocate file handle via 0x17974
  2. Check handle number < 100
  3. Call 0x26f34 to create file object
- **Calls**:
  - 0x1ba44 (allocate_file_handle wrapper)
  - 0x26f34 (create_file_object function)

### 13. 0x779AC-0x77AA6: `open_file`
- **Entry**: 0x779AC
- **Purpose**: Opens a file using the appropriate file system handler.
- **Arguments**:
  - A0 = filename/path
  - A1 = mode/parameters
- **Returns**: D0 = file handle or error code
- **Algorithm**:
  1. Find matching file system via `find_filesystem_by_format`
  2. If not found, iterate through file systems looking for one that can open the file
  3. Call file system's open function (offset 34+4)
  4. Manage execution context for error recovery
- **RAM access**:
  - 0x20008f4: execution context chain
- **Calls**:
  - 0x175d6 (find_filesystem_by_format)
  - 0x2df1c (push_execution_context)

### 14. 0x77AA8-0x77B74: `close_file`
- **Entry**: 0x77AA8
- **Purpose**: Closes a file handle and performs cleanup.
- **Arguments**:
  - A0 = file handle structure
  - A1 = parameters (likely flags)
- **Returns**: D0 = status code
- **Algorithm**:
  1. Check if any file systems registered
  2. Extract file mode bits from handle
  3. Validate handle number < 100
  4. Find file system object for this handle
  5. Call file system's close function (offset 34+16)
  6. Perform cleanup operations
- **RAM access**:
  - 0x2016a30: file system count
- **Calls**:
  - 0x26f34 (lookup file system)
  - 0x17714 (find_or_create_filesystem)
  - 0x1bb98 (cleanup functions)

### 15. 0x77B76-0x77BEA: `delete_file`
- **Entry**: 0x77B76
- **Purpose**: Deletes a file using the appropriate file system.
- **Arguments**: A0 = filename/path
- **Returns**: D0 = status code
- **Algorithm**:
  1. Create file object via 0x17974
  2. Find matching file system via 0x17714
  3. Call file system's delete function (offset 34+20)
  4. Manage execution context
- **Calls**:
  - 0x17974 (create_file_object)
  - 0x17714 (find_or_create_filesystem)
  - 0x2df1c (push_execution_context)

### 16. 0x77BEC-0x77C8E: `rename_file`
- **Entry**: 0x77BEC
- **Purpose**: Renames a file using the appropriate file system.
- **Arguments**:
  - A0 = old filename
  - A1 = new filename
- **Returns**: D0 = status code
- **Algorithm**:
  1. Create file objects for both names
  2. Find matching file system
  3. Compare format strings using `match_format_string`
  4. Call file system's rename function (offset 34+12)
  5. Manage execution context
- **Calls**:
  - 0x17974 (create_file_object)
  - 0x17714 (find_or_create_filesystem)
  - 0x77588 (match_format_string)
  - 0x2df1c (push_execution_context)

### 17. 0x77C90-0x77D24: `read_file`
- **Entry**: 0x77C90
- **Purpose**: Reads data from an open file.
- **Arguments**:
  - A0 = file handle
  - A1 = buffer pointer
  - A2 = count
- **Returns**: D0 = bytes read or error code
- **Algorithm**:
  1. Look up file descriptor from handle
  2. Check if file is opened for reading (bit 3 set)
  3. Call file system's read function (offset 34+44)
  4. Handle errors and cleanup
- **RAM access**:
  - 0x2017468: file descriptor table (magic numbers)
  - 0x2017428: file descriptor pointers
- **Calls**:
  - 0x1b78a (lookup_file_descriptor)
  - 0x1862c (get_file_descriptor)
  - 0x1818c (check_file_mode)
  - 0x1bb98 (cleanup)

### 18. 0x77D26-0x77DB2: `write_file`
- **Entry**: 0x77D26
- **Purpose**: Writes data to an open file.
- **Arguments**:
  - A0 = file handle
  - A1 = buffer pointer
  - A2 = count
- **Returns**: D0 = bytes written or error code
- **Algorithm**:
  1. Get file descriptor
  2. Clear read-only bit (bit 3)
  3. Call file system's write function (offset 34+40)
  4. Handle errors
- **Calls**:
  - 0x1b626 (get_file_handle)
  - 0x1b78a (lookup_file_descriptor)
  - 0x1862c (get_file_descriptor)
  - 0x1863a (error cleanup)

### 19. 0x77DB4-0x77E1E: `file_seek`
- **Entry**: 0x77DB4
- **Purpose**: Seeks to a position within a file.
- **Arguments**:
  - A0 = file handle
  - A1 = offset structure (two 32-bit values)
  - A2 = whence (seek mode)
- **Returns**: D0 = new position or error
- **Algorithm**:
  1. Extract offset values from structure
  2. Validate seek position against file size
  3. Call seek function (0x26f86)
  4. Update file position
- **Calls**:
  - 0x2dcd4 (validate_seek)
  - 0x26f86 (perform_seek)
  - 0x165aa (update_file_position)
  - 0x11334 (file_sync)

### 20. 0x77E20-0x77F92: `file_ioctl`
- **Entry**: 0x77E20
- **Purpose**: Performs device control operations on a file.
- **Arguments**:
  - A0 = file handle
  - A1 = command
  - A2 = parameters
- **Returns**: D0 = status code
- **Algorithm**:
  1. Get file descriptor
  2. Check file mode allows ioctl (bit 1)
  3. Iterate through file systems looking for one that handles the command
  4. Call file system's ioctl function (offset 34+8)
  5. Handle execution context and errors
- **RAM access**:
  - 0x2000950/0x2000954: error context pointers
- **Calls**:
  - 0x1b9b4 (get_file_info)
  - 0x1ba8e (get_ioctl_params)
  - 0x17974 (create_file_object)
  - 0x175d6 (find_filesystem_by_format)
  - 0x2df1c (push_execution_context)
  - 0x10f8c (error reporting)

### 21. 0x77F94-0x77FF4: `get_file_info`
- **Entry**: 0x77F94
- **Purpose**: Retrieves information about a file.
- **Arguments**: A0 = filename/path
- **Returns**: D0 = file info structure pointer or error
- **Algorithm**:
  1. Create file object
  2. Find matching file system
  3. Call file system's stat function (offset 34+28)
  4. Return file information
- **Calls**:
  - 0x17974 (create_file_object)
  - 0x175d6 (find_filesystem_by_format)
  - 0x1bb98 (cleanup/output)

### 22. 0x77FF6-0x78000: `file_flush` (partial)
- **Entry**: 0x77FF6
- **Purpose**: Flushes file buffers to disk.
- **Arguments**: Likely file handle
- **Returns**: Status code
- **Note**: Function continues beyond 0x78000

## KEY INSIGHTS:

1. **File System Architecture**: The code implements a pluggable file system architecture with registration/discovery mechanisms.

2. **Object Structure**: File system objects have a standard structure with:
   - Flags at offset 0 (bits: 3=initialized, 4=can open, 6=can stat, 7=registered)
   - Priority at offset 2
   - Function table pointer at offset 34

3. **Function Table Layout**: Each file system has a function table with operations at offsets:
   - 0: check format match
   - 4: open
   - 8: ioctl
   - 12: rename
   - 16: close
   - 20: delete
   - 24: initialize
   - 28: stat/get info
   - 40: write
   - 44: read

4. **Error Handling**: Extensive use of execution context management (0x2df1c) for error recovery.

5. **File Handle Management**: File handles are allocated from a pool with 38-byte structures.

The code in this region provides comprehensive file I/O operations with support for multiple file system types, proper error handling, and resource management.

; === CHUNK 33: 0x78000-0x78C00 ===

Looking at the raw disassembly from 0x78000 to 0x78C00, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addressing**: The prior analysis used 0x78000-0x79800 but the actual disassembly shows addresses starting at 0x78000 (which appears as 0x18000 in the listing due to base offset). I'll use the actual function addresses.

2. **Function boundaries**: Some functions were incorrectly identified. Let me trace through the actual code flow.

## REFINED ANALYSIS:

### 1. `file_read_byte` (0x78000)
- **Entry**: 0x78000
- **Purpose**: Reads a byte from a file handle. First calls 0x17974 (likely `get_file_handle`), then 0x175d6 (likely `validate_handle`). Checks bit 3 (read permission) and bit 7 (EOF) of file status byte. If EOF, calls read function at offset 0x20 in file's function table.
- **Arguments**: File handle structure pointer (passed via stack frame at fp@(-100))
- **Return**: D0 = byte read (via 0x1bc78 which likely converts to PS object)
- **RAM access**: Accesses file handle structure
- **Call targets**: 0x17974, 0x175d6, 0x263f2 (error), 0x1bc78

### 2. `file_write_byte` (0x7805e)
- **Entry**: 0x7805e
- **Purpose**: Writes a byte to a file handle. Similar to read but calls write function at offset 0x24 in file's function table.
- **Arguments**: File handle structure pointer
- **Return**: None (void)
- **Call targets**: 0x17974, 0x175d6, 0x263f2

### 3. `set_io_vectors` (0x780a0)
- **Entry**: 0x780a0
- **Purpose**: Sets up I/O vector tables. When D0=0, sets vectors at 0x2022278/0x202227c to 0x779ac/0x77aa8. When D0=1 and 0x20173c0 is set, calls 0x269fa with string table pointer.
- **Arguments**: D0 = mode (0=normal, 1=debug)
- **RAM access**: 0x2022278, 0x202227c, 0x20173c0
- **Call targets**: 0x269fa

### 4. **STRING TABLE** (0x780e0-0x78188) - CORRECTION
This is NOT a function but a data table containing 8 string pairs (16 entries total). Each pair appears to be a command name and handler address:
- "deletefile" (0x78128) -> 0x77b76
- "renamefile" (0x78133) -> 0x7bec
- "fileposition" (0x7813e) -> 0x7c90
- (another string at 0x7814b) -> 0x7d26
- "devstatus" (0x7815b) -> 0x7f94
- "devmount" (0x78165) -> 0x7ff6
- "devdismount" (0x7816e) -> 0x805e
- "filenameforall" (0x7817a) -> 0x7e20

### 5. `stream_getc` (0x7818c)
- **Entry**: 0x7818c
- **Purpose**: Gets a character from a stream buffer. Decrements count, reads from buffer if available, otherwise calls stream's read function at offset 0 in function table.
- **Arguments**: A5 = stream structure pointer (passed at fp@(8))
- **Structure**: Stream has: count@0, buffer_ptr@4, func_table@0xe
- **Return**: D0 = character (processed through function at offset 0x10 in function table)
- **Call targets**: Stream's read function, then processing function

### 6. `lookup_or_create_file_handle` (0x781de)
- **Entry**: 0x781de
- **Purpose**: Finds or creates a file handle in the file table (16 entries at 0x2017428). Searches for matching file pointer. If not found, allocates new slot with unique ID.
- **Arguments**: A5=file pointer, A4=output handle struct, D0=flags (from fp@(14))
- **Return**: Populates A4 with handle structure
- **RAM access**: 0x2017428 (file ptr table), 0x2017468 (ID table), 0x2016ad0 (device table), 0x2016ae0 (next ID)
- **Call targets**: 0x26382 (error)

### 7. `create_file_handle` (0x78304)
- **Entry**: 0x78304
- **Purpose**: Wrapper for lookup_or_create_file_handle that stores result in global buffer at 0x2016ae4.
- **Arguments**: File pointer (fp@(8)), flags (fp@(14))
- **Return**: D0 = pointer to handle in 0x2016ae4 buffer

### 8. `open_file` (0x78338)
- **Entry**: 0x78338
- **Purpose**: Opens a file with mode parsing. Supports % format specifiers. Parses mode string starting with '%', matches against known modes (r, w, a, r+, w+, a+).
- **Arguments**: Filename (fp@(8)), mode string (fp@(12)), flags (fp@(16))
- **Return**: A5 = file pointer
- **RAM access**: 0x200093c/0x2000938 (error strings), 0x20008f4 (execution context)
- **Call targets**: 0x2dcd4 (string length), 0x10f8c (error), 0x26f34 (parse filename), 0x2dc7c (string compare), 0x78a18 (file open helper), 0x263f2 (error), 0x2df1c (context check)

### 9. `close_file_if_needed` (0x784ba)
- **Entry**: 0x784ba
- **Purpose**: Simple stub that always returns 0. Likely placeholder for file closing logic.
- **Arguments**: None
- **Return**: D0 = 0

### 10. `check_and_close_file` (0x784c4)
- **Entry**: 0x784c4
- **Purpose**: Checks if a file needs closing by examining bit 4 of status byte at offset 0xC. Calls close function at offset 0x18 in function table.
- **Arguments**: A0 = file pointer
- **Return**: D0 = 1 if file was closed, 0 otherwise
- **Call targets**: File's close function

### 11. `validate_and_close_file_handle` (0x784fa)
- **Entry**: 0x784fa
- **Purpose**: Validates and closes a file handle by index and ID. Checks if handle ID matches stored ID, updates ID if file is read-only, calls write function if needed, then closes.
- **Arguments**: Handle index (fp@(10)), handle ID (fp@(12)), force flag (fp@(16))
- **RAM access**: 0x2017468 (ID table), 0x2017428 (file ptr table), 0x2017354 (hash?), 0x2016ae0 (next ID)
- **Call targets**: 0x26334 (error), 0x28394 (close file), 0x7863a (file cleanup)

### 12. `get_default_file_handle` (0x785c6)
- **Entry**: 0x785c6
- **Purpose**: Gets default file handle structure by searching execution stack for dictionary objects (type 6).
- **Arguments**: A5 = output buffer
- **RAM access**: 0x20174a4 (execution stack)
- **Return**: Populates A5 with handle structure

### 13. `get_null_file_handle` (0x7862c)
- **Entry**: 0x7862c
- **Purpose**: Returns pointer to null file handle at 0x2016aec.
- **Arguments**: None
- **Return**: D0 = 0x2016aec

### 14. `cleanup_file` (0x7863a)
- **Entry**: 0x7863a
- **Purpose**: Cleans up a file by closing it and reporting error.
- **Arguments**: File pointer
- **Call targets**: 0x28394 (close), 0x10f8c (error)

### 15. `setup_file_pointers` (0x78662)
- **Entry**: 0x78662
- **Purpose**: Sets up three file pointers in global variables 0x2000900, 0x2000904, 0x20008fc based on handle indices and IDs.
- **Arguments**: Three pairs of (index, ID) on stack
- **RAM access**: 0x2017468, 0x2017428, 0x2000900, 0x2000904, 0x20008fc
- **Call targets**: 0x7862c (get_null_file_handle)

### 16. `close_files_by_context` (0x7871c)
- **Entry**: 0x7871c
- **Purpose**: Closes all files belonging to a specific context (device ID).
- **Arguments**: D7 = context byte
- **RAM access**: 0x2017428 (file table), 0x2016ad0 (device table), 0x2017468 (ID table)
- **Call targets**: 0x184c4 (check_and_close_file)

### 17. `set_file_error_handler` (0x7877a)
- **Entry**: 0x7877a
- **Purpose**: Sets file error handler pointer at 0x2016b08.
- **Arguments**: Handler address
- **RAM access**: 0x2016b08

### 18. `initialize_stream_buffer` (0x7878a)
- **Entry**: 0x7878a
- **Purpose**: Initializes a stream buffer structure. Sets up buffer pointers and counts.
- **Arguments**: A1 = stream structure pointer
- **Structure**: Buffer starts at offset 0x12, with pointers at offsets 0, 4, 8

### 19. `validate_stream_character` (0x787ce)
- **Entry**: 0x787ce
- **Purpose**: Validates a character for stream output. Checks if character is control char (< 0x20) and not TAB/LF, reports error.
- **Arguments**: Character (fp@(11)), stream pointer (fp@(12))
- **Call targets**: 0x28430 (error reporting)

### 20. `flush_stream_buffer` (0x7880e)
- **Entry**: 0x7880e
- **Purpose**: Flushes all buffers in a stream's buffer chain to free memory.
- **Arguments**: Stream pointer
- **Call targets**: 0x2836c (free memory)

### 21. `stream_get_char` (0x78870)
- **Entry**: 0x78870
- **Purpose**: Gets a character from a stream buffer. Manages buffer chain, calls read function when buffer empty.
- **Arguments**: Stream pointer
- **Return**: D0 = character or -1 if EOF
- **Call targets**: Stream's read function

### 22. `stream_put_char` (0x788ee)
- **Entry**: 0x788ee
- **Purpose**: Puts a character to a stream buffer. Manages buffer chain, calls write function when buffer full.
- **Arguments**: Character (fp@(11)), stream pointer (fp@(12))
- **Return**: D0 = character written
- **Call targets**: Stream's write function

### 23. `stream_read_to_eof` (0x78966)
- **Entry**: 0x78966
- **Purpose**: Reads stream until EOF by repeatedly calling stream_get_char.
- **Arguments**: Stream pointer
- **Call targets**: 0x78870 (stream_get_char)

### 24. `free_stream_buffers` (0x78984)
- **Entry**: 0x78984
- **Purpose**: Frees all buffers associated with a stream.
- **Arguments**: Stream pointer
- **Call targets**: 0x2836c (free), 0x28584 (stream cleanup)

### 25. `get_stream_position` (0x789ca)
- **Entry**: 0x789ca
- **Purpose**: Gets current position in stream by summing buffer sizes in chain.
- **Arguments**: Stream pointer
- **Return**: D0 = position or -1 if stream has bit 4 set at offset 0xC

### 26. `file_open_helper` (0x78a18) - **MAJOR FUNCTION**
- **Entry**: 0x78a18
- **Purpose**: Main file opening helper with extensive state machine. Handles file operations with buffering, error checking, and character processing.
- **Arguments**: Three file pointers on stack (likely stdin, stdout, stderr equivalents)
- **RAM access**: 0x20008f4 (execution context), many local variables
- **Call targets**: 0x28544 (allocate), 0x26382 (error), 0x28344 (malloc), 0x1878a (initialize_stream_buffer), 0x2df1c (context check), 0x187ce (validate_stream_character), 0x283e8 (error), 0x1863a (cleanup), 0x184fa (validate_and_close), 0x283b0 (flush), 0x1880e (flush_stream_buffer)
- **Algorithm**: Complex state machine handling characters 0x0D, 0x12, 0x15, 0x7F specially, with buffering and error recovery

## KEY INSIGHTS:

1. **File handle management**: System maintains 16 file handles with IDs for validation against use-after-free.

2. **Stream buffering**: Sophisticated buffer chain management with 244-byte buffers (0xF4).

3. **Context-aware file operations**: Files are associated with execution contexts (device IDs).

4. **Error handling**: Extensive error checking with specific error codes for file operations.

5. **Character validation**: Control characters are validated with special handling for TAB, LF.

The code shows a complete file I/O subsystem with buffering, error handling, and context management typical of a PostScript interpreter's file system layer.

; === CHUNK 34: 0x78C00-0x79800 ===

Looking at the raw disassembly from 0x78C00 to 0x79800, I can see this is indeed part of the PostScript interpreter's stream handling and file I/O subsystem. Let me provide a corrected and refined analysis:

## CORRECTIONS TO PRIOR ANALYSIS:
The prior analysis had several inaccuracies:
1. The function at 0x78c00 is NOT `scan_token_continuation` - it's actually the continuation of a larger function that handles PostScript token scanning/processing.
2. The function at 0x78f2a is correctly identified as `read_decrypted_byte` for Type 1 font decryption.
3. The function at 0x78fde is correctly identified as `read_hex_char` for reading hexadecimal data.

## REFINED ANALYSIS:

### 1. `scan_token_continuation` (0x78c00-0x78e66)
**Entry**: 0x78c00 (continuation from earlier code)
**Purpose**: Continuation of PostScript token scanner - processes characters from input stream, handles line feeds, tabs, and special characters.
**Algorithm**:
- Reads characters via stream function table calls (offset 0x10 for special processing)
- Handles EOF (-1) and backspace (0x08)
- When encountering LF (0x0A), calls processing function at offset 0x10 in stream's function table
- Manages dynamic buffer growth (reallocates at 244 bytes)
- Processes printable characters (>= 0x20) and handles control characters specially
**Arguments**: Stream pointer in A5, other args on stack
**RAM access**: 0x2016b08 (processing flag), 0x20008f4 (global pointer chain)
**Call targets**: 0x283b0, 0x283e8, 0x28344 (malloc), 0x1878a, 0x2d8d8
**Note**: This is part of a larger token scanning function that starts earlier

### 2. `set_stream_eof` (0x78e6e-0x78e80)
**Entry**: 0x78e6e
**Purpose**: Sets EOF flag on a stream structure
**Arguments**: A0 = stream pointer (from FP@8)
**Behavior**: Sets bit 4 at offset 0xC in stream structure, returns -1
**Returns**: D0 = -1 (EOF indicator)
**Structure**: Stream has flags at offset 0xC

### 3. `stream_ungetc` (0x78e82-0x78ea8)
**Entry**: 0x78e82
**Purpose**: Pushes a character back onto stream buffer (ungetc functionality)
**Arguments**: D0 = character to push back, A0 = stream structure pointer
**Behavior**: Checks if buffer has space (current position > buffer start), decrements position, stores character
**Returns**: D0 = character if successful, -1 if buffer full
**Structure**: Stream buffer pointers: start@0, current@4, end@8

### 4. `stream_flush_buffer` (0x78eaa-0x78ec0)
**Entry**: 0x78eaa
**Purpose**: Flushes stream buffer by advancing buffer start to current position
**Arguments**: A0 = stream pointer
**Behavior**: Adds buffer length to start pointer, resets current position to start
**Used by**: Output streams to commit buffered data

### 5. `stream_close` (0x78ec2-0x78ed6)
**Entry**: 0x78ec2
**Purpose**: Closes a stream and frees associated resources
**Arguments**: Stream pointer on stack
**Behavior**: Calls 0x28584 (close function), returns 0
**Returns**: D0 = 0 (success)

### 6. `stream_get_buffer_start` (0x78ed8-0x78ee4)
**Entry**: 0x78ed8
**Purpose**: Returns the buffer start pointer from a stream structure
**Arguments**: A0 = stream pointer
**Returns**: D0 = buffer start address
**Used by**: Functions that need direct buffer access

### 7. `create_stream_structure` (0x78ee6-0x78f28)
**Entry**: 0x78ee6
**Purpose**: Allocates and initializes a new stream structure
**Arguments**: D0.W = stream type/flags, D1.L = initial value
**Behavior**: 
- Allocates 0x14f4 bytes via 0x28544 (malloc-like)
- Sets up structure: type@0, initial_value@4, copy@8, flags@0xC (sets bit 7)
**Returns**: D0 = pointer to new stream structure or NULL
**Structure**: 16+ bytes: type, value, copy, flags, function table pointer at 0xE

### 8. `read_decrypted_byte` (0x78f2a-0x78fdc)
**Entry**: 0x78f2a
**Purpose**: Reads and decrypts a byte from an encrypted stream (Type 1 font eexec)
**Algorithm**:
- Uses rolling XOR encryption with seed stored at stream@8
- Decryption: `char = (seed >> 8) ^ plain_byte & 0xFF`
- Updates seed: `seed = (seed + plain_byte) * 0x3FC5CE6D + 0x0D8658BF`
- Returns decrypted byte in D0
**Arguments**: A5 = stream pointer
**Returns**: D0 = decrypted byte or -1 on error
**Call targets**: 0x1862c (get file handle)
**Note**: Standard Type 1 font decryption algorithm

### 9. `read_hex_char` (0x78fde-0x790ca)
**Entry**: 0x78fde
**Purpose**: Reads and decrypts a hexadecimal character from encrypted stream
**Algorithm**:
- Reads 2 hex digits, converts to byte
- Uses same decryption as `read_decrypted_byte`
- Handles hex digits 0-9, A-F, a-f
**Arguments**: A5 = stream pointer
**Returns**: D0 = decrypted byte or -1 on error
**Call targets**: 0x1862c (get file handle)

### 10. `stream_putc` (0x790cc-0x790f4)
**Entry**: 0x790cc
**Purpose**: Puts a character into a stream buffer
**Arguments**: D0 = character, A0 = stream pointer
**Behavior**: Stores character at stream@4, returns character or -1
**Returns**: D0 = character if successful, -1 if error

### 11. `stream_getc` (0x790f6-0x79164)
**Entry**: 0x790f6
**Purpose**: Gets a character from a stream
**Arguments**: A0 = stream pointer
**Behavior**: Calls stream's getc function via function table
**Returns**: D0 = character or -1 on EOF
**Call targets**: 0x1862c (get file handle)

### 12. `stream_close_and_release` (0x79166-0x79200)
**Entry**: 0x79166
**Purpose**: Closes a stream and releases associated file handle
**Arguments**: A0 = stream pointer
**Behavior**: Closes stream, checks if file handle needs to be released
**Call targets**: 0x28584 (close), 0x1862c (get file handle), 0x184fa (release file)
**RAM access**: 0x2017354 (font dictionary), 0x20174bc

### 13. `stream_peekc` (0x79202-0x7926e)
**Entry**: 0x79202
**Purpose**: Peeks at next character in stream without consuming it
**Arguments**: A0 = stream pointer
**Behavior**: Calls stream's peek function via function table
**Returns**: D0 = next character or -1 on EOF
**Call targets**: 0x1862c (get file handle)

### 14. `is_encrypted_stream` (0x79270-0x792ce)
**Entry**: 0x79270
**Purpose**: Checks if a stream is encrypted (Type 1 font)
**Arguments**: D0.W = stream type, D1.L = stream ID
**Behavior**: Checks if stream's function table matches encryption handlers
**Returns**: D0 = 1 if encrypted, 0 if not
**Note**: Compares function table addresses 0x7a414 and 0x7a448

### 15. `process_encrypted_stream` (0x792d0-0x79630)
**Entry**: 0x792d0
**Purpose**: Main handler for processing encrypted Type 1 font streams
**Algorithm**:
1. Reads stream header to determine encryption type
2. For type 5 (eexec): creates decryption stream
3. For type 6 (hex): creates hex decryption stream
4. Processes decrypted data, handles font dictionary updates
**Arguments**: Stream descriptor on stack
**Call targets**: 0x165f8, 0x124ac, 0x1862c, 0x18ee6, 0x181de, 0x2df1c, 0x2d8d8, 0x7818c, 0x10350, 0x1665e
**RAM access**: 0x20008f4 (global pointer chain), 0x2000938/93c
**Note**: Complex function handling Type 1 font decryption and loading

### 16. `get_current_stream` (0x79632-0x79646)
**Entry**: 0x79632
**Purpose**: Gets the current active stream
**Arguments**: None
**Behavior**: Calls 0x1b94a to get stream, then processes it
**Returns**: D0 = stream pointer
**Call targets**: 0x1b94a, 0x1877a

### 17. `stream_seek` (0x79648-0x7968a)
**Entry**: 0x79648
**Purpose**: Seeks to a position in a stream
**Arguments**: Stream descriptor and position on stack
**Behavior**: Calls stream's seek function via function table
**Call targets**: 0x1ba44, stream function table offset 0xC

### 18. `stream_copy` (0x7968c-0x79700)
**Entry**: 0x7968c
**Purpose**: Copies data from one stream to another
**Arguments**: Two stream descriptors on stack
**Behavior**: Reads from source, writes to destination
**Call targets**: 0x1ba44, 0x10f8c, 0x26f34, 0x18338, 0x165aa

### 19. `compare_streams` (0x79702-0x7972c)
**Entry**: 0x79702
**Purpose**: Compares two stream descriptors for equality
**Arguments**: D0.W/D1.L = stream type/ID to compare against
**Behavior**: Gets current stream descriptor, compares with arguments
**Returns**: D0 = 1 if equal, 0 if not
**Call targets**: 0x185c6

### 20. `stream_getc_with_eof_check` (0x7972e-0x797fe)
**Entry**: 0x7972e
**Purpose**: Gets a character from stream with EOF and newline handling
**Algorithm**:
1. Checks stream access permissions
2. Gets character from stream
3. Handles EOF and newline specially (clears bit 3 in stream flags)
**Arguments**: Stream descriptor on stack
**Returns**: D0 = character
**Call targets**: 0x1b78a, 0x124ac, 0x1862c
**RAM access**: 0x2017468, 0x2017428

## KEY INSIGHTS:
1. This region contains the core stream I/O subsystem for the PostScript interpreter
2. Handles both regular streams and encrypted Type 1 font streams
3. Uses function tables at stream offset 0xE for polymorphic stream operations
4. Stream structure appears to be at least 0x18 bytes with function table pointer at 0xE
5. The encryption uses standard Type 1 font algorithm with multiplier 0x3FC5CE6D and addend 0x0D8658BF
6. Multiple stream types: regular I/O, encrypted binary, encrypted hex

## DATA REGIONS:
- No significant data tables in this range - mostly code
- Function table addresses referenced: 0x7a414, 0x7a448 (encryption handlers)

## CORRECTIONS FROM PRIOR:
The prior analysis was mostly correct but missed several functions and had incorrect names for some. The refined analysis provides more accurate function boundaries and purposes.

; === CHUNK 35: 0x79800-0x7A400 ===

Looking at this disassembly, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addressing**: The prior analysis uses 0x19800-0x1A400 addresses, but these are actually offsets from the start of bank 2. The actual ROM addresses are 0x79800-0x7A400.

2. **Function boundaries**: The prior analysis missed some functions and misidentified others.

3. **Data regions**: There's a jump table/data structure at 0x7A366 that wasn't mentioned.

## REFINED ANALYSIS:

### 1. `read_char` (0x79800)
**Entry:** 0x79800  
**Purpose:** Reads a single character from a file object. Checks if buffer has characters available; if not, calls the file's read function. Handles EOF (-1) by closing the file if it's in EOF mode.  
**Arguments:** File object pointer likely passed via stack (standard C calling convention).  
**Returns:** Character in D0 (extended to long), or -1 for EOF.  
**Hardware:** Accesses file tables at 0x02017428/0x02017468.  
**Key calls:** 0x1863a (file close), 0x184fa (error/cleanup), 0x1bb98 (return processing).  
**Called from:** Character input routines throughout the interpreter.

### 2. `write_char` (0x79874)  
**Entry:** 0x79874  
**Purpose:** Writes a single character to a file. Checks file mode bits, manages buffer, flushes if needed. Handles both buffered and unbuffered I/O.  
**Arguments:** Character in low byte, file object pointer.  
**Returns:** Success in D0.  
**Hardware:** Accesses 0x02017428/0x02017468 file tables.  
**Key calls:** 0x1b626 (get file object), 0x1b78a (check something), 0x1862c (get file handle).  
**Called from:** Character output routines.

### 3. `read_string` (0x79938)
**Entry:** 0x79938  
**Purpose:** Reads a string of specified length from a file. Handles line endings (CR/LF conversion to just LF), buffer management, and EOF. Uses a while loop to read characters one by one.  
**Arguments:** Buffer pointer, count, file object (likely via stack).  
**Returns:** Number of characters read in D0.  
**Hardware:** Uses file tables at 0x02017428/0x02017468.  
**Key calls:** 0x1b9b4 (get arguments), 0x1b78a, 0x263ba (error/exception).  
**Called from:** String input operations.

### 4. `write_string` (0x79ab4)
**Entry:** 0x79ab4  
**Purpose:** Writes a string to a file. Similar to write_char but for blocks. Checks file permissions and mode bits.  
**Arguments:** String pointer, length, file object.  
**Returns:** Number of characters written in D0.  
**Hardware:** Accesses file tables at 0x02017428/0x02017468.  
**Key calls:** 0x1b9b4, 0x1b78a, 0x1862c.  
**Called from:** String output operations.

### 5. `read_hex_string` (0x79be0)
**Entry:** 0x79be0  
**Purpose:** Reads hexadecimal-encoded ASCII data, converting pairs of hex digits to bytes. Uses translation table at 0x1A47C (likely maps '0'-'9','A'-'F','a'-'f' to 0-15, others to -1).  
**Arguments:** Buffer, count, file object.  
**Returns:** Success/failure in D0.  
**Hardware:** File tables at 0x02017428/0x02017468.  
**Key calls:** 0x1b9b4, 0x1b78a, 0x1862c.  
**Called from:** PostScript hex string decoding.

### 6. `write_hex_string` (0x79e10)
**Entry:** 0x79e10  
**Purpose:** Writes binary data as hexadecimal ASCII representation (two chars per byte). Uses hex digit table at 0x1A57C ("0123456789abcdef").  
**Arguments:** Binary data pointer, length, file object.  
**Returns:** Success in D0.  
**Hardware:** File tables.  
**Key calls:** 0x1ba44 (different argument getter), 0x1b78a, 0x1862c.  
**Called from:** Hex output operations.

### 7. `close_file` (0x79f80)
**Entry:** 0x79f80  
**Purpose:** Closes a file by calling cleanup/error function at 0x184fa.  
**Arguments:** File object.  
**Returns:** Nothing.  
**Key calls:** 0x1b78a, 0x184fa (cleanup).  
**Called from:** File management routines.

### 8. `execute_file` (0x79fa6)
**Entry:** 0x79fa6  
**Purpose:** Executes a file based on its type (checks low 4 bits of file mode byte). Type 5 (string) or type 6 (dictionary) are handled specially. For type 5, checks if it's a standard file handle. For type 6, calls a function pointer at 0x202227c.  
**Arguments:** File object.  
**Returns:** Nothing.  
**Key calls:** 0x165f8 (get file object), 0x1bc78 (return processing), 0x263d6 (error).  
**Called from:** File execution operations.

### 9. `unknown_file_op` (0x7a016)
**Entry:** 0x7a016  
**Purpose:** Unknown file operation - just calls error handler at 0x263d6.  
**Arguments:** Unknown.  
**Returns:** Nothing.  
**Key calls:** 0x263d6 (error).  
**Called from:** Unknown.

### 10. `flush_file` (0x7a024)
**Entry:** 0x7a024  
**Purpose:** Flushes a file's buffer by calling its flush function (offset 0x14 in function table). Clears the "pending newline" flag (bit 3 at offset 0xD).  
**Arguments:** File object.  
**Returns:** Nothing.  
**Key calls:** 0x1b78a, 0x1862c, 0x1863a (close if needed).  
**Called from:** File flush operations.

### 11. `flush_standard_output` (0x7a0a2)
**Entry:** 0x7a0a2  
**Purpose:** Flushes the standard output file (handle at 0x2000904).  
**Arguments:** None.  
**Returns:** Nothing.  
**Key calls:** Same as flush_file but for fixed address.  
**Called from:** Output flush operations.

### 12. `reset_file_read_state` (0x7a0dc)
**Entry:** 0x7a0dc  
**Purpose:** Resets a file's read state by calling function at offset 0x20 in function table. Clears "pending newline" flag.  
**Arguments:** File object.  
**Returns:** Nothing.  
**Key calls:** 0x1b78a, 0x1862c.  
**Called from:** File reset operations.

### 13. `clear_file_error` (0x7a146)
**Entry:** 0x7a146  
**Purpose:** Clears a file error flag (bit 7).  
**Arguments:** File object.  
**Returns:** Nothing.  
**Key calls:** 0x185c6 (get file), 0x165aa (process).  
**Called from:** Error handling.

### 14. `read_line` (0x7a16a)
**Entry:** 0x7a16a  
**Purpose:** Reads a line from a file (up to newline). Handles CR/LF conversion. Returns the character that caused termination (newline or EOF).  
**Arguments:** File object.  
**Returns:** Terminating character in D0.  
**Key calls:** 0x1b78a, 0x1862c, 0x1bb98 (return).  
**Called from:** Line input operations.

### 15. `execute_procedure_from_file` (0x7a254)
**Entry:** 0x7a254  
**Purpose:** Executes a procedure read from a file. Creates a file object from arguments, sets execute bit (bit 7), and calls procedure executor. Handles "undefined" errors specially.  
**Arguments:** Procedure data, length.  
**Returns:** Nothing.  
**Key calls:** 0x1ba44 (get args), 0x18338 (create file), 0x11334 (execute), 0x184fa (cleanup).  
**Called from:** Procedure execution.

### 16. `init_file_system` (0x7a2cc)
**Entry:** 0x7a2cc  
**Purpose:** Initializes the file system based on mode (0=normal, 1=something else). Clears file handle tables, sets up standard files, installs function pointers.  
**Arguments:** Mode in D0 (0 or 1).  
**Returns:** Nothing.  
**Key calls:** 0x28584 (init something), 0x27632 (setup), 0x269fa (other setup).  
**Called from:** System initialization.

### 17. **DATA REGION: File operation jump table** (0x7a366-0x7a3fc)
**Address:** 0x7a366  
**Size:** 150 bytes (0x7a366-0x7a3fc)  
**Format:** Array of 3-word entries (12 bytes each). Each entry appears to contain: operation code/offset, handler address, and maybe a file handle reference.  
**Content:** Contains addresses like 0x7A634, 0x7A63B, references to 0x2000900, 0x2000904, 0x20008FC, and handler addresses in the 0x78870-0x88494 range.  
**Purpose:** Dispatch table for file-related operations.

## ADDITIONAL NOTES:

1. **File object structure**: Based on the code, file objects appear to have:
   - Offset 0x0: Buffer count/position
   - Offset 0x4: Buffer pointer
   - Offset 0xC: Mode/flags byte (bits: 3=EOF mode, 4=needs flush)
   - Offset 0xD: Status byte (bit 3=pending newline)
   - Offset 0xE: Pointer to function table

2. **Function table offsets** (from file object +0xE):
   - 0x0: read_char function
   - 0x4: write_char function
   - 0x8: write_string function
   - 0xC: write_hex function
   - 0x10: read_string function
   - 0x14: flush function
   - 0x1C: read_line function
   - 0x20: reset_read function

3. **File handle tables** at:
   - 0x02017428: Array of 16 file object pointers
   - 0x02017468: Array of 16 reference values (for validation)

4. **Standard file handles** referenced:
   - 0x2000900: Standard input?
   - 0x2000904: Standard output
   - 0x20008FC: Standard error?

5. **The prior analysis incorrectly identified 0x79d50 as a function** - it's actually part of write_hex_string (0x79e10). The code at 0x79d50 appears to be a helper within write_hex_string.

6. **Error handling**: Multiple functions call 0x124ac (likely permission error), 0x263ba/0x263d6 (various errors), and 0x184fa (cleanup with error code).

This region (0x79800-0x7A400) contains the core file I/O subsystem for the PostScript interpreter, handling character, string, and hex I/O with buffering, line ending conversion, and proper error handling.

; === CHUNK 36: 0x7A400-0x7B000 ===

Looking at the raw disassembly for 0x7A400-0x7B000, I can see several issues with the prior analysis. Let me correct and refine it:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **The prior analysis incorrectly identified 0x7A400-0x7A5A0 as a jump table** - This is actually **DATA**, not code. The values like `0007 8eaa` are 32-bit values where the high word `0007` indicates bank 2 (0x70000 base) and the low word is an offset. This appears to be a table of function pointers or string references used by the PostScript interpreter.

2. **The hex translation table is at 0x7A47C-0x7A57B** (256 bytes), not 0x7A47C-0x7A57A.

3. **The prior analysis missed several key functions** in this range.

## REFINED ANALYSIS FOR 0x7A400-0x7B000:

### DATA REGIONS:

#### 1. **Function Pointer/String Reference Table** (0x7A400-0x7A5A0)
**Address:** 0x7A400-0x7A5A0  
**Size:** 0x1A0 bytes (416 bytes)  
**Format:** 32-bit values where high word = 0x0007 (bank 2 base address), low word = offset within bank 2.  
**Purpose:** Likely a dispatch table for PostScript file I/O operators or string operations. Each entry points to a function or string in bank 2.

#### 2. **Hex Digit Translation Table** (0x7A47C-0x7A57B)
**Address:** 0x7A47C-0x7A57B  
**Size:** 256 bytes  
**Pattern:** Maps ASCII characters to hex values (0-15) or 0xFF for invalid.  
**Example at 0x7A4AC:** `00 01 02 03 04 05 06 07 08 09 FF FF FF FF FF 0A 0B 0C 0D 0E 0F FF`  
**Purpose:** Used by hexadecimal string parsing functions.

#### 3. **Hex Digit String** (0x7A57C-0x7A58B)
**Address:** 0x7A57C-0x7A58B  
**Content:** "0123456789abcdef" (16 bytes, lowercase hex digits)

#### 4. **PostScript Operator Name Table** (0x7A58C-0x7A736)
**Address:** 0x7A58C-0x7A736  
**Size:** 0x1AA bytes (426 bytes)  
**Content:** Null-terminated strings for PostScript file I/O operators:
- `%sstdin`, `%sstdout`, `%sstderr`, `%slineedit`, `%sstatementedit` (format strings)
- `LineEdit`, `String`, `CryptBin`, `CryptHex`, `eexec`, `print`, `file`
- `read`, `write`, `readline`, `readstring`, `readhexstring`
- `writestring`, `writehexstring`, `closefile`, `status`, `flush`
- `flushfile`, `resetfile`, `currentfile`, `bytesavailable`, `run`

### FUNCTIONS:

#### 1. **`copy_string_struct`** (0x7A738)
**Entry:** 0x7A738  
**Purpose:** Copies an 8-byte string structure from source to destination. A string structure appears to be: 4-byte data pointer, 2-byte length, 2-byte unknown (flags/capacity?).  
**Arguments:** Source pointer in A0 (from FP+8), destination pointer in A5 (from FP+20), max length in FP+18.  
**Algorithm:** Copies 8 bytes, then ensures destination length doesn't exceed the specified max length.  
**Returns:** Destination pointer in D0 (0x02016B14 - a global temp location).  
**Called from:** Various string manipulation functions.

#### 2. **`substring_extract`** (0x7A766)
**Entry:** 0x7A766  
**Purpose:** Extracts a substring from a source string structure. Creates a new string structure pointing to a portion of the original data.  
**Arguments:** Source string struct (FP+8), offset (FP+18), length (FP+22), destination (FP+24).  
**Algorithm:** Validates bounds, creates substring by adjusting pointer and length.  
**Returns:** Updates destination string structure.  
**Hardware:** Uses RAM at 0x02016B1C for temporary storage.  
**Called from:** String manipulation operators.

#### 3. **`string_compare`** (0x7A804)
**Entry:** 0x7A804  
**Purpose:** Lexicographically compares two strings.  
**Arguments:** String1 length (FP+10), String1 data pointer (FP+12), String2 length (FP+18), String2 data pointer (FP+20).  
**Algorithm:** Compares character by character up to min(length1, length2). If equal up to that point, compares lengths.  
**Returns:** D0 = -1 (str1 < str2), 0 (equal), 1 (str1 > str2).  
**Called from:** Dictionary lookup, string comparison operators.

#### 4. **`substring_copy`** (0x7A870)
**Entry:** 0x7A870  
**Purpose:** Copies a substring from source to destination with bounds checking.  
**Arguments:** Source string struct (FP+8), source offset (FP+18), copy length (FP+22), destination (FP+24).  
**Algorithm:** Validates offset and length against source string bounds, then calls `substring_extract` followed by `copy_string_struct`.  
**Returns:** Updates destination string structure.  
**Called from:** String manipulation operators.

#### 5. **`substring_copy_to_temp`** (0x7A8DC)
**Entry:** 0x7A8DC  
**Purpose:** Copies a substring to a temporary buffer at 0x02016B1C.  
**Arguments:** Source string struct (FP+8), source offset (FP+18), copy length (FP+22).  
**Algorithm:** Calls `substring_copy` with destination set to temporary buffer.  
**Returns:** Pointer to temporary buffer in D0 (0x02016B1C).  
**Called from:** String manipulation operators.

#### 6. **`copy_substring_with_offset`** (0x7A91C)
**Entry:** 0x7A91C  
**Purpose:** Copies a substring from one string to another with offset and length validation.  
**Arguments:** Dest string struct (FP+8), dest offset (FP+18), source string struct (FP+20), source offset (FP+24), copy length (FP+28).  
**Algorithm:** Validates offsets and lengths, extracts source substring, then copies to destination.  
**Returns:** Updates destination string structure.  
**Called from:** String manipulation operators.

#### 7. **`compare_substrings`** (0x7A982)
**Entry:** 0x7A982  
**Purpose:** Compares a substring of one string with a substring of another.  
**Arguments:** String1 struct (FP+8), offset1 (FP+18), string2 struct (FP+20), offset2 (FP+24), length (FP+28).  
**Algorithm:** Extracts pointers and lengths, then compares byte-by-byte.  
**Returns:** D0 = 1 if equal, 0 if not equal.  
**Called from:** String search and comparison functions.

#### 8. **`read_char_from_stream`** (0x7A9B8)
**Entry:** 0x7A9B8  
**Purpose:** Reads a single character from a stream/file.  
**Algorithm:** Calls stream read function (0x1B564), checks for error (-1), converts character to string structure.  
**Returns:** String structure with the read character.  
**Called from:** File I/O operators.

#### 9. **`find_substring_in_string`** (0x7AA0C)
**Entry:** 0x7AA0C  
**Purpose:** Searches for a substring within a string.  
**Arguments:** Main string struct (FP+8), substring struct (FP+20).  
**Algorithm:** Iterates through main string, comparing substrings of equal length using `compare_substrings`.  
**Returns:** If found, returns 1 and updates temporary buffer; otherwise returns 0.  
**Called from:** String search operators.

#### 10. **`compare_strings_equal`** (0x7AB2A)
**Entry:** 0x7AB2A  
**Purpose:** Checks if two strings are equal.  
**Arguments:** String1 struct (FP+8), string2 struct (FP+20).  
**Algorithm:** Compares lengths, then uses `compare_substrings` to check equality.  
**Returns:** D0 = 1 if equal, 0 if not equal.  
**Called from:** String comparison operators.

#### 11. **`digit_to_char`** (0x7ABE2)
**Entry:** 0x7ABE2  
**Purpose:** Converts a digit (0-15) to its character representation.  
**Arguments:** Digit value (FP+10).  
**Algorithm:** For values 0-9, returns '0'-'9'; for 10-15, returns 'A'-'F'.  
**Returns:** Character in D0.  
**Called from:** Number formatting functions.

#### 12. **`format_number_base`** (0x7AC10)
**Entry:** 0x7AC10  
**Purpose:** Formats a number in a given base (2-36).  
**Arguments:** Buffer pointer (FP+8), number (FP+12), base (FP+18), width (FP+22).  
**Algorithm:** Repeated division by base, stores digits in reverse order, pads with zeros if needed.  
**Returns:** Null-terminated string in buffer.  
**Called from:** Number formatting and conversion functions.

#### 13. **`copy_string_to_struct`** (0x7ACC8)
**Entry:** 0x7ACC8  
**Purpose:** Copies a C string (null-terminated) to a string structure.  
**Arguments:** C string pointer (FP+8), string struct pointer (FP+12).  
**Algorithm:** Gets string length, validates against struct capacity, copies data.  
**Returns:** Updates string structure with length and data pointer.  
**Called from:** String creation functions.

#### 14. **`copy_string_to_struct_with_length`** (0x7AD12)
**Entry:** 0x7AD12  
**Purpose:** Copies a string with explicit length to a string structure.  
**Arguments:** Source data pointer (FP+8), length (FP+10), string struct pointer (FP+16).  
**Algorithm:** Calls `copy_substring_with_offset` with offset 0.  
**Returns:** Updates string structure.  
**Called from:** String creation functions.

#### 15. **`read_string_from_stream`** (0x7AD40)
**Entry:** 0x7AD40  
**Purpose:** Reads a string from a stream/file.  
**Algorithm:** Reads string structure from stream, validates length (< 128), converts to C string.  
**Returns:** Null-terminated string in buffer.  
**Called from:** File I/O operators.

#### 16. **`convert_object_to_string`** (0x7AD84)
**Entry:** 0x7AD84  
**Purpose:** Converts a PostScript object to its string representation.  
**Arguments:** Object type/length in FP-8, object value in FP-4.  
**Algorithm:** Handles different object types: integers, reals, booleans, names, etc.  
**Returns:** String structure with representation.  
**Called from:** Print/formatting operators.

#### 17. **`read_object_from_stream`** (0x7AF5C)
**Entry:** 0x7AF5C  
**Purpose:** Reads a PostScript object from a stream/file.  
**Algorithm:** Reads object header, determines type, handles special cases for numbers in different bases.  
**Returns:** Object in string structure.  
**Called from:** File I/O and parsing operators.

## KEY INSIGHTS:

1. **String Structure Format:** 8 bytes: [4-byte data pointer][2-byte length][2-byte flags/capacity]
2. **Temporary Buffers:** 0x02016B14 and 0x02016B1C are used for temporary string storage
3. **Error Handling:** Many functions call error handler at 0x263BA on bounds violations
4. **Stream I/O Integration:** Functions at 0x7A9B8, 0x7AD40, 0x7AF5C interface with stream subsystem
5. **Number Formatting:** Supports bases 2-36 with proper digit conversion

The code in this range appears to be part of the PostScript interpreter's string manipulation and I/O subsystem, providing core functionality for string operations, number formatting, and stream/file I/O.

; === CHUNK 37: 0x7B000-0x7BC00 ===

## REFINED ANALYSIS OF 0x7B000-0x7BC00

### 1. 0x7B000 - `push_and_call_string_op`
- **Entry**: 0x7B000
- **Purpose**: Helper function that pushes arguments and calls string/array operations. Pushes FP-16 and FP-2 values, calls 0x89AE8 (string operation), then processes results through 0x1AC10, 0x1ACC8, and finally 0x165AA.
- **Arguments**: Uses FP-16 and FP-2 as inputs.
- **Return**: Result from 0x165AA in D0.
- **Call targets**: 0x89AE8, 0x1AC10, 0x1ACC8, 0x165AA
- **Called by**: Unknown from this range.

### 2. 0x7B046 - `debug_print_three_objects`
- **Entry**: 0x7B046  
- **Purpose**: Debug function that prints three objects to debug channel. Checks if object at FP+8 has valid type bits (calls 0x124AC if not), then prints objects at FP+16, FP+8, and fixed address 0x2016B0C (debug buffer).
- **Arguments**: Two objects at FP+8 and FP+16.
- **RAM access**: 0x2016B0C (debug output buffer).
- **Call targets**: 0x124AC (type check), 0x1665E (print to debug).
- **Called by**: Likely error handling or debugging code.

### 3. 0x7B086 - `get_and_process_string_char`
- **Entry**: 0x7B086
- **Purpose**: Implements PostScript's `get` operator for strings. Gets string object from stack, validates it's type 5 (string), extracts first character, prints debug info, pushes character as integer.
- **Arguments**: None (operates on stack).
- **RAM access**: 0x2016B0C (debug output).
- **Call targets**: 0x166AC (get object), 0x16812 (get string info), 0x1A766 (extract char), 0x1665E (print), 0x1BB98 (push integer).
- **Called by**: PostScript `get` operator handler.

### 4. 0x7B120 - `setup_special_execution`
- **Entry**: 0x7B120
- **Purpose**: Sets up special execution context for operators 0 or 1. If argument is 0, does nothing. If 1, sets up error handler via 0x267F2 with callback to 0x7B086, then establishes execution context via 0x269FA with address 0x7B16C.
- **Arguments**: Integer at FP+8 (0 or 1).
- **RAM access**: 0x2016B0C.
- **Call targets**: 0x267F2 (error setup), 0x269FA (execution context).
- **Called by**: Special operator dispatch.

### 5. DATA REGION: 0x7B15C-0x7B1EA - String Table
- **Address**: 0x7B15C-0x7B1EA
- **Size**: 142 bytes
- **Format**: Mixed data - starts with string fragments, then pointer table, then more strings
- **Content**: 
  - 0x7B15C: "notstring--" (truncated, likely "notstring-array")
  - 0x7B16C: Pointer table (10 entries × 4 bytes each = 40 bytes)
    - 0x7B16C: 0x0007B1C4 (points to "cvs")
    - 0x7B170: 0x0007AD84 (unknown function)
    - 0x7B174: 0x0007B1C8 (points to "cvn")
    - 0x7B178: 0x0007AD40 (unknown function)
    - 0x7B17C: 0x0007B1CC (points to "anchorsearch")
    - 0x7B180: 0x0007A9B8 (unknown function)
    - 0x7B184: 0x0007B1D3 (points to "search")
    - 0x7B188: 0x0007AA0C (unknown function)
    - 0x7B18C: 0x0007B1DA (points to "cvrs")
    - 0x7B190: 0x0007AB2A (unknown function)
    - 0x7B194: 0x0007B1E7 (points to unknown)
  - 0x7B1A4: "%d %" (format string)
  - 0x7B1A8: "true" (PostScript boolean)
  - 0x7B1AE: "false" (PostScript boolean)
  - 0x7B1B4: "@string" (error message)
  - 0x7B1BC: "stringforall" (PostScript operator)
  - 0x7B1C8: "cvs" (PostScript operator)
  - 0x7B1CC: "cvn" (PostScript operator)  
  - 0x7B1D3: "anchorsearch" (PostScript operator)
  - 0x7B1DA: "search" (PostScript operator)
  - 0x7B1E7: "cvrs" (PostScript operator)

### 6. 0x7B1EC - `compare_objects` (MAJOR FUNCTION)
- **Entry**: 0x7B1EC
- **Purpose**: Main comparison function for PostScript operators. Compares two objects based on their types. Uses a jump table at 0x7B20C to dispatch based on first object's type (low 4 bits). Handles all 13 PostScript object types with specific comparison logic for each type pair.
- **Arguments**: Two objects at FP+8 and FP+16 (each 8 bytes: type+access bits, 2-byte flags, 4-byte data).
- **Return**: D0 = comparison result (0 = false, 1 = true, -1 = true for boolean comparisons).
- **Algorithm**: 
  1. Extract type of first object (low 4 bits)
  2. Use jump table at 0x7B20C to dispatch to type-specific handler
  3. Each handler checks second object's type and performs appropriate comparison
  4. Returns 1 if equal, 0 if not equal (or -1 for boolean true)
- **Type dispatch table** (offsets from 0x7B20C):
  - 0x001C: type 0 (special)
  - 0x0030: type 1 (integer)
  - 0x007C: type 2 (real)
  - 0x0104: type 3 (system)
  - 0x00E0: type 4 (boolean)
  - 0x018E: type 5 (string)
  - 0x0248: type 6 (dictionary)
  - 0x0274: type 7 (procedure)
  - 0x0298: type 8 (mark)
  - 0x02BC: type 9 (name)
  - 0x0308: type 10 (null)
  - 0x031E: type 11 (save)
  - 0x033E: type 12 (fontID)
  - 0x02DE: type 13 (operator)
- **Call targets**: 0x89A88 (real conversion), 0x899F8 (int to real), 0x89968 (real comparison), 0x89980 (int comparison), 0x124AC (type error), 0x13BD4 (string comparison), 0x1A804 (dictionary comparison)
- **Called by**: PostScript comparison operators (eq, ne, etc.)

### 7. 0x7B564 - `pop_integer_to_d0`
- **Entry**: 0x7B564
- **Purpose**: Pops an integer from the operand stack and returns it in D0. Validates the object is type 1 (integer) and range 0-65535.
- **Arguments**: None (pops from stack).
- **Return**: D0 = integer value (0-65535).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow check), 0x263BA (range error), 0x263D6 (type error).
- **Called by**: Functions needing integer arguments from stack.

### 8. 0x7B5EC - `validate_integer_range`
- **Entry**: 0x7B5EC
- **Purpose**: Validates that an object is type 1 (integer) and within range 0-65535.
- **Arguments**: Object at FP+8 (8-byte PostScript object).
- **Return**: D0 = integer value if valid.
- **Call targets**: 0x263D6 (type error), 0x263BA (range error).
- **Called by**: Integer validation code.

### 9. 0x7B626 - `pop_integer_to_d0_alt`
- **Entry**: 0x7B626
- **Purpose**: Alternative integer pop function, similar to 0x7B564 but returns value in D0 directly.
- **Arguments**: None (pops from stack).
- **Return**: D0 = integer value.
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Functions needing integer arguments.

### 10. 0x7B690 - `pop_integer_from_exec_stack`
- **Entry**: 0x7B690
- **Purpose**: Pops an integer from the execution stack (not operand stack).
- **Arguments**: None (pops from execution stack).
- **Return**: D0 = integer value.
- **RAM access**: 0x20174A4 (execution stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Execution stack operations.

### 11. 0x7B6FA - `pop_mark_object`
- **Entry**: 0x7B6FA
- **Purpose**: Pops a mark object (type 8) from operand stack and copies it to destination.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (object copied to destination).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Mark-related operations.

### 12. 0x7B766 - `pop_mark_to_global`
- **Entry**: 0x7B766
- **Purpose**: Pops a mark object and stores it at global address 0x2016B94.
- **Arguments**: None.
- **Return**: D0 = pointer to 0x2016B94.
- **RAM access**: 0x2016B94 (global mark storage), 0x20173E8 (operand stack).
- **Call targets**: 0x7B6FA (pop_mark_object).
- **Called by**: Mark operations needing global storage.

### 13. 0x7B78A - `pop_dict_object`
- **Entry**: 0x7B78A
- **Purpose**: Pops a dictionary object (type 6) from operand stack and copies it to destination.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (object copied to destination).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Dictionary operations.

### 14. 0x7B7F6 - `pop_dict_to_global`
- **Entry**: 0x7B7F6
- **Purpose**: Pops a dictionary object and stores it at global address 0x2016B9C.
- **Arguments**: None.
- **Return**: D0 = pointer to 0x2016B9C.
- **RAM access**: 0x2016B9C (global dict storage), 0x20173E8 (operand stack).
- **Call targets**: 0x7B78A (pop_dict_object).
- **Called by**: Dictionary operations needing global storage.

### 15. 0x7B81A - `pop_numeric_to_real`
- **Entry**: 0x7B81A
- **Purpose**: Pops a numeric value (integer or real) from stack, converts to real if integer, stores result.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (real value stored at destination).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error), 0x89A10 (int to real conversion).
- **Called by**: Numeric operations requiring real values.

### 16. 0x7B8A4 - `pop_numeric_and_convert`
- **Entry**: 0x7B8A4
- **Purpose**: Pops numeric value, converts to real, returns in D0/D1 (floating point registers).
- **Arguments**: None.
- **Return**: D0/D1 = real value.
- **Call targets**: 0x7B81A (pop_numeric_to_real), 0x89A88 (return real).
- **Called by**: Functions needing real values.

### 17. 0x7B8C0 - `pop_numeric_from_exec_stack`
- **Entry**: 0x7B8C0
- **Purpose**: Pops numeric value from execution stack, converts to real if integer.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (real value stored at destination).
- **RAM access**: 0x20174A4 (execution stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error), 0x89A10 (int to real).
- **Called by**: Execution stack numeric operations.

### 18. 0x7B94A - `pop_boolean`
- **Entry**: 0x7B94A
- **Purpose**: Pops a boolean value (type 4) from operand stack.
- **Arguments**: None.
- **Return**: D0 = boolean value (0 or 1).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Boolean operations.

### 19. 0x7B9B4 - `pop_string_object`
- **Entry**: 0x7B9B4
- **Purpose**: Pops a string object (type 5) from operand stack and copies it to destination.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (object copied to destination).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: String operations.

### 20. 0x7BA20 - `pop_string_to_global`
- **Entry**: 0x7BA20
- **Purpose**: Pops a string object and stores it at global address 0x2016BA4.
- **Arguments**: None.
- **Return**: D0 = pointer to 0x2016BA4.
- **RAM access**: 0x2016BA4 (global string storage), 0x20173E8 (operand stack).
- **Call targets**: 0x7B9B4 (pop_string_object).
- **Called by**: String operations needing global storage.

### 21. 0x7BA44 - `validate_string_access`
- **Entry**: 0x7BA44
- **Purpose**: Validates that a string object has execute access (bit 1 of access field).
- **Arguments**: String object pointer at FP+8.
- **Return**: None (calls error if invalid).
- **Call targets**: 0x7B9B4 (pop_string_object), 0x124AC (access error).
- **Called by**: String operations requiring execute access.

### 22. 0x7BA6A - `pop_string_with_access_check`
- **Entry**: 0x7BA6A
- **Purpose**: Pops string with execute access check, stores at 0x2016BAC.
- **Arguments**: None.
- **Return**: D0 = pointer to 0x2016BAC.
- **RAM access**: 0x2016BAC (global string storage).
- **Call targets**: 0x7BA44 (validate_string_access).
- **Called by**: String operations with access requirements.

### 23. 0x7BA8E - `pop_name_or_operator`
- **Entry**: 0x7BA8E
- **Purpose**: Pops a name (type 9) or operator (type 13) object from stack.
- **Arguments**: Destination pointer at FP+8.
- **Return**: None (object copied to destination).
- **RAM access**: 0x20173E8 (operand stack pointer).
- **Call targets**: 0x1648C (stack underflow), 0x263D6 (type error).
- **Called by**: Name/operator operations.

### 24. 0x7BB00 - `pop_name_or_operator_to_global`
- **Entry**: 0x7BB00
- **Purpose**: Pops name/operator object to global address 0x2016BB4.
- **Arguments**: None.
- **Return**: D0 = pointer to 0x2016BB4.
- **RAM access**: 0x2016BB4 (global name storage).
- **Call targets**: 0x7BA8E (pop_name_or_operator).
- **Called by**: Name/operator operations needing global storage.

### 25. 0x7BB24 - `push_short_integer`
- **Entry**: 0x7BB24
- **Purpose**: Pushes a short integer (0-65535) onto the operand stack. Uses template object at 0x87C60.
- **Arguments**: Integer value in low word of FP+8.
- **Return**: None (value pushed to stack).
- **RAM access**: 0x20008F8 (current color space), 0x20173E8 (operand stack pointer).
- **Call targets**: 0x164A8 (stack overflow check).
- **Called by**: Integer pushing operations.

### 26. 0x7BB98 - `push_integer`
- **Entry**: 0x7BB98
- **Purpose**: Pushes a 32-bit integer onto the operand stack. Uses template object at 0x87C60.
- **Arguments**: Integer value at FP+8.
- **Return**: None (value pushed to stack).
- **RAM access**: 0x20008F8 (current color space), 0x20173E8 (operand stack pointer).
- **Call targets**: 0x164A8 (stack overflow check).
- **Called by**: Integer pushing operations (called from 0x7B086).

## CORRECTIONS TO PRIOR ANALYSIS:
1. **0x7B086 function name**: Changed from `get_and_process_string_char` to `get_string_char_and_push` - more accurate description.
2. **0x7B15C data region**: Corrected interpretation - this is indeed a string table with operator names and function pointers.
3. **Added missing functions**: Prior analysis missed 14 stack manipulation functions (0x7B564 through 0x7BB98).
4. **Fixed jump table interpretation**: The prior analysis correctly identified the compare_objects jump table but missed some details about the offsets.

## KEY INSIGHTS:
This region contains core PostScript object manipulation functions:
- **Comparison engine** (0x7B1EC): Handles all type-specific comparisons
- **Stack manipulation utilities**: Specialized functions for popping different object types with validation
- **Type checking and validation**: Extensive error checking for type mismatches and access violations
- **Global storage helpers**: Functions that pop objects to specific global addresses for temporary storage

The functions follow a consistent pattern: LINK A6, stack manipulation, type checking, error handling, UNLK A6, RTS. This is characteristic of Sun C compiled code with standard 68020 calling conventions.

; === CHUNK 38: 0x7BC00-0x7C800 ===

## CORRECTED ANALYSIS OF 0x7BC00-0x7C800

The prior analysis was mostly correct but missed some important details and misidentified a few functions. Here's the refined analysis:

### 1. 0x7BC00 - `push_to_alternate_stack`
- **Entry**: 0x7BC00
- **Purpose**: Pushes an object onto the alternate stack (execution/save stack at 0x20174A4). This is used for saving continuation contexts in PostScript's coroutine system. The function saves the current A5 (continuation pointer) and pushes a new stack node with the object data.
- **Arguments**: Object pointer at FP+8 (the object to push)
- **Returns**: Nothing (modifies stack)
- **RAM access**: 0x20174A4 (alternate stack pointer), 0x20008F8 (context flag)
- **Call targets**: 0x164A8 (stack overflow check)
- **Called by**: PostScript operators that need to save execution state
- **Algorithm**: Allocates a new stack node from free list, links it into the stack, copies object data from FP+8 into the node.

### 2. 0x7BC78 - `push_to_main_stack`
- **Entry**: 0x7BC78
- **Purpose**: Pushes an object onto the main operand stack (at 0x20173E8). This is the standard PostScript operand stack for arguments and results.
- **Arguments**: Object pointer at FP+8
- **Returns**: Nothing
- **RAM access**: 0x20173E8 (main stack pointer), 0x20008F8
- **Call targets**: 0x164A8
- **Called by**: Most PostScript operators that push results
- **Algorithm**: Identical to 0x7BC00 but uses main stack pointer instead of alternate stack pointer.

### 3. 0x7BCE8 - `pop_two_objects`
- **Entry**: 0x7BCE8
- **Purpose**: Pops two objects from the main stack, converts them to appropriate types, and stores them at the destination. Handles integer-to-real conversion if needed. This is a type-aware pop for binary operators.
- **Arguments**: Destination buffer pointer at FP+8 (8 bytes for two objects)
- **Returns**: Nothing (stores at destination)
- **RAM access**: 0x20173E8
- **Call targets**: 0x89A10 (convert integer to real), 0x1B81A (type conversion helper)
- **Called by**: Operators needing two operands (arithmetic, comparisons)
- **Algorithm**: Pops top object (A3), then next object (A4). Checks type bits (low 4 bits of byte at offset 4): 1=int, 2=real, 5=string, etc. Converts integers to reals if needed for mixed-mode operations.

### 4. 0x7BDBC - `pop_two_and_store_global`
- **Entry**: 0x7BDBC
- **Purpose**: Pops two objects from stack and stores them at global location 0x2016BBC. Used for temporary storage during complex operations.
- **Arguments**: None
- **Returns**: Pointer to storage in D0 (0x2016BBC)
- **RAM access**: 0x2016BBC (global temp storage)
- **Call targets**: 0x7BCE8 (pop_two_objects)
- **Called by**: Complex operators needing temp storage
- **Algorithm**: Calls pop_two_objects with local buffer, then copies to global location.

### 5. 0x7BDE2 - `push_two_from_address`
- **Entry**: 0x7BDE2
- **Purpose**: Pushes two consecutive objects from a memory address onto the main stack. Used for restoring saved state or copying object pairs.
- **Arguments**: Base address at FP+8 (pushes objects at [addr] and [addr+4])
- **Returns**: Nothing
- **Call targets**: 0x7BE16 (push_object)
- **Called by**: Operators restoring saved state
- **Algorithm**: Calls push_object twice: first for object at address, then for object at address+4.

### 6. 0x7BE06 - `push_fp_plus_8`
- **Entry**: 0x7BE06
- **Purpose**: Wrapper that pushes the object at FP+8 onto stack. Essentially `push_object(FP+8)`.
- **Arguments**: Object at FP+8
- **Returns**: Nothing
- **Call targets**: 0x7BDE2
- **Called by**: Various operators needing to push a single argument

### 7. 0x7BE16 - `push_object`
- **Entry**: 0x7BE16
- **Purpose**: Core function to push an object onto the main stack. Allocates stack node from free list, copies object data.
- **Arguments**: Object pointer at FP+8
- **Returns**: Nothing
- **RAM access**: 0x20173E8, 0x20008F8
- **Call targets**: 0x164A8
- **Called by**: All push operations
- **Algorithm**: Allocates free node from stack's free list, links it in, copies object data from FP+8 into node.

### 8. 0x7BE88 - `push_integer`
- **Entry**: 0x7BE88
- **Purpose**: Creates an integer object from a 32-bit value and pushes it onto the main stack.
- **Arguments**: Integer value at FP+8
- **Returns**: Nothing
- **Call targets**: 0x899C8 (create integer object), 0x7BE16 (push_object)
- **Called by**: Operators returning integer results
- **Algorithm**: Calls create_integer_object, then pushes the resulting object.

### 9. 0x7BEAC - `push_to_alternate_stack_from_address`
- **Entry**: 0x7BEAC
- **Purpose**: Pushes an object from a memory address onto the alternate stack. Similar to 0x7BE16 but for alternate stack.
- **Arguments**: Object pointer at FP+8
- **Returns**: Nothing
- **RAM access**: 0x20174A4
- **Call targets**: 0x164A8
- **Called by**: Context-saving operations
- **Algorithm**: Same as push_object but uses alternate stack pointer.

### 10. 0x7BF1E - `push_integer_to_alternate_stack`
- **Entry**: 0x7BF1E
- **Purpose**: Creates an integer object and pushes it onto the alternate stack.
- **Arguments**: Integer value at FP+8
- **Returns**: Nothing
- **Call targets**: 0x899C8, 0x7BEAC
- **Called by**: Context-saving operations needing integer values
- **Algorithm**: Creates integer object, pushes to alternate stack.

### 11. 0x7BF42 - `pop_and_execute`
- **Entry**: 0x7BF42
- **Purpose**: Pops an object from the main stack and executes it if it's an operator. Handles different object types with a jump table.
- **Arguments**: None
- **Returns**: Nothing (executes the object)
- **RAM access**: 0x20173E8
- **Call targets**: 0x1648C (stack underflow check), 0x124AC (type error), 0x1064E (execute operator), 0x13BD4 (execute procedure), 0x263D6 (range check error)
- **Called by**: PostScript interpreter's execution loop
- **Algorithm**: Pops object, checks type byte (low 4 bits), dispatches via jump table at 0x7BFA8. Type 3=operator (execute), type 7=procedure (execute), others=error.

### 12. 0x7C028 - `check_executable_flag`
- **Entry**: 0x7C028
- **Purpose**: Checks if the top object on the stack has the executable flag set (bit 7 of type byte).
- **Arguments**: None
- **Returns**: Pushes boolean result (1 if executable, 0 if not)
- **Call targets**: 0x165F8 (pop_object), 0x7BC78 (push_boolean)
- **Called by**: `executable?` operator
- **Algorithm**: Pops object, tests bit 7 of type byte, pushes boolean result.

### 13. 0x7C056 - `check_readonly_flag`
- **Entry**: 0x7C056
- **Purpose**: Checks if the top object on the stack has the readonly flag set (bit 0 of access bits).
- **Arguments**: None
- **Returns**: Pushes boolean result (1 if readonly, 0 if not)
- **Call targets**: 0x165F8, 0x7BC78, 0x263D6
- **Called by**: `readonly?` operator
- **Algorithm**: Pops object, extracts access bits (bits 4-6), tests bit 0, pushes boolean.

### 14. 0x7C0DC - `check_executeonly_flag`
- **Entry**: 0x7C0DC
- **Purpose**: Checks if the top object on the stack has the executeonly flag set (bit 1 of access bits).
- **Arguments**: None
- **Returns**: Pushes boolean result
- **Call targets**: 0x165F8, 0x7BC78, 0x263D6
- **Called by**: `executeonly?` operator
- **Algorithm**: Similar to 0x7C056 but tests bit 1 of access bits.

### 15. 0x7C162 - `set_readonly_flag`
- **Entry**: 0x7C162
- **Purpose**: Sets the readonly flag (bit 0 of access bits) on the top object.
- **Arguments**: None
- **Returns**: Nothing (modifies object in place)
- **Call targets**: 0x165F8, 0x124AC (type error), 0x165AA (push_back)
- **Called by**: `readonly` operator
- **Algorithm**: Pops object, checks type, sets bit 0 of access bits (bits 4-6), pushes back.

### 16. 0x7C1D6 - `set_executeonly_flag`
- **Entry**: 0x7C1D6
- **Purpose**: Sets the executeonly flag (bit 1 of access bits) on the top object.
- **Arguments**: None
- **Returns**: Nothing
- **Call targets**: 0x165F8, 0x124AC, 0x10DA2 (set_access_bits), 0x165AA
- **Called by**: `executeonly` operator
- **Algorithm**: Pops object, checks type, calls set_access_bits with mask 0x10 (bit 1), pushes back.

### 17. 0x7C262 - `clear_access_flags`
- **Entry**: 0x7C262
- **Purpose**: Clears all access flags (readonly, executeonly, noaccess) on the top object.
- **Arguments**: None
- **Returns**: Nothing
- **Call targets**: 0x165F8, 0x124AC, 0x10DA2, 0x165AA
- **Called by**: `noaccess` operator
- **Algorithm**: Pops object, checks type, calls set_access_bits with mask 0x00, pushes back.

### 18. 0x7C2D4 - `get_type`
- **Entry**: 0x7C2D4
- **Purpose**: Gets the type of the top object and pushes it as an integer (0-13).
- **Arguments**: None
- **Returns**: Pushes integer type code
- **Call targets**: 0x165F8, 0x165AA
- **Called by**: `type` operator
- **Algorithm**: Pops object, extracts low 4 bits of type byte, uses as index into type table at 0x2016B24, pushes result.

### 19. 0x7C318 - `clear_executable_flag`
- **Entry**: 0x7C318
- **Purpose**: Clears the executable flag (bit 7) on the top object.
- **Arguments**: None
- **Returns**: Nothing
- **Call targets**: 0x1648C (stack underflow)
- **Called by**: `cvx` operator (make executable)
- **Algorithm**: Checks stack not empty, clears bit 7 of type byte.

### 20. 0x7C346 - `set_executable_flag`
- **Entry**: 0x7C346
- **Purpose**: Sets the executable flag (bit 7) on the top object.
- **Arguments**: None
- **Returns**: Nothing
- **Call targets**: 0x1648C
- **Called by**: `cvx` operator (when used with `bind`?)
- **Algorithm**: Checks stack not empty, sets bit 7 of type byte.

### 21. 0x7C374 - `convert_to_integer`
- **Entry**: 0x7C374
- **Purpose**: Converts the top object to an integer. Handles integer, real, and string types.
- **Arguments**: None
- **Returns**: Pushes integer result
- **Call targets**: 0x1648C, 0x89A88 (convert real to integer), 0x89968 (compare), 0x89A40 (truncate), 0x124AC, 0x1587E (string conversion), 0x10F8C (error), 0x1BB98 (push_integer)
- **Called by**: `cvi` operator
- **Algorithm**: Pops object, dispatches by type: integer→direct, real→range check and convert, string→convert via 0x1587E.

### 22. 0x7C4B0 - `convert_to_real`
- **Entry**: 0x7C4B0
- **Purpose**: Converts the top object to a real number. Handles integer, real, and string types.
- **Arguments**: None
- **Returns**: Pushes real result
- **Call targets**: 0x1648C, 0x89A10 (convert integer to real), 0x124AC, 0x1587E, 0x10F8C, 0x7BE16 (push_real)
- **Called by**: `cvr` operator
- **Algorithm**: Similar to 0x7C374 but converts to real instead.

### 23. 0x7C590 - `copy_object`
- **Entry**: 0x7C590
- **Purpose**: Copies an object (shallow copy). For arrays and strings, copies the underlying data.
- **Arguments**: None
- **Returns**: Pushes copy
- **Call targets**: 0x165F8, 0x1B5EC (copy routine), 0x16880 (allocate copy), 0x144B0 (array copy), 0x27310 (string copy), 0x26DC8 (dictionary copy), 0x26D7E (procedure copy), 0x26EB2 (mark copy), 0x124AC, 0x263D6, 0x165AA
- **Called by**: `copy` operator
- **Algorithm**: Pops source object, dispatches by type: integer/real→direct copy, string/array→allocate new storage and copy data, dictionary→copy entries, etc.

### 24. 0x7C738 - `get_length`
- **Entry**: 0x7C738
- **Purpose**: Gets the length of an object (string, array, dictionary, etc.).
- **Arguments**: None
- **Returns**: Pushes integer length
- **Call targets**: 0x1648C (x2), various type-specific length functions
- **Called by**: `length` operator
- **Algorithm**: Pops object, dispatches by type to appropriate length function.

## DATA REGIONS:
- **0x7C4A2-0x7C4AF**: Real constants for range checking in `cvi`
  - 0x7C4A2: 0x41DFFFFF (approx 2.147483647E9, max 32-bit signed int as float)
  - 0x7C4A6: 0xC1E00000 (approx -2.147483648E9, min 32-bit signed int as float)
- **0x7BFA8-0x7BFBB**: Jump table for `pop_and_execute` (type dispatch)
- **0x7C082-0x7C097**: Jump table for `check_readonly_flag`
- **0x7C108-0x7C11D**: Jump table for `check_executeonly_flag`
- **0x7C18E-0x7C1A3**: Jump table for `set_readonly_flag`
- **0x7C202-0x7C217**: Jump table for `set_executeonly_flag`
- **0x7C28E-0x7C2A3**: Jump table for `clear_access_flags`
- **0x7C68E-0x7C6A1**: Jump table for `copy_object`
- **0x7C7E4-0x7C7F9**: Jump table for `get_length`

## CORRECTIONS TO PRIOR ANALYSIS:
1. **0x7BF42** was misidentified as generic pop - it's actually `pop_and_execute` (executes operators/procedures)
2. **0x7C028** is `check_executable_flag` not a generic test
3. **0x7C056/0x7C0DC** are access flag checkers, not generic boolean tests
4. **0x7C162/0x7C1D6/0x7C262** are access flag setters, not generic modifiers
5. **0x7C2D4** is `get_type` operator implementation
6. **0x7C318/0x7C346** are executable flag modifiers (cvx/cvn equivalents)
7. **0x7C374/0x7C4B0** are type conversion operators (cvi/cvr)
8. **0x7C590** is `copy` operator implementation
9. **0x7C738** is `length` operator implementation (incomplete in provided disassembly)

## KEY INSIGHTS:
This region contains core PostScript object manipulation operators:
- Stack operations (push/pop to both stacks)
- Type checking and conversion (cvi, cvr, type)
- Access control (readonly, executeonly, noaccess, and their query operators)
- Object copying (copy)
- Object length (length)
- Execution control (pop_and_execute, executable flag manipulation)

The functions follow a consistent pattern: pop object(s), dispatch by type via jump tables, perform operation, push result. Error handling is centralized through common error functions (0x124AC for type errors, 0x263D6 for range errors).

; === CHUNK 39: 0x7C800-0x7D400 ===

Looking at the raw disassembly from 0x7C800 to 0x7D400, I can see several functions and data regions. Let me review and refine the prior analysis:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Addresses are wrong**: The prior analysis uses addresses like 0x1c800, but the actual addresses in the binary are 0x7c800-0x7d400. This is because the disassembly shows offsets from the start of the binary section.

2. **Function at 0x7c800 (0x1c800 in disassembly)**: This is NOT an error handler. It's actually a **PostScript operator implementation** that handles three operands from the stack. The prior analysis missed the key structure: it pops three objects from the operand stack (at 0x020173e8) and processes them based on their types.

3. **Function at 0x7c926 (0x1c926)**: This is a **three-argument operator handler**, not just a type dispatcher. It pops three objects and has a jump table for type-based dispatch.

4. **Data at 0x7cf14-0x7d06e**: This is a **large data table** (352 bytes) that appears to be character width or kerning data for a font, not code. The prior analysis incorrectly tried to interpret it as code.

5. **Function at 0x7d282 (0x1d282)**: This is a **font loading/search function** that wasn't mentioned in the prior analysis.

## REFINED ANALYSIS:

### 1. Function at 0x7c800 (0x1c800 in disassembly)
**Entry:** 0x7c800  
**Suggested name:** `ps_op_three_arg_handler`  
**Purpose:** Implements a PostScript operator that takes three arguments from the operand stack. Pops three objects, examines their types, and dispatches to appropriate handlers. Handles type checking and error cases.  
**Arguments:** None (operates on global operand stack at 0x020173e8)  
**Return value:** None (pushes result back to operand stack)  
**RAM accessed:** 0x020173e8 (operand stack pointer)  
**Call targets:** 0xf986, 0x164a8, 0x108fa, 0x124ac, 0x1b5ec, 0x263ba, 0x263d6, 0x1bb98  
**Called by:** PostScript operator dispatch table  
**Key algorithm:** 
1. Gets three objects from operand stack (linked list at 0x020173e8)
2. Checks types via bit extraction (bfextu) from object header
3. Dispatches based on type: calls 0xf986 for certain types, 0x108fa for others
4. Handles bounds checking and error conditions
5. Pushes result back to stack

### 2. Function at 0x7c926 (0x1c926)
**Entry:** 0x7c926  
**Suggested name:** `ps_op_three_arg_type_switch`  
**Purpose:** Another three-argument operator with type-based dispatch via jump table. More complex than the previous function, with a proper switch statement.  
**Arguments:** None (operates on global operand stack)  
**Return value:** None (pushes result to stack)  
**RAM accessed:** 0x020173e8 (operand stack)  
**Call targets:** 0x1648c (stack underflow error), 0x1b5ec, 0xf94a, 0x109b4, 0x273da, 0x124ac, 0x263d6  
**Jump table at:** 0x7ca16 (0x1ca16) - 9 entries for types 5-13  
**Key algorithm:**
1. Pops three objects from stack
2. Extracts type code (bits 1-3 of object header)
3. Uses jump table at 0x1ca16 for dispatch
4. Cases: type 5→0xf94a, type 9→0x109b4, type 13→character access via 0x273da
5. Error handling for type mismatches

### 3. Function at 0x7caf4 (0x1caf4)
**Entry:** 0x7caf4  
**Suggested name:** `ps_op_getinterval_or_substring`  
**Purpose:** Implements PostScript `getinterval` or substring operator. Takes two integer indices and a string/array, returns a substring or subarray.  
**Arguments:** Two integers and a string/array from stack  
**Return value:** Substring/subarray pushed to stack  
**RAM accessed:** 0x020173e8  
**Call targets:** 0x1b564 (get integer), 0x1648c, 0x124ac, 0x263ba, 0xf888, 0x1a870, 0x263d6, 0x164a8  
**Key algorithm:**
1. Gets two integers via 0x1b564 (start index and count)
2. Pops source object (string or array)
3. Bounds checking: count ≤ length - start
4. Type dispatch: string (type 5)→0x1a870, array (type 9/13)→0xf888
5. Creates new object with substring/subarray

### 4. Function at 0x7cc46 (0x1cc46)
**Entry:** 0x7cc46  
**Suggested name:** `ps_op_putinterval_or_substring`  
**Purpose:** Implements PostScript `putinterval` operator. Copies data from source to destination at specified offset.  
**Arguments:** Two objects (source and destination) and an integer offset from stack  
**Return value:** None (modifies destination in place)  
**RAM accessed:** 0x020173e8  
**Call targets:** 0x165f8, 0x1b564, 0x263ba, 0x144b0, 0x27310, 0xf90c, 0x1a91c, 0x124ac, 0x263d6  
**Key algorithm:**
1. Gets destination object via 0x165f8
2. Gets integer offset via 0x1b564
3. Gets source object via 0x165f8
4. Bounds checking: offset + source length ≤ destination length
5. Special case for array-to-array copy (types 13→9) with loop
6. Type dispatch: array→array (0xf90c), string→string (0x1a91c)
7. Error handling for type mismatches

### 5. Function at 0x7cd8e (0x1cd8e)
**Entry:** 0x7cd8e  
**Suggested name:** `ps_op_type_conversion`  
**Purpose:** Converts between PostScript object types (e.g., integer to real, string to name).  
**Arguments:** Source object from stack  
**Return value:** Converted object pushed to stack  
**RAM accessed:** 0x020173e8  
**Call targets:** 0x1ba8e, 0x165f8, 0xfbf4, 0x10d5e, 0x1b046, 0x263d6  
**Jump table at:** 0x7cdc4 (0x1cdc4) - 9 entries for types 5-13  
**Key algorithm:**
1. Gets source object via 0x1ba8e
2. Gets target type object via 0x165f8
3. Extracts type code from target
4. Uses jump table at 0x1cdc4 for dispatch
5. Cases: type 5→0xfbf4, type 9→0x10d5e, type 13→0x1b046
6. Error handling for unsupported types

### 6. Function at 0x7ce34 (0x1ce34)
**Entry:** 0x7ce34  
**Suggested name:** `convert_to_float`  
**Purpose:** Converts a PostScript integer to floating-point representation.  
**Arguments:** A0 points to integer value, A1 points to result buffer  
**Return value:** Floating-point value in result buffer  
**RAM accessed:** None directly  
**Call targets:** 0x89a88, 0x89aa0, 0x89920, 0x89a28, 0x89a10  
**Key algorithm:**
1. Checks if integer is negative
2. Calls floating-point conversion routines (0x89a88 for conversion)
3. Uses different paths for negative vs. positive values
4. Stores result in provided buffer

### 7. Function at 0x7ce8c (0x1ce8c)
**Entry:** 0x7ce8c  
**Suggested name:** `get_two_integers`  
**Purpose:** Extracts two integer values from the operand stack.  
**Arguments:** FP+8: first result pointer, FP+12: second result pointer, FP+16: destination for results  
**Return value:** Two integers stored at provided addresses  
**RAM accessed:** None directly  
**Call targets:** 0x2c218 (twice)  
**Key algorithm:**
1. Calls 0x2c218 to get first integer, stores at result[0]
2. Calls 0x2c218 to get second integer, stores at result[4]
3. Both integers are 32-bit values

### 8. Function at 0x7cebc (0x1cebc)
**Entry:** 0x7cebc  
**Suggested name:** `copy_two_values`  
**Purpose:** Copies two values from source to destination addresses.  
**Arguments:** FP+8: source1, FP+12: source2, FP+16: destination  
**Return value:** None (copies values)  
**RAM accessed:** None directly  
**Call targets:** 0x2c1e4 (twice)  
**Key algorithm:**
1. Calls 0x2c1e4 to copy first value from source1 to destination
2. Calls 0x2c1e4 to copy second value from source2 to destination+4
3. Simple memory copy operation

### 9. Function at 0x7cee8 (0x1cee8)
**Entry:** 0x7cee8  
**Suggested name:** `type_error_handler`  
**Purpose:** Handles type errors in PostScript operations, printing error messages.  
**Arguments:** FP+8: error code (0 or 1)  
**Return value:** None  
**RAM accessed:** None directly  
**Call targets:** 0x26a20, 0x269fa  
**Key algorithm:**
1. Checks error code (0 or 1)
2. If error code is 1, prints two error messages
3. Error messages at 0x1d0f8 and 0x1d060 (in data section)
4. Used for type mismatch or invalid operation errors

### 10. Data Region at 0x7cf14-0x7d06e (0x1cf14-0x1d06e)
**Address:** 0x7cf14  
**Size:** 352 bytes (0x15A bytes)  
**Format:** Character width/kerning table  
**Content:** Appears to be font metric data with repeated character codes:
- Bytes 0x7cf14-0x7d05e: 336 bytes of character data
- Values appear to be ASCII character codes or width values
- Pattern suggests font width table for multiple characters
- Likely used by font rendering system

### 11. Data Region at 0x7d060-0x7d0f6 (0x1d060-0x1d0f6)
**Address:** 0x7d060  
**Size:** 150 bytes  
**Format:** String table with pointers  
**Content:** 
- 0x7d060-0x7d0f6: Array of string pointers and data
- Each entry appears to be a pointer to an error message string
- Used by error handling functions
- Strings include PostScript type names and error messages

### 12. Data Region at 0x7d0f8-0x7d164 (0x1d0f8-0x1d164)
**Address:** 0x7d0f8  
**Size:** 108 bytes  
**Format:** Type name string table  
**Content:** Array of type name strings used for error messages:
- "nulltype", "integertype", "realtype", "booleantype", "nametype"
- "stringtype", "filetype", "operatortype", "dicttype", "savetype"
- "fonttype", "packedarraytype", "marktype", "arraytype"
- Each string has an associated address (likely type ID constants)

### 13. Data Region at 0x7d170-0x7d280 (0x1d170-0x1d280)
**Address:** 0x7d170  
**Size:** 272 bytes  
**Format:** String constants  
**Content:** Various PostScript-related string constants:
- "cvlit", "cvx", "length", "xcheck", "wcheck", "readonly"
- "executeonly", "noaccess", "type", "cvi", "cvr", "cvrs"
- "forall", "getinterval", "putinterval", "get", "put"
- "copy", "astore", "aload", "packedarray", "mark"
- "array", "save", "font", "operator", "dict", "file"
- "string", "name", "boolean", "real", "integer", "null"
- Used by type system and error messages

### 14. Function at 0x7d282 (0x1d282)
**Entry:** 0x7d282  
**Suggested name:** `search_and_load_font`  
**Purpose:** Searches for and loads a font from the font directory.  
**Arguments:** A5 points to font search context structure  
**Return value:** None (updates font context)  
**RAM accessed:** Various font directory structures  
**Call targets:** 0x1e6f0, 0x1f076, 0x1f0ac, 0x25354  
**Key algorithm:**
1. Checks if font is already loaded (bit 7 of offset 0x80)
2. Reads font directory header via 0x1e6f0
3. Iterates through font directory entries
4. Compares font names for exact match
5. Handles different font entry types (1=directory, 2=font data, 3=font file)
6. Updates font context with found font information
7. Manages font caching and loading state

### 15. Function at 0x7d3a6 (0x1d3a6)
**Entry:** 0x7d3a6  
**Suggested name:** `find_font_by_name`  
**Purpose:** Searches for a font by name in the font cache.  
**Arguments:** A5 points to font name string  
**Return value:** Font entry pointer or NULL  
**RAM accessed:** 0x02016bc4 (font cache table)  
**Call targets:** 0x2dcd4  
**Key algorithm:**
1. Searches through font cache table (4 entries at 0x02016bc4)
2. Each entry is 152 bytes with name at offset 8
3. Compares names with optional leading "/" handling
4. Returns matching font entry or NULL
5. Falls back to filesystem search via 0x2dcd4 if not in cache

## SUMMARY OF CORRECTIONS:

1. **Fixed address references**: All functions are in the 0x7C800-0x7D400 range, not 0x1C800-0x1D400.

2. **Corrected function purposes**: The prior analysis misidentified several PostScript operator implementations as error handlers or type dispatchers.

3. **Added missing functions**: Functions at 0x7ce34, 0x7ce8c, 0x7cebc, 0x7cee8, 0x7d282, and 0x7d3a6 were not mentioned in the prior analysis.

4. **Identified data regions**: Correctly identified the large data tables at 0x7cf14-0x7d06e, 0x7d060-0x7d0f6, 0x7d0f8-0x7d164, and 0x7d170-0x7d280 as data, not code.

5. **Refined algorithms**: Provided more specific details about how each function works, including their use of the PostScript operand stack and type system.

The region contains a mix of PostScript operator implementations (getinterval, putinterval, type conversion), font management functions, and data tables for error messages and font metrics. This aligns with the PostScript interpreter's need for type manipulation and font loading capabilities.

; === CHUNK 40: 0x7D400-0x7E000 ===

Looking at the raw disassembly from 0x7D400 to 0x7E000, I can see this is indeed a continuation of the file system and font management code. The prior analysis had some inaccuracies and missed several functions. Let me provide a corrected and detailed analysis.

## CORRECTIONS TO PRIOR ANALYSIS:
The prior analysis incorrectly identified the function at 0x7d400 as `file_open_or_create` - it's actually `open_file`. The function at 0x7d552 was misnamed - it's `compact_file_blocks`. Several functions were completely missed in the prior analysis.

## DETAILED FUNCTION ANALYSIS:

### 1. Function at 0x7d400 (open_file)
**Entry:** 0x7d400  
**Suggested name:** `open_file`  
**Purpose:** Opens a file from the filesystem. Handles path resolution (with '/' separator), allocates a file control block from cache (4 entries at 0x02016BC4), validates path length (<100 chars), copies filename, and initializes file structure. Returns pointer to file control block.  
**Arguments:** 
- A5: pointer to filename string
- fp@(12): boolean flag (0=open existing, 1=create new)
**Return value:** A4: pointer to file control block structure (152 bytes each)  
**RAM accessed:** 
- 0x02016E24: file cache index (circular buffer of 4 entries)
- 0x02016E28: base directory path string
- 0x02016BC4: file control block array (4 entries × 152 bytes)
**Call targets:** 
- 0x2DCD4 (strlen)
- 0x25354 (error handler)
- 0x2DCB0 (strcpy)
- 0x251F6 (filesystem lookup/create)
- 0x7D280 (flush_file_cache?)
**Algorithm:**
1. Calculate total path length (base dir + filename)
2. Validate length < 100 chars
3. Find free file control block in cache (4-entry circular buffer)
4. Copy base directory path if filename doesn't start with '/'
5. Append filename
6. Look up/create file in filesystem
7. Initialize file control block fields
8. Update cache index

### 2. Function at 0x7d552 (compact_file_blocks)
**Entry:** 0x7d552  
**Suggested name:** `compact_file_blocks`  
**Purpose:** Processes file data blocks (1024-byte pages). Scans through block directory entries, compacts contiguous blocks, handles different block types (1=data, 2=end marker, 3=free). Updates block directory structure.  
**Arguments:** 
- fp@(8): pointer to file control block
- fp@(12): maximum block count?  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure
- Block directory entries (each 12 bytes: 2-byte size, 2-byte type, 8-byte data)  
**Call targets:** 
- 0x1E6F0 (get_file_info)
- 0x1F076 (get_block_pointer)
- 0x2DCF8 (memmove for block compaction)
- 0x25354 (error handler)
- 0x1F0AC (update_block_directory)
- 0x1E52A (extend_file?)
- 0x1F090 (get_block_pointer2)
- 0x7D8D0 (update_file_cache_state)  
**Algorithm:** 
1. Gets file info (size, block count)
2. For each block directory entry (up to file size / 1024):
   - Scans 1024-byte block, processing sub-blocks
   - Type 1: data block, can be compacted with previous
   - Type 2: end marker, sets flag
   - Type 3: free space
3. Compacts blocks, updates directory
4. If max blocks exceeded, adds new end marker block

### 3. Function at 0x7d6ce (write_file_to_disk)
**Entry:** 0x7d6ce  
**Suggested name:** `write_file_to_disk`  
**Purpose:** Writes cached file data to disk. Validates file state (must be state 2 = dirty), processes blocks, updates file control block state to 3 (writing), writes data to disk.  
**Arguments:** A5: pointer to file control block  
**Return value:** None (void)  
**RAM accessed:** 
- File control block fields: state (offset 0), block pointer (4), size (112), cache pointer (108), etc.
- Block directory structure  
**Call targets:** 
- 0x25354 (error handler)
- 0x7D552 (compact_file_blocks)
- 0x7D280 (unknown file operation)
- 0x1F076 (get_block_pointer)
- 0x2DCB0 (strcpy)
- 0x1F0AC (update_block_directory)
- 0x7D8D0 (update_file_cache_state)  
**Algorithm:** 
1. Checks file state == 2 (dirty)
2. Processes blocks via 0x7D552
3. Gets current block pointer
4. Validates block type (1=data or 2=end marker)
5. Sets block type to 3 (writing)
6. Copies data from cache to block
7. Updates block directory
8. Sets file state to 3 (writing)

### 4. Function at 0x7d7e6 (complete_file_write)
**Entry:** 0x7d7e6  
**Suggested name:** `complete_file_write`  
**Purpose:** Completes a file write operation by updating block state from "writing" (3) to "data" (1). Handles merging with adjacent blocks if possible.  
**Arguments:** A5: pointer to file control block  
**Return value:** None (void)  
**RAM accessed:** 
- File control block fields: state (offset 0), block pointer (4), etc.
- Block directory structure  
**Call targets:** 
- 0x1F076 (get_block_pointer)
- 0x25354 (error handler)
- 0x7D8D0 (update_file_cache_state)
- 0x1F0AC (update_block_directory)  
**Algorithm:** 
1. Gets block pointer for current write position
2. Validates block type == 3 (writing)
3. Sets block type to 1 (data)
4. If next block is type 1 (data), merges them
5. Updates block directory
6. Sets file state to 2 (dirty)

### 5. Function at 0x7d8aa (init_file_cache)
**Entry:** 0x7d8aa  
**Suggested name:** `init_file_cache`  
**Purpose:** Initializes the file cache by clearing the file control block array and resetting cache index.  
**Arguments:** None  
**Return value:** None (void)  
**RAM accessed:** 
- 0x02016BC4: file control block array (608 bytes = 4 × 152)
- 0x02016E24: file cache index
- 0x02016E28: base directory path string  
**Call targets:** 
- 0x2DE50 (memset)  
**Algorithm:** 
1. Clears 608 bytes at 0x02016BC4
2. Resets cache index to 0
3. Clears first byte of base directory path

### 6. Function at 0x7d8d0 (update_file_cache_state)
**Entry:** 0x7d8d0  
**Suggested name:** `update_file_cache_state`  
**Purpose:** Updates the state of file control blocks in cache based on file handle and state code.  
**Arguments:** 
- fp@(8): file handle pointer
- fp@(12): state code (0=close, 1=open, 2=flush)  
**Return value:** None (void)  
**RAM accessed:** 
- 0x02016BC4: file control block array (4 entries)  
**Call targets:** 
- 0x25354 (error handler)  
**Algorithm:** 
1. Iterates through 4 file control blocks
2. For each block with matching file handle:
   - State 0: sets block offset 128 to -1 (closed)
   - State 1: sets block state to 1 (open)
   - State 2: clears block state (flushed)
   - Invalid state: calls error handler

### 7. Function at 0x7d93a (flush_file_cache)
**Entry:** 0x7d93a  
**Suggested name:** `flush_file_cache`  
**Purpose:** Flushes all blocks of a file by marking them as end markers (type 2).  
**Arguments:** A5: pointer to file control block  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure
- Block directory  
**Call targets:** 
- 0x7D8D0 (update_file_cache_state)
- 0x1E6F0 (get_file_info)
- 0x1F090 (get_block_pointer2)
- 0x1F0AC (update_block_directory)  
**Algorithm:** 
1. Sets file cache state to 2 (flush)
2. Gets file info (block count)
3. For each block:
   - Gets block pointer
   - Sets block type to 2 (end marker)
   - Sets block size to 1024
   - Updates block directory

### 8. Function at 0x7d9a2 (set_base_directory)
**Entry:** 0x7d9a2  
**Suggested name:** `set_base_directory`  
**Purpose:** Sets the base directory path for file operations.  
**Arguments:** fp@(8): pointer to directory path string  
**Return value:** None (void)  
**RAM accessed:** 
- 0x02016E28: base directory path string  
**Call targets:** 
- 0x2DCB0 (strcpy)  
**Algorithm:** 
1. Copies directory path to 0x02016E28

### 9. Function at 0x7d9bc (build_full_path)
**Entry:** 0x7d9bc  
**Suggested name:** `build_full_path`  
**Purpose:** Builds a full path by combining base directory with filename, ensures trailing '/'.  
**Arguments:** fp@(8): pointer to filename string  
**Return value:** None (void)  
**RAM accessed:** 
- 0x02016E28: base directory path string
- 0x02016E8C: pointer to end of base directory  
**Call targets:** 
- 0x2DCD4 (strlen)
- 0x25354 (error handler)  
**Algorithm:** 
1. Calculates total path length
2. Validates length < 100 chars
3. If filename doesn't start with '/', appends base directory
4. Appends filename
5. Ensures trailing '/'
6. Updates pointer to end of base directory

### 10. Function at 0x7da5e (get_file_info)
**Entry:** 0x7da5e  
**Suggested name:** `get_file_info`  
**Purpose:** Gets file information (size, modification time, etc.) from file control block.  
**Arguments:** 
- fp@(8): pointer to filename string
- fp@(12): pointer to info buffer (12 bytes)  
**Return value:** D0: boolean indicating if file is open (state == 3)  
**RAM accessed:** 
- File control block structure (offsets 140-152 for file info)  
**Call targets:** 
- 0x7D3A6 (lookup_file)  
**Algorithm:** 
1. Looks up file in cache
2. Copies 12 bytes of file info from offset 140
3. Returns true if file state == 3 (open)

### 11. Function at 0x7da96 (set_file_info)
**Entry:** 0x7da96  
**Suggested name:** `set_file_info`  
**Purpose:** Sets file information (size, modification time, etc.) in file control block.  
**Arguments:** 
- fp@(8): pointer to filename string
- fp@(12): pointer to info buffer (12 bytes)  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure (offsets 140-152 for file info)  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x25354 (error handler)
- 0x7D6CE (write_file_to_disk)  
**Algorithm:** 
1. Looks up file in cache
2. Validates file state == 2 (dirty)
3. Copies 12 bytes of file info to offset 140
4. Writes file to disk

### 12. Function at 0x7dade (close_file)
**Entry:** 0x7dade  
**Suggested name:** `close_file`  
**Purpose:** Closes a file by completing any pending write operations.  
**Arguments:** fp@(8): pointer to filename string  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x25354 (error handler)
- 0x7D7E6 (complete_file_write)  
**Algorithm:** 
1. Looks up file in cache
2. Validates file state == 3 (writing)
3. Completes file write operation

### 13. Function at 0x7db18 (search_directory)
**Entry:** 0x7db18  
**Suggested name:** `search_directory`  
**Purpose:** Searches directory for files matching criteria, with callback functions for filtering and processing.  
**Arguments:** 
- fp@(8): directory path string
- fp@(12): filter callback (returns non-zero to skip file)
- fp@(16): process callback (called for matching files)
- fp@(20): context pointer for callbacks  
**Return value:** D0: result from process callback or 0  
**RAM accessed:** 
- 0x020008F4: execution context stack
- File control block structure  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x1E6F0 (get_file_info)
- 0x1F076 (get_block_pointer)
- 0x2DCB0 (strcpy)
- 0x1F0AC (update_block_directory)
- 0x2DF1C (push_execution_context)
- 0x2D8D8 (pop_execution_context)  
**Algorithm:** 
1. Looks up directory file
2. Pushes execution context
3. Iterates through directory blocks
4. For each file entry:
   - Applies filter callback if provided
   - If matches, sets file state to 3 (open)
   - Calls process callback with file info
   - Updates block directory
5. Pops execution context
6. Returns result

### 14. Function at 0x7dd3e (create_file)
**Entry:** 0x7dd3e  
**Suggested name:** `create_file`  
**Purpose:** Creates a new file with initial data.  
**Arguments:** 
- fp@(8): filename string
- fp@(12): initial data buffer
- fp@(16): file info buffer (optional)
- fp@(20): parent directory handle  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x25354 (error handler)
- 0x1E386 (create_file_in_directory)
- 0x7DA96 (set_file_info)  
**Algorithm:** 
1. Looks up file in cache
2. Validates file state == 2 (dirty)
3. If no file info buffer provided, creates empty one
4. Creates file in directory
5. Sets file info

### 15. Function at 0x7ddc4 (delete_file)
**Entry:** 0x7ddc4  
**Suggested name:** `delete_file`  
**Purpose:** Deletes a file from the filesystem.  
**Arguments:** fp@(8): filename string  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structure  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x25354 (error handler)
- 0x7D7E6 (complete_file_write)
- 0x1E512 (remove_file_from_directory)  
**Algorithm:** 
1. Looks up file in cache
2. Validates file state == 3 (writing)
3. Completes any pending write
4. Removes file from directory

### 16. Function at 0x7de0a (rename_file)
**Entry:** 0x7de0a  
**Suggested name:** `rename_file`  
**Purpose:** Renames a file (moves it to new location).  
**Arguments:** 
- fp@(8): source filename
- fp@(12): destination filename  
**Return value:** None (void)  
**RAM accessed:** 
- File control block structures for both files
- 0x020008F4: execution context stack  
**Call targets:** 
- 0x7D3A6 (lookup_file)
- 0x25354 (error handler)
- 0x2DF1C (push_execution_context)
- 0x2D8D8 (pop_execution_context)
- 0x1E6F0 (get_file_info)
- 0x1E760 (update_file_info)
- 0x7D7E6 (complete_file_write)
- 0x7D6CE (write_file_to_disk)  
**Algorithm:** 
1. Looks up source file
2. Validates source state == 3 (writing)
3. Pushes execution context
4. Looks up destination file
5. Validates destination state == 2 (dirty)
6. Copies file info from source to destination
7. Completes source write
8. Writes destination to disk
9. Pops execution context

### 17. Function at 0x7df0a (get_next_filename)
**Entry:** 0x7df0a  
**Suggested name:** `get_next_filename`  
**Purpose:** Gets next filename in directory enumeration sequence.  
**Arguments:** A5: pointer to directory enumeration structure  
**Return value:** D0: filename index or -1 if at end  
**RAM accessed:** 
- Directory enumeration structure (offsets 44, 102)  
**Call targets:** 
- 0x206DE (read_directory_entry)  
**Algorithm:** 
1. Checks if current index >= directory size
2. If so, resets index and extends directory if needed
3. Returns current index and increments it

### 18. Function at 0x7df46 (validate_file_header)
**Entry:** 0x7df46  
**Suggested name:** `validate_file_header`  
**Purpose:** Validates a file header (magic number and size).  
**Arguments:** fp@(8): pointer to file handle structure  
**Return value:** D0: pointer to validated file header  
**RAM accessed:** 
- File handle structure
- File header at block -1000 (0xFC18)  
**Call targets:** 
- 0x25354 (error handler)
- 0x1F076 (get_block_pointer)
- 0x1F0AC (update_block_directory)  
**Algorithm:** 
1. Validates file magic (0x5FA87D27 for root)
2. Validates file size >= 4096 bytes
3. Reads header from block -1000
4. Validates header magic (0x1EADE460)
5. Validates header size matches file size
6. Returns header pointer or error

### 19. Function at 0x7dff2 (unfinished function)
**Entry:** 0x7dff2  
**Note:** This function appears incomplete in the disassembly (ends at 0x7E000 boundary). It seems to handle some file operation with multiple arguments.

## DATA REGIONS:
No significant data regions in this address range - all appears to be executable code.

## CORRECTIONS TO PRIOR ANALYSIS:
1. The function at 0x7d400 is `open_file`, not `file_open_or_create`
2. The function at 0x7d552 is `compact_file_blocks`, not misnamed
3. Multiple functions were missed: `complete_file_write`, `init_file_cache`, `update_file_cache_state`, `flush_file_cache`, `set_base_directory`, `build_full_path`, `get_file_info`, `set_file_info`, `close_file`, `search_directory`, `create_file`, `delete_file`, `rename_file`, `get_next_filename`, `validate_file_header`
4. All functions use standard C calling convention with LINK/UNLK
5. Error codes passed to 0x25354 (error handler) range from 0x05 to 0x19

## KEY INSIGHTS:
1. File control block is 152 bytes with state at offset 0, file handle at offset 4, filename at offset 8, cache pointer at offset 108, size at offset 112, etc.
2. File states: 0=closed/flushed, 1=open, 2=dirty, 3=writing
3. Block types: 1=data, 2=end marker, 3=free/writing
4. Directory search uses callbacks for filtering and processing
5. File operations use execution context stack (0x020008F4) for error recovery
6. Maximum path length is 100 characters including base directory

; === CHUNK 41: 0x7E000-0x7EC00 ===

Looking at this disassembly, I can see several issues with the prior analysis. Let me provide a corrected and more detailed analysis:

## CORRECTIONS TO PRIOR ANALYSIS:

1. **Address range**: The prior analysis said 0x7E000-0x7F800, but the disassembly shows 0x7E000-0x7EC00 (actually ends at 0x7EBF6 with more to come).

2. **Function at 0x7E000**: The prior analysis missed this function entirely. It's actually a file operation function that calls `bsrl 0x209c0` (likely `file_sync` or similar).

3. **Function names**: Many were too generic. I'll provide more specific names based on the actual operations.

## REFINED ANALYSIS:

### 1. `file_adjust_position` (0x7e000)
- **Entry**: 0x7e000
- **Purpose**: Adjusts a file's position pointer, likely after a read/write operation. Calls `bsrl 0x209c0` (file sync), then subtracts from a position field, then calls another function with offset -1000 (0xfffffc18).
- **Arguments**: 
  - `%fp@(8)`: File structure pointer
  - `%fp@(12)`: Adjustment value (subtracted from position)
  - `%fp@(16)`: Unknown parameter
- **Key operations**:
  - Calls `bsrl 0x209c0` (file sync)
  - Subtracts D0 from `%a0@(4)` (position field)
  - Calls `bsrl 0x1f0ac` with offset -1000
- **Hardware access**: None direct

### 2. `file_alloc_init` (0x7e02a) - CORRECTED
- **Entry**: 0x7e02a
- **Purpose**: Initializes a file allocation buffer structure (not a file handle). This is a buffer header for cached file data. Sets magic 0x1EADE460, allocates 0x400 (1024) bytes for the buffer, sets up page table header.
- **Arguments**:
  - `%fp@(8)`: Pointer to allocation structure (buffer header)
  - `%fp@(12)`: Source data structure with size info
  - `%fp@(16)`: Mode (1 or 2)
- **Key operations**:
  - Allocates 1024 bytes via `bsrl 0x2de50` (malloc wrapper)
  - Sets magic `0x1EADE460` at offset 0
  - Sets page table offset at offset 10 (0x0A) to 0x8A (138 bytes)
  - Initializes page table header: mode-dependent value (1 or 2) at offset 0, count=1 at offset 2
  - Sets initial file offset to -1000 (0xfffffc18) at offset 4
  - Copies sizes from source structure
- **Returns**: Initialized structure in A5
- **Called by**: 0x7e456

### 3. `get_page_table_entry` (0x7e0c0) - CORRECTED
- **Entry**: 0x7e0c0
- **Purpose**: Gets the current page table entry value from a file allocation structure. Returns the value at the current index in the page table.
- **Arguments**: `%fp@(8)`: File allocation structure pointer
- **Returns**: D0 = value from page table entry (likely a page number or disk address)
- **Key operations**:
  - Gets page table offset from `%a0@(10)`
  - Calculates page table address: base + offset
  - Reads current index from page table header word
  - Returns 32-bit value from page table entry at `index*8 + 4`
- **Called by**: 0x7e58e, 0x7e70a

### 4. `update_file_allocation` (0x7e0e6) - CORRECTED
- **Entry**: 0x7e0e6
- **Purpose**: Updates a file allocation structure with data from another structure. Used to copy buffer metadata between structures, possibly for cache management.
- **Arguments**:
  - `%fp@(8)`: Destination allocation structure
  - `%fp@(12)`: Source allocation structure
  - `%fp@(16)`: Flag (if non-zero, copies additional fields)
- **Key operations**:
  - Copies 4 bytes from source offset 0 to dest offset 20 (0x14)
  - If flag is set, copies source offsets 4 and 8 to dest offsets 24 (0x18) and 28 (0x1C)
  - Copies source offset 16 (0x10) to dest offset 32 (0x20)
  - If source has data at offset 20 (0x14), copies it to dest's buffer area
- **Called by**: 0x7e486, 0x7e7a2

### 5. `find_file_offset` (0x7e138) - CORRECTED
- **Entry**: 0x7e138
- **Purpose**: Locates a file offset within the page table and returns page information. Used to translate logical file offsets to physical page locations.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Logical file offset to find
  - `%fp@(16)`: Output: remain
  - `%fp@(20)`: Output: page_offset
  - `%fp@(24)`: Output: unknown (likely flags)
- **Returns**: D0 = success flag (1 if found, 0 if not)
- **Key operations**:
  - Special case for offset -1000 (0xfffffc18)
  - Validates offset is non-negative
  - Calls helper at 0x1df46 to get current page table
  - Walks page table entries to find containing range
  - Calculates remain and page_offset outputs
  - Updates file position if needed
- **Called by**: 0x7e88e

### 6. `insert_page_table_entry` (0x7e252) - CORRECTED
- **Entry**: 0x7e252
- **Purpose**: Inserts a new entry into the page table for a file allocation structure. Used when extending a file or allocating new pages.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: File offset for new entry
  - `%fp@(16)`: Size of new entry
  - `%fp@(20)`: Page number/disk address
- **Key operations**:
  - Gets page table pointer from structure
  - Validates offset matches expected next offset
  - If entry exists, extends it; otherwise creates new entry
  - Checks for buffer overflow (max 1024 bytes)
  - Updates page table count
- **Called by**: 0x7e5d0

### 7. `remove_page_table_entry` (0x7e2d8) - CORRECTED
- **Entry**: 0x7e2d8
- **Purpose**: Removes or truncates a page table entry. Used when deallocating file space or truncating files.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: File offset to remove from
  - `%fp@(16)`: Output: page_offset
- **Returns**: D0 = amount removed
- **Key operations**:
  - Gets page table pointer
  - Finds entry containing offset
  - Truncates or removes entry based on offset position
  - Special handling for offset -1000
  - Updates page table count
- **Called by**: 0x7e62e

### 8. `allocate_file_space` (0x7e386) - CORRECTED
- **Entry**: 0x7e386
- **Purpose**: Allocates space in a file, possibly extending it. Handles file growth and buffer allocation.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Size to allocate
  - `%fp@(16)`: Output structure for results
- **Key operations**:
  - Validates size (max 100 bytes? Actually checks against 100)
  - Validates offset range (0 to 0x40000000)
  - Calls file sync at 0x209e8
  - Allocates buffer via callback at offset 130 (0x82)
  - Updates file position
  - Calls `file_alloc_init` to initialize buffer
  - Updates output structure with results
- **Called by**: Unknown (likely file write operations)

### 9. `truncate_file` (0x7e512) and `truncate_file_at` (0x7e52a) - CORRECTED
- **Entry**: 0x7e512 (wrapper), 0x7e52a (main)
- **Purpose**: Truncates a file at specified offset. Handles both truncation to -1000 (clear) and arbitrary positions.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Truncation offset
- **Key operations**:
  - Validates offset range
  - Gets current page table via 0x1df46
  - Sets up execution context
  - Reads current page table entry
  - Loops through page table, removing/truncating entries
  - Updates file metadata
- **Called by**: 0x7e4e8, 0x7e51e

### 10. `read_file_data` (0x7e6f0) - CORRECTED
- **Entry**: 0x7e6f0
- **Purpose**: Reads data from a file allocation structure into an output buffer.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Output buffer structure
- **Key operations**:
  - Gets current page table via 0x1df46
  - Reads current page table entry via `get_page_table_entry`
  - Copies metadata to output structure
  - If output has buffer, copies data
  - Marks page table entry as accessed
- **Called by**: Unknown (likely file read operations)

### 11. `write_file_data` (0x7e760) - CORRECTED
- **Entry**: 0x7e760
- **Purpose**: Writes data to a file allocation structure from an input buffer.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Input buffer structure
- **Key operations**:
  - Validates input buffer size (< 100)
  - Gets current page table via 0x1df46
  - Calls `update_file_allocation` to copy data
  - Marks page table as modified (mode 2)
- **Called by**: Unknown (likely file write operations)

### 12. `file_io_operation` (0x7e80c) and wrappers (0x7e7c2, 0x7e7e6) - CORRECTED
- **Entry**: 0x7e80c (main), 0x7e7c2 (mode 0), 0x7e7e6 (mode 1)
- **Purpose**: Performs file I/O operations (read/write/seek). Main dispatcher for file operations.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Offset
  - `%fp@(16)`: Size
  - `%fp@(20)`: Buffer structure
  - `%fp@(24)`: Mode (0=read, 1=write, 3=seek)
- **Key operations**:
  - Mode 0 (read): Sets up for read operation
  - Mode 1 (write): Calls write function at 0x1f18e first
  - Mode 3 (seek): Sets up for seek operation
  - Main loop calls `find_file_offset` to locate position
  - Validates file magic (0x5FA87D27 for root)
  - Calls file callbacks at offsets 0xB4 and 0xB8
  - Handles buffer management and position updates
- **Called by**: 0x7e7d8, 0x7e7fe, 0x7eb72

### 13. `find_file_buffer` (0x7e970) - CORRECTED
- **Entry**: 0x7e970
- **Purpose**: Searches for a file buffer in the LRU cache by file identifier and offset.
- **Arguments**:
  - `%fp@(8)`: File identifier structure
  - `%fp@(12)`: File offset
  - `%fp@(16)`: Flag (if non-zero, promotes found buffer)
- **Returns**: D0 = pointer to buffer or NULL
- **Key operations**:
  - Walks LRU list starting at 0x2016e90 + 8
  - Compares file ID, offset, and position
  - Checks if buffer is valid (bit 7 set)
  - If found and flag set, promotes buffer in LRU
- **Called by**: Unknown (likely cache lookup)

### 14. `allocate_file_buffer` (0x7e9e8) - CORRECTED
- **Entry**: 0x7e9e8
- **Purpose**: Allocates a new file buffer from the LRU cache.
- **Arguments**:
  - `%fp@(8)`: File identifier structure (copied to buffer)
  - `%fp@(12)`: File offset
- **Returns**: D0 = pointer to allocated buffer
- **Key operations**:
  - Walks LRU free list
  - Finds buffer with use count 0
  - Sets buffer as active (bit 7), increments use count
  - Decrements free count at 0x2016e90+4
  - Copies file ID to buffer
  - Sets offset in buffer
  - Promotes buffer in LRU
- **Called by**: Unknown (likely cache miss handler)

### 15. `release_file_buffer` (0x7ea72) - CORRECTED
- **Entry**: 0x7ea72
- **Purpose**: Releases a file buffer back to the LRU cache.
- **Arguments**: `%fp@(8)`: Buffer pointer
- **Key operations**:
  - Validates buffer is in use (use count > 0, bit 7 set)
  - If buffer is dirty (bit 6), calls flush at 0x7eb1a
  - Clears active bit (7)
  - Resets buffer fields
  - Moves buffer to free list
  - Increments free count
- **Called by**: Unknown (likely when buffer evicted or file closed)

### 16. `flush_file_buffer` (0x7eb1a) - CORRECTED
- **Entry**: 0x7eb1a
- **Purpose**: Flushes a dirty file buffer to disk.
- **Arguments**: `%fp@(8)`: Buffer pointer
- **Key operations**:
  - Checks if buffer is dirty (bit 6)
  - Increments use count and dirty count
  - Sets up execution context
  - Calls `file_io_operation` with mode 3 (write)
  - Decrements counts on completion
  - Clears dirty bit
- **Called by**: 0x7ea0c, 0x7eab0

### 17. `search_file_buffer` (0x7ebcc) - INCOMPLETE
- **Entry**: 0x7ebcc
- **Purpose**: Searches for file buffers matching criteria (incomplete in this chunk).
- **Arguments**:
  - `%fp@(8)`: File identifier structure
  - `%fp@(12)`: Unknown
  - `%fp@(16)`: Unknown
- **Key operations**:
  - Gets LRU list head
  - Walks list comparing file IDs
  - More logic continues beyond 0x7ec00

## KEY DATA STRUCTURES:

1. **File Allocation Structure** (buffer header):
   - Offset 0: Magic 0x1EADE460
   - Offset 4: Unknown
   - Offset 8: File position
   - Offset 10: Page table offset (0x8A = 138)
   - Offset 36: Buffer offset (0x26 = 38)

2. **Page Table Header** (at buffer + offset):
   - Offset 0: Mode (1 or 2)
   - Offset 2: Entry count
   - Offset 4: First file offset (-1000 initially)

3. **Page Table Entry** (8 bytes each):
   - Offset 0: File offset
   - Offset 4: Page number/disk address

4. **LRU Buffer Structure** (at 0x2016e90):
   - Offset 0: List head
   - Offset 4: Free count
   - Offset 8: Active list head
   - Offset 20: Dirty count

5. **Buffer Entry** (linked list):
   - Offset 0: Next pointer
   - Offset 4: Previous pointer
   - Offset 8: File ID (12 bytes)
   - Offset 20: File offset
   - Offset 24: Unknown
   - Offset 28: Use count (word at 28)
   - Offset 30: Flags (byte at 30, bits: 6=dirty, 7=active)

## CALL RELATIONSHIPS:

```
file_io_operation (0x7e80c)
├── find_file_offset (0x7e138)
├── file callbacks (offsets 0xB4, 0xB8)
└── error handling

allocate_file_space (0x7e386)
├── file_alloc_init (0x7e02a)
└── update_file_allocation (0x7e0e6)

truncate_file_at (0x7e52a)
├── get_page_table_entry (0x7e0c0)
├── insert_page_table_entry (0x7e252)
├── remove_page_table_entry (0x7e2d8)
└── buffer management

flush_file_buffer (0x7eb1a)
└── file_io_operation (0x7e80c)
```

This region (0x7E000-0x7EC00) contains the core file buffer cache management system with LRU caching, page table management for file offsets, and I/O operations. The system supports 1024-byte pages with write-back caching and dirty flag management.

; === CHUNK 42: 0x7EC00-0x7F800 ===

Looking at this disassembly, I can see the prior analysis was mostly correct but had some inaccuracies in function boundaries and missed several key functions. Let me provide a corrected and refined analysis:

## CORRECTIONS AND REFINEMENTS:

The prior analysis correctly identified this as file buffer cache management, but missed several key functions and had some incorrect function boundaries. This range contains the **complete file buffer cache system** including LRU management, page allocation, and file I/O operations.

### Key Data Structure (File Buffer Cache Entry - 32 bytes):
Confirmed at 0x7ec76, 0x7ec78:
- 0x00: Next pointer (linked list)
- 0x04: Previous pointer  
- 0x08: File allocation structure pointer
- 0x0C: File offset (in bytes)
- 0x10: Size/status field
- 0x14: Buffer pointer (1024-byte page)
- 0x18: Reference count (word at 0x1C)
- 0x1C: Flags (byte at 0x1E)

## Functions in this range:

### 1. `cache_scan_for_write` (0x7ec00)
- **Entry**: 0x7ec00 (called from 0x7ebf6)
- **Purpose**: Scans cache for dirty pages that overlap with a write range and writes them back.
- **Arguments**: 
  - `%a4`: Current cache entry pointer
  - `%a5`: File allocation structure
  - `%d6`: Starting offset
  - `%d7`: Size
  - `%fp@(20)`: Callback function for writing dirty pages
- **Algorithm**: Iterates through cache entries (32-byte each), checks if entry belongs to same file, overlaps with write range, and is dirty (bit 7 at offset 0x1E), then calls callback.
- **Hardware**: None direct
- **Called by**: 0x7ebf6 (not in this range)

### 2. `cache_scan_for_file` (0x7ec3c)
- **Entry**: 0x7ec3c
- **Purpose**: Scans all cache entries for a specific file, calling a callback for each match.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Callback function
- **Algorithm**: Gets cache pointer from 0x2016e90, iterates through all entries, calls callback for entries matching the file.
- **Returns**: None
- **Called by**: 0x7f178, 0x7f1ee

### 3. `cache_init` (0x7ec88)
- **Entry**: 0x7ec88  
- **Purpose**: Initializes the file buffer cache with specified number of entries.
- **Arguments**: `%fp@(8)`: Number of cache entries (must be ≥6)
- **Algorithm**: 
  - Allocates main cache structure (24 bytes + n*32 bytes)
  - Sets up doubly-linked list of cache entries
  - Allocates 1024-byte buffer for each entry
  - Stores pointer at 0x2016e90 (global cache pointer)
- **Calls**: 0x25354 (error), 0x2d818 (malloc), 0x2d98c (malloc), 0x2d8ac (list_insert)
- **Returns**: None

### 4. `cache_read_pages` (0x7ed5a)
- **Entry**: 0x7ed5a
- **Purpose**: Reads/writes multiple pages (1024-byte blocks) from/to file.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Starting page number
  - `%fp@(16)`: Number of pages to read
  - `%fp@(20)`: Destination buffer
  - `%fp@(24)`: Write flag (0=read, 1=write)
- **Algorithm**: Loops through pages, calls cache_read_page or cache_write_page based on flag, then memcpy.
- **Calls**: 0x7f076 (cache_read_page), 0x7f090 (cache_write_page), 0x2dcf8 (memcpy)
- **Returns**: None

### 5. `cache_read` (0x7edd8) and `cache_write` (0x7edfa)
- **Entry**: 0x7edd8, 0x7edfa
- **Purpose**: Wrappers for `cache_read_pages` with appropriate write flag.
- **Arguments**: Same as cache_read_pages but without write flag parameter.
- **Returns**: None

### 6. `cache_read_bytes` (0x7ee1e)
- **Entry**: 0x7ee1e
- **Purpose**: Reads/writes arbitrary byte range (not page-aligned) from/to file.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Starting offset (bytes)
  - `%fp@(16)`: Number of bytes
  - `%fp@(20)`: Destination buffer
  - `%fp@(24)`: Write flag
- **Algorithm**: Handles partial first page, full middle pages, and partial last page using min() calculations.
- **Calls**: 0x2ded8 (min), 0x7f076 (cache_read_page), 0x2dcf8 (memcpy), 0x7f0ac (cache_release_page)
- **Returns**: None

### 7. `cache_read_byte_range` (0x7ef0a) and `cache_write_byte_range` (0x7ef2c)
- **Entry**: 0x7ef0a, 0x7ef2c
- **Purpose**: Wrappers for `cache_read_bytes` with appropriate write flag.
- **Arguments**: Same as cache_read_bytes but without write flag parameter.
- **Returns**: None

### 8. `cache_get_page` (0x7ef50)
- **Entry**: 0x7ef50
- **Purpose**: Gets a cache page for a file at specified offset, with optional allocation.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Page number
  - `%fp@(16)`: Allocation flag (0=don't allocate, 1=allocate)
- **Algorithm**: 
  - Checks cache usage vs. threshold (60 pages)
  - If cache full and no active pages, calls cache_flush (0x7f22a)
  - Searches for existing page via 0x7e970
  - If not found and allocation requested, creates new page via 0x7e9e8
  - Handles zero-filling new pages if needed
  - Updates reference counts
- **Calls**: 0x2e040 (get_time?), 0x7f22a (cache_flush), 0x7e970 (cache_find_page), 0x7e9e8 (cache_alloc_page), 0x2de50 (memset), 0x2df1c (setjmp), 0x1e80c (disk_read_page)
- **Returns**: Buffer pointer in %d0

### 9. `cache_read_page` (0x7f076) and `cache_write_page` (0x7f090)
- **Entry**: 0x7f076, 0x7f090
- **Purpose**: Wrappers for `cache_get_page` with appropriate allocation flag.
- **Arguments**: File allocation structure and page number.
- **Returns**: Buffer pointer

### 10. `cache_release_page` (0x7f0ac)
- **Entry**: 0x7f0ac
- **Purpose**: Releases a cache page with specified action.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Page number
  - `%fp@(16)`: Action (0=decrement ref, 1=mark dirty, 2=mark dirty and flush)
- **Algorithm**: 
  - Finds page via 0x7e970
  - Decrements reference count
  - Marks dirty if requested
  - If action=2, calls 0x1eb1a (cache_flush_page)
- **Calls**: 0x7e970 (cache_find_page), 0x1eb1a (cache_flush_page)
- **Returns**: None

### 11. `cache_flush_range` (0x7f13c)
- **Entry**: 0x7f13c
- **Purpose**: Flushes dirty pages in a range to disk.
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Starting offset
  - `%fp@(16)`: Size
  - `%fp@(20)`: Callback (0x1eb1a = cache_flush_page)
- **Algorithm**: Calls 0x1ebcc (cache_scan_for_write) with flush callback.
- **Calls**: 0x1ebcc (cache_scan_for_write)
- **Returns**: None

### 12. `cache_flush_file` (0x7f15c)
- **Entry**: 0x7f15c
- **Purpose**: Flushes entire file to disk.
- **Arguments**: File allocation structure
- **Algorithm**: Calls cache_flush_range with offset=-1000, size=0x400003e8 (huge range).
- **Calls**: 0x7f13c (cache_flush_range)
- **Returns**: None

### 13. `cache_invalidate_file` (0x7f178)
- **Entry**: 0x7f178
- **Purpose**: Invalidates all cache entries for a file.
- **Arguments**: File allocation structure
- **Algorithm**: Calls cache_scan_for_file with 0x1eb1a (cache_flush_page) callback.
- **Calls**: 0x1ec3c (cache_scan_for_file)
- **Returns**: None

### 14. `cache_truncate_range` (0x7f18e)
- **Entry**: 0x7f18e
- **Purpose**: Truncates a file range (marks as invalid).
- **Arguments**:
  - `%fp@(8)`: File allocation structure
  - `%fp@(12)`: Starting offset
  - `%fp@(16)`: Size
- **Algorithm**: 
  - Calls cache_flush_range twice (to flush dirty pages)
  - Then calls cache_scan_for_file with 0x1ea72 (cache_remove_page) callback
- **Calls**: 0x7f13c (cache_flush_range), 0x1ebcc (cache_scan_for_write), 0x1ea72 (cache_remove_page)
- **Returns**: None

### 15. `cache_truncate_file` (0x7f1d2)
- **Entry**: 0x7f1d2
- **Purpose**: Truncates entire file.
- **Arguments**: File allocation structure
- **Algorithm**: Calls cache_truncate_range with offset=-1000, size=0x400003e8.
- **Calls**: 0x7f18e (cache_truncate_range)
- **Returns**: None

### 16. `cache_close_file` (0x7f1ee)
- **Entry**: 0x7f1ee
- **Purpose**: Closes a file, flushing and invalidating cache.
- **Arguments**: File allocation structure
- **Algorithm**: 
  - If file has parent (offset 0x3C), invalidates parent first
  - Invalidates file three times (ensures all pages flushed)
  - Calls cache_scan_for_file with 0x1ea72 (cache_remove_page)
- **Calls**: 0x7f178 (cache_invalidate_file), 0x1ec3c (cache_scan_for_file)
- **Returns**: None

### 17. `cache_flush` (0x7f22a)
- **Entry**: 0x7f22a
- **Purpose**: Flushes all dirty pages in cache to free space.
- **Arguments**: None
- **Algorithm**: 
  - Gets current time via 0x2e040
  - Stores at cache structure offset 0x10
  - Iterates through all cache entries
  - If entry is dirty (bit 6) and unreferenced (refcount=0), flushes it
- **Calls**: 0x2e040 (get_time), 0x1eb1a (cache_flush_page)
- **Returns**: None

### 18. `file_seek` (0x7f278)
- **Entry**: 0x7f278
- **Purpose**: Seeks to position in file, handling cache and disk I/O.
- **Arguments**:
  - `%fp@(8)`: File handle structure
  - `%fp@(12)`: Offset
  - `%fp@(16)`: Mode (0=absolute, 1=relative, 2=end)
- **Algorithm**: 
  - Gets file allocation structure from offset 0x12
  - Calculates page numbers
  - Uses setjmp for error handling
  - Handles dirty page flushing
  - Updates file position and allocation info
  - Reads from disk if needed
- **Calls**: 0x2df1c (setjmp), 0x1e7e6 (disk_write_page), 0x1e52a (file_extend), 0x1e7c2 (disk_read_page)
- **Returns**: Success/failure in %d0

### 19. `file_read_write` (0x7f3e0)
- **Entry**: 0x7f3e0
- **Purpose**: Reads/writes data to/from file.
- **Arguments**:
  - `%fp@(8)`: Destination/source buffer
  - `%fp@(12)`: Element size
  - `%fp@(16)`: Count
  - `%fp@(20)`: File handle
  - `%fp@(24)`: Write flag (0=read, 1=write)
- **Algorithm**: 
  - Calculates total bytes = element size × count
  - Gets file allocation structure
  - Handles file extension if writing past EOF
  - Processes data in chunks: buffer cache, then direct disk I/O
  - Uses setjmp for error handling
- **Calls**: 0x2df1c (setjmp), 0x1e52a (file_extend), 0x7f278 (file_seek), 0x2dcf8 (memcpy), 0x2ded8 (min), 0x1e80c (disk_read_page)
- **Returns**: Number of elements processed

### 20. `file_flush` (0x7f620)
- **Entry**: 0x7f620
- **Purpose**: Flushes file buffers to disk.
- **Arguments**: File handle
- **Algorithm**: 
  - Gets file allocation structure
  - If file size changed (bit 5), writes directory entry
  - Uses setjmp for error handling
- **Calls**: 0x2df1c (setjmp), 0x1e6f0 (read_directory_entry), 0x1e760 (write_directory_entry)
- **Returns**: Success/failure

### 21. `file_open` (0x7f6b8)
- **Entry**: 0x7f6b8
- **Purpose**: Opens a file with specified mode.
- **Arguments**:
  - `%fp@(8)`: Directory entry pointer
  - `%fp@(12)`: Mode (0=read, 1=write, 2=read/write)
- **Algorithm**: 
  - Allocates file handle structure
  - Sets up file allocation structure
  - Initializes buffer pointers
  - Handles different open modes
  - Uses setjmp for error handling
- **Calls**: 0x1e6f0 (read_directory_entry), 0x28544 (allocate_file_handle), 0x2d818 (malloc), 0x2d98c (malloc), 0x1e760 (write_directory_entry), 0x209e8 (get_current_time)
- **Returns**: File handle pointer or NULL

## Key Observations:

1. **Cache Structure**: Global cache pointer at 0x2016e90 points to a 24-byte header followed by N×32-byte entries.

2. **Page Size**: 1024 bytes (0x400), confirmed at 0x7ed76, 0x7ed7a, etc.

3. **Error Handling**: Uses setjmp/longjmp (0x2df1c) for disk I/O errors.

4. **LRU Management**: Reference counting with dirty flag management.

5. **File Operations**: Complete read/write/seek/flush/truncate operations with cache coherence.

The prior analysis missed functions 0x7f278 (file_seek), 0x7f3e0 (file_read_write), 0x7f620 (file_flush), and 0x7f6b8 (file_open), which are critical file I/O operations. It also incorrectly identified some function boundaries and missed the detailed algorithms for cache management.

; === CHUNK 43: 0x7F800-0x80000 ===

Looking at this disassembly from 0x7F800 to 0x80000, I can see it's a continuation of the PostScript interpreter's stream/file I/O subsystem. Here's my refined analysis:

## FUNCTIONS:

### 1. 0x7F800 - `stream_cleanup_and_free` (or `fclose` wrapper)
**Entry:** 0x7F800
**What it does:** Cleans up stream resources. Tests fp@(-4) (likely a stream structure pointer), and if non-zero, frees buffers at offsets 8 and fp@(-8), then calls 0x28584 (likely free the stream structure itself). Finally calls 0x25354 with fp@(-36) as argument (error handling).
**Arguments:** Stream pointer in fp@(-4)
**Returns:** None (void function)
**Hardware:** None directly
**Cross-refs:** Calls 0x2DF1C, 0x2DB6C (x2), 0x28584, 0x25354
**Callers:** Likely called from stream close operations

### 2. 0x7F86E - `allocate_stream_buffer`
**Entry:** 0x7F86E
**What it does:** Allocates a buffer for stream I/O. Takes size parameter (fp@(16)), rounds up to next 1024-byte boundary (adds 1023, shifts right 10), calls allocation function at 0x2DEC8. Then calls 0x1DD3E to initialize the buffer.
**Arguments:** Three args: fp@(8)=stream, fp@(12)=?, fp@(16)=size
**Returns:** Buffer pointer in D0 or NULL on error
**Hardware:** None directly
**Cross-refs:** Calls 0x1DA5E, 0x25354, 0x2DEC8, 0x1DD3E, 0x1F6B8
**Algorithm:** size = (size + 1023) >> 10 (convert bytes to 1K pages)

### 3. 0x7F8E0 - `stream_getc` (get character from stream)
**Entry:** 0x7F8E0
**What it does:** Reads a byte from a buffered stream. A5 points to stream structure, A4 points to buffer structure at offset 18. Checks EOF flag (bit 4) and error flag (bit 3) at offset 12. If buffer empty, calls 0x7F278 to refill buffer. Returns byte (0-255) or -1 on EOF/error.
**Arguments:** Stream pointer in A5 (fp@(8))
**Returns:** Byte in D0 (0-255) or -1
**Hardware:** None directly
**Cross-refs:** Calls 0x7F278 (low-level read), 0x2DED8 (min function)
**Structure:** Stream has: offset 0=bytes left in buffer, 4=current read pointer, 8=buffer start, 12=status flags, 18=buffer structure pointer

### 4. 0x7F966 - `stream_putc` (put character to stream)
**Entry:** 0x7F966
**What it does:** Writes a byte to a buffered output stream. Similar to getc but for output. Calls 0x7F278 with mode 2 (write). Sets "dirty" flag (bit 6) at offset 28 in buffer structure.
**Arguments:** fp@(8)=byte value, fp@(12)=stream pointer
**Returns:** Byte written or -1 on error
**Hardware:** None directly
**Cross-refs:** Calls 0x7F278
**Note:** Uses fp@(11) for byte (low byte of 32-bit argument)

### 5. 0x7F9CE - `stream_seek_set` (absolute seek)
**Entry:** 0x7F9CE
**What it does:** Wrapper for seek with SEEK_SET (0). Passes 0 as first argument to 0x1F3E0 (the actual seek implementation).
**Arguments:** fp@(8)=stream, fp@(12)=offset_high, fp@(16)=offset_low, fp@(20)=whence (ignored, forced to 0)
**Returns:** Result from 0x1F3E0
**Cross-refs:** Calls 0x1F3E0

### 6. 0x7F9F0 - `stream_seek_cur` (relative seek)
**Entry:** 0x7F9F0
**What it does:** Wrapper for seek with SEEK_CUR (1). Passes 1 as first argument to 0x1F3E0.
**Arguments:** Same as above
**Returns:** Result from 0x1F3E0
**Cross-refs:** Calls 0x1F3E0

### 7. 0x7FA14 - `stream_ungetc` (push back character)
**Entry:** 0x7FA14
**What it does:** Implements ungetc functionality. Backs up stream position by 1 byte if possible. Clears EOF flag (bit 4). Returns the byte pushed back or -1 if cannot unget.
**Arguments:** fp@(8)=byte to push back, fp@(12)=stream
**Returns:** Byte or -1
**Cross-refs:** Calls 0x7F278
**Algorithm:** If read pointer > buffer start, just decrement pointer. Otherwise, seek back 1 byte in underlying file.

### 8. 0x7FA74 - `stream_flush` (flush output buffer)
**Entry:** 0x7FA74
**What it does:** Flushes output buffer by calling 0x7FB44 with arguments: stream, 0, 2 (SEEK_END). This forces buffer to be written.
**Arguments:** fp@(8)=stream
**Returns:** Result from seek
**Cross-refs:** Calls 0x7FB44

### 9. 0x7FA90 - `stream_sync` (sync position)
**Entry:** 0x7FA90
**What it does:** Synchronizes stream position with underlying file. Calculates current file position (buffer offset + buffer position), calls 0x7F278 with mode 1 (SEEK_CUR) and offset 0 to sync, then resets buffer count to 0.
**Arguments:** fp@(8)=stream
**Returns:** 0 on success, -1 on error
**Cross-refs:** Calls 0x7F278

### 10. 0x7FADA - `stream_close_internal`
**Entry:** 0x7FADA
**What it does:** Internal stream close function. First syncs stream (0x7FA90), then flushes (0x1F620), frees buffer structure (0x2DB6C), frees stream buffer (0x2DB6C), and finally frees stream structure itself (0x28584).
**Arguments:** fp@(8)=stream
**Returns:** Error code from sync/flush operations
**Cross-refs:** Calls 0x7FA90, 0x1F620, 0x2DB6C (x2), 0x28584

### 11. 0x7FB3A - `stream_error_stub`
**Entry:** 0x7FB3A
**What it does:** Simple stub that always returns -1. Likely a placeholder for unimplemented stream operations.
**Arguments:** None
**Returns:** -1
**Cross-refs:** None

### 12. 0x7FB44 - `stream_seek_implementation`
**Entry:** 0x7FB44
**What it does:** Main seek implementation. Handles SEEK_SET (0), SEEK_CUR (1), and SEEK_END (2). For SEEK_CUR, adds current buffer position; for SEEK_END, adds file size. Handles buffered I/O by checking if seek is within current buffer range.
**Arguments:** fp@(8)=stream, fp@(12)=offset, fp@(16)=whence
**Returns:** 0 on success, -1 on error
**Cross-refs:** Calls 0x2DED8 (min), 0x7F278
**Algorithm:** Complex logic for handling seeks within buffered data vs. requiring actual file seek.

### 13. 0x7FC08 - `stream_tell` (get current position)
**Entry:** 0x7FC08
**What it does:** Returns current file position = buffer offset + (current pointer - buffer start).
**Arguments:** fp@(8)=stream
**Returns:** Current position in D0
**Cross-refs:** None

### 14. 0x7FC2C - `stream_get_error`
**Entry:** 0x7FC2C
**What it does:** Returns error code from stream structure at offset 22.
**Arguments:** fp@(8)=stream
**Returns:** Error code in D0
**Cross-refs:** None

### 15. 0x7FC3C - `stream_copy_buffer_info`
**Entry:** 0x7FC3C
**What it does:** Copies buffer information from stream to destination. Copies 12 bytes from stream's buffer structure (offset 18) to destination pointer.
**Arguments:** fp@(8)=stream, fp@(12)=dest pointer
**Returns:** None (void)
**Cross-refs:** None

### 16. 0x7FC56 - `stream_set_buffer_size`
**Entry:** 0x7FC56
**What it does:** Changes buffer size for a stream. Calculates new size in 1K pages, syncs and flushes stream, then reallocates buffer if size changed.
**Arguments:** fp@(8)=stream
**Returns:** 0 on success, -1 on error
**Cross-refs:** Calls 0x7FA90, 0x1F620, 0x2DF1C, 0x1E52A
**Note:** Saves/restores execution context (0x20008F4) during reallocation.

### 17. 0x7FD1C - DATA: Stream function table (16 entries × 4 bytes)
**Address:** 0x7FD1C
**Size:** 64 bytes (16 × 4)
**Format:** Array of function pointers, likely a vtable for stream operations
**Contents:** 
0x7F8E0 (getc), 0x00088480 (??), 0x7F9CE (seek_set), 0x00088494 (??),
0x7FA14 (ungetc), 0x7FA74 (flush), 0x7FADA (close), 0x7FB3A (error_stub),
0x00088480 (??), 0x00088480 (??), 0x7FB44 (seek), 0x7FC08 (tell),
0x7FD84 (?? string "File"), ...

### 18. 0x7FD84 - STRING: "File"
**Address:** 0x7FD84
**Size:** 8 bytes
**Content:** "File" followed by null bytes
**Note:** Likely used for error messages or logging

### 19. 0x7FD90 - `file_stream_init`
**Entry:** 0x7FD90
**What it does:** Initializes a file stream. Calls 0x251E0, then 0x1EC88 with stream pointer, then 0x1D8AA.
**Arguments:** fp@(8)=stream pointer
**Returns:** Unknown
**Cross-refs:** Calls 0x251E0, 0x1EC88, 0x1D8AA

### 20. 0x7FDB0 - `allocate_stream_structure`
**Entry:** 0x7FDB0
**What it does:** Allocates a stream structure (24 bytes) via error handler 0x25354.
**Arguments:** None
**Returns:** Pointer to allocated structure or NULL
**Cross-refs:** Calls 0x25354

### 21. 0x7FDC4 - `initialize_root_directory`
**Entry:** 0x7FDC4
**What it does:** Initializes filesystem root directory structure. Sets magic number 0x5FA87D27, sets up directory entries, allocates space, and initializes various fields including free page list and timestamps.
**Arguments:** fp@(8)=root directory structure pointer
**Returns:** None (void)
**Cross-refs:** Calls 0x80590, 0x80800, 0x807CA, 0x2DCF8, 0x2E040, 0x2E094, 0x8089E, 0x20FD0
**Key operations:** Sets up directory with 10-entry overhead, manages free space, initializes timestamps.

### 22. 0x7FE9C - `create_file_entry`
**Entry:** 0x7FE9C
**What it does:** Creates a new file entry in directory. Allocates space via 0x809E8, calculates size in bytes (pages × 1024), sets up file structure.
**Arguments:** fp@(8)=dir pointer, fp@(12)=file entry pointer, fp@(16)=page count, fp@(20)=?
**Returns:** File entry pointer in D0
**Cross-refs:** Calls 0x809E8, 0x1E386

### 23. 0x7FEE8 - `read_directory_entry`
**Entry:** 0x7FEE8
**What it does:** Reads a directory entry from disk. Uses multiple helper functions to read directory structure and entry data.
**Arguments:** fp@(8)=directory pointer
**Returns:** Unknown
**Cross-refs:** Calls 0x1E6F0, 0x1D9A2, 0x1D9BC, 0x1DA96

### 24. 0x7FF44 - `allocate_contiguous_pages`
**Entry:** 0x7FF44
**What it does:** Allocates contiguous pages from free page list. Searches free list for block of requested size, with special handling for files already having some allocated pages (continuation allocation).
**Arguments:** fp@(8)=file structure, fp@(12)=result pointer, fp@(16)=page count
**Returns:** Number of pages allocated (0 if failed)
**Cross-refs:** Accesses 0x2016E98 (free page list head)
**Algorithm:** Linear search through free page blocks, tries to allocate at existing file end if possible for contiguous extension.

## DATA REGIONS:

### 0x7FD1C-0x7FD83: Stream operation function table
64 bytes containing 16 function pointers, likely a dispatch table for stream operations.

### 0x7FD84-0x7FD8B: String "File"
8 bytes: "File" with padding.

### 0x7FD8C-0x7FD8F: Padding/alignment
4 bytes of zeros.

## CORRECTIONS TO PRIOR ANALYSIS:

1. The prior analysis correctly identified most functions but missed the data regions at 0x7FD1C-0x7FD8F.
2. Function 0x7FC56 is `stream_set_buffer_size`, not mentioned in prior analysis.
3. The region contains significant filesystem code (root dir init, file creation, page allocation) not just stream I/O.
4. The seek implementation (0x7FB44) is more complex than initially described, handling buffered seeks intelligently.

## KEY INSIGHTS:

1. **Stream Structure:** Streams have buffer structures at offset 18, with buffer info including size, position, and dirty flags.
2. **Buffer Management:** Buffer size is in 1K pages, with rounding: `(size + 1023) >> 10`.
3. **Error Handling:** Stream errors stored at offset 22, with bits at offset 12 for EOF (bit 4) and error (bit 3).
4. **Filesystem Integration:** This region bridges stream I/O with filesystem operations (directory management, page allocation).
5. **Contiguous Allocation:** The page allocator tries to maintain contiguity for files, important for performance on this SCSI-based system.

The code shows sophisticated buffered I/O with seek optimization, proper error handling, and tight integration with the custom filesystem.