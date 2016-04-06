
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 17 37 10 80       	mov    $0x80103717,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 68 84 10 	movl   $0x80108468,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 31 4e 00 00       	call   80104e7f <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 de 4d 00 00       	call   80104ea0 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 f9 4d 00 00       	call   80104f02 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 a9 4a 00 00       	call   80104bcd <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 81 4d 00 00       	call   80104f02 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 6f 84 10 80 	movl   $0x8010846f,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 c9 25 00 00       	call   801027a1 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 80 84 10 80 	movl   $0x80108480,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 8c 25 00 00       	call   801027a1 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 87 84 10 80 	movl   $0x80108487,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 5f 4c 00 00       	call   80104ea0 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 03 4a 00 00       	call   80104ca5 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 54 4c 00 00       	call   80104f02 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 c1 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 e0 4a 00 00       	call   80104ea0 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 8e 84 10 80 	movl   $0x8010848e,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 5a 03 00 00       	call   80100750 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec 97 84 10 80 	movl   $0x80108497,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 84 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 ca 49 00 00       	call   80104f02 <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 9e 84 10 80 	movl   $0x8010849e,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 ad 84 10 80 	movl   $0x801084ad,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 bd 49 00 00       	call   80104f51 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 af 84 10 80 	movl   $0x801084af,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x11c>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 0c 4b 00 00       	call   801051c3 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 90 10 80       	mov    0x80109000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 0e 4a 00 00       	call   801050f4 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 d3 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 ba fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 a6 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 90 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 87 fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 30 63 00 00       	call   80106aab <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 24 63 00 00       	call   80106aab <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 18 63 00 00       	call   80106aab <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 0b 63 00 00       	call   80106aab <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 1f fe ff ff       	call   801005ca <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801007ba:	e8 e1 46 00 00       	call   80104ea0 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 37 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 64                	je     8010083a <consoleintr+0x8d>
801007d6:	e9 91 00 00 00       	jmp    8010086c <consoleintr+0xbf>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 55                	je     8010083a <consoleintr+0x8d>
801007e5:	e9 82 00 00 00       	jmp    8010086c <consoleintr+0xbf>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 59 45 00 00       	call   80104d48 <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100816:	a1 38 08 11 80       	mov    0x80110838,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 3c 08 11 80       	mov    0x8011083c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100831:	3c 0a                	cmp    $0xa,%al
80100833:	75 bf                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100835:	e9 c1 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083a:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100840:	a1 38 08 11 80       	mov    0x80110838,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 3c 08 11 80       	mov    0x8011083c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100856:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010085d:	e8 ee fe ff ff       	call   80100750 <consputc>
      }
      break;
80100862:	e9 94 00 00 00       	jmp    801008fb <consoleintr+0x14e>
80100867:	e9 8f 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100870:	0f 84 84 00 00 00    	je     801008fa <consoleintr+0x14d>
80100876:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
8010087c:	a1 34 08 11 80       	mov    0x80110834,%eax
80100881:	29 c2                	sub    %eax,%edx
80100883:	89 d0                	mov    %edx,%eax
80100885:	83 f8 7f             	cmp    $0x7f,%eax
80100888:	77 70                	ja     801008fa <consoleintr+0x14d>
        c = (c == '\r') ? '\n' : c;
8010088a:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010088e:	74 05                	je     80100895 <consoleintr+0xe8>
80100890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100893:	eb 05                	jmp    8010089a <consoleintr+0xed>
80100895:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
8010089d:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 3c 08 11 80    	mov    %edx,0x8011083c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 b4 07 11 80    	mov    %al,-0x7feef84c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008d5:	8b 15 34 08 11 80    	mov    0x80110834,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008e7:	a3 38 08 11 80       	mov    %eax,0x80110838
          wakeup(&input.r);
801008ec:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
801008f3:	e8 ad 43 00 00       	call   80104ca5 <wakeup>
        }
      }
      break;
801008f8:	eb 00                	jmp    801008fa <consoleintr+0x14d>
801008fa:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
801008fb:	8b 45 08             	mov    0x8(%ebp),%eax
801008fe:	ff d0                	call   *%eax
80100900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100907:	0f 89 b7 fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
8010090d:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100914:	e8 e9 45 00 00       	call   80104f02 <release>
}
80100919:	c9                   	leave  
8010091a:	c3                   	ret    

8010091b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010091b:	55                   	push   %ebp
8010091c:	89 e5                	mov    %esp,%ebp
8010091e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100921:	8b 45 08             	mov    0x8(%ebp),%eax
80100924:	89 04 24             	mov    %eax,(%esp)
80100927:	e8 7d 10 00 00       	call   801019a9 <iunlock>
  target = n;
8010092c:	8b 45 10             	mov    0x10(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100939:	e8 62 45 00 00       	call   80104ea0 <acquire>
  while(n > 0){
8010093e:	e9 aa 00 00 00       	jmp    801009ed <consoleread+0xd2>
    while(input.r == input.w){
80100943:	eb 42                	jmp    80100987 <consoleread+0x6c>
      if(proc->killed){
80100945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010094b:	8b 40 24             	mov    0x24(%eax),%eax
8010094e:	85 c0                	test   %eax,%eax
80100950:	74 21                	je     80100973 <consoleread+0x58>
        release(&input.lock);
80100952:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100959:	e8 a4 45 00 00       	call   80104f02 <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 f2 0e 00 00       	call   8010185b <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 07 11 	movl   $0x80110780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
80100982:	e8 46 42 00 00       	call   80104bcd <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 34 08 11 80    	mov    0x80110834,%edx
8010098d:	a1 38 08 11 80       	mov    0x80110838,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 34 08 11 80       	mov    0x80110834,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 34 08 11 80    	mov    %edx,0x80110834
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
801009ae:	0f be c0             	movsbl %al,%eax
801009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009b4:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009b8:	75 19                	jne    801009d3 <consoleread+0xb8>
      if(n < target){
801009ba:	8b 45 10             	mov    0x10(%ebp),%eax
801009bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009c0:	73 0f                	jae    801009d1 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009c2:	a1 34 08 11 80       	mov    0x80110834,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 34 08 11 80       	mov    %eax,0x80110834
      }
      break;
801009cf:	eb 26                	jmp    801009f7 <consoleread+0xdc>
801009d1:	eb 24                	jmp    801009f7 <consoleread+0xdc>
    }
    *dst++ = c;
801009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801009d6:	8d 50 01             	lea    0x1(%eax),%edx
801009d9:	89 55 0c             	mov    %edx,0xc(%ebp)
801009dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801009df:	88 10                	mov    %dl,(%eax)
    --n;
801009e1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009e5:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009e9:	75 02                	jne    801009ed <consoleread+0xd2>
      break;
801009eb:	eb 0a                	jmp    801009f7 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009ed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f1:	0f 8f 4c ff ff ff    	jg     80100943 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
801009f7:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801009fe:	e8 ff 44 00 00       	call   80104f02 <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 4d 0e 00 00       	call   8010185b <ilock>

  return target - n;
80100a0e:	8b 45 10             	mov    0x10(%ebp),%eax
80100a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a14:	29 c2                	sub    %eax,%edx
80100a16:	89 d0                	mov    %edx,%eax
}
80100a18:	c9                   	leave  
80100a19:	c3                   	ret    

80100a1a <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a1a:	55                   	push   %ebp
80100a1b:	89 e5                	mov    %esp,%ebp
80100a1d:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a20:	8b 45 08             	mov    0x8(%ebp),%eax
80100a23:	89 04 24             	mov    %eax,(%esp)
80100a26:	e8 7e 0f 00 00       	call   801019a9 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a32:	e8 69 44 00 00       	call   80104ea0 <acquire>
  for(i = 0; i < n; i++)
80100a37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a3e:	eb 1d                	jmp    80100a5d <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a46:	01 d0                	add    %edx,%eax
80100a48:	0f b6 00             	movzbl (%eax),%eax
80100a4b:	0f be c0             	movsbl %al,%eax
80100a4e:	0f b6 c0             	movzbl %al,%eax
80100a51:	89 04 24             	mov    %eax,(%esp)
80100a54:	e8 f7 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a60:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a63:	7c db                	jl     80100a40 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a65:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a6c:	e8 91 44 00 00       	call   80104f02 <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 df 0d 00 00       	call   8010185b <ilock>

  return n;
80100a7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a7f:	c9                   	leave  
80100a80:	c3                   	ret    

80100a81 <consoleinit>:

void
consoleinit(void)
{
80100a81:	55                   	push   %ebp
80100a82:	89 e5                	mov    %esp,%ebp
80100a84:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a87:	c7 44 24 04 b3 84 10 	movl   $0x801084b3,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a96:	e8 e4 43 00 00       	call   80104e7f <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 bb 84 10 	movl   $0x801084bb,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100aaa:	e8 d0 43 00 00       	call   80104e7f <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 ec 11 11 80 1a 	movl   $0x80100a1a,0x801111ec
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 e8 11 11 80 1b 	movl   $0x8010091b,0x801111e8
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 db 32 00 00       	call   80103db4 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 70 1e 00 00       	call   8010295d <ioapicenable>
}
80100aed:	c9                   	leave  
80100aee:	c3                   	ret    

80100aef <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100aef:	55                   	push   %ebp
80100af0:	89 e5                	mov    %esp,%ebp
80100af2:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100af8:	e8 13 29 00 00       	call   80103410 <begin_op>
  if((ip = namei(path)) == 0){
80100afd:	8b 45 08             	mov    0x8(%ebp),%eax
80100b00:	89 04 24             	mov    %eax,(%esp)
80100b03:	e8 fe 18 00 00       	call   80102406 <namei>
80100b08:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b0f:	75 0f                	jne    80100b20 <exec+0x31>
    end_op();
80100b11:	e8 7e 29 00 00       	call   80103494 <end_op>
    return -1;
80100b16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1b:	e9 e8 03 00 00       	jmp    80100f08 <exec+0x419>
  }
  ilock(ip);
80100b20:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b23:	89 04 24             	mov    %eax,(%esp)
80100b26:	e8 30 0d 00 00       	call   8010185b <ilock>
  pgdir = 0;
80100b2b:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b32:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b39:	00 
80100b3a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b41:	00 
80100b42:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b4f:	89 04 24             	mov    %eax,(%esp)
80100b52:	e8 11 12 00 00       	call   80101d68 <readi>
80100b57:	83 f8 33             	cmp    $0x33,%eax
80100b5a:	77 05                	ja     80100b61 <exec+0x72>
    goto bad;
80100b5c:	e9 7b 03 00 00       	jmp    80100edc <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
80100b61:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b67:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6c:	74 05                	je     80100b73 <exec+0x84>
    goto bad;
80100b6e:	e9 69 03 00 00       	jmp    80100edc <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
80100b73:	e8 84 70 00 00       	call   80107bfc <setupkvm>
80100b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b7f:	75 05                	jne    80100b86 <exec+0x97>
    goto bad;
80100b81:	e9 56 03 00 00       	jmp    80100edc <exec+0x3ed>

  // Load program into memory.
  sz = 0;
80100b86:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b8d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b94:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b9d:	e9 cb 00 00 00       	jmp    80100c6d <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ba5:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bac:	00 
80100bad:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb1:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bbb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bbe:	89 04 24             	mov    %eax,(%esp)
80100bc1:	e8 a2 11 00 00       	call   80101d68 <readi>
80100bc6:	83 f8 20             	cmp    $0x20,%eax
80100bc9:	74 05                	je     80100bd0 <exec+0xe1>
      goto bad;
80100bcb:	e9 0c 03 00 00       	jmp    80100edc <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
80100bd0:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bd6:	83 f8 01             	cmp    $0x1,%eax
80100bd9:	74 05                	je     80100be0 <exec+0xf1>
      continue;
80100bdb:	e9 80 00 00 00       	jmp    80100c60 <exec+0x171>
    if(ph.memsz < ph.filesz)
80100be0:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be6:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bec:	39 c2                	cmp    %eax,%edx
80100bee:	73 05                	jae    80100bf5 <exec+0x106>
      goto bad;
80100bf0:	e9 e7 02 00 00       	jmp    80100edc <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 b1 73 00 00       	call   80107fca <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	75 05                	jne    80100c27 <exec+0x138>
      goto bad;
80100c22:	e9 b5 02 00 00       	jmp    80100edc <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c27:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2d:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c33:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c41:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c44:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c4f:	89 04 24             	mov    %eax,(%esp)
80100c52:	e8 88 72 00 00       	call   80107edf <loaduvm>
80100c57:	85 c0                	test   %eax,%eax
80100c59:	79 05                	jns    80100c60 <exec+0x171>
      goto bad;
80100c5b:	e9 7c 02 00 00       	jmp    80100edc <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c60:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c64:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c67:	83 c0 20             	add    $0x20,%eax
80100c6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6d:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c74:	0f b7 c0             	movzwl %ax,%eax
80100c77:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7a:	0f 8f 22 ff ff ff    	jg     80100ba2 <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c80:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c83:	89 04 24             	mov    %eax,(%esp)
80100c86:	e8 54 0e 00 00       	call   80101adf <iunlockput>
  end_op();
80100c8b:	e8 04 28 00 00       	call   80103494 <end_op>
  ip = 0;
80100c90:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c9a:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100ca4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ca7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100caa:	05 00 20 00 00       	add    $0x2000,%eax
80100caf:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cbd:	89 04 24             	mov    %eax,(%esp)
80100cc0:	e8 05 73 00 00       	call   80107fca <allocuvm>
80100cc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cc8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ccc:	75 05                	jne    80100cd3 <exec+0x1e4>
    goto bad;
80100cce:	e9 09 02 00 00       	jmp    80100edc <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cd3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd6:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ce2:	89 04 24             	mov    %eax,(%esp)
80100ce5:	e8 10 75 00 00       	call   801081fa <clearpteu>
  sp = sz;
80100cea:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ced:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cf0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cf7:	e9 9a 00 00 00       	jmp    80100d96 <exec+0x2a7>
    if(argc >= MAXARG)
80100cfc:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d00:	76 05                	jbe    80100d07 <exec+0x218>
      goto bad;
80100d02:	e9 d5 01 00 00       	jmp    80100edc <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d11:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d14:	01 d0                	add    %edx,%eax
80100d16:	8b 00                	mov    (%eax),%eax
80100d18:	89 04 24             	mov    %eax,(%esp)
80100d1b:	e8 3e 46 00 00       	call   8010535e <strlen>
80100d20:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d23:	29 c2                	sub    %eax,%edx
80100d25:	89 d0                	mov    %edx,%eax
80100d27:	83 e8 01             	sub    $0x1,%eax
80100d2a:	83 e0 fc             	and    $0xfffffffc,%eax
80100d2d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d33:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d3d:	01 d0                	add    %edx,%eax
80100d3f:	8b 00                	mov    (%eax),%eax
80100d41:	89 04 24             	mov    %eax,(%esp)
80100d44:	e8 15 46 00 00       	call   8010535e <strlen>
80100d49:	83 c0 01             	add    $0x1,%eax
80100d4c:	89 c2                	mov    %eax,%edx
80100d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d51:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d58:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d5b:	01 c8                	add    %ecx,%eax
80100d5d:	8b 00                	mov    (%eax),%eax
80100d5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d63:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d67:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d71:	89 04 24             	mov    %eax,(%esp)
80100d74:	e8 46 76 00 00       	call   801083bf <copyout>
80100d79:	85 c0                	test   %eax,%eax
80100d7b:	79 05                	jns    80100d82 <exec+0x293>
      goto bad;
80100d7d:	e9 5a 01 00 00       	jmp    80100edc <exec+0x3ed>
    ustack[3+argc] = sp;
80100d82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d85:	8d 50 03             	lea    0x3(%eax),%edx
80100d88:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d8b:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d92:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d99:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100da0:	8b 45 0c             	mov    0xc(%ebp),%eax
80100da3:	01 d0                	add    %edx,%eax
80100da5:	8b 00                	mov    (%eax),%eax
80100da7:	85 c0                	test   %eax,%eax
80100da9:	0f 85 4d ff ff ff    	jne    80100cfc <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 03             	add    $0x3,%eax
80100db5:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dbc:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dc0:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dc7:	ff ff ff 
  ustack[1] = argc;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 01             	add    $0x1,%eax
80100dd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100de0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de3:	29 d0                	sub    %edx,%eax
80100de5:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dee:	83 c0 04             	add    $0x4,%eax
80100df1:	c1 e0 02             	shl    $0x2,%eax
80100df4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	83 c0 04             	add    $0x4,%eax
80100dfd:	c1 e0 02             	shl    $0x2,%eax
80100e00:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e04:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e0e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e18:	89 04 24             	mov    %eax,(%esp)
80100e1b:	e8 9f 75 00 00       	call   801083bf <copyout>
80100e20:	85 c0                	test   %eax,%eax
80100e22:	79 05                	jns    80100e29 <exec+0x33a>
    goto bad;
80100e24:	e9 b3 00 00 00       	jmp    80100edc <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e29:	8b 45 08             	mov    0x8(%ebp),%eax
80100e2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e32:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e35:	eb 17                	jmp    80100e4e <exec+0x35f>
    if(*s == '/')
80100e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3a:	0f b6 00             	movzbl (%eax),%eax
80100e3d:	3c 2f                	cmp    $0x2f,%al
80100e3f:	75 09                	jne    80100e4a <exec+0x35b>
      last = s+1;
80100e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e44:	83 c0 01             	add    $0x1,%eax
80100e47:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e4a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e51:	0f b6 00             	movzbl (%eax),%eax
80100e54:	84 c0                	test   %al,%al
80100e56:	75 df                	jne    80100e37 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e5e:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e61:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e68:	00 
80100e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e70:	89 14 24             	mov    %edx,(%esp)
80100e73:	e8 9c 44 00 00       	call   80105314 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7e:	8b 40 04             	mov    0x4(%eax),%eax
80100e81:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e8d:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e96:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e99:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea1:	8b 40 18             	mov    0x18(%eax),%eax
80100ea4:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100eaa:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ead:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb3:	8b 40 18             	mov    0x18(%eax),%eax
80100eb6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eb9:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ebc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec2:	89 04 24             	mov    %eax,(%esp)
80100ec5:	e8 23 6e 00 00       	call   80107ced <switchuvm>
  freevm(oldpgdir);
80100eca:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecd:	89 04 24             	mov    %eax,(%esp)
80100ed0:	e8 8b 72 00 00       	call   80108160 <freevm>
  return 0;
80100ed5:	b8 00 00 00 00       	mov    $0x0,%eax
80100eda:	eb 2c                	jmp    80100f08 <exec+0x419>

 bad:
  if(pgdir)
80100edc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ee0:	74 0b                	je     80100eed <exec+0x3fe>
    freevm(pgdir);
80100ee2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ee5:	89 04 24             	mov    %eax,(%esp)
80100ee8:	e8 73 72 00 00       	call   80108160 <freevm>
  if(ip){
80100eed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ef1:	74 10                	je     80100f03 <exec+0x414>
    iunlockput(ip);
80100ef3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef6:	89 04 24             	mov    %eax,(%esp)
80100ef9:	e8 e1 0b 00 00       	call   80101adf <iunlockput>
    end_op();
80100efe:	e8 91 25 00 00       	call   80103494 <end_op>
  }
  return -1;
80100f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f08:	c9                   	leave  
80100f09:	c3                   	ret    

80100f0a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f0a:	55                   	push   %ebp
80100f0b:	89 e5                	mov    %esp,%ebp
80100f0d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f10:	c7 44 24 04 c1 84 10 	movl   $0x801084c1,0x4(%esp)
80100f17:	80 
80100f18:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f1f:	e8 5b 3f 00 00       	call   80104e7f <initlock>
}
80100f24:	c9                   	leave  
80100f25:	c3                   	ret    

80100f26 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f26:	55                   	push   %ebp
80100f27:	89 e5                	mov    %esp,%ebp
80100f29:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f2c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f33:	e8 68 3f 00 00       	call   80104ea0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f38:	c7 45 f4 74 08 11 80 	movl   $0x80110874,-0xc(%ebp)
80100f3f:	eb 29                	jmp    80100f6a <filealloc+0x44>
    if(f->ref == 0){
80100f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f44:	8b 40 04             	mov    0x4(%eax),%eax
80100f47:	85 c0                	test   %eax,%eax
80100f49:	75 1b                	jne    80100f66 <filealloc+0x40>
      f->ref = 1;
80100f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f4e:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f55:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f5c:	e8 a1 3f 00 00       	call   80104f02 <release>
      return f;
80100f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f64:	eb 1e                	jmp    80100f84 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f66:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f6a:	81 7d f4 d4 11 11 80 	cmpl   $0x801111d4,-0xc(%ebp)
80100f71:	72 ce                	jb     80100f41 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f73:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f7a:	e8 83 3f 00 00       	call   80104f02 <release>
  return 0;
80100f7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f84:	c9                   	leave  
80100f85:	c3                   	ret    

80100f86 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f86:	55                   	push   %ebp
80100f87:	89 e5                	mov    %esp,%ebp
80100f89:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f8c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f93:	e8 08 3f 00 00       	call   80104ea0 <acquire>
  if(f->ref < 1)
80100f98:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9b:	8b 40 04             	mov    0x4(%eax),%eax
80100f9e:	85 c0                	test   %eax,%eax
80100fa0:	7f 0c                	jg     80100fae <filedup+0x28>
    panic("filedup");
80100fa2:	c7 04 24 c8 84 10 80 	movl   $0x801084c8,(%esp)
80100fa9:	e8 8c f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fae:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb1:	8b 40 04             	mov    0x4(%eax),%eax
80100fb4:	8d 50 01             	lea    0x1(%eax),%edx
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fbd:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fc4:	e8 39 3f 00 00       	call   80104f02 <release>
  return f;
80100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fcc:	c9                   	leave  
80100fcd:	c3                   	ret    

80100fce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fce:	55                   	push   %ebp
80100fcf:	89 e5                	mov    %esp,%ebp
80100fd1:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fd4:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fdb:	e8 c0 3e 00 00       	call   80104ea0 <acquire>
  if(f->ref < 1)
80100fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe3:	8b 40 04             	mov    0x4(%eax),%eax
80100fe6:	85 c0                	test   %eax,%eax
80100fe8:	7f 0c                	jg     80100ff6 <fileclose+0x28>
    panic("fileclose");
80100fea:	c7 04 24 d0 84 10 80 	movl   $0x801084d0,(%esp)
80100ff1:	e8 44 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80100ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff9:	8b 40 04             	mov    0x4(%eax),%eax
80100ffc:	8d 50 ff             	lea    -0x1(%eax),%edx
80100fff:	8b 45 08             	mov    0x8(%ebp),%eax
80101002:	89 50 04             	mov    %edx,0x4(%eax)
80101005:	8b 45 08             	mov    0x8(%ebp),%eax
80101008:	8b 40 04             	mov    0x4(%eax),%eax
8010100b:	85 c0                	test   %eax,%eax
8010100d:	7e 11                	jle    80101020 <fileclose+0x52>
    release(&ftable.lock);
8010100f:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101016:	e8 e7 3e 00 00       	call   80104f02 <release>
8010101b:	e9 82 00 00 00       	jmp    801010a2 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101020:	8b 45 08             	mov    0x8(%ebp),%eax
80101023:	8b 10                	mov    (%eax),%edx
80101025:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101028:	8b 50 04             	mov    0x4(%eax),%edx
8010102b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010102e:	8b 50 08             	mov    0x8(%eax),%edx
80101031:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101034:	8b 50 0c             	mov    0xc(%eax),%edx
80101037:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010103a:	8b 50 10             	mov    0x10(%eax),%edx
8010103d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101040:	8b 40 14             	mov    0x14(%eax),%eax
80101043:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101050:	8b 45 08             	mov    0x8(%ebp),%eax
80101053:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101059:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101060:	e8 9d 3e 00 00       	call   80104f02 <release>
  
  if(ff.type == FD_PIPE)
80101065:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101068:	83 f8 01             	cmp    $0x1,%eax
8010106b:	75 18                	jne    80101085 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010106d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101071:	0f be d0             	movsbl %al,%edx
80101074:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101077:	89 54 24 04          	mov    %edx,0x4(%esp)
8010107b:	89 04 24             	mov    %eax,(%esp)
8010107e:	e8 e1 2f 00 00       	call   80104064 <pipeclose>
80101083:	eb 1d                	jmp    801010a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101085:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101088:	83 f8 02             	cmp    $0x2,%eax
8010108b:	75 15                	jne    801010a2 <fileclose+0xd4>
    begin_op();
8010108d:	e8 7e 23 00 00       	call   80103410 <begin_op>
    iput(ff.ip);
80101092:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101095:	89 04 24             	mov    %eax,(%esp)
80101098:	e8 71 09 00 00       	call   80101a0e <iput>
    end_op();
8010109d:	e8 f2 23 00 00       	call   80103494 <end_op>
  }
}
801010a2:	c9                   	leave  
801010a3:	c3                   	ret    

801010a4 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010a4:	55                   	push   %ebp
801010a5:	89 e5                	mov    %esp,%ebp
801010a7:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010aa:	8b 45 08             	mov    0x8(%ebp),%eax
801010ad:	8b 00                	mov    (%eax),%eax
801010af:	83 f8 02             	cmp    $0x2,%eax
801010b2:	75 38                	jne    801010ec <filestat+0x48>
    ilock(f->ip);
801010b4:	8b 45 08             	mov    0x8(%ebp),%eax
801010b7:	8b 40 10             	mov    0x10(%eax),%eax
801010ba:	89 04 24             	mov    %eax,(%esp)
801010bd:	e8 99 07 00 00       	call   8010185b <ilock>
    stati(f->ip, st);
801010c2:	8b 45 08             	mov    0x8(%ebp),%eax
801010c5:	8b 40 10             	mov    0x10(%eax),%eax
801010c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801010cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801010cf:	89 04 24             	mov    %eax,(%esp)
801010d2:	e8 4c 0c 00 00       	call   80101d23 <stati>
    iunlock(f->ip);
801010d7:	8b 45 08             	mov    0x8(%ebp),%eax
801010da:	8b 40 10             	mov    0x10(%eax),%eax
801010dd:	89 04 24             	mov    %eax,(%esp)
801010e0:	e8 c4 08 00 00       	call   801019a9 <iunlock>
    return 0;
801010e5:	b8 00 00 00 00       	mov    $0x0,%eax
801010ea:	eb 05                	jmp    801010f1 <filestat+0x4d>
  }
  return -1;
801010ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010f1:	c9                   	leave  
801010f2:	c3                   	ret    

801010f3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010f3:	55                   	push   %ebp
801010f4:	89 e5                	mov    %esp,%ebp
801010f6:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010f9:	8b 45 08             	mov    0x8(%ebp),%eax
801010fc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101100:	84 c0                	test   %al,%al
80101102:	75 0a                	jne    8010110e <fileread+0x1b>
    return -1;
80101104:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101109:	e9 9f 00 00 00       	jmp    801011ad <fileread+0xba>
  if(f->type == FD_PIPE)
8010110e:	8b 45 08             	mov    0x8(%ebp),%eax
80101111:	8b 00                	mov    (%eax),%eax
80101113:	83 f8 01             	cmp    $0x1,%eax
80101116:	75 1e                	jne    80101136 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101118:	8b 45 08             	mov    0x8(%ebp),%eax
8010111b:	8b 40 0c             	mov    0xc(%eax),%eax
8010111e:	8b 55 10             	mov    0x10(%ebp),%edx
80101121:	89 54 24 08          	mov    %edx,0x8(%esp)
80101125:	8b 55 0c             	mov    0xc(%ebp),%edx
80101128:	89 54 24 04          	mov    %edx,0x4(%esp)
8010112c:	89 04 24             	mov    %eax,(%esp)
8010112f:	e8 b1 30 00 00       	call   801041e5 <piperead>
80101134:	eb 77                	jmp    801011ad <fileread+0xba>
  if(f->type == FD_INODE){
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 00                	mov    (%eax),%eax
8010113b:	83 f8 02             	cmp    $0x2,%eax
8010113e:	75 61                	jne    801011a1 <fileread+0xae>
    ilock(f->ip);
80101140:	8b 45 08             	mov    0x8(%ebp),%eax
80101143:	8b 40 10             	mov    0x10(%eax),%eax
80101146:	89 04 24             	mov    %eax,(%esp)
80101149:	e8 0d 07 00 00       	call   8010185b <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010114e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101151:	8b 45 08             	mov    0x8(%ebp),%eax
80101154:	8b 50 14             	mov    0x14(%eax),%edx
80101157:	8b 45 08             	mov    0x8(%ebp),%eax
8010115a:	8b 40 10             	mov    0x10(%eax),%eax
8010115d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101161:	89 54 24 08          	mov    %edx,0x8(%esp)
80101165:	8b 55 0c             	mov    0xc(%ebp),%edx
80101168:	89 54 24 04          	mov    %edx,0x4(%esp)
8010116c:	89 04 24             	mov    %eax,(%esp)
8010116f:	e8 f4 0b 00 00       	call   80101d68 <readi>
80101174:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101177:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010117b:	7e 11                	jle    8010118e <fileread+0x9b>
      f->off += r;
8010117d:	8b 45 08             	mov    0x8(%ebp),%eax
80101180:	8b 50 14             	mov    0x14(%eax),%edx
80101183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101186:	01 c2                	add    %eax,%edx
80101188:	8b 45 08             	mov    0x8(%ebp),%eax
8010118b:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010118e:	8b 45 08             	mov    0x8(%ebp),%eax
80101191:	8b 40 10             	mov    0x10(%eax),%eax
80101194:	89 04 24             	mov    %eax,(%esp)
80101197:	e8 0d 08 00 00       	call   801019a9 <iunlock>
    return r;
8010119c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010119f:	eb 0c                	jmp    801011ad <fileread+0xba>
  }
  panic("fileread");
801011a1:	c7 04 24 da 84 10 80 	movl   $0x801084da,(%esp)
801011a8:	e8 8d f3 ff ff       	call   8010053a <panic>
}
801011ad:	c9                   	leave  
801011ae:	c3                   	ret    

801011af <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011af:	55                   	push   %ebp
801011b0:	89 e5                	mov    %esp,%ebp
801011b2:	53                   	push   %ebx
801011b3:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011b6:	8b 45 08             	mov    0x8(%ebp),%eax
801011b9:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011bd:	84 c0                	test   %al,%al
801011bf:	75 0a                	jne    801011cb <filewrite+0x1c>
    return -1;
801011c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011c6:	e9 20 01 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011cb:	8b 45 08             	mov    0x8(%ebp),%eax
801011ce:	8b 00                	mov    (%eax),%eax
801011d0:	83 f8 01             	cmp    $0x1,%eax
801011d3:	75 21                	jne    801011f6 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011d5:	8b 45 08             	mov    0x8(%ebp),%eax
801011d8:	8b 40 0c             	mov    0xc(%eax),%eax
801011db:	8b 55 10             	mov    0x10(%ebp),%edx
801011de:	89 54 24 08          	mov    %edx,0x8(%esp)
801011e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801011e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801011e9:	89 04 24             	mov    %eax,(%esp)
801011ec:	e8 05 2f 00 00       	call   801040f6 <pipewrite>
801011f1:	e9 f5 00 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_INODE){
801011f6:	8b 45 08             	mov    0x8(%ebp),%eax
801011f9:	8b 00                	mov    (%eax),%eax
801011fb:	83 f8 02             	cmp    $0x2,%eax
801011fe:	0f 85 db 00 00 00    	jne    801012df <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101204:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010120b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101212:	e9 a8 00 00 00       	jmp    801012bf <filewrite+0x110>
      int n1 = n - i;
80101217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010121a:	8b 55 10             	mov    0x10(%ebp),%edx
8010121d:	29 c2                	sub    %eax,%edx
8010121f:	89 d0                	mov    %edx,%eax
80101221:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101224:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101227:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010122a:	7e 06                	jle    80101232 <filewrite+0x83>
        n1 = max;
8010122c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010122f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101232:	e8 d9 21 00 00       	call   80103410 <begin_op>
      ilock(f->ip);
80101237:	8b 45 08             	mov    0x8(%ebp),%eax
8010123a:	8b 40 10             	mov    0x10(%eax),%eax
8010123d:	89 04 24             	mov    %eax,(%esp)
80101240:	e8 16 06 00 00       	call   8010185b <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101245:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101248:	8b 45 08             	mov    0x8(%ebp),%eax
8010124b:	8b 50 14             	mov    0x14(%eax),%edx
8010124e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101251:	8b 45 0c             	mov    0xc(%ebp),%eax
80101254:	01 c3                	add    %eax,%ebx
80101256:	8b 45 08             	mov    0x8(%ebp),%eax
80101259:	8b 40 10             	mov    0x10(%eax),%eax
8010125c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101260:	89 54 24 08          	mov    %edx,0x8(%esp)
80101264:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101268:	89 04 24             	mov    %eax,(%esp)
8010126b:	e8 5c 0c 00 00       	call   80101ecc <writei>
80101270:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101273:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101277:	7e 11                	jle    8010128a <filewrite+0xdb>
        f->off += r;
80101279:	8b 45 08             	mov    0x8(%ebp),%eax
8010127c:	8b 50 14             	mov    0x14(%eax),%edx
8010127f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101282:	01 c2                	add    %eax,%edx
80101284:	8b 45 08             	mov    0x8(%ebp),%eax
80101287:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010128a:	8b 45 08             	mov    0x8(%ebp),%eax
8010128d:	8b 40 10             	mov    0x10(%eax),%eax
80101290:	89 04 24             	mov    %eax,(%esp)
80101293:	e8 11 07 00 00       	call   801019a9 <iunlock>
      end_op();
80101298:	e8 f7 21 00 00       	call   80103494 <end_op>

      if(r < 0)
8010129d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012a1:	79 02                	jns    801012a5 <filewrite+0xf6>
        break;
801012a3:	eb 26                	jmp    801012cb <filewrite+0x11c>
      if(r != n1)
801012a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012ab:	74 0c                	je     801012b9 <filewrite+0x10a>
        panic("short filewrite");
801012ad:	c7 04 24 e3 84 10 80 	movl   $0x801084e3,(%esp)
801012b4:	e8 81 f2 ff ff       	call   8010053a <panic>
      i += r;
801012b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012bc:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c2:	3b 45 10             	cmp    0x10(%ebp),%eax
801012c5:	0f 8c 4c ff ff ff    	jl     80101217 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ce:	3b 45 10             	cmp    0x10(%ebp),%eax
801012d1:	75 05                	jne    801012d8 <filewrite+0x129>
801012d3:	8b 45 10             	mov    0x10(%ebp),%eax
801012d6:	eb 05                	jmp    801012dd <filewrite+0x12e>
801012d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012dd:	eb 0c                	jmp    801012eb <filewrite+0x13c>
  }
  panic("filewrite");
801012df:	c7 04 24 f3 84 10 80 	movl   $0x801084f3,(%esp)
801012e6:	e8 4f f2 ff ff       	call   8010053a <panic>
}
801012eb:	83 c4 24             	add    $0x24,%esp
801012ee:	5b                   	pop    %ebx
801012ef:	5d                   	pop    %ebp
801012f0:	c3                   	ret    

801012f1 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012f1:	55                   	push   %ebp
801012f2:	89 e5                	mov    %esp,%ebp
801012f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012f7:	8b 45 08             	mov    0x8(%ebp),%eax
801012fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101301:	00 
80101302:	89 04 24             	mov    %eax,(%esp)
80101305:	e8 9c ee ff ff       	call   801001a6 <bread>
8010130a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010130d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101310:	83 c0 18             	add    $0x18,%eax
80101313:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010131a:	00 
8010131b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010131f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101322:	89 04 24             	mov    %eax,(%esp)
80101325:	e8 99 3e 00 00       	call   801051c3 <memmove>
  brelse(bp);
8010132a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010132d:	89 04 24             	mov    %eax,(%esp)
80101330:	e8 e2 ee ff ff       	call   80100217 <brelse>
}
80101335:	c9                   	leave  
80101336:	c3                   	ret    

80101337 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101337:	55                   	push   %ebp
80101338:	89 e5                	mov    %esp,%ebp
8010133a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010133d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101340:	8b 45 08             	mov    0x8(%ebp),%eax
80101343:	89 54 24 04          	mov    %edx,0x4(%esp)
80101347:	89 04 24             	mov    %eax,(%esp)
8010134a:	e8 57 ee ff ff       	call   801001a6 <bread>
8010134f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101355:	83 c0 18             	add    $0x18,%eax
80101358:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010135f:	00 
80101360:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101367:	00 
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 84 3d 00 00       	call   801050f4 <memset>
  log_write(bp);
80101370:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101373:	89 04 24             	mov    %eax,(%esp)
80101376:	e8 a0 22 00 00       	call   8010361b <log_write>
  brelse(bp);
8010137b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137e:	89 04 24             	mov    %eax,(%esp)
80101381:	e8 91 ee ff ff       	call   80100217 <brelse>
}
80101386:	c9                   	leave  
80101387:	c3                   	ret    

80101388 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101388:	55                   	push   %ebp
80101389:	89 e5                	mov    %esp,%ebp
8010138b:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010138e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101395:	8b 45 08             	mov    0x8(%ebp),%eax
80101398:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010139b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010139f:	89 04 24             	mov    %eax,(%esp)
801013a2:	e8 4a ff ff ff       	call   801012f1 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013ae:	e9 07 01 00 00       	jmp    801014ba <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013bc:	85 c0                	test   %eax,%eax
801013be:	0f 48 c2             	cmovs  %edx,%eax
801013c1:	c1 f8 0c             	sar    $0xc,%eax
801013c4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013c7:	c1 ea 03             	shr    $0x3,%edx
801013ca:	01 d0                	add    %edx,%eax
801013cc:	83 c0 03             	add    $0x3,%eax
801013cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801013d3:	8b 45 08             	mov    0x8(%ebp),%eax
801013d6:	89 04 24             	mov    %eax,(%esp)
801013d9:	e8 c8 ed ff ff       	call   801001a6 <bread>
801013de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013e1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013e8:	e9 9d 00 00 00       	jmp    8010148a <balloc+0x102>
      m = 1 << (bi % 8);
801013ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013f0:	99                   	cltd   
801013f1:	c1 ea 1d             	shr    $0x1d,%edx
801013f4:	01 d0                	add    %edx,%eax
801013f6:	83 e0 07             	and    $0x7,%eax
801013f9:	29 d0                	sub    %edx,%eax
801013fb:	ba 01 00 00 00       	mov    $0x1,%edx
80101400:	89 c1                	mov    %eax,%ecx
80101402:	d3 e2                	shl    %cl,%edx
80101404:	89 d0                	mov    %edx,%eax
80101406:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101409:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010140c:	8d 50 07             	lea    0x7(%eax),%edx
8010140f:	85 c0                	test   %eax,%eax
80101411:	0f 48 c2             	cmovs  %edx,%eax
80101414:	c1 f8 03             	sar    $0x3,%eax
80101417:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010141a:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010141f:	0f b6 c0             	movzbl %al,%eax
80101422:	23 45 e8             	and    -0x18(%ebp),%eax
80101425:	85 c0                	test   %eax,%eax
80101427:	75 5d                	jne    80101486 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101429:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010142c:	8d 50 07             	lea    0x7(%eax),%edx
8010142f:	85 c0                	test   %eax,%eax
80101431:	0f 48 c2             	cmovs  %edx,%eax
80101434:	c1 f8 03             	sar    $0x3,%eax
80101437:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010143a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010143f:	89 d1                	mov    %edx,%ecx
80101441:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101444:	09 ca                	or     %ecx,%edx
80101446:	89 d1                	mov    %edx,%ecx
80101448:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010144b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010144f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101452:	89 04 24             	mov    %eax,(%esp)
80101455:	e8 c1 21 00 00       	call   8010361b <log_write>
        brelse(bp);
8010145a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010145d:	89 04 24             	mov    %eax,(%esp)
80101460:	e8 b2 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101465:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101468:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010146b:	01 c2                	add    %eax,%edx
8010146d:	8b 45 08             	mov    0x8(%ebp),%eax
80101470:	89 54 24 04          	mov    %edx,0x4(%esp)
80101474:	89 04 24             	mov    %eax,(%esp)
80101477:	e8 bb fe ff ff       	call   80101337 <bzero>
        return b + bi;
8010147c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010147f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101482:	01 d0                	add    %edx,%eax
80101484:	eb 4e                	jmp    801014d4 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101486:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010148a:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101491:	7f 15                	jg     801014a8 <balloc+0x120>
80101493:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101496:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101499:	01 d0                	add    %edx,%eax
8010149b:	89 c2                	mov    %eax,%edx
8010149d:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014a0:	39 c2                	cmp    %eax,%edx
801014a2:	0f 82 45 ff ff ff    	jb     801013ed <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014ab:	89 04 24             	mov    %eax,(%esp)
801014ae:	e8 64 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014b3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014c0:	39 c2                	cmp    %eax,%edx
801014c2:	0f 82 eb fe ff ff    	jb     801013b3 <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014c8:	c7 04 24 fd 84 10 80 	movl   $0x801084fd,(%esp)
801014cf:	e8 66 f0 ff ff       	call   8010053a <panic>
}
801014d4:	c9                   	leave  
801014d5:	c3                   	ret    

801014d6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014d6:	55                   	push   %ebp
801014d7:	89 e5                	mov    %esp,%ebp
801014d9:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014df:	89 44 24 04          	mov    %eax,0x4(%esp)
801014e3:	8b 45 08             	mov    0x8(%ebp),%eax
801014e6:	89 04 24             	mov    %eax,(%esp)
801014e9:	e8 03 fe ff ff       	call   801012f1 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801014f1:	c1 e8 0c             	shr    $0xc,%eax
801014f4:	89 c2                	mov    %eax,%edx
801014f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014f9:	c1 e8 03             	shr    $0x3,%eax
801014fc:	01 d0                	add    %edx,%eax
801014fe:	8d 50 03             	lea    0x3(%eax),%edx
80101501:	8b 45 08             	mov    0x8(%ebp),%eax
80101504:	89 54 24 04          	mov    %edx,0x4(%esp)
80101508:	89 04 24             	mov    %eax,(%esp)
8010150b:	e8 96 ec ff ff       	call   801001a6 <bread>
80101510:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101513:	8b 45 0c             	mov    0xc(%ebp),%eax
80101516:	25 ff 0f 00 00       	and    $0xfff,%eax
8010151b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010151e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101521:	99                   	cltd   
80101522:	c1 ea 1d             	shr    $0x1d,%edx
80101525:	01 d0                	add    %edx,%eax
80101527:	83 e0 07             	and    $0x7,%eax
8010152a:	29 d0                	sub    %edx,%eax
8010152c:	ba 01 00 00 00       	mov    $0x1,%edx
80101531:	89 c1                	mov    %eax,%ecx
80101533:	d3 e2                	shl    %cl,%edx
80101535:	89 d0                	mov    %edx,%eax
80101537:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153d:	8d 50 07             	lea    0x7(%eax),%edx
80101540:	85 c0                	test   %eax,%eax
80101542:	0f 48 c2             	cmovs  %edx,%eax
80101545:	c1 f8 03             	sar    $0x3,%eax
80101548:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154b:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101550:	0f b6 c0             	movzbl %al,%eax
80101553:	23 45 ec             	and    -0x14(%ebp),%eax
80101556:	85 c0                	test   %eax,%eax
80101558:	75 0c                	jne    80101566 <bfree+0x90>
    panic("freeing free block");
8010155a:	c7 04 24 13 85 10 80 	movl   $0x80108513,(%esp)
80101561:	e8 d4 ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	8d 50 07             	lea    0x7(%eax),%edx
8010156c:	85 c0                	test   %eax,%eax
8010156e:	0f 48 c2             	cmovs  %edx,%eax
80101571:	c1 f8 03             	sar    $0x3,%eax
80101574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101577:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010157c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010157f:	f7 d1                	not    %ecx
80101581:	21 ca                	and    %ecx,%edx
80101583:	89 d1                	mov    %edx,%ecx
80101585:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101588:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010158c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010158f:	89 04 24             	mov    %eax,(%esp)
80101592:	e8 84 20 00 00       	call   8010361b <log_write>
  brelse(bp);
80101597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 75 ec ff ff       	call   80100217 <brelse>
}
801015a2:	c9                   	leave  
801015a3:	c3                   	ret    

801015a4 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015a4:	55                   	push   %ebp
801015a5:	89 e5                	mov    %esp,%ebp
801015a7:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015aa:	c7 44 24 04 26 85 10 	movl   $0x80108526,0x4(%esp)
801015b1:	80 
801015b2:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801015b9:	e8 c1 38 00 00       	call   80104e7f <initlock>
}
801015be:	c9                   	leave  
801015bf:	c3                   	ret    

801015c0 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015c0:	55                   	push   %ebp
801015c1:	89 e5                	mov    %esp,%ebp
801015c3:	83 ec 38             	sub    $0x38,%esp
801015c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801015c9:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015cd:	8b 45 08             	mov    0x8(%ebp),%eax
801015d0:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801015d7:	89 04 24             	mov    %eax,(%esp)
801015da:	e8 12 fd ff ff       	call   801012f1 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015df:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015e6:	e9 98 00 00 00       	jmp    80101683 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015ee:	c1 e8 03             	shr    $0x3,%eax
801015f1:	83 c0 02             	add    $0x2,%eax
801015f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801015f8:	8b 45 08             	mov    0x8(%ebp),%eax
801015fb:	89 04 24             	mov    %eax,(%esp)
801015fe:	e8 a3 eb ff ff       	call   801001a6 <bread>
80101603:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101606:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101609:	8d 50 18             	lea    0x18(%eax),%edx
8010160c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010160f:	83 e0 07             	and    $0x7,%eax
80101612:	c1 e0 06             	shl    $0x6,%eax
80101615:	01 d0                	add    %edx,%eax
80101617:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010161a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010161d:	0f b7 00             	movzwl (%eax),%eax
80101620:	66 85 c0             	test   %ax,%ax
80101623:	75 4f                	jne    80101674 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101625:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010162c:	00 
8010162d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101634:	00 
80101635:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101638:	89 04 24             	mov    %eax,(%esp)
8010163b:	e8 b4 3a 00 00       	call   801050f4 <memset>
      dip->type = type;
80101640:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101643:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101647:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
8010164a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010164d:	89 04 24             	mov    %eax,(%esp)
80101650:	e8 c6 1f 00 00       	call   8010361b <log_write>
      brelse(bp);
80101655:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101658:	89 04 24             	mov    %eax,(%esp)
8010165b:	e8 b7 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101660:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101663:	89 44 24 04          	mov    %eax,0x4(%esp)
80101667:	8b 45 08             	mov    0x8(%ebp),%eax
8010166a:	89 04 24             	mov    %eax,(%esp)
8010166d:	e8 e5 00 00 00       	call   80101757 <iget>
80101672:	eb 29                	jmp    8010169d <ialloc+0xdd>
    }
    brelse(bp);
80101674:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101677:	89 04 24             	mov    %eax,(%esp)
8010167a:	e8 98 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010167f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101683:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101689:	39 c2                	cmp    %eax,%edx
8010168b:	0f 82 5a ff ff ff    	jb     801015eb <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101691:	c7 04 24 2d 85 10 80 	movl   $0x8010852d,(%esp)
80101698:	e8 9d ee ff ff       	call   8010053a <panic>
}
8010169d:	c9                   	leave  
8010169e:	c3                   	ret    

8010169f <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010169f:	55                   	push   %ebp
801016a0:	89 e5                	mov    %esp,%ebp
801016a2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016a5:	8b 45 08             	mov    0x8(%ebp),%eax
801016a8:	8b 40 04             	mov    0x4(%eax),%eax
801016ab:	c1 e8 03             	shr    $0x3,%eax
801016ae:	8d 50 02             	lea    0x2(%eax),%edx
801016b1:	8b 45 08             	mov    0x8(%ebp),%eax
801016b4:	8b 00                	mov    (%eax),%eax
801016b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ba:	89 04 24             	mov    %eax,(%esp)
801016bd:	e8 e4 ea ff ff       	call   801001a6 <bread>
801016c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c8:	8d 50 18             	lea    0x18(%eax),%edx
801016cb:	8b 45 08             	mov    0x8(%ebp),%eax
801016ce:	8b 40 04             	mov    0x4(%eax),%eax
801016d1:	83 e0 07             	and    $0x7,%eax
801016d4:	c1 e0 06             	shl    $0x6,%eax
801016d7:	01 d0                	add    %edx,%eax
801016d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016dc:	8b 45 08             	mov    0x8(%ebp),%eax
801016df:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016e6:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016e9:	8b 45 08             	mov    0x8(%ebp),%eax
801016ec:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016f3:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801016f7:	8b 45 08             	mov    0x8(%ebp),%eax
801016fa:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801016fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101701:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101705:	8b 45 08             	mov    0x8(%ebp),%eax
80101708:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010170c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010170f:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101713:	8b 45 08             	mov    0x8(%ebp),%eax
80101716:	8b 50 18             	mov    0x18(%eax),%edx
80101719:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010171f:	8b 45 08             	mov    0x8(%ebp),%eax
80101722:	8d 50 1c             	lea    0x1c(%eax),%edx
80101725:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101728:	83 c0 0c             	add    $0xc,%eax
8010172b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101732:	00 
80101733:	89 54 24 04          	mov    %edx,0x4(%esp)
80101737:	89 04 24             	mov    %eax,(%esp)
8010173a:	e8 84 3a 00 00       	call   801051c3 <memmove>
  log_write(bp);
8010173f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101742:	89 04 24             	mov    %eax,(%esp)
80101745:	e8 d1 1e 00 00       	call   8010361b <log_write>
  brelse(bp);
8010174a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174d:	89 04 24             	mov    %eax,(%esp)
80101750:	e8 c2 ea ff ff       	call   80100217 <brelse>
}
80101755:	c9                   	leave  
80101756:	c3                   	ret    

80101757 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101757:	55                   	push   %ebp
80101758:	89 e5                	mov    %esp,%ebp
8010175a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010175d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101764:	e8 37 37 00 00       	call   80104ea0 <acquire>

  // Is the inode already cached?
  empty = 0;
80101769:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101770:	c7 45 f4 74 12 11 80 	movl   $0x80111274,-0xc(%ebp)
80101777:	eb 59                	jmp    801017d2 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177c:	8b 40 08             	mov    0x8(%eax),%eax
8010177f:	85 c0                	test   %eax,%eax
80101781:	7e 35                	jle    801017b8 <iget+0x61>
80101783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101786:	8b 00                	mov    (%eax),%eax
80101788:	3b 45 08             	cmp    0x8(%ebp),%eax
8010178b:	75 2b                	jne    801017b8 <iget+0x61>
8010178d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101790:	8b 40 04             	mov    0x4(%eax),%eax
80101793:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101796:	75 20                	jne    801017b8 <iget+0x61>
      ip->ref++;
80101798:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179b:	8b 40 08             	mov    0x8(%eax),%eax
8010179e:	8d 50 01             	lea    0x1(%eax),%edx
801017a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a4:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017a7:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017ae:	e8 4f 37 00 00       	call   80104f02 <release>
      return ip;
801017b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b6:	eb 6f                	jmp    80101827 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017bc:	75 10                	jne    801017ce <iget+0x77>
801017be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c1:	8b 40 08             	mov    0x8(%eax),%eax
801017c4:	85 c0                	test   %eax,%eax
801017c6:	75 06                	jne    801017ce <iget+0x77>
      empty = ip;
801017c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017cb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017ce:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017d2:	81 7d f4 14 22 11 80 	cmpl   $0x80112214,-0xc(%ebp)
801017d9:	72 9e                	jb     80101779 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017df:	75 0c                	jne    801017ed <iget+0x96>
    panic("iget: no inodes");
801017e1:	c7 04 24 3f 85 10 80 	movl   $0x8010853f,(%esp)
801017e8:	e8 4d ed ff ff       	call   8010053a <panic>

  ip = empty;
801017ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801017f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f6:	8b 55 08             	mov    0x8(%ebp),%edx
801017f9:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801017fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101801:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101807:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010180e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101811:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101818:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
8010181f:	e8 de 36 00 00       	call   80104f02 <release>

  return ip;
80101824:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101827:	c9                   	leave  
80101828:	c3                   	ret    

80101829 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101829:	55                   	push   %ebp
8010182a:	89 e5                	mov    %esp,%ebp
8010182c:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010182f:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101836:	e8 65 36 00 00       	call   80104ea0 <acquire>
  ip->ref++;
8010183b:	8b 45 08             	mov    0x8(%ebp),%eax
8010183e:	8b 40 08             	mov    0x8(%eax),%eax
80101841:	8d 50 01             	lea    0x1(%eax),%edx
80101844:	8b 45 08             	mov    0x8(%ebp),%eax
80101847:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010184a:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101851:	e8 ac 36 00 00       	call   80104f02 <release>
  return ip;
80101856:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101859:	c9                   	leave  
8010185a:	c3                   	ret    

8010185b <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010185b:	55                   	push   %ebp
8010185c:	89 e5                	mov    %esp,%ebp
8010185e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101861:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101865:	74 0a                	je     80101871 <ilock+0x16>
80101867:	8b 45 08             	mov    0x8(%ebp),%eax
8010186a:	8b 40 08             	mov    0x8(%eax),%eax
8010186d:	85 c0                	test   %eax,%eax
8010186f:	7f 0c                	jg     8010187d <ilock+0x22>
    panic("ilock");
80101871:	c7 04 24 4f 85 10 80 	movl   $0x8010854f,(%esp)
80101878:	e8 bd ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010187d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101884:	e8 17 36 00 00       	call   80104ea0 <acquire>
  while(ip->flags & I_BUSY)
80101889:	eb 13                	jmp    8010189e <ilock+0x43>
    sleep(ip, &icache.lock);
8010188b:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
80101892:	80 
80101893:	8b 45 08             	mov    0x8(%ebp),%eax
80101896:	89 04 24             	mov    %eax,(%esp)
80101899:	e8 2f 33 00 00       	call   80104bcd <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010189e:	8b 45 08             	mov    0x8(%ebp),%eax
801018a1:	8b 40 0c             	mov    0xc(%eax),%eax
801018a4:	83 e0 01             	and    $0x1,%eax
801018a7:	85 c0                	test   %eax,%eax
801018a9:	75 e0                	jne    8010188b <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018ab:	8b 45 08             	mov    0x8(%ebp),%eax
801018ae:	8b 40 0c             	mov    0xc(%eax),%eax
801018b1:	83 c8 01             	or     $0x1,%eax
801018b4:	89 c2                	mov    %eax,%edx
801018b6:	8b 45 08             	mov    0x8(%ebp),%eax
801018b9:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018bc:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018c3:	e8 3a 36 00 00       	call   80104f02 <release>

  if(!(ip->flags & I_VALID)){
801018c8:	8b 45 08             	mov    0x8(%ebp),%eax
801018cb:	8b 40 0c             	mov    0xc(%eax),%eax
801018ce:	83 e0 02             	and    $0x2,%eax
801018d1:	85 c0                	test   %eax,%eax
801018d3:	0f 85 ce 00 00 00    	jne    801019a7 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018d9:	8b 45 08             	mov    0x8(%ebp),%eax
801018dc:	8b 40 04             	mov    0x4(%eax),%eax
801018df:	c1 e8 03             	shr    $0x3,%eax
801018e2:	8d 50 02             	lea    0x2(%eax),%edx
801018e5:	8b 45 08             	mov    0x8(%ebp),%eax
801018e8:	8b 00                	mov    (%eax),%eax
801018ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801018ee:	89 04 24             	mov    %eax,(%esp)
801018f1:	e8 b0 e8 ff ff       	call   801001a6 <bread>
801018f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801018f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fc:	8d 50 18             	lea    0x18(%eax),%edx
801018ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101902:	8b 40 04             	mov    0x4(%eax),%eax
80101905:	83 e0 07             	and    $0x7,%eax
80101908:	c1 e0 06             	shl    $0x6,%eax
8010190b:	01 d0                	add    %edx,%eax
8010190d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101913:	0f b7 10             	movzwl (%eax),%edx
80101916:	8b 45 08             	mov    0x8(%ebp),%eax
80101919:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010191d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101920:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101924:	8b 45 08             	mov    0x8(%ebp),%eax
80101927:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
8010192b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010192e:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101932:	8b 45 08             	mov    0x8(%ebp),%eax
80101935:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010193c:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101940:	8b 45 08             	mov    0x8(%ebp),%eax
80101943:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101947:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194a:	8b 50 08             	mov    0x8(%eax),%edx
8010194d:	8b 45 08             	mov    0x8(%ebp),%eax
80101950:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101953:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101956:	8d 50 0c             	lea    0xc(%eax),%edx
80101959:	8b 45 08             	mov    0x8(%ebp),%eax
8010195c:	83 c0 1c             	add    $0x1c,%eax
8010195f:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101966:	00 
80101967:	89 54 24 04          	mov    %edx,0x4(%esp)
8010196b:	89 04 24             	mov    %eax,(%esp)
8010196e:	e8 50 38 00 00       	call   801051c3 <memmove>
    brelse(bp);
80101973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101976:	89 04 24             	mov    %eax,(%esp)
80101979:	e8 99 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010197e:	8b 45 08             	mov    0x8(%ebp),%eax
80101981:	8b 40 0c             	mov    0xc(%eax),%eax
80101984:	83 c8 02             	or     $0x2,%eax
80101987:	89 c2                	mov    %eax,%edx
80101989:	8b 45 08             	mov    0x8(%ebp),%eax
8010198c:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010198f:	8b 45 08             	mov    0x8(%ebp),%eax
80101992:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101996:	66 85 c0             	test   %ax,%ax
80101999:	75 0c                	jne    801019a7 <ilock+0x14c>
      panic("ilock: no type");
8010199b:	c7 04 24 55 85 10 80 	movl   $0x80108555,(%esp)
801019a2:	e8 93 eb ff ff       	call   8010053a <panic>
  }
}
801019a7:	c9                   	leave  
801019a8:	c3                   	ret    

801019a9 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019a9:	55                   	push   %ebp
801019aa:	89 e5                	mov    %esp,%ebp
801019ac:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019b3:	74 17                	je     801019cc <iunlock+0x23>
801019b5:	8b 45 08             	mov    0x8(%ebp),%eax
801019b8:	8b 40 0c             	mov    0xc(%eax),%eax
801019bb:	83 e0 01             	and    $0x1,%eax
801019be:	85 c0                	test   %eax,%eax
801019c0:	74 0a                	je     801019cc <iunlock+0x23>
801019c2:	8b 45 08             	mov    0x8(%ebp),%eax
801019c5:	8b 40 08             	mov    0x8(%eax),%eax
801019c8:	85 c0                	test   %eax,%eax
801019ca:	7f 0c                	jg     801019d8 <iunlock+0x2f>
    panic("iunlock");
801019cc:	c7 04 24 64 85 10 80 	movl   $0x80108564,(%esp)
801019d3:	e8 62 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019d8:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801019df:	e8 bc 34 00 00       	call   80104ea0 <acquire>
  ip->flags &= ~I_BUSY;
801019e4:	8b 45 08             	mov    0x8(%ebp),%eax
801019e7:	8b 40 0c             	mov    0xc(%eax),%eax
801019ea:	83 e0 fe             	and    $0xfffffffe,%eax
801019ed:	89 c2                	mov    %eax,%edx
801019ef:	8b 45 08             	mov    0x8(%ebp),%eax
801019f2:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	89 04 24             	mov    %eax,(%esp)
801019fb:	e8 a5 32 00 00       	call   80104ca5 <wakeup>
  release(&icache.lock);
80101a00:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a07:	e8 f6 34 00 00       	call   80104f02 <release>
}
80101a0c:	c9                   	leave  
80101a0d:	c3                   	ret    

80101a0e <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a0e:	55                   	push   %ebp
80101a0f:	89 e5                	mov    %esp,%ebp
80101a11:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a14:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a1b:	e8 80 34 00 00       	call   80104ea0 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a20:	8b 45 08             	mov    0x8(%ebp),%eax
80101a23:	8b 40 08             	mov    0x8(%eax),%eax
80101a26:	83 f8 01             	cmp    $0x1,%eax
80101a29:	0f 85 93 00 00 00    	jne    80101ac2 <iput+0xb4>
80101a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a32:	8b 40 0c             	mov    0xc(%eax),%eax
80101a35:	83 e0 02             	and    $0x2,%eax
80101a38:	85 c0                	test   %eax,%eax
80101a3a:	0f 84 82 00 00 00    	je     80101ac2 <iput+0xb4>
80101a40:	8b 45 08             	mov    0x8(%ebp),%eax
80101a43:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a47:	66 85 c0             	test   %ax,%ax
80101a4a:	75 76                	jne    80101ac2 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101a4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4f:	8b 40 0c             	mov    0xc(%eax),%eax
80101a52:	83 e0 01             	and    $0x1,%eax
80101a55:	85 c0                	test   %eax,%eax
80101a57:	74 0c                	je     80101a65 <iput+0x57>
      panic("iput busy");
80101a59:	c7 04 24 6c 85 10 80 	movl   $0x8010856c,(%esp)
80101a60:	e8 d5 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 40 0c             	mov    0xc(%eax),%eax
80101a6b:	83 c8 01             	or     $0x1,%eax
80101a6e:	89 c2                	mov    %eax,%edx
80101a70:	8b 45 08             	mov    0x8(%ebp),%eax
80101a73:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a76:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a7d:	e8 80 34 00 00       	call   80104f02 <release>
    itrunc(ip);
80101a82:	8b 45 08             	mov    0x8(%ebp),%eax
80101a85:	89 04 24             	mov    %eax,(%esp)
80101a88:	e8 7d 01 00 00       	call   80101c0a <itrunc>
    ip->type = 0;
80101a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a90:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101a96:	8b 45 08             	mov    0x8(%ebp),%eax
80101a99:	89 04 24             	mov    %eax,(%esp)
80101a9c:	e8 fe fb ff ff       	call   8010169f <iupdate>
    acquire(&icache.lock);
80101aa1:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101aa8:	e8 f3 33 00 00       	call   80104ea0 <acquire>
    ip->flags = 0;
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aba:	89 04 24             	mov    %eax,(%esp)
80101abd:	e8 e3 31 00 00       	call   80104ca5 <wakeup>
  }
  ip->ref--;
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 08             	mov    0x8(%eax),%eax
80101ac8:	8d 50 ff             	lea    -0x1(%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ad1:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101ad8:	e8 25 34 00 00       	call   80104f02 <release>
}
80101add:	c9                   	leave  
80101ade:	c3                   	ret    

80101adf <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101adf:	55                   	push   %ebp
80101ae0:	89 e5                	mov    %esp,%ebp
80101ae2:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae8:	89 04 24             	mov    %eax,(%esp)
80101aeb:	e8 b9 fe ff ff       	call   801019a9 <iunlock>
  iput(ip);
80101af0:	8b 45 08             	mov    0x8(%ebp),%eax
80101af3:	89 04 24             	mov    %eax,(%esp)
80101af6:	e8 13 ff ff ff       	call   80101a0e <iput>
}
80101afb:	c9                   	leave  
80101afc:	c3                   	ret    

80101afd <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101afd:	55                   	push   %ebp
80101afe:	89 e5                	mov    %esp,%ebp
80101b00:	53                   	push   %ebx
80101b01:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b04:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b08:	77 3e                	ja     80101b48 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b10:	83 c2 04             	add    $0x4,%edx
80101b13:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b1e:	75 20                	jne    80101b40 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b20:	8b 45 08             	mov    0x8(%ebp),%eax
80101b23:	8b 00                	mov    (%eax),%eax
80101b25:	89 04 24             	mov    %eax,(%esp)
80101b28:	e8 5b f8 ff ff       	call   80101388 <balloc>
80101b2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b30:	8b 45 08             	mov    0x8(%ebp),%eax
80101b33:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b36:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b3c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b43:	e9 bc 00 00 00       	jmp    80101c04 <bmap+0x107>
  }
  bn -= NDIRECT;
80101b48:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b4c:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b50:	0f 87 a2 00 00 00    	ja     80101bf8 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b56:	8b 45 08             	mov    0x8(%ebp),%eax
80101b59:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b63:	75 19                	jne    80101b7e <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	8b 00                	mov    (%eax),%eax
80101b6a:	89 04 24             	mov    %eax,(%esp)
80101b6d:	e8 16 f8 ff ff       	call   80101388 <balloc>
80101b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b75:	8b 45 08             	mov    0x8(%ebp),%eax
80101b78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b7b:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101b7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b81:	8b 00                	mov    (%eax),%eax
80101b83:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b86:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b8a:	89 04 24             	mov    %eax,(%esp)
80101b8d:	e8 14 e6 ff ff       	call   801001a6 <bread>
80101b92:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b98:	83 c0 18             	add    $0x18,%eax
80101b9b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ba1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ba8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bab:	01 d0                	add    %edx,%eax
80101bad:	8b 00                	mov    (%eax),%eax
80101baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bb6:	75 30                	jne    80101be8 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bbb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bc5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101bc8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcb:	8b 00                	mov    (%eax),%eax
80101bcd:	89 04 24             	mov    %eax,(%esp)
80101bd0:	e8 b3 f7 ff ff       	call   80101388 <balloc>
80101bd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bdb:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be0:	89 04 24             	mov    %eax,(%esp)
80101be3:	e8 33 1a 00 00       	call   8010361b <log_write>
    }
    brelse(bp);
80101be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101beb:	89 04 24             	mov    %eax,(%esp)
80101bee:	e8 24 e6 ff ff       	call   80100217 <brelse>
    return addr;
80101bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bf6:	eb 0c                	jmp    80101c04 <bmap+0x107>
  }

  panic("bmap: out of range");
80101bf8:	c7 04 24 76 85 10 80 	movl   $0x80108576,(%esp)
80101bff:	e8 36 e9 ff ff       	call   8010053a <panic>
}
80101c04:	83 c4 24             	add    $0x24,%esp
80101c07:	5b                   	pop    %ebx
80101c08:	5d                   	pop    %ebp
80101c09:	c3                   	ret    

80101c0a <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c0a:	55                   	push   %ebp
80101c0b:	89 e5                	mov    %esp,%ebp
80101c0d:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c17:	eb 44                	jmp    80101c5d <itrunc+0x53>
    if(ip->addrs[i]){
80101c19:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c1f:	83 c2 04             	add    $0x4,%edx
80101c22:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c26:	85 c0                	test   %eax,%eax
80101c28:	74 2f                	je     80101c59 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c30:	83 c2 04             	add    $0x4,%edx
80101c33:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c37:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3a:	8b 00                	mov    (%eax),%eax
80101c3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c40:	89 04 24             	mov    %eax,(%esp)
80101c43:	e8 8e f8 ff ff       	call   801014d6 <bfree>
      ip->addrs[i] = 0;
80101c48:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c4e:	83 c2 04             	add    $0x4,%edx
80101c51:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c58:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c5d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c61:	7e b6                	jle    80101c19 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c63:	8b 45 08             	mov    0x8(%ebp),%eax
80101c66:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c69:	85 c0                	test   %eax,%eax
80101c6b:	0f 84 9b 00 00 00    	je     80101d0c <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101c71:	8b 45 08             	mov    0x8(%ebp),%eax
80101c74:	8b 50 4c             	mov    0x4c(%eax),%edx
80101c77:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7a:	8b 00                	mov    (%eax),%eax
80101c7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c80:	89 04 24             	mov    %eax,(%esp)
80101c83:	e8 1e e5 ff ff       	call   801001a6 <bread>
80101c88:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c8e:	83 c0 18             	add    $0x18,%eax
80101c91:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101c94:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101c9b:	eb 3b                	jmp    80101cd8 <itrunc+0xce>
      if(a[j])
80101c9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ca7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101caa:	01 d0                	add    %edx,%eax
80101cac:	8b 00                	mov    (%eax),%eax
80101cae:	85 c0                	test   %eax,%eax
80101cb0:	74 22                	je     80101cd4 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cb5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cbc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cbf:	01 d0                	add    %edx,%eax
80101cc1:	8b 10                	mov    (%eax),%edx
80101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc6:	8b 00                	mov    (%eax),%eax
80101cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ccc:	89 04 24             	mov    %eax,(%esp)
80101ccf:	e8 02 f8 ff ff       	call   801014d6 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101cd4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cdb:	83 f8 7f             	cmp    $0x7f,%eax
80101cde:	76 bd                	jbe    80101c9d <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce3:	89 04 24             	mov    %eax,(%esp)
80101ce6:	e8 2c e5 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ceb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cee:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfa:	89 04 24             	mov    %eax,(%esp)
80101cfd:	e8 d4 f7 ff ff       	call   801014d6 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0f:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d16:	8b 45 08             	mov    0x8(%ebp),%eax
80101d19:	89 04 24             	mov    %eax,(%esp)
80101d1c:	e8 7e f9 ff ff       	call   8010169f <iupdate>
}
80101d21:	c9                   	leave  
80101d22:	c3                   	ret    

80101d23 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d23:	55                   	push   %ebp
80101d24:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d26:	8b 45 08             	mov    0x8(%ebp),%eax
80101d29:	8b 00                	mov    (%eax),%eax
80101d2b:	89 c2                	mov    %eax,%edx
80101d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d30:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d33:	8b 45 08             	mov    0x8(%ebp),%eax
80101d36:	8b 50 04             	mov    0x4(%eax),%edx
80101d39:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d3c:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d49:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4f:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d53:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d56:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d5d:	8b 50 18             	mov    0x18(%eax),%edx
80101d60:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d63:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d66:	5d                   	pop    %ebp
80101d67:	c3                   	ret    

80101d68 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d68:	55                   	push   %ebp
80101d69:	89 e5                	mov    %esp,%ebp
80101d6b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101d75:	66 83 f8 03          	cmp    $0x3,%ax
80101d79:	75 60                	jne    80101ddb <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d82:	66 85 c0             	test   %ax,%ax
80101d85:	78 20                	js     80101da7 <readi+0x3f>
80101d87:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d8e:	66 83 f8 09          	cmp    $0x9,%ax
80101d92:	7f 13                	jg     80101da7 <readi+0x3f>
80101d94:	8b 45 08             	mov    0x8(%ebp),%eax
80101d97:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d9b:	98                   	cwtl   
80101d9c:	8b 04 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%eax
80101da3:	85 c0                	test   %eax,%eax
80101da5:	75 0a                	jne    80101db1 <readi+0x49>
      return -1;
80101da7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101dac:	e9 19 01 00 00       	jmp    80101eca <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101db1:	8b 45 08             	mov    0x8(%ebp),%eax
80101db4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101db8:	98                   	cwtl   
80101db9:	8b 04 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%eax
80101dc0:	8b 55 14             	mov    0x14(%ebp),%edx
80101dc3:	89 54 24 08          	mov    %edx,0x8(%esp)
80101dc7:	8b 55 0c             	mov    0xc(%ebp),%edx
80101dca:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dce:	8b 55 08             	mov    0x8(%ebp),%edx
80101dd1:	89 14 24             	mov    %edx,(%esp)
80101dd4:	ff d0                	call   *%eax
80101dd6:	e9 ef 00 00 00       	jmp    80101eca <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dde:	8b 40 18             	mov    0x18(%eax),%eax
80101de1:	3b 45 10             	cmp    0x10(%ebp),%eax
80101de4:	72 0d                	jb     80101df3 <readi+0x8b>
80101de6:	8b 45 14             	mov    0x14(%ebp),%eax
80101de9:	8b 55 10             	mov    0x10(%ebp),%edx
80101dec:	01 d0                	add    %edx,%eax
80101dee:	3b 45 10             	cmp    0x10(%ebp),%eax
80101df1:	73 0a                	jae    80101dfd <readi+0x95>
    return -1;
80101df3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101df8:	e9 cd 00 00 00       	jmp    80101eca <readi+0x162>
  if(off + n > ip->size)
80101dfd:	8b 45 14             	mov    0x14(%ebp),%eax
80101e00:	8b 55 10             	mov    0x10(%ebp),%edx
80101e03:	01 c2                	add    %eax,%edx
80101e05:	8b 45 08             	mov    0x8(%ebp),%eax
80101e08:	8b 40 18             	mov    0x18(%eax),%eax
80101e0b:	39 c2                	cmp    %eax,%edx
80101e0d:	76 0c                	jbe    80101e1b <readi+0xb3>
    n = ip->size - off;
80101e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e12:	8b 40 18             	mov    0x18(%eax),%eax
80101e15:	2b 45 10             	sub    0x10(%ebp),%eax
80101e18:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e22:	e9 94 00 00 00       	jmp    80101ebb <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e27:	8b 45 10             	mov    0x10(%ebp),%eax
80101e2a:	c1 e8 09             	shr    $0x9,%eax
80101e2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e31:	8b 45 08             	mov    0x8(%ebp),%eax
80101e34:	89 04 24             	mov    %eax,(%esp)
80101e37:	e8 c1 fc ff ff       	call   80101afd <bmap>
80101e3c:	8b 55 08             	mov    0x8(%ebp),%edx
80101e3f:	8b 12                	mov    (%edx),%edx
80101e41:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e45:	89 14 24             	mov    %edx,(%esp)
80101e48:	e8 59 e3 ff ff       	call   801001a6 <bread>
80101e4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e50:	8b 45 10             	mov    0x10(%ebp),%eax
80101e53:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e58:	89 c2                	mov    %eax,%edx
80101e5a:	b8 00 02 00 00       	mov    $0x200,%eax
80101e5f:	29 d0                	sub    %edx,%eax
80101e61:	89 c2                	mov    %eax,%edx
80101e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e66:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e69:	29 c1                	sub    %eax,%ecx
80101e6b:	89 c8                	mov    %ecx,%eax
80101e6d:	39 c2                	cmp    %eax,%edx
80101e6f:	0f 46 c2             	cmovbe %edx,%eax
80101e72:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101e75:	8b 45 10             	mov    0x10(%ebp),%eax
80101e78:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e7d:	8d 50 10             	lea    0x10(%eax),%edx
80101e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e83:	01 d0                	add    %edx,%eax
80101e85:	8d 50 08             	lea    0x8(%eax),%edx
80101e88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e8b:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e93:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e96:	89 04 24             	mov    %eax,(%esp)
80101e99:	e8 25 33 00 00       	call   801051c3 <memmove>
    brelse(bp);
80101e9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ea1:	89 04 24             	mov    %eax,(%esp)
80101ea4:	e8 6e e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ea9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eac:	01 45 f4             	add    %eax,-0xc(%ebp)
80101eaf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb2:	01 45 10             	add    %eax,0x10(%ebp)
80101eb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb8:	01 45 0c             	add    %eax,0xc(%ebp)
80101ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ebe:	3b 45 14             	cmp    0x14(%ebp),%eax
80101ec1:	0f 82 60 ff ff ff    	jb     80101e27 <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101ec7:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101eca:	c9                   	leave  
80101ecb:	c3                   	ret    

80101ecc <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101ecc:	55                   	push   %ebp
80101ecd:	89 e5                	mov    %esp,%ebp
80101ecf:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ed9:	66 83 f8 03          	cmp    $0x3,%ax
80101edd:	75 60                	jne    80101f3f <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ee6:	66 85 c0             	test   %ax,%ax
80101ee9:	78 20                	js     80101f0b <writei+0x3f>
80101eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80101eee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef2:	66 83 f8 09          	cmp    $0x9,%ax
80101ef6:	7f 13                	jg     80101f0b <writei+0x3f>
80101ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80101efb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eff:	98                   	cwtl   
80101f00:	8b 04 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%eax
80101f07:	85 c0                	test   %eax,%eax
80101f09:	75 0a                	jne    80101f15 <writei+0x49>
      return -1;
80101f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f10:	e9 44 01 00 00       	jmp    80102059 <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80101f15:	8b 45 08             	mov    0x8(%ebp),%eax
80101f18:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1c:	98                   	cwtl   
80101f1d:	8b 04 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%eax
80101f24:	8b 55 14             	mov    0x14(%ebp),%edx
80101f27:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f2b:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f32:	8b 55 08             	mov    0x8(%ebp),%edx
80101f35:	89 14 24             	mov    %edx,(%esp)
80101f38:	ff d0                	call   *%eax
80101f3a:	e9 1a 01 00 00       	jmp    80102059 <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
80101f3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f42:	8b 40 18             	mov    0x18(%eax),%eax
80101f45:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f48:	72 0d                	jb     80101f57 <writei+0x8b>
80101f4a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f4d:	8b 55 10             	mov    0x10(%ebp),%edx
80101f50:	01 d0                	add    %edx,%eax
80101f52:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f55:	73 0a                	jae    80101f61 <writei+0x95>
    return -1;
80101f57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f5c:	e9 f8 00 00 00       	jmp    80102059 <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80101f61:	8b 45 14             	mov    0x14(%ebp),%eax
80101f64:	8b 55 10             	mov    0x10(%ebp),%edx
80101f67:	01 d0                	add    %edx,%eax
80101f69:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101f6e:	76 0a                	jbe    80101f7a <writei+0xae>
    return -1;
80101f70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f75:	e9 df 00 00 00       	jmp    80102059 <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101f7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f81:	e9 9f 00 00 00       	jmp    80102025 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f86:	8b 45 10             	mov    0x10(%ebp),%eax
80101f89:	c1 e8 09             	shr    $0x9,%eax
80101f8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f90:	8b 45 08             	mov    0x8(%ebp),%eax
80101f93:	89 04 24             	mov    %eax,(%esp)
80101f96:	e8 62 fb ff ff       	call   80101afd <bmap>
80101f9b:	8b 55 08             	mov    0x8(%ebp),%edx
80101f9e:	8b 12                	mov    (%edx),%edx
80101fa0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fa4:	89 14 24             	mov    %edx,(%esp)
80101fa7:	e8 fa e1 ff ff       	call   801001a6 <bread>
80101fac:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101faf:	8b 45 10             	mov    0x10(%ebp),%eax
80101fb2:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fb7:	89 c2                	mov    %eax,%edx
80101fb9:	b8 00 02 00 00       	mov    $0x200,%eax
80101fbe:	29 d0                	sub    %edx,%eax
80101fc0:	89 c2                	mov    %eax,%edx
80101fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fc5:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fc8:	29 c1                	sub    %eax,%ecx
80101fca:	89 c8                	mov    %ecx,%eax
80101fcc:	39 c2                	cmp    %eax,%edx
80101fce:	0f 46 c2             	cmovbe %edx,%eax
80101fd1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80101fd4:	8b 45 10             	mov    0x10(%ebp),%eax
80101fd7:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fdc:	8d 50 10             	lea    0x10(%eax),%edx
80101fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fe2:	01 d0                	add    %edx,%eax
80101fe4:	8d 50 08             	lea    0x8(%eax),%edx
80101fe7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fea:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fee:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ff1:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ff5:	89 14 24             	mov    %edx,(%esp)
80101ff8:	e8 c6 31 00 00       	call   801051c3 <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 13 16 00 00       	call   8010361b <log_write>
    brelse(bp);
80102008:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010200b:	89 04 24             	mov    %eax,(%esp)
8010200e:	e8 04 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102013:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102016:	01 45 f4             	add    %eax,-0xc(%ebp)
80102019:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010201c:	01 45 10             	add    %eax,0x10(%ebp)
8010201f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102022:	01 45 0c             	add    %eax,0xc(%ebp)
80102025:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102028:	3b 45 14             	cmp    0x14(%ebp),%eax
8010202b:	0f 82 55 ff ff ff    	jb     80101f86 <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102031:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102035:	74 1f                	je     80102056 <writei+0x18a>
80102037:	8b 45 08             	mov    0x8(%ebp),%eax
8010203a:	8b 40 18             	mov    0x18(%eax),%eax
8010203d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102040:	73 14                	jae    80102056 <writei+0x18a>
    ip->size = off;
80102042:	8b 45 08             	mov    0x8(%ebp),%eax
80102045:	8b 55 10             	mov    0x10(%ebp),%edx
80102048:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010204b:	8b 45 08             	mov    0x8(%ebp),%eax
8010204e:	89 04 24             	mov    %eax,(%esp)
80102051:	e8 49 f6 ff ff       	call   8010169f <iupdate>
  }
  return n;
80102056:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102059:	c9                   	leave  
8010205a:	c3                   	ret    

8010205b <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010205b:	55                   	push   %ebp
8010205c:	89 e5                	mov    %esp,%ebp
8010205e:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102061:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102068:	00 
80102069:	8b 45 0c             	mov    0xc(%ebp),%eax
8010206c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102070:	8b 45 08             	mov    0x8(%ebp),%eax
80102073:	89 04 24             	mov    %eax,(%esp)
80102076:	e8 eb 31 00 00       	call   80105266 <strncmp>
}
8010207b:	c9                   	leave  
8010207c:	c3                   	ret    

8010207d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
8010207d:	55                   	push   %ebp
8010207e:	89 e5                	mov    %esp,%ebp
80102080:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102083:	8b 45 08             	mov    0x8(%ebp),%eax
80102086:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010208a:	66 83 f8 01          	cmp    $0x1,%ax
8010208e:	74 0c                	je     8010209c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102090:	c7 04 24 89 85 10 80 	movl   $0x80108589,(%esp)
80102097:	e8 9e e4 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010209c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020a3:	e9 88 00 00 00       	jmp    80102130 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020a8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020af:	00 
801020b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020b3:	89 44 24 08          	mov    %eax,0x8(%esp)
801020b7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801020be:	8b 45 08             	mov    0x8(%ebp),%eax
801020c1:	89 04 24             	mov    %eax,(%esp)
801020c4:	e8 9f fc ff ff       	call   80101d68 <readi>
801020c9:	83 f8 10             	cmp    $0x10,%eax
801020cc:	74 0c                	je     801020da <dirlookup+0x5d>
      panic("dirlink read");
801020ce:	c7 04 24 9b 85 10 80 	movl   $0x8010859b,(%esp)
801020d5:	e8 60 e4 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801020da:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801020de:	66 85 c0             	test   %ax,%ax
801020e1:	75 02                	jne    801020e5 <dirlookup+0x68>
      continue;
801020e3:	eb 47                	jmp    8010212c <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
801020e5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020e8:	83 c0 02             	add    $0x2,%eax
801020eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801020f2:	89 04 24             	mov    %eax,(%esp)
801020f5:	e8 61 ff ff ff       	call   8010205b <namecmp>
801020fa:	85 c0                	test   %eax,%eax
801020fc:	75 2e                	jne    8010212c <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801020fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102102:	74 08                	je     8010210c <dirlookup+0x8f>
        *poff = off;
80102104:	8b 45 10             	mov    0x10(%ebp),%eax
80102107:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010210a:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010210c:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102110:	0f b7 c0             	movzwl %ax,%eax
80102113:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102116:	8b 45 08             	mov    0x8(%ebp),%eax
80102119:	8b 00                	mov    (%eax),%eax
8010211b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010211e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102122:	89 04 24             	mov    %eax,(%esp)
80102125:	e8 2d f6 ff ff       	call   80101757 <iget>
8010212a:	eb 18                	jmp    80102144 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010212c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102130:	8b 45 08             	mov    0x8(%ebp),%eax
80102133:	8b 40 18             	mov    0x18(%eax),%eax
80102136:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102139:	0f 87 69 ff ff ff    	ja     801020a8 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010213f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102144:	c9                   	leave  
80102145:	c3                   	ret    

80102146 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102146:	55                   	push   %ebp
80102147:	89 e5                	mov    %esp,%ebp
80102149:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010214c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102153:	00 
80102154:	8b 45 0c             	mov    0xc(%ebp),%eax
80102157:	89 44 24 04          	mov    %eax,0x4(%esp)
8010215b:	8b 45 08             	mov    0x8(%ebp),%eax
8010215e:	89 04 24             	mov    %eax,(%esp)
80102161:	e8 17 ff ff ff       	call   8010207d <dirlookup>
80102166:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102169:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010216d:	74 15                	je     80102184 <dirlink+0x3e>
    iput(ip);
8010216f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102172:	89 04 24             	mov    %eax,(%esp)
80102175:	e8 94 f8 ff ff       	call   80101a0e <iput>
    return -1;
8010217a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010217f:	e9 b7 00 00 00       	jmp    8010223b <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102184:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010218b:	eb 46                	jmp    801021d3 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010218d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102190:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102197:	00 
80102198:	89 44 24 08          	mov    %eax,0x8(%esp)
8010219c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010219f:	89 44 24 04          	mov    %eax,0x4(%esp)
801021a3:	8b 45 08             	mov    0x8(%ebp),%eax
801021a6:	89 04 24             	mov    %eax,(%esp)
801021a9:	e8 ba fb ff ff       	call   80101d68 <readi>
801021ae:	83 f8 10             	cmp    $0x10,%eax
801021b1:	74 0c                	je     801021bf <dirlink+0x79>
      panic("dirlink read");
801021b3:	c7 04 24 9b 85 10 80 	movl   $0x8010859b,(%esp)
801021ba:	e8 7b e3 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801021bf:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021c3:	66 85 c0             	test   %ax,%ax
801021c6:	75 02                	jne    801021ca <dirlink+0x84>
      break;
801021c8:	eb 16                	jmp    801021e0 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021cd:	83 c0 10             	add    $0x10,%eax
801021d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021d6:	8b 45 08             	mov    0x8(%ebp),%eax
801021d9:	8b 40 18             	mov    0x18(%eax),%eax
801021dc:	39 c2                	cmp    %eax,%edx
801021de:	72 ad                	jb     8010218d <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801021e0:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021e7:	00 
801021e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801021eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ef:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021f2:	83 c0 02             	add    $0x2,%eax
801021f5:	89 04 24             	mov    %eax,(%esp)
801021f8:	e8 bf 30 00 00       	call   801052bc <strncpy>
  de.inum = inum;
801021fd:	8b 45 10             	mov    0x10(%ebp),%eax
80102200:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102207:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010220e:	00 
8010220f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102213:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102216:	89 44 24 04          	mov    %eax,0x4(%esp)
8010221a:	8b 45 08             	mov    0x8(%ebp),%eax
8010221d:	89 04 24             	mov    %eax,(%esp)
80102220:	e8 a7 fc ff ff       	call   80101ecc <writei>
80102225:	83 f8 10             	cmp    $0x10,%eax
80102228:	74 0c                	je     80102236 <dirlink+0xf0>
    panic("dirlink");
8010222a:	c7 04 24 a8 85 10 80 	movl   $0x801085a8,(%esp)
80102231:	e8 04 e3 ff ff       	call   8010053a <panic>
  
  return 0;
80102236:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010223b:	c9                   	leave  
8010223c:	c3                   	ret    

8010223d <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010223d:	55                   	push   %ebp
8010223e:	89 e5                	mov    %esp,%ebp
80102240:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102243:	eb 04                	jmp    80102249 <skipelem+0xc>
    path++;
80102245:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102249:	8b 45 08             	mov    0x8(%ebp),%eax
8010224c:	0f b6 00             	movzbl (%eax),%eax
8010224f:	3c 2f                	cmp    $0x2f,%al
80102251:	74 f2                	je     80102245 <skipelem+0x8>
    path++;
  if(*path == 0)
80102253:	8b 45 08             	mov    0x8(%ebp),%eax
80102256:	0f b6 00             	movzbl (%eax),%eax
80102259:	84 c0                	test   %al,%al
8010225b:	75 0a                	jne    80102267 <skipelem+0x2a>
    return 0;
8010225d:	b8 00 00 00 00       	mov    $0x0,%eax
80102262:	e9 86 00 00 00       	jmp    801022ed <skipelem+0xb0>
  s = path;
80102267:	8b 45 08             	mov    0x8(%ebp),%eax
8010226a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010226d:	eb 04                	jmp    80102273 <skipelem+0x36>
    path++;
8010226f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102273:	8b 45 08             	mov    0x8(%ebp),%eax
80102276:	0f b6 00             	movzbl (%eax),%eax
80102279:	3c 2f                	cmp    $0x2f,%al
8010227b:	74 0a                	je     80102287 <skipelem+0x4a>
8010227d:	8b 45 08             	mov    0x8(%ebp),%eax
80102280:	0f b6 00             	movzbl (%eax),%eax
80102283:	84 c0                	test   %al,%al
80102285:	75 e8                	jne    8010226f <skipelem+0x32>
    path++;
  len = path - s;
80102287:	8b 55 08             	mov    0x8(%ebp),%edx
8010228a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010228d:	29 c2                	sub    %eax,%edx
8010228f:	89 d0                	mov    %edx,%eax
80102291:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102294:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102298:	7e 1c                	jle    801022b6 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010229a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022a1:	00 
801022a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801022ac:	89 04 24             	mov    %eax,(%esp)
801022af:	e8 0f 2f 00 00       	call   801051c3 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022b4:	eb 2a                	jmp    801022e0 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801022bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801022c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022c7:	89 04 24             	mov    %eax,(%esp)
801022ca:	e8 f4 2e 00 00       	call   801051c3 <memmove>
    name[len] = 0;
801022cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801022d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801022d5:	01 d0                	add    %edx,%eax
801022d7:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801022da:	eb 04                	jmp    801022e0 <skipelem+0xa3>
    path++;
801022dc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022e0:	8b 45 08             	mov    0x8(%ebp),%eax
801022e3:	0f b6 00             	movzbl (%eax),%eax
801022e6:	3c 2f                	cmp    $0x2f,%al
801022e8:	74 f2                	je     801022dc <skipelem+0x9f>
    path++;
  return path;
801022ea:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022ed:	c9                   	leave  
801022ee:	c3                   	ret    

801022ef <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801022ef:	55                   	push   %ebp
801022f0:	89 e5                	mov    %esp,%ebp
801022f2:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801022f5:	8b 45 08             	mov    0x8(%ebp),%eax
801022f8:	0f b6 00             	movzbl (%eax),%eax
801022fb:	3c 2f                	cmp    $0x2f,%al
801022fd:	75 1c                	jne    8010231b <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801022ff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102306:	00 
80102307:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010230e:	e8 44 f4 ff ff       	call   80101757 <iget>
80102313:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102316:	e9 af 00 00 00       	jmp    801023ca <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010231b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102321:	8b 40 68             	mov    0x68(%eax),%eax
80102324:	89 04 24             	mov    %eax,(%esp)
80102327:	e8 fd f4 ff ff       	call   80101829 <idup>
8010232c:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010232f:	e9 96 00 00 00       	jmp    801023ca <namex+0xdb>
    ilock(ip);
80102334:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102337:	89 04 24             	mov    %eax,(%esp)
8010233a:	e8 1c f5 ff ff       	call   8010185b <ilock>
    if(ip->type != T_DIR){
8010233f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102342:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102346:	66 83 f8 01          	cmp    $0x1,%ax
8010234a:	74 15                	je     80102361 <namex+0x72>
      iunlockput(ip);
8010234c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010234f:	89 04 24             	mov    %eax,(%esp)
80102352:	e8 88 f7 ff ff       	call   80101adf <iunlockput>
      return 0;
80102357:	b8 00 00 00 00       	mov    $0x0,%eax
8010235c:	e9 a3 00 00 00       	jmp    80102404 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102361:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102365:	74 1d                	je     80102384 <namex+0x95>
80102367:	8b 45 08             	mov    0x8(%ebp),%eax
8010236a:	0f b6 00             	movzbl (%eax),%eax
8010236d:	84 c0                	test   %al,%al
8010236f:	75 13                	jne    80102384 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102374:	89 04 24             	mov    %eax,(%esp)
80102377:	e8 2d f6 ff ff       	call   801019a9 <iunlock>
      return ip;
8010237c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237f:	e9 80 00 00 00       	jmp    80102404 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102384:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010238b:	00 
8010238c:	8b 45 10             	mov    0x10(%ebp),%eax
8010238f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102396:	89 04 24             	mov    %eax,(%esp)
80102399:	e8 df fc ff ff       	call   8010207d <dirlookup>
8010239e:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023a1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023a5:	75 12                	jne    801023b9 <namex+0xca>
      iunlockput(ip);
801023a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023aa:	89 04 24             	mov    %eax,(%esp)
801023ad:	e8 2d f7 ff ff       	call   80101adf <iunlockput>
      return 0;
801023b2:	b8 00 00 00 00       	mov    $0x0,%eax
801023b7:	eb 4b                	jmp    80102404 <namex+0x115>
    }
    iunlockput(ip);
801023b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023bc:	89 04 24             	mov    %eax,(%esp)
801023bf:	e8 1b f7 ff ff       	call   80101adf <iunlockput>
    ip = next;
801023c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023ca:	8b 45 10             	mov    0x10(%ebp),%eax
801023cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d1:	8b 45 08             	mov    0x8(%ebp),%eax
801023d4:	89 04 24             	mov    %eax,(%esp)
801023d7:	e8 61 fe ff ff       	call   8010223d <skipelem>
801023dc:	89 45 08             	mov    %eax,0x8(%ebp)
801023df:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023e3:	0f 85 4b ff ff ff    	jne    80102334 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801023e9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023ed:	74 12                	je     80102401 <namex+0x112>
    iput(ip);
801023ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f2:	89 04 24             	mov    %eax,(%esp)
801023f5:	e8 14 f6 ff ff       	call   80101a0e <iput>
    return 0;
801023fa:	b8 00 00 00 00       	mov    $0x0,%eax
801023ff:	eb 03                	jmp    80102404 <namex+0x115>
  }
  return ip;
80102401:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102404:	c9                   	leave  
80102405:	c3                   	ret    

80102406 <namei>:

struct inode*
namei(char *path)
{
80102406:	55                   	push   %ebp
80102407:	89 e5                	mov    %esp,%ebp
80102409:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010240c:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010240f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102413:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010241a:	00 
8010241b:	8b 45 08             	mov    0x8(%ebp),%eax
8010241e:	89 04 24             	mov    %eax,(%esp)
80102421:	e8 c9 fe ff ff       	call   801022ef <namex>
}
80102426:	c9                   	leave  
80102427:	c3                   	ret    

80102428 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102428:	55                   	push   %ebp
80102429:	89 e5                	mov    %esp,%ebp
8010242b:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010242e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102431:	89 44 24 08          	mov    %eax,0x8(%esp)
80102435:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010243c:	00 
8010243d:	8b 45 08             	mov    0x8(%ebp),%eax
80102440:	89 04 24             	mov    %eax,(%esp)
80102443:	e8 a7 fe ff ff       	call   801022ef <namex>
}
80102448:	c9                   	leave  
80102449:	c3                   	ret    

8010244a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010244a:	55                   	push   %ebp
8010244b:	89 e5                	mov    %esp,%ebp
8010244d:	83 ec 14             	sub    $0x14,%esp
80102450:	8b 45 08             	mov    0x8(%ebp),%eax
80102453:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102457:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010245b:	89 c2                	mov    %eax,%edx
8010245d:	ec                   	in     (%dx),%al
8010245e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102461:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102465:	c9                   	leave  
80102466:	c3                   	ret    

80102467 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102467:	55                   	push   %ebp
80102468:	89 e5                	mov    %esp,%ebp
8010246a:	57                   	push   %edi
8010246b:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010246c:	8b 55 08             	mov    0x8(%ebp),%edx
8010246f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102472:	8b 45 10             	mov    0x10(%ebp),%eax
80102475:	89 cb                	mov    %ecx,%ebx
80102477:	89 df                	mov    %ebx,%edi
80102479:	89 c1                	mov    %eax,%ecx
8010247b:	fc                   	cld    
8010247c:	f3 6d                	rep insl (%dx),%es:(%edi)
8010247e:	89 c8                	mov    %ecx,%eax
80102480:	89 fb                	mov    %edi,%ebx
80102482:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102485:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102488:	5b                   	pop    %ebx
80102489:	5f                   	pop    %edi
8010248a:	5d                   	pop    %ebp
8010248b:	c3                   	ret    

8010248c <outb>:

static inline void
outb(ushort port, uchar data)
{
8010248c:	55                   	push   %ebp
8010248d:	89 e5                	mov    %esp,%ebp
8010248f:	83 ec 08             	sub    $0x8,%esp
80102492:	8b 55 08             	mov    0x8(%ebp),%edx
80102495:	8b 45 0c             	mov    0xc(%ebp),%eax
80102498:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010249c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010249f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024a3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024a7:	ee                   	out    %al,(%dx)
}
801024a8:	c9                   	leave  
801024a9:	c3                   	ret    

801024aa <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024aa:	55                   	push   %ebp
801024ab:	89 e5                	mov    %esp,%ebp
801024ad:	56                   	push   %esi
801024ae:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801024af:	8b 55 08             	mov    0x8(%ebp),%edx
801024b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024b5:	8b 45 10             	mov    0x10(%ebp),%eax
801024b8:	89 cb                	mov    %ecx,%ebx
801024ba:	89 de                	mov    %ebx,%esi
801024bc:	89 c1                	mov    %eax,%ecx
801024be:	fc                   	cld    
801024bf:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801024c1:	89 c8                	mov    %ecx,%eax
801024c3:	89 f3                	mov    %esi,%ebx
801024c5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024c8:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801024cb:	5b                   	pop    %ebx
801024cc:	5e                   	pop    %esi
801024cd:	5d                   	pop    %ebp
801024ce:	c3                   	ret    

801024cf <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801024cf:	55                   	push   %ebp
801024d0:	89 e5                	mov    %esp,%ebp
801024d2:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801024d5:	90                   	nop
801024d6:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801024dd:	e8 68 ff ff ff       	call   8010244a <inb>
801024e2:	0f b6 c0             	movzbl %al,%eax
801024e5:	89 45 fc             	mov    %eax,-0x4(%ebp)
801024e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024eb:	25 c0 00 00 00       	and    $0xc0,%eax
801024f0:	83 f8 40             	cmp    $0x40,%eax
801024f3:	75 e1                	jne    801024d6 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801024f5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801024f9:	74 11                	je     8010250c <idewait+0x3d>
801024fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024fe:	83 e0 21             	and    $0x21,%eax
80102501:	85 c0                	test   %eax,%eax
80102503:	74 07                	je     8010250c <idewait+0x3d>
    return -1;
80102505:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010250a:	eb 05                	jmp    80102511 <idewait+0x42>
  return 0;
8010250c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102511:	c9                   	leave  
80102512:	c3                   	ret    

80102513 <ideinit>:

void
ideinit(void)
{
80102513:	55                   	push   %ebp
80102514:	89 e5                	mov    %esp,%ebp
80102516:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102519:	c7 44 24 04 b0 85 10 	movl   $0x801085b0,0x4(%esp)
80102520:	80 
80102521:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102528:	e8 52 29 00 00       	call   80104e7f <initlock>
  picenable(IRQ_IDE);
8010252d:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102534:	e8 7b 18 00 00       	call   80103db4 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102539:	a1 40 29 11 80       	mov    0x80112940,%eax
8010253e:	83 e8 01             	sub    $0x1,%eax
80102541:	89 44 24 04          	mov    %eax,0x4(%esp)
80102545:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254c:	e8 0c 04 00 00       	call   8010295d <ioapicenable>
  idewait(0);
80102551:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102558:	e8 72 ff ff ff       	call   801024cf <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
8010255d:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102564:	00 
80102565:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010256c:	e8 1b ff ff ff       	call   8010248c <outb>
  for(i=0; i<1000; i++){
80102571:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102578:	eb 20                	jmp    8010259a <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010257a:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102581:	e8 c4 fe ff ff       	call   8010244a <inb>
80102586:	84 c0                	test   %al,%al
80102588:	74 0c                	je     80102596 <ideinit+0x83>
      havedisk1 = 1;
8010258a:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102591:	00 00 00 
      break;
80102594:	eb 0d                	jmp    801025a3 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102596:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010259a:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025a1:	7e d7                	jle    8010257a <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025a3:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025aa:	00 
801025ab:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025b2:	e8 d5 fe ff ff       	call   8010248c <outb>
}
801025b7:	c9                   	leave  
801025b8:	c3                   	ret    

801025b9 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801025b9:	55                   	push   %ebp
801025ba:	89 e5                	mov    %esp,%ebp
801025bc:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801025bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025c3:	75 0c                	jne    801025d1 <idestart+0x18>
    panic("idestart");
801025c5:	c7 04 24 b4 85 10 80 	movl   $0x801085b4,(%esp)
801025cc:	e8 69 df ff ff       	call   8010053a <panic>

  idewait(0);
801025d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025d8:	e8 f2 fe ff ff       	call   801024cf <idewait>
  outb(0x3f6, 0);  // generate interrupt
801025dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025e4:	00 
801025e5:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801025ec:	e8 9b fe ff ff       	call   8010248c <outb>
  outb(0x1f2, 1);  // number of sectors
801025f1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801025f8:	00 
801025f9:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102600:	e8 87 fe ff ff       	call   8010248c <outb>
  outb(0x1f3, b->sector & 0xff);
80102605:	8b 45 08             	mov    0x8(%ebp),%eax
80102608:	8b 40 08             	mov    0x8(%eax),%eax
8010260b:	0f b6 c0             	movzbl %al,%eax
8010260e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102612:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102619:	e8 6e fe ff ff       	call   8010248c <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
8010261e:	8b 45 08             	mov    0x8(%ebp),%eax
80102621:	8b 40 08             	mov    0x8(%eax),%eax
80102624:	c1 e8 08             	shr    $0x8,%eax
80102627:	0f b6 c0             	movzbl %al,%eax
8010262a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010262e:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102635:	e8 52 fe ff ff       	call   8010248c <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
8010263a:	8b 45 08             	mov    0x8(%ebp),%eax
8010263d:	8b 40 08             	mov    0x8(%eax),%eax
80102640:	c1 e8 10             	shr    $0x10,%eax
80102643:	0f b6 c0             	movzbl %al,%eax
80102646:	89 44 24 04          	mov    %eax,0x4(%esp)
8010264a:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102651:	e8 36 fe ff ff       	call   8010248c <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102656:	8b 45 08             	mov    0x8(%ebp),%eax
80102659:	8b 40 04             	mov    0x4(%eax),%eax
8010265c:	83 e0 01             	and    $0x1,%eax
8010265f:	c1 e0 04             	shl    $0x4,%eax
80102662:	89 c2                	mov    %eax,%edx
80102664:	8b 45 08             	mov    0x8(%ebp),%eax
80102667:	8b 40 08             	mov    0x8(%eax),%eax
8010266a:	c1 e8 18             	shr    $0x18,%eax
8010266d:	83 e0 0f             	and    $0xf,%eax
80102670:	09 d0                	or     %edx,%eax
80102672:	83 c8 e0             	or     $0xffffffe0,%eax
80102675:	0f b6 c0             	movzbl %al,%eax
80102678:	89 44 24 04          	mov    %eax,0x4(%esp)
8010267c:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102683:	e8 04 fe ff ff       	call   8010248c <outb>
  if(b->flags & B_DIRTY){
80102688:	8b 45 08             	mov    0x8(%ebp),%eax
8010268b:	8b 00                	mov    (%eax),%eax
8010268d:	83 e0 04             	and    $0x4,%eax
80102690:	85 c0                	test   %eax,%eax
80102692:	74 34                	je     801026c8 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80102694:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
8010269b:	00 
8010269c:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026a3:	e8 e4 fd ff ff       	call   8010248c <outb>
    outsl(0x1f0, b->data, 512/4);
801026a8:	8b 45 08             	mov    0x8(%ebp),%eax
801026ab:	83 c0 18             	add    $0x18,%eax
801026ae:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801026b5:	00 
801026b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801026ba:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801026c1:	e8 e4 fd ff ff       	call   801024aa <outsl>
801026c6:	eb 14                	jmp    801026dc <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801026c8:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801026cf:	00 
801026d0:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026d7:	e8 b0 fd ff ff       	call   8010248c <outb>
  }
}
801026dc:	c9                   	leave  
801026dd:	c3                   	ret    

801026de <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801026de:	55                   	push   %ebp
801026df:	89 e5                	mov    %esp,%ebp
801026e1:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801026e4:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801026eb:	e8 b0 27 00 00       	call   80104ea0 <acquire>
  if((b = idequeue) == 0){
801026f0:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801026f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026fc:	75 11                	jne    8010270f <ideintr+0x31>
    release(&idelock);
801026fe:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102705:	e8 f8 27 00 00       	call   80104f02 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
8010270a:	e9 90 00 00 00       	jmp    8010279f <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010270f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102712:	8b 40 14             	mov    0x14(%eax),%eax
80102715:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
8010271a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010271d:	8b 00                	mov    (%eax),%eax
8010271f:	83 e0 04             	and    $0x4,%eax
80102722:	85 c0                	test   %eax,%eax
80102724:	75 2e                	jne    80102754 <ideintr+0x76>
80102726:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010272d:	e8 9d fd ff ff       	call   801024cf <idewait>
80102732:	85 c0                	test   %eax,%eax
80102734:	78 1e                	js     80102754 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102739:	83 c0 18             	add    $0x18,%eax
8010273c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102743:	00 
80102744:	89 44 24 04          	mov    %eax,0x4(%esp)
80102748:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010274f:	e8 13 fd ff ff       	call   80102467 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102754:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102757:	8b 00                	mov    (%eax),%eax
80102759:	83 c8 02             	or     $0x2,%eax
8010275c:	89 c2                	mov    %eax,%edx
8010275e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102761:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102763:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102766:	8b 00                	mov    (%eax),%eax
80102768:	83 e0 fb             	and    $0xfffffffb,%eax
8010276b:	89 c2                	mov    %eax,%edx
8010276d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102770:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102772:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102775:	89 04 24             	mov    %eax,(%esp)
80102778:	e8 28 25 00 00       	call   80104ca5 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
8010277d:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102782:	85 c0                	test   %eax,%eax
80102784:	74 0d                	je     80102793 <ideintr+0xb5>
    idestart(idequeue);
80102786:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010278b:	89 04 24             	mov    %eax,(%esp)
8010278e:	e8 26 fe ff ff       	call   801025b9 <idestart>

  release(&idelock);
80102793:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010279a:	e8 63 27 00 00       	call   80104f02 <release>
}
8010279f:	c9                   	leave  
801027a0:	c3                   	ret    

801027a1 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027a1:	55                   	push   %ebp
801027a2:	89 e5                	mov    %esp,%ebp
801027a4:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027a7:	8b 45 08             	mov    0x8(%ebp),%eax
801027aa:	8b 00                	mov    (%eax),%eax
801027ac:	83 e0 01             	and    $0x1,%eax
801027af:	85 c0                	test   %eax,%eax
801027b1:	75 0c                	jne    801027bf <iderw+0x1e>
    panic("iderw: buf not busy");
801027b3:	c7 04 24 bd 85 10 80 	movl   $0x801085bd,(%esp)
801027ba:	e8 7b dd ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027bf:	8b 45 08             	mov    0x8(%ebp),%eax
801027c2:	8b 00                	mov    (%eax),%eax
801027c4:	83 e0 06             	and    $0x6,%eax
801027c7:	83 f8 02             	cmp    $0x2,%eax
801027ca:	75 0c                	jne    801027d8 <iderw+0x37>
    panic("iderw: nothing to do");
801027cc:	c7 04 24 d1 85 10 80 	movl   $0x801085d1,(%esp)
801027d3:	e8 62 dd ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801027d8:	8b 45 08             	mov    0x8(%ebp),%eax
801027db:	8b 40 04             	mov    0x4(%eax),%eax
801027de:	85 c0                	test   %eax,%eax
801027e0:	74 15                	je     801027f7 <iderw+0x56>
801027e2:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801027e7:	85 c0                	test   %eax,%eax
801027e9:	75 0c                	jne    801027f7 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027eb:	c7 04 24 e6 85 10 80 	movl   $0x801085e6,(%esp)
801027f2:	e8 43 dd ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
801027f7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027fe:	e8 9d 26 00 00       	call   80104ea0 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102803:	8b 45 08             	mov    0x8(%ebp),%eax
80102806:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
8010280d:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102814:	eb 0b                	jmp    80102821 <iderw+0x80>
80102816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102819:	8b 00                	mov    (%eax),%eax
8010281b:	83 c0 14             	add    $0x14,%eax
8010281e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102824:	8b 00                	mov    (%eax),%eax
80102826:	85 c0                	test   %eax,%eax
80102828:	75 ec                	jne    80102816 <iderw+0x75>
    ;
  *pp = b;
8010282a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282d:	8b 55 08             	mov    0x8(%ebp),%edx
80102830:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102832:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102837:	3b 45 08             	cmp    0x8(%ebp),%eax
8010283a:	75 0d                	jne    80102849 <iderw+0xa8>
    idestart(b);
8010283c:	8b 45 08             	mov    0x8(%ebp),%eax
8010283f:	89 04 24             	mov    %eax,(%esp)
80102842:	e8 72 fd ff ff       	call   801025b9 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102847:	eb 15                	jmp    8010285e <iderw+0xbd>
80102849:	eb 13                	jmp    8010285e <iderw+0xbd>
    sleep(b, &idelock);
8010284b:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
80102852:	80 
80102853:	8b 45 08             	mov    0x8(%ebp),%eax
80102856:	89 04 24             	mov    %eax,(%esp)
80102859:	e8 6f 23 00 00       	call   80104bcd <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010285e:	8b 45 08             	mov    0x8(%ebp),%eax
80102861:	8b 00                	mov    (%eax),%eax
80102863:	83 e0 06             	and    $0x6,%eax
80102866:	83 f8 02             	cmp    $0x2,%eax
80102869:	75 e0                	jne    8010284b <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
8010286b:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102872:	e8 8b 26 00 00       	call   80104f02 <release>
}
80102877:	c9                   	leave  
80102878:	c3                   	ret    

80102879 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102879:	55                   	push   %ebp
8010287a:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010287c:	a1 14 22 11 80       	mov    0x80112214,%eax
80102881:	8b 55 08             	mov    0x8(%ebp),%edx
80102884:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102886:	a1 14 22 11 80       	mov    0x80112214,%eax
8010288b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010288e:	5d                   	pop    %ebp
8010288f:	c3                   	ret    

80102890 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102890:	55                   	push   %ebp
80102891:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102893:	a1 14 22 11 80       	mov    0x80112214,%eax
80102898:	8b 55 08             	mov    0x8(%ebp),%edx
8010289b:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
8010289d:	a1 14 22 11 80       	mov    0x80112214,%eax
801028a2:	8b 55 0c             	mov    0xc(%ebp),%edx
801028a5:	89 50 10             	mov    %edx,0x10(%eax)
}
801028a8:	5d                   	pop    %ebp
801028a9:	c3                   	ret    

801028aa <ioapicinit>:

void
ioapicinit(void)
{
801028aa:	55                   	push   %ebp
801028ab:	89 e5                	mov    %esp,%ebp
801028ad:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801028b0:	a1 44 23 11 80       	mov    0x80112344,%eax
801028b5:	85 c0                	test   %eax,%eax
801028b7:	75 05                	jne    801028be <ioapicinit+0x14>
    return;
801028b9:	e9 9d 00 00 00       	jmp    8010295b <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
801028be:	c7 05 14 22 11 80 00 	movl   $0xfec00000,0x80112214
801028c5:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801028c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801028cf:	e8 a5 ff ff ff       	call   80102879 <ioapicread>
801028d4:	c1 e8 10             	shr    $0x10,%eax
801028d7:	25 ff 00 00 00       	and    $0xff,%eax
801028dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801028df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801028e6:	e8 8e ff ff ff       	call   80102879 <ioapicread>
801028eb:	c1 e8 18             	shr    $0x18,%eax
801028ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801028f1:	0f b6 05 40 23 11 80 	movzbl 0x80112340,%eax
801028f8:	0f b6 c0             	movzbl %al,%eax
801028fb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801028fe:	74 0c                	je     8010290c <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102900:	c7 04 24 04 86 10 80 	movl   $0x80108604,(%esp)
80102907:	e8 94 da ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010290c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102913:	eb 3e                	jmp    80102953 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102915:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102918:	83 c0 20             	add    $0x20,%eax
8010291b:	0d 00 00 01 00       	or     $0x10000,%eax
80102920:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102923:	83 c2 08             	add    $0x8,%edx
80102926:	01 d2                	add    %edx,%edx
80102928:	89 44 24 04          	mov    %eax,0x4(%esp)
8010292c:	89 14 24             	mov    %edx,(%esp)
8010292f:	e8 5c ff ff ff       	call   80102890 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102937:	83 c0 08             	add    $0x8,%eax
8010293a:	01 c0                	add    %eax,%eax
8010293c:	83 c0 01             	add    $0x1,%eax
8010293f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102946:	00 
80102947:	89 04 24             	mov    %eax,(%esp)
8010294a:	e8 41 ff ff ff       	call   80102890 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010294f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102953:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102956:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102959:	7e ba                	jle    80102915 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
8010295b:	c9                   	leave  
8010295c:	c3                   	ret    

8010295d <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010295d:	55                   	push   %ebp
8010295e:	89 e5                	mov    %esp,%ebp
80102960:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102963:	a1 44 23 11 80       	mov    0x80112344,%eax
80102968:	85 c0                	test   %eax,%eax
8010296a:	75 02                	jne    8010296e <ioapicenable+0x11>
    return;
8010296c:	eb 37                	jmp    801029a5 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
8010296e:	8b 45 08             	mov    0x8(%ebp),%eax
80102971:	83 c0 20             	add    $0x20,%eax
80102974:	8b 55 08             	mov    0x8(%ebp),%edx
80102977:	83 c2 08             	add    $0x8,%edx
8010297a:	01 d2                	add    %edx,%edx
8010297c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102980:	89 14 24             	mov    %edx,(%esp)
80102983:	e8 08 ff ff ff       	call   80102890 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102988:	8b 45 0c             	mov    0xc(%ebp),%eax
8010298b:	c1 e0 18             	shl    $0x18,%eax
8010298e:	8b 55 08             	mov    0x8(%ebp),%edx
80102991:	83 c2 08             	add    $0x8,%edx
80102994:	01 d2                	add    %edx,%edx
80102996:	83 c2 01             	add    $0x1,%edx
80102999:	89 44 24 04          	mov    %eax,0x4(%esp)
8010299d:	89 14 24             	mov    %edx,(%esp)
801029a0:	e8 eb fe ff ff       	call   80102890 <ioapicwrite>
}
801029a5:	c9                   	leave  
801029a6:	c3                   	ret    

801029a7 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801029a7:	55                   	push   %ebp
801029a8:	89 e5                	mov    %esp,%ebp
801029aa:	8b 45 08             	mov    0x8(%ebp),%eax
801029ad:	05 00 00 00 80       	add    $0x80000000,%eax
801029b2:	5d                   	pop    %ebp
801029b3:	c3                   	ret    

801029b4 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029b4:	55                   	push   %ebp
801029b5:	89 e5                	mov    %esp,%ebp
801029b7:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029ba:	c7 44 24 04 36 86 10 	movl   $0x80108636,0x4(%esp)
801029c1:	80 
801029c2:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
801029c9:	e8 b1 24 00 00       	call   80104e7f <initlock>
  kmem.use_lock = 0;
801029ce:	c7 05 54 22 11 80 00 	movl   $0x0,0x80112254
801029d5:	00 00 00 
  freerange(vstart, vend);
801029d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801029db:	89 44 24 04          	mov    %eax,0x4(%esp)
801029df:	8b 45 08             	mov    0x8(%ebp),%eax
801029e2:	89 04 24             	mov    %eax,(%esp)
801029e5:	e8 26 00 00 00       	call   80102a10 <freerange>
}
801029ea:	c9                   	leave  
801029eb:	c3                   	ret    

801029ec <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801029ec:	55                   	push   %ebp
801029ed:	89 e5                	mov    %esp,%ebp
801029ef:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801029f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801029f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801029f9:	8b 45 08             	mov    0x8(%ebp),%eax
801029fc:	89 04 24             	mov    %eax,(%esp)
801029ff:	e8 0c 00 00 00       	call   80102a10 <freerange>
  kmem.use_lock = 1;
80102a04:	c7 05 54 22 11 80 01 	movl   $0x1,0x80112254
80102a0b:	00 00 00 
}
80102a0e:	c9                   	leave  
80102a0f:	c3                   	ret    

80102a10 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a10:	55                   	push   %ebp
80102a11:	89 e5                	mov    %esp,%ebp
80102a13:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a16:	8b 45 08             	mov    0x8(%ebp),%eax
80102a19:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a23:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a26:	eb 12                	jmp    80102a3a <freerange+0x2a>
    kfree(p);
80102a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a2b:	89 04 24             	mov    %eax,(%esp)
80102a2e:	e8 16 00 00 00       	call   80102a49 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a33:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a3d:	05 00 10 00 00       	add    $0x1000,%eax
80102a42:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a45:	76 e1                	jbe    80102a28 <freerange+0x18>
    kfree(p);
}
80102a47:	c9                   	leave  
80102a48:	c3                   	ret    

80102a49 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a49:	55                   	push   %ebp
80102a4a:	89 e5                	mov    %esp,%ebp
80102a4c:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a52:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a57:	85 c0                	test   %eax,%eax
80102a59:	75 1b                	jne    80102a76 <kfree+0x2d>
80102a5b:	81 7d 08 3c 51 11 80 	cmpl   $0x8011513c,0x8(%ebp)
80102a62:	72 12                	jb     80102a76 <kfree+0x2d>
80102a64:	8b 45 08             	mov    0x8(%ebp),%eax
80102a67:	89 04 24             	mov    %eax,(%esp)
80102a6a:	e8 38 ff ff ff       	call   801029a7 <v2p>
80102a6f:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102a74:	76 0c                	jbe    80102a82 <kfree+0x39>
    panic("kfree");
80102a76:	c7 04 24 3b 86 10 80 	movl   $0x8010863b,(%esp)
80102a7d:	e8 b8 da ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102a82:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102a89:	00 
80102a8a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102a91:	00 
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 57 26 00 00       	call   801050f4 <memset>

  if(kmem.use_lock)
80102a9d:	a1 54 22 11 80       	mov    0x80112254,%eax
80102aa2:	85 c0                	test   %eax,%eax
80102aa4:	74 0c                	je     80102ab2 <kfree+0x69>
    acquire(&kmem.lock);
80102aa6:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102aad:	e8 ee 23 00 00       	call   80104ea0 <acquire>
  r = (struct run*)v;
80102ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ab8:	8b 15 58 22 11 80    	mov    0x80112258,%edx
80102abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ac1:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ac6:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102acb:	a1 54 22 11 80       	mov    0x80112254,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x97>
    release(&kmem.lock);
80102ad4:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102adb:	e8 22 24 00 00       	call   80104f02 <release>
}
80102ae0:	c9                   	leave  
80102ae1:	c3                   	ret    

80102ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102ae2:	55                   	push   %ebp
80102ae3:	89 e5                	mov    %esp,%ebp
80102ae5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102ae8:	a1 54 22 11 80       	mov    0x80112254,%eax
80102aed:	85 c0                	test   %eax,%eax
80102aef:	74 0c                	je     80102afd <kalloc+0x1b>
    acquire(&kmem.lock);
80102af1:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102af8:	e8 a3 23 00 00       	call   80104ea0 <acquire>
  r = kmem.freelist;
80102afd:	a1 58 22 11 80       	mov    0x80112258,%eax
80102b02:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b09:	74 0a                	je     80102b15 <kalloc+0x33>
    kmem.freelist = r->next;
80102b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b0e:	8b 00                	mov    (%eax),%eax
80102b10:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102b15:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b1a:	85 c0                	test   %eax,%eax
80102b1c:	74 0c                	je     80102b2a <kalloc+0x48>
    release(&kmem.lock);
80102b1e:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b25:	e8 d8 23 00 00       	call   80104f02 <release>
  return (char*)r;
80102b2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b2d:	c9                   	leave  
80102b2e:	c3                   	ret    

80102b2f <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b2f:	55                   	push   %ebp
80102b30:	89 e5                	mov    %esp,%ebp
80102b32:	83 ec 14             	sub    $0x14,%esp
80102b35:	8b 45 08             	mov    0x8(%ebp),%eax
80102b38:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b3c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b40:	89 c2                	mov    %eax,%edx
80102b42:	ec                   	in     (%dx),%al
80102b43:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b46:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b4a:	c9                   	leave  
80102b4b:	c3                   	ret    

80102b4c <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102b4c:	55                   	push   %ebp
80102b4d:	89 e5                	mov    %esp,%ebp
80102b4f:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102b52:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102b59:	e8 d1 ff ff ff       	call   80102b2f <inb>
80102b5e:	0f b6 c0             	movzbl %al,%eax
80102b61:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b67:	83 e0 01             	and    $0x1,%eax
80102b6a:	85 c0                	test   %eax,%eax
80102b6c:	75 0a                	jne    80102b78 <kbdgetc+0x2c>
    return -1;
80102b6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b73:	e9 25 01 00 00       	jmp    80102c9d <kbdgetc+0x151>
  data = inb(KBDATAP);
80102b78:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102b7f:	e8 ab ff ff ff       	call   80102b2f <inb>
80102b84:	0f b6 c0             	movzbl %al,%eax
80102b87:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102b8a:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102b91:	75 17                	jne    80102baa <kbdgetc+0x5e>
    shift |= E0ESC;
80102b93:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102b98:	83 c8 40             	or     $0x40,%eax
80102b9b:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102ba0:	b8 00 00 00 00       	mov    $0x0,%eax
80102ba5:	e9 f3 00 00 00       	jmp    80102c9d <kbdgetc+0x151>
  } else if(data & 0x80){
80102baa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bad:	25 80 00 00 00       	and    $0x80,%eax
80102bb2:	85 c0                	test   %eax,%eax
80102bb4:	74 45                	je     80102bfb <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102bb6:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bbb:	83 e0 40             	and    $0x40,%eax
80102bbe:	85 c0                	test   %eax,%eax
80102bc0:	75 08                	jne    80102bca <kbdgetc+0x7e>
80102bc2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bc5:	83 e0 7f             	and    $0x7f,%eax
80102bc8:	eb 03                	jmp    80102bcd <kbdgetc+0x81>
80102bca:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bcd:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102bd0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bd3:	05 20 90 10 80       	add    $0x80109020,%eax
80102bd8:	0f b6 00             	movzbl (%eax),%eax
80102bdb:	83 c8 40             	or     $0x40,%eax
80102bde:	0f b6 c0             	movzbl %al,%eax
80102be1:	f7 d0                	not    %eax
80102be3:	89 c2                	mov    %eax,%edx
80102be5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bea:	21 d0                	and    %edx,%eax
80102bec:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102bf1:	b8 00 00 00 00       	mov    $0x0,%eax
80102bf6:	e9 a2 00 00 00       	jmp    80102c9d <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102bfb:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c00:	83 e0 40             	and    $0x40,%eax
80102c03:	85 c0                	test   %eax,%eax
80102c05:	74 14                	je     80102c1b <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c07:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c0e:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c13:	83 e0 bf             	and    $0xffffffbf,%eax
80102c16:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c1e:	05 20 90 10 80       	add    $0x80109020,%eax
80102c23:	0f b6 00             	movzbl (%eax),%eax
80102c26:	0f b6 d0             	movzbl %al,%edx
80102c29:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c2e:	09 d0                	or     %edx,%eax
80102c30:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c35:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c38:	05 20 91 10 80       	add    $0x80109120,%eax
80102c3d:	0f b6 00             	movzbl (%eax),%eax
80102c40:	0f b6 d0             	movzbl %al,%edx
80102c43:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c48:	31 d0                	xor    %edx,%eax
80102c4a:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102c4f:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c54:	83 e0 03             	and    $0x3,%eax
80102c57:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102c5e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c61:	01 d0                	add    %edx,%eax
80102c63:	0f b6 00             	movzbl (%eax),%eax
80102c66:	0f b6 c0             	movzbl %al,%eax
80102c69:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102c6c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c71:	83 e0 08             	and    $0x8,%eax
80102c74:	85 c0                	test   %eax,%eax
80102c76:	74 22                	je     80102c9a <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102c78:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102c7c:	76 0c                	jbe    80102c8a <kbdgetc+0x13e>
80102c7e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102c82:	77 06                	ja     80102c8a <kbdgetc+0x13e>
      c += 'A' - 'a';
80102c84:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102c88:	eb 10                	jmp    80102c9a <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102c8a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102c8e:	76 0a                	jbe    80102c9a <kbdgetc+0x14e>
80102c90:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102c94:	77 04                	ja     80102c9a <kbdgetc+0x14e>
      c += 'a' - 'A';
80102c96:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102c9a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102c9d:	c9                   	leave  
80102c9e:	c3                   	ret    

80102c9f <kbdintr>:

void
kbdintr(void)
{
80102c9f:	55                   	push   %ebp
80102ca0:	89 e5                	mov    %esp,%ebp
80102ca2:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102ca5:	c7 04 24 4c 2b 10 80 	movl   $0x80102b4c,(%esp)
80102cac:	e8 fc da ff ff       	call   801007ad <consoleintr>
}
80102cb1:	c9                   	leave  
80102cb2:	c3                   	ret    

80102cb3 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102cb3:	55                   	push   %ebp
80102cb4:	89 e5                	mov    %esp,%ebp
80102cb6:	83 ec 14             	sub    $0x14,%esp
80102cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80102cbc:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102cc0:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102cc4:	89 c2                	mov    %eax,%edx
80102cc6:	ec                   	in     (%dx),%al
80102cc7:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102cca:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102cce:	c9                   	leave  
80102ccf:	c3                   	ret    

80102cd0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102cd0:	55                   	push   %ebp
80102cd1:	89 e5                	mov    %esp,%ebp
80102cd3:	83 ec 08             	sub    $0x8,%esp
80102cd6:	8b 55 08             	mov    0x8(%ebp),%edx
80102cd9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102cdc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102ce0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ce3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ce7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102ceb:	ee                   	out    %al,(%dx)
}
80102cec:	c9                   	leave  
80102ced:	c3                   	ret    

80102cee <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102cee:	55                   	push   %ebp
80102cef:	89 e5                	mov    %esp,%ebp
80102cf1:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102cf4:	9c                   	pushf  
80102cf5:	58                   	pop    %eax
80102cf6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102cf9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102cfc:	c9                   	leave  
80102cfd:	c3                   	ret    

80102cfe <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102cfe:	55                   	push   %ebp
80102cff:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d01:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d06:	8b 55 08             	mov    0x8(%ebp),%edx
80102d09:	c1 e2 02             	shl    $0x2,%edx
80102d0c:	01 c2                	add    %eax,%edx
80102d0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d11:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d13:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d18:	83 c0 20             	add    $0x20,%eax
80102d1b:	8b 00                	mov    (%eax),%eax
}
80102d1d:	5d                   	pop    %ebp
80102d1e:	c3                   	ret    

80102d1f <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102d1f:	55                   	push   %ebp
80102d20:	89 e5                	mov    %esp,%ebp
80102d22:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d25:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d2a:	85 c0                	test   %eax,%eax
80102d2c:	75 05                	jne    80102d33 <lapicinit+0x14>
    return;
80102d2e:	e9 43 01 00 00       	jmp    80102e76 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d33:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d3a:	00 
80102d3b:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102d42:	e8 b7 ff ff ff       	call   80102cfe <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102d47:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102d4e:	00 
80102d4f:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102d56:	e8 a3 ff ff ff       	call   80102cfe <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102d5b:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102d62:	00 
80102d63:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102d6a:	e8 8f ff ff ff       	call   80102cfe <lapicw>
  lapicw(TICR, 10000000); 
80102d6f:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102d76:	00 
80102d77:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102d7e:	e8 7b ff ff ff       	call   80102cfe <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102d83:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102d8a:	00 
80102d8b:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102d92:	e8 67 ff ff ff       	call   80102cfe <lapicw>
  lapicw(LINT1, MASKED);
80102d97:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102d9e:	00 
80102d9f:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102da6:	e8 53 ff ff ff       	call   80102cfe <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102dab:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102db0:	83 c0 30             	add    $0x30,%eax
80102db3:	8b 00                	mov    (%eax),%eax
80102db5:	c1 e8 10             	shr    $0x10,%eax
80102db8:	0f b6 c0             	movzbl %al,%eax
80102dbb:	83 f8 03             	cmp    $0x3,%eax
80102dbe:	76 14                	jbe    80102dd4 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102dc0:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dc7:	00 
80102dc8:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102dcf:	e8 2a ff ff ff       	call   80102cfe <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102dd4:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102ddb:	00 
80102ddc:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102de3:	e8 16 ff ff ff       	call   80102cfe <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102de8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102def:	00 
80102df0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102df7:	e8 02 ff ff ff       	call   80102cfe <lapicw>
  lapicw(ESR, 0);
80102dfc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e03:	00 
80102e04:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e0b:	e8 ee fe ff ff       	call   80102cfe <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e10:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e17:	00 
80102e18:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e1f:	e8 da fe ff ff       	call   80102cfe <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e24:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e2b:	00 
80102e2c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e33:	e8 c6 fe ff ff       	call   80102cfe <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e38:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102e3f:	00 
80102e40:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102e47:	e8 b2 fe ff ff       	call   80102cfe <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102e4c:	90                   	nop
80102e4d:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e52:	05 00 03 00 00       	add    $0x300,%eax
80102e57:	8b 00                	mov    (%eax),%eax
80102e59:	25 00 10 00 00       	and    $0x1000,%eax
80102e5e:	85 c0                	test   %eax,%eax
80102e60:	75 eb                	jne    80102e4d <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102e62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e69:	00 
80102e6a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102e71:	e8 88 fe ff ff       	call   80102cfe <lapicw>
}
80102e76:	c9                   	leave  
80102e77:	c3                   	ret    

80102e78 <cpunum>:

int
cpunum(void)
{
80102e78:	55                   	push   %ebp
80102e79:	89 e5                	mov    %esp,%ebp
80102e7b:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102e7e:	e8 6b fe ff ff       	call   80102cee <readeflags>
80102e83:	25 00 02 00 00       	and    $0x200,%eax
80102e88:	85 c0                	test   %eax,%eax
80102e8a:	74 25                	je     80102eb1 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80102e8c:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102e91:	8d 50 01             	lea    0x1(%eax),%edx
80102e94:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
80102e9a:	85 c0                	test   %eax,%eax
80102e9c:	75 13                	jne    80102eb1 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80102e9e:	8b 45 04             	mov    0x4(%ebp),%eax
80102ea1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ea5:	c7 04 24 44 86 10 80 	movl   $0x80108644,(%esp)
80102eac:	e8 ef d4 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102eb1:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102eb6:	85 c0                	test   %eax,%eax
80102eb8:	74 0f                	je     80102ec9 <cpunum+0x51>
    return lapic[ID]>>24;
80102eba:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102ebf:	83 c0 20             	add    $0x20,%eax
80102ec2:	8b 00                	mov    (%eax),%eax
80102ec4:	c1 e8 18             	shr    $0x18,%eax
80102ec7:	eb 05                	jmp    80102ece <cpunum+0x56>
  return 0;
80102ec9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ece:	c9                   	leave  
80102ecf:	c3                   	ret    

80102ed0 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102ed0:	55                   	push   %ebp
80102ed1:	89 e5                	mov    %esp,%ebp
80102ed3:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102ed6:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102edb:	85 c0                	test   %eax,%eax
80102edd:	74 14                	je     80102ef3 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102edf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ee6:	00 
80102ee7:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102eee:	e8 0b fe ff ff       	call   80102cfe <lapicw>
}
80102ef3:	c9                   	leave  
80102ef4:	c3                   	ret    

80102ef5 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102ef5:	55                   	push   %ebp
80102ef6:	89 e5                	mov    %esp,%ebp
}
80102ef8:	5d                   	pop    %ebp
80102ef9:	c3                   	ret    

80102efa <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102efa:	55                   	push   %ebp
80102efb:	89 e5                	mov    %esp,%ebp
80102efd:	83 ec 1c             	sub    $0x1c,%esp
80102f00:	8b 45 08             	mov    0x8(%ebp),%eax
80102f03:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80102f06:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f0d:	00 
80102f0e:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f15:	e8 b6 fd ff ff       	call   80102cd0 <outb>
  outb(CMOS_PORT+1, 0x0A);
80102f1a:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f21:	00 
80102f22:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f29:	e8 a2 fd ff ff       	call   80102cd0 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f2e:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f35:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f38:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102f3d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f40:	8d 50 02             	lea    0x2(%eax),%edx
80102f43:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f46:	c1 e8 04             	shr    $0x4,%eax
80102f49:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102f4c:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102f50:	c1 e0 18             	shl    $0x18,%eax
80102f53:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f57:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f5e:	e8 9b fd ff ff       	call   80102cfe <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102f63:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102f6a:	00 
80102f6b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f72:	e8 87 fd ff ff       	call   80102cfe <lapicw>
  microdelay(200);
80102f77:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f7e:	e8 72 ff ff ff       	call   80102ef5 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102f83:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102f8a:	00 
80102f8b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f92:	e8 67 fd ff ff       	call   80102cfe <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80102f97:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102f9e:	e8 52 ff ff ff       	call   80102ef5 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102fa3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80102faa:	eb 40                	jmp    80102fec <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80102fac:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fb0:	c1 e0 18             	shl    $0x18,%eax
80102fb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fb7:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fbe:	e8 3b fd ff ff       	call   80102cfe <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102fc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fc6:	c1 e8 0c             	shr    $0xc,%eax
80102fc9:	80 cc 06             	or     $0x6,%ah
80102fcc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fd0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fd7:	e8 22 fd ff ff       	call   80102cfe <lapicw>
    microdelay(200);
80102fdc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fe3:	e8 0d ff ff ff       	call   80102ef5 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102fe8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80102fec:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80102ff0:	7e ba                	jle    80102fac <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80102ff2:	c9                   	leave  
80102ff3:	c3                   	ret    

80102ff4 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80102ff4:	55                   	push   %ebp
80102ff5:	89 e5                	mov    %esp,%ebp
80102ff7:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80102ffa:	8b 45 08             	mov    0x8(%ebp),%eax
80102ffd:	0f b6 c0             	movzbl %al,%eax
80103000:	89 44 24 04          	mov    %eax,0x4(%esp)
80103004:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010300b:	e8 c0 fc ff ff       	call   80102cd0 <outb>
  microdelay(200);
80103010:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103017:	e8 d9 fe ff ff       	call   80102ef5 <microdelay>

  return inb(CMOS_RETURN);
8010301c:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103023:	e8 8b fc ff ff       	call   80102cb3 <inb>
80103028:	0f b6 c0             	movzbl %al,%eax
}
8010302b:	c9                   	leave  
8010302c:	c3                   	ret    

8010302d <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
8010302d:	55                   	push   %ebp
8010302e:	89 e5                	mov    %esp,%ebp
80103030:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103033:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010303a:	e8 b5 ff ff ff       	call   80102ff4 <cmos_read>
8010303f:	8b 55 08             	mov    0x8(%ebp),%edx
80103042:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103044:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010304b:	e8 a4 ff ff ff       	call   80102ff4 <cmos_read>
80103050:	8b 55 08             	mov    0x8(%ebp),%edx
80103053:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103056:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010305d:	e8 92 ff ff ff       	call   80102ff4 <cmos_read>
80103062:	8b 55 08             	mov    0x8(%ebp),%edx
80103065:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103068:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010306f:	e8 80 ff ff ff       	call   80102ff4 <cmos_read>
80103074:	8b 55 08             	mov    0x8(%ebp),%edx
80103077:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010307a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103081:	e8 6e ff ff ff       	call   80102ff4 <cmos_read>
80103086:	8b 55 08             	mov    0x8(%ebp),%edx
80103089:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010308c:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103093:	e8 5c ff ff ff       	call   80102ff4 <cmos_read>
80103098:	8b 55 08             	mov    0x8(%ebp),%edx
8010309b:	89 42 14             	mov    %eax,0x14(%edx)
}
8010309e:	c9                   	leave  
8010309f:	c3                   	ret    

801030a0 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801030a0:	55                   	push   %ebp
801030a1:	89 e5                	mov    %esp,%ebp
801030a3:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801030a6:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801030ad:	e8 42 ff ff ff       	call   80102ff4 <cmos_read>
801030b2:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801030b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030b8:	83 e0 04             	and    $0x4,%eax
801030bb:	85 c0                	test   %eax,%eax
801030bd:	0f 94 c0             	sete   %al
801030c0:	0f b6 c0             	movzbl %al,%eax
801030c3:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801030c6:	8d 45 d8             	lea    -0x28(%ebp),%eax
801030c9:	89 04 24             	mov    %eax,(%esp)
801030cc:	e8 5c ff ff ff       	call   8010302d <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801030d1:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801030d8:	e8 17 ff ff ff       	call   80102ff4 <cmos_read>
801030dd:	25 80 00 00 00       	and    $0x80,%eax
801030e2:	85 c0                	test   %eax,%eax
801030e4:	74 02                	je     801030e8 <cmostime+0x48>
        continue;
801030e6:	eb 36                	jmp    8010311e <cmostime+0x7e>
    fill_rtcdate(&t2);
801030e8:	8d 45 c0             	lea    -0x40(%ebp),%eax
801030eb:	89 04 24             	mov    %eax,(%esp)
801030ee:	e8 3a ff ff ff       	call   8010302d <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801030f3:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801030fa:	00 
801030fb:	8d 45 c0             	lea    -0x40(%ebp),%eax
801030fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80103102:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103105:	89 04 24             	mov    %eax,(%esp)
80103108:	e8 5e 20 00 00       	call   8010516b <memcmp>
8010310d:	85 c0                	test   %eax,%eax
8010310f:	75 0d                	jne    8010311e <cmostime+0x7e>
      break;
80103111:	90                   	nop
  }

  // convert
  if (bcd) {
80103112:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103116:	0f 84 ac 00 00 00    	je     801031c8 <cmostime+0x128>
8010311c:	eb 02                	jmp    80103120 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
8010311e:	eb a6                	jmp    801030c6 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103120:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103123:	c1 e8 04             	shr    $0x4,%eax
80103126:	89 c2                	mov    %eax,%edx
80103128:	89 d0                	mov    %edx,%eax
8010312a:	c1 e0 02             	shl    $0x2,%eax
8010312d:	01 d0                	add    %edx,%eax
8010312f:	01 c0                	add    %eax,%eax
80103131:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103134:	83 e2 0f             	and    $0xf,%edx
80103137:	01 d0                	add    %edx,%eax
80103139:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
8010313c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010313f:	c1 e8 04             	shr    $0x4,%eax
80103142:	89 c2                	mov    %eax,%edx
80103144:	89 d0                	mov    %edx,%eax
80103146:	c1 e0 02             	shl    $0x2,%eax
80103149:	01 d0                	add    %edx,%eax
8010314b:	01 c0                	add    %eax,%eax
8010314d:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103150:	83 e2 0f             	and    $0xf,%edx
80103153:	01 d0                	add    %edx,%eax
80103155:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103158:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010315b:	c1 e8 04             	shr    $0x4,%eax
8010315e:	89 c2                	mov    %eax,%edx
80103160:	89 d0                	mov    %edx,%eax
80103162:	c1 e0 02             	shl    $0x2,%eax
80103165:	01 d0                	add    %edx,%eax
80103167:	01 c0                	add    %eax,%eax
80103169:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010316c:	83 e2 0f             	and    $0xf,%edx
8010316f:	01 d0                	add    %edx,%eax
80103171:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103174:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103177:	c1 e8 04             	shr    $0x4,%eax
8010317a:	89 c2                	mov    %eax,%edx
8010317c:	89 d0                	mov    %edx,%eax
8010317e:	c1 e0 02             	shl    $0x2,%eax
80103181:	01 d0                	add    %edx,%eax
80103183:	01 c0                	add    %eax,%eax
80103185:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103188:	83 e2 0f             	and    $0xf,%edx
8010318b:	01 d0                	add    %edx,%eax
8010318d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103190:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103193:	c1 e8 04             	shr    $0x4,%eax
80103196:	89 c2                	mov    %eax,%edx
80103198:	89 d0                	mov    %edx,%eax
8010319a:	c1 e0 02             	shl    $0x2,%eax
8010319d:	01 d0                	add    %edx,%eax
8010319f:	01 c0                	add    %eax,%eax
801031a1:	8b 55 e8             	mov    -0x18(%ebp),%edx
801031a4:	83 e2 0f             	and    $0xf,%edx
801031a7:	01 d0                	add    %edx,%eax
801031a9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801031ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031af:	c1 e8 04             	shr    $0x4,%eax
801031b2:	89 c2                	mov    %eax,%edx
801031b4:	89 d0                	mov    %edx,%eax
801031b6:	c1 e0 02             	shl    $0x2,%eax
801031b9:	01 d0                	add    %edx,%eax
801031bb:	01 c0                	add    %eax,%eax
801031bd:	8b 55 ec             	mov    -0x14(%ebp),%edx
801031c0:	83 e2 0f             	and    $0xf,%edx
801031c3:	01 d0                	add    %edx,%eax
801031c5:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801031c8:	8b 45 08             	mov    0x8(%ebp),%eax
801031cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
801031ce:	89 10                	mov    %edx,(%eax)
801031d0:	8b 55 dc             	mov    -0x24(%ebp),%edx
801031d3:	89 50 04             	mov    %edx,0x4(%eax)
801031d6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801031d9:	89 50 08             	mov    %edx,0x8(%eax)
801031dc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801031df:	89 50 0c             	mov    %edx,0xc(%eax)
801031e2:	8b 55 e8             	mov    -0x18(%ebp),%edx
801031e5:	89 50 10             	mov    %edx,0x10(%eax)
801031e8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801031eb:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801031ee:	8b 45 08             	mov    0x8(%ebp),%eax
801031f1:	8b 40 14             	mov    0x14(%eax),%eax
801031f4:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801031fa:	8b 45 08             	mov    0x8(%ebp),%eax
801031fd:	89 50 14             	mov    %edx,0x14(%eax)
}
80103200:	c9                   	leave  
80103201:	c3                   	ret    

80103202 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
80103202:	55                   	push   %ebp
80103203:	89 e5                	mov    %esp,%ebp
80103205:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103208:	c7 44 24 04 70 86 10 	movl   $0x80108670,0x4(%esp)
8010320f:	80 
80103210:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103217:	e8 63 1c 00 00       	call   80104e7f <initlock>
  readsb(ROOTDEV, &sb);
8010321c:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010321f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103223:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010322a:	e8 c2 e0 ff ff       	call   801012f1 <readsb>
  log.start = sb.size - sb.nlog;
8010322f:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103232:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103235:	29 c2                	sub    %eax,%edx
80103237:	89 d0                	mov    %edx,%eax
80103239:	a3 94 22 11 80       	mov    %eax,0x80112294
  log.size = sb.nlog;
8010323e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103241:	a3 98 22 11 80       	mov    %eax,0x80112298
  log.dev = ROOTDEV;
80103246:	c7 05 a4 22 11 80 01 	movl   $0x1,0x801122a4
8010324d:	00 00 00 
  recover_from_log();
80103250:	e8 9a 01 00 00       	call   801033ef <recover_from_log>
}
80103255:	c9                   	leave  
80103256:	c3                   	ret    

80103257 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103257:	55                   	push   %ebp
80103258:	89 e5                	mov    %esp,%ebp
8010325a:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010325d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103264:	e9 8c 00 00 00       	jmp    801032f5 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103269:	8b 15 94 22 11 80    	mov    0x80112294,%edx
8010326f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103272:	01 d0                	add    %edx,%eax
80103274:	83 c0 01             	add    $0x1,%eax
80103277:	89 c2                	mov    %eax,%edx
80103279:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010327e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103282:	89 04 24             	mov    %eax,(%esp)
80103285:	e8 1c cf ff ff       	call   801001a6 <bread>
8010328a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010328d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103290:	83 c0 10             	add    $0x10,%eax
80103293:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
8010329a:	89 c2                	mov    %eax,%edx
8010329c:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801032a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801032a5:	89 04 24             	mov    %eax,(%esp)
801032a8:	e8 f9 ce ff ff       	call   801001a6 <bread>
801032ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801032b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032b3:	8d 50 18             	lea    0x18(%eax),%edx
801032b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032b9:	83 c0 18             	add    $0x18,%eax
801032bc:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801032c3:	00 
801032c4:	89 54 24 04          	mov    %edx,0x4(%esp)
801032c8:	89 04 24             	mov    %eax,(%esp)
801032cb:	e8 f3 1e 00 00       	call   801051c3 <memmove>
    bwrite(dbuf);  // write dst to disk
801032d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032d3:	89 04 24             	mov    %eax,(%esp)
801032d6:	e8 02 cf ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801032db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032de:	89 04 24             	mov    %eax,(%esp)
801032e1:	e8 31 cf ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801032e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032e9:	89 04 24             	mov    %eax,(%esp)
801032ec:	e8 26 cf ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801032f5:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801032fa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801032fd:	0f 8f 66 ff ff ff    	jg     80103269 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103303:	c9                   	leave  
80103304:	c3                   	ret    

80103305 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103305:	55                   	push   %ebp
80103306:	89 e5                	mov    %esp,%ebp
80103308:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010330b:	a1 94 22 11 80       	mov    0x80112294,%eax
80103310:	89 c2                	mov    %eax,%edx
80103312:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103317:	89 54 24 04          	mov    %edx,0x4(%esp)
8010331b:	89 04 24             	mov    %eax,(%esp)
8010331e:	e8 83 ce ff ff       	call   801001a6 <bread>
80103323:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103326:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103329:	83 c0 18             	add    $0x18,%eax
8010332c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010332f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103332:	8b 00                	mov    (%eax),%eax
80103334:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  for (i = 0; i < log.lh.n; i++) {
80103339:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103340:	eb 1b                	jmp    8010335d <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103342:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103345:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103348:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010334c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010334f:	83 c2 10             	add    $0x10,%edx
80103352:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103359:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010335d:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103362:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103365:	7f db                	jg     80103342 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103367:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010336a:	89 04 24             	mov    %eax,(%esp)
8010336d:	e8 a5 ce ff ff       	call   80100217 <brelse>
}
80103372:	c9                   	leave  
80103373:	c3                   	ret    

80103374 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103374:	55                   	push   %ebp
80103375:	89 e5                	mov    %esp,%ebp
80103377:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010337a:	a1 94 22 11 80       	mov    0x80112294,%eax
8010337f:	89 c2                	mov    %eax,%edx
80103381:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103386:	89 54 24 04          	mov    %edx,0x4(%esp)
8010338a:	89 04 24             	mov    %eax,(%esp)
8010338d:	e8 14 ce ff ff       	call   801001a6 <bread>
80103392:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103395:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103398:	83 c0 18             	add    $0x18,%eax
8010339b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010339e:	8b 15 a8 22 11 80    	mov    0x801122a8,%edx
801033a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033a7:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801033a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033b0:	eb 1b                	jmp    801033cd <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801033b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033b5:	83 c0 10             	add    $0x10,%eax
801033b8:	8b 0c 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%ecx
801033bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c5:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801033c9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033cd:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801033d2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033d5:	7f db                	jg     801033b2 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801033d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033da:	89 04 24             	mov    %eax,(%esp)
801033dd:	e8 fb cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
801033e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e5:	89 04 24             	mov    %eax,(%esp)
801033e8:	e8 2a ce ff ff       	call   80100217 <brelse>
}
801033ed:	c9                   	leave  
801033ee:	c3                   	ret    

801033ef <recover_from_log>:

static void
recover_from_log(void)
{
801033ef:	55                   	push   %ebp
801033f0:	89 e5                	mov    %esp,%ebp
801033f2:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801033f5:	e8 0b ff ff ff       	call   80103305 <read_head>
  install_trans(); // if committed, copy from log to disk
801033fa:	e8 58 fe ff ff       	call   80103257 <install_trans>
  log.lh.n = 0;
801033ff:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103406:	00 00 00 
  write_head(); // clear the log
80103409:	e8 66 ff ff ff       	call   80103374 <write_head>
}
8010340e:	c9                   	leave  
8010340f:	c3                   	ret    

80103410 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103410:	55                   	push   %ebp
80103411:	89 e5                	mov    %esp,%ebp
80103413:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103416:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010341d:	e8 7e 1a 00 00       	call   80104ea0 <acquire>
  while(1){
    if(log.committing){
80103422:	a1 a0 22 11 80       	mov    0x801122a0,%eax
80103427:	85 c0                	test   %eax,%eax
80103429:	74 16                	je     80103441 <begin_op+0x31>
      sleep(&log, &log.lock);
8010342b:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103432:	80 
80103433:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010343a:	e8 8e 17 00 00       	call   80104bcd <sleep>
8010343f:	eb 4f                	jmp    80103490 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103441:	8b 0d a8 22 11 80    	mov    0x801122a8,%ecx
80103447:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010344c:	8d 50 01             	lea    0x1(%eax),%edx
8010344f:	89 d0                	mov    %edx,%eax
80103451:	c1 e0 02             	shl    $0x2,%eax
80103454:	01 d0                	add    %edx,%eax
80103456:	01 c0                	add    %eax,%eax
80103458:	01 c8                	add    %ecx,%eax
8010345a:	83 f8 1e             	cmp    $0x1e,%eax
8010345d:	7e 16                	jle    80103475 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
8010345f:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103466:	80 
80103467:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010346e:	e8 5a 17 00 00       	call   80104bcd <sleep>
80103473:	eb 1b                	jmp    80103490 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103475:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010347a:	83 c0 01             	add    $0x1,%eax
8010347d:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
80103482:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103489:	e8 74 1a 00 00       	call   80104f02 <release>
      break;
8010348e:	eb 02                	jmp    80103492 <begin_op+0x82>
    }
  }
80103490:	eb 90                	jmp    80103422 <begin_op+0x12>
}
80103492:	c9                   	leave  
80103493:	c3                   	ret    

80103494 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103494:	55                   	push   %ebp
80103495:	89 e5                	mov    %esp,%ebp
80103497:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
8010349a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801034a1:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034a8:	e8 f3 19 00 00       	call   80104ea0 <acquire>
  log.outstanding -= 1;
801034ad:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034b2:	83 e8 01             	sub    $0x1,%eax
801034b5:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
801034ba:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801034bf:	85 c0                	test   %eax,%eax
801034c1:	74 0c                	je     801034cf <end_op+0x3b>
    panic("log.committing");
801034c3:	c7 04 24 74 86 10 80 	movl   $0x80108674,(%esp)
801034ca:	e8 6b d0 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801034cf:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034d4:	85 c0                	test   %eax,%eax
801034d6:	75 13                	jne    801034eb <end_op+0x57>
    do_commit = 1;
801034d8:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801034df:	c7 05 a0 22 11 80 01 	movl   $0x1,0x801122a0
801034e6:	00 00 00 
801034e9:	eb 0c                	jmp    801034f7 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
801034eb:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034f2:	e8 ae 17 00 00       	call   80104ca5 <wakeup>
  }
  release(&log.lock);
801034f7:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034fe:	e8 ff 19 00 00       	call   80104f02 <release>

  if(do_commit){
80103503:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103507:	74 33                	je     8010353c <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103509:	e8 de 00 00 00       	call   801035ec <commit>
    acquire(&log.lock);
8010350e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103515:	e8 86 19 00 00       	call   80104ea0 <acquire>
    log.committing = 0;
8010351a:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
80103521:	00 00 00 
    wakeup(&log);
80103524:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010352b:	e8 75 17 00 00       	call   80104ca5 <wakeup>
    release(&log.lock);
80103530:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103537:	e8 c6 19 00 00       	call   80104f02 <release>
  }
}
8010353c:	c9                   	leave  
8010353d:	c3                   	ret    

8010353e <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
8010353e:	55                   	push   %ebp
8010353f:	89 e5                	mov    %esp,%ebp
80103541:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103544:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010354b:	e9 8c 00 00 00       	jmp    801035dc <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103550:	8b 15 94 22 11 80    	mov    0x80112294,%edx
80103556:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103559:	01 d0                	add    %edx,%eax
8010355b:	83 c0 01             	add    $0x1,%eax
8010355e:	89 c2                	mov    %eax,%edx
80103560:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103565:	89 54 24 04          	mov    %edx,0x4(%esp)
80103569:	89 04 24             	mov    %eax,(%esp)
8010356c:	e8 35 cc ff ff       	call   801001a6 <bread>
80103571:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
80103574:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103577:	83 c0 10             	add    $0x10,%eax
8010357a:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103581:	89 c2                	mov    %eax,%edx
80103583:	a1 a4 22 11 80       	mov    0x801122a4,%eax
80103588:	89 54 24 04          	mov    %edx,0x4(%esp)
8010358c:	89 04 24             	mov    %eax,(%esp)
8010358f:	e8 12 cc ff ff       	call   801001a6 <bread>
80103594:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103597:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010359a:	8d 50 18             	lea    0x18(%eax),%edx
8010359d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035a0:	83 c0 18             	add    $0x18,%eax
801035a3:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801035aa:	00 
801035ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801035af:	89 04 24             	mov    %eax,(%esp)
801035b2:	e8 0c 1c 00 00       	call   801051c3 <memmove>
    bwrite(to);  // write the log
801035b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035ba:	89 04 24             	mov    %eax,(%esp)
801035bd:	e8 1b cc ff ff       	call   801001dd <bwrite>
    brelse(from); 
801035c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035c5:	89 04 24             	mov    %eax,(%esp)
801035c8:	e8 4a cc ff ff       	call   80100217 <brelse>
    brelse(to);
801035cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035d0:	89 04 24             	mov    %eax,(%esp)
801035d3:	e8 3f cc ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801035d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035dc:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801035e1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035e4:	0f 8f 66 ff ff ff    	jg     80103550 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
801035ea:	c9                   	leave  
801035eb:	c3                   	ret    

801035ec <commit>:

static void
commit()
{
801035ec:	55                   	push   %ebp
801035ed:	89 e5                	mov    %esp,%ebp
801035ef:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
801035f2:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801035f7:	85 c0                	test   %eax,%eax
801035f9:	7e 1e                	jle    80103619 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
801035fb:	e8 3e ff ff ff       	call   8010353e <write_log>
    write_head();    // Write header to disk -- the real commit
80103600:	e8 6f fd ff ff       	call   80103374 <write_head>
    install_trans(); // Now install writes to home locations
80103605:	e8 4d fc ff ff       	call   80103257 <install_trans>
    log.lh.n = 0; 
8010360a:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103611:	00 00 00 
    write_head();    // Erase the transaction from the log
80103614:	e8 5b fd ff ff       	call   80103374 <write_head>
  }
}
80103619:	c9                   	leave  
8010361a:	c3                   	ret    

8010361b <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010361b:	55                   	push   %ebp
8010361c:	89 e5                	mov    %esp,%ebp
8010361e:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103621:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103626:	83 f8 1d             	cmp    $0x1d,%eax
80103629:	7f 12                	jg     8010363d <log_write+0x22>
8010362b:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103630:	8b 15 98 22 11 80    	mov    0x80112298,%edx
80103636:	83 ea 01             	sub    $0x1,%edx
80103639:	39 d0                	cmp    %edx,%eax
8010363b:	7c 0c                	jl     80103649 <log_write+0x2e>
    panic("too big a transaction");
8010363d:	c7 04 24 83 86 10 80 	movl   $0x80108683,(%esp)
80103644:	e8 f1 ce ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103649:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010364e:	85 c0                	test   %eax,%eax
80103650:	7f 0c                	jg     8010365e <log_write+0x43>
    panic("log_write outside of trans");
80103652:	c7 04 24 99 86 10 80 	movl   $0x80108699,(%esp)
80103659:	e8 dc ce ff ff       	call   8010053a <panic>

  acquire(&log.lock);
8010365e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103665:	e8 36 18 00 00       	call   80104ea0 <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010366a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103671:	eb 1f                	jmp    80103692 <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
80103673:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103676:	83 c0 10             	add    $0x10,%eax
80103679:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
80103680:	89 c2                	mov    %eax,%edx
80103682:	8b 45 08             	mov    0x8(%ebp),%eax
80103685:	8b 40 08             	mov    0x8(%eax),%eax
80103688:	39 c2                	cmp    %eax,%edx
8010368a:	75 02                	jne    8010368e <log_write+0x73>
      break;
8010368c:	eb 0e                	jmp    8010369c <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
8010368e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103692:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103697:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010369a:	7f d7                	jg     80103673 <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
8010369c:	8b 45 08             	mov    0x8(%ebp),%eax
8010369f:	8b 40 08             	mov    0x8(%eax),%eax
801036a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036a5:	83 c2 10             	add    $0x10,%edx
801036a8:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
  if (i == log.lh.n)
801036af:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036b7:	75 0d                	jne    801036c6 <log_write+0xab>
    log.lh.n++;
801036b9:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036be:	83 c0 01             	add    $0x1,%eax
801036c1:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  b->flags |= B_DIRTY; // prevent eviction
801036c6:	8b 45 08             	mov    0x8(%ebp),%eax
801036c9:	8b 00                	mov    (%eax),%eax
801036cb:	83 c8 04             	or     $0x4,%eax
801036ce:	89 c2                	mov    %eax,%edx
801036d0:	8b 45 08             	mov    0x8(%ebp),%eax
801036d3:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801036d5:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801036dc:	e8 21 18 00 00       	call   80104f02 <release>
}
801036e1:	c9                   	leave  
801036e2:	c3                   	ret    

801036e3 <v2p>:
801036e3:	55                   	push   %ebp
801036e4:	89 e5                	mov    %esp,%ebp
801036e6:	8b 45 08             	mov    0x8(%ebp),%eax
801036e9:	05 00 00 00 80       	add    $0x80000000,%eax
801036ee:	5d                   	pop    %ebp
801036ef:	c3                   	ret    

801036f0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801036f0:	55                   	push   %ebp
801036f1:	89 e5                	mov    %esp,%ebp
801036f3:	8b 45 08             	mov    0x8(%ebp),%eax
801036f6:	05 00 00 00 80       	add    $0x80000000,%eax
801036fb:	5d                   	pop    %ebp
801036fc:	c3                   	ret    

801036fd <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801036fd:	55                   	push   %ebp
801036fe:	89 e5                	mov    %esp,%ebp
80103700:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103703:	8b 55 08             	mov    0x8(%ebp),%edx
80103706:	8b 45 0c             	mov    0xc(%ebp),%eax
80103709:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010370c:	f0 87 02             	lock xchg %eax,(%edx)
8010370f:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103712:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103715:	c9                   	leave  
80103716:	c3                   	ret    

80103717 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103717:	55                   	push   %ebp
80103718:	89 e5                	mov    %esp,%ebp
8010371a:	83 e4 f0             	and    $0xfffffff0,%esp
8010371d:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103720:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103727:	80 
80103728:	c7 04 24 3c 51 11 80 	movl   $0x8011513c,(%esp)
8010372f:	e8 80 f2 ff ff       	call   801029b4 <kinit1>
  kvmalloc();      // kernel page table
80103734:	e8 80 45 00 00       	call   80107cb9 <kvmalloc>
  mpinit();        // collect info about this machine
80103739:	e8 46 04 00 00       	call   80103b84 <mpinit>
  lapicinit();
8010373e:	e8 dc f5 ff ff       	call   80102d1f <lapicinit>
  seginit();       // set up segments
80103743:	e8 04 3f 00 00       	call   8010764c <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103748:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010374e:	0f b6 00             	movzbl (%eax),%eax
80103751:	0f b6 c0             	movzbl %al,%eax
80103754:	89 44 24 04          	mov    %eax,0x4(%esp)
80103758:	c7 04 24 b4 86 10 80 	movl   $0x801086b4,(%esp)
8010375f:	e8 3c cc ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103764:	e8 79 06 00 00       	call   80103de2 <picinit>
  ioapicinit();    // another interrupt controller
80103769:	e8 3c f1 ff ff       	call   801028aa <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010376e:	e8 0e d3 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
80103773:	e8 23 32 00 00       	call   8010699b <uartinit>
  pinit();         // process table
80103778:	e8 6f 0b 00 00       	call   801042ec <pinit>
  tvinit();        // trap vectors
8010377d:	e8 cb 2d 00 00       	call   8010654d <tvinit>
  binit();         // buffer cache
80103782:	e8 ad c8 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103787:	e8 7e d7 ff ff       	call   80100f0a <fileinit>
  iinit();         // inode cache
8010378c:	e8 13 de ff ff       	call   801015a4 <iinit>
  ideinit();       // disk
80103791:	e8 7d ed ff ff       	call   80102513 <ideinit>
  if(!ismp)
80103796:	a1 44 23 11 80       	mov    0x80112344,%eax
8010379b:	85 c0                	test   %eax,%eax
8010379d:	75 05                	jne    801037a4 <main+0x8d>
    timerinit();   // uniprocessor timer
8010379f:	e8 f4 2c 00 00       	call   80106498 <timerinit>
  startothers();   // start other processors
801037a4:	e8 7f 00 00 00       	call   80103828 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801037a9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801037b0:	8e 
801037b1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801037b8:	e8 2f f2 ff ff       	call   801029ec <kinit2>
  userinit();      // first user process
801037bd:	e8 70 0c 00 00       	call   80104432 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801037c2:	e8 1a 00 00 00       	call   801037e1 <mpmain>

801037c7 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801037c7:	55                   	push   %ebp
801037c8:	89 e5                	mov    %esp,%ebp
801037ca:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801037cd:	e8 fe 44 00 00       	call   80107cd0 <switchkvm>
  seginit();
801037d2:	e8 75 3e 00 00       	call   8010764c <seginit>
  lapicinit();
801037d7:	e8 43 f5 ff ff       	call   80102d1f <lapicinit>
  mpmain();
801037dc:	e8 00 00 00 00       	call   801037e1 <mpmain>

801037e1 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801037e1:	55                   	push   %ebp
801037e2:	89 e5                	mov    %esp,%ebp
801037e4:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801037e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801037ed:	0f b6 00             	movzbl (%eax),%eax
801037f0:	0f b6 c0             	movzbl %al,%eax
801037f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801037f7:	c7 04 24 cb 86 10 80 	movl   $0x801086cb,(%esp)
801037fe:	e8 9d cb ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103803:	e8 b9 2e 00 00       	call   801066c1 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103808:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010380e:	05 a8 00 00 00       	add    $0xa8,%eax
80103813:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010381a:	00 
8010381b:	89 04 24             	mov    %eax,(%esp)
8010381e:	e8 da fe ff ff       	call   801036fd <xchg>
  scheduler();     // start running processes
80103823:	e8 e7 11 00 00       	call   80104a0f <scheduler>

80103828 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103828:	55                   	push   %ebp
80103829:	89 e5                	mov    %esp,%ebp
8010382b:	53                   	push   %ebx
8010382c:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010382f:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103836:	e8 b5 fe ff ff       	call   801036f0 <p2v>
8010383b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010383e:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103843:	89 44 24 08          	mov    %eax,0x8(%esp)
80103847:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
8010384e:	80 
8010384f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103852:	89 04 24             	mov    %eax,(%esp)
80103855:	e8 69 19 00 00       	call   801051c3 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010385a:	c7 45 f4 60 23 11 80 	movl   $0x80112360,-0xc(%ebp)
80103861:	e9 85 00 00 00       	jmp    801038eb <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103866:	e8 0d f6 ff ff       	call   80102e78 <cpunum>
8010386b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103871:	05 60 23 11 80       	add    $0x80112360,%eax
80103876:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103879:	75 02                	jne    8010387d <startothers+0x55>
      continue;
8010387b:	eb 67                	jmp    801038e4 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010387d:	e8 60 f2 ff ff       	call   80102ae2 <kalloc>
80103882:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103885:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103888:	83 e8 04             	sub    $0x4,%eax
8010388b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010388e:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103894:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103896:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103899:	83 e8 08             	sub    $0x8,%eax
8010389c:	c7 00 c7 37 10 80    	movl   $0x801037c7,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801038a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a5:	8d 58 f4             	lea    -0xc(%eax),%ebx
801038a8:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801038af:	e8 2f fe ff ff       	call   801036e3 <v2p>
801038b4:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801038b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b9:	89 04 24             	mov    %eax,(%esp)
801038bc:	e8 22 fe ff ff       	call   801036e3 <v2p>
801038c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038c4:	0f b6 12             	movzbl (%edx),%edx
801038c7:	0f b6 d2             	movzbl %dl,%edx
801038ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801038ce:	89 14 24             	mov    %edx,(%esp)
801038d1:	e8 24 f6 ff ff       	call   80102efa <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801038d6:	90                   	nop
801038d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038da:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801038e0:	85 c0                	test   %eax,%eax
801038e2:	74 f3                	je     801038d7 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801038e4:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801038eb:	a1 40 29 11 80       	mov    0x80112940,%eax
801038f0:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801038f6:	05 60 23 11 80       	add    $0x80112360,%eax
801038fb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038fe:	0f 87 62 ff ff ff    	ja     80103866 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103904:	83 c4 24             	add    $0x24,%esp
80103907:	5b                   	pop    %ebx
80103908:	5d                   	pop    %ebp
80103909:	c3                   	ret    

8010390a <p2v>:
8010390a:	55                   	push   %ebp
8010390b:	89 e5                	mov    %esp,%ebp
8010390d:	8b 45 08             	mov    0x8(%ebp),%eax
80103910:	05 00 00 00 80       	add    $0x80000000,%eax
80103915:	5d                   	pop    %ebp
80103916:	c3                   	ret    

80103917 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103917:	55                   	push   %ebp
80103918:	89 e5                	mov    %esp,%ebp
8010391a:	83 ec 14             	sub    $0x14,%esp
8010391d:	8b 45 08             	mov    0x8(%ebp),%eax
80103920:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103924:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103928:	89 c2                	mov    %eax,%edx
8010392a:	ec                   	in     (%dx),%al
8010392b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010392e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103932:	c9                   	leave  
80103933:	c3                   	ret    

80103934 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103934:	55                   	push   %ebp
80103935:	89 e5                	mov    %esp,%ebp
80103937:	83 ec 08             	sub    $0x8,%esp
8010393a:	8b 55 08             	mov    0x8(%ebp),%edx
8010393d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103940:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103944:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103947:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010394b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010394f:	ee                   	out    %al,(%dx)
}
80103950:	c9                   	leave  
80103951:	c3                   	ret    

80103952 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103952:	55                   	push   %ebp
80103953:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103955:	a1 44 b6 10 80       	mov    0x8010b644,%eax
8010395a:	89 c2                	mov    %eax,%edx
8010395c:	b8 60 23 11 80       	mov    $0x80112360,%eax
80103961:	29 c2                	sub    %eax,%edx
80103963:	89 d0                	mov    %edx,%eax
80103965:	c1 f8 02             	sar    $0x2,%eax
80103968:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010396e:	5d                   	pop    %ebp
8010396f:	c3                   	ret    

80103970 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103970:	55                   	push   %ebp
80103971:	89 e5                	mov    %esp,%ebp
80103973:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103976:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010397d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103984:	eb 15                	jmp    8010399b <sum+0x2b>
    sum += addr[i];
80103986:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103989:	8b 45 08             	mov    0x8(%ebp),%eax
8010398c:	01 d0                	add    %edx,%eax
8010398e:	0f b6 00             	movzbl (%eax),%eax
80103991:	0f b6 c0             	movzbl %al,%eax
80103994:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103997:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010399b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010399e:	3b 45 0c             	cmp    0xc(%ebp),%eax
801039a1:	7c e3                	jl     80103986 <sum+0x16>
    sum += addr[i];
  return sum;
801039a3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801039a6:	c9                   	leave  
801039a7:	c3                   	ret    

801039a8 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801039a8:	55                   	push   %ebp
801039a9:	89 e5                	mov    %esp,%ebp
801039ab:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801039ae:	8b 45 08             	mov    0x8(%ebp),%eax
801039b1:	89 04 24             	mov    %eax,(%esp)
801039b4:	e8 51 ff ff ff       	call   8010390a <p2v>
801039b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801039bc:	8b 55 0c             	mov    0xc(%ebp),%edx
801039bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039c2:	01 d0                	add    %edx,%eax
801039c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801039c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
801039cd:	eb 3f                	jmp    80103a0e <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801039cf:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801039d6:	00 
801039d7:	c7 44 24 04 dc 86 10 	movl   $0x801086dc,0x4(%esp)
801039de:	80 
801039df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e2:	89 04 24             	mov    %eax,(%esp)
801039e5:	e8 81 17 00 00       	call   8010516b <memcmp>
801039ea:	85 c0                	test   %eax,%eax
801039ec:	75 1c                	jne    80103a0a <mpsearch1+0x62>
801039ee:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801039f5:	00 
801039f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f9:	89 04 24             	mov    %eax,(%esp)
801039fc:	e8 6f ff ff ff       	call   80103970 <sum>
80103a01:	84 c0                	test   %al,%al
80103a03:	75 05                	jne    80103a0a <mpsearch1+0x62>
      return (struct mp*)p;
80103a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a08:	eb 11                	jmp    80103a1b <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103a0a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a11:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a14:	72 b9                	jb     801039cf <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103a16:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103a1b:	c9                   	leave  
80103a1c:	c3                   	ret    

80103a1d <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103a1d:	55                   	push   %ebp
80103a1e:	89 e5                	mov    %esp,%ebp
80103a20:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103a23:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a2d:	83 c0 0f             	add    $0xf,%eax
80103a30:	0f b6 00             	movzbl (%eax),%eax
80103a33:	0f b6 c0             	movzbl %al,%eax
80103a36:	c1 e0 08             	shl    $0x8,%eax
80103a39:	89 c2                	mov    %eax,%edx
80103a3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a3e:	83 c0 0e             	add    $0xe,%eax
80103a41:	0f b6 00             	movzbl (%eax),%eax
80103a44:	0f b6 c0             	movzbl %al,%eax
80103a47:	09 d0                	or     %edx,%eax
80103a49:	c1 e0 04             	shl    $0x4,%eax
80103a4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103a4f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103a53:	74 21                	je     80103a76 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103a55:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a5c:	00 
80103a5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a60:	89 04 24             	mov    %eax,(%esp)
80103a63:	e8 40 ff ff ff       	call   801039a8 <mpsearch1>
80103a68:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a6b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a6f:	74 50                	je     80103ac1 <mpsearch+0xa4>
      return mp;
80103a71:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a74:	eb 5f                	jmp    80103ad5 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103a76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a79:	83 c0 14             	add    $0x14,%eax
80103a7c:	0f b6 00             	movzbl (%eax),%eax
80103a7f:	0f b6 c0             	movzbl %al,%eax
80103a82:	c1 e0 08             	shl    $0x8,%eax
80103a85:	89 c2                	mov    %eax,%edx
80103a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a8a:	83 c0 13             	add    $0x13,%eax
80103a8d:	0f b6 00             	movzbl (%eax),%eax
80103a90:	0f b6 c0             	movzbl %al,%eax
80103a93:	09 d0                	or     %edx,%eax
80103a95:	c1 e0 0a             	shl    $0xa,%eax
80103a98:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103a9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a9e:	2d 00 04 00 00       	sub    $0x400,%eax
80103aa3:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103aaa:	00 
80103aab:	89 04 24             	mov    %eax,(%esp)
80103aae:	e8 f5 fe ff ff       	call   801039a8 <mpsearch1>
80103ab3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103ab6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103aba:	74 05                	je     80103ac1 <mpsearch+0xa4>
      return mp;
80103abc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103abf:	eb 14                	jmp    80103ad5 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103ac1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ac8:	00 
80103ac9:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103ad0:	e8 d3 fe ff ff       	call   801039a8 <mpsearch1>
}
80103ad5:	c9                   	leave  
80103ad6:	c3                   	ret    

80103ad7 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103ad7:	55                   	push   %ebp
80103ad8:	89 e5                	mov    %esp,%ebp
80103ada:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103add:	e8 3b ff ff ff       	call   80103a1d <mpsearch>
80103ae2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ae5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ae9:	74 0a                	je     80103af5 <mpconfig+0x1e>
80103aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aee:	8b 40 04             	mov    0x4(%eax),%eax
80103af1:	85 c0                	test   %eax,%eax
80103af3:	75 0a                	jne    80103aff <mpconfig+0x28>
    return 0;
80103af5:	b8 00 00 00 00       	mov    $0x0,%eax
80103afa:	e9 83 00 00 00       	jmp    80103b82 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103aff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b02:	8b 40 04             	mov    0x4(%eax),%eax
80103b05:	89 04 24             	mov    %eax,(%esp)
80103b08:	e8 fd fd ff ff       	call   8010390a <p2v>
80103b0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103b10:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103b17:	00 
80103b18:	c7 44 24 04 e1 86 10 	movl   $0x801086e1,0x4(%esp)
80103b1f:	80 
80103b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b23:	89 04 24             	mov    %eax,(%esp)
80103b26:	e8 40 16 00 00       	call   8010516b <memcmp>
80103b2b:	85 c0                	test   %eax,%eax
80103b2d:	74 07                	je     80103b36 <mpconfig+0x5f>
    return 0;
80103b2f:	b8 00 00 00 00       	mov    $0x0,%eax
80103b34:	eb 4c                	jmp    80103b82 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103b36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b39:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b3d:	3c 01                	cmp    $0x1,%al
80103b3f:	74 12                	je     80103b53 <mpconfig+0x7c>
80103b41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b44:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b48:	3c 04                	cmp    $0x4,%al
80103b4a:	74 07                	je     80103b53 <mpconfig+0x7c>
    return 0;
80103b4c:	b8 00 00 00 00       	mov    $0x0,%eax
80103b51:	eb 2f                	jmp    80103b82 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103b53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b56:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b5a:	0f b7 c0             	movzwl %ax,%eax
80103b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b64:	89 04 24             	mov    %eax,(%esp)
80103b67:	e8 04 fe ff ff       	call   80103970 <sum>
80103b6c:	84 c0                	test   %al,%al
80103b6e:	74 07                	je     80103b77 <mpconfig+0xa0>
    return 0;
80103b70:	b8 00 00 00 00       	mov    $0x0,%eax
80103b75:	eb 0b                	jmp    80103b82 <mpconfig+0xab>
  *pmp = mp;
80103b77:	8b 45 08             	mov    0x8(%ebp),%eax
80103b7a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b7d:	89 10                	mov    %edx,(%eax)
  return conf;
80103b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103b82:	c9                   	leave  
80103b83:	c3                   	ret    

80103b84 <mpinit>:

void
mpinit(void)
{
80103b84:	55                   	push   %ebp
80103b85:	89 e5                	mov    %esp,%ebp
80103b87:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103b8a:	c7 05 44 b6 10 80 60 	movl   $0x80112360,0x8010b644
80103b91:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103b94:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103b97:	89 04 24             	mov    %eax,(%esp)
80103b9a:	e8 38 ff ff ff       	call   80103ad7 <mpconfig>
80103b9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103ba2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103ba6:	75 05                	jne    80103bad <mpinit+0x29>
    return;
80103ba8:	e9 9c 01 00 00       	jmp    80103d49 <mpinit+0x1c5>
  ismp = 1;
80103bad:	c7 05 44 23 11 80 01 	movl   $0x1,0x80112344
80103bb4:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103bb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bba:	8b 40 24             	mov    0x24(%eax),%eax
80103bbd:	a3 5c 22 11 80       	mov    %eax,0x8011225c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103bc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bc5:	83 c0 2c             	add    $0x2c,%eax
80103bc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bce:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103bd2:	0f b7 d0             	movzwl %ax,%edx
80103bd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bd8:	01 d0                	add    %edx,%eax
80103bda:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103bdd:	e9 f4 00 00 00       	jmp    80103cd6 <mpinit+0x152>
    switch(*p){
80103be2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be5:	0f b6 00             	movzbl (%eax),%eax
80103be8:	0f b6 c0             	movzbl %al,%eax
80103beb:	83 f8 04             	cmp    $0x4,%eax
80103bee:	0f 87 bf 00 00 00    	ja     80103cb3 <mpinit+0x12f>
80103bf4:	8b 04 85 24 87 10 80 	mov    -0x7fef78dc(,%eax,4),%eax
80103bfb:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c00:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103c03:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c06:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c0a:	0f b6 d0             	movzbl %al,%edx
80103c0d:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c12:	39 c2                	cmp    %eax,%edx
80103c14:	74 2d                	je     80103c43 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103c16:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c19:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c1d:	0f b6 d0             	movzbl %al,%edx
80103c20:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c25:	89 54 24 08          	mov    %edx,0x8(%esp)
80103c29:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c2d:	c7 04 24 e6 86 10 80 	movl   $0x801086e6,(%esp)
80103c34:	e8 67 c7 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103c39:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103c40:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103c43:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c46:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103c4a:	0f b6 c0             	movzbl %al,%eax
80103c4d:	83 e0 02             	and    $0x2,%eax
80103c50:	85 c0                	test   %eax,%eax
80103c52:	74 15                	je     80103c69 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103c54:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c59:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103c5f:	05 60 23 11 80       	add    $0x80112360,%eax
80103c64:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103c69:	8b 15 40 29 11 80    	mov    0x80112940,%edx
80103c6f:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c74:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103c7a:	81 c2 60 23 11 80    	add    $0x80112360,%edx
80103c80:	88 02                	mov    %al,(%edx)
      ncpu++;
80103c82:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c87:	83 c0 01             	add    $0x1,%eax
80103c8a:	a3 40 29 11 80       	mov    %eax,0x80112940
      p += sizeof(struct mpproc);
80103c8f:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103c93:	eb 41                	jmp    80103cd6 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103c95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103c9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103c9e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103ca2:	a2 40 23 11 80       	mov    %al,0x80112340
      p += sizeof(struct mpioapic);
80103ca7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103cab:	eb 29                	jmp    80103cd6 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103cad:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103cb1:	eb 23                	jmp    80103cd6 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cb6:	0f b6 00             	movzbl (%eax),%eax
80103cb9:	0f b6 c0             	movzbl %al,%eax
80103cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cc0:	c7 04 24 04 87 10 80 	movl   $0x80108704,(%esp)
80103cc7:	e8 d4 c6 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103ccc:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103cd3:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103cd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cd9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103cdc:	0f 82 00 ff ff ff    	jb     80103be2 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103ce2:	a1 44 23 11 80       	mov    0x80112344,%eax
80103ce7:	85 c0                	test   %eax,%eax
80103ce9:	75 1d                	jne    80103d08 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103ceb:	c7 05 40 29 11 80 01 	movl   $0x1,0x80112940
80103cf2:	00 00 00 
    lapic = 0;
80103cf5:	c7 05 5c 22 11 80 00 	movl   $0x0,0x8011225c
80103cfc:	00 00 00 
    ioapicid = 0;
80103cff:	c6 05 40 23 11 80 00 	movb   $0x0,0x80112340
    return;
80103d06:	eb 41                	jmp    80103d49 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103d08:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103d0b:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103d0f:	84 c0                	test   %al,%al
80103d11:	74 36                	je     80103d49 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103d13:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103d1a:	00 
80103d1b:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103d22:	e8 0d fc ff ff       	call   80103934 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103d27:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103d2e:	e8 e4 fb ff ff       	call   80103917 <inb>
80103d33:	83 c8 01             	or     $0x1,%eax
80103d36:	0f b6 c0             	movzbl %al,%eax
80103d39:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d3d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103d44:	e8 eb fb ff ff       	call   80103934 <outb>
  }
}
80103d49:	c9                   	leave  
80103d4a:	c3                   	ret    

80103d4b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103d4b:	55                   	push   %ebp
80103d4c:	89 e5                	mov    %esp,%ebp
80103d4e:	83 ec 08             	sub    $0x8,%esp
80103d51:	8b 55 08             	mov    0x8(%ebp),%edx
80103d54:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d57:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103d5b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103d5e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103d62:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103d66:	ee                   	out    %al,(%dx)
}
80103d67:	c9                   	leave  
80103d68:	c3                   	ret    

80103d69 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103d69:	55                   	push   %ebp
80103d6a:	89 e5                	mov    %esp,%ebp
80103d6c:	83 ec 0c             	sub    $0xc,%esp
80103d6f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d72:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103d76:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103d7a:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103d80:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103d84:	0f b6 c0             	movzbl %al,%eax
80103d87:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d8b:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d92:	e8 b4 ff ff ff       	call   80103d4b <outb>
  outb(IO_PIC2+1, mask >> 8);
80103d97:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103d9b:	66 c1 e8 08          	shr    $0x8,%ax
80103d9f:	0f b6 c0             	movzbl %al,%eax
80103da2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103da6:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103dad:	e8 99 ff ff ff       	call   80103d4b <outb>
}
80103db2:	c9                   	leave  
80103db3:	c3                   	ret    

80103db4 <picenable>:

void
picenable(int irq)
{
80103db4:	55                   	push   %ebp
80103db5:	89 e5                	mov    %esp,%ebp
80103db7:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103dba:	8b 45 08             	mov    0x8(%ebp),%eax
80103dbd:	ba 01 00 00 00       	mov    $0x1,%edx
80103dc2:	89 c1                	mov    %eax,%ecx
80103dc4:	d3 e2                	shl    %cl,%edx
80103dc6:	89 d0                	mov    %edx,%eax
80103dc8:	f7 d0                	not    %eax
80103dca:	89 c2                	mov    %eax,%edx
80103dcc:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103dd3:	21 d0                	and    %edx,%eax
80103dd5:	0f b7 c0             	movzwl %ax,%eax
80103dd8:	89 04 24             	mov    %eax,(%esp)
80103ddb:	e8 89 ff ff ff       	call   80103d69 <picsetmask>
}
80103de0:	c9                   	leave  
80103de1:	c3                   	ret    

80103de2 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103de2:	55                   	push   %ebp
80103de3:	89 e5                	mov    %esp,%ebp
80103de5:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103de8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103def:	00 
80103df0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103df7:	e8 4f ff ff ff       	call   80103d4b <outb>
  outb(IO_PIC2+1, 0xFF);
80103dfc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103e03:	00 
80103e04:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e0b:	e8 3b ff ff ff       	call   80103d4b <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103e10:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103e17:	00 
80103e18:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e1f:	e8 27 ff ff ff       	call   80103d4b <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103e24:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103e2b:	00 
80103e2c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e33:	e8 13 ff ff ff       	call   80103d4b <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103e38:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103e3f:	00 
80103e40:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e47:	e8 ff fe ff ff       	call   80103d4b <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103e4c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103e53:	00 
80103e54:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e5b:	e8 eb fe ff ff       	call   80103d4b <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103e60:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103e67:	00 
80103e68:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e6f:	e8 d7 fe ff ff       	call   80103d4b <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103e74:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103e7b:	00 
80103e7c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e83:	e8 c3 fe ff ff       	call   80103d4b <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103e88:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103e8f:	00 
80103e90:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e97:	e8 af fe ff ff       	call   80103d4b <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103e9c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103ea3:	00 
80103ea4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103eab:	e8 9b fe ff ff       	call   80103d4b <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103eb0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103eb7:	00 
80103eb8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ebf:	e8 87 fe ff ff       	call   80103d4b <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103ec4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103ecb:	00 
80103ecc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ed3:	e8 73 fe ff ff       	call   80103d4b <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103ed8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103edf:	00 
80103ee0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ee7:	e8 5f fe ff ff       	call   80103d4b <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103eec:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103ef3:	00 
80103ef4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103efb:	e8 4b fe ff ff       	call   80103d4b <outb>

  if(irqmask != 0xFFFF)
80103f00:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103f07:	66 83 f8 ff          	cmp    $0xffff,%ax
80103f0b:	74 12                	je     80103f1f <picinit+0x13d>
    picsetmask(irqmask);
80103f0d:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103f14:	0f b7 c0             	movzwl %ax,%eax
80103f17:	89 04 24             	mov    %eax,(%esp)
80103f1a:	e8 4a fe ff ff       	call   80103d69 <picsetmask>
}
80103f1f:	c9                   	leave  
80103f20:	c3                   	ret    

80103f21 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103f21:	55                   	push   %ebp
80103f22:	89 e5                	mov    %esp,%ebp
80103f24:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103f27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f31:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103f37:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f3a:	8b 10                	mov    (%eax),%edx
80103f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3f:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103f41:	e8 e0 cf ff ff       	call   80100f26 <filealloc>
80103f46:	8b 55 08             	mov    0x8(%ebp),%edx
80103f49:	89 02                	mov    %eax,(%edx)
80103f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4e:	8b 00                	mov    (%eax),%eax
80103f50:	85 c0                	test   %eax,%eax
80103f52:	0f 84 c8 00 00 00    	je     80104020 <pipealloc+0xff>
80103f58:	e8 c9 cf ff ff       	call   80100f26 <filealloc>
80103f5d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f60:	89 02                	mov    %eax,(%edx)
80103f62:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f65:	8b 00                	mov    (%eax),%eax
80103f67:	85 c0                	test   %eax,%eax
80103f69:	0f 84 b1 00 00 00    	je     80104020 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103f6f:	e8 6e eb ff ff       	call   80102ae2 <kalloc>
80103f74:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103f77:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103f7b:	75 05                	jne    80103f82 <pipealloc+0x61>
    goto bad;
80103f7d:	e9 9e 00 00 00       	jmp    80104020 <pipealloc+0xff>
  p->readopen = 1;
80103f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f85:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103f8c:	00 00 00 
  p->writeopen = 1;
80103f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f92:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103f99:	00 00 00 
  p->nwrite = 0;
80103f9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f9f:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103fa6:	00 00 00 
  p->nread = 0;
80103fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fac:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103fb3:	00 00 00 
  initlock(&p->lock, "pipe");
80103fb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fb9:	c7 44 24 04 38 87 10 	movl   $0x80108738,0x4(%esp)
80103fc0:	80 
80103fc1:	89 04 24             	mov    %eax,(%esp)
80103fc4:	e8 b6 0e 00 00       	call   80104e7f <initlock>
  (*f0)->type = FD_PIPE;
80103fc9:	8b 45 08             	mov    0x8(%ebp),%eax
80103fcc:	8b 00                	mov    (%eax),%eax
80103fce:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103fd4:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd7:	8b 00                	mov    (%eax),%eax
80103fd9:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe0:	8b 00                	mov    (%eax),%eax
80103fe2:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe9:	8b 00                	mov    (%eax),%eax
80103feb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103fee:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103ff1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ff4:	8b 00                	mov    (%eax),%eax
80103ff6:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fff:	8b 00                	mov    (%eax),%eax
80104001:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104005:	8b 45 0c             	mov    0xc(%ebp),%eax
80104008:	8b 00                	mov    (%eax),%eax
8010400a:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010400e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104011:	8b 00                	mov    (%eax),%eax
80104013:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104016:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104019:	b8 00 00 00 00       	mov    $0x0,%eax
8010401e:	eb 42                	jmp    80104062 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104020:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104024:	74 0b                	je     80104031 <pipealloc+0x110>
    kfree((char*)p);
80104026:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104029:	89 04 24             	mov    %eax,(%esp)
8010402c:	e8 18 ea ff ff       	call   80102a49 <kfree>
  if(*f0)
80104031:	8b 45 08             	mov    0x8(%ebp),%eax
80104034:	8b 00                	mov    (%eax),%eax
80104036:	85 c0                	test   %eax,%eax
80104038:	74 0d                	je     80104047 <pipealloc+0x126>
    fileclose(*f0);
8010403a:	8b 45 08             	mov    0x8(%ebp),%eax
8010403d:	8b 00                	mov    (%eax),%eax
8010403f:	89 04 24             	mov    %eax,(%esp)
80104042:	e8 87 cf ff ff       	call   80100fce <fileclose>
  if(*f1)
80104047:	8b 45 0c             	mov    0xc(%ebp),%eax
8010404a:	8b 00                	mov    (%eax),%eax
8010404c:	85 c0                	test   %eax,%eax
8010404e:	74 0d                	je     8010405d <pipealloc+0x13c>
    fileclose(*f1);
80104050:	8b 45 0c             	mov    0xc(%ebp),%eax
80104053:	8b 00                	mov    (%eax),%eax
80104055:	89 04 24             	mov    %eax,(%esp)
80104058:	e8 71 cf ff ff       	call   80100fce <fileclose>
  return -1;
8010405d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104062:	c9                   	leave  
80104063:	c3                   	ret    

80104064 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104064:	55                   	push   %ebp
80104065:	89 e5                	mov    %esp,%ebp
80104067:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010406a:	8b 45 08             	mov    0x8(%ebp),%eax
8010406d:	89 04 24             	mov    %eax,(%esp)
80104070:	e8 2b 0e 00 00       	call   80104ea0 <acquire>
  if(writable){
80104075:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104079:	74 1f                	je     8010409a <pipeclose+0x36>
    p->writeopen = 0;
8010407b:	8b 45 08             	mov    0x8(%ebp),%eax
8010407e:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104085:	00 00 00 
    wakeup(&p->nread);
80104088:	8b 45 08             	mov    0x8(%ebp),%eax
8010408b:	05 34 02 00 00       	add    $0x234,%eax
80104090:	89 04 24             	mov    %eax,(%esp)
80104093:	e8 0d 0c 00 00       	call   80104ca5 <wakeup>
80104098:	eb 1d                	jmp    801040b7 <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010409a:	8b 45 08             	mov    0x8(%ebp),%eax
8010409d:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801040a4:	00 00 00 
    wakeup(&p->nwrite);
801040a7:	8b 45 08             	mov    0x8(%ebp),%eax
801040aa:	05 38 02 00 00       	add    $0x238,%eax
801040af:	89 04 24             	mov    %eax,(%esp)
801040b2:	e8 ee 0b 00 00       	call   80104ca5 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801040b7:	8b 45 08             	mov    0x8(%ebp),%eax
801040ba:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801040c0:	85 c0                	test   %eax,%eax
801040c2:	75 25                	jne    801040e9 <pipeclose+0x85>
801040c4:	8b 45 08             	mov    0x8(%ebp),%eax
801040c7:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801040cd:	85 c0                	test   %eax,%eax
801040cf:	75 18                	jne    801040e9 <pipeclose+0x85>
    release(&p->lock);
801040d1:	8b 45 08             	mov    0x8(%ebp),%eax
801040d4:	89 04 24             	mov    %eax,(%esp)
801040d7:	e8 26 0e 00 00       	call   80104f02 <release>
    kfree((char*)p);
801040dc:	8b 45 08             	mov    0x8(%ebp),%eax
801040df:	89 04 24             	mov    %eax,(%esp)
801040e2:	e8 62 e9 ff ff       	call   80102a49 <kfree>
801040e7:	eb 0b                	jmp    801040f4 <pipeclose+0x90>
  } else
    release(&p->lock);
801040e9:	8b 45 08             	mov    0x8(%ebp),%eax
801040ec:	89 04 24             	mov    %eax,(%esp)
801040ef:	e8 0e 0e 00 00       	call   80104f02 <release>
}
801040f4:	c9                   	leave  
801040f5:	c3                   	ret    

801040f6 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801040f6:	55                   	push   %ebp
801040f7:	89 e5                	mov    %esp,%ebp
801040f9:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
801040fc:	8b 45 08             	mov    0x8(%ebp),%eax
801040ff:	89 04 24             	mov    %eax,(%esp)
80104102:	e8 99 0d 00 00       	call   80104ea0 <acquire>
  for(i = 0; i < n; i++){
80104107:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010410e:	e9 a6 00 00 00       	jmp    801041b9 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104113:	eb 57                	jmp    8010416c <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104115:	8b 45 08             	mov    0x8(%ebp),%eax
80104118:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010411e:	85 c0                	test   %eax,%eax
80104120:	74 0d                	je     8010412f <pipewrite+0x39>
80104122:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104128:	8b 40 24             	mov    0x24(%eax),%eax
8010412b:	85 c0                	test   %eax,%eax
8010412d:	74 15                	je     80104144 <pipewrite+0x4e>
        release(&p->lock);
8010412f:	8b 45 08             	mov    0x8(%ebp),%eax
80104132:	89 04 24             	mov    %eax,(%esp)
80104135:	e8 c8 0d 00 00       	call   80104f02 <release>
        return -1;
8010413a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413f:	e9 9f 00 00 00       	jmp    801041e3 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104144:	8b 45 08             	mov    0x8(%ebp),%eax
80104147:	05 34 02 00 00       	add    $0x234,%eax
8010414c:	89 04 24             	mov    %eax,(%esp)
8010414f:	e8 51 0b 00 00       	call   80104ca5 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104154:	8b 45 08             	mov    0x8(%ebp),%eax
80104157:	8b 55 08             	mov    0x8(%ebp),%edx
8010415a:	81 c2 38 02 00 00    	add    $0x238,%edx
80104160:	89 44 24 04          	mov    %eax,0x4(%esp)
80104164:	89 14 24             	mov    %edx,(%esp)
80104167:	e8 61 0a 00 00       	call   80104bcd <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010416c:	8b 45 08             	mov    0x8(%ebp),%eax
8010416f:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104175:	8b 45 08             	mov    0x8(%ebp),%eax
80104178:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010417e:	05 00 02 00 00       	add    $0x200,%eax
80104183:	39 c2                	cmp    %eax,%edx
80104185:	74 8e                	je     80104115 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104187:	8b 45 08             	mov    0x8(%ebp),%eax
8010418a:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104190:	8d 48 01             	lea    0x1(%eax),%ecx
80104193:	8b 55 08             	mov    0x8(%ebp),%edx
80104196:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010419c:	25 ff 01 00 00       	and    $0x1ff,%eax
801041a1:	89 c1                	mov    %eax,%ecx
801041a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801041a9:	01 d0                	add    %edx,%eax
801041ab:	0f b6 10             	movzbl (%eax),%edx
801041ae:	8b 45 08             	mov    0x8(%ebp),%eax
801041b1:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801041b5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801041b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bc:	3b 45 10             	cmp    0x10(%ebp),%eax
801041bf:	0f 8c 4e ff ff ff    	jl     80104113 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801041c5:	8b 45 08             	mov    0x8(%ebp),%eax
801041c8:	05 34 02 00 00       	add    $0x234,%eax
801041cd:	89 04 24             	mov    %eax,(%esp)
801041d0:	e8 d0 0a 00 00       	call   80104ca5 <wakeup>
  release(&p->lock);
801041d5:	8b 45 08             	mov    0x8(%ebp),%eax
801041d8:	89 04 24             	mov    %eax,(%esp)
801041db:	e8 22 0d 00 00       	call   80104f02 <release>
  return n;
801041e0:	8b 45 10             	mov    0x10(%ebp),%eax
}
801041e3:	c9                   	leave  
801041e4:	c3                   	ret    

801041e5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801041e5:	55                   	push   %ebp
801041e6:	89 e5                	mov    %esp,%ebp
801041e8:	53                   	push   %ebx
801041e9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801041ec:	8b 45 08             	mov    0x8(%ebp),%eax
801041ef:	89 04 24             	mov    %eax,(%esp)
801041f2:	e8 a9 0c 00 00       	call   80104ea0 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801041f7:	eb 3a                	jmp    80104233 <piperead+0x4e>
    if(proc->killed){
801041f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801041ff:	8b 40 24             	mov    0x24(%eax),%eax
80104202:	85 c0                	test   %eax,%eax
80104204:	74 15                	je     8010421b <piperead+0x36>
      release(&p->lock);
80104206:	8b 45 08             	mov    0x8(%ebp),%eax
80104209:	89 04 24             	mov    %eax,(%esp)
8010420c:	e8 f1 0c 00 00       	call   80104f02 <release>
      return -1;
80104211:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104216:	e9 b5 00 00 00       	jmp    801042d0 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010421b:	8b 45 08             	mov    0x8(%ebp),%eax
8010421e:	8b 55 08             	mov    0x8(%ebp),%edx
80104221:	81 c2 34 02 00 00    	add    $0x234,%edx
80104227:	89 44 24 04          	mov    %eax,0x4(%esp)
8010422b:	89 14 24             	mov    %edx,(%esp)
8010422e:	e8 9a 09 00 00       	call   80104bcd <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104233:	8b 45 08             	mov    0x8(%ebp),%eax
80104236:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010423c:	8b 45 08             	mov    0x8(%ebp),%eax
8010423f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104245:	39 c2                	cmp    %eax,%edx
80104247:	75 0d                	jne    80104256 <piperead+0x71>
80104249:	8b 45 08             	mov    0x8(%ebp),%eax
8010424c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104252:	85 c0                	test   %eax,%eax
80104254:	75 a3                	jne    801041f9 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104256:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010425d:	eb 4b                	jmp    801042aa <piperead+0xc5>
    if(p->nread == p->nwrite)
8010425f:	8b 45 08             	mov    0x8(%ebp),%eax
80104262:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104268:	8b 45 08             	mov    0x8(%ebp),%eax
8010426b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104271:	39 c2                	cmp    %eax,%edx
80104273:	75 02                	jne    80104277 <piperead+0x92>
      break;
80104275:	eb 3b                	jmp    801042b2 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104277:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010427a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010427d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104280:	8b 45 08             	mov    0x8(%ebp),%eax
80104283:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104289:	8d 48 01             	lea    0x1(%eax),%ecx
8010428c:	8b 55 08             	mov    0x8(%ebp),%edx
8010428f:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104295:	25 ff 01 00 00       	and    $0x1ff,%eax
8010429a:	89 c2                	mov    %eax,%edx
8010429c:	8b 45 08             	mov    0x8(%ebp),%eax
8010429f:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801042a4:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801042a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801042aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ad:	3b 45 10             	cmp    0x10(%ebp),%eax
801042b0:	7c ad                	jl     8010425f <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801042b2:	8b 45 08             	mov    0x8(%ebp),%eax
801042b5:	05 38 02 00 00       	add    $0x238,%eax
801042ba:	89 04 24             	mov    %eax,(%esp)
801042bd:	e8 e3 09 00 00       	call   80104ca5 <wakeup>
  release(&p->lock);
801042c2:	8b 45 08             	mov    0x8(%ebp),%eax
801042c5:	89 04 24             	mov    %eax,(%esp)
801042c8:	e8 35 0c 00 00       	call   80104f02 <release>
  return i;
801042cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801042d0:	83 c4 24             	add    $0x24,%esp
801042d3:	5b                   	pop    %ebx
801042d4:	5d                   	pop    %ebp
801042d5:	c3                   	ret    

801042d6 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801042d6:	55                   	push   %ebp
801042d7:	89 e5                	mov    %esp,%ebp
801042d9:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801042dc:	9c                   	pushf  
801042dd:	58                   	pop    %eax
801042de:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801042e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801042e4:	c9                   	leave  
801042e5:	c3                   	ret    

801042e6 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801042e6:	55                   	push   %ebp
801042e7:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801042e9:	fb                   	sti    
}
801042ea:	5d                   	pop    %ebp
801042eb:	c3                   	ret    

801042ec <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801042ec:	55                   	push   %ebp
801042ed:	89 e5                	mov    %esp,%ebp
801042ef:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801042f2:	c7 44 24 04 3d 87 10 	movl   $0x8010873d,0x4(%esp)
801042f9:	80 
801042fa:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104301:	e8 79 0b 00 00       	call   80104e7f <initlock>
}
80104306:	c9                   	leave  
80104307:	c3                   	ret    

80104308 <allocpid>:

int 
allocpid(void) 
{
80104308:	55                   	push   %ebp
80104309:	89 e5                	mov    %esp,%ebp
8010430b:	83 ec 28             	sub    $0x28,%esp
  int pid;
  acquire(&ptable.lock);
8010430e:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104315:	e8 86 0b 00 00       	call   80104ea0 <acquire>
  pid = nextpid++;
8010431a:	a1 04 b0 10 80       	mov    0x8010b004,%eax
8010431f:	8d 50 01             	lea    0x1(%eax),%edx
80104322:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
80104328:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&ptable.lock);
8010432b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104332:	e8 cb 0b 00 00       	call   80104f02 <release>
  return pid;
80104337:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010433a:	c9                   	leave  
8010433b:	c3                   	ret    

8010433c <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010433c:	55                   	push   %ebp
8010433d:	89 e5                	mov    %esp,%ebp
8010433f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104342:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104349:	e8 52 0b 00 00       	call   80104ea0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010434e:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104355:	eb 47                	jmp    8010439e <allocproc+0x62>
    if(p->state == UNUSED)
80104357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435a:	8b 40 0c             	mov    0xc(%eax),%eax
8010435d:	85 c0                	test   %eax,%eax
8010435f:	75 39                	jne    8010439a <allocproc+0x5e>
      goto found;
80104361:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;  
80104362:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104365:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  release(&ptable.lock);
8010436c:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104373:	e8 8a 0b 00 00       	call   80104f02 <release>

  p->pid = allocpid();
80104378:	e8 8b ff ff ff       	call   80104308 <allocpid>
8010437d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104380:	89 42 10             	mov    %eax,0x10(%edx)

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104383:	e8 5a e7 ff ff       	call   80102ae2 <kalloc>
80104388:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010438b:	89 42 08             	mov    %eax,0x8(%edx)
8010438e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104391:	8b 40 08             	mov    0x8(%eax),%eax
80104394:	85 c0                	test   %eax,%eax
80104396:	75 33                	jne    801043cb <allocproc+0x8f>
80104398:	eb 20                	jmp    801043ba <allocproc+0x7e>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010439a:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010439e:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
801043a5:	72 b0                	jb     80104357 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801043a7:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043ae:	e8 4f 0b 00 00       	call   80104f02 <release>
  return 0;
801043b3:	b8 00 00 00 00       	mov    $0x0,%eax
801043b8:	eb 76                	jmp    80104430 <allocproc+0xf4>

  p->pid = allocpid();

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801043ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043bd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801043c4:	b8 00 00 00 00       	mov    $0x0,%eax
801043c9:	eb 65                	jmp    80104430 <allocproc+0xf4>
  }
  sp = p->kstack + KSTACKSIZE;
801043cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ce:	8b 40 08             	mov    0x8(%eax),%eax
801043d1:	05 00 10 00 00       	add    $0x1000,%eax
801043d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801043d9:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801043dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043e0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801043e3:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801043e6:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801043ea:	ba 08 65 10 80       	mov    $0x80106508,%edx
801043ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043f2:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801043f4:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801043f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801043fe:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104401:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104404:	8b 40 1c             	mov    0x1c(%eax),%eax
80104407:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010440e:	00 
8010440f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104416:	00 
80104417:	89 04 24             	mov    %eax,(%esp)
8010441a:	e8 d5 0c 00 00       	call   801050f4 <memset>
  p->context->eip = (uint)forkret;
8010441f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104422:	8b 40 1c             	mov    0x1c(%eax),%eax
80104425:	ba a1 4b 10 80       	mov    $0x80104ba1,%edx
8010442a:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010442d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104430:	c9                   	leave  
80104431:	c3                   	ret    

80104432 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104432:	55                   	push   %ebp
80104433:	89 e5                	mov    %esp,%ebp
80104435:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104438:	e8 ff fe ff ff       	call   8010433c <allocproc>
8010443d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104440:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104443:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104448:	e8 af 37 00 00       	call   80107bfc <setupkvm>
8010444d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104450:	89 42 04             	mov    %eax,0x4(%edx)
80104453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104456:	8b 40 04             	mov    0x4(%eax),%eax
80104459:	85 c0                	test   %eax,%eax
8010445b:	75 0c                	jne    80104469 <userinit+0x37>
    panic("userinit: out of memory?");
8010445d:	c7 04 24 44 87 10 80 	movl   $0x80108744,(%esp)
80104464:	e8 d1 c0 ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104469:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010446e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104471:	8b 40 04             	mov    0x4(%eax),%eax
80104474:	89 54 24 08          	mov    %edx,0x8(%esp)
80104478:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
8010447f:	80 
80104480:	89 04 24             	mov    %eax,(%esp)
80104483:	e8 cc 39 00 00       	call   80107e54 <inituvm>
  p->sz = PGSIZE;
80104488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010448b:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104491:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104494:	8b 40 18             	mov    0x18(%eax),%eax
80104497:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010449e:	00 
8010449f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801044a6:	00 
801044a7:	89 04 24             	mov    %eax,(%esp)
801044aa:	e8 45 0c 00 00       	call   801050f4 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801044af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b2:	8b 40 18             	mov    0x18(%eax),%eax
801044b5:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801044bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044be:	8b 40 18             	mov    0x18(%eax),%eax
801044c1:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801044c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ca:	8b 40 18             	mov    0x18(%eax),%eax
801044cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044d0:	8b 52 18             	mov    0x18(%edx),%edx
801044d3:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801044d7:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801044db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044de:	8b 40 18             	mov    0x18(%eax),%eax
801044e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044e4:	8b 52 18             	mov    0x18(%edx),%edx
801044e7:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801044eb:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801044ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f2:	8b 40 18             	mov    0x18(%eax),%eax
801044f5:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801044fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ff:	8b 40 18             	mov    0x18(%eax),%eax
80104502:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010450c:	8b 40 18             	mov    0x18(%eax),%eax
8010450f:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104516:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104519:	83 c0 6c             	add    $0x6c,%eax
8010451c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104523:	00 
80104524:	c7 44 24 04 5d 87 10 	movl   $0x8010875d,0x4(%esp)
8010452b:	80 
8010452c:	89 04 24             	mov    %eax,(%esp)
8010452f:	e8 e0 0d 00 00       	call   80105314 <safestrcpy>
  p->cwd = namei("/");
80104534:	c7 04 24 66 87 10 80 	movl   $0x80108766,(%esp)
8010453b:	e8 c6 de ff ff       	call   80102406 <namei>
80104540:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104543:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104546:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104549:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104550:	c9                   	leave  
80104551:	c3                   	ret    

80104552 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104552:	55                   	push   %ebp
80104553:	89 e5                	mov    %esp,%ebp
80104555:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104558:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010455e:	8b 00                	mov    (%eax),%eax
80104560:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104563:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104567:	7e 34                	jle    8010459d <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104569:	8b 55 08             	mov    0x8(%ebp),%edx
8010456c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456f:	01 c2                	add    %eax,%edx
80104571:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104577:	8b 40 04             	mov    0x4(%eax),%eax
8010457a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010457e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104581:	89 54 24 04          	mov    %edx,0x4(%esp)
80104585:	89 04 24             	mov    %eax,(%esp)
80104588:	e8 3d 3a 00 00       	call   80107fca <allocuvm>
8010458d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104590:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104594:	75 41                	jne    801045d7 <growproc+0x85>
      return -1;
80104596:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010459b:	eb 58                	jmp    801045f5 <growproc+0xa3>
  } else if(n < 0){
8010459d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801045a1:	79 34                	jns    801045d7 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801045a3:	8b 55 08             	mov    0x8(%ebp),%edx
801045a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045a9:	01 c2                	add    %eax,%edx
801045ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045b1:	8b 40 04             	mov    0x4(%eax),%eax
801045b4:	89 54 24 08          	mov    %edx,0x8(%esp)
801045b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801045bf:	89 04 24             	mov    %eax,(%esp)
801045c2:	e8 dd 3a 00 00       	call   801080a4 <deallocuvm>
801045c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801045ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801045ce:	75 07                	jne    801045d7 <growproc+0x85>
      return -1;
801045d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045d5:	eb 1e                	jmp    801045f5 <growproc+0xa3>
  }
  proc->sz = sz;
801045d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045e0:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801045e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045e8:	89 04 24             	mov    %eax,(%esp)
801045eb:	e8 fd 36 00 00       	call   80107ced <switchuvm>
  return 0;
801045f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045f5:	c9                   	leave  
801045f6:	c3                   	ret    

801045f7 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801045f7:	55                   	push   %ebp
801045f8:	89 e5                	mov    %esp,%ebp
801045fa:	57                   	push   %edi
801045fb:	56                   	push   %esi
801045fc:	53                   	push   %ebx
801045fd:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104600:	e8 37 fd ff ff       	call   8010433c <allocproc>
80104605:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104608:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010460c:	75 0a                	jne    80104618 <fork+0x21>
    return -1;
8010460e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104613:	e9 52 01 00 00       	jmp    8010476a <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104618:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010461e:	8b 10                	mov    (%eax),%edx
80104620:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104626:	8b 40 04             	mov    0x4(%eax),%eax
80104629:	89 54 24 04          	mov    %edx,0x4(%esp)
8010462d:	89 04 24             	mov    %eax,(%esp)
80104630:	e8 0b 3c 00 00       	call   80108240 <copyuvm>
80104635:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104638:	89 42 04             	mov    %eax,0x4(%edx)
8010463b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010463e:	8b 40 04             	mov    0x4(%eax),%eax
80104641:	85 c0                	test   %eax,%eax
80104643:	75 2c                	jne    80104671 <fork+0x7a>
    kfree(np->kstack);
80104645:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104648:	8b 40 08             	mov    0x8(%eax),%eax
8010464b:	89 04 24             	mov    %eax,(%esp)
8010464e:	e8 f6 e3 ff ff       	call   80102a49 <kfree>
    np->kstack = 0;
80104653:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104656:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010465d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104660:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104667:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010466c:	e9 f9 00 00 00       	jmp    8010476a <fork+0x173>
  }
  np->sz = proc->sz;
80104671:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104677:	8b 10                	mov    (%eax),%edx
80104679:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010467c:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010467e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104685:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104688:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010468b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010468e:	8b 50 18             	mov    0x18(%eax),%edx
80104691:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104697:	8b 40 18             	mov    0x18(%eax),%eax
8010469a:	89 c3                	mov    %eax,%ebx
8010469c:	b8 13 00 00 00       	mov    $0x13,%eax
801046a1:	89 d7                	mov    %edx,%edi
801046a3:	89 de                	mov    %ebx,%esi
801046a5:	89 c1                	mov    %eax,%ecx
801046a7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801046a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046ac:	8b 40 18             	mov    0x18(%eax),%eax
801046af:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801046b6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801046bd:	eb 3d                	jmp    801046fc <fork+0x105>
    if(proc->ofile[i])
801046bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046c5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801046c8:	83 c2 08             	add    $0x8,%edx
801046cb:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046cf:	85 c0                	test   %eax,%eax
801046d1:	74 25                	je     801046f8 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801046d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801046dc:	83 c2 08             	add    $0x8,%edx
801046df:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046e3:	89 04 24             	mov    %eax,(%esp)
801046e6:	e8 9b c8 ff ff       	call   80100f86 <filedup>
801046eb:	8b 55 e0             	mov    -0x20(%ebp),%edx
801046ee:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801046f1:	83 c1 08             	add    $0x8,%ecx
801046f4:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801046f8:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801046fc:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104700:	7e bd                	jle    801046bf <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104702:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104708:	8b 40 68             	mov    0x68(%eax),%eax
8010470b:	89 04 24             	mov    %eax,(%esp)
8010470e:	e8 16 d1 ff ff       	call   80101829 <idup>
80104713:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104716:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104719:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471f:	8d 50 6c             	lea    0x6c(%eax),%edx
80104722:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104725:	83 c0 6c             	add    $0x6c,%eax
80104728:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010472f:	00 
80104730:	89 54 24 04          	mov    %edx,0x4(%esp)
80104734:	89 04 24             	mov    %eax,(%esp)
80104737:	e8 d8 0b 00 00       	call   80105314 <safestrcpy>
 
  pid = np->pid;
8010473c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010473f:	8b 40 10             	mov    0x10(%eax),%eax
80104742:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104745:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010474c:	e8 4f 07 00 00       	call   80104ea0 <acquire>
  np->state = RUNNABLE;
80104751:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104754:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
8010475b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104762:	e8 9b 07 00 00       	call   80104f02 <release>
  
  return pid;
80104767:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010476a:	83 c4 2c             	add    $0x2c,%esp
8010476d:	5b                   	pop    %ebx
8010476e:	5e                   	pop    %esi
8010476f:	5f                   	pop    %edi
80104770:	5d                   	pop    %ebp
80104771:	c3                   	ret    

80104772 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104772:	55                   	push   %ebp
80104773:	89 e5                	mov    %esp,%ebp
80104775:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104778:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010477f:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104784:	39 c2                	cmp    %eax,%edx
80104786:	75 0c                	jne    80104794 <exit+0x22>
    panic("init exiting");
80104788:	c7 04 24 68 87 10 80 	movl   $0x80108768,(%esp)
8010478f:	e8 a6 bd ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104794:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010479b:	eb 44                	jmp    801047e1 <exit+0x6f>
    if(proc->ofile[fd]){
8010479d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047a3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047a6:	83 c2 08             	add    $0x8,%edx
801047a9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047ad:	85 c0                	test   %eax,%eax
801047af:	74 2c                	je     801047dd <exit+0x6b>
      fileclose(proc->ofile[fd]);
801047b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047b7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047ba:	83 c2 08             	add    $0x8,%edx
801047bd:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047c1:	89 04 24             	mov    %eax,(%esp)
801047c4:	e8 05 c8 ff ff       	call   80100fce <fileclose>
      proc->ofile[fd] = 0;
801047c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047d2:	83 c2 08             	add    $0x8,%edx
801047d5:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801047dc:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801047dd:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801047e1:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801047e5:	7e b6                	jle    8010479d <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
801047e7:	e8 24 ec ff ff       	call   80103410 <begin_op>
  iput(proc->cwd);
801047ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f2:	8b 40 68             	mov    0x68(%eax),%eax
801047f5:	89 04 24             	mov    %eax,(%esp)
801047f8:	e8 11 d2 ff ff       	call   80101a0e <iput>
  end_op();
801047fd:	e8 92 ec ff ff       	call   80103494 <end_op>
  proc->cwd = 0;
80104802:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104808:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
8010480f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104816:	e8 85 06 00 00       	call   80104ea0 <acquire>

  proc->state = ZOMBIE;
8010481b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104821:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104828:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010482e:	8b 40 14             	mov    0x14(%eax),%eax
80104831:	89 04 24             	mov    %eax,(%esp)
80104834:	e8 22 04 00 00       	call   80104c5b <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104839:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104840:	eb 38                	jmp    8010487a <exit+0x108>
    if(p->parent == proc){
80104842:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104845:	8b 50 14             	mov    0x14(%eax),%edx
80104848:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484e:	39 c2                	cmp    %eax,%edx
80104850:	75 24                	jne    80104876 <exit+0x104>
      p->parent = initproc;
80104852:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104858:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010485b:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010485e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104861:	8b 40 0c             	mov    0xc(%eax),%eax
80104864:	83 f8 05             	cmp    $0x5,%eax
80104867:	75 0d                	jne    80104876 <exit+0x104>
        wakeup1(initproc);
80104869:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010486e:	89 04 24             	mov    %eax,(%esp)
80104871:	e8 e5 03 00 00       	call   80104c5b <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104876:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010487a:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104881:	72 bf                	jb     80104842 <exit+0xd0>
    }
  }

  // Jump into the scheduler, never to return.
  
  sched();
80104883:	e8 35 02 00 00       	call   80104abd <sched>
  panic("zombie exit");
80104888:	c7 04 24 75 87 10 80 	movl   $0x80108775,(%esp)
8010488f:	e8 a6 bc ff ff       	call   8010053a <panic>

80104894 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104894:	55                   	push   %ebp
80104895:	89 e5                	mov    %esp,%ebp
80104897:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010489a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801048a1:	e8 fa 05 00 00       	call   80104ea0 <acquire>
  for(;;){
    proc->chan = (int)proc;
801048a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ac:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048b3:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;    
801048b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048bc:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    // Scan through table looking for zombie children.
    havekids = 0;
801048c3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048ca:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801048d1:	e9 81 00 00 00       	jmp    80104957 <wait+0xc3>
      if(p->parent != proc)
801048d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d9:	8b 50 14             	mov    0x14(%eax),%edx
801048dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e2:	39 c2                	cmp    %eax,%edx
801048e4:	74 02                	je     801048e8 <wait+0x54>
        continue;
801048e6:	eb 6b                	jmp    80104953 <wait+0xbf>
      havekids = 1;
801048e8:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801048ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048f2:	8b 40 0c             	mov    0xc(%eax),%eax
801048f5:	83 f8 05             	cmp    $0x5,%eax
801048f8:	75 59                	jne    80104953 <wait+0xbf>
        // Found one.
        pid = p->pid;
801048fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048fd:	8b 40 10             	mov    0x10(%eax),%eax
80104900:	89 45 ec             	mov    %eax,-0x14(%ebp)
        p->state = UNUSED;
80104903:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104906:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010490d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104910:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104917:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104921:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104924:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)

        proc->chan = 0;
80104928:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010492e:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
        proc->state = RUNNING;
80104935:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493b:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
        release(&ptable.lock);
80104942:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104949:	e8 b4 05 00 00       	call   80104f02 <release>
        return pid;
8010494e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104951:	eb 5b                	jmp    801049ae <wait+0x11a>
  for(;;){
    proc->chan = (int)proc;
    proc->state = SLEEPING;    
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104953:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104957:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
8010495e:	0f 82 72 ff ff ff    	jb     801048d6 <wait+0x42>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104964:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104968:	74 0d                	je     80104977 <wait+0xe3>
8010496a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104970:	8b 40 24             	mov    0x24(%eax),%eax
80104973:	85 c0                	test   %eax,%eax
80104975:	74 2d                	je     801049a4 <wait+0x110>
      proc->chan = 0;
80104977:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497d:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
      proc->state = RUNNING;      
80104984:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010498a:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      release(&ptable.lock);
80104991:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104998:	e8 65 05 00 00       	call   80104f02 <release>
      return -1;
8010499d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049a2:	eb 0a                	jmp    801049ae <wait+0x11a>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sched();
801049a4:	e8 14 01 00 00       	call   80104abd <sched>
  }
801049a9:	e9 f8 fe ff ff       	jmp    801048a6 <wait+0x12>
}
801049ae:	c9                   	leave  
801049af:	c3                   	ret    

801049b0 <freeproc>:

void 
freeproc(struct proc *p)
{
801049b0:	55                   	push   %ebp
801049b1:	89 e5                	mov    %esp,%ebp
801049b3:	83 ec 18             	sub    $0x18,%esp
  if (!p || p->state != ZOMBIE)
801049b6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801049ba:	74 0b                	je     801049c7 <freeproc+0x17>
801049bc:	8b 45 08             	mov    0x8(%ebp),%eax
801049bf:	8b 40 0c             	mov    0xc(%eax),%eax
801049c2:	83 f8 05             	cmp    $0x5,%eax
801049c5:	74 0c                	je     801049d3 <freeproc+0x23>
    panic("freeproc not zombie");
801049c7:	c7 04 24 81 87 10 80 	movl   $0x80108781,(%esp)
801049ce:	e8 67 bb ff ff       	call   8010053a <panic>
  kfree(p->kstack);
801049d3:	8b 45 08             	mov    0x8(%ebp),%eax
801049d6:	8b 40 08             	mov    0x8(%eax),%eax
801049d9:	89 04 24             	mov    %eax,(%esp)
801049dc:	e8 68 e0 ff ff       	call   80102a49 <kfree>
  p->kstack = 0;
801049e1:	8b 45 08             	mov    0x8(%ebp),%eax
801049e4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  freevm(p->pgdir);
801049eb:	8b 45 08             	mov    0x8(%ebp),%eax
801049ee:	8b 40 04             	mov    0x4(%eax),%eax
801049f1:	89 04 24             	mov    %eax,(%esp)
801049f4:	e8 67 37 00 00       	call   80108160 <freevm>
  p->killed = 0;
801049f9:	8b 45 08             	mov    0x8(%ebp),%eax
801049fc:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
  p->chan = 0;
80104a03:	8b 45 08             	mov    0x8(%ebp),%eax
80104a06:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
}
80104a0d:	c9                   	leave  
80104a0e:	c3                   	ret    

80104a0f <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104a0f:	55                   	push   %ebp
80104a10:	89 e5                	mov    %esp,%ebp
80104a12:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104a15:	e8 cc f8 ff ff       	call   801042e6 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104a1a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a21:	e8 7a 04 00 00       	call   80104ea0 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a26:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104a2d:	eb 74                	jmp    80104aa3 <scheduler+0x94>
      if(p->state != RUNNABLE)
80104a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a32:	8b 40 0c             	mov    0xc(%eax),%eax
80104a35:	83 f8 03             	cmp    $0x3,%eax
80104a38:	74 02                	je     80104a3c <scheduler+0x2d>
        continue;
80104a3a:	eb 63                	jmp    80104a9f <scheduler+0x90>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3f:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a48:	89 04 24             	mov    %eax,(%esp)
80104a4b:	e8 9d 32 00 00       	call   80107ced <switchuvm>
      p->state = RUNNING;
80104a50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a53:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104a5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a60:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a63:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104a6a:	83 c2 04             	add    $0x4,%edx
80104a6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a71:	89 14 24             	mov    %edx,(%esp)
80104a74:	e8 0c 09 00 00       	call   80105385 <swtch>
      switchkvm();
80104a79:	e8 52 32 00 00       	call   80107cd0 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104a7e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104a85:	00 00 00 00 
      if (p->state == ZOMBIE)
80104a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8c:	8b 40 0c             	mov    0xc(%eax),%eax
80104a8f:	83 f8 05             	cmp    $0x5,%eax
80104a92:	75 0b                	jne    80104a9f <scheduler+0x90>
        freeproc(p);
80104a94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a97:	89 04 24             	mov    %eax,(%esp)
80104a9a:	e8 11 ff ff ff       	call   801049b0 <freeproc>
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a9f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104aa3:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104aaa:	72 83                	jb     80104a2f <scheduler+0x20>
      // It should have changed its p->state before coming back.
      proc = 0;
      if (p->state == ZOMBIE)
        freeproc(p);
    }
    release(&ptable.lock);
80104aac:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ab3:	e8 4a 04 00 00       	call   80104f02 <release>

  }
80104ab8:	e9 58 ff ff ff       	jmp    80104a15 <scheduler+0x6>

80104abd <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104abd:	55                   	push   %ebp
80104abe:	89 e5                	mov    %esp,%ebp
80104ac0:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104ac3:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104aca:	e8 fb 04 00 00       	call   80104fca <holding>
80104acf:	85 c0                	test   %eax,%eax
80104ad1:	75 0c                	jne    80104adf <sched+0x22>
    panic("sched ptable.lock");
80104ad3:	c7 04 24 95 87 10 80 	movl   $0x80108795,(%esp)
80104ada:	e8 5b ba ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104adf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ae5:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104aeb:	83 f8 01             	cmp    $0x1,%eax
80104aee:	74 0c                	je     80104afc <sched+0x3f>
    panic("sched locks");
80104af0:	c7 04 24 a7 87 10 80 	movl   $0x801087a7,(%esp)
80104af7:	e8 3e ba ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104afc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b02:	8b 40 0c             	mov    0xc(%eax),%eax
80104b05:	83 f8 04             	cmp    $0x4,%eax
80104b08:	75 0c                	jne    80104b16 <sched+0x59>
    panic("sched running");
80104b0a:	c7 04 24 b3 87 10 80 	movl   $0x801087b3,(%esp)
80104b11:	e8 24 ba ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104b16:	e8 bb f7 ff ff       	call   801042d6 <readeflags>
80104b1b:	25 00 02 00 00       	and    $0x200,%eax
80104b20:	85 c0                	test   %eax,%eax
80104b22:	74 0c                	je     80104b30 <sched+0x73>
    panic("sched interruptible");
80104b24:	c7 04 24 c1 87 10 80 	movl   $0x801087c1,(%esp)
80104b2b:	e8 0a ba ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104b30:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b36:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104b3c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104b3f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b45:	8b 40 04             	mov    0x4(%eax),%eax
80104b48:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b4f:	83 c2 1c             	add    $0x1c,%edx
80104b52:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b56:	89 14 24             	mov    %edx,(%esp)
80104b59:	e8 27 08 00 00       	call   80105385 <swtch>
  cpu->intena = intena;
80104b5e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b64:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b67:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104b6d:	c9                   	leave  
80104b6e:	c3                   	ret    

80104b6f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104b6f:	55                   	push   %ebp
80104b70:	89 e5                	mov    %esp,%ebp
80104b72:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104b75:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b7c:	e8 1f 03 00 00       	call   80104ea0 <acquire>
  proc->state = RUNNABLE;
80104b81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b87:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104b8e:	e8 2a ff ff ff       	call   80104abd <sched>
  release(&ptable.lock);
80104b93:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104b9a:	e8 63 03 00 00       	call   80104f02 <release>
}
80104b9f:	c9                   	leave  
80104ba0:	c3                   	ret    

80104ba1 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104ba1:	55                   	push   %ebp
80104ba2:	89 e5                	mov    %esp,%ebp
80104ba4:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104ba7:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bae:	e8 4f 03 00 00       	call   80104f02 <release>

  if (first) {
80104bb3:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104bb8:	85 c0                	test   %eax,%eax
80104bba:	74 0f                	je     80104bcb <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104bbc:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104bc3:	00 00 00 
    initlog();
80104bc6:	e8 37 e6 ff ff       	call   80103202 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104bcb:	c9                   	leave  
80104bcc:	c3                   	ret    

80104bcd <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104bcd:	55                   	push   %ebp
80104bce:	89 e5                	mov    %esp,%ebp
80104bd0:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104bd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bd9:	85 c0                	test   %eax,%eax
80104bdb:	75 0c                	jne    80104be9 <sleep+0x1c>
    panic("sleep");
80104bdd:	c7 04 24 d5 87 10 80 	movl   $0x801087d5,(%esp)
80104be4:	e8 51 b9 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104be9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104bed:	75 0c                	jne    80104bfb <sleep+0x2e>
    panic("sleep without lk");
80104bef:	c7 04 24 db 87 10 80 	movl   $0x801087db,(%esp)
80104bf6:	e8 3f b9 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104bfb:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c02:	74 17                	je     80104c1b <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104c04:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c0b:	e8 90 02 00 00       	call   80104ea0 <acquire>
    release(lk);
80104c10:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c13:	89 04 24             	mov    %eax,(%esp)
80104c16:	e8 e7 02 00 00       	call   80104f02 <release>
  }

  // Go to sleep.
  proc->chan = (int)chan;
80104c1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c21:	8b 55 08             	mov    0x8(%ebp),%edx
80104c24:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104c27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c2d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)


  sched();
80104c34:	e8 84 fe ff ff       	call   80104abd <sched>

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104c39:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c40:	74 17                	je     80104c59 <sleep+0x8c>
    release(&ptable.lock);
80104c42:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c49:	e8 b4 02 00 00       	call   80104f02 <release>
    acquire(lk);
80104c4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c51:	89 04 24             	mov    %eax,(%esp)
80104c54:	e8 47 02 00 00       	call   80104ea0 <acquire>
  }
}
80104c59:	c9                   	leave  
80104c5a:	c3                   	ret    

80104c5b <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104c5b:	55                   	push   %ebp
80104c5c:	89 e5                	mov    %esp,%ebp
80104c5e:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c61:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104c68:	eb 30                	jmp    80104c9a <wakeup1+0x3f>
    if(p->state == SLEEPING && p->chan == (int)chan){
80104c6a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c6d:	8b 40 0c             	mov    0xc(%eax),%eax
80104c70:	83 f8 02             	cmp    $0x2,%eax
80104c73:	75 21                	jne    80104c96 <wakeup1+0x3b>
80104c75:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c78:	8b 50 20             	mov    0x20(%eax),%edx
80104c7b:	8b 45 08             	mov    0x8(%ebp),%eax
80104c7e:	39 c2                	cmp    %eax,%edx
80104c80:	75 14                	jne    80104c96 <wakeup1+0x3b>
      // Tidy up.
      p->chan = 0;
80104c82:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c85:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
      p->state = RUNNABLE;
80104c8c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c8f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c96:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104c9a:	81 7d fc 94 48 11 80 	cmpl   $0x80114894,-0x4(%ebp)
80104ca1:	72 c7                	jb     80104c6a <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == (int)chan){
      // Tidy up.
      p->chan = 0;
      p->state = RUNNABLE;
    }
}
80104ca3:	c9                   	leave  
80104ca4:	c3                   	ret    

80104ca5 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104ca5:	55                   	push   %ebp
80104ca6:	89 e5                	mov    %esp,%ebp
80104ca8:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104cab:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cb2:	e8 e9 01 00 00       	call   80104ea0 <acquire>
  wakeup1(chan);
80104cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80104cba:	89 04 24             	mov    %eax,(%esp)
80104cbd:	e8 99 ff ff ff       	call   80104c5b <wakeup1>
  release(&ptable.lock);
80104cc2:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cc9:	e8 34 02 00 00       	call   80104f02 <release>
}
80104cce:	c9                   	leave  
80104ccf:	c3                   	ret    

80104cd0 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104cd0:	55                   	push   %ebp
80104cd1:	89 e5                	mov    %esp,%ebp
80104cd3:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104cd6:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cdd:	e8 be 01 00 00       	call   80104ea0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ce2:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104ce9:	eb 41                	jmp    80104d2c <kill+0x5c>
    if(p->pid == pid){
80104ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cee:	8b 40 10             	mov    0x10(%eax),%eax
80104cf1:	3b 45 08             	cmp    0x8(%ebp),%eax
80104cf4:	75 32                	jne    80104d28 <kill+0x58>
      p->killed = 1;
80104cf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf9:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104d00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d03:	8b 40 0c             	mov    0xc(%eax),%eax
80104d06:	83 f8 02             	cmp    $0x2,%eax
80104d09:	75 0a                	jne    80104d15 <kill+0x45>
        p->state = RUNNABLE;
80104d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d0e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104d15:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d1c:	e8 e1 01 00 00       	call   80104f02 <release>
      return 0;
80104d21:	b8 00 00 00 00       	mov    $0x0,%eax
80104d26:	eb 1e                	jmp    80104d46 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d28:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104d2c:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104d33:	72 b6                	jb     80104ceb <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104d35:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d3c:	e8 c1 01 00 00       	call   80104f02 <release>
  return -1;
80104d41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d46:	c9                   	leave  
80104d47:	c3                   	ret    

80104d48 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104d48:	55                   	push   %ebp
80104d49:	89 e5                	mov    %esp,%ebp
80104d4b:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d4e:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104d55:	e9 e0 00 00 00       	jmp    80104e3a <procdump+0xf2>
    if(p->state == UNUSED)
80104d5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d5d:	8b 40 0c             	mov    0xc(%eax),%eax
80104d60:	85 c0                	test   %eax,%eax
80104d62:	75 05                	jne    80104d69 <procdump+0x21>
      continue;
80104d64:	e9 cd 00 00 00       	jmp    80104e36 <procdump+0xee>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104d69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6c:	8b 40 0c             	mov    0xc(%eax),%eax
80104d6f:	85 c0                	test   %eax,%eax
80104d71:	78 2e                	js     80104da1 <procdump+0x59>
80104d73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d76:	8b 40 0c             	mov    0xc(%eax),%eax
80104d79:	83 f8 05             	cmp    $0x5,%eax
80104d7c:	77 23                	ja     80104da1 <procdump+0x59>
80104d7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d81:	8b 40 0c             	mov    0xc(%eax),%eax
80104d84:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104d8b:	85 c0                	test   %eax,%eax
80104d8d:	74 12                	je     80104da1 <procdump+0x59>
      state = states[p->state];
80104d8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d92:	8b 40 0c             	mov    0xc(%eax),%eax
80104d95:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104d9c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104d9f:	eb 07                	jmp    80104da8 <procdump+0x60>
    else
      state = "???";
80104da1:	c7 45 ec ec 87 10 80 	movl   $0x801087ec,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104da8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dab:	8d 50 6c             	lea    0x6c(%eax),%edx
80104dae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104db1:	8b 40 10             	mov    0x10(%eax),%eax
80104db4:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104db8:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104dbb:	89 54 24 08          	mov    %edx,0x8(%esp)
80104dbf:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dc3:	c7 04 24 f0 87 10 80 	movl   $0x801087f0,(%esp)
80104dca:	e8 d1 b5 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104dcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dd2:	8b 40 0c             	mov    0xc(%eax),%eax
80104dd5:	83 f8 02             	cmp    $0x2,%eax
80104dd8:	75 50                	jne    80104e2a <procdump+0xe2>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104dda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ddd:	8b 40 1c             	mov    0x1c(%eax),%eax
80104de0:	8b 40 0c             	mov    0xc(%eax),%eax
80104de3:	83 c0 08             	add    $0x8,%eax
80104de6:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104de9:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ded:	89 04 24             	mov    %eax,(%esp)
80104df0:	e8 5c 01 00 00       	call   80104f51 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104df5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104dfc:	eb 1b                	jmp    80104e19 <procdump+0xd1>
        cprintf(" %p", pc[i]);
80104dfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e01:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e05:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e09:	c7 04 24 f9 87 10 80 	movl   $0x801087f9,(%esp)
80104e10:	e8 8b b5 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104e15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e19:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104e1d:	7f 0b                	jg     80104e2a <procdump+0xe2>
80104e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e22:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e26:	85 c0                	test   %eax,%eax
80104e28:	75 d4                	jne    80104dfe <procdump+0xb6>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104e2a:	c7 04 24 fd 87 10 80 	movl   $0x801087fd,(%esp)
80104e31:	e8 6a b5 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e36:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104e3a:	81 7d f0 94 48 11 80 	cmpl   $0x80114894,-0x10(%ebp)
80104e41:	0f 82 13 ff ff ff    	jb     80104d5a <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104e47:	c9                   	leave  
80104e48:	c3                   	ret    

80104e49 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104e49:	55                   	push   %ebp
80104e4a:	89 e5                	mov    %esp,%ebp
80104e4c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104e4f:	9c                   	pushf  
80104e50:	58                   	pop    %eax
80104e51:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104e54:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104e57:	c9                   	leave  
80104e58:	c3                   	ret    

80104e59 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104e59:	55                   	push   %ebp
80104e5a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104e5c:	fa                   	cli    
}
80104e5d:	5d                   	pop    %ebp
80104e5e:	c3                   	ret    

80104e5f <sti>:

static inline void
sti(void)
{
80104e5f:	55                   	push   %ebp
80104e60:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104e62:	fb                   	sti    
}
80104e63:	5d                   	pop    %ebp
80104e64:	c3                   	ret    

80104e65 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104e65:	55                   	push   %ebp
80104e66:	89 e5                	mov    %esp,%ebp
80104e68:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104e6b:	8b 55 08             	mov    0x8(%ebp),%edx
80104e6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e71:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e74:	f0 87 02             	lock xchg %eax,(%edx)
80104e77:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104e7a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104e7d:	c9                   	leave  
80104e7e:	c3                   	ret    

80104e7f <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104e7f:	55                   	push   %ebp
80104e80:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104e82:	8b 45 08             	mov    0x8(%ebp),%eax
80104e85:	8b 55 0c             	mov    0xc(%ebp),%edx
80104e88:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e8e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104e94:	8b 45 08             	mov    0x8(%ebp),%eax
80104e97:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104e9e:	5d                   	pop    %ebp
80104e9f:	c3                   	ret    

80104ea0 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104ea0:	55                   	push   %ebp
80104ea1:	89 e5                	mov    %esp,%ebp
80104ea3:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104ea6:	e8 49 01 00 00       	call   80104ff4 <pushcli>
  if(holding(lk))
80104eab:	8b 45 08             	mov    0x8(%ebp),%eax
80104eae:	89 04 24             	mov    %eax,(%esp)
80104eb1:	e8 14 01 00 00       	call   80104fca <holding>
80104eb6:	85 c0                	test   %eax,%eax
80104eb8:	74 0c                	je     80104ec6 <acquire+0x26>
    panic("acquire");
80104eba:	c7 04 24 29 88 10 80 	movl   $0x80108829,(%esp)
80104ec1:	e8 74 b6 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104ec6:	90                   	nop
80104ec7:	8b 45 08             	mov    0x8(%ebp),%eax
80104eca:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104ed1:	00 
80104ed2:	89 04 24             	mov    %eax,(%esp)
80104ed5:	e8 8b ff ff ff       	call   80104e65 <xchg>
80104eda:	85 c0                	test   %eax,%eax
80104edc:	75 e9                	jne    80104ec7 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104ede:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104ee8:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80104eee:	83 c0 0c             	add    $0xc,%eax
80104ef1:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ef5:	8d 45 08             	lea    0x8(%ebp),%eax
80104ef8:	89 04 24             	mov    %eax,(%esp)
80104efb:	e8 51 00 00 00       	call   80104f51 <getcallerpcs>
}
80104f00:	c9                   	leave  
80104f01:	c3                   	ret    

80104f02 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104f02:	55                   	push   %ebp
80104f03:	89 e5                	mov    %esp,%ebp
80104f05:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104f08:	8b 45 08             	mov    0x8(%ebp),%eax
80104f0b:	89 04 24             	mov    %eax,(%esp)
80104f0e:	e8 b7 00 00 00       	call   80104fca <holding>
80104f13:	85 c0                	test   %eax,%eax
80104f15:	75 0c                	jne    80104f23 <release+0x21>
    panic("release");
80104f17:	c7 04 24 31 88 10 80 	movl   $0x80108831,(%esp)
80104f1e:	e8 17 b6 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80104f23:	8b 45 08             	mov    0x8(%ebp),%eax
80104f26:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80104f30:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104f37:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104f41:	00 
80104f42:	89 04 24             	mov    %eax,(%esp)
80104f45:	e8 1b ff ff ff       	call   80104e65 <xchg>

  popcli();
80104f4a:	e8 e9 00 00 00       	call   80105038 <popcli>
}
80104f4f:	c9                   	leave  
80104f50:	c3                   	ret    

80104f51 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104f51:	55                   	push   %ebp
80104f52:	89 e5                	mov    %esp,%ebp
80104f54:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104f57:	8b 45 08             	mov    0x8(%ebp),%eax
80104f5a:	83 e8 08             	sub    $0x8,%eax
80104f5d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104f60:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104f67:	eb 38                	jmp    80104fa1 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104f69:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104f6d:	74 38                	je     80104fa7 <getcallerpcs+0x56>
80104f6f:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104f76:	76 2f                	jbe    80104fa7 <getcallerpcs+0x56>
80104f78:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104f7c:	74 29                	je     80104fa7 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104f7e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f81:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104f88:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f8b:	01 c2                	add    %eax,%edx
80104f8d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f90:	8b 40 04             	mov    0x4(%eax),%eax
80104f93:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80104f95:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f98:	8b 00                	mov    (%eax),%eax
80104f9a:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104f9d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104fa1:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104fa5:	7e c2                	jle    80104f69 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104fa7:	eb 19                	jmp    80104fc2 <getcallerpcs+0x71>
    pcs[i] = 0;
80104fa9:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fac:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80104fb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb6:	01 d0                	add    %edx,%eax
80104fb8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104fbe:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104fc2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104fc6:	7e e1                	jle    80104fa9 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80104fc8:	c9                   	leave  
80104fc9:	c3                   	ret    

80104fca <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104fca:	55                   	push   %ebp
80104fcb:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd0:	8b 00                	mov    (%eax),%eax
80104fd2:	85 c0                	test   %eax,%eax
80104fd4:	74 17                	je     80104fed <holding+0x23>
80104fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd9:	8b 50 08             	mov    0x8(%eax),%edx
80104fdc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104fe2:	39 c2                	cmp    %eax,%edx
80104fe4:	75 07                	jne    80104fed <holding+0x23>
80104fe6:	b8 01 00 00 00       	mov    $0x1,%eax
80104feb:	eb 05                	jmp    80104ff2 <holding+0x28>
80104fed:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ff2:	5d                   	pop    %ebp
80104ff3:	c3                   	ret    

80104ff4 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104ff4:	55                   	push   %ebp
80104ff5:	89 e5                	mov    %esp,%ebp
80104ff7:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104ffa:	e8 4a fe ff ff       	call   80104e49 <readeflags>
80104fff:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105002:	e8 52 fe ff ff       	call   80104e59 <cli>
  if(cpu->ncli++ == 0)
80105007:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010500e:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105014:	8d 48 01             	lea    0x1(%eax),%ecx
80105017:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
8010501d:	85 c0                	test   %eax,%eax
8010501f:	75 15                	jne    80105036 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105021:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105027:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010502a:	81 e2 00 02 00 00    	and    $0x200,%edx
80105030:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105036:	c9                   	leave  
80105037:	c3                   	ret    

80105038 <popcli>:

void
popcli(void)
{
80105038:	55                   	push   %ebp
80105039:	89 e5                	mov    %esp,%ebp
8010503b:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010503e:	e8 06 fe ff ff       	call   80104e49 <readeflags>
80105043:	25 00 02 00 00       	and    $0x200,%eax
80105048:	85 c0                	test   %eax,%eax
8010504a:	74 0c                	je     80105058 <popcli+0x20>
    panic("popcli - interruptible");
8010504c:	c7 04 24 39 88 10 80 	movl   $0x80108839,(%esp)
80105053:	e8 e2 b4 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105058:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010505e:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105064:	83 ea 01             	sub    $0x1,%edx
80105067:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010506d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105073:	85 c0                	test   %eax,%eax
80105075:	79 0c                	jns    80105083 <popcli+0x4b>
    panic("popcli");
80105077:	c7 04 24 50 88 10 80 	movl   $0x80108850,(%esp)
8010507e:	e8 b7 b4 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105083:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105089:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010508f:	85 c0                	test   %eax,%eax
80105091:	75 15                	jne    801050a8 <popcli+0x70>
80105093:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105099:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010509f:	85 c0                	test   %eax,%eax
801050a1:	74 05                	je     801050a8 <popcli+0x70>
    sti();
801050a3:	e8 b7 fd ff ff       	call   80104e5f <sti>
}
801050a8:	c9                   	leave  
801050a9:	c3                   	ret    

801050aa <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801050aa:	55                   	push   %ebp
801050ab:	89 e5                	mov    %esp,%ebp
801050ad:	57                   	push   %edi
801050ae:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801050af:	8b 4d 08             	mov    0x8(%ebp),%ecx
801050b2:	8b 55 10             	mov    0x10(%ebp),%edx
801050b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801050b8:	89 cb                	mov    %ecx,%ebx
801050ba:	89 df                	mov    %ebx,%edi
801050bc:	89 d1                	mov    %edx,%ecx
801050be:	fc                   	cld    
801050bf:	f3 aa                	rep stos %al,%es:(%edi)
801050c1:	89 ca                	mov    %ecx,%edx
801050c3:	89 fb                	mov    %edi,%ebx
801050c5:	89 5d 08             	mov    %ebx,0x8(%ebp)
801050c8:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801050cb:	5b                   	pop    %ebx
801050cc:	5f                   	pop    %edi
801050cd:	5d                   	pop    %ebp
801050ce:	c3                   	ret    

801050cf <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801050cf:	55                   	push   %ebp
801050d0:	89 e5                	mov    %esp,%ebp
801050d2:	57                   	push   %edi
801050d3:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801050d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
801050d7:	8b 55 10             	mov    0x10(%ebp),%edx
801050da:	8b 45 0c             	mov    0xc(%ebp),%eax
801050dd:	89 cb                	mov    %ecx,%ebx
801050df:	89 df                	mov    %ebx,%edi
801050e1:	89 d1                	mov    %edx,%ecx
801050e3:	fc                   	cld    
801050e4:	f3 ab                	rep stos %eax,%es:(%edi)
801050e6:	89 ca                	mov    %ecx,%edx
801050e8:	89 fb                	mov    %edi,%ebx
801050ea:	89 5d 08             	mov    %ebx,0x8(%ebp)
801050ed:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801050f0:	5b                   	pop    %ebx
801050f1:	5f                   	pop    %edi
801050f2:	5d                   	pop    %ebp
801050f3:	c3                   	ret    

801050f4 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801050f4:	55                   	push   %ebp
801050f5:	89 e5                	mov    %esp,%ebp
801050f7:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801050fa:	8b 45 08             	mov    0x8(%ebp),%eax
801050fd:	83 e0 03             	and    $0x3,%eax
80105100:	85 c0                	test   %eax,%eax
80105102:	75 49                	jne    8010514d <memset+0x59>
80105104:	8b 45 10             	mov    0x10(%ebp),%eax
80105107:	83 e0 03             	and    $0x3,%eax
8010510a:	85 c0                	test   %eax,%eax
8010510c:	75 3f                	jne    8010514d <memset+0x59>
    c &= 0xFF;
8010510e:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105115:	8b 45 10             	mov    0x10(%ebp),%eax
80105118:	c1 e8 02             	shr    $0x2,%eax
8010511b:	89 c2                	mov    %eax,%edx
8010511d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105120:	c1 e0 18             	shl    $0x18,%eax
80105123:	89 c1                	mov    %eax,%ecx
80105125:	8b 45 0c             	mov    0xc(%ebp),%eax
80105128:	c1 e0 10             	shl    $0x10,%eax
8010512b:	09 c1                	or     %eax,%ecx
8010512d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105130:	c1 e0 08             	shl    $0x8,%eax
80105133:	09 c8                	or     %ecx,%eax
80105135:	0b 45 0c             	or     0xc(%ebp),%eax
80105138:	89 54 24 08          	mov    %edx,0x8(%esp)
8010513c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105140:	8b 45 08             	mov    0x8(%ebp),%eax
80105143:	89 04 24             	mov    %eax,(%esp)
80105146:	e8 84 ff ff ff       	call   801050cf <stosl>
8010514b:	eb 19                	jmp    80105166 <memset+0x72>
  } else
    stosb(dst, c, n);
8010514d:	8b 45 10             	mov    0x10(%ebp),%eax
80105150:	89 44 24 08          	mov    %eax,0x8(%esp)
80105154:	8b 45 0c             	mov    0xc(%ebp),%eax
80105157:	89 44 24 04          	mov    %eax,0x4(%esp)
8010515b:	8b 45 08             	mov    0x8(%ebp),%eax
8010515e:	89 04 24             	mov    %eax,(%esp)
80105161:	e8 44 ff ff ff       	call   801050aa <stosb>
  return dst;
80105166:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105169:	c9                   	leave  
8010516a:	c3                   	ret    

8010516b <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010516b:	55                   	push   %ebp
8010516c:	89 e5                	mov    %esp,%ebp
8010516e:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105171:	8b 45 08             	mov    0x8(%ebp),%eax
80105174:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105177:	8b 45 0c             	mov    0xc(%ebp),%eax
8010517a:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010517d:	eb 30                	jmp    801051af <memcmp+0x44>
    if(*s1 != *s2)
8010517f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105182:	0f b6 10             	movzbl (%eax),%edx
80105185:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105188:	0f b6 00             	movzbl (%eax),%eax
8010518b:	38 c2                	cmp    %al,%dl
8010518d:	74 18                	je     801051a7 <memcmp+0x3c>
      return *s1 - *s2;
8010518f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105192:	0f b6 00             	movzbl (%eax),%eax
80105195:	0f b6 d0             	movzbl %al,%edx
80105198:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010519b:	0f b6 00             	movzbl (%eax),%eax
8010519e:	0f b6 c0             	movzbl %al,%eax
801051a1:	29 c2                	sub    %eax,%edx
801051a3:	89 d0                	mov    %edx,%eax
801051a5:	eb 1a                	jmp    801051c1 <memcmp+0x56>
    s1++, s2++;
801051a7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051ab:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801051af:	8b 45 10             	mov    0x10(%ebp),%eax
801051b2:	8d 50 ff             	lea    -0x1(%eax),%edx
801051b5:	89 55 10             	mov    %edx,0x10(%ebp)
801051b8:	85 c0                	test   %eax,%eax
801051ba:	75 c3                	jne    8010517f <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801051bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051c1:	c9                   	leave  
801051c2:	c3                   	ret    

801051c3 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801051c3:	55                   	push   %ebp
801051c4:	89 e5                	mov    %esp,%ebp
801051c6:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801051c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801051cc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801051cf:	8b 45 08             	mov    0x8(%ebp),%eax
801051d2:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801051d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801051db:	73 3d                	jae    8010521a <memmove+0x57>
801051dd:	8b 45 10             	mov    0x10(%ebp),%eax
801051e0:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051e3:	01 d0                	add    %edx,%eax
801051e5:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801051e8:	76 30                	jbe    8010521a <memmove+0x57>
    s += n;
801051ea:	8b 45 10             	mov    0x10(%ebp),%eax
801051ed:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801051f0:	8b 45 10             	mov    0x10(%ebp),%eax
801051f3:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801051f6:	eb 13                	jmp    8010520b <memmove+0x48>
      *--d = *--s;
801051f8:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801051fc:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105200:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105203:	0f b6 10             	movzbl (%eax),%edx
80105206:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105209:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
8010520b:	8b 45 10             	mov    0x10(%ebp),%eax
8010520e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105211:	89 55 10             	mov    %edx,0x10(%ebp)
80105214:	85 c0                	test   %eax,%eax
80105216:	75 e0                	jne    801051f8 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105218:	eb 26                	jmp    80105240 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010521a:	eb 17                	jmp    80105233 <memmove+0x70>
      *d++ = *s++;
8010521c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010521f:	8d 50 01             	lea    0x1(%eax),%edx
80105222:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105225:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105228:	8d 4a 01             	lea    0x1(%edx),%ecx
8010522b:	89 4d fc             	mov    %ecx,-0x4(%ebp)
8010522e:	0f b6 12             	movzbl (%edx),%edx
80105231:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105233:	8b 45 10             	mov    0x10(%ebp),%eax
80105236:	8d 50 ff             	lea    -0x1(%eax),%edx
80105239:	89 55 10             	mov    %edx,0x10(%ebp)
8010523c:	85 c0                	test   %eax,%eax
8010523e:	75 dc                	jne    8010521c <memmove+0x59>
      *d++ = *s++;

  return dst;
80105240:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105243:	c9                   	leave  
80105244:	c3                   	ret    

80105245 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105245:	55                   	push   %ebp
80105246:	89 e5                	mov    %esp,%ebp
80105248:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
8010524b:	8b 45 10             	mov    0x10(%ebp),%eax
8010524e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105252:	8b 45 0c             	mov    0xc(%ebp),%eax
80105255:	89 44 24 04          	mov    %eax,0x4(%esp)
80105259:	8b 45 08             	mov    0x8(%ebp),%eax
8010525c:	89 04 24             	mov    %eax,(%esp)
8010525f:	e8 5f ff ff ff       	call   801051c3 <memmove>
}
80105264:	c9                   	leave  
80105265:	c3                   	ret    

80105266 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105266:	55                   	push   %ebp
80105267:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105269:	eb 0c                	jmp    80105277 <strncmp+0x11>
    n--, p++, q++;
8010526b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010526f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105273:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105277:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010527b:	74 1a                	je     80105297 <strncmp+0x31>
8010527d:	8b 45 08             	mov    0x8(%ebp),%eax
80105280:	0f b6 00             	movzbl (%eax),%eax
80105283:	84 c0                	test   %al,%al
80105285:	74 10                	je     80105297 <strncmp+0x31>
80105287:	8b 45 08             	mov    0x8(%ebp),%eax
8010528a:	0f b6 10             	movzbl (%eax),%edx
8010528d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105290:	0f b6 00             	movzbl (%eax),%eax
80105293:	38 c2                	cmp    %al,%dl
80105295:	74 d4                	je     8010526b <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105297:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010529b:	75 07                	jne    801052a4 <strncmp+0x3e>
    return 0;
8010529d:	b8 00 00 00 00       	mov    $0x0,%eax
801052a2:	eb 16                	jmp    801052ba <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
801052a4:	8b 45 08             	mov    0x8(%ebp),%eax
801052a7:	0f b6 00             	movzbl (%eax),%eax
801052aa:	0f b6 d0             	movzbl %al,%edx
801052ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b0:	0f b6 00             	movzbl (%eax),%eax
801052b3:	0f b6 c0             	movzbl %al,%eax
801052b6:	29 c2                	sub    %eax,%edx
801052b8:	89 d0                	mov    %edx,%eax
}
801052ba:	5d                   	pop    %ebp
801052bb:	c3                   	ret    

801052bc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801052bc:	55                   	push   %ebp
801052bd:	89 e5                	mov    %esp,%ebp
801052bf:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801052c2:	8b 45 08             	mov    0x8(%ebp),%eax
801052c5:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801052c8:	90                   	nop
801052c9:	8b 45 10             	mov    0x10(%ebp),%eax
801052cc:	8d 50 ff             	lea    -0x1(%eax),%edx
801052cf:	89 55 10             	mov    %edx,0x10(%ebp)
801052d2:	85 c0                	test   %eax,%eax
801052d4:	7e 1e                	jle    801052f4 <strncpy+0x38>
801052d6:	8b 45 08             	mov    0x8(%ebp),%eax
801052d9:	8d 50 01             	lea    0x1(%eax),%edx
801052dc:	89 55 08             	mov    %edx,0x8(%ebp)
801052df:	8b 55 0c             	mov    0xc(%ebp),%edx
801052e2:	8d 4a 01             	lea    0x1(%edx),%ecx
801052e5:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801052e8:	0f b6 12             	movzbl (%edx),%edx
801052eb:	88 10                	mov    %dl,(%eax)
801052ed:	0f b6 00             	movzbl (%eax),%eax
801052f0:	84 c0                	test   %al,%al
801052f2:	75 d5                	jne    801052c9 <strncpy+0xd>
    ;
  while(n-- > 0)
801052f4:	eb 0c                	jmp    80105302 <strncpy+0x46>
    *s++ = 0;
801052f6:	8b 45 08             	mov    0x8(%ebp),%eax
801052f9:	8d 50 01             	lea    0x1(%eax),%edx
801052fc:	89 55 08             	mov    %edx,0x8(%ebp)
801052ff:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105302:	8b 45 10             	mov    0x10(%ebp),%eax
80105305:	8d 50 ff             	lea    -0x1(%eax),%edx
80105308:	89 55 10             	mov    %edx,0x10(%ebp)
8010530b:	85 c0                	test   %eax,%eax
8010530d:	7f e7                	jg     801052f6 <strncpy+0x3a>
    *s++ = 0;
  return os;
8010530f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105312:	c9                   	leave  
80105313:	c3                   	ret    

80105314 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105314:	55                   	push   %ebp
80105315:	89 e5                	mov    %esp,%ebp
80105317:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010531a:	8b 45 08             	mov    0x8(%ebp),%eax
8010531d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105320:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105324:	7f 05                	jg     8010532b <safestrcpy+0x17>
    return os;
80105326:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105329:	eb 31                	jmp    8010535c <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
8010532b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010532f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105333:	7e 1e                	jle    80105353 <safestrcpy+0x3f>
80105335:	8b 45 08             	mov    0x8(%ebp),%eax
80105338:	8d 50 01             	lea    0x1(%eax),%edx
8010533b:	89 55 08             	mov    %edx,0x8(%ebp)
8010533e:	8b 55 0c             	mov    0xc(%ebp),%edx
80105341:	8d 4a 01             	lea    0x1(%edx),%ecx
80105344:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105347:	0f b6 12             	movzbl (%edx),%edx
8010534a:	88 10                	mov    %dl,(%eax)
8010534c:	0f b6 00             	movzbl (%eax),%eax
8010534f:	84 c0                	test   %al,%al
80105351:	75 d8                	jne    8010532b <safestrcpy+0x17>
    ;
  *s = 0;
80105353:	8b 45 08             	mov    0x8(%ebp),%eax
80105356:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105359:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010535c:	c9                   	leave  
8010535d:	c3                   	ret    

8010535e <strlen>:

int
strlen(const char *s)
{
8010535e:	55                   	push   %ebp
8010535f:	89 e5                	mov    %esp,%ebp
80105361:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105364:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010536b:	eb 04                	jmp    80105371 <strlen+0x13>
8010536d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105371:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105374:	8b 45 08             	mov    0x8(%ebp),%eax
80105377:	01 d0                	add    %edx,%eax
80105379:	0f b6 00             	movzbl (%eax),%eax
8010537c:	84 c0                	test   %al,%al
8010537e:	75 ed                	jne    8010536d <strlen+0xf>
    ;
  return n;
80105380:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105383:	c9                   	leave  
80105384:	c3                   	ret    

80105385 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105385:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105389:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010538d:	55                   	push   %ebp
  pushl %ebx
8010538e:	53                   	push   %ebx
  pushl %esi
8010538f:	56                   	push   %esi
  pushl %edi
80105390:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105391:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105393:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105395:	5f                   	pop    %edi
  popl %esi
80105396:	5e                   	pop    %esi
  popl %ebx
80105397:	5b                   	pop    %ebx
  popl %ebp
80105398:	5d                   	pop    %ebp
  ret
80105399:	c3                   	ret    

8010539a <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010539a:	55                   	push   %ebp
8010539b:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
8010539d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053a3:	8b 00                	mov    (%eax),%eax
801053a5:	3b 45 08             	cmp    0x8(%ebp),%eax
801053a8:	76 12                	jbe    801053bc <fetchint+0x22>
801053aa:	8b 45 08             	mov    0x8(%ebp),%eax
801053ad:	8d 50 04             	lea    0x4(%eax),%edx
801053b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053b6:	8b 00                	mov    (%eax),%eax
801053b8:	39 c2                	cmp    %eax,%edx
801053ba:	76 07                	jbe    801053c3 <fetchint+0x29>
    return -1;
801053bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053c1:	eb 0f                	jmp    801053d2 <fetchint+0x38>
  *ip = *(int*)(addr);
801053c3:	8b 45 08             	mov    0x8(%ebp),%eax
801053c6:	8b 10                	mov    (%eax),%edx
801053c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801053cb:	89 10                	mov    %edx,(%eax)
  return 0;
801053cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801053d2:	5d                   	pop    %ebp
801053d3:	c3                   	ret    

801053d4 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801053d4:	55                   	push   %ebp
801053d5:	89 e5                	mov    %esp,%ebp
801053d7:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
801053da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053e0:	8b 00                	mov    (%eax),%eax
801053e2:	3b 45 08             	cmp    0x8(%ebp),%eax
801053e5:	77 07                	ja     801053ee <fetchstr+0x1a>
    return -1;
801053e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053ec:	eb 46                	jmp    80105434 <fetchstr+0x60>
  *pp = (char*)addr;
801053ee:	8b 55 08             	mov    0x8(%ebp),%edx
801053f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801053f4:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
801053f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053fc:	8b 00                	mov    (%eax),%eax
801053fe:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105401:	8b 45 0c             	mov    0xc(%ebp),%eax
80105404:	8b 00                	mov    (%eax),%eax
80105406:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105409:	eb 1c                	jmp    80105427 <fetchstr+0x53>
    if(*s == 0)
8010540b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010540e:	0f b6 00             	movzbl (%eax),%eax
80105411:	84 c0                	test   %al,%al
80105413:	75 0e                	jne    80105423 <fetchstr+0x4f>
      return s - *pp;
80105415:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105418:	8b 45 0c             	mov    0xc(%ebp),%eax
8010541b:	8b 00                	mov    (%eax),%eax
8010541d:	29 c2                	sub    %eax,%edx
8010541f:	89 d0                	mov    %edx,%eax
80105421:	eb 11                	jmp    80105434 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105423:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105427:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010542a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010542d:	72 dc                	jb     8010540b <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
8010542f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105434:	c9                   	leave  
80105435:	c3                   	ret    

80105436 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105436:	55                   	push   %ebp
80105437:	89 e5                	mov    %esp,%ebp
80105439:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
8010543c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105442:	8b 40 18             	mov    0x18(%eax),%eax
80105445:	8b 50 44             	mov    0x44(%eax),%edx
80105448:	8b 45 08             	mov    0x8(%ebp),%eax
8010544b:	c1 e0 02             	shl    $0x2,%eax
8010544e:	01 d0                	add    %edx,%eax
80105450:	8d 50 04             	lea    0x4(%eax),%edx
80105453:	8b 45 0c             	mov    0xc(%ebp),%eax
80105456:	89 44 24 04          	mov    %eax,0x4(%esp)
8010545a:	89 14 24             	mov    %edx,(%esp)
8010545d:	e8 38 ff ff ff       	call   8010539a <fetchint>
}
80105462:	c9                   	leave  
80105463:	c3                   	ret    

80105464 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105464:	55                   	push   %ebp
80105465:	89 e5                	mov    %esp,%ebp
80105467:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
8010546a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010546d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105471:	8b 45 08             	mov    0x8(%ebp),%eax
80105474:	89 04 24             	mov    %eax,(%esp)
80105477:	e8 ba ff ff ff       	call   80105436 <argint>
8010547c:	85 c0                	test   %eax,%eax
8010547e:	79 07                	jns    80105487 <argptr+0x23>
    return -1;
80105480:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105485:	eb 3d                	jmp    801054c4 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105487:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010548a:	89 c2                	mov    %eax,%edx
8010548c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105492:	8b 00                	mov    (%eax),%eax
80105494:	39 c2                	cmp    %eax,%edx
80105496:	73 16                	jae    801054ae <argptr+0x4a>
80105498:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010549b:	89 c2                	mov    %eax,%edx
8010549d:	8b 45 10             	mov    0x10(%ebp),%eax
801054a0:	01 c2                	add    %eax,%edx
801054a2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054a8:	8b 00                	mov    (%eax),%eax
801054aa:	39 c2                	cmp    %eax,%edx
801054ac:	76 07                	jbe    801054b5 <argptr+0x51>
    return -1;
801054ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054b3:	eb 0f                	jmp    801054c4 <argptr+0x60>
  *pp = (char*)i;
801054b5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054b8:	89 c2                	mov    %eax,%edx
801054ba:	8b 45 0c             	mov    0xc(%ebp),%eax
801054bd:	89 10                	mov    %edx,(%eax)
  return 0;
801054bf:	b8 00 00 00 00       	mov    $0x0,%eax
}
801054c4:	c9                   	leave  
801054c5:	c3                   	ret    

801054c6 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801054c6:	55                   	push   %ebp
801054c7:	89 e5                	mov    %esp,%ebp
801054c9:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
801054cc:	8d 45 fc             	lea    -0x4(%ebp),%eax
801054cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801054d3:	8b 45 08             	mov    0x8(%ebp),%eax
801054d6:	89 04 24             	mov    %eax,(%esp)
801054d9:	e8 58 ff ff ff       	call   80105436 <argint>
801054de:	85 c0                	test   %eax,%eax
801054e0:	79 07                	jns    801054e9 <argstr+0x23>
    return -1;
801054e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054e7:	eb 12                	jmp    801054fb <argstr+0x35>
  return fetchstr(addr, pp);
801054e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054ec:	8b 55 0c             	mov    0xc(%ebp),%edx
801054ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801054f3:	89 04 24             	mov    %eax,(%esp)
801054f6:	e8 d9 fe ff ff       	call   801053d4 <fetchstr>
}
801054fb:	c9                   	leave  
801054fc:	c3                   	ret    

801054fd <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801054fd:	55                   	push   %ebp
801054fe:	89 e5                	mov    %esp,%ebp
80105500:	53                   	push   %ebx
80105501:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105504:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550a:	8b 40 18             	mov    0x18(%eax),%eax
8010550d:	8b 40 1c             	mov    0x1c(%eax),%eax
80105510:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105513:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105517:	7e 30                	jle    80105549 <syscall+0x4c>
80105519:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010551c:	83 f8 15             	cmp    $0x15,%eax
8010551f:	77 28                	ja     80105549 <syscall+0x4c>
80105521:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105524:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010552b:	85 c0                	test   %eax,%eax
8010552d:	74 1a                	je     80105549 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
8010552f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105535:	8b 58 18             	mov    0x18(%eax),%ebx
80105538:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010553b:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105542:	ff d0                	call   *%eax
80105544:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105547:	eb 3d                	jmp    80105586 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105549:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010554f:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105552:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105558:	8b 40 10             	mov    0x10(%eax),%eax
8010555b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010555e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105562:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105566:	89 44 24 04          	mov    %eax,0x4(%esp)
8010556a:	c7 04 24 57 88 10 80 	movl   $0x80108857,(%esp)
80105571:	e8 2a ae ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105576:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010557c:	8b 40 18             	mov    0x18(%eax),%eax
8010557f:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105586:	83 c4 24             	add    $0x24,%esp
80105589:	5b                   	pop    %ebx
8010558a:	5d                   	pop    %ebp
8010558b:	c3                   	ret    

8010558c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010558c:	55                   	push   %ebp
8010558d:	89 e5                	mov    %esp,%ebp
8010558f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105592:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105595:	89 44 24 04          	mov    %eax,0x4(%esp)
80105599:	8b 45 08             	mov    0x8(%ebp),%eax
8010559c:	89 04 24             	mov    %eax,(%esp)
8010559f:	e8 92 fe ff ff       	call   80105436 <argint>
801055a4:	85 c0                	test   %eax,%eax
801055a6:	79 07                	jns    801055af <argfd+0x23>
    return -1;
801055a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055ad:	eb 50                	jmp    801055ff <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801055af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055b2:	85 c0                	test   %eax,%eax
801055b4:	78 21                	js     801055d7 <argfd+0x4b>
801055b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055b9:	83 f8 0f             	cmp    $0xf,%eax
801055bc:	7f 19                	jg     801055d7 <argfd+0x4b>
801055be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801055c7:	83 c2 08             	add    $0x8,%edx
801055ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801055ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
801055d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801055d5:	75 07                	jne    801055de <argfd+0x52>
    return -1;
801055d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055dc:	eb 21                	jmp    801055ff <argfd+0x73>
  if(pfd)
801055de:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801055e2:	74 08                	je     801055ec <argfd+0x60>
    *pfd = fd;
801055e4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801055e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801055ea:	89 10                	mov    %edx,(%eax)
  if(pf)
801055ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055f0:	74 08                	je     801055fa <argfd+0x6e>
    *pf = f;
801055f2:	8b 45 10             	mov    0x10(%ebp),%eax
801055f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055f8:	89 10                	mov    %edx,(%eax)
  return 0;
801055fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055ff:	c9                   	leave  
80105600:	c3                   	ret    

80105601 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105601:	55                   	push   %ebp
80105602:	89 e5                	mov    %esp,%ebp
80105604:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105607:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010560e:	eb 30                	jmp    80105640 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105610:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105616:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105619:	83 c2 08             	add    $0x8,%edx
8010561c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105620:	85 c0                	test   %eax,%eax
80105622:	75 18                	jne    8010563c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105624:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010562a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010562d:	8d 4a 08             	lea    0x8(%edx),%ecx
80105630:	8b 55 08             	mov    0x8(%ebp),%edx
80105633:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105637:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010563a:	eb 0f                	jmp    8010564b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010563c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105640:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105644:	7e ca                	jle    80105610 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105646:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010564b:	c9                   	leave  
8010564c:	c3                   	ret    

8010564d <sys_dup>:

int
sys_dup(void)
{
8010564d:	55                   	push   %ebp
8010564e:	89 e5                	mov    %esp,%ebp
80105650:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105653:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105656:	89 44 24 08          	mov    %eax,0x8(%esp)
8010565a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105661:	00 
80105662:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105669:	e8 1e ff ff ff       	call   8010558c <argfd>
8010566e:	85 c0                	test   %eax,%eax
80105670:	79 07                	jns    80105679 <sys_dup+0x2c>
    return -1;
80105672:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105677:	eb 29                	jmp    801056a2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105679:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010567c:	89 04 24             	mov    %eax,(%esp)
8010567f:	e8 7d ff ff ff       	call   80105601 <fdalloc>
80105684:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105687:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010568b:	79 07                	jns    80105694 <sys_dup+0x47>
    return -1;
8010568d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105692:	eb 0e                	jmp    801056a2 <sys_dup+0x55>
  filedup(f);
80105694:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105697:	89 04 24             	mov    %eax,(%esp)
8010569a:	e8 e7 b8 ff ff       	call   80100f86 <filedup>
  return fd;
8010569f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801056a2:	c9                   	leave  
801056a3:	c3                   	ret    

801056a4 <sys_read>:

int
sys_read(void)
{
801056a4:	55                   	push   %ebp
801056a5:	89 e5                	mov    %esp,%ebp
801056a7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801056aa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801056ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801056b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801056b8:	00 
801056b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801056c0:	e8 c7 fe ff ff       	call   8010558c <argfd>
801056c5:	85 c0                	test   %eax,%eax
801056c7:	78 35                	js     801056fe <sys_read+0x5a>
801056c9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801056d7:	e8 5a fd ff ff       	call   80105436 <argint>
801056dc:	85 c0                	test   %eax,%eax
801056de:	78 1e                	js     801056fe <sys_read+0x5a>
801056e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056e3:	89 44 24 08          	mov    %eax,0x8(%esp)
801056e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801056ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801056ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801056f5:	e8 6a fd ff ff       	call   80105464 <argptr>
801056fa:	85 c0                	test   %eax,%eax
801056fc:	79 07                	jns    80105705 <sys_read+0x61>
    return -1;
801056fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105703:	eb 19                	jmp    8010571e <sys_read+0x7a>
  return fileread(f, p, n);
80105705:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105708:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010570b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010570e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105712:	89 54 24 04          	mov    %edx,0x4(%esp)
80105716:	89 04 24             	mov    %eax,(%esp)
80105719:	e8 d5 b9 ff ff       	call   801010f3 <fileread>
}
8010571e:	c9                   	leave  
8010571f:	c3                   	ret    

80105720 <sys_write>:

int
sys_write(void)
{
80105720:	55                   	push   %ebp
80105721:	89 e5                	mov    %esp,%ebp
80105723:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105726:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105729:	89 44 24 08          	mov    %eax,0x8(%esp)
8010572d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105734:	00 
80105735:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010573c:	e8 4b fe ff ff       	call   8010558c <argfd>
80105741:	85 c0                	test   %eax,%eax
80105743:	78 35                	js     8010577a <sys_write+0x5a>
80105745:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010574c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105753:	e8 de fc ff ff       	call   80105436 <argint>
80105758:	85 c0                	test   %eax,%eax
8010575a:	78 1e                	js     8010577a <sys_write+0x5a>
8010575c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010575f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105763:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105766:	89 44 24 04          	mov    %eax,0x4(%esp)
8010576a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105771:	e8 ee fc ff ff       	call   80105464 <argptr>
80105776:	85 c0                	test   %eax,%eax
80105778:	79 07                	jns    80105781 <sys_write+0x61>
    return -1;
8010577a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010577f:	eb 19                	jmp    8010579a <sys_write+0x7a>
  return filewrite(f, p, n);
80105781:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105784:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105787:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010578a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010578e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105792:	89 04 24             	mov    %eax,(%esp)
80105795:	e8 15 ba ff ff       	call   801011af <filewrite>
}
8010579a:	c9                   	leave  
8010579b:	c3                   	ret    

8010579c <sys_close>:

int
sys_close(void)
{
8010579c:	55                   	push   %ebp
8010579d:	89 e5                	mov    %esp,%ebp
8010579f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801057a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801057a9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801057b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057b7:	e8 d0 fd ff ff       	call   8010558c <argfd>
801057bc:	85 c0                	test   %eax,%eax
801057be:	79 07                	jns    801057c7 <sys_close+0x2b>
    return -1;
801057c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057c5:	eb 24                	jmp    801057eb <sys_close+0x4f>
  proc->ofile[fd] = 0;
801057c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057d0:	83 c2 08             	add    $0x8,%edx
801057d3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801057da:	00 
  fileclose(f);
801057db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057de:	89 04 24             	mov    %eax,(%esp)
801057e1:	e8 e8 b7 ff ff       	call   80100fce <fileclose>
  return 0;
801057e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801057eb:	c9                   	leave  
801057ec:	c3                   	ret    

801057ed <sys_fstat>:

int
sys_fstat(void)
{
801057ed:	55                   	push   %ebp
801057ee:	89 e5                	mov    %esp,%ebp
801057f0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801057f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801057fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105801:	00 
80105802:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105809:	e8 7e fd ff ff       	call   8010558c <argfd>
8010580e:	85 c0                	test   %eax,%eax
80105810:	78 1f                	js     80105831 <sys_fstat+0x44>
80105812:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105819:	00 
8010581a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010581d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105821:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105828:	e8 37 fc ff ff       	call   80105464 <argptr>
8010582d:	85 c0                	test   %eax,%eax
8010582f:	79 07                	jns    80105838 <sys_fstat+0x4b>
    return -1;
80105831:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105836:	eb 12                	jmp    8010584a <sys_fstat+0x5d>
  return filestat(f, st);
80105838:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010583b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010583e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105842:	89 04 24             	mov    %eax,(%esp)
80105845:	e8 5a b8 ff ff       	call   801010a4 <filestat>
}
8010584a:	c9                   	leave  
8010584b:	c3                   	ret    

8010584c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010584c:	55                   	push   %ebp
8010584d:	89 e5                	mov    %esp,%ebp
8010584f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105852:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105855:	89 44 24 04          	mov    %eax,0x4(%esp)
80105859:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105860:	e8 61 fc ff ff       	call   801054c6 <argstr>
80105865:	85 c0                	test   %eax,%eax
80105867:	78 17                	js     80105880 <sys_link+0x34>
80105869:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010586c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105870:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105877:	e8 4a fc ff ff       	call   801054c6 <argstr>
8010587c:	85 c0                	test   %eax,%eax
8010587e:	79 0a                	jns    8010588a <sys_link+0x3e>
    return -1;
80105880:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105885:	e9 42 01 00 00       	jmp    801059cc <sys_link+0x180>

  begin_op();
8010588a:	e8 81 db ff ff       	call   80103410 <begin_op>
  if((ip = namei(old)) == 0){
8010588f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105892:	89 04 24             	mov    %eax,(%esp)
80105895:	e8 6c cb ff ff       	call   80102406 <namei>
8010589a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010589d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801058a1:	75 0f                	jne    801058b2 <sys_link+0x66>
    end_op();
801058a3:	e8 ec db ff ff       	call   80103494 <end_op>
    return -1;
801058a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058ad:	e9 1a 01 00 00       	jmp    801059cc <sys_link+0x180>
  }

  ilock(ip);
801058b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b5:	89 04 24             	mov    %eax,(%esp)
801058b8:	e8 9e bf ff ff       	call   8010185b <ilock>
  if(ip->type == T_DIR){
801058bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058c0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801058c4:	66 83 f8 01          	cmp    $0x1,%ax
801058c8:	75 1a                	jne    801058e4 <sys_link+0x98>
    iunlockput(ip);
801058ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058cd:	89 04 24             	mov    %eax,(%esp)
801058d0:	e8 0a c2 ff ff       	call   80101adf <iunlockput>
    end_op();
801058d5:	e8 ba db ff ff       	call   80103494 <end_op>
    return -1;
801058da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058df:	e9 e8 00 00 00       	jmp    801059cc <sys_link+0x180>
  }

  ip->nlink++;
801058e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801058eb:	8d 50 01             	lea    0x1(%eax),%edx
801058ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f1:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801058f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f8:	89 04 24             	mov    %eax,(%esp)
801058fb:	e8 9f bd ff ff       	call   8010169f <iupdate>
  iunlock(ip);
80105900:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105903:	89 04 24             	mov    %eax,(%esp)
80105906:	e8 9e c0 ff ff       	call   801019a9 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010590b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010590e:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105911:	89 54 24 04          	mov    %edx,0x4(%esp)
80105915:	89 04 24             	mov    %eax,(%esp)
80105918:	e8 0b cb ff ff       	call   80102428 <nameiparent>
8010591d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105920:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105924:	75 02                	jne    80105928 <sys_link+0xdc>
    goto bad;
80105926:	eb 68                	jmp    80105990 <sys_link+0x144>
  ilock(dp);
80105928:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010592b:	89 04 24             	mov    %eax,(%esp)
8010592e:	e8 28 bf ff ff       	call   8010185b <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105936:	8b 10                	mov    (%eax),%edx
80105938:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010593b:	8b 00                	mov    (%eax),%eax
8010593d:	39 c2                	cmp    %eax,%edx
8010593f:	75 20                	jne    80105961 <sys_link+0x115>
80105941:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105944:	8b 40 04             	mov    0x4(%eax),%eax
80105947:	89 44 24 08          	mov    %eax,0x8(%esp)
8010594b:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010594e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105952:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105955:	89 04 24             	mov    %eax,(%esp)
80105958:	e8 e9 c7 ff ff       	call   80102146 <dirlink>
8010595d:	85 c0                	test   %eax,%eax
8010595f:	79 0d                	jns    8010596e <sys_link+0x122>
    iunlockput(dp);
80105961:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105964:	89 04 24             	mov    %eax,(%esp)
80105967:	e8 73 c1 ff ff       	call   80101adf <iunlockput>
    goto bad;
8010596c:	eb 22                	jmp    80105990 <sys_link+0x144>
  }
  iunlockput(dp);
8010596e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105971:	89 04 24             	mov    %eax,(%esp)
80105974:	e8 66 c1 ff ff       	call   80101adf <iunlockput>
  iput(ip);
80105979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010597c:	89 04 24             	mov    %eax,(%esp)
8010597f:	e8 8a c0 ff ff       	call   80101a0e <iput>

  end_op();
80105984:	e8 0b db ff ff       	call   80103494 <end_op>

  return 0;
80105989:	b8 00 00 00 00       	mov    $0x0,%eax
8010598e:	eb 3c                	jmp    801059cc <sys_link+0x180>

bad:
  ilock(ip);
80105990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105993:	89 04 24             	mov    %eax,(%esp)
80105996:	e8 c0 be ff ff       	call   8010185b <ilock>
  ip->nlink--;
8010599b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059a2:	8d 50 ff             	lea    -0x1(%eax),%edx
801059a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059a8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801059ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059af:	89 04 24             	mov    %eax,(%esp)
801059b2:	e8 e8 bc ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
801059b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ba:	89 04 24             	mov    %eax,(%esp)
801059bd:	e8 1d c1 ff ff       	call   80101adf <iunlockput>
  end_op();
801059c2:	e8 cd da ff ff       	call   80103494 <end_op>
  return -1;
801059c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801059cc:	c9                   	leave  
801059cd:	c3                   	ret    

801059ce <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801059ce:	55                   	push   %ebp
801059cf:	89 e5                	mov    %esp,%ebp
801059d1:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801059d4:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801059db:	eb 4b                	jmp    80105a28 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801059dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059e0:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801059e7:	00 
801059e8:	89 44 24 08          	mov    %eax,0x8(%esp)
801059ec:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801059ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801059f3:	8b 45 08             	mov    0x8(%ebp),%eax
801059f6:	89 04 24             	mov    %eax,(%esp)
801059f9:	e8 6a c3 ff ff       	call   80101d68 <readi>
801059fe:	83 f8 10             	cmp    $0x10,%eax
80105a01:	74 0c                	je     80105a0f <isdirempty+0x41>
      panic("isdirempty: readi");
80105a03:	c7 04 24 73 88 10 80 	movl   $0x80108873,(%esp)
80105a0a:	e8 2b ab ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105a0f:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105a13:	66 85 c0             	test   %ax,%ax
80105a16:	74 07                	je     80105a1f <isdirempty+0x51>
      return 0;
80105a18:	b8 00 00 00 00       	mov    $0x0,%eax
80105a1d:	eb 1b                	jmp    80105a3a <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a22:	83 c0 10             	add    $0x10,%eax
80105a25:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a28:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a2e:	8b 40 18             	mov    0x18(%eax),%eax
80105a31:	39 c2                	cmp    %eax,%edx
80105a33:	72 a8                	jb     801059dd <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105a35:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105a3a:	c9                   	leave  
80105a3b:	c3                   	ret    

80105a3c <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105a3c:	55                   	push   %ebp
80105a3d:	89 e5                	mov    %esp,%ebp
80105a3f:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105a42:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105a45:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a49:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a50:	e8 71 fa ff ff       	call   801054c6 <argstr>
80105a55:	85 c0                	test   %eax,%eax
80105a57:	79 0a                	jns    80105a63 <sys_unlink+0x27>
    return -1;
80105a59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a5e:	e9 af 01 00 00       	jmp    80105c12 <sys_unlink+0x1d6>

  begin_op();
80105a63:	e8 a8 d9 ff ff       	call   80103410 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105a68:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105a6b:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105a6e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a72:	89 04 24             	mov    %eax,(%esp)
80105a75:	e8 ae c9 ff ff       	call   80102428 <nameiparent>
80105a7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a7d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a81:	75 0f                	jne    80105a92 <sys_unlink+0x56>
    end_op();
80105a83:	e8 0c da ff ff       	call   80103494 <end_op>
    return -1;
80105a88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a8d:	e9 80 01 00 00       	jmp    80105c12 <sys_unlink+0x1d6>
  }

  ilock(dp);
80105a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a95:	89 04 24             	mov    %eax,(%esp)
80105a98:	e8 be bd ff ff       	call   8010185b <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105a9d:	c7 44 24 04 85 88 10 	movl   $0x80108885,0x4(%esp)
80105aa4:	80 
80105aa5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105aa8:	89 04 24             	mov    %eax,(%esp)
80105aab:	e8 ab c5 ff ff       	call   8010205b <namecmp>
80105ab0:	85 c0                	test   %eax,%eax
80105ab2:	0f 84 45 01 00 00    	je     80105bfd <sys_unlink+0x1c1>
80105ab8:	c7 44 24 04 87 88 10 	movl   $0x80108887,0x4(%esp)
80105abf:	80 
80105ac0:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ac3:	89 04 24             	mov    %eax,(%esp)
80105ac6:	e8 90 c5 ff ff       	call   8010205b <namecmp>
80105acb:	85 c0                	test   %eax,%eax
80105acd:	0f 84 2a 01 00 00    	je     80105bfd <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105ad3:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105ad6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ada:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105add:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ae4:	89 04 24             	mov    %eax,(%esp)
80105ae7:	e8 91 c5 ff ff       	call   8010207d <dirlookup>
80105aec:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105aef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105af3:	75 05                	jne    80105afa <sys_unlink+0xbe>
    goto bad;
80105af5:	e9 03 01 00 00       	jmp    80105bfd <sys_unlink+0x1c1>
  ilock(ip);
80105afa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105afd:	89 04 24             	mov    %eax,(%esp)
80105b00:	e8 56 bd ff ff       	call   8010185b <ilock>

  if(ip->nlink < 1)
80105b05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b08:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b0c:	66 85 c0             	test   %ax,%ax
80105b0f:	7f 0c                	jg     80105b1d <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105b11:	c7 04 24 8a 88 10 80 	movl   $0x8010888a,(%esp)
80105b18:	e8 1d aa ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105b1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b20:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b24:	66 83 f8 01          	cmp    $0x1,%ax
80105b28:	75 1f                	jne    80105b49 <sys_unlink+0x10d>
80105b2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b2d:	89 04 24             	mov    %eax,(%esp)
80105b30:	e8 99 fe ff ff       	call   801059ce <isdirempty>
80105b35:	85 c0                	test   %eax,%eax
80105b37:	75 10                	jne    80105b49 <sys_unlink+0x10d>
    iunlockput(ip);
80105b39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b3c:	89 04 24             	mov    %eax,(%esp)
80105b3f:	e8 9b bf ff ff       	call   80101adf <iunlockput>
    goto bad;
80105b44:	e9 b4 00 00 00       	jmp    80105bfd <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105b49:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105b50:	00 
80105b51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105b58:	00 
80105b59:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105b5c:	89 04 24             	mov    %eax,(%esp)
80105b5f:	e8 90 f5 ff ff       	call   801050f4 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105b64:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105b67:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105b6e:	00 
80105b6f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b73:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105b76:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b7d:	89 04 24             	mov    %eax,(%esp)
80105b80:	e8 47 c3 ff ff       	call   80101ecc <writei>
80105b85:	83 f8 10             	cmp    $0x10,%eax
80105b88:	74 0c                	je     80105b96 <sys_unlink+0x15a>
    panic("unlink: writei");
80105b8a:	c7 04 24 9c 88 10 80 	movl   $0x8010889c,(%esp)
80105b91:	e8 a4 a9 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105b96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b99:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b9d:	66 83 f8 01          	cmp    $0x1,%ax
80105ba1:	75 1c                	jne    80105bbf <sys_unlink+0x183>
    dp->nlink--;
80105ba3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ba6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105baa:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105bb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb7:	89 04 24             	mov    %eax,(%esp)
80105bba:	e8 e0 ba ff ff       	call   8010169f <iupdate>
  }
  iunlockput(dp);
80105bbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc2:	89 04 24             	mov    %eax,(%esp)
80105bc5:	e8 15 bf ff ff       	call   80101adf <iunlockput>

  ip->nlink--;
80105bca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bcd:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105bd1:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd7:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105bdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bde:	89 04 24             	mov    %eax,(%esp)
80105be1:	e8 b9 ba ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105be6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105be9:	89 04 24             	mov    %eax,(%esp)
80105bec:	e8 ee be ff ff       	call   80101adf <iunlockput>

  end_op();
80105bf1:	e8 9e d8 ff ff       	call   80103494 <end_op>

  return 0;
80105bf6:	b8 00 00 00 00       	mov    $0x0,%eax
80105bfb:	eb 15                	jmp    80105c12 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c00:	89 04 24             	mov    %eax,(%esp)
80105c03:	e8 d7 be ff ff       	call   80101adf <iunlockput>
  end_op();
80105c08:	e8 87 d8 ff ff       	call   80103494 <end_op>
  return -1;
80105c0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c12:	c9                   	leave  
80105c13:	c3                   	ret    

80105c14 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105c14:	55                   	push   %ebp
80105c15:	89 e5                	mov    %esp,%ebp
80105c17:	83 ec 48             	sub    $0x48,%esp
80105c1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105c1d:	8b 55 10             	mov    0x10(%ebp),%edx
80105c20:	8b 45 14             	mov    0x14(%ebp),%eax
80105c23:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105c27:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105c2b:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105c2f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c36:	8b 45 08             	mov    0x8(%ebp),%eax
80105c39:	89 04 24             	mov    %eax,(%esp)
80105c3c:	e8 e7 c7 ff ff       	call   80102428 <nameiparent>
80105c41:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c44:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c48:	75 0a                	jne    80105c54 <create+0x40>
    return 0;
80105c4a:	b8 00 00 00 00       	mov    $0x0,%eax
80105c4f:	e9 7e 01 00 00       	jmp    80105dd2 <create+0x1be>
  ilock(dp);
80105c54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c57:	89 04 24             	mov    %eax,(%esp)
80105c5a:	e8 fc bb ff ff       	call   8010185b <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105c5f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105c62:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c66:	8d 45 de             	lea    -0x22(%ebp),%eax
80105c69:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c70:	89 04 24             	mov    %eax,(%esp)
80105c73:	e8 05 c4 ff ff       	call   8010207d <dirlookup>
80105c78:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c7b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c7f:	74 47                	je     80105cc8 <create+0xb4>
    iunlockput(dp);
80105c81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c84:	89 04 24             	mov    %eax,(%esp)
80105c87:	e8 53 be ff ff       	call   80101adf <iunlockput>
    ilock(ip);
80105c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c8f:	89 04 24             	mov    %eax,(%esp)
80105c92:	e8 c4 bb ff ff       	call   8010185b <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105c97:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105c9c:	75 15                	jne    80105cb3 <create+0x9f>
80105c9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ca5:	66 83 f8 02          	cmp    $0x2,%ax
80105ca9:	75 08                	jne    80105cb3 <create+0x9f>
      return ip;
80105cab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cae:	e9 1f 01 00 00       	jmp    80105dd2 <create+0x1be>
    iunlockput(ip);
80105cb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cb6:	89 04 24             	mov    %eax,(%esp)
80105cb9:	e8 21 be ff ff       	call   80101adf <iunlockput>
    return 0;
80105cbe:	b8 00 00 00 00       	mov    $0x0,%eax
80105cc3:	e9 0a 01 00 00       	jmp    80105dd2 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105cc8:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105ccc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ccf:	8b 00                	mov    (%eax),%eax
80105cd1:	89 54 24 04          	mov    %edx,0x4(%esp)
80105cd5:	89 04 24             	mov    %eax,(%esp)
80105cd8:	e8 e3 b8 ff ff       	call   801015c0 <ialloc>
80105cdd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ce0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ce4:	75 0c                	jne    80105cf2 <create+0xde>
    panic("create: ialloc");
80105ce6:	c7 04 24 ab 88 10 80 	movl   $0x801088ab,(%esp)
80105ced:	e8 48 a8 ff ff       	call   8010053a <panic>

  ilock(ip);
80105cf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cf5:	89 04 24             	mov    %eax,(%esp)
80105cf8:	e8 5e bb ff ff       	call   8010185b <ilock>
  ip->major = major;
80105cfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d00:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105d04:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105d08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d0b:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105d0f:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105d13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d16:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105d1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1f:	89 04 24             	mov    %eax,(%esp)
80105d22:	e8 78 b9 ff ff       	call   8010169f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105d27:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105d2c:	75 6a                	jne    80105d98 <create+0x184>
    dp->nlink++;  // for ".."
80105d2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d31:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d35:	8d 50 01             	lea    0x1(%eax),%edx
80105d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d3b:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105d3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d42:	89 04 24             	mov    %eax,(%esp)
80105d45:	e8 55 b9 ff ff       	call   8010169f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105d4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d4d:	8b 40 04             	mov    0x4(%eax),%eax
80105d50:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d54:	c7 44 24 04 85 88 10 	movl   $0x80108885,0x4(%esp)
80105d5b:	80 
80105d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d5f:	89 04 24             	mov    %eax,(%esp)
80105d62:	e8 df c3 ff ff       	call   80102146 <dirlink>
80105d67:	85 c0                	test   %eax,%eax
80105d69:	78 21                	js     80105d8c <create+0x178>
80105d6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d6e:	8b 40 04             	mov    0x4(%eax),%eax
80105d71:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d75:	c7 44 24 04 87 88 10 	movl   $0x80108887,0x4(%esp)
80105d7c:	80 
80105d7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d80:	89 04 24             	mov    %eax,(%esp)
80105d83:	e8 be c3 ff ff       	call   80102146 <dirlink>
80105d88:	85 c0                	test   %eax,%eax
80105d8a:	79 0c                	jns    80105d98 <create+0x184>
      panic("create dots");
80105d8c:	c7 04 24 ba 88 10 80 	movl   $0x801088ba,(%esp)
80105d93:	e8 a2 a7 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105d98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d9b:	8b 40 04             	mov    0x4(%eax),%eax
80105d9e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105da2:	8d 45 de             	lea    -0x22(%ebp),%eax
80105da5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105da9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dac:	89 04 24             	mov    %eax,(%esp)
80105daf:	e8 92 c3 ff ff       	call   80102146 <dirlink>
80105db4:	85 c0                	test   %eax,%eax
80105db6:	79 0c                	jns    80105dc4 <create+0x1b0>
    panic("create: dirlink");
80105db8:	c7 04 24 c6 88 10 80 	movl   $0x801088c6,(%esp)
80105dbf:	e8 76 a7 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80105dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc7:	89 04 24             	mov    %eax,(%esp)
80105dca:	e8 10 bd ff ff       	call   80101adf <iunlockput>

  return ip;
80105dcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105dd2:	c9                   	leave  
80105dd3:	c3                   	ret    

80105dd4 <sys_open>:

int
sys_open(void)
{
80105dd4:	55                   	push   %ebp
80105dd5:	89 e5                	mov    %esp,%ebp
80105dd7:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105dda:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105de8:	e8 d9 f6 ff ff       	call   801054c6 <argstr>
80105ded:	85 c0                	test   %eax,%eax
80105def:	78 17                	js     80105e08 <sys_open+0x34>
80105df1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105df4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105df8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105dff:	e8 32 f6 ff ff       	call   80105436 <argint>
80105e04:	85 c0                	test   %eax,%eax
80105e06:	79 0a                	jns    80105e12 <sys_open+0x3e>
    return -1;
80105e08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e0d:	e9 5c 01 00 00       	jmp    80105f6e <sys_open+0x19a>

  begin_op();
80105e12:	e8 f9 d5 ff ff       	call   80103410 <begin_op>

  if(omode & O_CREATE){
80105e17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e1a:	25 00 02 00 00       	and    $0x200,%eax
80105e1f:	85 c0                	test   %eax,%eax
80105e21:	74 3b                	je     80105e5e <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105e23:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e26:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105e2d:	00 
80105e2e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105e35:	00 
80105e36:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105e3d:	00 
80105e3e:	89 04 24             	mov    %eax,(%esp)
80105e41:	e8 ce fd ff ff       	call   80105c14 <create>
80105e46:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105e49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e4d:	75 6b                	jne    80105eba <sys_open+0xe6>
      end_op();
80105e4f:	e8 40 d6 ff ff       	call   80103494 <end_op>
      return -1;
80105e54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e59:	e9 10 01 00 00       	jmp    80105f6e <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80105e5e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e61:	89 04 24             	mov    %eax,(%esp)
80105e64:	e8 9d c5 ff ff       	call   80102406 <namei>
80105e69:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e6c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e70:	75 0f                	jne    80105e81 <sys_open+0xad>
      end_op();
80105e72:	e8 1d d6 ff ff       	call   80103494 <end_op>
      return -1;
80105e77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e7c:	e9 ed 00 00 00       	jmp    80105f6e <sys_open+0x19a>
    }
    ilock(ip);
80105e81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e84:	89 04 24             	mov    %eax,(%esp)
80105e87:	e8 cf b9 ff ff       	call   8010185b <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105e8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e8f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e93:	66 83 f8 01          	cmp    $0x1,%ax
80105e97:	75 21                	jne    80105eba <sys_open+0xe6>
80105e99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e9c:	85 c0                	test   %eax,%eax
80105e9e:	74 1a                	je     80105eba <sys_open+0xe6>
      iunlockput(ip);
80105ea0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea3:	89 04 24             	mov    %eax,(%esp)
80105ea6:	e8 34 bc ff ff       	call   80101adf <iunlockput>
      end_op();
80105eab:	e8 e4 d5 ff ff       	call   80103494 <end_op>
      return -1;
80105eb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eb5:	e9 b4 00 00 00       	jmp    80105f6e <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105eba:	e8 67 b0 ff ff       	call   80100f26 <filealloc>
80105ebf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ec2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ec6:	74 14                	je     80105edc <sys_open+0x108>
80105ec8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ecb:	89 04 24             	mov    %eax,(%esp)
80105ece:	e8 2e f7 ff ff       	call   80105601 <fdalloc>
80105ed3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105ed6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105eda:	79 28                	jns    80105f04 <sys_open+0x130>
    if(f)
80105edc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ee0:	74 0b                	je     80105eed <sys_open+0x119>
      fileclose(f);
80105ee2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ee5:	89 04 24             	mov    %eax,(%esp)
80105ee8:	e8 e1 b0 ff ff       	call   80100fce <fileclose>
    iunlockput(ip);
80105eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ef0:	89 04 24             	mov    %eax,(%esp)
80105ef3:	e8 e7 bb ff ff       	call   80101adf <iunlockput>
    end_op();
80105ef8:	e8 97 d5 ff ff       	call   80103494 <end_op>
    return -1;
80105efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f02:	eb 6a                	jmp    80105f6e <sys_open+0x19a>
  }
  iunlock(ip);
80105f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f07:	89 04 24             	mov    %eax,(%esp)
80105f0a:	e8 9a ba ff ff       	call   801019a9 <iunlock>
  end_op();
80105f0f:	e8 80 d5 ff ff       	call   80103494 <end_op>

  f->type = FD_INODE;
80105f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f17:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105f1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f20:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f23:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105f26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f29:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105f30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f33:	83 e0 01             	and    $0x1,%eax
80105f36:	85 c0                	test   %eax,%eax
80105f38:	0f 94 c0             	sete   %al
80105f3b:	89 c2                	mov    %eax,%edx
80105f3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f40:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105f43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f46:	83 e0 01             	and    $0x1,%eax
80105f49:	85 c0                	test   %eax,%eax
80105f4b:	75 0a                	jne    80105f57 <sys_open+0x183>
80105f4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f50:	83 e0 02             	and    $0x2,%eax
80105f53:	85 c0                	test   %eax,%eax
80105f55:	74 07                	je     80105f5e <sys_open+0x18a>
80105f57:	b8 01 00 00 00       	mov    $0x1,%eax
80105f5c:	eb 05                	jmp    80105f63 <sys_open+0x18f>
80105f5e:	b8 00 00 00 00       	mov    $0x0,%eax
80105f63:	89 c2                	mov    %eax,%edx
80105f65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f68:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105f6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105f6e:	c9                   	leave  
80105f6f:	c3                   	ret    

80105f70 <sys_mkdir>:

int
sys_mkdir(void)
{
80105f70:	55                   	push   %ebp
80105f71:	89 e5                	mov    %esp,%ebp
80105f73:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80105f76:	e8 95 d4 ff ff       	call   80103410 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105f7b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f82:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f89:	e8 38 f5 ff ff       	call   801054c6 <argstr>
80105f8e:	85 c0                	test   %eax,%eax
80105f90:	78 2c                	js     80105fbe <sys_mkdir+0x4e>
80105f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f95:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105f9c:	00 
80105f9d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105fa4:	00 
80105fa5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105fac:	00 
80105fad:	89 04 24             	mov    %eax,(%esp)
80105fb0:	e8 5f fc ff ff       	call   80105c14 <create>
80105fb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fb8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fbc:	75 0c                	jne    80105fca <sys_mkdir+0x5a>
    end_op();
80105fbe:	e8 d1 d4 ff ff       	call   80103494 <end_op>
    return -1;
80105fc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fc8:	eb 15                	jmp    80105fdf <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105fca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fcd:	89 04 24             	mov    %eax,(%esp)
80105fd0:	e8 0a bb ff ff       	call   80101adf <iunlockput>
  end_op();
80105fd5:	e8 ba d4 ff ff       	call   80103494 <end_op>
  return 0;
80105fda:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105fdf:	c9                   	leave  
80105fe0:	c3                   	ret    

80105fe1 <sys_mknod>:

int
sys_mknod(void)
{
80105fe1:	55                   	push   %ebp
80105fe2:	89 e5                	mov    %esp,%ebp
80105fe4:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80105fe7:	e8 24 d4 ff ff       	call   80103410 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80105fec:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fef:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ff3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ffa:	e8 c7 f4 ff ff       	call   801054c6 <argstr>
80105fff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106002:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106006:	78 5e                	js     80106066 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106008:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010600b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010600f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106016:	e8 1b f4 ff ff       	call   80105436 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
8010601b:	85 c0                	test   %eax,%eax
8010601d:	78 47                	js     80106066 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010601f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106022:	89 44 24 04          	mov    %eax,0x4(%esp)
80106026:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010602d:	e8 04 f4 ff ff       	call   80105436 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106032:	85 c0                	test   %eax,%eax
80106034:	78 30                	js     80106066 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106036:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106039:	0f bf c8             	movswl %ax,%ecx
8010603c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010603f:	0f bf d0             	movswl %ax,%edx
80106042:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106045:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106049:	89 54 24 08          	mov    %edx,0x8(%esp)
8010604d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106054:	00 
80106055:	89 04 24             	mov    %eax,(%esp)
80106058:	e8 b7 fb ff ff       	call   80105c14 <create>
8010605d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106060:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106064:	75 0c                	jne    80106072 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106066:	e8 29 d4 ff ff       	call   80103494 <end_op>
    return -1;
8010606b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106070:	eb 15                	jmp    80106087 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106072:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106075:	89 04 24             	mov    %eax,(%esp)
80106078:	e8 62 ba ff ff       	call   80101adf <iunlockput>
  end_op();
8010607d:	e8 12 d4 ff ff       	call   80103494 <end_op>
  return 0;
80106082:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106087:	c9                   	leave  
80106088:	c3                   	ret    

80106089 <sys_chdir>:

int
sys_chdir(void)
{
80106089:	55                   	push   %ebp
8010608a:	89 e5                	mov    %esp,%ebp
8010608c:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010608f:	e8 7c d3 ff ff       	call   80103410 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106094:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106097:	89 44 24 04          	mov    %eax,0x4(%esp)
8010609b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060a2:	e8 1f f4 ff ff       	call   801054c6 <argstr>
801060a7:	85 c0                	test   %eax,%eax
801060a9:	78 14                	js     801060bf <sys_chdir+0x36>
801060ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ae:	89 04 24             	mov    %eax,(%esp)
801060b1:	e8 50 c3 ff ff       	call   80102406 <namei>
801060b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060bd:	75 0c                	jne    801060cb <sys_chdir+0x42>
    end_op();
801060bf:	e8 d0 d3 ff ff       	call   80103494 <end_op>
    return -1;
801060c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060c9:	eb 61                	jmp    8010612c <sys_chdir+0xa3>
  }
  ilock(ip);
801060cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ce:	89 04 24             	mov    %eax,(%esp)
801060d1:	e8 85 b7 ff ff       	call   8010185b <ilock>
  if(ip->type != T_DIR){
801060d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060d9:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801060dd:	66 83 f8 01          	cmp    $0x1,%ax
801060e1:	74 17                	je     801060fa <sys_chdir+0x71>
    iunlockput(ip);
801060e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e6:	89 04 24             	mov    %eax,(%esp)
801060e9:	e8 f1 b9 ff ff       	call   80101adf <iunlockput>
    end_op();
801060ee:	e8 a1 d3 ff ff       	call   80103494 <end_op>
    return -1;
801060f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060f8:	eb 32                	jmp    8010612c <sys_chdir+0xa3>
  }
  iunlock(ip);
801060fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060fd:	89 04 24             	mov    %eax,(%esp)
80106100:	e8 a4 b8 ff ff       	call   801019a9 <iunlock>
  iput(proc->cwd);
80106105:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010610b:	8b 40 68             	mov    0x68(%eax),%eax
8010610e:	89 04 24             	mov    %eax,(%esp)
80106111:	e8 f8 b8 ff ff       	call   80101a0e <iput>
  end_op();
80106116:	e8 79 d3 ff ff       	call   80103494 <end_op>
  proc->cwd = ip;
8010611b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106121:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106124:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106127:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010612c:	c9                   	leave  
8010612d:	c3                   	ret    

8010612e <sys_exec>:

int
sys_exec(void)
{
8010612e:	55                   	push   %ebp
8010612f:	89 e5                	mov    %esp,%ebp
80106131:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106137:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010613a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010613e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106145:	e8 7c f3 ff ff       	call   801054c6 <argstr>
8010614a:	85 c0                	test   %eax,%eax
8010614c:	78 1a                	js     80106168 <sys_exec+0x3a>
8010614e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106154:	89 44 24 04          	mov    %eax,0x4(%esp)
80106158:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010615f:	e8 d2 f2 ff ff       	call   80105436 <argint>
80106164:	85 c0                	test   %eax,%eax
80106166:	79 0a                	jns    80106172 <sys_exec+0x44>
    return -1;
80106168:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010616d:	e9 c8 00 00 00       	jmp    8010623a <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106172:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106179:	00 
8010617a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106181:	00 
80106182:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106188:	89 04 24             	mov    %eax,(%esp)
8010618b:	e8 64 ef ff ff       	call   801050f4 <memset>
  for(i=0;; i++){
80106190:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010619a:	83 f8 1f             	cmp    $0x1f,%eax
8010619d:	76 0a                	jbe    801061a9 <sys_exec+0x7b>
      return -1;
8010619f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a4:	e9 91 00 00 00       	jmp    8010623a <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
801061a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ac:	c1 e0 02             	shl    $0x2,%eax
801061af:	89 c2                	mov    %eax,%edx
801061b1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801061b7:	01 c2                	add    %eax,%edx
801061b9:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
801061bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c3:	89 14 24             	mov    %edx,(%esp)
801061c6:	e8 cf f1 ff ff       	call   8010539a <fetchint>
801061cb:	85 c0                	test   %eax,%eax
801061cd:	79 07                	jns    801061d6 <sys_exec+0xa8>
      return -1;
801061cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d4:	eb 64                	jmp    8010623a <sys_exec+0x10c>
    if(uarg == 0){
801061d6:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801061dc:	85 c0                	test   %eax,%eax
801061de:	75 26                	jne    80106206 <sys_exec+0xd8>
      argv[i] = 0;
801061e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e3:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801061ea:	00 00 00 00 
      break;
801061ee:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801061ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061f2:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801061f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801061fc:	89 04 24             	mov    %eax,(%esp)
801061ff:	e8 eb a8 ff ff       	call   80100aef <exec>
80106204:	eb 34                	jmp    8010623a <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106206:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010620c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010620f:	c1 e2 02             	shl    $0x2,%edx
80106212:	01 c2                	add    %eax,%edx
80106214:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010621a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010621e:	89 04 24             	mov    %eax,(%esp)
80106221:	e8 ae f1 ff ff       	call   801053d4 <fetchstr>
80106226:	85 c0                	test   %eax,%eax
80106228:	79 07                	jns    80106231 <sys_exec+0x103>
      return -1;
8010622a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010622f:	eb 09                	jmp    8010623a <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106231:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106235:	e9 5d ff ff ff       	jmp    80106197 <sys_exec+0x69>
  return exec(path, argv);
}
8010623a:	c9                   	leave  
8010623b:	c3                   	ret    

8010623c <sys_pipe>:

int
sys_pipe(void)
{
8010623c:	55                   	push   %ebp
8010623d:	89 e5                	mov    %esp,%ebp
8010623f:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106242:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106249:	00 
8010624a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010624d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106251:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106258:	e8 07 f2 ff ff       	call   80105464 <argptr>
8010625d:	85 c0                	test   %eax,%eax
8010625f:	79 0a                	jns    8010626b <sys_pipe+0x2f>
    return -1;
80106261:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106266:	e9 9b 00 00 00       	jmp    80106306 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
8010626b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010626e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106272:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106275:	89 04 24             	mov    %eax,(%esp)
80106278:	e8 a4 dc ff ff       	call   80103f21 <pipealloc>
8010627d:	85 c0                	test   %eax,%eax
8010627f:	79 07                	jns    80106288 <sys_pipe+0x4c>
    return -1;
80106281:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106286:	eb 7e                	jmp    80106306 <sys_pipe+0xca>
  fd0 = -1;
80106288:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010628f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106292:	89 04 24             	mov    %eax,(%esp)
80106295:	e8 67 f3 ff ff       	call   80105601 <fdalloc>
8010629a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010629d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062a1:	78 14                	js     801062b7 <sys_pipe+0x7b>
801062a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062a6:	89 04 24             	mov    %eax,(%esp)
801062a9:	e8 53 f3 ff ff       	call   80105601 <fdalloc>
801062ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
801062b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062b5:	79 37                	jns    801062ee <sys_pipe+0xb2>
    if(fd0 >= 0)
801062b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062bb:	78 14                	js     801062d1 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801062bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062c6:	83 c2 08             	add    $0x8,%edx
801062c9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801062d0:	00 
    fileclose(rf);
801062d1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801062d4:	89 04 24             	mov    %eax,(%esp)
801062d7:	e8 f2 ac ff ff       	call   80100fce <fileclose>
    fileclose(wf);
801062dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062df:	89 04 24             	mov    %eax,(%esp)
801062e2:	e8 e7 ac ff ff       	call   80100fce <fileclose>
    return -1;
801062e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062ec:	eb 18                	jmp    80106306 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801062ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801062f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062f4:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801062f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801062f9:	8d 50 04             	lea    0x4(%eax),%edx
801062fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062ff:	89 02                	mov    %eax,(%edx)
  return 0;
80106301:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106306:	c9                   	leave  
80106307:	c3                   	ret    

80106308 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106308:	55                   	push   %ebp
80106309:	89 e5                	mov    %esp,%ebp
8010630b:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010630e:	e8 e4 e2 ff ff       	call   801045f7 <fork>
}
80106313:	c9                   	leave  
80106314:	c3                   	ret    

80106315 <sys_exit>:

int
sys_exit(void)
{
80106315:	55                   	push   %ebp
80106316:	89 e5                	mov    %esp,%ebp
80106318:	83 ec 08             	sub    $0x8,%esp
  exit();
8010631b:	e8 52 e4 ff ff       	call   80104772 <exit>
  return 0;  // not reached
80106320:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106325:	c9                   	leave  
80106326:	c3                   	ret    

80106327 <sys_wait>:

int
sys_wait(void)
{
80106327:	55                   	push   %ebp
80106328:	89 e5                	mov    %esp,%ebp
8010632a:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010632d:	e8 62 e5 ff ff       	call   80104894 <wait>
}
80106332:	c9                   	leave  
80106333:	c3                   	ret    

80106334 <sys_kill>:

int
sys_kill(void)
{
80106334:	55                   	push   %ebp
80106335:	89 e5                	mov    %esp,%ebp
80106337:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010633a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010633d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106341:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106348:	e8 e9 f0 ff ff       	call   80105436 <argint>
8010634d:	85 c0                	test   %eax,%eax
8010634f:	79 07                	jns    80106358 <sys_kill+0x24>
    return -1;
80106351:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106356:	eb 0b                	jmp    80106363 <sys_kill+0x2f>
  return kill(pid);
80106358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010635b:	89 04 24             	mov    %eax,(%esp)
8010635e:	e8 6d e9 ff ff       	call   80104cd0 <kill>
}
80106363:	c9                   	leave  
80106364:	c3                   	ret    

80106365 <sys_getpid>:

int
sys_getpid(void)
{
80106365:	55                   	push   %ebp
80106366:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106368:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010636e:	8b 40 10             	mov    0x10(%eax),%eax
}
80106371:	5d                   	pop    %ebp
80106372:	c3                   	ret    

80106373 <sys_sbrk>:

int
sys_sbrk(void)
{
80106373:	55                   	push   %ebp
80106374:	89 e5                	mov    %esp,%ebp
80106376:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106379:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010637c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106380:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106387:	e8 aa f0 ff ff       	call   80105436 <argint>
8010638c:	85 c0                	test   %eax,%eax
8010638e:	79 07                	jns    80106397 <sys_sbrk+0x24>
    return -1;
80106390:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106395:	eb 24                	jmp    801063bb <sys_sbrk+0x48>
  addr = proc->sz;
80106397:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010639d:	8b 00                	mov    (%eax),%eax
8010639f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801063a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a5:	89 04 24             	mov    %eax,(%esp)
801063a8:	e8 a5 e1 ff ff       	call   80104552 <growproc>
801063ad:	85 c0                	test   %eax,%eax
801063af:	79 07                	jns    801063b8 <sys_sbrk+0x45>
    return -1;
801063b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063b6:	eb 03                	jmp    801063bb <sys_sbrk+0x48>
  return addr;
801063b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801063bb:	c9                   	leave  
801063bc:	c3                   	ret    

801063bd <sys_sleep>:

int
sys_sleep(void)
{
801063bd:	55                   	push   %ebp
801063be:	89 e5                	mov    %esp,%ebp
801063c0:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801063c3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801063ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063d1:	e8 60 f0 ff ff       	call   80105436 <argint>
801063d6:	85 c0                	test   %eax,%eax
801063d8:	79 07                	jns    801063e1 <sys_sleep+0x24>
    return -1;
801063da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063df:	eb 6c                	jmp    8010644d <sys_sleep+0x90>
  acquire(&tickslock);
801063e1:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801063e8:	e8 b3 ea ff ff       	call   80104ea0 <acquire>
  ticks0 = ticks;
801063ed:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801063f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801063f5:	eb 34                	jmp    8010642b <sys_sleep+0x6e>
    if(proc->killed){
801063f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063fd:	8b 40 24             	mov    0x24(%eax),%eax
80106400:	85 c0                	test   %eax,%eax
80106402:	74 13                	je     80106417 <sys_sleep+0x5a>
      release(&tickslock);
80106404:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010640b:	e8 f2 ea ff ff       	call   80104f02 <release>
      return -1;
80106410:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106415:	eb 36                	jmp    8010644d <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106417:	c7 44 24 04 a0 48 11 	movl   $0x801148a0,0x4(%esp)
8010641e:	80 
8010641f:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
80106426:	e8 a2 e7 ff ff       	call   80104bcd <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010642b:	a1 e0 50 11 80       	mov    0x801150e0,%eax
80106430:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106433:	89 c2                	mov    %eax,%edx
80106435:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106438:	39 c2                	cmp    %eax,%edx
8010643a:	72 bb                	jb     801063f7 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010643c:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106443:	e8 ba ea ff ff       	call   80104f02 <release>
  return 0;
80106448:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010644d:	c9                   	leave  
8010644e:	c3                   	ret    

8010644f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010644f:	55                   	push   %ebp
80106450:	89 e5                	mov    %esp,%ebp
80106452:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106455:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010645c:	e8 3f ea ff ff       	call   80104ea0 <acquire>
  xticks = ticks;
80106461:	a1 e0 50 11 80       	mov    0x801150e0,%eax
80106466:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106469:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106470:	e8 8d ea ff ff       	call   80104f02 <release>
  return xticks;
80106475:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106478:	c9                   	leave  
80106479:	c3                   	ret    

8010647a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010647a:	55                   	push   %ebp
8010647b:	89 e5                	mov    %esp,%ebp
8010647d:	83 ec 08             	sub    $0x8,%esp
80106480:	8b 55 08             	mov    0x8(%ebp),%edx
80106483:	8b 45 0c             	mov    0xc(%ebp),%eax
80106486:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010648a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010648d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106491:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106495:	ee                   	out    %al,(%dx)
}
80106496:	c9                   	leave  
80106497:	c3                   	ret    

80106498 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106498:	55                   	push   %ebp
80106499:	89 e5                	mov    %esp,%ebp
8010649b:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010649e:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801064a5:	00 
801064a6:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801064ad:	e8 c8 ff ff ff       	call   8010647a <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801064b2:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801064b9:	00 
801064ba:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801064c1:	e8 b4 ff ff ff       	call   8010647a <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801064c6:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801064cd:	00 
801064ce:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801064d5:	e8 a0 ff ff ff       	call   8010647a <outb>
  picenable(IRQ_TIMER);
801064da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064e1:	e8 ce d8 ff ff       	call   80103db4 <picenable>
}
801064e6:	c9                   	leave  
801064e7:	c3                   	ret    

801064e8 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801064e8:	1e                   	push   %ds
  pushl %es
801064e9:	06                   	push   %es
  pushl %fs
801064ea:	0f a0                	push   %fs
  pushl %gs
801064ec:	0f a8                	push   %gs
  pushal
801064ee:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801064ef:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801064f3:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801064f5:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801064f7:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801064fb:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801064fd:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801064ff:	54                   	push   %esp
  call trap
80106500:	e8 d8 01 00 00       	call   801066dd <trap>
  addl $4, %esp
80106505:	83 c4 04             	add    $0x4,%esp

80106508 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106508:	61                   	popa   
  popl %gs
80106509:	0f a9                	pop    %gs
  popl %fs
8010650b:	0f a1                	pop    %fs
  popl %es
8010650d:	07                   	pop    %es
  popl %ds
8010650e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010650f:	83 c4 08             	add    $0x8,%esp
  iret
80106512:	cf                   	iret   

80106513 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106513:	55                   	push   %ebp
80106514:	89 e5                	mov    %esp,%ebp
80106516:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106519:	8b 45 0c             	mov    0xc(%ebp),%eax
8010651c:	83 e8 01             	sub    $0x1,%eax
8010651f:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106523:	8b 45 08             	mov    0x8(%ebp),%eax
80106526:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010652a:	8b 45 08             	mov    0x8(%ebp),%eax
8010652d:	c1 e8 10             	shr    $0x10,%eax
80106530:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106534:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106537:	0f 01 18             	lidtl  (%eax)
}
8010653a:	c9                   	leave  
8010653b:	c3                   	ret    

8010653c <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010653c:	55                   	push   %ebp
8010653d:	89 e5                	mov    %esp,%ebp
8010653f:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106542:	0f 20 d0             	mov    %cr2,%eax
80106545:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106548:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010654b:	c9                   	leave  
8010654c:	c3                   	ret    

8010654d <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010654d:	55                   	push   %ebp
8010654e:	89 e5                	mov    %esp,%ebp
80106550:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106553:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010655a:	e9 c3 00 00 00       	jmp    80106622 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010655f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106562:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106569:	89 c2                	mov    %eax,%edx
8010656b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010656e:	66 89 14 c5 e0 48 11 	mov    %dx,-0x7feeb720(,%eax,8)
80106575:	80 
80106576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106579:	66 c7 04 c5 e2 48 11 	movw   $0x8,-0x7feeb71e(,%eax,8)
80106580:	80 08 00 
80106583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106586:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
8010658d:	80 
8010658e:	83 e2 e0             	and    $0xffffffe0,%edx
80106591:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
80106598:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010659b:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
801065a2:	80 
801065a3:	83 e2 1f             	and    $0x1f,%edx
801065a6:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
801065ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b0:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801065b7:	80 
801065b8:	83 e2 f0             	and    $0xfffffff0,%edx
801065bb:	83 ca 0e             	or     $0xe,%edx
801065be:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801065c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c8:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801065cf:	80 
801065d0:	83 e2 ef             	and    $0xffffffef,%edx
801065d3:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801065da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065dd:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801065e4:	80 
801065e5:	83 e2 9f             	and    $0xffffff9f,%edx
801065e8:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
801065ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065f2:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
801065f9:	80 
801065fa:	83 ca 80             	or     $0xffffff80,%edx
801065fd:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
80106604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106607:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010660e:	c1 e8 10             	shr    $0x10,%eax
80106611:	89 c2                	mov    %eax,%edx
80106613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106616:	66 89 14 c5 e6 48 11 	mov    %dx,-0x7feeb71a(,%eax,8)
8010661d:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010661e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106622:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106629:	0f 8e 30 ff ff ff    	jle    8010655f <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010662f:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106634:	66 a3 e0 4a 11 80    	mov    %ax,0x80114ae0
8010663a:	66 c7 05 e2 4a 11 80 	movw   $0x8,0x80114ae2
80106641:	08 00 
80106643:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
8010664a:	83 e0 e0             	and    $0xffffffe0,%eax
8010664d:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
80106652:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
80106659:	83 e0 1f             	and    $0x1f,%eax
8010665c:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
80106661:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106668:	83 c8 0f             	or     $0xf,%eax
8010666b:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
80106670:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106677:	83 e0 ef             	and    $0xffffffef,%eax
8010667a:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010667f:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106686:	83 c8 60             	or     $0x60,%eax
80106689:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010668e:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106695:	83 c8 80             	or     $0xffffff80,%eax
80106698:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
8010669d:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801066a2:	c1 e8 10             	shr    $0x10,%eax
801066a5:	66 a3 e6 4a 11 80    	mov    %ax,0x80114ae6
  
  initlock(&tickslock, "time");
801066ab:	c7 44 24 04 d8 88 10 	movl   $0x801088d8,0x4(%esp)
801066b2:	80 
801066b3:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801066ba:	e8 c0 e7 ff ff       	call   80104e7f <initlock>
}
801066bf:	c9                   	leave  
801066c0:	c3                   	ret    

801066c1 <idtinit>:

void
idtinit(void)
{
801066c1:	55                   	push   %ebp
801066c2:	89 e5                	mov    %esp,%ebp
801066c4:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801066c7:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801066ce:	00 
801066cf:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
801066d6:	e8 38 fe ff ff       	call   80106513 <lidt>
}
801066db:	c9                   	leave  
801066dc:	c3                   	ret    

801066dd <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801066dd:	55                   	push   %ebp
801066de:	89 e5                	mov    %esp,%ebp
801066e0:	57                   	push   %edi
801066e1:	56                   	push   %esi
801066e2:	53                   	push   %ebx
801066e3:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801066e6:	8b 45 08             	mov    0x8(%ebp),%eax
801066e9:	8b 40 30             	mov    0x30(%eax),%eax
801066ec:	83 f8 40             	cmp    $0x40,%eax
801066ef:	75 3f                	jne    80106730 <trap+0x53>
    if(proc->killed)
801066f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066f7:	8b 40 24             	mov    0x24(%eax),%eax
801066fa:	85 c0                	test   %eax,%eax
801066fc:	74 05                	je     80106703 <trap+0x26>
      exit();
801066fe:	e8 6f e0 ff ff       	call   80104772 <exit>
    proc->tf = tf;
80106703:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106709:	8b 55 08             	mov    0x8(%ebp),%edx
8010670c:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010670f:	e8 e9 ed ff ff       	call   801054fd <syscall>
    if(proc->killed)
80106714:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010671a:	8b 40 24             	mov    0x24(%eax),%eax
8010671d:	85 c0                	test   %eax,%eax
8010671f:	74 0a                	je     8010672b <trap+0x4e>
      exit();
80106721:	e8 4c e0 ff ff       	call   80104772 <exit>
    return;
80106726:	e9 2d 02 00 00       	jmp    80106958 <trap+0x27b>
8010672b:	e9 28 02 00 00       	jmp    80106958 <trap+0x27b>
  }

  switch(tf->trapno){
80106730:	8b 45 08             	mov    0x8(%ebp),%eax
80106733:	8b 40 30             	mov    0x30(%eax),%eax
80106736:	83 e8 20             	sub    $0x20,%eax
80106739:	83 f8 1f             	cmp    $0x1f,%eax
8010673c:	0f 87 bc 00 00 00    	ja     801067fe <trap+0x121>
80106742:	8b 04 85 80 89 10 80 	mov    -0x7fef7680(,%eax,4),%eax
80106749:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010674b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106751:	0f b6 00             	movzbl (%eax),%eax
80106754:	84 c0                	test   %al,%al
80106756:	75 31                	jne    80106789 <trap+0xac>
      acquire(&tickslock);
80106758:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
8010675f:	e8 3c e7 ff ff       	call   80104ea0 <acquire>
      ticks++;
80106764:	a1 e0 50 11 80       	mov    0x801150e0,%eax
80106769:	83 c0 01             	add    $0x1,%eax
8010676c:	a3 e0 50 11 80       	mov    %eax,0x801150e0
      wakeup(&ticks);
80106771:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
80106778:	e8 28 e5 ff ff       	call   80104ca5 <wakeup>
      release(&tickslock);
8010677d:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106784:	e8 79 e7 ff ff       	call   80104f02 <release>
    }
    lapiceoi();
80106789:	e8 42 c7 ff ff       	call   80102ed0 <lapiceoi>
    break;
8010678e:	e9 41 01 00 00       	jmp    801068d4 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106793:	e8 46 bf ff ff       	call   801026de <ideintr>
    lapiceoi();
80106798:	e8 33 c7 ff ff       	call   80102ed0 <lapiceoi>
    break;
8010679d:	e9 32 01 00 00       	jmp    801068d4 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801067a2:	e8 f8 c4 ff ff       	call   80102c9f <kbdintr>
    lapiceoi();
801067a7:	e8 24 c7 ff ff       	call   80102ed0 <lapiceoi>
    break;
801067ac:	e9 23 01 00 00       	jmp    801068d4 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801067b1:	e8 97 03 00 00       	call   80106b4d <uartintr>
    lapiceoi();
801067b6:	e8 15 c7 ff ff       	call   80102ed0 <lapiceoi>
    break;
801067bb:	e9 14 01 00 00       	jmp    801068d4 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801067c0:	8b 45 08             	mov    0x8(%ebp),%eax
801067c3:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801067c6:	8b 45 08             	mov    0x8(%ebp),%eax
801067c9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801067cd:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801067d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801067d6:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801067d9:	0f b6 c0             	movzbl %al,%eax
801067dc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801067e0:	89 54 24 08          	mov    %edx,0x8(%esp)
801067e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801067e8:	c7 04 24 e0 88 10 80 	movl   $0x801088e0,(%esp)
801067ef:	e8 ac 9b ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801067f4:	e8 d7 c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
801067f9:	e9 d6 00 00 00       	jmp    801068d4 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801067fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106804:	85 c0                	test   %eax,%eax
80106806:	74 11                	je     80106819 <trap+0x13c>
80106808:	8b 45 08             	mov    0x8(%ebp),%eax
8010680b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010680f:	0f b7 c0             	movzwl %ax,%eax
80106812:	83 e0 03             	and    $0x3,%eax
80106815:	85 c0                	test   %eax,%eax
80106817:	75 46                	jne    8010685f <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106819:	e8 1e fd ff ff       	call   8010653c <rcr2>
8010681e:	8b 55 08             	mov    0x8(%ebp),%edx
80106821:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106824:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010682b:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010682e:	0f b6 ca             	movzbl %dl,%ecx
80106831:	8b 55 08             	mov    0x8(%ebp),%edx
80106834:	8b 52 30             	mov    0x30(%edx),%edx
80106837:	89 44 24 10          	mov    %eax,0x10(%esp)
8010683b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010683f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106843:	89 54 24 04          	mov    %edx,0x4(%esp)
80106847:	c7 04 24 04 89 10 80 	movl   $0x80108904,(%esp)
8010684e:	e8 4d 9b ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106853:	c7 04 24 36 89 10 80 	movl   $0x80108936,(%esp)
8010685a:	e8 db 9c ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010685f:	e8 d8 fc ff ff       	call   8010653c <rcr2>
80106864:	89 c2                	mov    %eax,%edx
80106866:	8b 45 08             	mov    0x8(%ebp),%eax
80106869:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010686c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106872:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106875:	0f b6 f0             	movzbl %al,%esi
80106878:	8b 45 08             	mov    0x8(%ebp),%eax
8010687b:	8b 58 34             	mov    0x34(%eax),%ebx
8010687e:	8b 45 08             	mov    0x8(%ebp),%eax
80106881:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106884:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010688a:	83 c0 6c             	add    $0x6c,%eax
8010688d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106890:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106896:	8b 40 10             	mov    0x10(%eax),%eax
80106899:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010689d:	89 7c 24 18          	mov    %edi,0x18(%esp)
801068a1:	89 74 24 14          	mov    %esi,0x14(%esp)
801068a5:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801068a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801068ad:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801068b0:	89 74 24 08          	mov    %esi,0x8(%esp)
801068b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801068b8:	c7 04 24 3c 89 10 80 	movl   $0x8010893c,(%esp)
801068bf:	e8 dc 9a ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801068c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068ca:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801068d1:	eb 01                	jmp    801068d4 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801068d3:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801068d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068da:	85 c0                	test   %eax,%eax
801068dc:	74 24                	je     80106902 <trap+0x225>
801068de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068e4:	8b 40 24             	mov    0x24(%eax),%eax
801068e7:	85 c0                	test   %eax,%eax
801068e9:	74 17                	je     80106902 <trap+0x225>
801068eb:	8b 45 08             	mov    0x8(%ebp),%eax
801068ee:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801068f2:	0f b7 c0             	movzwl %ax,%eax
801068f5:	83 e0 03             	and    $0x3,%eax
801068f8:	83 f8 03             	cmp    $0x3,%eax
801068fb:	75 05                	jne    80106902 <trap+0x225>
    exit();
801068fd:	e8 70 de ff ff       	call   80104772 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106902:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106908:	85 c0                	test   %eax,%eax
8010690a:	74 1e                	je     8010692a <trap+0x24d>
8010690c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106912:	8b 40 0c             	mov    0xc(%eax),%eax
80106915:	83 f8 04             	cmp    $0x4,%eax
80106918:	75 10                	jne    8010692a <trap+0x24d>
8010691a:	8b 45 08             	mov    0x8(%ebp),%eax
8010691d:	8b 40 30             	mov    0x30(%eax),%eax
80106920:	83 f8 20             	cmp    $0x20,%eax
80106923:	75 05                	jne    8010692a <trap+0x24d>
    yield();
80106925:	e8 45 e2 ff ff       	call   80104b6f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010692a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106930:	85 c0                	test   %eax,%eax
80106932:	74 24                	je     80106958 <trap+0x27b>
80106934:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010693a:	8b 40 24             	mov    0x24(%eax),%eax
8010693d:	85 c0                	test   %eax,%eax
8010693f:	74 17                	je     80106958 <trap+0x27b>
80106941:	8b 45 08             	mov    0x8(%ebp),%eax
80106944:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106948:	0f b7 c0             	movzwl %ax,%eax
8010694b:	83 e0 03             	and    $0x3,%eax
8010694e:	83 f8 03             	cmp    $0x3,%eax
80106951:	75 05                	jne    80106958 <trap+0x27b>
    exit();
80106953:	e8 1a de ff ff       	call   80104772 <exit>
}
80106958:	83 c4 3c             	add    $0x3c,%esp
8010695b:	5b                   	pop    %ebx
8010695c:	5e                   	pop    %esi
8010695d:	5f                   	pop    %edi
8010695e:	5d                   	pop    %ebp
8010695f:	c3                   	ret    

80106960 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106960:	55                   	push   %ebp
80106961:	89 e5                	mov    %esp,%ebp
80106963:	83 ec 14             	sub    $0x14,%esp
80106966:	8b 45 08             	mov    0x8(%ebp),%eax
80106969:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010696d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106971:	89 c2                	mov    %eax,%edx
80106973:	ec                   	in     (%dx),%al
80106974:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106977:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010697b:	c9                   	leave  
8010697c:	c3                   	ret    

8010697d <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010697d:	55                   	push   %ebp
8010697e:	89 e5                	mov    %esp,%ebp
80106980:	83 ec 08             	sub    $0x8,%esp
80106983:	8b 55 08             	mov    0x8(%ebp),%edx
80106986:	8b 45 0c             	mov    0xc(%ebp),%eax
80106989:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010698d:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106990:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106994:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106998:	ee                   	out    %al,(%dx)
}
80106999:	c9                   	leave  
8010699a:	c3                   	ret    

8010699b <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
8010699b:	55                   	push   %ebp
8010699c:	89 e5                	mov    %esp,%ebp
8010699e:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801069a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801069a8:	00 
801069a9:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801069b0:	e8 c8 ff ff ff       	call   8010697d <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801069b5:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801069bc:	00 
801069bd:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801069c4:	e8 b4 ff ff ff       	call   8010697d <outb>
  outb(COM1+0, 115200/9600);
801069c9:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801069d0:	00 
801069d1:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801069d8:	e8 a0 ff ff ff       	call   8010697d <outb>
  outb(COM1+1, 0);
801069dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801069e4:	00 
801069e5:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801069ec:	e8 8c ff ff ff       	call   8010697d <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801069f1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801069f8:	00 
801069f9:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106a00:	e8 78 ff ff ff       	call   8010697d <outb>
  outb(COM1+4, 0);
80106a05:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a0c:	00 
80106a0d:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106a14:	e8 64 ff ff ff       	call   8010697d <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106a19:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106a20:	00 
80106a21:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106a28:	e8 50 ff ff ff       	call   8010697d <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106a2d:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106a34:	e8 27 ff ff ff       	call   80106960 <inb>
80106a39:	3c ff                	cmp    $0xff,%al
80106a3b:	75 02                	jne    80106a3f <uartinit+0xa4>
    return;
80106a3d:	eb 6a                	jmp    80106aa9 <uartinit+0x10e>
  uart = 1;
80106a3f:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106a46:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106a49:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106a50:	e8 0b ff ff ff       	call   80106960 <inb>
  inb(COM1+0);
80106a55:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106a5c:	e8 ff fe ff ff       	call   80106960 <inb>
  picenable(IRQ_COM1);
80106a61:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106a68:	e8 47 d3 ff ff       	call   80103db4 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106a6d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a74:	00 
80106a75:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106a7c:	e8 dc be ff ff       	call   8010295d <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106a81:	c7 45 f4 00 8a 10 80 	movl   $0x80108a00,-0xc(%ebp)
80106a88:	eb 15                	jmp    80106a9f <uartinit+0x104>
    uartputc(*p);
80106a8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8d:	0f b6 00             	movzbl (%eax),%eax
80106a90:	0f be c0             	movsbl %al,%eax
80106a93:	89 04 24             	mov    %eax,(%esp)
80106a96:	e8 10 00 00 00       	call   80106aab <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106a9b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa2:	0f b6 00             	movzbl (%eax),%eax
80106aa5:	84 c0                	test   %al,%al
80106aa7:	75 e1                	jne    80106a8a <uartinit+0xef>
    uartputc(*p);
}
80106aa9:	c9                   	leave  
80106aaa:	c3                   	ret    

80106aab <uartputc>:

void
uartputc(int c)
{
80106aab:	55                   	push   %ebp
80106aac:	89 e5                	mov    %esp,%ebp
80106aae:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106ab1:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106ab6:	85 c0                	test   %eax,%eax
80106ab8:	75 02                	jne    80106abc <uartputc+0x11>
    return;
80106aba:	eb 4b                	jmp    80106b07 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106abc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106ac3:	eb 10                	jmp    80106ad5 <uartputc+0x2a>
    microdelay(10);
80106ac5:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106acc:	e8 24 c4 ff ff       	call   80102ef5 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106ad1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106ad5:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106ad9:	7f 16                	jg     80106af1 <uartputc+0x46>
80106adb:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106ae2:	e8 79 fe ff ff       	call   80106960 <inb>
80106ae7:	0f b6 c0             	movzbl %al,%eax
80106aea:	83 e0 20             	and    $0x20,%eax
80106aed:	85 c0                	test   %eax,%eax
80106aef:	74 d4                	je     80106ac5 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106af1:	8b 45 08             	mov    0x8(%ebp),%eax
80106af4:	0f b6 c0             	movzbl %al,%eax
80106af7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106afb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b02:	e8 76 fe ff ff       	call   8010697d <outb>
}
80106b07:	c9                   	leave  
80106b08:	c3                   	ret    

80106b09 <uartgetc>:

static int
uartgetc(void)
{
80106b09:	55                   	push   %ebp
80106b0a:	89 e5                	mov    %esp,%ebp
80106b0c:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106b0f:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106b14:	85 c0                	test   %eax,%eax
80106b16:	75 07                	jne    80106b1f <uartgetc+0x16>
    return -1;
80106b18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b1d:	eb 2c                	jmp    80106b4b <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106b1f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b26:	e8 35 fe ff ff       	call   80106960 <inb>
80106b2b:	0f b6 c0             	movzbl %al,%eax
80106b2e:	83 e0 01             	and    $0x1,%eax
80106b31:	85 c0                	test   %eax,%eax
80106b33:	75 07                	jne    80106b3c <uartgetc+0x33>
    return -1;
80106b35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b3a:	eb 0f                	jmp    80106b4b <uartgetc+0x42>
  return inb(COM1+0);
80106b3c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b43:	e8 18 fe ff ff       	call   80106960 <inb>
80106b48:	0f b6 c0             	movzbl %al,%eax
}
80106b4b:	c9                   	leave  
80106b4c:	c3                   	ret    

80106b4d <uartintr>:

void
uartintr(void)
{
80106b4d:	55                   	push   %ebp
80106b4e:	89 e5                	mov    %esp,%ebp
80106b50:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106b53:	c7 04 24 09 6b 10 80 	movl   $0x80106b09,(%esp)
80106b5a:	e8 4e 9c ff ff       	call   801007ad <consoleintr>
}
80106b5f:	c9                   	leave  
80106b60:	c3                   	ret    

80106b61 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106b61:	6a 00                	push   $0x0
  pushl $0
80106b63:	6a 00                	push   $0x0
  jmp alltraps
80106b65:	e9 7e f9 ff ff       	jmp    801064e8 <alltraps>

80106b6a <vector1>:
.globl vector1
vector1:
  pushl $0
80106b6a:	6a 00                	push   $0x0
  pushl $1
80106b6c:	6a 01                	push   $0x1
  jmp alltraps
80106b6e:	e9 75 f9 ff ff       	jmp    801064e8 <alltraps>

80106b73 <vector2>:
.globl vector2
vector2:
  pushl $0
80106b73:	6a 00                	push   $0x0
  pushl $2
80106b75:	6a 02                	push   $0x2
  jmp alltraps
80106b77:	e9 6c f9 ff ff       	jmp    801064e8 <alltraps>

80106b7c <vector3>:
.globl vector3
vector3:
  pushl $0
80106b7c:	6a 00                	push   $0x0
  pushl $3
80106b7e:	6a 03                	push   $0x3
  jmp alltraps
80106b80:	e9 63 f9 ff ff       	jmp    801064e8 <alltraps>

80106b85 <vector4>:
.globl vector4
vector4:
  pushl $0
80106b85:	6a 00                	push   $0x0
  pushl $4
80106b87:	6a 04                	push   $0x4
  jmp alltraps
80106b89:	e9 5a f9 ff ff       	jmp    801064e8 <alltraps>

80106b8e <vector5>:
.globl vector5
vector5:
  pushl $0
80106b8e:	6a 00                	push   $0x0
  pushl $5
80106b90:	6a 05                	push   $0x5
  jmp alltraps
80106b92:	e9 51 f9 ff ff       	jmp    801064e8 <alltraps>

80106b97 <vector6>:
.globl vector6
vector6:
  pushl $0
80106b97:	6a 00                	push   $0x0
  pushl $6
80106b99:	6a 06                	push   $0x6
  jmp alltraps
80106b9b:	e9 48 f9 ff ff       	jmp    801064e8 <alltraps>

80106ba0 <vector7>:
.globl vector7
vector7:
  pushl $0
80106ba0:	6a 00                	push   $0x0
  pushl $7
80106ba2:	6a 07                	push   $0x7
  jmp alltraps
80106ba4:	e9 3f f9 ff ff       	jmp    801064e8 <alltraps>

80106ba9 <vector8>:
.globl vector8
vector8:
  pushl $8
80106ba9:	6a 08                	push   $0x8
  jmp alltraps
80106bab:	e9 38 f9 ff ff       	jmp    801064e8 <alltraps>

80106bb0 <vector9>:
.globl vector9
vector9:
  pushl $0
80106bb0:	6a 00                	push   $0x0
  pushl $9
80106bb2:	6a 09                	push   $0x9
  jmp alltraps
80106bb4:	e9 2f f9 ff ff       	jmp    801064e8 <alltraps>

80106bb9 <vector10>:
.globl vector10
vector10:
  pushl $10
80106bb9:	6a 0a                	push   $0xa
  jmp alltraps
80106bbb:	e9 28 f9 ff ff       	jmp    801064e8 <alltraps>

80106bc0 <vector11>:
.globl vector11
vector11:
  pushl $11
80106bc0:	6a 0b                	push   $0xb
  jmp alltraps
80106bc2:	e9 21 f9 ff ff       	jmp    801064e8 <alltraps>

80106bc7 <vector12>:
.globl vector12
vector12:
  pushl $12
80106bc7:	6a 0c                	push   $0xc
  jmp alltraps
80106bc9:	e9 1a f9 ff ff       	jmp    801064e8 <alltraps>

80106bce <vector13>:
.globl vector13
vector13:
  pushl $13
80106bce:	6a 0d                	push   $0xd
  jmp alltraps
80106bd0:	e9 13 f9 ff ff       	jmp    801064e8 <alltraps>

80106bd5 <vector14>:
.globl vector14
vector14:
  pushl $14
80106bd5:	6a 0e                	push   $0xe
  jmp alltraps
80106bd7:	e9 0c f9 ff ff       	jmp    801064e8 <alltraps>

80106bdc <vector15>:
.globl vector15
vector15:
  pushl $0
80106bdc:	6a 00                	push   $0x0
  pushl $15
80106bde:	6a 0f                	push   $0xf
  jmp alltraps
80106be0:	e9 03 f9 ff ff       	jmp    801064e8 <alltraps>

80106be5 <vector16>:
.globl vector16
vector16:
  pushl $0
80106be5:	6a 00                	push   $0x0
  pushl $16
80106be7:	6a 10                	push   $0x10
  jmp alltraps
80106be9:	e9 fa f8 ff ff       	jmp    801064e8 <alltraps>

80106bee <vector17>:
.globl vector17
vector17:
  pushl $17
80106bee:	6a 11                	push   $0x11
  jmp alltraps
80106bf0:	e9 f3 f8 ff ff       	jmp    801064e8 <alltraps>

80106bf5 <vector18>:
.globl vector18
vector18:
  pushl $0
80106bf5:	6a 00                	push   $0x0
  pushl $18
80106bf7:	6a 12                	push   $0x12
  jmp alltraps
80106bf9:	e9 ea f8 ff ff       	jmp    801064e8 <alltraps>

80106bfe <vector19>:
.globl vector19
vector19:
  pushl $0
80106bfe:	6a 00                	push   $0x0
  pushl $19
80106c00:	6a 13                	push   $0x13
  jmp alltraps
80106c02:	e9 e1 f8 ff ff       	jmp    801064e8 <alltraps>

80106c07 <vector20>:
.globl vector20
vector20:
  pushl $0
80106c07:	6a 00                	push   $0x0
  pushl $20
80106c09:	6a 14                	push   $0x14
  jmp alltraps
80106c0b:	e9 d8 f8 ff ff       	jmp    801064e8 <alltraps>

80106c10 <vector21>:
.globl vector21
vector21:
  pushl $0
80106c10:	6a 00                	push   $0x0
  pushl $21
80106c12:	6a 15                	push   $0x15
  jmp alltraps
80106c14:	e9 cf f8 ff ff       	jmp    801064e8 <alltraps>

80106c19 <vector22>:
.globl vector22
vector22:
  pushl $0
80106c19:	6a 00                	push   $0x0
  pushl $22
80106c1b:	6a 16                	push   $0x16
  jmp alltraps
80106c1d:	e9 c6 f8 ff ff       	jmp    801064e8 <alltraps>

80106c22 <vector23>:
.globl vector23
vector23:
  pushl $0
80106c22:	6a 00                	push   $0x0
  pushl $23
80106c24:	6a 17                	push   $0x17
  jmp alltraps
80106c26:	e9 bd f8 ff ff       	jmp    801064e8 <alltraps>

80106c2b <vector24>:
.globl vector24
vector24:
  pushl $0
80106c2b:	6a 00                	push   $0x0
  pushl $24
80106c2d:	6a 18                	push   $0x18
  jmp alltraps
80106c2f:	e9 b4 f8 ff ff       	jmp    801064e8 <alltraps>

80106c34 <vector25>:
.globl vector25
vector25:
  pushl $0
80106c34:	6a 00                	push   $0x0
  pushl $25
80106c36:	6a 19                	push   $0x19
  jmp alltraps
80106c38:	e9 ab f8 ff ff       	jmp    801064e8 <alltraps>

80106c3d <vector26>:
.globl vector26
vector26:
  pushl $0
80106c3d:	6a 00                	push   $0x0
  pushl $26
80106c3f:	6a 1a                	push   $0x1a
  jmp alltraps
80106c41:	e9 a2 f8 ff ff       	jmp    801064e8 <alltraps>

80106c46 <vector27>:
.globl vector27
vector27:
  pushl $0
80106c46:	6a 00                	push   $0x0
  pushl $27
80106c48:	6a 1b                	push   $0x1b
  jmp alltraps
80106c4a:	e9 99 f8 ff ff       	jmp    801064e8 <alltraps>

80106c4f <vector28>:
.globl vector28
vector28:
  pushl $0
80106c4f:	6a 00                	push   $0x0
  pushl $28
80106c51:	6a 1c                	push   $0x1c
  jmp alltraps
80106c53:	e9 90 f8 ff ff       	jmp    801064e8 <alltraps>

80106c58 <vector29>:
.globl vector29
vector29:
  pushl $0
80106c58:	6a 00                	push   $0x0
  pushl $29
80106c5a:	6a 1d                	push   $0x1d
  jmp alltraps
80106c5c:	e9 87 f8 ff ff       	jmp    801064e8 <alltraps>

80106c61 <vector30>:
.globl vector30
vector30:
  pushl $0
80106c61:	6a 00                	push   $0x0
  pushl $30
80106c63:	6a 1e                	push   $0x1e
  jmp alltraps
80106c65:	e9 7e f8 ff ff       	jmp    801064e8 <alltraps>

80106c6a <vector31>:
.globl vector31
vector31:
  pushl $0
80106c6a:	6a 00                	push   $0x0
  pushl $31
80106c6c:	6a 1f                	push   $0x1f
  jmp alltraps
80106c6e:	e9 75 f8 ff ff       	jmp    801064e8 <alltraps>

80106c73 <vector32>:
.globl vector32
vector32:
  pushl $0
80106c73:	6a 00                	push   $0x0
  pushl $32
80106c75:	6a 20                	push   $0x20
  jmp alltraps
80106c77:	e9 6c f8 ff ff       	jmp    801064e8 <alltraps>

80106c7c <vector33>:
.globl vector33
vector33:
  pushl $0
80106c7c:	6a 00                	push   $0x0
  pushl $33
80106c7e:	6a 21                	push   $0x21
  jmp alltraps
80106c80:	e9 63 f8 ff ff       	jmp    801064e8 <alltraps>

80106c85 <vector34>:
.globl vector34
vector34:
  pushl $0
80106c85:	6a 00                	push   $0x0
  pushl $34
80106c87:	6a 22                	push   $0x22
  jmp alltraps
80106c89:	e9 5a f8 ff ff       	jmp    801064e8 <alltraps>

80106c8e <vector35>:
.globl vector35
vector35:
  pushl $0
80106c8e:	6a 00                	push   $0x0
  pushl $35
80106c90:	6a 23                	push   $0x23
  jmp alltraps
80106c92:	e9 51 f8 ff ff       	jmp    801064e8 <alltraps>

80106c97 <vector36>:
.globl vector36
vector36:
  pushl $0
80106c97:	6a 00                	push   $0x0
  pushl $36
80106c99:	6a 24                	push   $0x24
  jmp alltraps
80106c9b:	e9 48 f8 ff ff       	jmp    801064e8 <alltraps>

80106ca0 <vector37>:
.globl vector37
vector37:
  pushl $0
80106ca0:	6a 00                	push   $0x0
  pushl $37
80106ca2:	6a 25                	push   $0x25
  jmp alltraps
80106ca4:	e9 3f f8 ff ff       	jmp    801064e8 <alltraps>

80106ca9 <vector38>:
.globl vector38
vector38:
  pushl $0
80106ca9:	6a 00                	push   $0x0
  pushl $38
80106cab:	6a 26                	push   $0x26
  jmp alltraps
80106cad:	e9 36 f8 ff ff       	jmp    801064e8 <alltraps>

80106cb2 <vector39>:
.globl vector39
vector39:
  pushl $0
80106cb2:	6a 00                	push   $0x0
  pushl $39
80106cb4:	6a 27                	push   $0x27
  jmp alltraps
80106cb6:	e9 2d f8 ff ff       	jmp    801064e8 <alltraps>

80106cbb <vector40>:
.globl vector40
vector40:
  pushl $0
80106cbb:	6a 00                	push   $0x0
  pushl $40
80106cbd:	6a 28                	push   $0x28
  jmp alltraps
80106cbf:	e9 24 f8 ff ff       	jmp    801064e8 <alltraps>

80106cc4 <vector41>:
.globl vector41
vector41:
  pushl $0
80106cc4:	6a 00                	push   $0x0
  pushl $41
80106cc6:	6a 29                	push   $0x29
  jmp alltraps
80106cc8:	e9 1b f8 ff ff       	jmp    801064e8 <alltraps>

80106ccd <vector42>:
.globl vector42
vector42:
  pushl $0
80106ccd:	6a 00                	push   $0x0
  pushl $42
80106ccf:	6a 2a                	push   $0x2a
  jmp alltraps
80106cd1:	e9 12 f8 ff ff       	jmp    801064e8 <alltraps>

80106cd6 <vector43>:
.globl vector43
vector43:
  pushl $0
80106cd6:	6a 00                	push   $0x0
  pushl $43
80106cd8:	6a 2b                	push   $0x2b
  jmp alltraps
80106cda:	e9 09 f8 ff ff       	jmp    801064e8 <alltraps>

80106cdf <vector44>:
.globl vector44
vector44:
  pushl $0
80106cdf:	6a 00                	push   $0x0
  pushl $44
80106ce1:	6a 2c                	push   $0x2c
  jmp alltraps
80106ce3:	e9 00 f8 ff ff       	jmp    801064e8 <alltraps>

80106ce8 <vector45>:
.globl vector45
vector45:
  pushl $0
80106ce8:	6a 00                	push   $0x0
  pushl $45
80106cea:	6a 2d                	push   $0x2d
  jmp alltraps
80106cec:	e9 f7 f7 ff ff       	jmp    801064e8 <alltraps>

80106cf1 <vector46>:
.globl vector46
vector46:
  pushl $0
80106cf1:	6a 00                	push   $0x0
  pushl $46
80106cf3:	6a 2e                	push   $0x2e
  jmp alltraps
80106cf5:	e9 ee f7 ff ff       	jmp    801064e8 <alltraps>

80106cfa <vector47>:
.globl vector47
vector47:
  pushl $0
80106cfa:	6a 00                	push   $0x0
  pushl $47
80106cfc:	6a 2f                	push   $0x2f
  jmp alltraps
80106cfe:	e9 e5 f7 ff ff       	jmp    801064e8 <alltraps>

80106d03 <vector48>:
.globl vector48
vector48:
  pushl $0
80106d03:	6a 00                	push   $0x0
  pushl $48
80106d05:	6a 30                	push   $0x30
  jmp alltraps
80106d07:	e9 dc f7 ff ff       	jmp    801064e8 <alltraps>

80106d0c <vector49>:
.globl vector49
vector49:
  pushl $0
80106d0c:	6a 00                	push   $0x0
  pushl $49
80106d0e:	6a 31                	push   $0x31
  jmp alltraps
80106d10:	e9 d3 f7 ff ff       	jmp    801064e8 <alltraps>

80106d15 <vector50>:
.globl vector50
vector50:
  pushl $0
80106d15:	6a 00                	push   $0x0
  pushl $50
80106d17:	6a 32                	push   $0x32
  jmp alltraps
80106d19:	e9 ca f7 ff ff       	jmp    801064e8 <alltraps>

80106d1e <vector51>:
.globl vector51
vector51:
  pushl $0
80106d1e:	6a 00                	push   $0x0
  pushl $51
80106d20:	6a 33                	push   $0x33
  jmp alltraps
80106d22:	e9 c1 f7 ff ff       	jmp    801064e8 <alltraps>

80106d27 <vector52>:
.globl vector52
vector52:
  pushl $0
80106d27:	6a 00                	push   $0x0
  pushl $52
80106d29:	6a 34                	push   $0x34
  jmp alltraps
80106d2b:	e9 b8 f7 ff ff       	jmp    801064e8 <alltraps>

80106d30 <vector53>:
.globl vector53
vector53:
  pushl $0
80106d30:	6a 00                	push   $0x0
  pushl $53
80106d32:	6a 35                	push   $0x35
  jmp alltraps
80106d34:	e9 af f7 ff ff       	jmp    801064e8 <alltraps>

80106d39 <vector54>:
.globl vector54
vector54:
  pushl $0
80106d39:	6a 00                	push   $0x0
  pushl $54
80106d3b:	6a 36                	push   $0x36
  jmp alltraps
80106d3d:	e9 a6 f7 ff ff       	jmp    801064e8 <alltraps>

80106d42 <vector55>:
.globl vector55
vector55:
  pushl $0
80106d42:	6a 00                	push   $0x0
  pushl $55
80106d44:	6a 37                	push   $0x37
  jmp alltraps
80106d46:	e9 9d f7 ff ff       	jmp    801064e8 <alltraps>

80106d4b <vector56>:
.globl vector56
vector56:
  pushl $0
80106d4b:	6a 00                	push   $0x0
  pushl $56
80106d4d:	6a 38                	push   $0x38
  jmp alltraps
80106d4f:	e9 94 f7 ff ff       	jmp    801064e8 <alltraps>

80106d54 <vector57>:
.globl vector57
vector57:
  pushl $0
80106d54:	6a 00                	push   $0x0
  pushl $57
80106d56:	6a 39                	push   $0x39
  jmp alltraps
80106d58:	e9 8b f7 ff ff       	jmp    801064e8 <alltraps>

80106d5d <vector58>:
.globl vector58
vector58:
  pushl $0
80106d5d:	6a 00                	push   $0x0
  pushl $58
80106d5f:	6a 3a                	push   $0x3a
  jmp alltraps
80106d61:	e9 82 f7 ff ff       	jmp    801064e8 <alltraps>

80106d66 <vector59>:
.globl vector59
vector59:
  pushl $0
80106d66:	6a 00                	push   $0x0
  pushl $59
80106d68:	6a 3b                	push   $0x3b
  jmp alltraps
80106d6a:	e9 79 f7 ff ff       	jmp    801064e8 <alltraps>

80106d6f <vector60>:
.globl vector60
vector60:
  pushl $0
80106d6f:	6a 00                	push   $0x0
  pushl $60
80106d71:	6a 3c                	push   $0x3c
  jmp alltraps
80106d73:	e9 70 f7 ff ff       	jmp    801064e8 <alltraps>

80106d78 <vector61>:
.globl vector61
vector61:
  pushl $0
80106d78:	6a 00                	push   $0x0
  pushl $61
80106d7a:	6a 3d                	push   $0x3d
  jmp alltraps
80106d7c:	e9 67 f7 ff ff       	jmp    801064e8 <alltraps>

80106d81 <vector62>:
.globl vector62
vector62:
  pushl $0
80106d81:	6a 00                	push   $0x0
  pushl $62
80106d83:	6a 3e                	push   $0x3e
  jmp alltraps
80106d85:	e9 5e f7 ff ff       	jmp    801064e8 <alltraps>

80106d8a <vector63>:
.globl vector63
vector63:
  pushl $0
80106d8a:	6a 00                	push   $0x0
  pushl $63
80106d8c:	6a 3f                	push   $0x3f
  jmp alltraps
80106d8e:	e9 55 f7 ff ff       	jmp    801064e8 <alltraps>

80106d93 <vector64>:
.globl vector64
vector64:
  pushl $0
80106d93:	6a 00                	push   $0x0
  pushl $64
80106d95:	6a 40                	push   $0x40
  jmp alltraps
80106d97:	e9 4c f7 ff ff       	jmp    801064e8 <alltraps>

80106d9c <vector65>:
.globl vector65
vector65:
  pushl $0
80106d9c:	6a 00                	push   $0x0
  pushl $65
80106d9e:	6a 41                	push   $0x41
  jmp alltraps
80106da0:	e9 43 f7 ff ff       	jmp    801064e8 <alltraps>

80106da5 <vector66>:
.globl vector66
vector66:
  pushl $0
80106da5:	6a 00                	push   $0x0
  pushl $66
80106da7:	6a 42                	push   $0x42
  jmp alltraps
80106da9:	e9 3a f7 ff ff       	jmp    801064e8 <alltraps>

80106dae <vector67>:
.globl vector67
vector67:
  pushl $0
80106dae:	6a 00                	push   $0x0
  pushl $67
80106db0:	6a 43                	push   $0x43
  jmp alltraps
80106db2:	e9 31 f7 ff ff       	jmp    801064e8 <alltraps>

80106db7 <vector68>:
.globl vector68
vector68:
  pushl $0
80106db7:	6a 00                	push   $0x0
  pushl $68
80106db9:	6a 44                	push   $0x44
  jmp alltraps
80106dbb:	e9 28 f7 ff ff       	jmp    801064e8 <alltraps>

80106dc0 <vector69>:
.globl vector69
vector69:
  pushl $0
80106dc0:	6a 00                	push   $0x0
  pushl $69
80106dc2:	6a 45                	push   $0x45
  jmp alltraps
80106dc4:	e9 1f f7 ff ff       	jmp    801064e8 <alltraps>

80106dc9 <vector70>:
.globl vector70
vector70:
  pushl $0
80106dc9:	6a 00                	push   $0x0
  pushl $70
80106dcb:	6a 46                	push   $0x46
  jmp alltraps
80106dcd:	e9 16 f7 ff ff       	jmp    801064e8 <alltraps>

80106dd2 <vector71>:
.globl vector71
vector71:
  pushl $0
80106dd2:	6a 00                	push   $0x0
  pushl $71
80106dd4:	6a 47                	push   $0x47
  jmp alltraps
80106dd6:	e9 0d f7 ff ff       	jmp    801064e8 <alltraps>

80106ddb <vector72>:
.globl vector72
vector72:
  pushl $0
80106ddb:	6a 00                	push   $0x0
  pushl $72
80106ddd:	6a 48                	push   $0x48
  jmp alltraps
80106ddf:	e9 04 f7 ff ff       	jmp    801064e8 <alltraps>

80106de4 <vector73>:
.globl vector73
vector73:
  pushl $0
80106de4:	6a 00                	push   $0x0
  pushl $73
80106de6:	6a 49                	push   $0x49
  jmp alltraps
80106de8:	e9 fb f6 ff ff       	jmp    801064e8 <alltraps>

80106ded <vector74>:
.globl vector74
vector74:
  pushl $0
80106ded:	6a 00                	push   $0x0
  pushl $74
80106def:	6a 4a                	push   $0x4a
  jmp alltraps
80106df1:	e9 f2 f6 ff ff       	jmp    801064e8 <alltraps>

80106df6 <vector75>:
.globl vector75
vector75:
  pushl $0
80106df6:	6a 00                	push   $0x0
  pushl $75
80106df8:	6a 4b                	push   $0x4b
  jmp alltraps
80106dfa:	e9 e9 f6 ff ff       	jmp    801064e8 <alltraps>

80106dff <vector76>:
.globl vector76
vector76:
  pushl $0
80106dff:	6a 00                	push   $0x0
  pushl $76
80106e01:	6a 4c                	push   $0x4c
  jmp alltraps
80106e03:	e9 e0 f6 ff ff       	jmp    801064e8 <alltraps>

80106e08 <vector77>:
.globl vector77
vector77:
  pushl $0
80106e08:	6a 00                	push   $0x0
  pushl $77
80106e0a:	6a 4d                	push   $0x4d
  jmp alltraps
80106e0c:	e9 d7 f6 ff ff       	jmp    801064e8 <alltraps>

80106e11 <vector78>:
.globl vector78
vector78:
  pushl $0
80106e11:	6a 00                	push   $0x0
  pushl $78
80106e13:	6a 4e                	push   $0x4e
  jmp alltraps
80106e15:	e9 ce f6 ff ff       	jmp    801064e8 <alltraps>

80106e1a <vector79>:
.globl vector79
vector79:
  pushl $0
80106e1a:	6a 00                	push   $0x0
  pushl $79
80106e1c:	6a 4f                	push   $0x4f
  jmp alltraps
80106e1e:	e9 c5 f6 ff ff       	jmp    801064e8 <alltraps>

80106e23 <vector80>:
.globl vector80
vector80:
  pushl $0
80106e23:	6a 00                	push   $0x0
  pushl $80
80106e25:	6a 50                	push   $0x50
  jmp alltraps
80106e27:	e9 bc f6 ff ff       	jmp    801064e8 <alltraps>

80106e2c <vector81>:
.globl vector81
vector81:
  pushl $0
80106e2c:	6a 00                	push   $0x0
  pushl $81
80106e2e:	6a 51                	push   $0x51
  jmp alltraps
80106e30:	e9 b3 f6 ff ff       	jmp    801064e8 <alltraps>

80106e35 <vector82>:
.globl vector82
vector82:
  pushl $0
80106e35:	6a 00                	push   $0x0
  pushl $82
80106e37:	6a 52                	push   $0x52
  jmp alltraps
80106e39:	e9 aa f6 ff ff       	jmp    801064e8 <alltraps>

80106e3e <vector83>:
.globl vector83
vector83:
  pushl $0
80106e3e:	6a 00                	push   $0x0
  pushl $83
80106e40:	6a 53                	push   $0x53
  jmp alltraps
80106e42:	e9 a1 f6 ff ff       	jmp    801064e8 <alltraps>

80106e47 <vector84>:
.globl vector84
vector84:
  pushl $0
80106e47:	6a 00                	push   $0x0
  pushl $84
80106e49:	6a 54                	push   $0x54
  jmp alltraps
80106e4b:	e9 98 f6 ff ff       	jmp    801064e8 <alltraps>

80106e50 <vector85>:
.globl vector85
vector85:
  pushl $0
80106e50:	6a 00                	push   $0x0
  pushl $85
80106e52:	6a 55                	push   $0x55
  jmp alltraps
80106e54:	e9 8f f6 ff ff       	jmp    801064e8 <alltraps>

80106e59 <vector86>:
.globl vector86
vector86:
  pushl $0
80106e59:	6a 00                	push   $0x0
  pushl $86
80106e5b:	6a 56                	push   $0x56
  jmp alltraps
80106e5d:	e9 86 f6 ff ff       	jmp    801064e8 <alltraps>

80106e62 <vector87>:
.globl vector87
vector87:
  pushl $0
80106e62:	6a 00                	push   $0x0
  pushl $87
80106e64:	6a 57                	push   $0x57
  jmp alltraps
80106e66:	e9 7d f6 ff ff       	jmp    801064e8 <alltraps>

80106e6b <vector88>:
.globl vector88
vector88:
  pushl $0
80106e6b:	6a 00                	push   $0x0
  pushl $88
80106e6d:	6a 58                	push   $0x58
  jmp alltraps
80106e6f:	e9 74 f6 ff ff       	jmp    801064e8 <alltraps>

80106e74 <vector89>:
.globl vector89
vector89:
  pushl $0
80106e74:	6a 00                	push   $0x0
  pushl $89
80106e76:	6a 59                	push   $0x59
  jmp alltraps
80106e78:	e9 6b f6 ff ff       	jmp    801064e8 <alltraps>

80106e7d <vector90>:
.globl vector90
vector90:
  pushl $0
80106e7d:	6a 00                	push   $0x0
  pushl $90
80106e7f:	6a 5a                	push   $0x5a
  jmp alltraps
80106e81:	e9 62 f6 ff ff       	jmp    801064e8 <alltraps>

80106e86 <vector91>:
.globl vector91
vector91:
  pushl $0
80106e86:	6a 00                	push   $0x0
  pushl $91
80106e88:	6a 5b                	push   $0x5b
  jmp alltraps
80106e8a:	e9 59 f6 ff ff       	jmp    801064e8 <alltraps>

80106e8f <vector92>:
.globl vector92
vector92:
  pushl $0
80106e8f:	6a 00                	push   $0x0
  pushl $92
80106e91:	6a 5c                	push   $0x5c
  jmp alltraps
80106e93:	e9 50 f6 ff ff       	jmp    801064e8 <alltraps>

80106e98 <vector93>:
.globl vector93
vector93:
  pushl $0
80106e98:	6a 00                	push   $0x0
  pushl $93
80106e9a:	6a 5d                	push   $0x5d
  jmp alltraps
80106e9c:	e9 47 f6 ff ff       	jmp    801064e8 <alltraps>

80106ea1 <vector94>:
.globl vector94
vector94:
  pushl $0
80106ea1:	6a 00                	push   $0x0
  pushl $94
80106ea3:	6a 5e                	push   $0x5e
  jmp alltraps
80106ea5:	e9 3e f6 ff ff       	jmp    801064e8 <alltraps>

80106eaa <vector95>:
.globl vector95
vector95:
  pushl $0
80106eaa:	6a 00                	push   $0x0
  pushl $95
80106eac:	6a 5f                	push   $0x5f
  jmp alltraps
80106eae:	e9 35 f6 ff ff       	jmp    801064e8 <alltraps>

80106eb3 <vector96>:
.globl vector96
vector96:
  pushl $0
80106eb3:	6a 00                	push   $0x0
  pushl $96
80106eb5:	6a 60                	push   $0x60
  jmp alltraps
80106eb7:	e9 2c f6 ff ff       	jmp    801064e8 <alltraps>

80106ebc <vector97>:
.globl vector97
vector97:
  pushl $0
80106ebc:	6a 00                	push   $0x0
  pushl $97
80106ebe:	6a 61                	push   $0x61
  jmp alltraps
80106ec0:	e9 23 f6 ff ff       	jmp    801064e8 <alltraps>

80106ec5 <vector98>:
.globl vector98
vector98:
  pushl $0
80106ec5:	6a 00                	push   $0x0
  pushl $98
80106ec7:	6a 62                	push   $0x62
  jmp alltraps
80106ec9:	e9 1a f6 ff ff       	jmp    801064e8 <alltraps>

80106ece <vector99>:
.globl vector99
vector99:
  pushl $0
80106ece:	6a 00                	push   $0x0
  pushl $99
80106ed0:	6a 63                	push   $0x63
  jmp alltraps
80106ed2:	e9 11 f6 ff ff       	jmp    801064e8 <alltraps>

80106ed7 <vector100>:
.globl vector100
vector100:
  pushl $0
80106ed7:	6a 00                	push   $0x0
  pushl $100
80106ed9:	6a 64                	push   $0x64
  jmp alltraps
80106edb:	e9 08 f6 ff ff       	jmp    801064e8 <alltraps>

80106ee0 <vector101>:
.globl vector101
vector101:
  pushl $0
80106ee0:	6a 00                	push   $0x0
  pushl $101
80106ee2:	6a 65                	push   $0x65
  jmp alltraps
80106ee4:	e9 ff f5 ff ff       	jmp    801064e8 <alltraps>

80106ee9 <vector102>:
.globl vector102
vector102:
  pushl $0
80106ee9:	6a 00                	push   $0x0
  pushl $102
80106eeb:	6a 66                	push   $0x66
  jmp alltraps
80106eed:	e9 f6 f5 ff ff       	jmp    801064e8 <alltraps>

80106ef2 <vector103>:
.globl vector103
vector103:
  pushl $0
80106ef2:	6a 00                	push   $0x0
  pushl $103
80106ef4:	6a 67                	push   $0x67
  jmp alltraps
80106ef6:	e9 ed f5 ff ff       	jmp    801064e8 <alltraps>

80106efb <vector104>:
.globl vector104
vector104:
  pushl $0
80106efb:	6a 00                	push   $0x0
  pushl $104
80106efd:	6a 68                	push   $0x68
  jmp alltraps
80106eff:	e9 e4 f5 ff ff       	jmp    801064e8 <alltraps>

80106f04 <vector105>:
.globl vector105
vector105:
  pushl $0
80106f04:	6a 00                	push   $0x0
  pushl $105
80106f06:	6a 69                	push   $0x69
  jmp alltraps
80106f08:	e9 db f5 ff ff       	jmp    801064e8 <alltraps>

80106f0d <vector106>:
.globl vector106
vector106:
  pushl $0
80106f0d:	6a 00                	push   $0x0
  pushl $106
80106f0f:	6a 6a                	push   $0x6a
  jmp alltraps
80106f11:	e9 d2 f5 ff ff       	jmp    801064e8 <alltraps>

80106f16 <vector107>:
.globl vector107
vector107:
  pushl $0
80106f16:	6a 00                	push   $0x0
  pushl $107
80106f18:	6a 6b                	push   $0x6b
  jmp alltraps
80106f1a:	e9 c9 f5 ff ff       	jmp    801064e8 <alltraps>

80106f1f <vector108>:
.globl vector108
vector108:
  pushl $0
80106f1f:	6a 00                	push   $0x0
  pushl $108
80106f21:	6a 6c                	push   $0x6c
  jmp alltraps
80106f23:	e9 c0 f5 ff ff       	jmp    801064e8 <alltraps>

80106f28 <vector109>:
.globl vector109
vector109:
  pushl $0
80106f28:	6a 00                	push   $0x0
  pushl $109
80106f2a:	6a 6d                	push   $0x6d
  jmp alltraps
80106f2c:	e9 b7 f5 ff ff       	jmp    801064e8 <alltraps>

80106f31 <vector110>:
.globl vector110
vector110:
  pushl $0
80106f31:	6a 00                	push   $0x0
  pushl $110
80106f33:	6a 6e                	push   $0x6e
  jmp alltraps
80106f35:	e9 ae f5 ff ff       	jmp    801064e8 <alltraps>

80106f3a <vector111>:
.globl vector111
vector111:
  pushl $0
80106f3a:	6a 00                	push   $0x0
  pushl $111
80106f3c:	6a 6f                	push   $0x6f
  jmp alltraps
80106f3e:	e9 a5 f5 ff ff       	jmp    801064e8 <alltraps>

80106f43 <vector112>:
.globl vector112
vector112:
  pushl $0
80106f43:	6a 00                	push   $0x0
  pushl $112
80106f45:	6a 70                	push   $0x70
  jmp alltraps
80106f47:	e9 9c f5 ff ff       	jmp    801064e8 <alltraps>

80106f4c <vector113>:
.globl vector113
vector113:
  pushl $0
80106f4c:	6a 00                	push   $0x0
  pushl $113
80106f4e:	6a 71                	push   $0x71
  jmp alltraps
80106f50:	e9 93 f5 ff ff       	jmp    801064e8 <alltraps>

80106f55 <vector114>:
.globl vector114
vector114:
  pushl $0
80106f55:	6a 00                	push   $0x0
  pushl $114
80106f57:	6a 72                	push   $0x72
  jmp alltraps
80106f59:	e9 8a f5 ff ff       	jmp    801064e8 <alltraps>

80106f5e <vector115>:
.globl vector115
vector115:
  pushl $0
80106f5e:	6a 00                	push   $0x0
  pushl $115
80106f60:	6a 73                	push   $0x73
  jmp alltraps
80106f62:	e9 81 f5 ff ff       	jmp    801064e8 <alltraps>

80106f67 <vector116>:
.globl vector116
vector116:
  pushl $0
80106f67:	6a 00                	push   $0x0
  pushl $116
80106f69:	6a 74                	push   $0x74
  jmp alltraps
80106f6b:	e9 78 f5 ff ff       	jmp    801064e8 <alltraps>

80106f70 <vector117>:
.globl vector117
vector117:
  pushl $0
80106f70:	6a 00                	push   $0x0
  pushl $117
80106f72:	6a 75                	push   $0x75
  jmp alltraps
80106f74:	e9 6f f5 ff ff       	jmp    801064e8 <alltraps>

80106f79 <vector118>:
.globl vector118
vector118:
  pushl $0
80106f79:	6a 00                	push   $0x0
  pushl $118
80106f7b:	6a 76                	push   $0x76
  jmp alltraps
80106f7d:	e9 66 f5 ff ff       	jmp    801064e8 <alltraps>

80106f82 <vector119>:
.globl vector119
vector119:
  pushl $0
80106f82:	6a 00                	push   $0x0
  pushl $119
80106f84:	6a 77                	push   $0x77
  jmp alltraps
80106f86:	e9 5d f5 ff ff       	jmp    801064e8 <alltraps>

80106f8b <vector120>:
.globl vector120
vector120:
  pushl $0
80106f8b:	6a 00                	push   $0x0
  pushl $120
80106f8d:	6a 78                	push   $0x78
  jmp alltraps
80106f8f:	e9 54 f5 ff ff       	jmp    801064e8 <alltraps>

80106f94 <vector121>:
.globl vector121
vector121:
  pushl $0
80106f94:	6a 00                	push   $0x0
  pushl $121
80106f96:	6a 79                	push   $0x79
  jmp alltraps
80106f98:	e9 4b f5 ff ff       	jmp    801064e8 <alltraps>

80106f9d <vector122>:
.globl vector122
vector122:
  pushl $0
80106f9d:	6a 00                	push   $0x0
  pushl $122
80106f9f:	6a 7a                	push   $0x7a
  jmp alltraps
80106fa1:	e9 42 f5 ff ff       	jmp    801064e8 <alltraps>

80106fa6 <vector123>:
.globl vector123
vector123:
  pushl $0
80106fa6:	6a 00                	push   $0x0
  pushl $123
80106fa8:	6a 7b                	push   $0x7b
  jmp alltraps
80106faa:	e9 39 f5 ff ff       	jmp    801064e8 <alltraps>

80106faf <vector124>:
.globl vector124
vector124:
  pushl $0
80106faf:	6a 00                	push   $0x0
  pushl $124
80106fb1:	6a 7c                	push   $0x7c
  jmp alltraps
80106fb3:	e9 30 f5 ff ff       	jmp    801064e8 <alltraps>

80106fb8 <vector125>:
.globl vector125
vector125:
  pushl $0
80106fb8:	6a 00                	push   $0x0
  pushl $125
80106fba:	6a 7d                	push   $0x7d
  jmp alltraps
80106fbc:	e9 27 f5 ff ff       	jmp    801064e8 <alltraps>

80106fc1 <vector126>:
.globl vector126
vector126:
  pushl $0
80106fc1:	6a 00                	push   $0x0
  pushl $126
80106fc3:	6a 7e                	push   $0x7e
  jmp alltraps
80106fc5:	e9 1e f5 ff ff       	jmp    801064e8 <alltraps>

80106fca <vector127>:
.globl vector127
vector127:
  pushl $0
80106fca:	6a 00                	push   $0x0
  pushl $127
80106fcc:	6a 7f                	push   $0x7f
  jmp alltraps
80106fce:	e9 15 f5 ff ff       	jmp    801064e8 <alltraps>

80106fd3 <vector128>:
.globl vector128
vector128:
  pushl $0
80106fd3:	6a 00                	push   $0x0
  pushl $128
80106fd5:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106fda:	e9 09 f5 ff ff       	jmp    801064e8 <alltraps>

80106fdf <vector129>:
.globl vector129
vector129:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $129
80106fe1:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106fe6:	e9 fd f4 ff ff       	jmp    801064e8 <alltraps>

80106feb <vector130>:
.globl vector130
vector130:
  pushl $0
80106feb:	6a 00                	push   $0x0
  pushl $130
80106fed:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106ff2:	e9 f1 f4 ff ff       	jmp    801064e8 <alltraps>

80106ff7 <vector131>:
.globl vector131
vector131:
  pushl $0
80106ff7:	6a 00                	push   $0x0
  pushl $131
80106ff9:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106ffe:	e9 e5 f4 ff ff       	jmp    801064e8 <alltraps>

80107003 <vector132>:
.globl vector132
vector132:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $132
80107005:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010700a:	e9 d9 f4 ff ff       	jmp    801064e8 <alltraps>

8010700f <vector133>:
.globl vector133
vector133:
  pushl $0
8010700f:	6a 00                	push   $0x0
  pushl $133
80107011:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107016:	e9 cd f4 ff ff       	jmp    801064e8 <alltraps>

8010701b <vector134>:
.globl vector134
vector134:
  pushl $0
8010701b:	6a 00                	push   $0x0
  pushl $134
8010701d:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107022:	e9 c1 f4 ff ff       	jmp    801064e8 <alltraps>

80107027 <vector135>:
.globl vector135
vector135:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $135
80107029:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010702e:	e9 b5 f4 ff ff       	jmp    801064e8 <alltraps>

80107033 <vector136>:
.globl vector136
vector136:
  pushl $0
80107033:	6a 00                	push   $0x0
  pushl $136
80107035:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010703a:	e9 a9 f4 ff ff       	jmp    801064e8 <alltraps>

8010703f <vector137>:
.globl vector137
vector137:
  pushl $0
8010703f:	6a 00                	push   $0x0
  pushl $137
80107041:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107046:	e9 9d f4 ff ff       	jmp    801064e8 <alltraps>

8010704b <vector138>:
.globl vector138
vector138:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $138
8010704d:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107052:	e9 91 f4 ff ff       	jmp    801064e8 <alltraps>

80107057 <vector139>:
.globl vector139
vector139:
  pushl $0
80107057:	6a 00                	push   $0x0
  pushl $139
80107059:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010705e:	e9 85 f4 ff ff       	jmp    801064e8 <alltraps>

80107063 <vector140>:
.globl vector140
vector140:
  pushl $0
80107063:	6a 00                	push   $0x0
  pushl $140
80107065:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010706a:	e9 79 f4 ff ff       	jmp    801064e8 <alltraps>

8010706f <vector141>:
.globl vector141
vector141:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $141
80107071:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107076:	e9 6d f4 ff ff       	jmp    801064e8 <alltraps>

8010707b <vector142>:
.globl vector142
vector142:
  pushl $0
8010707b:	6a 00                	push   $0x0
  pushl $142
8010707d:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107082:	e9 61 f4 ff ff       	jmp    801064e8 <alltraps>

80107087 <vector143>:
.globl vector143
vector143:
  pushl $0
80107087:	6a 00                	push   $0x0
  pushl $143
80107089:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010708e:	e9 55 f4 ff ff       	jmp    801064e8 <alltraps>

80107093 <vector144>:
.globl vector144
vector144:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $144
80107095:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010709a:	e9 49 f4 ff ff       	jmp    801064e8 <alltraps>

8010709f <vector145>:
.globl vector145
vector145:
  pushl $0
8010709f:	6a 00                	push   $0x0
  pushl $145
801070a1:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801070a6:	e9 3d f4 ff ff       	jmp    801064e8 <alltraps>

801070ab <vector146>:
.globl vector146
vector146:
  pushl $0
801070ab:	6a 00                	push   $0x0
  pushl $146
801070ad:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801070b2:	e9 31 f4 ff ff       	jmp    801064e8 <alltraps>

801070b7 <vector147>:
.globl vector147
vector147:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $147
801070b9:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801070be:	e9 25 f4 ff ff       	jmp    801064e8 <alltraps>

801070c3 <vector148>:
.globl vector148
vector148:
  pushl $0
801070c3:	6a 00                	push   $0x0
  pushl $148
801070c5:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801070ca:	e9 19 f4 ff ff       	jmp    801064e8 <alltraps>

801070cf <vector149>:
.globl vector149
vector149:
  pushl $0
801070cf:	6a 00                	push   $0x0
  pushl $149
801070d1:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801070d6:	e9 0d f4 ff ff       	jmp    801064e8 <alltraps>

801070db <vector150>:
.globl vector150
vector150:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $150
801070dd:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801070e2:	e9 01 f4 ff ff       	jmp    801064e8 <alltraps>

801070e7 <vector151>:
.globl vector151
vector151:
  pushl $0
801070e7:	6a 00                	push   $0x0
  pushl $151
801070e9:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801070ee:	e9 f5 f3 ff ff       	jmp    801064e8 <alltraps>

801070f3 <vector152>:
.globl vector152
vector152:
  pushl $0
801070f3:	6a 00                	push   $0x0
  pushl $152
801070f5:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801070fa:	e9 e9 f3 ff ff       	jmp    801064e8 <alltraps>

801070ff <vector153>:
.globl vector153
vector153:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $153
80107101:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107106:	e9 dd f3 ff ff       	jmp    801064e8 <alltraps>

8010710b <vector154>:
.globl vector154
vector154:
  pushl $0
8010710b:	6a 00                	push   $0x0
  pushl $154
8010710d:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107112:	e9 d1 f3 ff ff       	jmp    801064e8 <alltraps>

80107117 <vector155>:
.globl vector155
vector155:
  pushl $0
80107117:	6a 00                	push   $0x0
  pushl $155
80107119:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010711e:	e9 c5 f3 ff ff       	jmp    801064e8 <alltraps>

80107123 <vector156>:
.globl vector156
vector156:
  pushl $0
80107123:	6a 00                	push   $0x0
  pushl $156
80107125:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010712a:	e9 b9 f3 ff ff       	jmp    801064e8 <alltraps>

8010712f <vector157>:
.globl vector157
vector157:
  pushl $0
8010712f:	6a 00                	push   $0x0
  pushl $157
80107131:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107136:	e9 ad f3 ff ff       	jmp    801064e8 <alltraps>

8010713b <vector158>:
.globl vector158
vector158:
  pushl $0
8010713b:	6a 00                	push   $0x0
  pushl $158
8010713d:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107142:	e9 a1 f3 ff ff       	jmp    801064e8 <alltraps>

80107147 <vector159>:
.globl vector159
vector159:
  pushl $0
80107147:	6a 00                	push   $0x0
  pushl $159
80107149:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010714e:	e9 95 f3 ff ff       	jmp    801064e8 <alltraps>

80107153 <vector160>:
.globl vector160
vector160:
  pushl $0
80107153:	6a 00                	push   $0x0
  pushl $160
80107155:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010715a:	e9 89 f3 ff ff       	jmp    801064e8 <alltraps>

8010715f <vector161>:
.globl vector161
vector161:
  pushl $0
8010715f:	6a 00                	push   $0x0
  pushl $161
80107161:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107166:	e9 7d f3 ff ff       	jmp    801064e8 <alltraps>

8010716b <vector162>:
.globl vector162
vector162:
  pushl $0
8010716b:	6a 00                	push   $0x0
  pushl $162
8010716d:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107172:	e9 71 f3 ff ff       	jmp    801064e8 <alltraps>

80107177 <vector163>:
.globl vector163
vector163:
  pushl $0
80107177:	6a 00                	push   $0x0
  pushl $163
80107179:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010717e:	e9 65 f3 ff ff       	jmp    801064e8 <alltraps>

80107183 <vector164>:
.globl vector164
vector164:
  pushl $0
80107183:	6a 00                	push   $0x0
  pushl $164
80107185:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010718a:	e9 59 f3 ff ff       	jmp    801064e8 <alltraps>

8010718f <vector165>:
.globl vector165
vector165:
  pushl $0
8010718f:	6a 00                	push   $0x0
  pushl $165
80107191:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107196:	e9 4d f3 ff ff       	jmp    801064e8 <alltraps>

8010719b <vector166>:
.globl vector166
vector166:
  pushl $0
8010719b:	6a 00                	push   $0x0
  pushl $166
8010719d:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801071a2:	e9 41 f3 ff ff       	jmp    801064e8 <alltraps>

801071a7 <vector167>:
.globl vector167
vector167:
  pushl $0
801071a7:	6a 00                	push   $0x0
  pushl $167
801071a9:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801071ae:	e9 35 f3 ff ff       	jmp    801064e8 <alltraps>

801071b3 <vector168>:
.globl vector168
vector168:
  pushl $0
801071b3:	6a 00                	push   $0x0
  pushl $168
801071b5:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801071ba:	e9 29 f3 ff ff       	jmp    801064e8 <alltraps>

801071bf <vector169>:
.globl vector169
vector169:
  pushl $0
801071bf:	6a 00                	push   $0x0
  pushl $169
801071c1:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801071c6:	e9 1d f3 ff ff       	jmp    801064e8 <alltraps>

801071cb <vector170>:
.globl vector170
vector170:
  pushl $0
801071cb:	6a 00                	push   $0x0
  pushl $170
801071cd:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801071d2:	e9 11 f3 ff ff       	jmp    801064e8 <alltraps>

801071d7 <vector171>:
.globl vector171
vector171:
  pushl $0
801071d7:	6a 00                	push   $0x0
  pushl $171
801071d9:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801071de:	e9 05 f3 ff ff       	jmp    801064e8 <alltraps>

801071e3 <vector172>:
.globl vector172
vector172:
  pushl $0
801071e3:	6a 00                	push   $0x0
  pushl $172
801071e5:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801071ea:	e9 f9 f2 ff ff       	jmp    801064e8 <alltraps>

801071ef <vector173>:
.globl vector173
vector173:
  pushl $0
801071ef:	6a 00                	push   $0x0
  pushl $173
801071f1:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801071f6:	e9 ed f2 ff ff       	jmp    801064e8 <alltraps>

801071fb <vector174>:
.globl vector174
vector174:
  pushl $0
801071fb:	6a 00                	push   $0x0
  pushl $174
801071fd:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107202:	e9 e1 f2 ff ff       	jmp    801064e8 <alltraps>

80107207 <vector175>:
.globl vector175
vector175:
  pushl $0
80107207:	6a 00                	push   $0x0
  pushl $175
80107209:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010720e:	e9 d5 f2 ff ff       	jmp    801064e8 <alltraps>

80107213 <vector176>:
.globl vector176
vector176:
  pushl $0
80107213:	6a 00                	push   $0x0
  pushl $176
80107215:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010721a:	e9 c9 f2 ff ff       	jmp    801064e8 <alltraps>

8010721f <vector177>:
.globl vector177
vector177:
  pushl $0
8010721f:	6a 00                	push   $0x0
  pushl $177
80107221:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107226:	e9 bd f2 ff ff       	jmp    801064e8 <alltraps>

8010722b <vector178>:
.globl vector178
vector178:
  pushl $0
8010722b:	6a 00                	push   $0x0
  pushl $178
8010722d:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107232:	e9 b1 f2 ff ff       	jmp    801064e8 <alltraps>

80107237 <vector179>:
.globl vector179
vector179:
  pushl $0
80107237:	6a 00                	push   $0x0
  pushl $179
80107239:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010723e:	e9 a5 f2 ff ff       	jmp    801064e8 <alltraps>

80107243 <vector180>:
.globl vector180
vector180:
  pushl $0
80107243:	6a 00                	push   $0x0
  pushl $180
80107245:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010724a:	e9 99 f2 ff ff       	jmp    801064e8 <alltraps>

8010724f <vector181>:
.globl vector181
vector181:
  pushl $0
8010724f:	6a 00                	push   $0x0
  pushl $181
80107251:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107256:	e9 8d f2 ff ff       	jmp    801064e8 <alltraps>

8010725b <vector182>:
.globl vector182
vector182:
  pushl $0
8010725b:	6a 00                	push   $0x0
  pushl $182
8010725d:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107262:	e9 81 f2 ff ff       	jmp    801064e8 <alltraps>

80107267 <vector183>:
.globl vector183
vector183:
  pushl $0
80107267:	6a 00                	push   $0x0
  pushl $183
80107269:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010726e:	e9 75 f2 ff ff       	jmp    801064e8 <alltraps>

80107273 <vector184>:
.globl vector184
vector184:
  pushl $0
80107273:	6a 00                	push   $0x0
  pushl $184
80107275:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010727a:	e9 69 f2 ff ff       	jmp    801064e8 <alltraps>

8010727f <vector185>:
.globl vector185
vector185:
  pushl $0
8010727f:	6a 00                	push   $0x0
  pushl $185
80107281:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107286:	e9 5d f2 ff ff       	jmp    801064e8 <alltraps>

8010728b <vector186>:
.globl vector186
vector186:
  pushl $0
8010728b:	6a 00                	push   $0x0
  pushl $186
8010728d:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107292:	e9 51 f2 ff ff       	jmp    801064e8 <alltraps>

80107297 <vector187>:
.globl vector187
vector187:
  pushl $0
80107297:	6a 00                	push   $0x0
  pushl $187
80107299:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010729e:	e9 45 f2 ff ff       	jmp    801064e8 <alltraps>

801072a3 <vector188>:
.globl vector188
vector188:
  pushl $0
801072a3:	6a 00                	push   $0x0
  pushl $188
801072a5:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801072aa:	e9 39 f2 ff ff       	jmp    801064e8 <alltraps>

801072af <vector189>:
.globl vector189
vector189:
  pushl $0
801072af:	6a 00                	push   $0x0
  pushl $189
801072b1:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801072b6:	e9 2d f2 ff ff       	jmp    801064e8 <alltraps>

801072bb <vector190>:
.globl vector190
vector190:
  pushl $0
801072bb:	6a 00                	push   $0x0
  pushl $190
801072bd:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801072c2:	e9 21 f2 ff ff       	jmp    801064e8 <alltraps>

801072c7 <vector191>:
.globl vector191
vector191:
  pushl $0
801072c7:	6a 00                	push   $0x0
  pushl $191
801072c9:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801072ce:	e9 15 f2 ff ff       	jmp    801064e8 <alltraps>

801072d3 <vector192>:
.globl vector192
vector192:
  pushl $0
801072d3:	6a 00                	push   $0x0
  pushl $192
801072d5:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801072da:	e9 09 f2 ff ff       	jmp    801064e8 <alltraps>

801072df <vector193>:
.globl vector193
vector193:
  pushl $0
801072df:	6a 00                	push   $0x0
  pushl $193
801072e1:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801072e6:	e9 fd f1 ff ff       	jmp    801064e8 <alltraps>

801072eb <vector194>:
.globl vector194
vector194:
  pushl $0
801072eb:	6a 00                	push   $0x0
  pushl $194
801072ed:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801072f2:	e9 f1 f1 ff ff       	jmp    801064e8 <alltraps>

801072f7 <vector195>:
.globl vector195
vector195:
  pushl $0
801072f7:	6a 00                	push   $0x0
  pushl $195
801072f9:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801072fe:	e9 e5 f1 ff ff       	jmp    801064e8 <alltraps>

80107303 <vector196>:
.globl vector196
vector196:
  pushl $0
80107303:	6a 00                	push   $0x0
  pushl $196
80107305:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010730a:	e9 d9 f1 ff ff       	jmp    801064e8 <alltraps>

8010730f <vector197>:
.globl vector197
vector197:
  pushl $0
8010730f:	6a 00                	push   $0x0
  pushl $197
80107311:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107316:	e9 cd f1 ff ff       	jmp    801064e8 <alltraps>

8010731b <vector198>:
.globl vector198
vector198:
  pushl $0
8010731b:	6a 00                	push   $0x0
  pushl $198
8010731d:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107322:	e9 c1 f1 ff ff       	jmp    801064e8 <alltraps>

80107327 <vector199>:
.globl vector199
vector199:
  pushl $0
80107327:	6a 00                	push   $0x0
  pushl $199
80107329:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
8010732e:	e9 b5 f1 ff ff       	jmp    801064e8 <alltraps>

80107333 <vector200>:
.globl vector200
vector200:
  pushl $0
80107333:	6a 00                	push   $0x0
  pushl $200
80107335:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
8010733a:	e9 a9 f1 ff ff       	jmp    801064e8 <alltraps>

8010733f <vector201>:
.globl vector201
vector201:
  pushl $0
8010733f:	6a 00                	push   $0x0
  pushl $201
80107341:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107346:	e9 9d f1 ff ff       	jmp    801064e8 <alltraps>

8010734b <vector202>:
.globl vector202
vector202:
  pushl $0
8010734b:	6a 00                	push   $0x0
  pushl $202
8010734d:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107352:	e9 91 f1 ff ff       	jmp    801064e8 <alltraps>

80107357 <vector203>:
.globl vector203
vector203:
  pushl $0
80107357:	6a 00                	push   $0x0
  pushl $203
80107359:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010735e:	e9 85 f1 ff ff       	jmp    801064e8 <alltraps>

80107363 <vector204>:
.globl vector204
vector204:
  pushl $0
80107363:	6a 00                	push   $0x0
  pushl $204
80107365:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010736a:	e9 79 f1 ff ff       	jmp    801064e8 <alltraps>

8010736f <vector205>:
.globl vector205
vector205:
  pushl $0
8010736f:	6a 00                	push   $0x0
  pushl $205
80107371:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107376:	e9 6d f1 ff ff       	jmp    801064e8 <alltraps>

8010737b <vector206>:
.globl vector206
vector206:
  pushl $0
8010737b:	6a 00                	push   $0x0
  pushl $206
8010737d:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107382:	e9 61 f1 ff ff       	jmp    801064e8 <alltraps>

80107387 <vector207>:
.globl vector207
vector207:
  pushl $0
80107387:	6a 00                	push   $0x0
  pushl $207
80107389:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010738e:	e9 55 f1 ff ff       	jmp    801064e8 <alltraps>

80107393 <vector208>:
.globl vector208
vector208:
  pushl $0
80107393:	6a 00                	push   $0x0
  pushl $208
80107395:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010739a:	e9 49 f1 ff ff       	jmp    801064e8 <alltraps>

8010739f <vector209>:
.globl vector209
vector209:
  pushl $0
8010739f:	6a 00                	push   $0x0
  pushl $209
801073a1:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801073a6:	e9 3d f1 ff ff       	jmp    801064e8 <alltraps>

801073ab <vector210>:
.globl vector210
vector210:
  pushl $0
801073ab:	6a 00                	push   $0x0
  pushl $210
801073ad:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801073b2:	e9 31 f1 ff ff       	jmp    801064e8 <alltraps>

801073b7 <vector211>:
.globl vector211
vector211:
  pushl $0
801073b7:	6a 00                	push   $0x0
  pushl $211
801073b9:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801073be:	e9 25 f1 ff ff       	jmp    801064e8 <alltraps>

801073c3 <vector212>:
.globl vector212
vector212:
  pushl $0
801073c3:	6a 00                	push   $0x0
  pushl $212
801073c5:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801073ca:	e9 19 f1 ff ff       	jmp    801064e8 <alltraps>

801073cf <vector213>:
.globl vector213
vector213:
  pushl $0
801073cf:	6a 00                	push   $0x0
  pushl $213
801073d1:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801073d6:	e9 0d f1 ff ff       	jmp    801064e8 <alltraps>

801073db <vector214>:
.globl vector214
vector214:
  pushl $0
801073db:	6a 00                	push   $0x0
  pushl $214
801073dd:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801073e2:	e9 01 f1 ff ff       	jmp    801064e8 <alltraps>

801073e7 <vector215>:
.globl vector215
vector215:
  pushl $0
801073e7:	6a 00                	push   $0x0
  pushl $215
801073e9:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801073ee:	e9 f5 f0 ff ff       	jmp    801064e8 <alltraps>

801073f3 <vector216>:
.globl vector216
vector216:
  pushl $0
801073f3:	6a 00                	push   $0x0
  pushl $216
801073f5:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801073fa:	e9 e9 f0 ff ff       	jmp    801064e8 <alltraps>

801073ff <vector217>:
.globl vector217
vector217:
  pushl $0
801073ff:	6a 00                	push   $0x0
  pushl $217
80107401:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107406:	e9 dd f0 ff ff       	jmp    801064e8 <alltraps>

8010740b <vector218>:
.globl vector218
vector218:
  pushl $0
8010740b:	6a 00                	push   $0x0
  pushl $218
8010740d:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107412:	e9 d1 f0 ff ff       	jmp    801064e8 <alltraps>

80107417 <vector219>:
.globl vector219
vector219:
  pushl $0
80107417:	6a 00                	push   $0x0
  pushl $219
80107419:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
8010741e:	e9 c5 f0 ff ff       	jmp    801064e8 <alltraps>

80107423 <vector220>:
.globl vector220
vector220:
  pushl $0
80107423:	6a 00                	push   $0x0
  pushl $220
80107425:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010742a:	e9 b9 f0 ff ff       	jmp    801064e8 <alltraps>

8010742f <vector221>:
.globl vector221
vector221:
  pushl $0
8010742f:	6a 00                	push   $0x0
  pushl $221
80107431:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107436:	e9 ad f0 ff ff       	jmp    801064e8 <alltraps>

8010743b <vector222>:
.globl vector222
vector222:
  pushl $0
8010743b:	6a 00                	push   $0x0
  pushl $222
8010743d:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107442:	e9 a1 f0 ff ff       	jmp    801064e8 <alltraps>

80107447 <vector223>:
.globl vector223
vector223:
  pushl $0
80107447:	6a 00                	push   $0x0
  pushl $223
80107449:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
8010744e:	e9 95 f0 ff ff       	jmp    801064e8 <alltraps>

80107453 <vector224>:
.globl vector224
vector224:
  pushl $0
80107453:	6a 00                	push   $0x0
  pushl $224
80107455:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010745a:	e9 89 f0 ff ff       	jmp    801064e8 <alltraps>

8010745f <vector225>:
.globl vector225
vector225:
  pushl $0
8010745f:	6a 00                	push   $0x0
  pushl $225
80107461:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107466:	e9 7d f0 ff ff       	jmp    801064e8 <alltraps>

8010746b <vector226>:
.globl vector226
vector226:
  pushl $0
8010746b:	6a 00                	push   $0x0
  pushl $226
8010746d:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107472:	e9 71 f0 ff ff       	jmp    801064e8 <alltraps>

80107477 <vector227>:
.globl vector227
vector227:
  pushl $0
80107477:	6a 00                	push   $0x0
  pushl $227
80107479:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010747e:	e9 65 f0 ff ff       	jmp    801064e8 <alltraps>

80107483 <vector228>:
.globl vector228
vector228:
  pushl $0
80107483:	6a 00                	push   $0x0
  pushl $228
80107485:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010748a:	e9 59 f0 ff ff       	jmp    801064e8 <alltraps>

8010748f <vector229>:
.globl vector229
vector229:
  pushl $0
8010748f:	6a 00                	push   $0x0
  pushl $229
80107491:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107496:	e9 4d f0 ff ff       	jmp    801064e8 <alltraps>

8010749b <vector230>:
.globl vector230
vector230:
  pushl $0
8010749b:	6a 00                	push   $0x0
  pushl $230
8010749d:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801074a2:	e9 41 f0 ff ff       	jmp    801064e8 <alltraps>

801074a7 <vector231>:
.globl vector231
vector231:
  pushl $0
801074a7:	6a 00                	push   $0x0
  pushl $231
801074a9:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801074ae:	e9 35 f0 ff ff       	jmp    801064e8 <alltraps>

801074b3 <vector232>:
.globl vector232
vector232:
  pushl $0
801074b3:	6a 00                	push   $0x0
  pushl $232
801074b5:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801074ba:	e9 29 f0 ff ff       	jmp    801064e8 <alltraps>

801074bf <vector233>:
.globl vector233
vector233:
  pushl $0
801074bf:	6a 00                	push   $0x0
  pushl $233
801074c1:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801074c6:	e9 1d f0 ff ff       	jmp    801064e8 <alltraps>

801074cb <vector234>:
.globl vector234
vector234:
  pushl $0
801074cb:	6a 00                	push   $0x0
  pushl $234
801074cd:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801074d2:	e9 11 f0 ff ff       	jmp    801064e8 <alltraps>

801074d7 <vector235>:
.globl vector235
vector235:
  pushl $0
801074d7:	6a 00                	push   $0x0
  pushl $235
801074d9:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801074de:	e9 05 f0 ff ff       	jmp    801064e8 <alltraps>

801074e3 <vector236>:
.globl vector236
vector236:
  pushl $0
801074e3:	6a 00                	push   $0x0
  pushl $236
801074e5:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801074ea:	e9 f9 ef ff ff       	jmp    801064e8 <alltraps>

801074ef <vector237>:
.globl vector237
vector237:
  pushl $0
801074ef:	6a 00                	push   $0x0
  pushl $237
801074f1:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801074f6:	e9 ed ef ff ff       	jmp    801064e8 <alltraps>

801074fb <vector238>:
.globl vector238
vector238:
  pushl $0
801074fb:	6a 00                	push   $0x0
  pushl $238
801074fd:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107502:	e9 e1 ef ff ff       	jmp    801064e8 <alltraps>

80107507 <vector239>:
.globl vector239
vector239:
  pushl $0
80107507:	6a 00                	push   $0x0
  pushl $239
80107509:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010750e:	e9 d5 ef ff ff       	jmp    801064e8 <alltraps>

80107513 <vector240>:
.globl vector240
vector240:
  pushl $0
80107513:	6a 00                	push   $0x0
  pushl $240
80107515:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010751a:	e9 c9 ef ff ff       	jmp    801064e8 <alltraps>

8010751f <vector241>:
.globl vector241
vector241:
  pushl $0
8010751f:	6a 00                	push   $0x0
  pushl $241
80107521:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107526:	e9 bd ef ff ff       	jmp    801064e8 <alltraps>

8010752b <vector242>:
.globl vector242
vector242:
  pushl $0
8010752b:	6a 00                	push   $0x0
  pushl $242
8010752d:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107532:	e9 b1 ef ff ff       	jmp    801064e8 <alltraps>

80107537 <vector243>:
.globl vector243
vector243:
  pushl $0
80107537:	6a 00                	push   $0x0
  pushl $243
80107539:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
8010753e:	e9 a5 ef ff ff       	jmp    801064e8 <alltraps>

80107543 <vector244>:
.globl vector244
vector244:
  pushl $0
80107543:	6a 00                	push   $0x0
  pushl $244
80107545:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010754a:	e9 99 ef ff ff       	jmp    801064e8 <alltraps>

8010754f <vector245>:
.globl vector245
vector245:
  pushl $0
8010754f:	6a 00                	push   $0x0
  pushl $245
80107551:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107556:	e9 8d ef ff ff       	jmp    801064e8 <alltraps>

8010755b <vector246>:
.globl vector246
vector246:
  pushl $0
8010755b:	6a 00                	push   $0x0
  pushl $246
8010755d:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107562:	e9 81 ef ff ff       	jmp    801064e8 <alltraps>

80107567 <vector247>:
.globl vector247
vector247:
  pushl $0
80107567:	6a 00                	push   $0x0
  pushl $247
80107569:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010756e:	e9 75 ef ff ff       	jmp    801064e8 <alltraps>

80107573 <vector248>:
.globl vector248
vector248:
  pushl $0
80107573:	6a 00                	push   $0x0
  pushl $248
80107575:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010757a:	e9 69 ef ff ff       	jmp    801064e8 <alltraps>

8010757f <vector249>:
.globl vector249
vector249:
  pushl $0
8010757f:	6a 00                	push   $0x0
  pushl $249
80107581:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107586:	e9 5d ef ff ff       	jmp    801064e8 <alltraps>

8010758b <vector250>:
.globl vector250
vector250:
  pushl $0
8010758b:	6a 00                	push   $0x0
  pushl $250
8010758d:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107592:	e9 51 ef ff ff       	jmp    801064e8 <alltraps>

80107597 <vector251>:
.globl vector251
vector251:
  pushl $0
80107597:	6a 00                	push   $0x0
  pushl $251
80107599:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010759e:	e9 45 ef ff ff       	jmp    801064e8 <alltraps>

801075a3 <vector252>:
.globl vector252
vector252:
  pushl $0
801075a3:	6a 00                	push   $0x0
  pushl $252
801075a5:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801075aa:	e9 39 ef ff ff       	jmp    801064e8 <alltraps>

801075af <vector253>:
.globl vector253
vector253:
  pushl $0
801075af:	6a 00                	push   $0x0
  pushl $253
801075b1:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801075b6:	e9 2d ef ff ff       	jmp    801064e8 <alltraps>

801075bb <vector254>:
.globl vector254
vector254:
  pushl $0
801075bb:	6a 00                	push   $0x0
  pushl $254
801075bd:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801075c2:	e9 21 ef ff ff       	jmp    801064e8 <alltraps>

801075c7 <vector255>:
.globl vector255
vector255:
  pushl $0
801075c7:	6a 00                	push   $0x0
  pushl $255
801075c9:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801075ce:	e9 15 ef ff ff       	jmp    801064e8 <alltraps>

801075d3 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801075d3:	55                   	push   %ebp
801075d4:	89 e5                	mov    %esp,%ebp
801075d6:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801075d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801075dc:	83 e8 01             	sub    $0x1,%eax
801075df:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801075e3:	8b 45 08             	mov    0x8(%ebp),%eax
801075e6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801075ea:	8b 45 08             	mov    0x8(%ebp),%eax
801075ed:	c1 e8 10             	shr    $0x10,%eax
801075f0:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801075f4:	8d 45 fa             	lea    -0x6(%ebp),%eax
801075f7:	0f 01 10             	lgdtl  (%eax)
}
801075fa:	c9                   	leave  
801075fb:	c3                   	ret    

801075fc <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801075fc:	55                   	push   %ebp
801075fd:	89 e5                	mov    %esp,%ebp
801075ff:	83 ec 04             	sub    $0x4,%esp
80107602:	8b 45 08             	mov    0x8(%ebp),%eax
80107605:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107609:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010760d:	0f 00 d8             	ltr    %ax
}
80107610:	c9                   	leave  
80107611:	c3                   	ret    

80107612 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107612:	55                   	push   %ebp
80107613:	89 e5                	mov    %esp,%ebp
80107615:	83 ec 04             	sub    $0x4,%esp
80107618:	8b 45 08             	mov    0x8(%ebp),%eax
8010761b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
8010761f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107623:	8e e8                	mov    %eax,%gs
}
80107625:	c9                   	leave  
80107626:	c3                   	ret    

80107627 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107627:	55                   	push   %ebp
80107628:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010762a:	8b 45 08             	mov    0x8(%ebp),%eax
8010762d:	0f 22 d8             	mov    %eax,%cr3
}
80107630:	5d                   	pop    %ebp
80107631:	c3                   	ret    

80107632 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107632:	55                   	push   %ebp
80107633:	89 e5                	mov    %esp,%ebp
80107635:	8b 45 08             	mov    0x8(%ebp),%eax
80107638:	05 00 00 00 80       	add    $0x80000000,%eax
8010763d:	5d                   	pop    %ebp
8010763e:	c3                   	ret    

8010763f <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010763f:	55                   	push   %ebp
80107640:	89 e5                	mov    %esp,%ebp
80107642:	8b 45 08             	mov    0x8(%ebp),%eax
80107645:	05 00 00 00 80       	add    $0x80000000,%eax
8010764a:	5d                   	pop    %ebp
8010764b:	c3                   	ret    

8010764c <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
8010764c:	55                   	push   %ebp
8010764d:	89 e5                	mov    %esp,%ebp
8010764f:	53                   	push   %ebx
80107650:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107653:	e8 20 b8 ff ff       	call   80102e78 <cpunum>
80107658:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010765e:	05 60 23 11 80       	add    $0x80112360,%eax
80107663:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107669:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010766f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107672:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107678:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010767b:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010767f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107682:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107686:	83 e2 f0             	and    $0xfffffff0,%edx
80107689:	83 ca 0a             	or     $0xa,%edx
8010768c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010768f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107692:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107696:	83 ca 10             	or     $0x10,%edx
80107699:	88 50 7d             	mov    %dl,0x7d(%eax)
8010769c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010769f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076a3:	83 e2 9f             	and    $0xffffff9f,%edx
801076a6:	88 50 7d             	mov    %dl,0x7d(%eax)
801076a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ac:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801076b0:	83 ca 80             	or     $0xffffff80,%edx
801076b3:	88 50 7d             	mov    %dl,0x7d(%eax)
801076b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076bd:	83 ca 0f             	or     $0xf,%edx
801076c0:	88 50 7e             	mov    %dl,0x7e(%eax)
801076c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076ca:	83 e2 ef             	and    $0xffffffef,%edx
801076cd:	88 50 7e             	mov    %dl,0x7e(%eax)
801076d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d3:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076d7:	83 e2 df             	and    $0xffffffdf,%edx
801076da:	88 50 7e             	mov    %dl,0x7e(%eax)
801076dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e0:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076e4:	83 ca 40             	or     $0x40,%edx
801076e7:	88 50 7e             	mov    %dl,0x7e(%eax)
801076ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ed:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801076f1:	83 ca 80             	or     $0xffffff80,%edx
801076f4:	88 50 7e             	mov    %dl,0x7e(%eax)
801076f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fa:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801076fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107701:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107708:	ff ff 
8010770a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770d:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107714:	00 00 
80107716:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107719:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107720:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107723:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010772a:	83 e2 f0             	and    $0xfffffff0,%edx
8010772d:	83 ca 02             	or     $0x2,%edx
80107730:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107739:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107740:	83 ca 10             	or     $0x10,%edx
80107743:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107753:	83 e2 9f             	and    $0xffffff9f,%edx
80107756:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010775c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775f:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107766:	83 ca 80             	or     $0xffffff80,%edx
80107769:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010776f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107772:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107779:	83 ca 0f             	or     $0xf,%edx
8010777c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107782:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107785:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010778c:	83 e2 ef             	and    $0xffffffef,%edx
8010778f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107795:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107798:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010779f:	83 e2 df             	and    $0xffffffdf,%edx
801077a2:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ab:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077b2:	83 ca 40             	or     $0x40,%edx
801077b5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077be:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077c5:	83 ca 80             	or     $0xffffff80,%edx
801077c8:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d1:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801077d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077db:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801077e2:	ff ff 
801077e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e7:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801077ee:	00 00 
801077f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f3:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801077fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fd:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107804:	83 e2 f0             	and    $0xfffffff0,%edx
80107807:	83 ca 0a             	or     $0xa,%edx
8010780a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107813:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010781a:	83 ca 10             	or     $0x10,%edx
8010781d:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107826:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010782d:	83 ca 60             	or     $0x60,%edx
80107830:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107839:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107840:	83 ca 80             	or     $0xffffff80,%edx
80107843:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784c:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107853:	83 ca 0f             	or     $0xf,%edx
80107856:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010785c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107866:	83 e2 ef             	and    $0xffffffef,%edx
80107869:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010786f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107872:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107879:	83 e2 df             	and    $0xffffffdf,%edx
8010787c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107882:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107885:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010788c:	83 ca 40             	or     $0x40,%edx
8010788f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107898:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010789f:	83 ca 80             	or     $0xffffff80,%edx
801078a2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801078a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ab:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801078b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b5:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801078bc:	ff ff 
801078be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c1:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801078c8:	00 00 
801078ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078cd:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801078d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d7:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801078de:	83 e2 f0             	and    $0xfffffff0,%edx
801078e1:	83 ca 02             	or     $0x2,%edx
801078e4:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801078ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ed:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801078f4:	83 ca 10             	or     $0x10,%edx
801078f7:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801078fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107900:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107907:	83 ca 60             	or     $0x60,%edx
8010790a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107910:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107913:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010791a:	83 ca 80             	or     $0xffffff80,%edx
8010791d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107926:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010792d:	83 ca 0f             	or     $0xf,%edx
80107930:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107939:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107940:	83 e2 ef             	and    $0xffffffef,%edx
80107943:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794c:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107953:	83 e2 df             	and    $0xffffffdf,%edx
80107956:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010795c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107966:	83 ca 40             	or     $0x40,%edx
80107969:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010796f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107972:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107979:	83 ca 80             	or     $0xffffff80,%edx
8010797c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107982:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107985:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
8010798c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798f:	05 b4 00 00 00       	add    $0xb4,%eax
80107994:	89 c3                	mov    %eax,%ebx
80107996:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107999:	05 b4 00 00 00       	add    $0xb4,%eax
8010799e:	c1 e8 10             	shr    $0x10,%eax
801079a1:	89 c1                	mov    %eax,%ecx
801079a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a6:	05 b4 00 00 00       	add    $0xb4,%eax
801079ab:	c1 e8 18             	shr    $0x18,%eax
801079ae:	89 c2                	mov    %eax,%edx
801079b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b3:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801079ba:	00 00 
801079bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079bf:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801079c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c9:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801079cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d2:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801079d9:	83 e1 f0             	and    $0xfffffff0,%ecx
801079dc:	83 c9 02             	or     $0x2,%ecx
801079df:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801079e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e8:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801079ef:	83 c9 10             	or     $0x10,%ecx
801079f2:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801079f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fb:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a02:	83 e1 9f             	and    $0xffffff9f,%ecx
80107a05:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a0e:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a15:	83 c9 80             	or     $0xffffff80,%ecx
80107a18:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a21:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107a28:	83 e1 f0             	and    $0xfffffff0,%ecx
80107a2b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a34:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107a3b:	83 e1 ef             	and    $0xffffffef,%ecx
80107a3e:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a47:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107a4e:	83 e1 df             	and    $0xffffffdf,%ecx
80107a51:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107a61:	83 c9 40             	or     $0x40,%ecx
80107a64:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a6d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107a74:	83 c9 80             	or     $0xffffff80,%ecx
80107a77:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a80:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107a86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a89:	83 c0 70             	add    $0x70,%eax
80107a8c:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107a93:	00 
80107a94:	89 04 24             	mov    %eax,(%esp)
80107a97:	e8 37 fb ff ff       	call   801075d3 <lgdt>
  loadgs(SEG_KCPU << 3);
80107a9c:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107aa3:	e8 6a fb ff ff       	call   80107612 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aab:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107ab1:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107ab8:	00 00 00 00 
}
80107abc:	83 c4 24             	add    $0x24,%esp
80107abf:	5b                   	pop    %ebx
80107ac0:	5d                   	pop    %ebp
80107ac1:	c3                   	ret    

80107ac2 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107ac2:	55                   	push   %ebp
80107ac3:	89 e5                	mov    %esp,%ebp
80107ac5:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107ac8:	8b 45 0c             	mov    0xc(%ebp),%eax
80107acb:	c1 e8 16             	shr    $0x16,%eax
80107ace:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107ad5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ad8:	01 d0                	add    %edx,%eax
80107ada:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107add:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ae0:	8b 00                	mov    (%eax),%eax
80107ae2:	83 e0 01             	and    $0x1,%eax
80107ae5:	85 c0                	test   %eax,%eax
80107ae7:	74 17                	je     80107b00 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107aec:	8b 00                	mov    (%eax),%eax
80107aee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107af3:	89 04 24             	mov    %eax,(%esp)
80107af6:	e8 44 fb ff ff       	call   8010763f <p2v>
80107afb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107afe:	eb 4b                	jmp    80107b4b <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107b00:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107b04:	74 0e                	je     80107b14 <walkpgdir+0x52>
80107b06:	e8 d7 af ff ff       	call   80102ae2 <kalloc>
80107b0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107b0e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107b12:	75 07                	jne    80107b1b <walkpgdir+0x59>
      return 0;
80107b14:	b8 00 00 00 00       	mov    $0x0,%eax
80107b19:	eb 47                	jmp    80107b62 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107b1b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107b22:	00 
80107b23:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b2a:	00 
80107b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b2e:	89 04 24             	mov    %eax,(%esp)
80107b31:	e8 be d5 ff ff       	call   801050f4 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b39:	89 04 24             	mov    %eax,(%esp)
80107b3c:	e8 f1 fa ff ff       	call   80107632 <v2p>
80107b41:	83 c8 07             	or     $0x7,%eax
80107b44:	89 c2                	mov    %eax,%edx
80107b46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b49:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107b4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b4e:	c1 e8 0c             	shr    $0xc,%eax
80107b51:	25 ff 03 00 00       	and    $0x3ff,%eax
80107b56:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b60:	01 d0                	add    %edx,%eax
}
80107b62:	c9                   	leave  
80107b63:	c3                   	ret    

80107b64 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107b64:	55                   	push   %ebp
80107b65:	89 e5                	mov    %esp,%ebp
80107b67:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107b6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b6d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107b75:	8b 55 0c             	mov    0xc(%ebp),%edx
80107b78:	8b 45 10             	mov    0x10(%ebp),%eax
80107b7b:	01 d0                	add    %edx,%eax
80107b7d:	83 e8 01             	sub    $0x1,%eax
80107b80:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b85:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107b88:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107b8f:	00 
80107b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b93:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b97:	8b 45 08             	mov    0x8(%ebp),%eax
80107b9a:	89 04 24             	mov    %eax,(%esp)
80107b9d:	e8 20 ff ff ff       	call   80107ac2 <walkpgdir>
80107ba2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107ba5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ba9:	75 07                	jne    80107bb2 <mappages+0x4e>
      return -1;
80107bab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107bb0:	eb 48                	jmp    80107bfa <mappages+0x96>
    if(*pte & PTE_P)
80107bb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107bb5:	8b 00                	mov    (%eax),%eax
80107bb7:	83 e0 01             	and    $0x1,%eax
80107bba:	85 c0                	test   %eax,%eax
80107bbc:	74 0c                	je     80107bca <mappages+0x66>
      panic("remap");
80107bbe:	c7 04 24 08 8a 10 80 	movl   $0x80108a08,(%esp)
80107bc5:	e8 70 89 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107bca:	8b 45 18             	mov    0x18(%ebp),%eax
80107bcd:	0b 45 14             	or     0x14(%ebp),%eax
80107bd0:	83 c8 01             	or     $0x1,%eax
80107bd3:	89 c2                	mov    %eax,%edx
80107bd5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107bd8:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bdd:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107be0:	75 08                	jne    80107bea <mappages+0x86>
      break;
80107be2:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107be3:	b8 00 00 00 00       	mov    $0x0,%eax
80107be8:	eb 10                	jmp    80107bfa <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107bea:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107bf1:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107bf8:	eb 8e                	jmp    80107b88 <mappages+0x24>
  return 0;
}
80107bfa:	c9                   	leave  
80107bfb:	c3                   	ret    

80107bfc <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107bfc:	55                   	push   %ebp
80107bfd:	89 e5                	mov    %esp,%ebp
80107bff:	53                   	push   %ebx
80107c00:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107c03:	e8 da ae ff ff       	call   80102ae2 <kalloc>
80107c08:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107c0b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107c0f:	75 0a                	jne    80107c1b <setupkvm+0x1f>
    return 0;
80107c11:	b8 00 00 00 00       	mov    $0x0,%eax
80107c16:	e9 98 00 00 00       	jmp    80107cb3 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107c1b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c22:	00 
80107c23:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c2a:	00 
80107c2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c2e:	89 04 24             	mov    %eax,(%esp)
80107c31:	e8 be d4 ff ff       	call   801050f4 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107c36:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107c3d:	e8 fd f9 ff ff       	call   8010763f <p2v>
80107c42:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107c47:	76 0c                	jbe    80107c55 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107c49:	c7 04 24 0e 8a 10 80 	movl   $0x80108a0e,(%esp)
80107c50:	e8 e5 88 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107c55:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107c5c:	eb 49                	jmp    80107ca7 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c61:	8b 48 0c             	mov    0xc(%eax),%ecx
80107c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c67:	8b 50 04             	mov    0x4(%eax),%edx
80107c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c6d:	8b 58 08             	mov    0x8(%eax),%ebx
80107c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c73:	8b 40 04             	mov    0x4(%eax),%eax
80107c76:	29 c3                	sub    %eax,%ebx
80107c78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c7b:	8b 00                	mov    (%eax),%eax
80107c7d:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107c81:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107c85:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107c89:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c90:	89 04 24             	mov    %eax,(%esp)
80107c93:	e8 cc fe ff ff       	call   80107b64 <mappages>
80107c98:	85 c0                	test   %eax,%eax
80107c9a:	79 07                	jns    80107ca3 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107c9c:	b8 00 00 00 00       	mov    $0x0,%eax
80107ca1:	eb 10                	jmp    80107cb3 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107ca3:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107ca7:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107cae:	72 ae                	jb     80107c5e <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107cb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107cb3:	83 c4 34             	add    $0x34,%esp
80107cb6:	5b                   	pop    %ebx
80107cb7:	5d                   	pop    %ebp
80107cb8:	c3                   	ret    

80107cb9 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107cb9:	55                   	push   %ebp
80107cba:	89 e5                	mov    %esp,%ebp
80107cbc:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107cbf:	e8 38 ff ff ff       	call   80107bfc <setupkvm>
80107cc4:	a3 38 51 11 80       	mov    %eax,0x80115138
  switchkvm();
80107cc9:	e8 02 00 00 00       	call   80107cd0 <switchkvm>
}
80107cce:	c9                   	leave  
80107ccf:	c3                   	ret    

80107cd0 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107cd0:	55                   	push   %ebp
80107cd1:	89 e5                	mov    %esp,%ebp
80107cd3:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107cd6:	a1 38 51 11 80       	mov    0x80115138,%eax
80107cdb:	89 04 24             	mov    %eax,(%esp)
80107cde:	e8 4f f9 ff ff       	call   80107632 <v2p>
80107ce3:	89 04 24             	mov    %eax,(%esp)
80107ce6:	e8 3c f9 ff ff       	call   80107627 <lcr3>
}
80107ceb:	c9                   	leave  
80107cec:	c3                   	ret    

80107ced <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107ced:	55                   	push   %ebp
80107cee:	89 e5                	mov    %esp,%ebp
80107cf0:	53                   	push   %ebx
80107cf1:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107cf4:	e8 fb d2 ff ff       	call   80104ff4 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107cf9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107cff:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d06:	83 c2 08             	add    $0x8,%edx
80107d09:	89 d3                	mov    %edx,%ebx
80107d0b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d12:	83 c2 08             	add    $0x8,%edx
80107d15:	c1 ea 10             	shr    $0x10,%edx
80107d18:	89 d1                	mov    %edx,%ecx
80107d1a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d21:	83 c2 08             	add    $0x8,%edx
80107d24:	c1 ea 18             	shr    $0x18,%edx
80107d27:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107d2e:	67 00 
80107d30:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107d37:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107d3d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107d44:	83 e1 f0             	and    $0xfffffff0,%ecx
80107d47:	83 c9 09             	or     $0x9,%ecx
80107d4a:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107d50:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107d57:	83 c9 10             	or     $0x10,%ecx
80107d5a:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107d60:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107d67:	83 e1 9f             	and    $0xffffff9f,%ecx
80107d6a:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107d70:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107d77:	83 c9 80             	or     $0xffffff80,%ecx
80107d7a:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107d80:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107d87:	83 e1 f0             	and    $0xfffffff0,%ecx
80107d8a:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107d90:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107d97:	83 e1 ef             	and    $0xffffffef,%ecx
80107d9a:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107da0:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107da7:	83 e1 df             	and    $0xffffffdf,%ecx
80107daa:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107db0:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107db7:	83 c9 40             	or     $0x40,%ecx
80107dba:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107dc0:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107dc7:	83 e1 7f             	and    $0x7f,%ecx
80107dca:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107dd0:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107dd6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107ddc:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107de3:	83 e2 ef             	and    $0xffffffef,%edx
80107de6:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107dec:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107df2:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107df8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107dfe:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107e05:	8b 52 08             	mov    0x8(%edx),%edx
80107e08:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107e0e:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107e11:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107e18:	e8 df f7 ff ff       	call   801075fc <ltr>
  if(p->pgdir == 0)
80107e1d:	8b 45 08             	mov    0x8(%ebp),%eax
80107e20:	8b 40 04             	mov    0x4(%eax),%eax
80107e23:	85 c0                	test   %eax,%eax
80107e25:	75 0c                	jne    80107e33 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107e27:	c7 04 24 1f 8a 10 80 	movl   $0x80108a1f,(%esp)
80107e2e:	e8 07 87 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107e33:	8b 45 08             	mov    0x8(%ebp),%eax
80107e36:	8b 40 04             	mov    0x4(%eax),%eax
80107e39:	89 04 24             	mov    %eax,(%esp)
80107e3c:	e8 f1 f7 ff ff       	call   80107632 <v2p>
80107e41:	89 04 24             	mov    %eax,(%esp)
80107e44:	e8 de f7 ff ff       	call   80107627 <lcr3>
  popcli();
80107e49:	e8 ea d1 ff ff       	call   80105038 <popcli>
}
80107e4e:	83 c4 14             	add    $0x14,%esp
80107e51:	5b                   	pop    %ebx
80107e52:	5d                   	pop    %ebp
80107e53:	c3                   	ret    

80107e54 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107e54:	55                   	push   %ebp
80107e55:	89 e5                	mov    %esp,%ebp
80107e57:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107e5a:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107e61:	76 0c                	jbe    80107e6f <inituvm+0x1b>
    panic("inituvm: more than a page");
80107e63:	c7 04 24 33 8a 10 80 	movl   $0x80108a33,(%esp)
80107e6a:	e8 cb 86 ff ff       	call   8010053a <panic>
  mem = kalloc();
80107e6f:	e8 6e ac ff ff       	call   80102ae2 <kalloc>
80107e74:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107e77:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e7e:	00 
80107e7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e86:	00 
80107e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e8a:	89 04 24             	mov    %eax,(%esp)
80107e8d:	e8 62 d2 ff ff       	call   801050f4 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e95:	89 04 24             	mov    %eax,(%esp)
80107e98:	e8 95 f7 ff ff       	call   80107632 <v2p>
80107e9d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107ea4:	00 
80107ea5:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107ea9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107eb0:	00 
80107eb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107eb8:	00 
80107eb9:	8b 45 08             	mov    0x8(%ebp),%eax
80107ebc:	89 04 24             	mov    %eax,(%esp)
80107ebf:	e8 a0 fc ff ff       	call   80107b64 <mappages>
  memmove(mem, init, sz);
80107ec4:	8b 45 10             	mov    0x10(%ebp),%eax
80107ec7:	89 44 24 08          	mov    %eax,0x8(%esp)
80107ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ece:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ed2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed5:	89 04 24             	mov    %eax,(%esp)
80107ed8:	e8 e6 d2 ff ff       	call   801051c3 <memmove>
}
80107edd:	c9                   	leave  
80107ede:	c3                   	ret    

80107edf <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107edf:	55                   	push   %ebp
80107ee0:	89 e5                	mov    %esp,%ebp
80107ee2:	53                   	push   %ebx
80107ee3:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107ee6:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ee9:	25 ff 0f 00 00       	and    $0xfff,%eax
80107eee:	85 c0                	test   %eax,%eax
80107ef0:	74 0c                	je     80107efe <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107ef2:	c7 04 24 50 8a 10 80 	movl   $0x80108a50,(%esp)
80107ef9:	e8 3c 86 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107efe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107f05:	e9 a9 00 00 00       	jmp    80107fb3 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107f0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80107f10:	01 d0                	add    %edx,%eax
80107f12:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f19:	00 
80107f1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f1e:	8b 45 08             	mov    0x8(%ebp),%eax
80107f21:	89 04 24             	mov    %eax,(%esp)
80107f24:	e8 99 fb ff ff       	call   80107ac2 <walkpgdir>
80107f29:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107f2c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f30:	75 0c                	jne    80107f3e <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107f32:	c7 04 24 73 8a 10 80 	movl   $0x80108a73,(%esp)
80107f39:	e8 fc 85 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80107f3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f41:	8b 00                	mov    (%eax),%eax
80107f43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f48:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f4e:	8b 55 18             	mov    0x18(%ebp),%edx
80107f51:	29 c2                	sub    %eax,%edx
80107f53:	89 d0                	mov    %edx,%eax
80107f55:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107f5a:	77 0f                	ja     80107f6b <loaduvm+0x8c>
      n = sz - i;
80107f5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f5f:	8b 55 18             	mov    0x18(%ebp),%edx
80107f62:	29 c2                	sub    %eax,%edx
80107f64:	89 d0                	mov    %edx,%eax
80107f66:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107f69:	eb 07                	jmp    80107f72 <loaduvm+0x93>
    else
      n = PGSIZE;
80107f6b:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107f72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f75:	8b 55 14             	mov    0x14(%ebp),%edx
80107f78:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107f7b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f7e:	89 04 24             	mov    %eax,(%esp)
80107f81:	e8 b9 f6 ff ff       	call   8010763f <p2v>
80107f86:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107f89:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107f8d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107f91:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f95:	8b 45 10             	mov    0x10(%ebp),%eax
80107f98:	89 04 24             	mov    %eax,(%esp)
80107f9b:	e8 c8 9d ff ff       	call   80101d68 <readi>
80107fa0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107fa3:	74 07                	je     80107fac <loaduvm+0xcd>
      return -1;
80107fa5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107faa:	eb 18                	jmp    80107fc4 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107fac:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107fb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb6:	3b 45 18             	cmp    0x18(%ebp),%eax
80107fb9:	0f 82 4b ff ff ff    	jb     80107f0a <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107fbf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107fc4:	83 c4 24             	add    $0x24,%esp
80107fc7:	5b                   	pop    %ebx
80107fc8:	5d                   	pop    %ebp
80107fc9:	c3                   	ret    

80107fca <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107fca:	55                   	push   %ebp
80107fcb:	89 e5                	mov    %esp,%ebp
80107fcd:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107fd0:	8b 45 10             	mov    0x10(%ebp),%eax
80107fd3:	85 c0                	test   %eax,%eax
80107fd5:	79 0a                	jns    80107fe1 <allocuvm+0x17>
    return 0;
80107fd7:	b8 00 00 00 00       	mov    $0x0,%eax
80107fdc:	e9 c1 00 00 00       	jmp    801080a2 <allocuvm+0xd8>
  if(newsz < oldsz)
80107fe1:	8b 45 10             	mov    0x10(%ebp),%eax
80107fe4:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107fe7:	73 08                	jae    80107ff1 <allocuvm+0x27>
    return oldsz;
80107fe9:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fec:	e9 b1 00 00 00       	jmp    801080a2 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107ff1:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ff4:	05 ff 0f 00 00       	add    $0xfff,%eax
80107ff9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ffe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108001:	e9 8d 00 00 00       	jmp    80108093 <allocuvm+0xc9>
    mem = kalloc();
80108006:	e8 d7 aa ff ff       	call   80102ae2 <kalloc>
8010800b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010800e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108012:	75 2c                	jne    80108040 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108014:	c7 04 24 91 8a 10 80 	movl   $0x80108a91,(%esp)
8010801b:	e8 80 83 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108020:	8b 45 0c             	mov    0xc(%ebp),%eax
80108023:	89 44 24 08          	mov    %eax,0x8(%esp)
80108027:	8b 45 10             	mov    0x10(%ebp),%eax
8010802a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010802e:	8b 45 08             	mov    0x8(%ebp),%eax
80108031:	89 04 24             	mov    %eax,(%esp)
80108034:	e8 6b 00 00 00       	call   801080a4 <deallocuvm>
      return 0;
80108039:	b8 00 00 00 00       	mov    $0x0,%eax
8010803e:	eb 62                	jmp    801080a2 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108040:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108047:	00 
80108048:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010804f:	00 
80108050:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108053:	89 04 24             	mov    %eax,(%esp)
80108056:	e8 99 d0 ff ff       	call   801050f4 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010805b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010805e:	89 04 24             	mov    %eax,(%esp)
80108061:	e8 cc f5 ff ff       	call   80107632 <v2p>
80108066:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108069:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108070:	00 
80108071:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108075:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010807c:	00 
8010807d:	89 54 24 04          	mov    %edx,0x4(%esp)
80108081:	8b 45 08             	mov    0x8(%ebp),%eax
80108084:	89 04 24             	mov    %eax,(%esp)
80108087:	e8 d8 fa ff ff       	call   80107b64 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010808c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108093:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108096:	3b 45 10             	cmp    0x10(%ebp),%eax
80108099:	0f 82 67 ff ff ff    	jb     80108006 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
8010809f:	8b 45 10             	mov    0x10(%ebp),%eax
}
801080a2:	c9                   	leave  
801080a3:	c3                   	ret    

801080a4 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801080a4:	55                   	push   %ebp
801080a5:	89 e5                	mov    %esp,%ebp
801080a7:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801080aa:	8b 45 10             	mov    0x10(%ebp),%eax
801080ad:	3b 45 0c             	cmp    0xc(%ebp),%eax
801080b0:	72 08                	jb     801080ba <deallocuvm+0x16>
    return oldsz;
801080b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801080b5:	e9 a4 00 00 00       	jmp    8010815e <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801080ba:	8b 45 10             	mov    0x10(%ebp),%eax
801080bd:	05 ff 0f 00 00       	add    $0xfff,%eax
801080c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801080ca:	e9 80 00 00 00       	jmp    8010814f <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801080cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080d9:	00 
801080da:	89 44 24 04          	mov    %eax,0x4(%esp)
801080de:	8b 45 08             	mov    0x8(%ebp),%eax
801080e1:	89 04 24             	mov    %eax,(%esp)
801080e4:	e8 d9 f9 ff ff       	call   80107ac2 <walkpgdir>
801080e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801080ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801080f0:	75 09                	jne    801080fb <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801080f2:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801080f9:	eb 4d                	jmp    80108148 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801080fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080fe:	8b 00                	mov    (%eax),%eax
80108100:	83 e0 01             	and    $0x1,%eax
80108103:	85 c0                	test   %eax,%eax
80108105:	74 41                	je     80108148 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108107:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010810a:	8b 00                	mov    (%eax),%eax
8010810c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108111:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108114:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108118:	75 0c                	jne    80108126 <deallocuvm+0x82>
        panic("kfree");
8010811a:	c7 04 24 a9 8a 10 80 	movl   $0x80108aa9,(%esp)
80108121:	e8 14 84 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108126:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108129:	89 04 24             	mov    %eax,(%esp)
8010812c:	e8 0e f5 ff ff       	call   8010763f <p2v>
80108131:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108134:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108137:	89 04 24             	mov    %eax,(%esp)
8010813a:	e8 0a a9 ff ff       	call   80102a49 <kfree>
      *pte = 0;
8010813f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108142:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108148:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010814f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108152:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108155:	0f 82 74 ff ff ff    	jb     801080cf <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
8010815b:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010815e:	c9                   	leave  
8010815f:	c3                   	ret    

80108160 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108160:	55                   	push   %ebp
80108161:	89 e5                	mov    %esp,%ebp
80108163:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108166:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010816a:	75 0c                	jne    80108178 <freevm+0x18>
    panic("freevm: no pgdir");
8010816c:	c7 04 24 af 8a 10 80 	movl   $0x80108aaf,(%esp)
80108173:	e8 c2 83 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108178:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010817f:	00 
80108180:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108187:	80 
80108188:	8b 45 08             	mov    0x8(%ebp),%eax
8010818b:	89 04 24             	mov    %eax,(%esp)
8010818e:	e8 11 ff ff ff       	call   801080a4 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108193:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010819a:	eb 48                	jmp    801081e4 <freevm+0x84>
    if(pgdir[i] & PTE_P){
8010819c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801081a6:	8b 45 08             	mov    0x8(%ebp),%eax
801081a9:	01 d0                	add    %edx,%eax
801081ab:	8b 00                	mov    (%eax),%eax
801081ad:	83 e0 01             	and    $0x1,%eax
801081b0:	85 c0                	test   %eax,%eax
801081b2:	74 2c                	je     801081e0 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801081b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801081be:	8b 45 08             	mov    0x8(%ebp),%eax
801081c1:	01 d0                	add    %edx,%eax
801081c3:	8b 00                	mov    (%eax),%eax
801081c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081ca:	89 04 24             	mov    %eax,(%esp)
801081cd:	e8 6d f4 ff ff       	call   8010763f <p2v>
801081d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801081d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081d8:	89 04 24             	mov    %eax,(%esp)
801081db:	e8 69 a8 ff ff       	call   80102a49 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801081e0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801081e4:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801081eb:	76 af                	jbe    8010819c <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801081ed:	8b 45 08             	mov    0x8(%ebp),%eax
801081f0:	89 04 24             	mov    %eax,(%esp)
801081f3:	e8 51 a8 ff ff       	call   80102a49 <kfree>
}
801081f8:	c9                   	leave  
801081f9:	c3                   	ret    

801081fa <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801081fa:	55                   	push   %ebp
801081fb:	89 e5                	mov    %esp,%ebp
801081fd:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108200:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108207:	00 
80108208:	8b 45 0c             	mov    0xc(%ebp),%eax
8010820b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010820f:	8b 45 08             	mov    0x8(%ebp),%eax
80108212:	89 04 24             	mov    %eax,(%esp)
80108215:	e8 a8 f8 ff ff       	call   80107ac2 <walkpgdir>
8010821a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010821d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108221:	75 0c                	jne    8010822f <clearpteu+0x35>
    panic("clearpteu");
80108223:	c7 04 24 c0 8a 10 80 	movl   $0x80108ac0,(%esp)
8010822a:	e8 0b 83 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
8010822f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108232:	8b 00                	mov    (%eax),%eax
80108234:	83 e0 fb             	and    $0xfffffffb,%eax
80108237:	89 c2                	mov    %eax,%edx
80108239:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823c:	89 10                	mov    %edx,(%eax)
}
8010823e:	c9                   	leave  
8010823f:	c3                   	ret    

80108240 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108240:	55                   	push   %ebp
80108241:	89 e5                	mov    %esp,%ebp
80108243:	53                   	push   %ebx
80108244:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108247:	e8 b0 f9 ff ff       	call   80107bfc <setupkvm>
8010824c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010824f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108253:	75 0a                	jne    8010825f <copyuvm+0x1f>
    return 0;
80108255:	b8 00 00 00 00       	mov    $0x0,%eax
8010825a:	e9 fd 00 00 00       	jmp    8010835c <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
8010825f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108266:	e9 d0 00 00 00       	jmp    8010833b <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010826b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108275:	00 
80108276:	89 44 24 04          	mov    %eax,0x4(%esp)
8010827a:	8b 45 08             	mov    0x8(%ebp),%eax
8010827d:	89 04 24             	mov    %eax,(%esp)
80108280:	e8 3d f8 ff ff       	call   80107ac2 <walkpgdir>
80108285:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108288:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010828c:	75 0c                	jne    8010829a <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
8010828e:	c7 04 24 ca 8a 10 80 	movl   $0x80108aca,(%esp)
80108295:	e8 a0 82 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
8010829a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010829d:	8b 00                	mov    (%eax),%eax
8010829f:	83 e0 01             	and    $0x1,%eax
801082a2:	85 c0                	test   %eax,%eax
801082a4:	75 0c                	jne    801082b2 <copyuvm+0x72>
      panic("copyuvm: page not present");
801082a6:	c7 04 24 e4 8a 10 80 	movl   $0x80108ae4,(%esp)
801082ad:	e8 88 82 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801082b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082b5:	8b 00                	mov    (%eax),%eax
801082b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082bc:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801082bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082c2:	8b 00                	mov    (%eax),%eax
801082c4:	25 ff 0f 00 00       	and    $0xfff,%eax
801082c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801082cc:	e8 11 a8 ff ff       	call   80102ae2 <kalloc>
801082d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
801082d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801082d8:	75 02                	jne    801082dc <copyuvm+0x9c>
      goto bad;
801082da:	eb 70                	jmp    8010834c <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
801082dc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801082df:	89 04 24             	mov    %eax,(%esp)
801082e2:	e8 58 f3 ff ff       	call   8010763f <p2v>
801082e7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082ee:	00 
801082ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801082f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801082f6:	89 04 24             	mov    %eax,(%esp)
801082f9:	e8 c5 ce ff ff       	call   801051c3 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
801082fe:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108301:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108304:	89 04 24             	mov    %eax,(%esp)
80108307:	e8 26 f3 ff ff       	call   80107632 <v2p>
8010830c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010830f:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108313:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108317:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010831e:	00 
8010831f:	89 54 24 04          	mov    %edx,0x4(%esp)
80108323:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108326:	89 04 24             	mov    %eax,(%esp)
80108329:	e8 36 f8 ff ff       	call   80107b64 <mappages>
8010832e:	85 c0                	test   %eax,%eax
80108330:	79 02                	jns    80108334 <copyuvm+0xf4>
      goto bad;
80108332:	eb 18                	jmp    8010834c <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108334:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010833b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108341:	0f 82 24 ff ff ff    	jb     8010826b <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108347:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010834a:	eb 10                	jmp    8010835c <copyuvm+0x11c>

bad:
  freevm(d);
8010834c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010834f:	89 04 24             	mov    %eax,(%esp)
80108352:	e8 09 fe ff ff       	call   80108160 <freevm>
  return 0;
80108357:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010835c:	83 c4 44             	add    $0x44,%esp
8010835f:	5b                   	pop    %ebx
80108360:	5d                   	pop    %ebp
80108361:	c3                   	ret    

80108362 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108362:	55                   	push   %ebp
80108363:	89 e5                	mov    %esp,%ebp
80108365:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108368:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010836f:	00 
80108370:	8b 45 0c             	mov    0xc(%ebp),%eax
80108373:	89 44 24 04          	mov    %eax,0x4(%esp)
80108377:	8b 45 08             	mov    0x8(%ebp),%eax
8010837a:	89 04 24             	mov    %eax,(%esp)
8010837d:	e8 40 f7 ff ff       	call   80107ac2 <walkpgdir>
80108382:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108388:	8b 00                	mov    (%eax),%eax
8010838a:	83 e0 01             	and    $0x1,%eax
8010838d:	85 c0                	test   %eax,%eax
8010838f:	75 07                	jne    80108398 <uva2ka+0x36>
    return 0;
80108391:	b8 00 00 00 00       	mov    $0x0,%eax
80108396:	eb 25                	jmp    801083bd <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108398:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839b:	8b 00                	mov    (%eax),%eax
8010839d:	83 e0 04             	and    $0x4,%eax
801083a0:	85 c0                	test   %eax,%eax
801083a2:	75 07                	jne    801083ab <uva2ka+0x49>
    return 0;
801083a4:	b8 00 00 00 00       	mov    $0x0,%eax
801083a9:	eb 12                	jmp    801083bd <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801083ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ae:	8b 00                	mov    (%eax),%eax
801083b0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083b5:	89 04 24             	mov    %eax,(%esp)
801083b8:	e8 82 f2 ff ff       	call   8010763f <p2v>
}
801083bd:	c9                   	leave  
801083be:	c3                   	ret    

801083bf <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801083bf:	55                   	push   %ebp
801083c0:	89 e5                	mov    %esp,%ebp
801083c2:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801083c5:	8b 45 10             	mov    0x10(%ebp),%eax
801083c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801083cb:	e9 87 00 00 00       	jmp    80108457 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
801083d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801083d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083d8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801083db:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083de:	89 44 24 04          	mov    %eax,0x4(%esp)
801083e2:	8b 45 08             	mov    0x8(%ebp),%eax
801083e5:	89 04 24             	mov    %eax,(%esp)
801083e8:	e8 75 ff ff ff       	call   80108362 <uva2ka>
801083ed:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801083f0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801083f4:	75 07                	jne    801083fd <copyout+0x3e>
      return -1;
801083f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801083fb:	eb 69                	jmp    80108466 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801083fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80108400:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108403:	29 c2                	sub    %eax,%edx
80108405:	89 d0                	mov    %edx,%eax
80108407:	05 00 10 00 00       	add    $0x1000,%eax
8010840c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010840f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108412:	3b 45 14             	cmp    0x14(%ebp),%eax
80108415:	76 06                	jbe    8010841d <copyout+0x5e>
      n = len;
80108417:	8b 45 14             	mov    0x14(%ebp),%eax
8010841a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010841d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108420:	8b 55 0c             	mov    0xc(%ebp),%edx
80108423:	29 c2                	sub    %eax,%edx
80108425:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108428:	01 c2                	add    %eax,%edx
8010842a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010842d:	89 44 24 08          	mov    %eax,0x8(%esp)
80108431:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108434:	89 44 24 04          	mov    %eax,0x4(%esp)
80108438:	89 14 24             	mov    %edx,(%esp)
8010843b:	e8 83 cd ff ff       	call   801051c3 <memmove>
    len -= n;
80108440:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108443:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108446:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108449:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010844c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010844f:	05 00 10 00 00       	add    $0x1000,%eax
80108454:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108457:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010845b:	0f 85 6f ff ff ff    	jne    801083d0 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108461:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108466:	c9                   	leave  
80108467:	c3                   	ret    
