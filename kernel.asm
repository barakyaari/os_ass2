
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
8010003a:	c7 44 24 04 e4 84 10 	movl   $0x801084e4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 ab 4e 00 00       	call   80104ef9 <initlock>

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
801000bd:	e8 58 4e 00 00       	call   80104f1a <acquire>

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
80100104:	e8 73 4e 00 00       	call   80104f7c <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 d1 4a 00 00       	call   80104bf5 <sleep>
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
8010017c:	e8 fb 4d 00 00       	call   80104f7c <release>
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
80100198:	c7 04 24 eb 84 10 80 	movl   $0x801084eb,(%esp)
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
801001ef:	c7 04 24 fc 84 10 80 	movl   $0x801084fc,(%esp)
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
80100229:	c7 04 24 03 85 10 80 	movl   $0x80108503,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 d9 4c 00 00       	call   80104f1a <acquire>

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
8010029d:	e8 2b 4a 00 00       	call   80104ccd <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 ce 4c 00 00       	call   80104f7c <release>
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
801003bb:	e8 5a 4b 00 00       	call   80104f1a <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 0a 85 10 80 	movl   $0x8010850a,(%esp)
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
801004b0:	c7 45 ec 13 85 10 80 	movl   $0x80108513,-0x14(%ebp)
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
80100533:	e8 44 4a 00 00       	call   80104f7c <release>
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
8010055f:	c7 04 24 1a 85 10 80 	movl   $0x8010851a,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 29 85 10 80 	movl   $0x80108529,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 37 4a 00 00       	call   80104fcb <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 2b 85 10 80 	movl   $0x8010852b,(%esp)
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
801006b2:	e8 86 4b 00 00       	call   8010523d <memmove>
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
801006e1:	e8 88 4a 00 00       	call   8010516e <memset>
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
80100776:	e8 aa 63 00 00       	call   80106b25 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 9e 63 00 00       	call   80106b25 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 92 63 00 00       	call   80106b25 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 85 63 00 00       	call   80106b25 <uartputc>
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
801007ba:	e8 5b 47 00 00       	call   80104f1a <acquire>
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
801007ea:	e8 d3 45 00 00       	call   80104dc2 <procdump>
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
801008f3:	e8 d5 43 00 00       	call   80104ccd <wakeup>
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
80100914:	e8 63 46 00 00       	call   80104f7c <release>
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
80100939:	e8 dc 45 00 00       	call   80104f1a <acquire>
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
80100959:	e8 1e 46 00 00       	call   80104f7c <release>
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
80100982:	e8 6e 42 00 00       	call   80104bf5 <sleep>

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
801009fe:	e8 79 45 00 00       	call   80104f7c <release>
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
80100a32:	e8 e3 44 00 00       	call   80104f1a <acquire>
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
80100a6c:	e8 0b 45 00 00       	call   80104f7c <release>
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
80100a87:	c7 44 24 04 2f 85 10 	movl   $0x8010852f,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a96:	e8 5e 44 00 00       	call   80104ef9 <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 37 85 10 	movl   $0x80108537,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100aaa:	e8 4a 44 00 00       	call   80104ef9 <initlock>

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
80100b73:	e8 fe 70 00 00       	call   80107c76 <setupkvm>
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
80100c14:	e8 2b 74 00 00       	call   80108044 <allocuvm>
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
80100c52:	e8 02 73 00 00       	call   80107f59 <loaduvm>
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
80100cc0:	e8 7f 73 00 00       	call   80108044 <allocuvm>
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
80100ce5:	e8 8a 75 00 00       	call   80108274 <clearpteu>
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
80100d1b:	e8 b8 46 00 00       	call   801053d8 <strlen>
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
80100d44:	e8 8f 46 00 00       	call   801053d8 <strlen>
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
80100d74:	e8 c0 76 00 00       	call   80108439 <copyout>
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
80100e1b:	e8 19 76 00 00       	call   80108439 <copyout>
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
80100e73:	e8 16 45 00 00       	call   8010538e <safestrcpy>

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
80100ec5:	e8 9d 6e 00 00       	call   80107d67 <switchuvm>
  freevm(oldpgdir);
80100eca:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecd:	89 04 24             	mov    %eax,(%esp)
80100ed0:	e8 05 73 00 00       	call   801081da <freevm>
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
80100ee8:	e8 ed 72 00 00       	call   801081da <freevm>
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
80100f10:	c7 44 24 04 3d 85 10 	movl   $0x8010853d,0x4(%esp)
80100f17:	80 
80100f18:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f1f:	e8 d5 3f 00 00       	call   80104ef9 <initlock>
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
80100f33:	e8 e2 3f 00 00       	call   80104f1a <acquire>
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
80100f5c:	e8 1b 40 00 00       	call   80104f7c <release>
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
80100f7a:	e8 fd 3f 00 00       	call   80104f7c <release>
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
80100f93:	e8 82 3f 00 00       	call   80104f1a <acquire>
  if(f->ref < 1)
80100f98:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9b:	8b 40 04             	mov    0x4(%eax),%eax
80100f9e:	85 c0                	test   %eax,%eax
80100fa0:	7f 0c                	jg     80100fae <filedup+0x28>
    panic("filedup");
80100fa2:	c7 04 24 44 85 10 80 	movl   $0x80108544,(%esp)
80100fa9:	e8 8c f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fae:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb1:	8b 40 04             	mov    0x4(%eax),%eax
80100fb4:	8d 50 01             	lea    0x1(%eax),%edx
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fbd:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fc4:	e8 b3 3f 00 00       	call   80104f7c <release>
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
80100fdb:	e8 3a 3f 00 00       	call   80104f1a <acquire>
  if(f->ref < 1)
80100fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe3:	8b 40 04             	mov    0x4(%eax),%eax
80100fe6:	85 c0                	test   %eax,%eax
80100fe8:	7f 0c                	jg     80100ff6 <fileclose+0x28>
    panic("fileclose");
80100fea:	c7 04 24 4c 85 10 80 	movl   $0x8010854c,(%esp)
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
80101016:	e8 61 3f 00 00       	call   80104f7c <release>
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
80101060:	e8 17 3f 00 00       	call   80104f7c <release>
  
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
801011a1:	c7 04 24 56 85 10 80 	movl   $0x80108556,(%esp)
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
801012ad:	c7 04 24 5f 85 10 80 	movl   $0x8010855f,(%esp)
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
801012df:	c7 04 24 6f 85 10 80 	movl   $0x8010856f,(%esp)
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
80101325:	e8 13 3f 00 00       	call   8010523d <memmove>
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
8010136b:	e8 fe 3d 00 00       	call   8010516e <memset>
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
801014c8:	c7 04 24 79 85 10 80 	movl   $0x80108579,(%esp)
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
8010155a:	c7 04 24 8f 85 10 80 	movl   $0x8010858f,(%esp)
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
801015aa:	c7 44 24 04 a2 85 10 	movl   $0x801085a2,0x4(%esp)
801015b1:	80 
801015b2:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801015b9:	e8 3b 39 00 00       	call   80104ef9 <initlock>
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
8010163b:	e8 2e 3b 00 00       	call   8010516e <memset>
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
80101691:	c7 04 24 a9 85 10 80 	movl   $0x801085a9,(%esp)
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
8010173a:	e8 fe 3a 00 00       	call   8010523d <memmove>
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
80101764:	e8 b1 37 00 00       	call   80104f1a <acquire>

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
801017ae:	e8 c9 37 00 00       	call   80104f7c <release>
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
801017e1:	c7 04 24 bb 85 10 80 	movl   $0x801085bb,(%esp)
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
8010181f:	e8 58 37 00 00       	call   80104f7c <release>

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
80101836:	e8 df 36 00 00       	call   80104f1a <acquire>
  ip->ref++;
8010183b:	8b 45 08             	mov    0x8(%ebp),%eax
8010183e:	8b 40 08             	mov    0x8(%eax),%eax
80101841:	8d 50 01             	lea    0x1(%eax),%edx
80101844:	8b 45 08             	mov    0x8(%ebp),%eax
80101847:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010184a:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101851:	e8 26 37 00 00       	call   80104f7c <release>
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
80101871:	c7 04 24 cb 85 10 80 	movl   $0x801085cb,(%esp)
80101878:	e8 bd ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010187d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101884:	e8 91 36 00 00       	call   80104f1a <acquire>
  while(ip->flags & I_BUSY)
80101889:	eb 13                	jmp    8010189e <ilock+0x43>
    sleep(ip, &icache.lock);
8010188b:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
80101892:	80 
80101893:	8b 45 08             	mov    0x8(%ebp),%eax
80101896:	89 04 24             	mov    %eax,(%esp)
80101899:	e8 57 33 00 00       	call   80104bf5 <sleep>

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
801018c3:	e8 b4 36 00 00       	call   80104f7c <release>

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
8010196e:	e8 ca 38 00 00       	call   8010523d <memmove>
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
8010199b:	c7 04 24 d1 85 10 80 	movl   $0x801085d1,(%esp)
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
801019cc:	c7 04 24 e0 85 10 80 	movl   $0x801085e0,(%esp)
801019d3:	e8 62 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019d8:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801019df:	e8 36 35 00 00       	call   80104f1a <acquire>
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
801019fb:	e8 cd 32 00 00       	call   80104ccd <wakeup>
  release(&icache.lock);
80101a00:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a07:	e8 70 35 00 00       	call   80104f7c <release>
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
80101a1b:	e8 fa 34 00 00       	call   80104f1a <acquire>
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
80101a59:	c7 04 24 e8 85 10 80 	movl   $0x801085e8,(%esp)
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
80101a7d:	e8 fa 34 00 00       	call   80104f7c <release>
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
80101aa8:	e8 6d 34 00 00       	call   80104f1a <acquire>
    ip->flags = 0;
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aba:	89 04 24             	mov    %eax,(%esp)
80101abd:	e8 0b 32 00 00       	call   80104ccd <wakeup>
  }
  ip->ref--;
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 08             	mov    0x8(%eax),%eax
80101ac8:	8d 50 ff             	lea    -0x1(%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ad1:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101ad8:	e8 9f 34 00 00       	call   80104f7c <release>
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
80101bf8:	c7 04 24 f2 85 10 80 	movl   $0x801085f2,(%esp)
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
80101e99:	e8 9f 33 00 00       	call   8010523d <memmove>
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
80101ff8:	e8 40 32 00 00       	call   8010523d <memmove>
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
80102076:	e8 65 32 00 00       	call   801052e0 <strncmp>
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
80102090:	c7 04 24 05 86 10 80 	movl   $0x80108605,(%esp)
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
801020ce:	c7 04 24 17 86 10 80 	movl   $0x80108617,(%esp)
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
801021b3:	c7 04 24 17 86 10 80 	movl   $0x80108617,(%esp)
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
801021f8:	e8 39 31 00 00       	call   80105336 <strncpy>
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
8010222a:	c7 04 24 24 86 10 80 	movl   $0x80108624,(%esp)
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
801022af:	e8 89 2f 00 00       	call   8010523d <memmove>
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
801022ca:	e8 6e 2f 00 00       	call   8010523d <memmove>
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
80102519:	c7 44 24 04 2c 86 10 	movl   $0x8010862c,0x4(%esp)
80102520:	80 
80102521:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102528:	e8 cc 29 00 00       	call   80104ef9 <initlock>
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
801025c5:	c7 04 24 30 86 10 80 	movl   $0x80108630,(%esp)
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
801026eb:	e8 2a 28 00 00       	call   80104f1a <acquire>
  if((b = idequeue) == 0){
801026f0:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801026f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026fc:	75 11                	jne    8010270f <ideintr+0x31>
    release(&idelock);
801026fe:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102705:	e8 72 28 00 00       	call   80104f7c <release>
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
80102778:	e8 50 25 00 00       	call   80104ccd <wakeup>
  
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
8010279a:	e8 dd 27 00 00       	call   80104f7c <release>
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
801027b3:	c7 04 24 39 86 10 80 	movl   $0x80108639,(%esp)
801027ba:	e8 7b dd ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027bf:	8b 45 08             	mov    0x8(%ebp),%eax
801027c2:	8b 00                	mov    (%eax),%eax
801027c4:	83 e0 06             	and    $0x6,%eax
801027c7:	83 f8 02             	cmp    $0x2,%eax
801027ca:	75 0c                	jne    801027d8 <iderw+0x37>
    panic("iderw: nothing to do");
801027cc:	c7 04 24 4d 86 10 80 	movl   $0x8010864d,(%esp)
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
801027eb:	c7 04 24 62 86 10 80 	movl   $0x80108662,(%esp)
801027f2:	e8 43 dd ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
801027f7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027fe:	e8 17 27 00 00       	call   80104f1a <acquire>

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
80102859:	e8 97 23 00 00       	call   80104bf5 <sleep>
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
80102872:	e8 05 27 00 00       	call   80104f7c <release>
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
80102900:	c7 04 24 80 86 10 80 	movl   $0x80108680,(%esp)
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
801029ba:	c7 44 24 04 b2 86 10 	movl   $0x801086b2,0x4(%esp)
801029c1:	80 
801029c2:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
801029c9:	e8 2b 25 00 00       	call   80104ef9 <initlock>
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
80102a76:	c7 04 24 b7 86 10 80 	movl   $0x801086b7,(%esp)
80102a7d:	e8 b8 da ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102a82:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102a89:	00 
80102a8a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102a91:	00 
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 d1 26 00 00       	call   8010516e <memset>

  if(kmem.use_lock)
80102a9d:	a1 54 22 11 80       	mov    0x80112254,%eax
80102aa2:	85 c0                	test   %eax,%eax
80102aa4:	74 0c                	je     80102ab2 <kfree+0x69>
    acquire(&kmem.lock);
80102aa6:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102aad:	e8 68 24 00 00       	call   80104f1a <acquire>
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
80102adb:	e8 9c 24 00 00       	call   80104f7c <release>
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
80102af8:	e8 1d 24 00 00       	call   80104f1a <acquire>
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
80102b25:	e8 52 24 00 00       	call   80104f7c <release>
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
80102ea5:	c7 04 24 c0 86 10 80 	movl   $0x801086c0,(%esp)
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
80103108:	e8 d8 20 00 00       	call   801051e5 <memcmp>
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
80103208:	c7 44 24 04 ec 86 10 	movl   $0x801086ec,0x4(%esp)
8010320f:	80 
80103210:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103217:	e8 dd 1c 00 00       	call   80104ef9 <initlock>
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
801032cb:	e8 6d 1f 00 00       	call   8010523d <memmove>
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
8010341d:	e8 f8 1a 00 00       	call   80104f1a <acquire>
  while(1){
    if(log.committing){
80103422:	a1 a0 22 11 80       	mov    0x801122a0,%eax
80103427:	85 c0                	test   %eax,%eax
80103429:	74 16                	je     80103441 <begin_op+0x31>
      sleep(&log, &log.lock);
8010342b:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103432:	80 
80103433:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010343a:	e8 b6 17 00 00       	call   80104bf5 <sleep>
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
8010346e:	e8 82 17 00 00       	call   80104bf5 <sleep>
80103473:	eb 1b                	jmp    80103490 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103475:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010347a:	83 c0 01             	add    $0x1,%eax
8010347d:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
80103482:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103489:	e8 ee 1a 00 00       	call   80104f7c <release>
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
801034a8:	e8 6d 1a 00 00       	call   80104f1a <acquire>
  log.outstanding -= 1;
801034ad:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034b2:	83 e8 01             	sub    $0x1,%eax
801034b5:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
801034ba:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801034bf:	85 c0                	test   %eax,%eax
801034c1:	74 0c                	je     801034cf <end_op+0x3b>
    panic("log.committing");
801034c3:	c7 04 24 f0 86 10 80 	movl   $0x801086f0,(%esp)
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
801034f2:	e8 d6 17 00 00       	call   80104ccd <wakeup>
  }
  release(&log.lock);
801034f7:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034fe:	e8 79 1a 00 00       	call   80104f7c <release>

  if(do_commit){
80103503:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103507:	74 33                	je     8010353c <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103509:	e8 de 00 00 00       	call   801035ec <commit>
    acquire(&log.lock);
8010350e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103515:	e8 00 1a 00 00       	call   80104f1a <acquire>
    log.committing = 0;
8010351a:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
80103521:	00 00 00 
    wakeup(&log);
80103524:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010352b:	e8 9d 17 00 00       	call   80104ccd <wakeup>
    release(&log.lock);
80103530:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103537:	e8 40 1a 00 00       	call   80104f7c <release>
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
801035b2:	e8 86 1c 00 00       	call   8010523d <memmove>
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
8010363d:	c7 04 24 ff 86 10 80 	movl   $0x801086ff,(%esp)
80103644:	e8 f1 ce ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103649:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010364e:	85 c0                	test   %eax,%eax
80103650:	7f 0c                	jg     8010365e <log_write+0x43>
    panic("log_write outside of trans");
80103652:	c7 04 24 15 87 10 80 	movl   $0x80108715,(%esp)
80103659:	e8 dc ce ff ff       	call   8010053a <panic>

  acquire(&log.lock);
8010365e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103665:	e8 b0 18 00 00       	call   80104f1a <acquire>
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
801036dc:	e8 9b 18 00 00       	call   80104f7c <release>
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
80103734:	e8 fa 45 00 00       	call   80107d33 <kvmalloc>
  mpinit();        // collect info about this machine
80103739:	e8 46 04 00 00       	call   80103b84 <mpinit>
  lapicinit();
8010373e:	e8 dc f5 ff ff       	call   80102d1f <lapicinit>
  seginit();       // set up segments
80103743:	e8 7e 3f 00 00       	call   801076c6 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103748:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010374e:	0f b6 00             	movzbl (%eax),%eax
80103751:	0f b6 c0             	movzbl %al,%eax
80103754:	89 44 24 04          	mov    %eax,0x4(%esp)
80103758:	c7 04 24 30 87 10 80 	movl   $0x80108730,(%esp)
8010375f:	e8 3c cc ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103764:	e8 79 06 00 00       	call   80103de2 <picinit>
  ioapicinit();    // another interrupt controller
80103769:	e8 3c f1 ff ff       	call   801028aa <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010376e:	e8 0e d3 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
80103773:	e8 9d 32 00 00       	call   80106a15 <uartinit>
  pinit();         // process table
80103778:	e8 97 0b 00 00       	call   80104314 <pinit>
  tvinit();        // trap vectors
8010377d:	e8 45 2e 00 00       	call   801065c7 <tvinit>
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
8010379f:	e8 6e 2d 00 00       	call   80106512 <timerinit>
  startothers();   // start other processors
801037a4:	e8 7f 00 00 00       	call   80103828 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801037a9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801037b0:	8e 
801037b1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801037b8:	e8 2f f2 ff ff       	call   801029ec <kinit2>
  userinit();      // first user process
801037bd:	e8 98 0c 00 00       	call   8010445a <userinit>
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
801037cd:	e8 78 45 00 00       	call   80107d4a <switchkvm>
  seginit();
801037d2:	e8 ef 3e 00 00       	call   801076c6 <seginit>
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
801037f7:	c7 04 24 47 87 10 80 	movl   $0x80108747,(%esp)
801037fe:	e8 9d cb ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103803:	e8 33 2f 00 00       	call   8010673b <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103808:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010380e:	05 a8 00 00 00       	add    $0xa8,%eax
80103813:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010381a:	00 
8010381b:	89 04 24             	mov    %eax,(%esp)
8010381e:	e8 da fe ff ff       	call   801036fd <xchg>
  scheduler();     // start running processes
80103823:	e8 0f 12 00 00       	call   80104a37 <scheduler>

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
80103855:	e8 e3 19 00 00       	call   8010523d <memmove>

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
801039d7:	c7 44 24 04 58 87 10 	movl   $0x80108758,0x4(%esp)
801039de:	80 
801039df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e2:	89 04 24             	mov    %eax,(%esp)
801039e5:	e8 fb 17 00 00       	call   801051e5 <memcmp>
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
80103b18:	c7 44 24 04 5d 87 10 	movl   $0x8010875d,0x4(%esp)
80103b1f:	80 
80103b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b23:	89 04 24             	mov    %eax,(%esp)
80103b26:	e8 ba 16 00 00       	call   801051e5 <memcmp>
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
80103bf4:	8b 04 85 a0 87 10 80 	mov    -0x7fef7860(,%eax,4),%eax
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
80103c2d:	c7 04 24 62 87 10 80 	movl   $0x80108762,(%esp)
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
80103cc0:	c7 04 24 80 87 10 80 	movl   $0x80108780,(%esp)
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
80103fb9:	c7 44 24 04 b4 87 10 	movl   $0x801087b4,0x4(%esp)
80103fc0:	80 
80103fc1:	89 04 24             	mov    %eax,(%esp)
80103fc4:	e8 30 0f 00 00       	call   80104ef9 <initlock>
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
80104070:	e8 a5 0e 00 00       	call   80104f1a <acquire>
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
80104093:	e8 35 0c 00 00       	call   80104ccd <wakeup>
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
801040b2:	e8 16 0c 00 00       	call   80104ccd <wakeup>
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
801040d7:	e8 a0 0e 00 00       	call   80104f7c <release>
    kfree((char*)p);
801040dc:	8b 45 08             	mov    0x8(%ebp),%eax
801040df:	89 04 24             	mov    %eax,(%esp)
801040e2:	e8 62 e9 ff ff       	call   80102a49 <kfree>
801040e7:	eb 0b                	jmp    801040f4 <pipeclose+0x90>
  } else
    release(&p->lock);
801040e9:	8b 45 08             	mov    0x8(%ebp),%eax
801040ec:	89 04 24             	mov    %eax,(%esp)
801040ef:	e8 88 0e 00 00       	call   80104f7c <release>
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
80104102:	e8 13 0e 00 00       	call   80104f1a <acquire>
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
80104135:	e8 42 0e 00 00       	call   80104f7c <release>
        return -1;
8010413a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413f:	e9 9f 00 00 00       	jmp    801041e3 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104144:	8b 45 08             	mov    0x8(%ebp),%eax
80104147:	05 34 02 00 00       	add    $0x234,%eax
8010414c:	89 04 24             	mov    %eax,(%esp)
8010414f:	e8 79 0b 00 00       	call   80104ccd <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104154:	8b 45 08             	mov    0x8(%ebp),%eax
80104157:	8b 55 08             	mov    0x8(%ebp),%edx
8010415a:	81 c2 38 02 00 00    	add    $0x238,%edx
80104160:	89 44 24 04          	mov    %eax,0x4(%esp)
80104164:	89 14 24             	mov    %edx,(%esp)
80104167:	e8 89 0a 00 00       	call   80104bf5 <sleep>
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
801041d0:	e8 f8 0a 00 00       	call   80104ccd <wakeup>
  release(&p->lock);
801041d5:	8b 45 08             	mov    0x8(%ebp),%eax
801041d8:	89 04 24             	mov    %eax,(%esp)
801041db:	e8 9c 0d 00 00       	call   80104f7c <release>
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
801041f2:	e8 23 0d 00 00       	call   80104f1a <acquire>
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
8010420c:	e8 6b 0d 00 00       	call   80104f7c <release>
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
8010422e:	e8 c2 09 00 00       	call   80104bf5 <sleep>
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
801042bd:	e8 0b 0a 00 00       	call   80104ccd <wakeup>
  release(&p->lock);
801042c2:	8b 45 08             	mov    0x8(%ebp),%eax
801042c5:	89 04 24             	mov    %eax,(%esp)
801042c8:	e8 af 0c 00 00       	call   80104f7c <release>
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

801042ec <cas>:
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
}

static inline int
cas(volatile int *addr, int expected, int newval){
801042ec:	55                   	push   %ebp
801042ed:	89 e5                	mov    %esp,%ebp
801042ef:	83 ec 10             	sub    $0x10,%esp

	int result = 1;
801042f2:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
	  asm volatile(
801042f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801042fc:	8b 55 08             	mov    0x8(%ebp),%edx
801042ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
80104302:	f0 0f b1 0a          	lock cmpxchg %ecx,(%edx)
80104306:	74 07                	je     8010430f <success>
80104308:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

8010430f <success>:
	  	"movl $0, %0\n\t"
	  	"success:\n\t"
	  	: "=m"(result)
	  	:  "r" (expected), "r" (addr), "r"(newval)
	    : "memory");
	  return result;
8010430f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104312:	c9                   	leave  
80104313:	c3                   	ret    

80104314 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104314:	55                   	push   %ebp
80104315:	89 e5                	mov    %esp,%ebp
80104317:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010431a:	c7 44 24 04 b9 87 10 	movl   $0x801087b9,0x4(%esp)
80104321:	80 
80104322:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104329:	e8 cb 0b 00 00       	call   80104ef9 <initlock>
}
8010432e:	c9                   	leave  
8010432f:	c3                   	ret    

80104330 <allocpid>:

int 
allocpid(void) 
{
80104330:	55                   	push   %ebp
80104331:	89 e5                	mov    %esp,%ebp
80104333:	83 ec 28             	sub    $0x28,%esp
  int pid;
  acquire(&ptable.lock);
80104336:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010433d:	e8 d8 0b 00 00       	call   80104f1a <acquire>
  pid = nextpid++;
80104342:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104347:	8d 50 01             	lea    0x1(%eax),%edx
8010434a:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
80104350:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&ptable.lock);
80104353:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010435a:	e8 1d 0c 00 00       	call   80104f7c <release>
  return pid;
8010435f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104362:	c9                   	leave  
80104363:	c3                   	ret    

80104364 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104364:	55                   	push   %ebp
80104365:	89 e5                	mov    %esp,%ebp
80104367:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010436a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104371:	e8 a4 0b 00 00       	call   80104f1a <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104376:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
8010437d:	eb 47                	jmp    801043c6 <allocproc+0x62>
    if(p->state == UNUSED)
8010437f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104382:	8b 40 0c             	mov    0xc(%eax),%eax
80104385:	85 c0                	test   %eax,%eax
80104387:	75 39                	jne    801043c2 <allocproc+0x5e>
      goto found;
80104389:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;  
8010438a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010438d:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  release(&ptable.lock);
80104394:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010439b:	e8 dc 0b 00 00       	call   80104f7c <release>

  p->pid = allocpid();
801043a0:	e8 8b ff ff ff       	call   80104330 <allocpid>
801043a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043a8:	89 42 10             	mov    %eax,0x10(%edx)

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801043ab:	e8 32 e7 ff ff       	call   80102ae2 <kalloc>
801043b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043b3:	89 42 08             	mov    %eax,0x8(%edx)
801043b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043b9:	8b 40 08             	mov    0x8(%eax),%eax
801043bc:	85 c0                	test   %eax,%eax
801043be:	75 33                	jne    801043f3 <allocproc+0x8f>
801043c0:	eb 20                	jmp    801043e2 <allocproc+0x7e>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801043c2:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801043c6:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
801043cd:	72 b0                	jb     8010437f <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801043cf:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043d6:	e8 a1 0b 00 00       	call   80104f7c <release>
  return 0;
801043db:	b8 00 00 00 00       	mov    $0x0,%eax
801043e0:	eb 76                	jmp    80104458 <allocproc+0xf4>

  p->pid = allocpid();

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801043e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043e5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801043ec:	b8 00 00 00 00       	mov    $0x0,%eax
801043f1:	eb 65                	jmp    80104458 <allocproc+0xf4>
  }
  sp = p->kstack + KSTACKSIZE;
801043f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043f6:	8b 40 08             	mov    0x8(%eax),%eax
801043f9:	05 00 10 00 00       	add    $0x1000,%eax
801043fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104401:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104405:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104408:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010440b:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010440e:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104412:	ba 82 65 10 80       	mov    $0x80106582,%edx
80104417:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010441a:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010441c:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104423:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104426:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104429:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442c:	8b 40 1c             	mov    0x1c(%eax),%eax
8010442f:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104436:	00 
80104437:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010443e:	00 
8010443f:	89 04 24             	mov    %eax,(%esp)
80104442:	e8 27 0d 00 00       	call   8010516e <memset>
  p->context->eip = (uint)forkret;
80104447:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444a:	8b 40 1c             	mov    0x1c(%eax),%eax
8010444d:	ba c9 4b 10 80       	mov    $0x80104bc9,%edx
80104452:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104455:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104458:	c9                   	leave  
80104459:	c3                   	ret    

8010445a <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010445a:	55                   	push   %ebp
8010445b:	89 e5                	mov    %esp,%ebp
8010445d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104460:	e8 ff fe ff ff       	call   80104364 <allocproc>
80104465:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104468:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010446b:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104470:	e8 01 38 00 00       	call   80107c76 <setupkvm>
80104475:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104478:	89 42 04             	mov    %eax,0x4(%edx)
8010447b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447e:	8b 40 04             	mov    0x4(%eax),%eax
80104481:	85 c0                	test   %eax,%eax
80104483:	75 0c                	jne    80104491 <userinit+0x37>
    panic("userinit: out of memory?");
80104485:	c7 04 24 c0 87 10 80 	movl   $0x801087c0,(%esp)
8010448c:	e8 a9 c0 ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104491:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104496:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104499:	8b 40 04             	mov    0x4(%eax),%eax
8010449c:	89 54 24 08          	mov    %edx,0x8(%esp)
801044a0:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801044a7:	80 
801044a8:	89 04 24             	mov    %eax,(%esp)
801044ab:	e8 1e 3a 00 00       	call   80107ece <inituvm>
  p->sz = PGSIZE;
801044b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b3:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801044b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044bc:	8b 40 18             	mov    0x18(%eax),%eax
801044bf:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801044c6:	00 
801044c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801044ce:	00 
801044cf:	89 04 24             	mov    %eax,(%esp)
801044d2:	e8 97 0c 00 00       	call   8010516e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801044d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044da:	8b 40 18             	mov    0x18(%eax),%eax
801044dd:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801044e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e6:	8b 40 18             	mov    0x18(%eax),%eax
801044e9:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801044ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f2:	8b 40 18             	mov    0x18(%eax),%eax
801044f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044f8:	8b 52 18             	mov    0x18(%edx),%edx
801044fb:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801044ff:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104506:	8b 40 18             	mov    0x18(%eax),%eax
80104509:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010450c:	8b 52 18             	mov    0x18(%edx),%edx
8010450f:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104513:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104517:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010451a:	8b 40 18             	mov    0x18(%eax),%eax
8010451d:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104524:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104527:	8b 40 18             	mov    0x18(%eax),%eax
8010452a:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104534:	8b 40 18             	mov    0x18(%eax),%eax
80104537:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010453e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104541:	83 c0 6c             	add    $0x6c,%eax
80104544:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010454b:	00 
8010454c:	c7 44 24 04 d9 87 10 	movl   $0x801087d9,0x4(%esp)
80104553:	80 
80104554:	89 04 24             	mov    %eax,(%esp)
80104557:	e8 32 0e 00 00       	call   8010538e <safestrcpy>
  p->cwd = namei("/");
8010455c:	c7 04 24 e2 87 10 80 	movl   $0x801087e2,(%esp)
80104563:	e8 9e de ff ff       	call   80102406 <namei>
80104568:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010456b:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
8010456e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104571:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104578:	c9                   	leave  
80104579:	c3                   	ret    

8010457a <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010457a:	55                   	push   %ebp
8010457b:	89 e5                	mov    %esp,%ebp
8010457d:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104580:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104586:	8b 00                	mov    (%eax),%eax
80104588:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010458b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010458f:	7e 34                	jle    801045c5 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104591:	8b 55 08             	mov    0x8(%ebp),%edx
80104594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104597:	01 c2                	add    %eax,%edx
80104599:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010459f:	8b 40 04             	mov    0x4(%eax),%eax
801045a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801045a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801045ad:	89 04 24             	mov    %eax,(%esp)
801045b0:	e8 8f 3a 00 00       	call   80108044 <allocuvm>
801045b5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801045b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801045bc:	75 41                	jne    801045ff <growproc+0x85>
      return -1;
801045be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045c3:	eb 58                	jmp    8010461d <growproc+0xa3>
  } else if(n < 0){
801045c5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801045c9:	79 34                	jns    801045ff <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801045cb:	8b 55 08             	mov    0x8(%ebp),%edx
801045ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d1:	01 c2                	add    %eax,%edx
801045d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045d9:	8b 40 04             	mov    0x4(%eax),%eax
801045dc:	89 54 24 08          	mov    %edx,0x8(%esp)
801045e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801045e7:	89 04 24             	mov    %eax,(%esp)
801045ea:	e8 2f 3b 00 00       	call   8010811e <deallocuvm>
801045ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
801045f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801045f6:	75 07                	jne    801045ff <growproc+0x85>
      return -1;
801045f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045fd:	eb 1e                	jmp    8010461d <growproc+0xa3>
  }
  proc->sz = sz;
801045ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104605:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104608:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010460a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104610:	89 04 24             	mov    %eax,(%esp)
80104613:	e8 4f 37 00 00       	call   80107d67 <switchuvm>
  return 0;
80104618:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010461d:	c9                   	leave  
8010461e:	c3                   	ret    

8010461f <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010461f:	55                   	push   %ebp
80104620:	89 e5                	mov    %esp,%ebp
80104622:	57                   	push   %edi
80104623:	56                   	push   %esi
80104624:	53                   	push   %ebx
80104625:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104628:	e8 37 fd ff ff       	call   80104364 <allocproc>
8010462d:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104630:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104634:	75 0a                	jne    80104640 <fork+0x21>
    return -1;
80104636:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010463b:	e9 52 01 00 00       	jmp    80104792 <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104640:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104646:	8b 10                	mov    (%eax),%edx
80104648:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010464e:	8b 40 04             	mov    0x4(%eax),%eax
80104651:	89 54 24 04          	mov    %edx,0x4(%esp)
80104655:	89 04 24             	mov    %eax,(%esp)
80104658:	e8 5d 3c 00 00       	call   801082ba <copyuvm>
8010465d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104660:	89 42 04             	mov    %eax,0x4(%edx)
80104663:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104666:	8b 40 04             	mov    0x4(%eax),%eax
80104669:	85 c0                	test   %eax,%eax
8010466b:	75 2c                	jne    80104699 <fork+0x7a>
    kfree(np->kstack);
8010466d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104670:	8b 40 08             	mov    0x8(%eax),%eax
80104673:	89 04 24             	mov    %eax,(%esp)
80104676:	e8 ce e3 ff ff       	call   80102a49 <kfree>
    np->kstack = 0;
8010467b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010467e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104685:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104688:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010468f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104694:	e9 f9 00 00 00       	jmp    80104792 <fork+0x173>
  }
  np->sz = proc->sz;
80104699:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010469f:	8b 10                	mov    (%eax),%edx
801046a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046a4:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801046a6:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801046ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046b0:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801046b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046b6:	8b 50 18             	mov    0x18(%eax),%edx
801046b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046bf:	8b 40 18             	mov    0x18(%eax),%eax
801046c2:	89 c3                	mov    %eax,%ebx
801046c4:	b8 13 00 00 00       	mov    $0x13,%eax
801046c9:	89 d7                	mov    %edx,%edi
801046cb:	89 de                	mov    %ebx,%esi
801046cd:	89 c1                	mov    %eax,%ecx
801046cf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801046d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046d4:	8b 40 18             	mov    0x18(%eax),%eax
801046d7:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801046de:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801046e5:	eb 3d                	jmp    80104724 <fork+0x105>
    if(proc->ofile[i])
801046e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046ed:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801046f0:	83 c2 08             	add    $0x8,%edx
801046f3:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046f7:	85 c0                	test   %eax,%eax
801046f9:	74 25                	je     80104720 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801046fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104701:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104704:	83 c2 08             	add    $0x8,%edx
80104707:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010470b:	89 04 24             	mov    %eax,(%esp)
8010470e:	e8 73 c8 ff ff       	call   80100f86 <filedup>
80104713:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104716:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104719:	83 c1 08             	add    $0x8,%ecx
8010471c:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104720:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104724:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104728:	7e bd                	jle    801046e7 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010472a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104730:	8b 40 68             	mov    0x68(%eax),%eax
80104733:	89 04 24             	mov    %eax,(%esp)
80104736:	e8 ee d0 ff ff       	call   80101829 <idup>
8010473b:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010473e:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104741:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104747:	8d 50 6c             	lea    0x6c(%eax),%edx
8010474a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010474d:	83 c0 6c             	add    $0x6c,%eax
80104750:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104757:	00 
80104758:	89 54 24 04          	mov    %edx,0x4(%esp)
8010475c:	89 04 24             	mov    %eax,(%esp)
8010475f:	e8 2a 0c 00 00       	call   8010538e <safestrcpy>
 
  pid = np->pid;
80104764:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104767:	8b 40 10             	mov    0x10(%eax),%eax
8010476a:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
8010476d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104774:	e8 a1 07 00 00       	call   80104f1a <acquire>
  np->state = RUNNABLE;
80104779:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010477c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104783:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010478a:	e8 ed 07 00 00       	call   80104f7c <release>
  
  return pid;
8010478f:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104792:	83 c4 2c             	add    $0x2c,%esp
80104795:	5b                   	pop    %ebx
80104796:	5e                   	pop    %esi
80104797:	5f                   	pop    %edi
80104798:	5d                   	pop    %ebp
80104799:	c3                   	ret    

8010479a <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010479a:	55                   	push   %ebp
8010479b:	89 e5                	mov    %esp,%ebp
8010479d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801047a0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047a7:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801047ac:	39 c2                	cmp    %eax,%edx
801047ae:	75 0c                	jne    801047bc <exit+0x22>
    panic("init exiting");
801047b0:	c7 04 24 e4 87 10 80 	movl   $0x801087e4,(%esp)
801047b7:	e8 7e bd ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801047bc:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801047c3:	eb 44                	jmp    80104809 <exit+0x6f>
    if(proc->ofile[fd]){
801047c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047cb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047ce:	83 c2 08             	add    $0x8,%edx
801047d1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047d5:	85 c0                	test   %eax,%eax
801047d7:	74 2c                	je     80104805 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801047d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047df:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047e2:	83 c2 08             	add    $0x8,%edx
801047e5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801047e9:	89 04 24             	mov    %eax,(%esp)
801047ec:	e8 dd c7 ff ff       	call   80100fce <fileclose>
      proc->ofile[fd] = 0;
801047f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801047fa:	83 c2 08             	add    $0x8,%edx
801047fd:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104804:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104805:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104809:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010480d:	7e b6                	jle    801047c5 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
8010480f:	e8 fc eb ff ff       	call   80103410 <begin_op>
  iput(proc->cwd);
80104814:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010481a:	8b 40 68             	mov    0x68(%eax),%eax
8010481d:	89 04 24             	mov    %eax,(%esp)
80104820:	e8 e9 d1 ff ff       	call   80101a0e <iput>
  end_op();
80104825:	e8 6a ec ff ff       	call   80103494 <end_op>
  proc->cwd = 0;
8010482a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104830:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104837:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010483e:	e8 d7 06 00 00       	call   80104f1a <acquire>

  proc->state = ZOMBIE;
80104843:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104849:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104850:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104856:	8b 40 14             	mov    0x14(%eax),%eax
80104859:	89 04 24             	mov    %eax,(%esp)
8010485c:	e8 22 04 00 00       	call   80104c83 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104861:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104868:	eb 38                	jmp    801048a2 <exit+0x108>
    if(p->parent == proc){
8010486a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010486d:	8b 50 14             	mov    0x14(%eax),%edx
80104870:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104876:	39 c2                	cmp    %eax,%edx
80104878:	75 24                	jne    8010489e <exit+0x104>
      p->parent = initproc;
8010487a:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104883:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104886:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104889:	8b 40 0c             	mov    0xc(%eax),%eax
8010488c:	83 f8 05             	cmp    $0x5,%eax
8010488f:	75 0d                	jne    8010489e <exit+0x104>
        wakeup1(initproc);
80104891:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104896:	89 04 24             	mov    %eax,(%esp)
80104899:	e8 e5 03 00 00       	call   80104c83 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010489e:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048a2:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
801048a9:	72 bf                	jb     8010486a <exit+0xd0>
    }
  }

  // Jump into the scheduler, never to return.
  
  sched();
801048ab:	e8 35 02 00 00       	call   80104ae5 <sched>
  panic("zombie exit");
801048b0:	c7 04 24 f1 87 10 80 	movl   $0x801087f1,(%esp)
801048b7:	e8 7e bc ff ff       	call   8010053a <panic>

801048bc <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801048bc:	55                   	push   %ebp
801048bd:	89 e5                	mov    %esp,%ebp
801048bf:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801048c2:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801048c9:	e8 4c 06 00 00       	call   80104f1a <acquire>
  for(;;){
    proc->chan = (int)proc;
801048ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048db:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;    
801048de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e4:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    // Scan through table looking for zombie children.
    havekids = 0;
801048eb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048f2:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
801048f9:	e9 81 00 00 00       	jmp    8010497f <wait+0xc3>
      if(p->parent != proc)
801048fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104901:	8b 50 14             	mov    0x14(%eax),%edx
80104904:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010490a:	39 c2                	cmp    %eax,%edx
8010490c:	74 02                	je     80104910 <wait+0x54>
        continue;
8010490e:	eb 6b                	jmp    8010497b <wait+0xbf>
      havekids = 1;
80104910:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104917:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491a:	8b 40 0c             	mov    0xc(%eax),%eax
8010491d:	83 f8 05             	cmp    $0x5,%eax
80104920:	75 59                	jne    8010497b <wait+0xbf>
        // Found one.
        pid = p->pid;
80104922:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104925:	8b 40 10             	mov    0x10(%eax),%eax
80104928:	89 45 ec             	mov    %eax,-0x14(%ebp)
        p->state = UNUSED;
8010492b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010492e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104938:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010493f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104942:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)

        proc->chan = 0;
80104950:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104956:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
        proc->state = RUNNING;
8010495d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104963:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
        release(&ptable.lock);
8010496a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104971:	e8 06 06 00 00       	call   80104f7c <release>
        return pid;
80104976:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104979:	eb 5b                	jmp    801049d6 <wait+0x11a>
  for(;;){
    proc->chan = (int)proc;
    proc->state = SLEEPING;    
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010497b:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010497f:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104986:	0f 82 72 ff ff ff    	jb     801048fe <wait+0x42>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
8010498c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104990:	74 0d                	je     8010499f <wait+0xe3>
80104992:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104998:	8b 40 24             	mov    0x24(%eax),%eax
8010499b:	85 c0                	test   %eax,%eax
8010499d:	74 2d                	je     801049cc <wait+0x110>
      proc->chan = 0;
8010499f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a5:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
      proc->state = RUNNING;      
801049ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049b2:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      release(&ptable.lock);
801049b9:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801049c0:	e8 b7 05 00 00       	call   80104f7c <release>
      return -1;
801049c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049ca:	eb 0a                	jmp    801049d6 <wait+0x11a>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sched();
801049cc:	e8 14 01 00 00       	call   80104ae5 <sched>
  }
801049d1:	e9 f8 fe ff ff       	jmp    801048ce <wait+0x12>
}
801049d6:	c9                   	leave  
801049d7:	c3                   	ret    

801049d8 <freeproc>:

void 
freeproc(struct proc *p)
{
801049d8:	55                   	push   %ebp
801049d9:	89 e5                	mov    %esp,%ebp
801049db:	83 ec 18             	sub    $0x18,%esp
  if (!p || p->state != ZOMBIE)
801049de:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801049e2:	74 0b                	je     801049ef <freeproc+0x17>
801049e4:	8b 45 08             	mov    0x8(%ebp),%eax
801049e7:	8b 40 0c             	mov    0xc(%eax),%eax
801049ea:	83 f8 05             	cmp    $0x5,%eax
801049ed:	74 0c                	je     801049fb <freeproc+0x23>
    panic("freeproc not zombie");
801049ef:	c7 04 24 fd 87 10 80 	movl   $0x801087fd,(%esp)
801049f6:	e8 3f bb ff ff       	call   8010053a <panic>
  kfree(p->kstack);
801049fb:	8b 45 08             	mov    0x8(%ebp),%eax
801049fe:	8b 40 08             	mov    0x8(%eax),%eax
80104a01:	89 04 24             	mov    %eax,(%esp)
80104a04:	e8 40 e0 ff ff       	call   80102a49 <kfree>
  p->kstack = 0;
80104a09:	8b 45 08             	mov    0x8(%ebp),%eax
80104a0c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  freevm(p->pgdir);
80104a13:	8b 45 08             	mov    0x8(%ebp),%eax
80104a16:	8b 40 04             	mov    0x4(%eax),%eax
80104a19:	89 04 24             	mov    %eax,(%esp)
80104a1c:	e8 b9 37 00 00       	call   801081da <freevm>
  p->killed = 0;
80104a21:	8b 45 08             	mov    0x8(%ebp),%eax
80104a24:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
  p->chan = 0;
80104a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80104a2e:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
}
80104a35:	c9                   	leave  
80104a36:	c3                   	ret    

80104a37 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104a37:	55                   	push   %ebp
80104a38:	89 e5                	mov    %esp,%ebp
80104a3a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104a3d:	e8 a4 f8 ff ff       	call   801042e6 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104a42:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a49:	e8 cc 04 00 00       	call   80104f1a <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a4e:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104a55:	eb 74                	jmp    80104acb <scheduler+0x94>
      if(p->state != RUNNABLE)
80104a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5a:	8b 40 0c             	mov    0xc(%eax),%eax
80104a5d:	83 f8 03             	cmp    $0x3,%eax
80104a60:	74 02                	je     80104a64 <scheduler+0x2d>
        continue;
80104a62:	eb 63                	jmp    80104ac7 <scheduler+0x90>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104a64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a67:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104a6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a70:	89 04 24             	mov    %eax,(%esp)
80104a73:	e8 ef 32 00 00       	call   80107d67 <switchuvm>
      p->state = RUNNING;
80104a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a7b:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104a82:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a88:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a8b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104a92:	83 c2 04             	add    $0x4,%edx
80104a95:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a99:	89 14 24             	mov    %edx,(%esp)
80104a9c:	e8 5e 09 00 00       	call   801053ff <swtch>
      switchkvm();
80104aa1:	e8 a4 32 00 00       	call   80107d4a <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104aa6:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104aad:	00 00 00 00 
      if (p->state == ZOMBIE)
80104ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ab7:	83 f8 05             	cmp    $0x5,%eax
80104aba:	75 0b                	jne    80104ac7 <scheduler+0x90>
        freeproc(p);
80104abc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abf:	89 04 24             	mov    %eax,(%esp)
80104ac2:	e8 11 ff ff ff       	call   801049d8 <freeproc>
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ac7:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104acb:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104ad2:	72 83                	jb     80104a57 <scheduler+0x20>
      // It should have changed its p->state before coming back.
      proc = 0;
      if (p->state == ZOMBIE)
        freeproc(p);
    }
    release(&ptable.lock);
80104ad4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104adb:	e8 9c 04 00 00       	call   80104f7c <release>

  }
80104ae0:	e9 58 ff ff ff       	jmp    80104a3d <scheduler+0x6>

80104ae5 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104ae5:	55                   	push   %ebp
80104ae6:	89 e5                	mov    %esp,%ebp
80104ae8:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104aeb:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104af2:	e8 4d 05 00 00       	call   80105044 <holding>
80104af7:	85 c0                	test   %eax,%eax
80104af9:	75 0c                	jne    80104b07 <sched+0x22>
    panic("sched ptable.lock");
80104afb:	c7 04 24 11 88 10 80 	movl   $0x80108811,(%esp)
80104b02:	e8 33 ba ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104b07:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b0d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104b13:	83 f8 01             	cmp    $0x1,%eax
80104b16:	74 0c                	je     80104b24 <sched+0x3f>
    panic("sched locks");
80104b18:	c7 04 24 23 88 10 80 	movl   $0x80108823,(%esp)
80104b1f:	e8 16 ba ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104b24:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b2a:	8b 40 0c             	mov    0xc(%eax),%eax
80104b2d:	83 f8 04             	cmp    $0x4,%eax
80104b30:	75 0c                	jne    80104b3e <sched+0x59>
    panic("sched running");
80104b32:	c7 04 24 2f 88 10 80 	movl   $0x8010882f,(%esp)
80104b39:	e8 fc b9 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104b3e:	e8 93 f7 ff ff       	call   801042d6 <readeflags>
80104b43:	25 00 02 00 00       	and    $0x200,%eax
80104b48:	85 c0                	test   %eax,%eax
80104b4a:	74 0c                	je     80104b58 <sched+0x73>
    panic("sched interruptible");
80104b4c:	c7 04 24 3d 88 10 80 	movl   $0x8010883d,(%esp)
80104b53:	e8 e2 b9 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104b58:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b5e:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104b64:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104b67:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b6d:	8b 40 04             	mov    0x4(%eax),%eax
80104b70:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b77:	83 c2 1c             	add    $0x1c,%edx
80104b7a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b7e:	89 14 24             	mov    %edx,(%esp)
80104b81:	e8 79 08 00 00       	call   801053ff <swtch>
  cpu->intena = intena;
80104b86:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b8c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b8f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104b95:	c9                   	leave  
80104b96:	c3                   	ret    

80104b97 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104b97:	55                   	push   %ebp
80104b98:	89 e5                	mov    %esp,%ebp
80104b9a:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104b9d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ba4:	e8 71 03 00 00       	call   80104f1a <acquire>
  proc->state = RUNNABLE;
80104ba9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104baf:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104bb6:	e8 2a ff ff ff       	call   80104ae5 <sched>
  release(&ptable.lock);
80104bbb:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bc2:	e8 b5 03 00 00       	call   80104f7c <release>
}
80104bc7:	c9                   	leave  
80104bc8:	c3                   	ret    

80104bc9 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104bc9:	55                   	push   %ebp
80104bca:	89 e5                	mov    %esp,%ebp
80104bcc:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104bcf:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bd6:	e8 a1 03 00 00       	call   80104f7c <release>

  if (first) {
80104bdb:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104be0:	85 c0                	test   %eax,%eax
80104be2:	74 0f                	je     80104bf3 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104be4:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104beb:	00 00 00 
    initlog();
80104bee:	e8 0f e6 ff ff       	call   80103202 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104bf3:	c9                   	leave  
80104bf4:	c3                   	ret    

80104bf5 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104bf5:	55                   	push   %ebp
80104bf6:	89 e5                	mov    %esp,%ebp
80104bf8:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104bfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c01:	85 c0                	test   %eax,%eax
80104c03:	75 0c                	jne    80104c11 <sleep+0x1c>
    panic("sleep");
80104c05:	c7 04 24 51 88 10 80 	movl   $0x80108851,(%esp)
80104c0c:	e8 29 b9 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104c11:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c15:	75 0c                	jne    80104c23 <sleep+0x2e>
    panic("sleep without lk");
80104c17:	c7 04 24 57 88 10 80 	movl   $0x80108857,(%esp)
80104c1e:	e8 17 b9 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104c23:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c2a:	74 17                	je     80104c43 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104c2c:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c33:	e8 e2 02 00 00       	call   80104f1a <acquire>
    release(lk);
80104c38:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c3b:	89 04 24             	mov    %eax,(%esp)
80104c3e:	e8 39 03 00 00       	call   80104f7c <release>
  }

  // Go to sleep.
  proc->chan = (int)chan;
80104c43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c49:	8b 55 08             	mov    0x8(%ebp),%edx
80104c4c:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104c4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c55:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)


  sched();
80104c5c:	e8 84 fe ff ff       	call   80104ae5 <sched>

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104c61:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c68:	74 17                	je     80104c81 <sleep+0x8c>
    release(&ptable.lock);
80104c6a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c71:	e8 06 03 00 00       	call   80104f7c <release>
    acquire(lk);
80104c76:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c79:	89 04 24             	mov    %eax,(%esp)
80104c7c:	e8 99 02 00 00       	call   80104f1a <acquire>
  }
}
80104c81:	c9                   	leave  
80104c82:	c3                   	ret    

80104c83 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104c83:	55                   	push   %ebp
80104c84:	89 e5                	mov    %esp,%ebp
80104c86:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c89:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104c90:	eb 30                	jmp    80104cc2 <wakeup1+0x3f>
    if(p->state == SLEEPING && p->chan == (int)chan){
80104c92:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c95:	8b 40 0c             	mov    0xc(%eax),%eax
80104c98:	83 f8 02             	cmp    $0x2,%eax
80104c9b:	75 21                	jne    80104cbe <wakeup1+0x3b>
80104c9d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ca0:	8b 50 20             	mov    0x20(%eax),%edx
80104ca3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca6:	39 c2                	cmp    %eax,%edx
80104ca8:	75 14                	jne    80104cbe <wakeup1+0x3b>
      // Tidy up.
      p->chan = 0;
80104caa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cad:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
      p->state = RUNNABLE;
80104cb4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cb7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104cbe:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104cc2:	81 7d fc 94 48 11 80 	cmpl   $0x80114894,-0x4(%ebp)
80104cc9:	72 c7                	jb     80104c92 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == (int)chan){
      // Tidy up.
      p->chan = 0;
      p->state = RUNNABLE;
    }
}
80104ccb:	c9                   	leave  
80104ccc:	c3                   	ret    

80104ccd <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104ccd:	55                   	push   %ebp
80104cce:	89 e5                	mov    %esp,%ebp
80104cd0:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104cd3:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cda:	e8 3b 02 00 00       	call   80104f1a <acquire>
  wakeup1(chan);
80104cdf:	8b 45 08             	mov    0x8(%ebp),%eax
80104ce2:	89 04 24             	mov    %eax,(%esp)
80104ce5:	e8 99 ff ff ff       	call   80104c83 <wakeup1>
  release(&ptable.lock);
80104cea:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cf1:	e8 86 02 00 00       	call   80104f7c <release>
}
80104cf6:	c9                   	leave  
80104cf7:	c3                   	ret    

80104cf8 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104cf8:	55                   	push   %ebp
80104cf9:	89 e5                	mov    %esp,%ebp
80104cfb:	83 ec 28             	sub    $0x28,%esp
  int actual = 10;
80104cfe:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)

  int ans = -1;
80104d05:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  //Cas test:
  ans = cas(&actual, 10, 20);
80104d0c:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104d13:	00 
80104d14:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104d1b:	00 
80104d1c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d1f:	89 04 24             	mov    %eax,(%esp)
80104d22:	e8 c5 f5 ff ff       	call   801042ec <cas>
80104d27:	89 45 f0             	mov    %eax,-0x10(%ebp)
  cprintf("got: %d\n", ans);
80104d2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d31:	c7 04 24 68 88 10 80 	movl   $0x80108868,(%esp)
80104d38:	e8 63 b6 ff ff       	call   801003a0 <cprintf>
  cprintf("actual is: %d\n", actual);
80104d3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d40:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d44:	c7 04 24 71 88 10 80 	movl   $0x80108871,(%esp)
80104d4b:	e8 50 b6 ff ff       	call   801003a0 <cprintf>
//---------------------


  struct proc *p;

  acquire(&ptable.lock);
80104d50:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d57:	e8 be 01 00 00       	call   80104f1a <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d5c:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104d63:	eb 41                	jmp    80104da6 <kill+0xae>
    if(p->pid == pid){
80104d65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d68:	8b 40 10             	mov    0x10(%eax),%eax
80104d6b:	3b 45 08             	cmp    0x8(%ebp),%eax
80104d6e:	75 32                	jne    80104da2 <kill+0xaa>
      p->killed = 1;
80104d70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d73:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d7d:	8b 40 0c             	mov    0xc(%eax),%eax
80104d80:	83 f8 02             	cmp    $0x2,%eax
80104d83:	75 0a                	jne    80104d8f <kill+0x97>
        p->state = RUNNABLE;
80104d85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d88:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104d8f:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d96:	e8 e1 01 00 00       	call   80104f7c <release>
      return 0;
80104d9b:	b8 00 00 00 00       	mov    $0x0,%eax
80104da0:	eb 1e                	jmp    80104dc0 <kill+0xc8>


  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104da2:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104da6:	81 7d f4 94 48 11 80 	cmpl   $0x80114894,-0xc(%ebp)
80104dad:	72 b6                	jb     80104d65 <kill+0x6d>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104daf:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104db6:	e8 c1 01 00 00       	call   80104f7c <release>
  return -1;
80104dbb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104dc0:	c9                   	leave  
80104dc1:	c3                   	ret    

80104dc2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104dc2:	55                   	push   %ebp
80104dc3:	89 e5                	mov    %esp,%ebp
80104dc5:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dc8:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104dcf:	e9 e0 00 00 00       	jmp    80104eb4 <procdump+0xf2>
    if(p->state == UNUSED)
80104dd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dd7:	8b 40 0c             	mov    0xc(%eax),%eax
80104dda:	85 c0                	test   %eax,%eax
80104ddc:	75 05                	jne    80104de3 <procdump+0x21>
      continue;
80104dde:	e9 cd 00 00 00       	jmp    80104eb0 <procdump+0xee>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104de3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104de6:	8b 40 0c             	mov    0xc(%eax),%eax
80104de9:	85 c0                	test   %eax,%eax
80104deb:	78 2e                	js     80104e1b <procdump+0x59>
80104ded:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104df0:	8b 40 0c             	mov    0xc(%eax),%eax
80104df3:	83 f8 05             	cmp    $0x5,%eax
80104df6:	77 23                	ja     80104e1b <procdump+0x59>
80104df8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dfb:	8b 40 0c             	mov    0xc(%eax),%eax
80104dfe:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104e05:	85 c0                	test   %eax,%eax
80104e07:	74 12                	je     80104e1b <procdump+0x59>
      state = states[p->state];
80104e09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e0c:	8b 40 0c             	mov    0xc(%eax),%eax
80104e0f:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104e16:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104e19:	eb 07                	jmp    80104e22 <procdump+0x60>
    else
      state = "???";
80104e1b:	c7 45 ec 80 88 10 80 	movl   $0x80108880,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104e22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e25:	8d 50 6c             	lea    0x6c(%eax),%edx
80104e28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e2b:	8b 40 10             	mov    0x10(%eax),%eax
80104e2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e32:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104e35:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e39:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e3d:	c7 04 24 84 88 10 80 	movl   $0x80108884,(%esp)
80104e44:	e8 57 b5 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104e49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e4c:	8b 40 0c             	mov    0xc(%eax),%eax
80104e4f:	83 f8 02             	cmp    $0x2,%eax
80104e52:	75 50                	jne    80104ea4 <procdump+0xe2>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e57:	8b 40 1c             	mov    0x1c(%eax),%eax
80104e5a:	8b 40 0c             	mov    0xc(%eax),%eax
80104e5d:	83 c0 08             	add    $0x8,%eax
80104e60:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104e63:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e67:	89 04 24             	mov    %eax,(%esp)
80104e6a:	e8 5c 01 00 00       	call   80104fcb <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104e6f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e76:	eb 1b                	jmp    80104e93 <procdump+0xd1>
        cprintf(" %p", pc[i]);
80104e78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e7b:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e83:	c7 04 24 8d 88 10 80 	movl   $0x8010888d,(%esp)
80104e8a:	e8 11 b5 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104e8f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e93:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104e97:	7f 0b                	jg     80104ea4 <procdump+0xe2>
80104e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e9c:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104ea0:	85 c0                	test   %eax,%eax
80104ea2:	75 d4                	jne    80104e78 <procdump+0xb6>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104ea4:	c7 04 24 91 88 10 80 	movl   $0x80108891,(%esp)
80104eab:	e8 f0 b4 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104eb0:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104eb4:	81 7d f0 94 48 11 80 	cmpl   $0x80114894,-0x10(%ebp)
80104ebb:	0f 82 13 ff ff ff    	jb     80104dd4 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104ec1:	c9                   	leave  
80104ec2:	c3                   	ret    

80104ec3 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104ec3:	55                   	push   %ebp
80104ec4:	89 e5                	mov    %esp,%ebp
80104ec6:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104ec9:	9c                   	pushf  
80104eca:	58                   	pop    %eax
80104ecb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104ece:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104ed1:	c9                   	leave  
80104ed2:	c3                   	ret    

80104ed3 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104ed3:	55                   	push   %ebp
80104ed4:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104ed6:	fa                   	cli    
}
80104ed7:	5d                   	pop    %ebp
80104ed8:	c3                   	ret    

80104ed9 <sti>:

static inline void
sti(void)
{
80104ed9:	55                   	push   %ebp
80104eda:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104edc:	fb                   	sti    
}
80104edd:	5d                   	pop    %ebp
80104ede:	c3                   	ret    

80104edf <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104edf:	55                   	push   %ebp
80104ee0:	89 e5                	mov    %esp,%ebp
80104ee2:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104ee5:	8b 55 08             	mov    0x8(%ebp),%edx
80104ee8:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eeb:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104eee:	f0 87 02             	lock xchg %eax,(%edx)
80104ef1:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104ef4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104ef7:	c9                   	leave  
80104ef8:	c3                   	ret    

80104ef9 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104ef9:	55                   	push   %ebp
80104efa:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104efc:	8b 45 08             	mov    0x8(%ebp),%eax
80104eff:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f02:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104f05:	8b 45 08             	mov    0x8(%ebp),%eax
80104f08:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104f0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f11:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104f18:	5d                   	pop    %ebp
80104f19:	c3                   	ret    

80104f1a <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104f1a:	55                   	push   %ebp
80104f1b:	89 e5                	mov    %esp,%ebp
80104f1d:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104f20:	e8 49 01 00 00       	call   8010506e <pushcli>
  if(holding(lk))
80104f25:	8b 45 08             	mov    0x8(%ebp),%eax
80104f28:	89 04 24             	mov    %eax,(%esp)
80104f2b:	e8 14 01 00 00       	call   80105044 <holding>
80104f30:	85 c0                	test   %eax,%eax
80104f32:	74 0c                	je     80104f40 <acquire+0x26>
    panic("acquire");
80104f34:	c7 04 24 bd 88 10 80 	movl   $0x801088bd,(%esp)
80104f3b:	e8 fa b5 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104f40:	90                   	nop
80104f41:	8b 45 08             	mov    0x8(%ebp),%eax
80104f44:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104f4b:	00 
80104f4c:	89 04 24             	mov    %eax,(%esp)
80104f4f:	e8 8b ff ff ff       	call   80104edf <xchg>
80104f54:	85 c0                	test   %eax,%eax
80104f56:	75 e9                	jne    80104f41 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104f58:	8b 45 08             	mov    0x8(%ebp),%eax
80104f5b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104f62:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104f65:	8b 45 08             	mov    0x8(%ebp),%eax
80104f68:	83 c0 0c             	add    $0xc,%eax
80104f6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f6f:	8d 45 08             	lea    0x8(%ebp),%eax
80104f72:	89 04 24             	mov    %eax,(%esp)
80104f75:	e8 51 00 00 00       	call   80104fcb <getcallerpcs>
}
80104f7a:	c9                   	leave  
80104f7b:	c3                   	ret    

80104f7c <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104f7c:	55                   	push   %ebp
80104f7d:	89 e5                	mov    %esp,%ebp
80104f7f:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104f82:	8b 45 08             	mov    0x8(%ebp),%eax
80104f85:	89 04 24             	mov    %eax,(%esp)
80104f88:	e8 b7 00 00 00       	call   80105044 <holding>
80104f8d:	85 c0                	test   %eax,%eax
80104f8f:	75 0c                	jne    80104f9d <release+0x21>
    panic("release");
80104f91:	c7 04 24 c5 88 10 80 	movl   $0x801088c5,(%esp)
80104f98:	e8 9d b5 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80104f9d:	8b 45 08             	mov    0x8(%ebp),%eax
80104fa0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104fa7:	8b 45 08             	mov    0x8(%ebp),%eax
80104faa:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104fb1:	8b 45 08             	mov    0x8(%ebp),%eax
80104fb4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104fbb:	00 
80104fbc:	89 04 24             	mov    %eax,(%esp)
80104fbf:	e8 1b ff ff ff       	call   80104edf <xchg>

  popcli();
80104fc4:	e8 e9 00 00 00       	call   801050b2 <popcli>
}
80104fc9:	c9                   	leave  
80104fca:	c3                   	ret    

80104fcb <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104fcb:	55                   	push   %ebp
80104fcc:	89 e5                	mov    %esp,%ebp
80104fce:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104fd1:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd4:	83 e8 08             	sub    $0x8,%eax
80104fd7:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104fda:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104fe1:	eb 38                	jmp    8010501b <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104fe3:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104fe7:	74 38                	je     80105021 <getcallerpcs+0x56>
80104fe9:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104ff0:	76 2f                	jbe    80105021 <getcallerpcs+0x56>
80104ff2:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104ff6:	74 29                	je     80105021 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104ff8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ffb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105002:	8b 45 0c             	mov    0xc(%ebp),%eax
80105005:	01 c2                	add    %eax,%edx
80105007:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010500a:	8b 40 04             	mov    0x4(%eax),%eax
8010500d:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
8010500f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105012:	8b 00                	mov    (%eax),%eax
80105014:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105017:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010501b:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010501f:	7e c2                	jle    80104fe3 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105021:	eb 19                	jmp    8010503c <getcallerpcs+0x71>
    pcs[i] = 0;
80105023:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105026:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010502d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105030:	01 d0                	add    %edx,%eax
80105032:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105038:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010503c:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105040:	7e e1                	jle    80105023 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105042:	c9                   	leave  
80105043:	c3                   	ret    

80105044 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105044:	55                   	push   %ebp
80105045:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105047:	8b 45 08             	mov    0x8(%ebp),%eax
8010504a:	8b 00                	mov    (%eax),%eax
8010504c:	85 c0                	test   %eax,%eax
8010504e:	74 17                	je     80105067 <holding+0x23>
80105050:	8b 45 08             	mov    0x8(%ebp),%eax
80105053:	8b 50 08             	mov    0x8(%eax),%edx
80105056:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010505c:	39 c2                	cmp    %eax,%edx
8010505e:	75 07                	jne    80105067 <holding+0x23>
80105060:	b8 01 00 00 00       	mov    $0x1,%eax
80105065:	eb 05                	jmp    8010506c <holding+0x28>
80105067:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010506c:	5d                   	pop    %ebp
8010506d:	c3                   	ret    

8010506e <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010506e:	55                   	push   %ebp
8010506f:	89 e5                	mov    %esp,%ebp
80105071:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105074:	e8 4a fe ff ff       	call   80104ec3 <readeflags>
80105079:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010507c:	e8 52 fe ff ff       	call   80104ed3 <cli>
  if(cpu->ncli++ == 0)
80105081:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105088:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
8010508e:	8d 48 01             	lea    0x1(%eax),%ecx
80105091:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105097:	85 c0                	test   %eax,%eax
80105099:	75 15                	jne    801050b0 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
8010509b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801050a1:	8b 55 fc             	mov    -0x4(%ebp),%edx
801050a4:	81 e2 00 02 00 00    	and    $0x200,%edx
801050aa:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801050b0:	c9                   	leave  
801050b1:	c3                   	ret    

801050b2 <popcli>:

void
popcli(void)
{
801050b2:	55                   	push   %ebp
801050b3:	89 e5                	mov    %esp,%ebp
801050b5:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801050b8:	e8 06 fe ff ff       	call   80104ec3 <readeflags>
801050bd:	25 00 02 00 00       	and    $0x200,%eax
801050c2:	85 c0                	test   %eax,%eax
801050c4:	74 0c                	je     801050d2 <popcli+0x20>
    panic("popcli - interruptible");
801050c6:	c7 04 24 cd 88 10 80 	movl   $0x801088cd,(%esp)
801050cd:	e8 68 b4 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
801050d2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801050d8:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801050de:	83 ea 01             	sub    $0x1,%edx
801050e1:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801050e7:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801050ed:	85 c0                	test   %eax,%eax
801050ef:	79 0c                	jns    801050fd <popcli+0x4b>
    panic("popcli");
801050f1:	c7 04 24 e4 88 10 80 	movl   $0x801088e4,(%esp)
801050f8:	e8 3d b4 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
801050fd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105103:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105109:	85 c0                	test   %eax,%eax
8010510b:	75 15                	jne    80105122 <popcli+0x70>
8010510d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105113:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105119:	85 c0                	test   %eax,%eax
8010511b:	74 05                	je     80105122 <popcli+0x70>
    sti();
8010511d:	e8 b7 fd ff ff       	call   80104ed9 <sti>
}
80105122:	c9                   	leave  
80105123:	c3                   	ret    

80105124 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105124:	55                   	push   %ebp
80105125:	89 e5                	mov    %esp,%ebp
80105127:	57                   	push   %edi
80105128:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105129:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010512c:	8b 55 10             	mov    0x10(%ebp),%edx
8010512f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105132:	89 cb                	mov    %ecx,%ebx
80105134:	89 df                	mov    %ebx,%edi
80105136:	89 d1                	mov    %edx,%ecx
80105138:	fc                   	cld    
80105139:	f3 aa                	rep stos %al,%es:(%edi)
8010513b:	89 ca                	mov    %ecx,%edx
8010513d:	89 fb                	mov    %edi,%ebx
8010513f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105142:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105145:	5b                   	pop    %ebx
80105146:	5f                   	pop    %edi
80105147:	5d                   	pop    %ebp
80105148:	c3                   	ret    

80105149 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105149:	55                   	push   %ebp
8010514a:	89 e5                	mov    %esp,%ebp
8010514c:	57                   	push   %edi
8010514d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010514e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105151:	8b 55 10             	mov    0x10(%ebp),%edx
80105154:	8b 45 0c             	mov    0xc(%ebp),%eax
80105157:	89 cb                	mov    %ecx,%ebx
80105159:	89 df                	mov    %ebx,%edi
8010515b:	89 d1                	mov    %edx,%ecx
8010515d:	fc                   	cld    
8010515e:	f3 ab                	rep stos %eax,%es:(%edi)
80105160:	89 ca                	mov    %ecx,%edx
80105162:	89 fb                	mov    %edi,%ebx
80105164:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105167:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010516a:	5b                   	pop    %ebx
8010516b:	5f                   	pop    %edi
8010516c:	5d                   	pop    %ebp
8010516d:	c3                   	ret    

8010516e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010516e:	55                   	push   %ebp
8010516f:	89 e5                	mov    %esp,%ebp
80105171:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105174:	8b 45 08             	mov    0x8(%ebp),%eax
80105177:	83 e0 03             	and    $0x3,%eax
8010517a:	85 c0                	test   %eax,%eax
8010517c:	75 49                	jne    801051c7 <memset+0x59>
8010517e:	8b 45 10             	mov    0x10(%ebp),%eax
80105181:	83 e0 03             	and    $0x3,%eax
80105184:	85 c0                	test   %eax,%eax
80105186:	75 3f                	jne    801051c7 <memset+0x59>
    c &= 0xFF;
80105188:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010518f:	8b 45 10             	mov    0x10(%ebp),%eax
80105192:	c1 e8 02             	shr    $0x2,%eax
80105195:	89 c2                	mov    %eax,%edx
80105197:	8b 45 0c             	mov    0xc(%ebp),%eax
8010519a:	c1 e0 18             	shl    $0x18,%eax
8010519d:	89 c1                	mov    %eax,%ecx
8010519f:	8b 45 0c             	mov    0xc(%ebp),%eax
801051a2:	c1 e0 10             	shl    $0x10,%eax
801051a5:	09 c1                	or     %eax,%ecx
801051a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801051aa:	c1 e0 08             	shl    $0x8,%eax
801051ad:	09 c8                	or     %ecx,%eax
801051af:	0b 45 0c             	or     0xc(%ebp),%eax
801051b2:	89 54 24 08          	mov    %edx,0x8(%esp)
801051b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801051ba:	8b 45 08             	mov    0x8(%ebp),%eax
801051bd:	89 04 24             	mov    %eax,(%esp)
801051c0:	e8 84 ff ff ff       	call   80105149 <stosl>
801051c5:	eb 19                	jmp    801051e0 <memset+0x72>
  } else
    stosb(dst, c, n);
801051c7:	8b 45 10             	mov    0x10(%ebp),%eax
801051ca:	89 44 24 08          	mov    %eax,0x8(%esp)
801051ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801051d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801051d5:	8b 45 08             	mov    0x8(%ebp),%eax
801051d8:	89 04 24             	mov    %eax,(%esp)
801051db:	e8 44 ff ff ff       	call   80105124 <stosb>
  return dst;
801051e0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801051e3:	c9                   	leave  
801051e4:	c3                   	ret    

801051e5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801051e5:	55                   	push   %ebp
801051e6:	89 e5                	mov    %esp,%ebp
801051e8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801051eb:	8b 45 08             	mov    0x8(%ebp),%eax
801051ee:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801051f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801051f4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801051f7:	eb 30                	jmp    80105229 <memcmp+0x44>
    if(*s1 != *s2)
801051f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051fc:	0f b6 10             	movzbl (%eax),%edx
801051ff:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105202:	0f b6 00             	movzbl (%eax),%eax
80105205:	38 c2                	cmp    %al,%dl
80105207:	74 18                	je     80105221 <memcmp+0x3c>
      return *s1 - *s2;
80105209:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010520c:	0f b6 00             	movzbl (%eax),%eax
8010520f:	0f b6 d0             	movzbl %al,%edx
80105212:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105215:	0f b6 00             	movzbl (%eax),%eax
80105218:	0f b6 c0             	movzbl %al,%eax
8010521b:	29 c2                	sub    %eax,%edx
8010521d:	89 d0                	mov    %edx,%eax
8010521f:	eb 1a                	jmp    8010523b <memcmp+0x56>
    s1++, s2++;
80105221:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105225:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105229:	8b 45 10             	mov    0x10(%ebp),%eax
8010522c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010522f:	89 55 10             	mov    %edx,0x10(%ebp)
80105232:	85 c0                	test   %eax,%eax
80105234:	75 c3                	jne    801051f9 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105236:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010523b:	c9                   	leave  
8010523c:	c3                   	ret    

8010523d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010523d:	55                   	push   %ebp
8010523e:	89 e5                	mov    %esp,%ebp
80105240:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105243:	8b 45 0c             	mov    0xc(%ebp),%eax
80105246:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105249:	8b 45 08             	mov    0x8(%ebp),%eax
8010524c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010524f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105252:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105255:	73 3d                	jae    80105294 <memmove+0x57>
80105257:	8b 45 10             	mov    0x10(%ebp),%eax
8010525a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010525d:	01 d0                	add    %edx,%eax
8010525f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105262:	76 30                	jbe    80105294 <memmove+0x57>
    s += n;
80105264:	8b 45 10             	mov    0x10(%ebp),%eax
80105267:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010526a:	8b 45 10             	mov    0x10(%ebp),%eax
8010526d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105270:	eb 13                	jmp    80105285 <memmove+0x48>
      *--d = *--s;
80105272:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105276:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010527a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010527d:	0f b6 10             	movzbl (%eax),%edx
80105280:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105283:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105285:	8b 45 10             	mov    0x10(%ebp),%eax
80105288:	8d 50 ff             	lea    -0x1(%eax),%edx
8010528b:	89 55 10             	mov    %edx,0x10(%ebp)
8010528e:	85 c0                	test   %eax,%eax
80105290:	75 e0                	jne    80105272 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105292:	eb 26                	jmp    801052ba <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105294:	eb 17                	jmp    801052ad <memmove+0x70>
      *d++ = *s++;
80105296:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105299:	8d 50 01             	lea    0x1(%eax),%edx
8010529c:	89 55 f8             	mov    %edx,-0x8(%ebp)
8010529f:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052a2:	8d 4a 01             	lea    0x1(%edx),%ecx
801052a5:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801052a8:	0f b6 12             	movzbl (%edx),%edx
801052ab:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801052ad:	8b 45 10             	mov    0x10(%ebp),%eax
801052b0:	8d 50 ff             	lea    -0x1(%eax),%edx
801052b3:	89 55 10             	mov    %edx,0x10(%ebp)
801052b6:	85 c0                	test   %eax,%eax
801052b8:	75 dc                	jne    80105296 <memmove+0x59>
      *d++ = *s++;

  return dst;
801052ba:	8b 45 08             	mov    0x8(%ebp),%eax
}
801052bd:	c9                   	leave  
801052be:	c3                   	ret    

801052bf <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801052bf:	55                   	push   %ebp
801052c0:	89 e5                	mov    %esp,%ebp
801052c2:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801052c5:	8b 45 10             	mov    0x10(%ebp),%eax
801052c8:	89 44 24 08          	mov    %eax,0x8(%esp)
801052cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801052cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801052d3:	8b 45 08             	mov    0x8(%ebp),%eax
801052d6:	89 04 24             	mov    %eax,(%esp)
801052d9:	e8 5f ff ff ff       	call   8010523d <memmove>
}
801052de:	c9                   	leave  
801052df:	c3                   	ret    

801052e0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801052e0:	55                   	push   %ebp
801052e1:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801052e3:	eb 0c                	jmp    801052f1 <strncmp+0x11>
    n--, p++, q++;
801052e5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801052e9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801052ed:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801052f1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801052f5:	74 1a                	je     80105311 <strncmp+0x31>
801052f7:	8b 45 08             	mov    0x8(%ebp),%eax
801052fa:	0f b6 00             	movzbl (%eax),%eax
801052fd:	84 c0                	test   %al,%al
801052ff:	74 10                	je     80105311 <strncmp+0x31>
80105301:	8b 45 08             	mov    0x8(%ebp),%eax
80105304:	0f b6 10             	movzbl (%eax),%edx
80105307:	8b 45 0c             	mov    0xc(%ebp),%eax
8010530a:	0f b6 00             	movzbl (%eax),%eax
8010530d:	38 c2                	cmp    %al,%dl
8010530f:	74 d4                	je     801052e5 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105311:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105315:	75 07                	jne    8010531e <strncmp+0x3e>
    return 0;
80105317:	b8 00 00 00 00       	mov    $0x0,%eax
8010531c:	eb 16                	jmp    80105334 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
8010531e:	8b 45 08             	mov    0x8(%ebp),%eax
80105321:	0f b6 00             	movzbl (%eax),%eax
80105324:	0f b6 d0             	movzbl %al,%edx
80105327:	8b 45 0c             	mov    0xc(%ebp),%eax
8010532a:	0f b6 00             	movzbl (%eax),%eax
8010532d:	0f b6 c0             	movzbl %al,%eax
80105330:	29 c2                	sub    %eax,%edx
80105332:	89 d0                	mov    %edx,%eax
}
80105334:	5d                   	pop    %ebp
80105335:	c3                   	ret    

80105336 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105336:	55                   	push   %ebp
80105337:	89 e5                	mov    %esp,%ebp
80105339:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010533c:	8b 45 08             	mov    0x8(%ebp),%eax
8010533f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105342:	90                   	nop
80105343:	8b 45 10             	mov    0x10(%ebp),%eax
80105346:	8d 50 ff             	lea    -0x1(%eax),%edx
80105349:	89 55 10             	mov    %edx,0x10(%ebp)
8010534c:	85 c0                	test   %eax,%eax
8010534e:	7e 1e                	jle    8010536e <strncpy+0x38>
80105350:	8b 45 08             	mov    0x8(%ebp),%eax
80105353:	8d 50 01             	lea    0x1(%eax),%edx
80105356:	89 55 08             	mov    %edx,0x8(%ebp)
80105359:	8b 55 0c             	mov    0xc(%ebp),%edx
8010535c:	8d 4a 01             	lea    0x1(%edx),%ecx
8010535f:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105362:	0f b6 12             	movzbl (%edx),%edx
80105365:	88 10                	mov    %dl,(%eax)
80105367:	0f b6 00             	movzbl (%eax),%eax
8010536a:	84 c0                	test   %al,%al
8010536c:	75 d5                	jne    80105343 <strncpy+0xd>
    ;
  while(n-- > 0)
8010536e:	eb 0c                	jmp    8010537c <strncpy+0x46>
    *s++ = 0;
80105370:	8b 45 08             	mov    0x8(%ebp),%eax
80105373:	8d 50 01             	lea    0x1(%eax),%edx
80105376:	89 55 08             	mov    %edx,0x8(%ebp)
80105379:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010537c:	8b 45 10             	mov    0x10(%ebp),%eax
8010537f:	8d 50 ff             	lea    -0x1(%eax),%edx
80105382:	89 55 10             	mov    %edx,0x10(%ebp)
80105385:	85 c0                	test   %eax,%eax
80105387:	7f e7                	jg     80105370 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105389:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010538c:	c9                   	leave  
8010538d:	c3                   	ret    

8010538e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010538e:	55                   	push   %ebp
8010538f:	89 e5                	mov    %esp,%ebp
80105391:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105394:	8b 45 08             	mov    0x8(%ebp),%eax
80105397:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010539a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010539e:	7f 05                	jg     801053a5 <safestrcpy+0x17>
    return os;
801053a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053a3:	eb 31                	jmp    801053d6 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
801053a5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053ad:	7e 1e                	jle    801053cd <safestrcpy+0x3f>
801053af:	8b 45 08             	mov    0x8(%ebp),%eax
801053b2:	8d 50 01             	lea    0x1(%eax),%edx
801053b5:	89 55 08             	mov    %edx,0x8(%ebp)
801053b8:	8b 55 0c             	mov    0xc(%ebp),%edx
801053bb:	8d 4a 01             	lea    0x1(%edx),%ecx
801053be:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801053c1:	0f b6 12             	movzbl (%edx),%edx
801053c4:	88 10                	mov    %dl,(%eax)
801053c6:	0f b6 00             	movzbl (%eax),%eax
801053c9:	84 c0                	test   %al,%al
801053cb:	75 d8                	jne    801053a5 <safestrcpy+0x17>
    ;
  *s = 0;
801053cd:	8b 45 08             	mov    0x8(%ebp),%eax
801053d0:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801053d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801053d6:	c9                   	leave  
801053d7:	c3                   	ret    

801053d8 <strlen>:

int
strlen(const char *s)
{
801053d8:	55                   	push   %ebp
801053d9:	89 e5                	mov    %esp,%ebp
801053db:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801053de:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801053e5:	eb 04                	jmp    801053eb <strlen+0x13>
801053e7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801053eb:	8b 55 fc             	mov    -0x4(%ebp),%edx
801053ee:	8b 45 08             	mov    0x8(%ebp),%eax
801053f1:	01 d0                	add    %edx,%eax
801053f3:	0f b6 00             	movzbl (%eax),%eax
801053f6:	84 c0                	test   %al,%al
801053f8:	75 ed                	jne    801053e7 <strlen+0xf>
    ;
  return n;
801053fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801053fd:	c9                   	leave  
801053fe:	c3                   	ret    

801053ff <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801053ff:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105403:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105407:	55                   	push   %ebp
  pushl %ebx
80105408:	53                   	push   %ebx
  pushl %esi
80105409:	56                   	push   %esi
  pushl %edi
8010540a:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010540b:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010540d:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010540f:	5f                   	pop    %edi
  popl %esi
80105410:	5e                   	pop    %esi
  popl %ebx
80105411:	5b                   	pop    %ebx
  popl %ebp
80105412:	5d                   	pop    %ebp
  ret
80105413:	c3                   	ret    

80105414 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105414:	55                   	push   %ebp
80105415:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105417:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010541d:	8b 00                	mov    (%eax),%eax
8010541f:	3b 45 08             	cmp    0x8(%ebp),%eax
80105422:	76 12                	jbe    80105436 <fetchint+0x22>
80105424:	8b 45 08             	mov    0x8(%ebp),%eax
80105427:	8d 50 04             	lea    0x4(%eax),%edx
8010542a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105430:	8b 00                	mov    (%eax),%eax
80105432:	39 c2                	cmp    %eax,%edx
80105434:	76 07                	jbe    8010543d <fetchint+0x29>
    return -1;
80105436:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010543b:	eb 0f                	jmp    8010544c <fetchint+0x38>
  *ip = *(int*)(addr);
8010543d:	8b 45 08             	mov    0x8(%ebp),%eax
80105440:	8b 10                	mov    (%eax),%edx
80105442:	8b 45 0c             	mov    0xc(%ebp),%eax
80105445:	89 10                	mov    %edx,(%eax)
  return 0;
80105447:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010544c:	5d                   	pop    %ebp
8010544d:	c3                   	ret    

8010544e <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010544e:	55                   	push   %ebp
8010544f:	89 e5                	mov    %esp,%ebp
80105451:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105454:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010545a:	8b 00                	mov    (%eax),%eax
8010545c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010545f:	77 07                	ja     80105468 <fetchstr+0x1a>
    return -1;
80105461:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105466:	eb 46                	jmp    801054ae <fetchstr+0x60>
  *pp = (char*)addr;
80105468:	8b 55 08             	mov    0x8(%ebp),%edx
8010546b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010546e:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105470:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105476:	8b 00                	mov    (%eax),%eax
80105478:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010547b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010547e:	8b 00                	mov    (%eax),%eax
80105480:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105483:	eb 1c                	jmp    801054a1 <fetchstr+0x53>
    if(*s == 0)
80105485:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105488:	0f b6 00             	movzbl (%eax),%eax
8010548b:	84 c0                	test   %al,%al
8010548d:	75 0e                	jne    8010549d <fetchstr+0x4f>
      return s - *pp;
8010548f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105492:	8b 45 0c             	mov    0xc(%ebp),%eax
80105495:	8b 00                	mov    (%eax),%eax
80105497:	29 c2                	sub    %eax,%edx
80105499:	89 d0                	mov    %edx,%eax
8010549b:	eb 11                	jmp    801054ae <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
8010549d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054a4:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801054a7:	72 dc                	jb     80105485 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
801054a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801054ae:	c9                   	leave  
801054af:	c3                   	ret    

801054b0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801054b0:	55                   	push   %ebp
801054b1:	89 e5                	mov    %esp,%ebp
801054b3:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
801054b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bc:	8b 40 18             	mov    0x18(%eax),%eax
801054bf:	8b 50 44             	mov    0x44(%eax),%edx
801054c2:	8b 45 08             	mov    0x8(%ebp),%eax
801054c5:	c1 e0 02             	shl    $0x2,%eax
801054c8:	01 d0                	add    %edx,%eax
801054ca:	8d 50 04             	lea    0x4(%eax),%edx
801054cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801054d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801054d4:	89 14 24             	mov    %edx,(%esp)
801054d7:	e8 38 ff ff ff       	call   80105414 <fetchint>
}
801054dc:	c9                   	leave  
801054dd:	c3                   	ret    

801054de <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801054de:	55                   	push   %ebp
801054df:	89 e5                	mov    %esp,%ebp
801054e1:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801054e4:	8d 45 fc             	lea    -0x4(%ebp),%eax
801054e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801054eb:	8b 45 08             	mov    0x8(%ebp),%eax
801054ee:	89 04 24             	mov    %eax,(%esp)
801054f1:	e8 ba ff ff ff       	call   801054b0 <argint>
801054f6:	85 c0                	test   %eax,%eax
801054f8:	79 07                	jns    80105501 <argptr+0x23>
    return -1;
801054fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054ff:	eb 3d                	jmp    8010553e <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105501:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105504:	89 c2                	mov    %eax,%edx
80105506:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550c:	8b 00                	mov    (%eax),%eax
8010550e:	39 c2                	cmp    %eax,%edx
80105510:	73 16                	jae    80105528 <argptr+0x4a>
80105512:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105515:	89 c2                	mov    %eax,%edx
80105517:	8b 45 10             	mov    0x10(%ebp),%eax
8010551a:	01 c2                	add    %eax,%edx
8010551c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105522:	8b 00                	mov    (%eax),%eax
80105524:	39 c2                	cmp    %eax,%edx
80105526:	76 07                	jbe    8010552f <argptr+0x51>
    return -1;
80105528:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010552d:	eb 0f                	jmp    8010553e <argptr+0x60>
  *pp = (char*)i;
8010552f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105532:	89 c2                	mov    %eax,%edx
80105534:	8b 45 0c             	mov    0xc(%ebp),%eax
80105537:	89 10                	mov    %edx,(%eax)
  return 0;
80105539:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010553e:	c9                   	leave  
8010553f:	c3                   	ret    

80105540 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105540:	55                   	push   %ebp
80105541:	89 e5                	mov    %esp,%ebp
80105543:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105546:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105549:	89 44 24 04          	mov    %eax,0x4(%esp)
8010554d:	8b 45 08             	mov    0x8(%ebp),%eax
80105550:	89 04 24             	mov    %eax,(%esp)
80105553:	e8 58 ff ff ff       	call   801054b0 <argint>
80105558:	85 c0                	test   %eax,%eax
8010555a:	79 07                	jns    80105563 <argstr+0x23>
    return -1;
8010555c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105561:	eb 12                	jmp    80105575 <argstr+0x35>
  return fetchstr(addr, pp);
80105563:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105566:	8b 55 0c             	mov    0xc(%ebp),%edx
80105569:	89 54 24 04          	mov    %edx,0x4(%esp)
8010556d:	89 04 24             	mov    %eax,(%esp)
80105570:	e8 d9 fe ff ff       	call   8010544e <fetchstr>
}
80105575:	c9                   	leave  
80105576:	c3                   	ret    

80105577 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105577:	55                   	push   %ebp
80105578:	89 e5                	mov    %esp,%ebp
8010557a:	53                   	push   %ebx
8010557b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010557e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105584:	8b 40 18             	mov    0x18(%eax),%eax
80105587:	8b 40 1c             	mov    0x1c(%eax),%eax
8010558a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010558d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105591:	7e 30                	jle    801055c3 <syscall+0x4c>
80105593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105596:	83 f8 15             	cmp    $0x15,%eax
80105599:	77 28                	ja     801055c3 <syscall+0x4c>
8010559b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559e:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801055a5:	85 c0                	test   %eax,%eax
801055a7:	74 1a                	je     801055c3 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801055a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055af:	8b 58 18             	mov    0x18(%eax),%ebx
801055b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055b5:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801055bc:	ff d0                	call   *%eax
801055be:	89 43 1c             	mov    %eax,0x1c(%ebx)
801055c1:	eb 3d                	jmp    80105600 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801055c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c9:	8d 48 6c             	lea    0x6c(%eax),%ecx
801055cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801055d2:	8b 40 10             	mov    0x10(%eax),%eax
801055d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055d8:	89 54 24 0c          	mov    %edx,0xc(%esp)
801055dc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801055e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801055e4:	c7 04 24 eb 88 10 80 	movl   $0x801088eb,(%esp)
801055eb:	e8 b0 ad ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801055f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055f6:	8b 40 18             	mov    0x18(%eax),%eax
801055f9:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105600:	83 c4 24             	add    $0x24,%esp
80105603:	5b                   	pop    %ebx
80105604:	5d                   	pop    %ebp
80105605:	c3                   	ret    

80105606 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105606:	55                   	push   %ebp
80105607:	89 e5                	mov    %esp,%ebp
80105609:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010560c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010560f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105613:	8b 45 08             	mov    0x8(%ebp),%eax
80105616:	89 04 24             	mov    %eax,(%esp)
80105619:	e8 92 fe ff ff       	call   801054b0 <argint>
8010561e:	85 c0                	test   %eax,%eax
80105620:	79 07                	jns    80105629 <argfd+0x23>
    return -1;
80105622:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105627:	eb 50                	jmp    80105679 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105629:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010562c:	85 c0                	test   %eax,%eax
8010562e:	78 21                	js     80105651 <argfd+0x4b>
80105630:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105633:	83 f8 0f             	cmp    $0xf,%eax
80105636:	7f 19                	jg     80105651 <argfd+0x4b>
80105638:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010563e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105641:	83 c2 08             	add    $0x8,%edx
80105644:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105648:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010564b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010564f:	75 07                	jne    80105658 <argfd+0x52>
    return -1;
80105651:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105656:	eb 21                	jmp    80105679 <argfd+0x73>
  if(pfd)
80105658:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010565c:	74 08                	je     80105666 <argfd+0x60>
    *pfd = fd;
8010565e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105661:	8b 45 0c             	mov    0xc(%ebp),%eax
80105664:	89 10                	mov    %edx,(%eax)
  if(pf)
80105666:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010566a:	74 08                	je     80105674 <argfd+0x6e>
    *pf = f;
8010566c:	8b 45 10             	mov    0x10(%ebp),%eax
8010566f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105672:	89 10                	mov    %edx,(%eax)
  return 0;
80105674:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105679:	c9                   	leave  
8010567a:	c3                   	ret    

8010567b <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010567b:	55                   	push   %ebp
8010567c:	89 e5                	mov    %esp,%ebp
8010567e:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105681:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105688:	eb 30                	jmp    801056ba <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
8010568a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105690:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105693:	83 c2 08             	add    $0x8,%edx
80105696:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010569a:	85 c0                	test   %eax,%eax
8010569c:	75 18                	jne    801056b6 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010569e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056a4:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056a7:	8d 4a 08             	lea    0x8(%edx),%ecx
801056aa:	8b 55 08             	mov    0x8(%ebp),%edx
801056ad:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801056b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056b4:	eb 0f                	jmp    801056c5 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801056b6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801056ba:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801056be:	7e ca                	jle    8010568a <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801056c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801056c5:	c9                   	leave  
801056c6:	c3                   	ret    

801056c7 <sys_dup>:

int
sys_dup(void)
{
801056c7:	55                   	push   %ebp
801056c8:	89 e5                	mov    %esp,%ebp
801056ca:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801056cd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056d0:	89 44 24 08          	mov    %eax,0x8(%esp)
801056d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801056db:	00 
801056dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801056e3:	e8 1e ff ff ff       	call   80105606 <argfd>
801056e8:	85 c0                	test   %eax,%eax
801056ea:	79 07                	jns    801056f3 <sys_dup+0x2c>
    return -1;
801056ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056f1:	eb 29                	jmp    8010571c <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801056f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056f6:	89 04 24             	mov    %eax,(%esp)
801056f9:	e8 7d ff ff ff       	call   8010567b <fdalloc>
801056fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105701:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105705:	79 07                	jns    8010570e <sys_dup+0x47>
    return -1;
80105707:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010570c:	eb 0e                	jmp    8010571c <sys_dup+0x55>
  filedup(f);
8010570e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105711:	89 04 24             	mov    %eax,(%esp)
80105714:	e8 6d b8 ff ff       	call   80100f86 <filedup>
  return fd;
80105719:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010571c:	c9                   	leave  
8010571d:	c3                   	ret    

8010571e <sys_read>:

int
sys_read(void)
{
8010571e:	55                   	push   %ebp
8010571f:	89 e5                	mov    %esp,%ebp
80105721:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105724:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105727:	89 44 24 08          	mov    %eax,0x8(%esp)
8010572b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105732:	00 
80105733:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010573a:	e8 c7 fe ff ff       	call   80105606 <argfd>
8010573f:	85 c0                	test   %eax,%eax
80105741:	78 35                	js     80105778 <sys_read+0x5a>
80105743:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105746:	89 44 24 04          	mov    %eax,0x4(%esp)
8010574a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105751:	e8 5a fd ff ff       	call   801054b0 <argint>
80105756:	85 c0                	test   %eax,%eax
80105758:	78 1e                	js     80105778 <sys_read+0x5a>
8010575a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010575d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105761:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105764:	89 44 24 04          	mov    %eax,0x4(%esp)
80105768:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010576f:	e8 6a fd ff ff       	call   801054de <argptr>
80105774:	85 c0                	test   %eax,%eax
80105776:	79 07                	jns    8010577f <sys_read+0x61>
    return -1;
80105778:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010577d:	eb 19                	jmp    80105798 <sys_read+0x7a>
  return fileread(f, p, n);
8010577f:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105782:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105785:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105788:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010578c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105790:	89 04 24             	mov    %eax,(%esp)
80105793:	e8 5b b9 ff ff       	call   801010f3 <fileread>
}
80105798:	c9                   	leave  
80105799:	c3                   	ret    

8010579a <sys_write>:

int
sys_write(void)
{
8010579a:	55                   	push   %ebp
8010579b:	89 e5                	mov    %esp,%ebp
8010579d:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801057a0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057a3:	89 44 24 08          	mov    %eax,0x8(%esp)
801057a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057ae:	00 
801057af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057b6:	e8 4b fe ff ff       	call   80105606 <argfd>
801057bb:	85 c0                	test   %eax,%eax
801057bd:	78 35                	js     801057f4 <sys_write+0x5a>
801057bf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801057c6:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801057cd:	e8 de fc ff ff       	call   801054b0 <argint>
801057d2:	85 c0                	test   %eax,%eax
801057d4:	78 1e                	js     801057f4 <sys_write+0x5a>
801057d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057d9:	89 44 24 08          	mov    %eax,0x8(%esp)
801057dd:	8d 45 ec             	lea    -0x14(%ebp),%eax
801057e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801057e4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801057eb:	e8 ee fc ff ff       	call   801054de <argptr>
801057f0:	85 c0                	test   %eax,%eax
801057f2:	79 07                	jns    801057fb <sys_write+0x61>
    return -1;
801057f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057f9:	eb 19                	jmp    80105814 <sys_write+0x7a>
  return filewrite(f, p, n);
801057fb:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801057fe:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105801:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105804:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105808:	89 54 24 04          	mov    %edx,0x4(%esp)
8010580c:	89 04 24             	mov    %eax,(%esp)
8010580f:	e8 9b b9 ff ff       	call   801011af <filewrite>
}
80105814:	c9                   	leave  
80105815:	c3                   	ret    

80105816 <sys_close>:

int
sys_close(void)
{
80105816:	55                   	push   %ebp
80105817:	89 e5                	mov    %esp,%ebp
80105819:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010581c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010581f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105823:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105826:	89 44 24 04          	mov    %eax,0x4(%esp)
8010582a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105831:	e8 d0 fd ff ff       	call   80105606 <argfd>
80105836:	85 c0                	test   %eax,%eax
80105838:	79 07                	jns    80105841 <sys_close+0x2b>
    return -1;
8010583a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010583f:	eb 24                	jmp    80105865 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105841:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105847:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010584a:	83 c2 08             	add    $0x8,%edx
8010584d:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105854:	00 
  fileclose(f);
80105855:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105858:	89 04 24             	mov    %eax,(%esp)
8010585b:	e8 6e b7 ff ff       	call   80100fce <fileclose>
  return 0;
80105860:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105865:	c9                   	leave  
80105866:	c3                   	ret    

80105867 <sys_fstat>:

int
sys_fstat(void)
{
80105867:	55                   	push   %ebp
80105868:	89 e5                	mov    %esp,%ebp
8010586a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010586d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105870:	89 44 24 08          	mov    %eax,0x8(%esp)
80105874:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010587b:	00 
8010587c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105883:	e8 7e fd ff ff       	call   80105606 <argfd>
80105888:	85 c0                	test   %eax,%eax
8010588a:	78 1f                	js     801058ab <sys_fstat+0x44>
8010588c:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105893:	00 
80105894:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105897:	89 44 24 04          	mov    %eax,0x4(%esp)
8010589b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058a2:	e8 37 fc ff ff       	call   801054de <argptr>
801058a7:	85 c0                	test   %eax,%eax
801058a9:	79 07                	jns    801058b2 <sys_fstat+0x4b>
    return -1;
801058ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058b0:	eb 12                	jmp    801058c4 <sys_fstat+0x5d>
  return filestat(f, st);
801058b2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801058b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801058bc:	89 04 24             	mov    %eax,(%esp)
801058bf:	e8 e0 b7 ff ff       	call   801010a4 <filestat>
}
801058c4:	c9                   	leave  
801058c5:	c3                   	ret    

801058c6 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801058c6:	55                   	push   %ebp
801058c7:	89 e5                	mov    %esp,%ebp
801058c9:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801058cc:	8d 45 d8             	lea    -0x28(%ebp),%eax
801058cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801058d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801058da:	e8 61 fc ff ff       	call   80105540 <argstr>
801058df:	85 c0                	test   %eax,%eax
801058e1:	78 17                	js     801058fa <sys_link+0x34>
801058e3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801058e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801058ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058f1:	e8 4a fc ff ff       	call   80105540 <argstr>
801058f6:	85 c0                	test   %eax,%eax
801058f8:	79 0a                	jns    80105904 <sys_link+0x3e>
    return -1;
801058fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058ff:	e9 42 01 00 00       	jmp    80105a46 <sys_link+0x180>

  begin_op();
80105904:	e8 07 db ff ff       	call   80103410 <begin_op>
  if((ip = namei(old)) == 0){
80105909:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010590c:	89 04 24             	mov    %eax,(%esp)
8010590f:	e8 f2 ca ff ff       	call   80102406 <namei>
80105914:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105917:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010591b:	75 0f                	jne    8010592c <sys_link+0x66>
    end_op();
8010591d:	e8 72 db ff ff       	call   80103494 <end_op>
    return -1;
80105922:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105927:	e9 1a 01 00 00       	jmp    80105a46 <sys_link+0x180>
  }

  ilock(ip);
8010592c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010592f:	89 04 24             	mov    %eax,(%esp)
80105932:	e8 24 bf ff ff       	call   8010185b <ilock>
  if(ip->type == T_DIR){
80105937:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010593a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010593e:	66 83 f8 01          	cmp    $0x1,%ax
80105942:	75 1a                	jne    8010595e <sys_link+0x98>
    iunlockput(ip);
80105944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105947:	89 04 24             	mov    %eax,(%esp)
8010594a:	e8 90 c1 ff ff       	call   80101adf <iunlockput>
    end_op();
8010594f:	e8 40 db ff ff       	call   80103494 <end_op>
    return -1;
80105954:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105959:	e9 e8 00 00 00       	jmp    80105a46 <sys_link+0x180>
  }

  ip->nlink++;
8010595e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105961:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105965:	8d 50 01             	lea    0x1(%eax),%edx
80105968:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010596f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105972:	89 04 24             	mov    %eax,(%esp)
80105975:	e8 25 bd ff ff       	call   8010169f <iupdate>
  iunlock(ip);
8010597a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010597d:	89 04 24             	mov    %eax,(%esp)
80105980:	e8 24 c0 ff ff       	call   801019a9 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105985:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105988:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010598b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010598f:	89 04 24             	mov    %eax,(%esp)
80105992:	e8 91 ca ff ff       	call   80102428 <nameiparent>
80105997:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010599a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010599e:	75 02                	jne    801059a2 <sys_link+0xdc>
    goto bad;
801059a0:	eb 68                	jmp    80105a0a <sys_link+0x144>
  ilock(dp);
801059a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059a5:	89 04 24             	mov    %eax,(%esp)
801059a8:	e8 ae be ff ff       	call   8010185b <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801059ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059b0:	8b 10                	mov    (%eax),%edx
801059b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b5:	8b 00                	mov    (%eax),%eax
801059b7:	39 c2                	cmp    %eax,%edx
801059b9:	75 20                	jne    801059db <sys_link+0x115>
801059bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059be:	8b 40 04             	mov    0x4(%eax),%eax
801059c1:	89 44 24 08          	mov    %eax,0x8(%esp)
801059c5:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801059c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801059cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059cf:	89 04 24             	mov    %eax,(%esp)
801059d2:	e8 6f c7 ff ff       	call   80102146 <dirlink>
801059d7:	85 c0                	test   %eax,%eax
801059d9:	79 0d                	jns    801059e8 <sys_link+0x122>
    iunlockput(dp);
801059db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059de:	89 04 24             	mov    %eax,(%esp)
801059e1:	e8 f9 c0 ff ff       	call   80101adf <iunlockput>
    goto bad;
801059e6:	eb 22                	jmp    80105a0a <sys_link+0x144>
  }
  iunlockput(dp);
801059e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059eb:	89 04 24             	mov    %eax,(%esp)
801059ee:	e8 ec c0 ff ff       	call   80101adf <iunlockput>
  iput(ip);
801059f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059f6:	89 04 24             	mov    %eax,(%esp)
801059f9:	e8 10 c0 ff ff       	call   80101a0e <iput>

  end_op();
801059fe:	e8 91 da ff ff       	call   80103494 <end_op>

  return 0;
80105a03:	b8 00 00 00 00       	mov    $0x0,%eax
80105a08:	eb 3c                	jmp    80105a46 <sys_link+0x180>

bad:
  ilock(ip);
80105a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a0d:	89 04 24             	mov    %eax,(%esp)
80105a10:	e8 46 be ff ff       	call   8010185b <ilock>
  ip->nlink--;
80105a15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a18:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a1c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a22:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a29:	89 04 24             	mov    %eax,(%esp)
80105a2c:	e8 6e bc ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a34:	89 04 24             	mov    %eax,(%esp)
80105a37:	e8 a3 c0 ff ff       	call   80101adf <iunlockput>
  end_op();
80105a3c:	e8 53 da ff ff       	call   80103494 <end_op>
  return -1;
80105a41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a46:	c9                   	leave  
80105a47:	c3                   	ret    

80105a48 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105a48:	55                   	push   %ebp
80105a49:	89 e5                	mov    %esp,%ebp
80105a4b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105a4e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105a55:	eb 4b                	jmp    80105aa2 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105a61:	00 
80105a62:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a66:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105a69:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a6d:	8b 45 08             	mov    0x8(%ebp),%eax
80105a70:	89 04 24             	mov    %eax,(%esp)
80105a73:	e8 f0 c2 ff ff       	call   80101d68 <readi>
80105a78:	83 f8 10             	cmp    $0x10,%eax
80105a7b:	74 0c                	je     80105a89 <isdirempty+0x41>
      panic("isdirempty: readi");
80105a7d:	c7 04 24 07 89 10 80 	movl   $0x80108907,(%esp)
80105a84:	e8 b1 aa ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105a89:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105a8d:	66 85 c0             	test   %ax,%ax
80105a90:	74 07                	je     80105a99 <isdirempty+0x51>
      return 0;
80105a92:	b8 00 00 00 00       	mov    $0x0,%eax
80105a97:	eb 1b                	jmp    80105ab4 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105a99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a9c:	83 c0 10             	add    $0x10,%eax
80105a9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105aa2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105aa5:	8b 45 08             	mov    0x8(%ebp),%eax
80105aa8:	8b 40 18             	mov    0x18(%eax),%eax
80105aab:	39 c2                	cmp    %eax,%edx
80105aad:	72 a8                	jb     80105a57 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105aaf:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105ab4:	c9                   	leave  
80105ab5:	c3                   	ret    

80105ab6 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105ab6:	55                   	push   %ebp
80105ab7:	89 e5                	mov    %esp,%ebp
80105ab9:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105abc:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105abf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ac3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105aca:	e8 71 fa ff ff       	call   80105540 <argstr>
80105acf:	85 c0                	test   %eax,%eax
80105ad1:	79 0a                	jns    80105add <sys_unlink+0x27>
    return -1;
80105ad3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad8:	e9 af 01 00 00       	jmp    80105c8c <sys_unlink+0x1d6>

  begin_op();
80105add:	e8 2e d9 ff ff       	call   80103410 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105ae2:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105ae5:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105ae8:	89 54 24 04          	mov    %edx,0x4(%esp)
80105aec:	89 04 24             	mov    %eax,(%esp)
80105aef:	e8 34 c9 ff ff       	call   80102428 <nameiparent>
80105af4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105af7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105afb:	75 0f                	jne    80105b0c <sys_unlink+0x56>
    end_op();
80105afd:	e8 92 d9 ff ff       	call   80103494 <end_op>
    return -1;
80105b02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b07:	e9 80 01 00 00       	jmp    80105c8c <sys_unlink+0x1d6>
  }

  ilock(dp);
80105b0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b0f:	89 04 24             	mov    %eax,(%esp)
80105b12:	e8 44 bd ff ff       	call   8010185b <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105b17:	c7 44 24 04 19 89 10 	movl   $0x80108919,0x4(%esp)
80105b1e:	80 
80105b1f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b22:	89 04 24             	mov    %eax,(%esp)
80105b25:	e8 31 c5 ff ff       	call   8010205b <namecmp>
80105b2a:	85 c0                	test   %eax,%eax
80105b2c:	0f 84 45 01 00 00    	je     80105c77 <sys_unlink+0x1c1>
80105b32:	c7 44 24 04 1b 89 10 	movl   $0x8010891b,0x4(%esp)
80105b39:	80 
80105b3a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b3d:	89 04 24             	mov    %eax,(%esp)
80105b40:	e8 16 c5 ff ff       	call   8010205b <namecmp>
80105b45:	85 c0                	test   %eax,%eax
80105b47:	0f 84 2a 01 00 00    	je     80105c77 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105b4d:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105b50:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b54:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b57:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5e:	89 04 24             	mov    %eax,(%esp)
80105b61:	e8 17 c5 ff ff       	call   8010207d <dirlookup>
80105b66:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b69:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b6d:	75 05                	jne    80105b74 <sys_unlink+0xbe>
    goto bad;
80105b6f:	e9 03 01 00 00       	jmp    80105c77 <sys_unlink+0x1c1>
  ilock(ip);
80105b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b77:	89 04 24             	mov    %eax,(%esp)
80105b7a:	e8 dc bc ff ff       	call   8010185b <ilock>

  if(ip->nlink < 1)
80105b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b82:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b86:	66 85 c0             	test   %ax,%ax
80105b89:	7f 0c                	jg     80105b97 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105b8b:	c7 04 24 1e 89 10 80 	movl   $0x8010891e,(%esp)
80105b92:	e8 a3 a9 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105b97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b9a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b9e:	66 83 f8 01          	cmp    $0x1,%ax
80105ba2:	75 1f                	jne    80105bc3 <sys_unlink+0x10d>
80105ba4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba7:	89 04 24             	mov    %eax,(%esp)
80105baa:	e8 99 fe ff ff       	call   80105a48 <isdirempty>
80105baf:	85 c0                	test   %eax,%eax
80105bb1:	75 10                	jne    80105bc3 <sys_unlink+0x10d>
    iunlockput(ip);
80105bb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bb6:	89 04 24             	mov    %eax,(%esp)
80105bb9:	e8 21 bf ff ff       	call   80101adf <iunlockput>
    goto bad;
80105bbe:	e9 b4 00 00 00       	jmp    80105c77 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105bc3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105bca:	00 
80105bcb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105bd2:	00 
80105bd3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105bd6:	89 04 24             	mov    %eax,(%esp)
80105bd9:	e8 90 f5 ff ff       	call   8010516e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105bde:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105be1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105be8:	00 
80105be9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bed:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105bf0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bf7:	89 04 24             	mov    %eax,(%esp)
80105bfa:	e8 cd c2 ff ff       	call   80101ecc <writei>
80105bff:	83 f8 10             	cmp    $0x10,%eax
80105c02:	74 0c                	je     80105c10 <sys_unlink+0x15a>
    panic("unlink: writei");
80105c04:	c7 04 24 30 89 10 80 	movl   $0x80108930,(%esp)
80105c0b:	e8 2a a9 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105c10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c13:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c17:	66 83 f8 01          	cmp    $0x1,%ax
80105c1b:	75 1c                	jne    80105c39 <sys_unlink+0x183>
    dp->nlink--;
80105c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c20:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c24:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2a:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c31:	89 04 24             	mov    %eax,(%esp)
80105c34:	e8 66 ba ff ff       	call   8010169f <iupdate>
  }
  iunlockput(dp);
80105c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3c:	89 04 24             	mov    %eax,(%esp)
80105c3f:	e8 9b be ff ff       	call   80101adf <iunlockput>

  ip->nlink--;
80105c44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c47:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c4b:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c51:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105c55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c58:	89 04 24             	mov    %eax,(%esp)
80105c5b:	e8 3f ba ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105c60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c63:	89 04 24             	mov    %eax,(%esp)
80105c66:	e8 74 be ff ff       	call   80101adf <iunlockput>

  end_op();
80105c6b:	e8 24 d8 ff ff       	call   80103494 <end_op>

  return 0;
80105c70:	b8 00 00 00 00       	mov    $0x0,%eax
80105c75:	eb 15                	jmp    80105c8c <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7a:	89 04 24             	mov    %eax,(%esp)
80105c7d:	e8 5d be ff ff       	call   80101adf <iunlockput>
  end_op();
80105c82:	e8 0d d8 ff ff       	call   80103494 <end_op>
  return -1;
80105c87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c8c:	c9                   	leave  
80105c8d:	c3                   	ret    

80105c8e <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105c8e:	55                   	push   %ebp
80105c8f:	89 e5                	mov    %esp,%ebp
80105c91:	83 ec 48             	sub    $0x48,%esp
80105c94:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105c97:	8b 55 10             	mov    0x10(%ebp),%edx
80105c9a:	8b 45 14             	mov    0x14(%ebp),%eax
80105c9d:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105ca1:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ca5:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105ca9:	8d 45 de             	lea    -0x22(%ebp),%eax
80105cac:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb0:	8b 45 08             	mov    0x8(%ebp),%eax
80105cb3:	89 04 24             	mov    %eax,(%esp)
80105cb6:	e8 6d c7 ff ff       	call   80102428 <nameiparent>
80105cbb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cbe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cc2:	75 0a                	jne    80105cce <create+0x40>
    return 0;
80105cc4:	b8 00 00 00 00       	mov    $0x0,%eax
80105cc9:	e9 7e 01 00 00       	jmp    80105e4c <create+0x1be>
  ilock(dp);
80105cce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cd1:	89 04 24             	mov    %eax,(%esp)
80105cd4:	e8 82 bb ff ff       	call   8010185b <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105cd9:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105cdc:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ce0:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ce3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cea:	89 04 24             	mov    %eax,(%esp)
80105ced:	e8 8b c3 ff ff       	call   8010207d <dirlookup>
80105cf2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105cf5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cf9:	74 47                	je     80105d42 <create+0xb4>
    iunlockput(dp);
80105cfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cfe:	89 04 24             	mov    %eax,(%esp)
80105d01:	e8 d9 bd ff ff       	call   80101adf <iunlockput>
    ilock(ip);
80105d06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d09:	89 04 24             	mov    %eax,(%esp)
80105d0c:	e8 4a bb ff ff       	call   8010185b <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105d11:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105d16:	75 15                	jne    80105d2d <create+0x9f>
80105d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d1f:	66 83 f8 02          	cmp    $0x2,%ax
80105d23:	75 08                	jne    80105d2d <create+0x9f>
      return ip;
80105d25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d28:	e9 1f 01 00 00       	jmp    80105e4c <create+0x1be>
    iunlockput(ip);
80105d2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d30:	89 04 24             	mov    %eax,(%esp)
80105d33:	e8 a7 bd ff ff       	call   80101adf <iunlockput>
    return 0;
80105d38:	b8 00 00 00 00       	mov    $0x0,%eax
80105d3d:	e9 0a 01 00 00       	jmp    80105e4c <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105d42:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d49:	8b 00                	mov    (%eax),%eax
80105d4b:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d4f:	89 04 24             	mov    %eax,(%esp)
80105d52:	e8 69 b8 ff ff       	call   801015c0 <ialloc>
80105d57:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d5a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d5e:	75 0c                	jne    80105d6c <create+0xde>
    panic("create: ialloc");
80105d60:	c7 04 24 3f 89 10 80 	movl   $0x8010893f,(%esp)
80105d67:	e8 ce a7 ff ff       	call   8010053a <panic>

  ilock(ip);
80105d6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d6f:	89 04 24             	mov    %eax,(%esp)
80105d72:	e8 e4 ba ff ff       	call   8010185b <ilock>
  ip->major = major;
80105d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d7a:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105d7e:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105d82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d85:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105d89:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105d8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d90:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105d96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d99:	89 04 24             	mov    %eax,(%esp)
80105d9c:	e8 fe b8 ff ff       	call   8010169f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105da1:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105da6:	75 6a                	jne    80105e12 <create+0x184>
    dp->nlink++;  // for ".."
80105da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dab:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105daf:	8d 50 01             	lea    0x1(%eax),%edx
80105db2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105db5:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dbc:	89 04 24             	mov    %eax,(%esp)
80105dbf:	e8 db b8 ff ff       	call   8010169f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105dc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc7:	8b 40 04             	mov    0x4(%eax),%eax
80105dca:	89 44 24 08          	mov    %eax,0x8(%esp)
80105dce:	c7 44 24 04 19 89 10 	movl   $0x80108919,0x4(%esp)
80105dd5:	80 
80105dd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd9:	89 04 24             	mov    %eax,(%esp)
80105ddc:	e8 65 c3 ff ff       	call   80102146 <dirlink>
80105de1:	85 c0                	test   %eax,%eax
80105de3:	78 21                	js     80105e06 <create+0x178>
80105de5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de8:	8b 40 04             	mov    0x4(%eax),%eax
80105deb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105def:	c7 44 24 04 1b 89 10 	movl   $0x8010891b,0x4(%esp)
80105df6:	80 
80105df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dfa:	89 04 24             	mov    %eax,(%esp)
80105dfd:	e8 44 c3 ff ff       	call   80102146 <dirlink>
80105e02:	85 c0                	test   %eax,%eax
80105e04:	79 0c                	jns    80105e12 <create+0x184>
      panic("create dots");
80105e06:	c7 04 24 4e 89 10 80 	movl   $0x8010894e,(%esp)
80105e0d:	e8 28 a7 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e15:	8b 40 04             	mov    0x4(%eax),%eax
80105e18:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e1c:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e26:	89 04 24             	mov    %eax,(%esp)
80105e29:	e8 18 c3 ff ff       	call   80102146 <dirlink>
80105e2e:	85 c0                	test   %eax,%eax
80105e30:	79 0c                	jns    80105e3e <create+0x1b0>
    panic("create: dirlink");
80105e32:	c7 04 24 5a 89 10 80 	movl   $0x8010895a,(%esp)
80105e39:	e8 fc a6 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80105e3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e41:	89 04 24             	mov    %eax,(%esp)
80105e44:	e8 96 bc ff ff       	call   80101adf <iunlockput>

  return ip;
80105e49:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105e4c:	c9                   	leave  
80105e4d:	c3                   	ret    

80105e4e <sys_open>:

int
sys_open(void)
{
80105e4e:	55                   	push   %ebp
80105e4f:	89 e5                	mov    %esp,%ebp
80105e51:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105e54:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105e57:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e5b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e62:	e8 d9 f6 ff ff       	call   80105540 <argstr>
80105e67:	85 c0                	test   %eax,%eax
80105e69:	78 17                	js     80105e82 <sys_open+0x34>
80105e6b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e72:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e79:	e8 32 f6 ff ff       	call   801054b0 <argint>
80105e7e:	85 c0                	test   %eax,%eax
80105e80:	79 0a                	jns    80105e8c <sys_open+0x3e>
    return -1;
80105e82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e87:	e9 5c 01 00 00       	jmp    80105fe8 <sys_open+0x19a>

  begin_op();
80105e8c:	e8 7f d5 ff ff       	call   80103410 <begin_op>

  if(omode & O_CREATE){
80105e91:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e94:	25 00 02 00 00       	and    $0x200,%eax
80105e99:	85 c0                	test   %eax,%eax
80105e9b:	74 3b                	je     80105ed8 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105e9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ea0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105ea7:	00 
80105ea8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105eaf:	00 
80105eb0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105eb7:	00 
80105eb8:	89 04 24             	mov    %eax,(%esp)
80105ebb:	e8 ce fd ff ff       	call   80105c8e <create>
80105ec0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105ec3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ec7:	75 6b                	jne    80105f34 <sys_open+0xe6>
      end_op();
80105ec9:	e8 c6 d5 ff ff       	call   80103494 <end_op>
      return -1;
80105ece:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed3:	e9 10 01 00 00       	jmp    80105fe8 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80105ed8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105edb:	89 04 24             	mov    %eax,(%esp)
80105ede:	e8 23 c5 ff ff       	call   80102406 <namei>
80105ee3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ee6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105eea:	75 0f                	jne    80105efb <sys_open+0xad>
      end_op();
80105eec:	e8 a3 d5 ff ff       	call   80103494 <end_op>
      return -1;
80105ef1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ef6:	e9 ed 00 00 00       	jmp    80105fe8 <sys_open+0x19a>
    }
    ilock(ip);
80105efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105efe:	89 04 24             	mov    %eax,(%esp)
80105f01:	e8 55 b9 ff ff       	call   8010185b <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f09:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f0d:	66 83 f8 01          	cmp    $0x1,%ax
80105f11:	75 21                	jne    80105f34 <sys_open+0xe6>
80105f13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f16:	85 c0                	test   %eax,%eax
80105f18:	74 1a                	je     80105f34 <sys_open+0xe6>
      iunlockput(ip);
80105f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f1d:	89 04 24             	mov    %eax,(%esp)
80105f20:	e8 ba bb ff ff       	call   80101adf <iunlockput>
      end_op();
80105f25:	e8 6a d5 ff ff       	call   80103494 <end_op>
      return -1;
80105f2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f2f:	e9 b4 00 00 00       	jmp    80105fe8 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105f34:	e8 ed af ff ff       	call   80100f26 <filealloc>
80105f39:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f3c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f40:	74 14                	je     80105f56 <sys_open+0x108>
80105f42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f45:	89 04 24             	mov    %eax,(%esp)
80105f48:	e8 2e f7 ff ff       	call   8010567b <fdalloc>
80105f4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105f50:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105f54:	79 28                	jns    80105f7e <sys_open+0x130>
    if(f)
80105f56:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f5a:	74 0b                	je     80105f67 <sys_open+0x119>
      fileclose(f);
80105f5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f5f:	89 04 24             	mov    %eax,(%esp)
80105f62:	e8 67 b0 ff ff       	call   80100fce <fileclose>
    iunlockput(ip);
80105f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f6a:	89 04 24             	mov    %eax,(%esp)
80105f6d:	e8 6d bb ff ff       	call   80101adf <iunlockput>
    end_op();
80105f72:	e8 1d d5 ff ff       	call   80103494 <end_op>
    return -1;
80105f77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f7c:	eb 6a                	jmp    80105fe8 <sys_open+0x19a>
  }
  iunlock(ip);
80105f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f81:	89 04 24             	mov    %eax,(%esp)
80105f84:	e8 20 ba ff ff       	call   801019a9 <iunlock>
  end_op();
80105f89:	e8 06 d5 ff ff       	call   80103494 <end_op>

  f->type = FD_INODE;
80105f8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f91:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105f97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f9d:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105fa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105faa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fad:	83 e0 01             	and    $0x1,%eax
80105fb0:	85 c0                	test   %eax,%eax
80105fb2:	0f 94 c0             	sete   %al
80105fb5:	89 c2                	mov    %eax,%edx
80105fb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fba:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105fbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fc0:	83 e0 01             	and    $0x1,%eax
80105fc3:	85 c0                	test   %eax,%eax
80105fc5:	75 0a                	jne    80105fd1 <sys_open+0x183>
80105fc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fca:	83 e0 02             	and    $0x2,%eax
80105fcd:	85 c0                	test   %eax,%eax
80105fcf:	74 07                	je     80105fd8 <sys_open+0x18a>
80105fd1:	b8 01 00 00 00       	mov    $0x1,%eax
80105fd6:	eb 05                	jmp    80105fdd <sys_open+0x18f>
80105fd8:	b8 00 00 00 00       	mov    $0x0,%eax
80105fdd:	89 c2                	mov    %eax,%edx
80105fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fe2:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105fe5:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105fe8:	c9                   	leave  
80105fe9:	c3                   	ret    

80105fea <sys_mkdir>:

int
sys_mkdir(void)
{
80105fea:	55                   	push   %ebp
80105feb:	89 e5                	mov    %esp,%ebp
80105fed:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80105ff0:	e8 1b d4 ff ff       	call   80103410 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105ff5:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ffc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106003:	e8 38 f5 ff ff       	call   80105540 <argstr>
80106008:	85 c0                	test   %eax,%eax
8010600a:	78 2c                	js     80106038 <sys_mkdir+0x4e>
8010600c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010600f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106016:	00 
80106017:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010601e:	00 
8010601f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106026:	00 
80106027:	89 04 24             	mov    %eax,(%esp)
8010602a:	e8 5f fc ff ff       	call   80105c8e <create>
8010602f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106032:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106036:	75 0c                	jne    80106044 <sys_mkdir+0x5a>
    end_op();
80106038:	e8 57 d4 ff ff       	call   80103494 <end_op>
    return -1;
8010603d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106042:	eb 15                	jmp    80106059 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106044:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106047:	89 04 24             	mov    %eax,(%esp)
8010604a:	e8 90 ba ff ff       	call   80101adf <iunlockput>
  end_op();
8010604f:	e8 40 d4 ff ff       	call   80103494 <end_op>
  return 0;
80106054:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106059:	c9                   	leave  
8010605a:	c3                   	ret    

8010605b <sys_mknod>:

int
sys_mknod(void)
{
8010605b:	55                   	push   %ebp
8010605c:	89 e5                	mov    %esp,%ebp
8010605e:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106061:	e8 aa d3 ff ff       	call   80103410 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106066:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106069:	89 44 24 04          	mov    %eax,0x4(%esp)
8010606d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106074:	e8 c7 f4 ff ff       	call   80105540 <argstr>
80106079:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010607c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106080:	78 5e                	js     801060e0 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106082:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106085:	89 44 24 04          	mov    %eax,0x4(%esp)
80106089:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106090:	e8 1b f4 ff ff       	call   801054b0 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106095:	85 c0                	test   %eax,%eax
80106097:	78 47                	js     801060e0 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106099:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010609c:	89 44 24 04          	mov    %eax,0x4(%esp)
801060a0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801060a7:	e8 04 f4 ff ff       	call   801054b0 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801060ac:	85 c0                	test   %eax,%eax
801060ae:	78 30                	js     801060e0 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801060b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060b3:	0f bf c8             	movswl %ax,%ecx
801060b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060b9:	0f bf d0             	movswl %ax,%edx
801060bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801060c3:	89 54 24 08          	mov    %edx,0x8(%esp)
801060c7:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801060ce:	00 
801060cf:	89 04 24             	mov    %eax,(%esp)
801060d2:	e8 b7 fb ff ff       	call   80105c8e <create>
801060d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060da:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060de:	75 0c                	jne    801060ec <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801060e0:	e8 af d3 ff ff       	call   80103494 <end_op>
    return -1;
801060e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060ea:	eb 15                	jmp    80106101 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801060ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ef:	89 04 24             	mov    %eax,(%esp)
801060f2:	e8 e8 b9 ff ff       	call   80101adf <iunlockput>
  end_op();
801060f7:	e8 98 d3 ff ff       	call   80103494 <end_op>
  return 0;
801060fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106101:	c9                   	leave  
80106102:	c3                   	ret    

80106103 <sys_chdir>:

int
sys_chdir(void)
{
80106103:	55                   	push   %ebp
80106104:	89 e5                	mov    %esp,%ebp
80106106:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106109:	e8 02 d3 ff ff       	call   80103410 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
8010610e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106111:	89 44 24 04          	mov    %eax,0x4(%esp)
80106115:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010611c:	e8 1f f4 ff ff       	call   80105540 <argstr>
80106121:	85 c0                	test   %eax,%eax
80106123:	78 14                	js     80106139 <sys_chdir+0x36>
80106125:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106128:	89 04 24             	mov    %eax,(%esp)
8010612b:	e8 d6 c2 ff ff       	call   80102406 <namei>
80106130:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106133:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106137:	75 0c                	jne    80106145 <sys_chdir+0x42>
    end_op();
80106139:	e8 56 d3 ff ff       	call   80103494 <end_op>
    return -1;
8010613e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106143:	eb 61                	jmp    801061a6 <sys_chdir+0xa3>
  }
  ilock(ip);
80106145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106148:	89 04 24             	mov    %eax,(%esp)
8010614b:	e8 0b b7 ff ff       	call   8010185b <ilock>
  if(ip->type != T_DIR){
80106150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106153:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106157:	66 83 f8 01          	cmp    $0x1,%ax
8010615b:	74 17                	je     80106174 <sys_chdir+0x71>
    iunlockput(ip);
8010615d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106160:	89 04 24             	mov    %eax,(%esp)
80106163:	e8 77 b9 ff ff       	call   80101adf <iunlockput>
    end_op();
80106168:	e8 27 d3 ff ff       	call   80103494 <end_op>
    return -1;
8010616d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106172:	eb 32                	jmp    801061a6 <sys_chdir+0xa3>
  }
  iunlock(ip);
80106174:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106177:	89 04 24             	mov    %eax,(%esp)
8010617a:	e8 2a b8 ff ff       	call   801019a9 <iunlock>
  iput(proc->cwd);
8010617f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106185:	8b 40 68             	mov    0x68(%eax),%eax
80106188:	89 04 24             	mov    %eax,(%esp)
8010618b:	e8 7e b8 ff ff       	call   80101a0e <iput>
  end_op();
80106190:	e8 ff d2 ff ff       	call   80103494 <end_op>
  proc->cwd = ip;
80106195:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010619b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010619e:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801061a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061a6:	c9                   	leave  
801061a7:	c3                   	ret    

801061a8 <sys_exec>:

int
sys_exec(void)
{
801061a8:	55                   	push   %ebp
801061a9:	89 e5                	mov    %esp,%ebp
801061ab:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801061b1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801061b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061bf:	e8 7c f3 ff ff       	call   80105540 <argstr>
801061c4:	85 c0                	test   %eax,%eax
801061c6:	78 1a                	js     801061e2 <sys_exec+0x3a>
801061c8:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801061ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801061d2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061d9:	e8 d2 f2 ff ff       	call   801054b0 <argint>
801061de:	85 c0                	test   %eax,%eax
801061e0:	79 0a                	jns    801061ec <sys_exec+0x44>
    return -1;
801061e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e7:	e9 c8 00 00 00       	jmp    801062b4 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
801061ec:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801061f3:	00 
801061f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801061fb:	00 
801061fc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106202:	89 04 24             	mov    %eax,(%esp)
80106205:	e8 64 ef ff ff       	call   8010516e <memset>
  for(i=0;; i++){
8010620a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106214:	83 f8 1f             	cmp    $0x1f,%eax
80106217:	76 0a                	jbe    80106223 <sys_exec+0x7b>
      return -1;
80106219:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010621e:	e9 91 00 00 00       	jmp    801062b4 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106226:	c1 e0 02             	shl    $0x2,%eax
80106229:	89 c2                	mov    %eax,%edx
8010622b:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106231:	01 c2                	add    %eax,%edx
80106233:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106239:	89 44 24 04          	mov    %eax,0x4(%esp)
8010623d:	89 14 24             	mov    %edx,(%esp)
80106240:	e8 cf f1 ff ff       	call   80105414 <fetchint>
80106245:	85 c0                	test   %eax,%eax
80106247:	79 07                	jns    80106250 <sys_exec+0xa8>
      return -1;
80106249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010624e:	eb 64                	jmp    801062b4 <sys_exec+0x10c>
    if(uarg == 0){
80106250:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106256:	85 c0                	test   %eax,%eax
80106258:	75 26                	jne    80106280 <sys_exec+0xd8>
      argv[i] = 0;
8010625a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010625d:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106264:	00 00 00 00 
      break;
80106268:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106269:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010626c:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106272:	89 54 24 04          	mov    %edx,0x4(%esp)
80106276:	89 04 24             	mov    %eax,(%esp)
80106279:	e8 71 a8 ff ff       	call   80100aef <exec>
8010627e:	eb 34                	jmp    801062b4 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106280:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106286:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106289:	c1 e2 02             	shl    $0x2,%edx
8010628c:	01 c2                	add    %eax,%edx
8010628e:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106294:	89 54 24 04          	mov    %edx,0x4(%esp)
80106298:	89 04 24             	mov    %eax,(%esp)
8010629b:	e8 ae f1 ff ff       	call   8010544e <fetchstr>
801062a0:	85 c0                	test   %eax,%eax
801062a2:	79 07                	jns    801062ab <sys_exec+0x103>
      return -1;
801062a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062a9:	eb 09                	jmp    801062b4 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801062ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
801062af:	e9 5d ff ff ff       	jmp    80106211 <sys_exec+0x69>
  return exec(path, argv);
}
801062b4:	c9                   	leave  
801062b5:	c3                   	ret    

801062b6 <sys_pipe>:

int
sys_pipe(void)
{
801062b6:	55                   	push   %ebp
801062b7:	89 e5                	mov    %esp,%ebp
801062b9:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801062bc:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801062c3:	00 
801062c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801062cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062d2:	e8 07 f2 ff ff       	call   801054de <argptr>
801062d7:	85 c0                	test   %eax,%eax
801062d9:	79 0a                	jns    801062e5 <sys_pipe+0x2f>
    return -1;
801062db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062e0:	e9 9b 00 00 00       	jmp    80106380 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801062e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801062e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ec:	8d 45 e8             	lea    -0x18(%ebp),%eax
801062ef:	89 04 24             	mov    %eax,(%esp)
801062f2:	e8 2a dc ff ff       	call   80103f21 <pipealloc>
801062f7:	85 c0                	test   %eax,%eax
801062f9:	79 07                	jns    80106302 <sys_pipe+0x4c>
    return -1;
801062fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106300:	eb 7e                	jmp    80106380 <sys_pipe+0xca>
  fd0 = -1;
80106302:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106309:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010630c:	89 04 24             	mov    %eax,(%esp)
8010630f:	e8 67 f3 ff ff       	call   8010567b <fdalloc>
80106314:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106317:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010631b:	78 14                	js     80106331 <sys_pipe+0x7b>
8010631d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106320:	89 04 24             	mov    %eax,(%esp)
80106323:	e8 53 f3 ff ff       	call   8010567b <fdalloc>
80106328:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010632b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010632f:	79 37                	jns    80106368 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106331:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106335:	78 14                	js     8010634b <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106337:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010633d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106340:	83 c2 08             	add    $0x8,%edx
80106343:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010634a:	00 
    fileclose(rf);
8010634b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010634e:	89 04 24             	mov    %eax,(%esp)
80106351:	e8 78 ac ff ff       	call   80100fce <fileclose>
    fileclose(wf);
80106356:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106359:	89 04 24             	mov    %eax,(%esp)
8010635c:	e8 6d ac ff ff       	call   80100fce <fileclose>
    return -1;
80106361:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106366:	eb 18                	jmp    80106380 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106368:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010636b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010636e:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106370:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106373:	8d 50 04             	lea    0x4(%eax),%edx
80106376:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106379:	89 02                	mov    %eax,(%edx)
  return 0;
8010637b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106380:	c9                   	leave  
80106381:	c3                   	ret    

80106382 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106382:	55                   	push   %ebp
80106383:	89 e5                	mov    %esp,%ebp
80106385:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106388:	e8 92 e2 ff ff       	call   8010461f <fork>
}
8010638d:	c9                   	leave  
8010638e:	c3                   	ret    

8010638f <sys_exit>:

int
sys_exit(void)
{
8010638f:	55                   	push   %ebp
80106390:	89 e5                	mov    %esp,%ebp
80106392:	83 ec 08             	sub    $0x8,%esp
  exit();
80106395:	e8 00 e4 ff ff       	call   8010479a <exit>
  return 0;  // not reached
8010639a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010639f:	c9                   	leave  
801063a0:	c3                   	ret    

801063a1 <sys_wait>:

int
sys_wait(void)
{
801063a1:	55                   	push   %ebp
801063a2:	89 e5                	mov    %esp,%ebp
801063a4:	83 ec 08             	sub    $0x8,%esp
  return wait();
801063a7:	e8 10 e5 ff ff       	call   801048bc <wait>
}
801063ac:	c9                   	leave  
801063ad:	c3                   	ret    

801063ae <sys_kill>:

int
sys_kill(void)
{
801063ae:	55                   	push   %ebp
801063af:	89 e5                	mov    %esp,%ebp
801063b1:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801063b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801063bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063c2:	e8 e9 f0 ff ff       	call   801054b0 <argint>
801063c7:	85 c0                	test   %eax,%eax
801063c9:	79 07                	jns    801063d2 <sys_kill+0x24>
    return -1;
801063cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063d0:	eb 0b                	jmp    801063dd <sys_kill+0x2f>
  return kill(pid);
801063d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d5:	89 04 24             	mov    %eax,(%esp)
801063d8:	e8 1b e9 ff ff       	call   80104cf8 <kill>
}
801063dd:	c9                   	leave  
801063de:	c3                   	ret    

801063df <sys_getpid>:

int
sys_getpid(void)
{
801063df:	55                   	push   %ebp
801063e0:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801063e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063e8:	8b 40 10             	mov    0x10(%eax),%eax
}
801063eb:	5d                   	pop    %ebp
801063ec:	c3                   	ret    

801063ed <sys_sbrk>:

int
sys_sbrk(void)
{
801063ed:	55                   	push   %ebp
801063ee:	89 e5                	mov    %esp,%ebp
801063f0:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801063f3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801063fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106401:	e8 aa f0 ff ff       	call   801054b0 <argint>
80106406:	85 c0                	test   %eax,%eax
80106408:	79 07                	jns    80106411 <sys_sbrk+0x24>
    return -1;
8010640a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010640f:	eb 24                	jmp    80106435 <sys_sbrk+0x48>
  addr = proc->sz;
80106411:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106417:	8b 00                	mov    (%eax),%eax
80106419:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010641c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010641f:	89 04 24             	mov    %eax,(%esp)
80106422:	e8 53 e1 ff ff       	call   8010457a <growproc>
80106427:	85 c0                	test   %eax,%eax
80106429:	79 07                	jns    80106432 <sys_sbrk+0x45>
    return -1;
8010642b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106430:	eb 03                	jmp    80106435 <sys_sbrk+0x48>
  return addr;
80106432:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106435:	c9                   	leave  
80106436:	c3                   	ret    

80106437 <sys_sleep>:

int
sys_sleep(void)
{
80106437:	55                   	push   %ebp
80106438:	89 e5                	mov    %esp,%ebp
8010643a:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010643d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106440:	89 44 24 04          	mov    %eax,0x4(%esp)
80106444:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010644b:	e8 60 f0 ff ff       	call   801054b0 <argint>
80106450:	85 c0                	test   %eax,%eax
80106452:	79 07                	jns    8010645b <sys_sleep+0x24>
    return -1;
80106454:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106459:	eb 6c                	jmp    801064c7 <sys_sleep+0x90>
  acquire(&tickslock);
8010645b:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106462:	e8 b3 ea ff ff       	call   80104f1a <acquire>
  ticks0 = ticks;
80106467:	a1 e0 50 11 80       	mov    0x801150e0,%eax
8010646c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010646f:	eb 34                	jmp    801064a5 <sys_sleep+0x6e>
    if(proc->killed){
80106471:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106477:	8b 40 24             	mov    0x24(%eax),%eax
8010647a:	85 c0                	test   %eax,%eax
8010647c:	74 13                	je     80106491 <sys_sleep+0x5a>
      release(&tickslock);
8010647e:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106485:	e8 f2 ea ff ff       	call   80104f7c <release>
      return -1;
8010648a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648f:	eb 36                	jmp    801064c7 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106491:	c7 44 24 04 a0 48 11 	movl   $0x801148a0,0x4(%esp)
80106498:	80 
80106499:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
801064a0:	e8 50 e7 ff ff       	call   80104bf5 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801064a5:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801064aa:	2b 45 f4             	sub    -0xc(%ebp),%eax
801064ad:	89 c2                	mov    %eax,%edx
801064af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b2:	39 c2                	cmp    %eax,%edx
801064b4:	72 bb                	jb     80106471 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801064b6:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801064bd:	e8 ba ea ff ff       	call   80104f7c <release>
  return 0;
801064c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064c7:	c9                   	leave  
801064c8:	c3                   	ret    

801064c9 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801064c9:	55                   	push   %ebp
801064ca:	89 e5                	mov    %esp,%ebp
801064cc:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801064cf:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801064d6:	e8 3f ea ff ff       	call   80104f1a <acquire>
  xticks = ticks;
801064db:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801064e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801064e3:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801064ea:	e8 8d ea ff ff       	call   80104f7c <release>
  return xticks;
801064ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801064f2:	c9                   	leave  
801064f3:	c3                   	ret    

801064f4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801064f4:	55                   	push   %ebp
801064f5:	89 e5                	mov    %esp,%ebp
801064f7:	83 ec 08             	sub    $0x8,%esp
801064fa:	8b 55 08             	mov    0x8(%ebp),%edx
801064fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80106500:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106504:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106507:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010650b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010650f:	ee                   	out    %al,(%dx)
}
80106510:	c9                   	leave  
80106511:	c3                   	ret    

80106512 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106512:	55                   	push   %ebp
80106513:	89 e5                	mov    %esp,%ebp
80106515:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106518:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010651f:	00 
80106520:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106527:	e8 c8 ff ff ff       	call   801064f4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010652c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106533:	00 
80106534:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010653b:	e8 b4 ff ff ff       	call   801064f4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106540:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106547:	00 
80106548:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010654f:	e8 a0 ff ff ff       	call   801064f4 <outb>
  picenable(IRQ_TIMER);
80106554:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010655b:	e8 54 d8 ff ff       	call   80103db4 <picenable>
}
80106560:	c9                   	leave  
80106561:	c3                   	ret    

80106562 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106562:	1e                   	push   %ds
  pushl %es
80106563:	06                   	push   %es
  pushl %fs
80106564:	0f a0                	push   %fs
  pushl %gs
80106566:	0f a8                	push   %gs
  pushal
80106568:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106569:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010656d:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010656f:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106571:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106575:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106577:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106579:	54                   	push   %esp
  call trap
8010657a:	e8 d8 01 00 00       	call   80106757 <trap>
  addl $4, %esp
8010657f:	83 c4 04             	add    $0x4,%esp

80106582 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106582:	61                   	popa   
  popl %gs
80106583:	0f a9                	pop    %gs
  popl %fs
80106585:	0f a1                	pop    %fs
  popl %es
80106587:	07                   	pop    %es
  popl %ds
80106588:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106589:	83 c4 08             	add    $0x8,%esp
  iret
8010658c:	cf                   	iret   

8010658d <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010658d:	55                   	push   %ebp
8010658e:	89 e5                	mov    %esp,%ebp
80106590:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106593:	8b 45 0c             	mov    0xc(%ebp),%eax
80106596:	83 e8 01             	sub    $0x1,%eax
80106599:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010659d:	8b 45 08             	mov    0x8(%ebp),%eax
801065a0:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801065a4:	8b 45 08             	mov    0x8(%ebp),%eax
801065a7:	c1 e8 10             	shr    $0x10,%eax
801065aa:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801065ae:	8d 45 fa             	lea    -0x6(%ebp),%eax
801065b1:	0f 01 18             	lidtl  (%eax)
}
801065b4:	c9                   	leave  
801065b5:	c3                   	ret    

801065b6 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801065b6:	55                   	push   %ebp
801065b7:	89 e5                	mov    %esp,%ebp
801065b9:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801065bc:	0f 20 d0             	mov    %cr2,%eax
801065bf:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801065c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801065c5:	c9                   	leave  
801065c6:	c3                   	ret    

801065c7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801065c7:	55                   	push   %ebp
801065c8:	89 e5                	mov    %esp,%ebp
801065ca:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801065cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801065d4:	e9 c3 00 00 00       	jmp    8010669c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801065d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065dc:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801065e3:	89 c2                	mov    %eax,%edx
801065e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e8:	66 89 14 c5 e0 48 11 	mov    %dx,-0x7feeb720(,%eax,8)
801065ef:	80 
801065f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065f3:	66 c7 04 c5 e2 48 11 	movw   $0x8,-0x7feeb71e(,%eax,8)
801065fa:	80 08 00 
801065fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106600:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
80106607:	80 
80106608:	83 e2 e0             	and    $0xffffffe0,%edx
8010660b:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
80106612:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106615:	0f b6 14 c5 e4 48 11 	movzbl -0x7feeb71c(,%eax,8),%edx
8010661c:	80 
8010661d:	83 e2 1f             	and    $0x1f,%edx
80106620:	88 14 c5 e4 48 11 80 	mov    %dl,-0x7feeb71c(,%eax,8)
80106627:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662a:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
80106631:	80 
80106632:	83 e2 f0             	and    $0xfffffff0,%edx
80106635:	83 ca 0e             	or     $0xe,%edx
80106638:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
8010663f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106642:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
80106649:	80 
8010664a:	83 e2 ef             	and    $0xffffffef,%edx
8010664d:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
80106654:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106657:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
8010665e:	80 
8010665f:	83 e2 9f             	and    $0xffffff9f,%edx
80106662:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
80106669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666c:	0f b6 14 c5 e5 48 11 	movzbl -0x7feeb71b(,%eax,8),%edx
80106673:	80 
80106674:	83 ca 80             	or     $0xffffff80,%edx
80106677:	88 14 c5 e5 48 11 80 	mov    %dl,-0x7feeb71b(,%eax,8)
8010667e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106681:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106688:	c1 e8 10             	shr    $0x10,%eax
8010668b:	89 c2                	mov    %eax,%edx
8010668d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106690:	66 89 14 c5 e6 48 11 	mov    %dx,-0x7feeb71a(,%eax,8)
80106697:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106698:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010669c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801066a3:	0f 8e 30 ff ff ff    	jle    801065d9 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801066a9:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801066ae:	66 a3 e0 4a 11 80    	mov    %ax,0x80114ae0
801066b4:	66 c7 05 e2 4a 11 80 	movw   $0x8,0x80114ae2
801066bb:	08 00 
801066bd:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
801066c4:	83 e0 e0             	and    $0xffffffe0,%eax
801066c7:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
801066cc:	0f b6 05 e4 4a 11 80 	movzbl 0x80114ae4,%eax
801066d3:	83 e0 1f             	and    $0x1f,%eax
801066d6:	a2 e4 4a 11 80       	mov    %al,0x80114ae4
801066db:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801066e2:	83 c8 0f             	or     $0xf,%eax
801066e5:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801066ea:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
801066f1:	83 e0 ef             	and    $0xffffffef,%eax
801066f4:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
801066f9:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
80106700:	83 c8 60             	or     $0x60,%eax
80106703:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
80106708:	0f b6 05 e5 4a 11 80 	movzbl 0x80114ae5,%eax
8010670f:	83 c8 80             	or     $0xffffff80,%eax
80106712:	a2 e5 4a 11 80       	mov    %al,0x80114ae5
80106717:	a1 98 b1 10 80       	mov    0x8010b198,%eax
8010671c:	c1 e8 10             	shr    $0x10,%eax
8010671f:	66 a3 e6 4a 11 80    	mov    %ax,0x80114ae6
  
  initlock(&tickslock, "time");
80106725:	c7 44 24 04 6c 89 10 	movl   $0x8010896c,0x4(%esp)
8010672c:	80 
8010672d:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
80106734:	e8 c0 e7 ff ff       	call   80104ef9 <initlock>
}
80106739:	c9                   	leave  
8010673a:	c3                   	ret    

8010673b <idtinit>:

void
idtinit(void)
{
8010673b:	55                   	push   %ebp
8010673c:	89 e5                	mov    %esp,%ebp
8010673e:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106741:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106748:	00 
80106749:	c7 04 24 e0 48 11 80 	movl   $0x801148e0,(%esp)
80106750:	e8 38 fe ff ff       	call   8010658d <lidt>
}
80106755:	c9                   	leave  
80106756:	c3                   	ret    

80106757 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106757:	55                   	push   %ebp
80106758:	89 e5                	mov    %esp,%ebp
8010675a:	57                   	push   %edi
8010675b:	56                   	push   %esi
8010675c:	53                   	push   %ebx
8010675d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106760:	8b 45 08             	mov    0x8(%ebp),%eax
80106763:	8b 40 30             	mov    0x30(%eax),%eax
80106766:	83 f8 40             	cmp    $0x40,%eax
80106769:	75 3f                	jne    801067aa <trap+0x53>
    if(proc->killed)
8010676b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106771:	8b 40 24             	mov    0x24(%eax),%eax
80106774:	85 c0                	test   %eax,%eax
80106776:	74 05                	je     8010677d <trap+0x26>
      exit();
80106778:	e8 1d e0 ff ff       	call   8010479a <exit>
    proc->tf = tf;
8010677d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106783:	8b 55 08             	mov    0x8(%ebp),%edx
80106786:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106789:	e8 e9 ed ff ff       	call   80105577 <syscall>
    if(proc->killed)
8010678e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106794:	8b 40 24             	mov    0x24(%eax),%eax
80106797:	85 c0                	test   %eax,%eax
80106799:	74 0a                	je     801067a5 <trap+0x4e>
      exit();
8010679b:	e8 fa df ff ff       	call   8010479a <exit>
    return;
801067a0:	e9 2d 02 00 00       	jmp    801069d2 <trap+0x27b>
801067a5:	e9 28 02 00 00       	jmp    801069d2 <trap+0x27b>
  }

  switch(tf->trapno){
801067aa:	8b 45 08             	mov    0x8(%ebp),%eax
801067ad:	8b 40 30             	mov    0x30(%eax),%eax
801067b0:	83 e8 20             	sub    $0x20,%eax
801067b3:	83 f8 1f             	cmp    $0x1f,%eax
801067b6:	0f 87 bc 00 00 00    	ja     80106878 <trap+0x121>
801067bc:	8b 04 85 14 8a 10 80 	mov    -0x7fef75ec(,%eax,4),%eax
801067c3:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801067c5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801067cb:	0f b6 00             	movzbl (%eax),%eax
801067ce:	84 c0                	test   %al,%al
801067d0:	75 31                	jne    80106803 <trap+0xac>
      acquire(&tickslock);
801067d2:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801067d9:	e8 3c e7 ff ff       	call   80104f1a <acquire>
      ticks++;
801067de:	a1 e0 50 11 80       	mov    0x801150e0,%eax
801067e3:	83 c0 01             	add    $0x1,%eax
801067e6:	a3 e0 50 11 80       	mov    %eax,0x801150e0
      wakeup(&ticks);
801067eb:	c7 04 24 e0 50 11 80 	movl   $0x801150e0,(%esp)
801067f2:	e8 d6 e4 ff ff       	call   80104ccd <wakeup>
      release(&tickslock);
801067f7:	c7 04 24 a0 48 11 80 	movl   $0x801148a0,(%esp)
801067fe:	e8 79 e7 ff ff       	call   80104f7c <release>
    }
    lapiceoi();
80106803:	e8 c8 c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
80106808:	e9 41 01 00 00       	jmp    8010694e <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010680d:	e8 cc be ff ff       	call   801026de <ideintr>
    lapiceoi();
80106812:	e8 b9 c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
80106817:	e9 32 01 00 00       	jmp    8010694e <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010681c:	e8 7e c4 ff ff       	call   80102c9f <kbdintr>
    lapiceoi();
80106821:	e8 aa c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
80106826:	e9 23 01 00 00       	jmp    8010694e <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010682b:	e8 97 03 00 00       	call   80106bc7 <uartintr>
    lapiceoi();
80106830:	e8 9b c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
80106835:	e9 14 01 00 00       	jmp    8010694e <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010683a:	8b 45 08             	mov    0x8(%ebp),%eax
8010683d:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106840:	8b 45 08             	mov    0x8(%ebp),%eax
80106843:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106847:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010684a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106850:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106853:	0f b6 c0             	movzbl %al,%eax
80106856:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010685a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010685e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106862:	c7 04 24 74 89 10 80 	movl   $0x80108974,(%esp)
80106869:	e8 32 9b ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010686e:	e8 5d c6 ff ff       	call   80102ed0 <lapiceoi>
    break;
80106873:	e9 d6 00 00 00       	jmp    8010694e <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106878:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010687e:	85 c0                	test   %eax,%eax
80106880:	74 11                	je     80106893 <trap+0x13c>
80106882:	8b 45 08             	mov    0x8(%ebp),%eax
80106885:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106889:	0f b7 c0             	movzwl %ax,%eax
8010688c:	83 e0 03             	and    $0x3,%eax
8010688f:	85 c0                	test   %eax,%eax
80106891:	75 46                	jne    801068d9 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106893:	e8 1e fd ff ff       	call   801065b6 <rcr2>
80106898:	8b 55 08             	mov    0x8(%ebp),%edx
8010689b:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010689e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801068a5:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801068a8:	0f b6 ca             	movzbl %dl,%ecx
801068ab:	8b 55 08             	mov    0x8(%ebp),%edx
801068ae:	8b 52 30             	mov    0x30(%edx),%edx
801068b1:	89 44 24 10          	mov    %eax,0x10(%esp)
801068b5:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801068b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801068bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801068c1:	c7 04 24 98 89 10 80 	movl   $0x80108998,(%esp)
801068c8:	e8 d3 9a ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801068cd:	c7 04 24 ca 89 10 80 	movl   $0x801089ca,(%esp)
801068d4:	e8 61 9c ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801068d9:	e8 d8 fc ff ff       	call   801065b6 <rcr2>
801068de:	89 c2                	mov    %eax,%edx
801068e0:	8b 45 08             	mov    0x8(%ebp),%eax
801068e3:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801068e6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801068ec:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801068ef:	0f b6 f0             	movzbl %al,%esi
801068f2:	8b 45 08             	mov    0x8(%ebp),%eax
801068f5:	8b 58 34             	mov    0x34(%eax),%ebx
801068f8:	8b 45 08             	mov    0x8(%ebp),%eax
801068fb:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801068fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106904:	83 c0 6c             	add    $0x6c,%eax
80106907:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010690a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106910:	8b 40 10             	mov    0x10(%eax),%eax
80106913:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106917:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010691b:	89 74 24 14          	mov    %esi,0x14(%esp)
8010691f:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106923:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106927:	8b 75 e4             	mov    -0x1c(%ebp),%esi
8010692a:	89 74 24 08          	mov    %esi,0x8(%esp)
8010692e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106932:	c7 04 24 d0 89 10 80 	movl   $0x801089d0,(%esp)
80106939:	e8 62 9a ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010693e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106944:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010694b:	eb 01                	jmp    8010694e <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010694d:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010694e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106954:	85 c0                	test   %eax,%eax
80106956:	74 24                	je     8010697c <trap+0x225>
80106958:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010695e:	8b 40 24             	mov    0x24(%eax),%eax
80106961:	85 c0                	test   %eax,%eax
80106963:	74 17                	je     8010697c <trap+0x225>
80106965:	8b 45 08             	mov    0x8(%ebp),%eax
80106968:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010696c:	0f b7 c0             	movzwl %ax,%eax
8010696f:	83 e0 03             	and    $0x3,%eax
80106972:	83 f8 03             	cmp    $0x3,%eax
80106975:	75 05                	jne    8010697c <trap+0x225>
    exit();
80106977:	e8 1e de ff ff       	call   8010479a <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010697c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106982:	85 c0                	test   %eax,%eax
80106984:	74 1e                	je     801069a4 <trap+0x24d>
80106986:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010698c:	8b 40 0c             	mov    0xc(%eax),%eax
8010698f:	83 f8 04             	cmp    $0x4,%eax
80106992:	75 10                	jne    801069a4 <trap+0x24d>
80106994:	8b 45 08             	mov    0x8(%ebp),%eax
80106997:	8b 40 30             	mov    0x30(%eax),%eax
8010699a:	83 f8 20             	cmp    $0x20,%eax
8010699d:	75 05                	jne    801069a4 <trap+0x24d>
    yield();
8010699f:	e8 f3 e1 ff ff       	call   80104b97 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801069a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069aa:	85 c0                	test   %eax,%eax
801069ac:	74 24                	je     801069d2 <trap+0x27b>
801069ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069b4:	8b 40 24             	mov    0x24(%eax),%eax
801069b7:	85 c0                	test   %eax,%eax
801069b9:	74 17                	je     801069d2 <trap+0x27b>
801069bb:	8b 45 08             	mov    0x8(%ebp),%eax
801069be:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801069c2:	0f b7 c0             	movzwl %ax,%eax
801069c5:	83 e0 03             	and    $0x3,%eax
801069c8:	83 f8 03             	cmp    $0x3,%eax
801069cb:	75 05                	jne    801069d2 <trap+0x27b>
    exit();
801069cd:	e8 c8 dd ff ff       	call   8010479a <exit>
}
801069d2:	83 c4 3c             	add    $0x3c,%esp
801069d5:	5b                   	pop    %ebx
801069d6:	5e                   	pop    %esi
801069d7:	5f                   	pop    %edi
801069d8:	5d                   	pop    %ebp
801069d9:	c3                   	ret    

801069da <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801069da:	55                   	push   %ebp
801069db:	89 e5                	mov    %esp,%ebp
801069dd:	83 ec 14             	sub    $0x14,%esp
801069e0:	8b 45 08             	mov    0x8(%ebp),%eax
801069e3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801069e7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801069eb:	89 c2                	mov    %eax,%edx
801069ed:	ec                   	in     (%dx),%al
801069ee:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801069f1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801069f5:	c9                   	leave  
801069f6:	c3                   	ret    

801069f7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801069f7:	55                   	push   %ebp
801069f8:	89 e5                	mov    %esp,%ebp
801069fa:	83 ec 08             	sub    $0x8,%esp
801069fd:	8b 55 08             	mov    0x8(%ebp),%edx
80106a00:	8b 45 0c             	mov    0xc(%ebp),%eax
80106a03:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106a07:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106a0a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106a0e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106a12:	ee                   	out    %al,(%dx)
}
80106a13:	c9                   	leave  
80106a14:	c3                   	ret    

80106a15 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106a15:	55                   	push   %ebp
80106a16:	89 e5                	mov    %esp,%ebp
80106a18:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106a1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a22:	00 
80106a23:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106a2a:	e8 c8 ff ff ff       	call   801069f7 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106a2f:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106a36:	00 
80106a37:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106a3e:	e8 b4 ff ff ff       	call   801069f7 <outb>
  outb(COM1+0, 115200/9600);
80106a43:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106a4a:	00 
80106a4b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106a52:	e8 a0 ff ff ff       	call   801069f7 <outb>
  outb(COM1+1, 0);
80106a57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a5e:	00 
80106a5f:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106a66:	e8 8c ff ff ff       	call   801069f7 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106a6b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106a72:	00 
80106a73:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106a7a:	e8 78 ff ff ff       	call   801069f7 <outb>
  outb(COM1+4, 0);
80106a7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a86:	00 
80106a87:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106a8e:	e8 64 ff ff ff       	call   801069f7 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106a93:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106a9a:	00 
80106a9b:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106aa2:	e8 50 ff ff ff       	call   801069f7 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106aa7:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106aae:	e8 27 ff ff ff       	call   801069da <inb>
80106ab3:	3c ff                	cmp    $0xff,%al
80106ab5:	75 02                	jne    80106ab9 <uartinit+0xa4>
    return;
80106ab7:	eb 6a                	jmp    80106b23 <uartinit+0x10e>
  uart = 1;
80106ab9:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106ac0:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106ac3:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106aca:	e8 0b ff ff ff       	call   801069da <inb>
  inb(COM1+0);
80106acf:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106ad6:	e8 ff fe ff ff       	call   801069da <inb>
  picenable(IRQ_COM1);
80106adb:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106ae2:	e8 cd d2 ff ff       	call   80103db4 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106ae7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106aee:	00 
80106aef:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106af6:	e8 62 be ff ff       	call   8010295d <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106afb:	c7 45 f4 94 8a 10 80 	movl   $0x80108a94,-0xc(%ebp)
80106b02:	eb 15                	jmp    80106b19 <uartinit+0x104>
    uartputc(*p);
80106b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b07:	0f b6 00             	movzbl (%eax),%eax
80106b0a:	0f be c0             	movsbl %al,%eax
80106b0d:	89 04 24             	mov    %eax,(%esp)
80106b10:	e8 10 00 00 00       	call   80106b25 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106b15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b1c:	0f b6 00             	movzbl (%eax),%eax
80106b1f:	84 c0                	test   %al,%al
80106b21:	75 e1                	jne    80106b04 <uartinit+0xef>
    uartputc(*p);
}
80106b23:	c9                   	leave  
80106b24:	c3                   	ret    

80106b25 <uartputc>:

void
uartputc(int c)
{
80106b25:	55                   	push   %ebp
80106b26:	89 e5                	mov    %esp,%ebp
80106b28:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106b2b:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106b30:	85 c0                	test   %eax,%eax
80106b32:	75 02                	jne    80106b36 <uartputc+0x11>
    return;
80106b34:	eb 4b                	jmp    80106b81 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106b36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106b3d:	eb 10                	jmp    80106b4f <uartputc+0x2a>
    microdelay(10);
80106b3f:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106b46:	e8 aa c3 ff ff       	call   80102ef5 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106b4b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106b4f:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106b53:	7f 16                	jg     80106b6b <uartputc+0x46>
80106b55:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b5c:	e8 79 fe ff ff       	call   801069da <inb>
80106b61:	0f b6 c0             	movzbl %al,%eax
80106b64:	83 e0 20             	and    $0x20,%eax
80106b67:	85 c0                	test   %eax,%eax
80106b69:	74 d4                	je     80106b3f <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106b6b:	8b 45 08             	mov    0x8(%ebp),%eax
80106b6e:	0f b6 c0             	movzbl %al,%eax
80106b71:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b75:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b7c:	e8 76 fe ff ff       	call   801069f7 <outb>
}
80106b81:	c9                   	leave  
80106b82:	c3                   	ret    

80106b83 <uartgetc>:

static int
uartgetc(void)
{
80106b83:	55                   	push   %ebp
80106b84:	89 e5                	mov    %esp,%ebp
80106b86:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106b89:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106b8e:	85 c0                	test   %eax,%eax
80106b90:	75 07                	jne    80106b99 <uartgetc+0x16>
    return -1;
80106b92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b97:	eb 2c                	jmp    80106bc5 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106b99:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106ba0:	e8 35 fe ff ff       	call   801069da <inb>
80106ba5:	0f b6 c0             	movzbl %al,%eax
80106ba8:	83 e0 01             	and    $0x1,%eax
80106bab:	85 c0                	test   %eax,%eax
80106bad:	75 07                	jne    80106bb6 <uartgetc+0x33>
    return -1;
80106baf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bb4:	eb 0f                	jmp    80106bc5 <uartgetc+0x42>
  return inb(COM1+0);
80106bb6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106bbd:	e8 18 fe ff ff       	call   801069da <inb>
80106bc2:	0f b6 c0             	movzbl %al,%eax
}
80106bc5:	c9                   	leave  
80106bc6:	c3                   	ret    

80106bc7 <uartintr>:

void
uartintr(void)
{
80106bc7:	55                   	push   %ebp
80106bc8:	89 e5                	mov    %esp,%ebp
80106bca:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106bcd:	c7 04 24 83 6b 10 80 	movl   $0x80106b83,(%esp)
80106bd4:	e8 d4 9b ff ff       	call   801007ad <consoleintr>
}
80106bd9:	c9                   	leave  
80106bda:	c3                   	ret    

80106bdb <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $0
80106bdd:	6a 00                	push   $0x0
  jmp alltraps
80106bdf:	e9 7e f9 ff ff       	jmp    80106562 <alltraps>

80106be4 <vector1>:
.globl vector1
vector1:
  pushl $0
80106be4:	6a 00                	push   $0x0
  pushl $1
80106be6:	6a 01                	push   $0x1
  jmp alltraps
80106be8:	e9 75 f9 ff ff       	jmp    80106562 <alltraps>

80106bed <vector2>:
.globl vector2
vector2:
  pushl $0
80106bed:	6a 00                	push   $0x0
  pushl $2
80106bef:	6a 02                	push   $0x2
  jmp alltraps
80106bf1:	e9 6c f9 ff ff       	jmp    80106562 <alltraps>

80106bf6 <vector3>:
.globl vector3
vector3:
  pushl $0
80106bf6:	6a 00                	push   $0x0
  pushl $3
80106bf8:	6a 03                	push   $0x3
  jmp alltraps
80106bfa:	e9 63 f9 ff ff       	jmp    80106562 <alltraps>

80106bff <vector4>:
.globl vector4
vector4:
  pushl $0
80106bff:	6a 00                	push   $0x0
  pushl $4
80106c01:	6a 04                	push   $0x4
  jmp alltraps
80106c03:	e9 5a f9 ff ff       	jmp    80106562 <alltraps>

80106c08 <vector5>:
.globl vector5
vector5:
  pushl $0
80106c08:	6a 00                	push   $0x0
  pushl $5
80106c0a:	6a 05                	push   $0x5
  jmp alltraps
80106c0c:	e9 51 f9 ff ff       	jmp    80106562 <alltraps>

80106c11 <vector6>:
.globl vector6
vector6:
  pushl $0
80106c11:	6a 00                	push   $0x0
  pushl $6
80106c13:	6a 06                	push   $0x6
  jmp alltraps
80106c15:	e9 48 f9 ff ff       	jmp    80106562 <alltraps>

80106c1a <vector7>:
.globl vector7
vector7:
  pushl $0
80106c1a:	6a 00                	push   $0x0
  pushl $7
80106c1c:	6a 07                	push   $0x7
  jmp alltraps
80106c1e:	e9 3f f9 ff ff       	jmp    80106562 <alltraps>

80106c23 <vector8>:
.globl vector8
vector8:
  pushl $8
80106c23:	6a 08                	push   $0x8
  jmp alltraps
80106c25:	e9 38 f9 ff ff       	jmp    80106562 <alltraps>

80106c2a <vector9>:
.globl vector9
vector9:
  pushl $0
80106c2a:	6a 00                	push   $0x0
  pushl $9
80106c2c:	6a 09                	push   $0x9
  jmp alltraps
80106c2e:	e9 2f f9 ff ff       	jmp    80106562 <alltraps>

80106c33 <vector10>:
.globl vector10
vector10:
  pushl $10
80106c33:	6a 0a                	push   $0xa
  jmp alltraps
80106c35:	e9 28 f9 ff ff       	jmp    80106562 <alltraps>

80106c3a <vector11>:
.globl vector11
vector11:
  pushl $11
80106c3a:	6a 0b                	push   $0xb
  jmp alltraps
80106c3c:	e9 21 f9 ff ff       	jmp    80106562 <alltraps>

80106c41 <vector12>:
.globl vector12
vector12:
  pushl $12
80106c41:	6a 0c                	push   $0xc
  jmp alltraps
80106c43:	e9 1a f9 ff ff       	jmp    80106562 <alltraps>

80106c48 <vector13>:
.globl vector13
vector13:
  pushl $13
80106c48:	6a 0d                	push   $0xd
  jmp alltraps
80106c4a:	e9 13 f9 ff ff       	jmp    80106562 <alltraps>

80106c4f <vector14>:
.globl vector14
vector14:
  pushl $14
80106c4f:	6a 0e                	push   $0xe
  jmp alltraps
80106c51:	e9 0c f9 ff ff       	jmp    80106562 <alltraps>

80106c56 <vector15>:
.globl vector15
vector15:
  pushl $0
80106c56:	6a 00                	push   $0x0
  pushl $15
80106c58:	6a 0f                	push   $0xf
  jmp alltraps
80106c5a:	e9 03 f9 ff ff       	jmp    80106562 <alltraps>

80106c5f <vector16>:
.globl vector16
vector16:
  pushl $0
80106c5f:	6a 00                	push   $0x0
  pushl $16
80106c61:	6a 10                	push   $0x10
  jmp alltraps
80106c63:	e9 fa f8 ff ff       	jmp    80106562 <alltraps>

80106c68 <vector17>:
.globl vector17
vector17:
  pushl $17
80106c68:	6a 11                	push   $0x11
  jmp alltraps
80106c6a:	e9 f3 f8 ff ff       	jmp    80106562 <alltraps>

80106c6f <vector18>:
.globl vector18
vector18:
  pushl $0
80106c6f:	6a 00                	push   $0x0
  pushl $18
80106c71:	6a 12                	push   $0x12
  jmp alltraps
80106c73:	e9 ea f8 ff ff       	jmp    80106562 <alltraps>

80106c78 <vector19>:
.globl vector19
vector19:
  pushl $0
80106c78:	6a 00                	push   $0x0
  pushl $19
80106c7a:	6a 13                	push   $0x13
  jmp alltraps
80106c7c:	e9 e1 f8 ff ff       	jmp    80106562 <alltraps>

80106c81 <vector20>:
.globl vector20
vector20:
  pushl $0
80106c81:	6a 00                	push   $0x0
  pushl $20
80106c83:	6a 14                	push   $0x14
  jmp alltraps
80106c85:	e9 d8 f8 ff ff       	jmp    80106562 <alltraps>

80106c8a <vector21>:
.globl vector21
vector21:
  pushl $0
80106c8a:	6a 00                	push   $0x0
  pushl $21
80106c8c:	6a 15                	push   $0x15
  jmp alltraps
80106c8e:	e9 cf f8 ff ff       	jmp    80106562 <alltraps>

80106c93 <vector22>:
.globl vector22
vector22:
  pushl $0
80106c93:	6a 00                	push   $0x0
  pushl $22
80106c95:	6a 16                	push   $0x16
  jmp alltraps
80106c97:	e9 c6 f8 ff ff       	jmp    80106562 <alltraps>

80106c9c <vector23>:
.globl vector23
vector23:
  pushl $0
80106c9c:	6a 00                	push   $0x0
  pushl $23
80106c9e:	6a 17                	push   $0x17
  jmp alltraps
80106ca0:	e9 bd f8 ff ff       	jmp    80106562 <alltraps>

80106ca5 <vector24>:
.globl vector24
vector24:
  pushl $0
80106ca5:	6a 00                	push   $0x0
  pushl $24
80106ca7:	6a 18                	push   $0x18
  jmp alltraps
80106ca9:	e9 b4 f8 ff ff       	jmp    80106562 <alltraps>

80106cae <vector25>:
.globl vector25
vector25:
  pushl $0
80106cae:	6a 00                	push   $0x0
  pushl $25
80106cb0:	6a 19                	push   $0x19
  jmp alltraps
80106cb2:	e9 ab f8 ff ff       	jmp    80106562 <alltraps>

80106cb7 <vector26>:
.globl vector26
vector26:
  pushl $0
80106cb7:	6a 00                	push   $0x0
  pushl $26
80106cb9:	6a 1a                	push   $0x1a
  jmp alltraps
80106cbb:	e9 a2 f8 ff ff       	jmp    80106562 <alltraps>

80106cc0 <vector27>:
.globl vector27
vector27:
  pushl $0
80106cc0:	6a 00                	push   $0x0
  pushl $27
80106cc2:	6a 1b                	push   $0x1b
  jmp alltraps
80106cc4:	e9 99 f8 ff ff       	jmp    80106562 <alltraps>

80106cc9 <vector28>:
.globl vector28
vector28:
  pushl $0
80106cc9:	6a 00                	push   $0x0
  pushl $28
80106ccb:	6a 1c                	push   $0x1c
  jmp alltraps
80106ccd:	e9 90 f8 ff ff       	jmp    80106562 <alltraps>

80106cd2 <vector29>:
.globl vector29
vector29:
  pushl $0
80106cd2:	6a 00                	push   $0x0
  pushl $29
80106cd4:	6a 1d                	push   $0x1d
  jmp alltraps
80106cd6:	e9 87 f8 ff ff       	jmp    80106562 <alltraps>

80106cdb <vector30>:
.globl vector30
vector30:
  pushl $0
80106cdb:	6a 00                	push   $0x0
  pushl $30
80106cdd:	6a 1e                	push   $0x1e
  jmp alltraps
80106cdf:	e9 7e f8 ff ff       	jmp    80106562 <alltraps>

80106ce4 <vector31>:
.globl vector31
vector31:
  pushl $0
80106ce4:	6a 00                	push   $0x0
  pushl $31
80106ce6:	6a 1f                	push   $0x1f
  jmp alltraps
80106ce8:	e9 75 f8 ff ff       	jmp    80106562 <alltraps>

80106ced <vector32>:
.globl vector32
vector32:
  pushl $0
80106ced:	6a 00                	push   $0x0
  pushl $32
80106cef:	6a 20                	push   $0x20
  jmp alltraps
80106cf1:	e9 6c f8 ff ff       	jmp    80106562 <alltraps>

80106cf6 <vector33>:
.globl vector33
vector33:
  pushl $0
80106cf6:	6a 00                	push   $0x0
  pushl $33
80106cf8:	6a 21                	push   $0x21
  jmp alltraps
80106cfa:	e9 63 f8 ff ff       	jmp    80106562 <alltraps>

80106cff <vector34>:
.globl vector34
vector34:
  pushl $0
80106cff:	6a 00                	push   $0x0
  pushl $34
80106d01:	6a 22                	push   $0x22
  jmp alltraps
80106d03:	e9 5a f8 ff ff       	jmp    80106562 <alltraps>

80106d08 <vector35>:
.globl vector35
vector35:
  pushl $0
80106d08:	6a 00                	push   $0x0
  pushl $35
80106d0a:	6a 23                	push   $0x23
  jmp alltraps
80106d0c:	e9 51 f8 ff ff       	jmp    80106562 <alltraps>

80106d11 <vector36>:
.globl vector36
vector36:
  pushl $0
80106d11:	6a 00                	push   $0x0
  pushl $36
80106d13:	6a 24                	push   $0x24
  jmp alltraps
80106d15:	e9 48 f8 ff ff       	jmp    80106562 <alltraps>

80106d1a <vector37>:
.globl vector37
vector37:
  pushl $0
80106d1a:	6a 00                	push   $0x0
  pushl $37
80106d1c:	6a 25                	push   $0x25
  jmp alltraps
80106d1e:	e9 3f f8 ff ff       	jmp    80106562 <alltraps>

80106d23 <vector38>:
.globl vector38
vector38:
  pushl $0
80106d23:	6a 00                	push   $0x0
  pushl $38
80106d25:	6a 26                	push   $0x26
  jmp alltraps
80106d27:	e9 36 f8 ff ff       	jmp    80106562 <alltraps>

80106d2c <vector39>:
.globl vector39
vector39:
  pushl $0
80106d2c:	6a 00                	push   $0x0
  pushl $39
80106d2e:	6a 27                	push   $0x27
  jmp alltraps
80106d30:	e9 2d f8 ff ff       	jmp    80106562 <alltraps>

80106d35 <vector40>:
.globl vector40
vector40:
  pushl $0
80106d35:	6a 00                	push   $0x0
  pushl $40
80106d37:	6a 28                	push   $0x28
  jmp alltraps
80106d39:	e9 24 f8 ff ff       	jmp    80106562 <alltraps>

80106d3e <vector41>:
.globl vector41
vector41:
  pushl $0
80106d3e:	6a 00                	push   $0x0
  pushl $41
80106d40:	6a 29                	push   $0x29
  jmp alltraps
80106d42:	e9 1b f8 ff ff       	jmp    80106562 <alltraps>

80106d47 <vector42>:
.globl vector42
vector42:
  pushl $0
80106d47:	6a 00                	push   $0x0
  pushl $42
80106d49:	6a 2a                	push   $0x2a
  jmp alltraps
80106d4b:	e9 12 f8 ff ff       	jmp    80106562 <alltraps>

80106d50 <vector43>:
.globl vector43
vector43:
  pushl $0
80106d50:	6a 00                	push   $0x0
  pushl $43
80106d52:	6a 2b                	push   $0x2b
  jmp alltraps
80106d54:	e9 09 f8 ff ff       	jmp    80106562 <alltraps>

80106d59 <vector44>:
.globl vector44
vector44:
  pushl $0
80106d59:	6a 00                	push   $0x0
  pushl $44
80106d5b:	6a 2c                	push   $0x2c
  jmp alltraps
80106d5d:	e9 00 f8 ff ff       	jmp    80106562 <alltraps>

80106d62 <vector45>:
.globl vector45
vector45:
  pushl $0
80106d62:	6a 00                	push   $0x0
  pushl $45
80106d64:	6a 2d                	push   $0x2d
  jmp alltraps
80106d66:	e9 f7 f7 ff ff       	jmp    80106562 <alltraps>

80106d6b <vector46>:
.globl vector46
vector46:
  pushl $0
80106d6b:	6a 00                	push   $0x0
  pushl $46
80106d6d:	6a 2e                	push   $0x2e
  jmp alltraps
80106d6f:	e9 ee f7 ff ff       	jmp    80106562 <alltraps>

80106d74 <vector47>:
.globl vector47
vector47:
  pushl $0
80106d74:	6a 00                	push   $0x0
  pushl $47
80106d76:	6a 2f                	push   $0x2f
  jmp alltraps
80106d78:	e9 e5 f7 ff ff       	jmp    80106562 <alltraps>

80106d7d <vector48>:
.globl vector48
vector48:
  pushl $0
80106d7d:	6a 00                	push   $0x0
  pushl $48
80106d7f:	6a 30                	push   $0x30
  jmp alltraps
80106d81:	e9 dc f7 ff ff       	jmp    80106562 <alltraps>

80106d86 <vector49>:
.globl vector49
vector49:
  pushl $0
80106d86:	6a 00                	push   $0x0
  pushl $49
80106d88:	6a 31                	push   $0x31
  jmp alltraps
80106d8a:	e9 d3 f7 ff ff       	jmp    80106562 <alltraps>

80106d8f <vector50>:
.globl vector50
vector50:
  pushl $0
80106d8f:	6a 00                	push   $0x0
  pushl $50
80106d91:	6a 32                	push   $0x32
  jmp alltraps
80106d93:	e9 ca f7 ff ff       	jmp    80106562 <alltraps>

80106d98 <vector51>:
.globl vector51
vector51:
  pushl $0
80106d98:	6a 00                	push   $0x0
  pushl $51
80106d9a:	6a 33                	push   $0x33
  jmp alltraps
80106d9c:	e9 c1 f7 ff ff       	jmp    80106562 <alltraps>

80106da1 <vector52>:
.globl vector52
vector52:
  pushl $0
80106da1:	6a 00                	push   $0x0
  pushl $52
80106da3:	6a 34                	push   $0x34
  jmp alltraps
80106da5:	e9 b8 f7 ff ff       	jmp    80106562 <alltraps>

80106daa <vector53>:
.globl vector53
vector53:
  pushl $0
80106daa:	6a 00                	push   $0x0
  pushl $53
80106dac:	6a 35                	push   $0x35
  jmp alltraps
80106dae:	e9 af f7 ff ff       	jmp    80106562 <alltraps>

80106db3 <vector54>:
.globl vector54
vector54:
  pushl $0
80106db3:	6a 00                	push   $0x0
  pushl $54
80106db5:	6a 36                	push   $0x36
  jmp alltraps
80106db7:	e9 a6 f7 ff ff       	jmp    80106562 <alltraps>

80106dbc <vector55>:
.globl vector55
vector55:
  pushl $0
80106dbc:	6a 00                	push   $0x0
  pushl $55
80106dbe:	6a 37                	push   $0x37
  jmp alltraps
80106dc0:	e9 9d f7 ff ff       	jmp    80106562 <alltraps>

80106dc5 <vector56>:
.globl vector56
vector56:
  pushl $0
80106dc5:	6a 00                	push   $0x0
  pushl $56
80106dc7:	6a 38                	push   $0x38
  jmp alltraps
80106dc9:	e9 94 f7 ff ff       	jmp    80106562 <alltraps>

80106dce <vector57>:
.globl vector57
vector57:
  pushl $0
80106dce:	6a 00                	push   $0x0
  pushl $57
80106dd0:	6a 39                	push   $0x39
  jmp alltraps
80106dd2:	e9 8b f7 ff ff       	jmp    80106562 <alltraps>

80106dd7 <vector58>:
.globl vector58
vector58:
  pushl $0
80106dd7:	6a 00                	push   $0x0
  pushl $58
80106dd9:	6a 3a                	push   $0x3a
  jmp alltraps
80106ddb:	e9 82 f7 ff ff       	jmp    80106562 <alltraps>

80106de0 <vector59>:
.globl vector59
vector59:
  pushl $0
80106de0:	6a 00                	push   $0x0
  pushl $59
80106de2:	6a 3b                	push   $0x3b
  jmp alltraps
80106de4:	e9 79 f7 ff ff       	jmp    80106562 <alltraps>

80106de9 <vector60>:
.globl vector60
vector60:
  pushl $0
80106de9:	6a 00                	push   $0x0
  pushl $60
80106deb:	6a 3c                	push   $0x3c
  jmp alltraps
80106ded:	e9 70 f7 ff ff       	jmp    80106562 <alltraps>

80106df2 <vector61>:
.globl vector61
vector61:
  pushl $0
80106df2:	6a 00                	push   $0x0
  pushl $61
80106df4:	6a 3d                	push   $0x3d
  jmp alltraps
80106df6:	e9 67 f7 ff ff       	jmp    80106562 <alltraps>

80106dfb <vector62>:
.globl vector62
vector62:
  pushl $0
80106dfb:	6a 00                	push   $0x0
  pushl $62
80106dfd:	6a 3e                	push   $0x3e
  jmp alltraps
80106dff:	e9 5e f7 ff ff       	jmp    80106562 <alltraps>

80106e04 <vector63>:
.globl vector63
vector63:
  pushl $0
80106e04:	6a 00                	push   $0x0
  pushl $63
80106e06:	6a 3f                	push   $0x3f
  jmp alltraps
80106e08:	e9 55 f7 ff ff       	jmp    80106562 <alltraps>

80106e0d <vector64>:
.globl vector64
vector64:
  pushl $0
80106e0d:	6a 00                	push   $0x0
  pushl $64
80106e0f:	6a 40                	push   $0x40
  jmp alltraps
80106e11:	e9 4c f7 ff ff       	jmp    80106562 <alltraps>

80106e16 <vector65>:
.globl vector65
vector65:
  pushl $0
80106e16:	6a 00                	push   $0x0
  pushl $65
80106e18:	6a 41                	push   $0x41
  jmp alltraps
80106e1a:	e9 43 f7 ff ff       	jmp    80106562 <alltraps>

80106e1f <vector66>:
.globl vector66
vector66:
  pushl $0
80106e1f:	6a 00                	push   $0x0
  pushl $66
80106e21:	6a 42                	push   $0x42
  jmp alltraps
80106e23:	e9 3a f7 ff ff       	jmp    80106562 <alltraps>

80106e28 <vector67>:
.globl vector67
vector67:
  pushl $0
80106e28:	6a 00                	push   $0x0
  pushl $67
80106e2a:	6a 43                	push   $0x43
  jmp alltraps
80106e2c:	e9 31 f7 ff ff       	jmp    80106562 <alltraps>

80106e31 <vector68>:
.globl vector68
vector68:
  pushl $0
80106e31:	6a 00                	push   $0x0
  pushl $68
80106e33:	6a 44                	push   $0x44
  jmp alltraps
80106e35:	e9 28 f7 ff ff       	jmp    80106562 <alltraps>

80106e3a <vector69>:
.globl vector69
vector69:
  pushl $0
80106e3a:	6a 00                	push   $0x0
  pushl $69
80106e3c:	6a 45                	push   $0x45
  jmp alltraps
80106e3e:	e9 1f f7 ff ff       	jmp    80106562 <alltraps>

80106e43 <vector70>:
.globl vector70
vector70:
  pushl $0
80106e43:	6a 00                	push   $0x0
  pushl $70
80106e45:	6a 46                	push   $0x46
  jmp alltraps
80106e47:	e9 16 f7 ff ff       	jmp    80106562 <alltraps>

80106e4c <vector71>:
.globl vector71
vector71:
  pushl $0
80106e4c:	6a 00                	push   $0x0
  pushl $71
80106e4e:	6a 47                	push   $0x47
  jmp alltraps
80106e50:	e9 0d f7 ff ff       	jmp    80106562 <alltraps>

80106e55 <vector72>:
.globl vector72
vector72:
  pushl $0
80106e55:	6a 00                	push   $0x0
  pushl $72
80106e57:	6a 48                	push   $0x48
  jmp alltraps
80106e59:	e9 04 f7 ff ff       	jmp    80106562 <alltraps>

80106e5e <vector73>:
.globl vector73
vector73:
  pushl $0
80106e5e:	6a 00                	push   $0x0
  pushl $73
80106e60:	6a 49                	push   $0x49
  jmp alltraps
80106e62:	e9 fb f6 ff ff       	jmp    80106562 <alltraps>

80106e67 <vector74>:
.globl vector74
vector74:
  pushl $0
80106e67:	6a 00                	push   $0x0
  pushl $74
80106e69:	6a 4a                	push   $0x4a
  jmp alltraps
80106e6b:	e9 f2 f6 ff ff       	jmp    80106562 <alltraps>

80106e70 <vector75>:
.globl vector75
vector75:
  pushl $0
80106e70:	6a 00                	push   $0x0
  pushl $75
80106e72:	6a 4b                	push   $0x4b
  jmp alltraps
80106e74:	e9 e9 f6 ff ff       	jmp    80106562 <alltraps>

80106e79 <vector76>:
.globl vector76
vector76:
  pushl $0
80106e79:	6a 00                	push   $0x0
  pushl $76
80106e7b:	6a 4c                	push   $0x4c
  jmp alltraps
80106e7d:	e9 e0 f6 ff ff       	jmp    80106562 <alltraps>

80106e82 <vector77>:
.globl vector77
vector77:
  pushl $0
80106e82:	6a 00                	push   $0x0
  pushl $77
80106e84:	6a 4d                	push   $0x4d
  jmp alltraps
80106e86:	e9 d7 f6 ff ff       	jmp    80106562 <alltraps>

80106e8b <vector78>:
.globl vector78
vector78:
  pushl $0
80106e8b:	6a 00                	push   $0x0
  pushl $78
80106e8d:	6a 4e                	push   $0x4e
  jmp alltraps
80106e8f:	e9 ce f6 ff ff       	jmp    80106562 <alltraps>

80106e94 <vector79>:
.globl vector79
vector79:
  pushl $0
80106e94:	6a 00                	push   $0x0
  pushl $79
80106e96:	6a 4f                	push   $0x4f
  jmp alltraps
80106e98:	e9 c5 f6 ff ff       	jmp    80106562 <alltraps>

80106e9d <vector80>:
.globl vector80
vector80:
  pushl $0
80106e9d:	6a 00                	push   $0x0
  pushl $80
80106e9f:	6a 50                	push   $0x50
  jmp alltraps
80106ea1:	e9 bc f6 ff ff       	jmp    80106562 <alltraps>

80106ea6 <vector81>:
.globl vector81
vector81:
  pushl $0
80106ea6:	6a 00                	push   $0x0
  pushl $81
80106ea8:	6a 51                	push   $0x51
  jmp alltraps
80106eaa:	e9 b3 f6 ff ff       	jmp    80106562 <alltraps>

80106eaf <vector82>:
.globl vector82
vector82:
  pushl $0
80106eaf:	6a 00                	push   $0x0
  pushl $82
80106eb1:	6a 52                	push   $0x52
  jmp alltraps
80106eb3:	e9 aa f6 ff ff       	jmp    80106562 <alltraps>

80106eb8 <vector83>:
.globl vector83
vector83:
  pushl $0
80106eb8:	6a 00                	push   $0x0
  pushl $83
80106eba:	6a 53                	push   $0x53
  jmp alltraps
80106ebc:	e9 a1 f6 ff ff       	jmp    80106562 <alltraps>

80106ec1 <vector84>:
.globl vector84
vector84:
  pushl $0
80106ec1:	6a 00                	push   $0x0
  pushl $84
80106ec3:	6a 54                	push   $0x54
  jmp alltraps
80106ec5:	e9 98 f6 ff ff       	jmp    80106562 <alltraps>

80106eca <vector85>:
.globl vector85
vector85:
  pushl $0
80106eca:	6a 00                	push   $0x0
  pushl $85
80106ecc:	6a 55                	push   $0x55
  jmp alltraps
80106ece:	e9 8f f6 ff ff       	jmp    80106562 <alltraps>

80106ed3 <vector86>:
.globl vector86
vector86:
  pushl $0
80106ed3:	6a 00                	push   $0x0
  pushl $86
80106ed5:	6a 56                	push   $0x56
  jmp alltraps
80106ed7:	e9 86 f6 ff ff       	jmp    80106562 <alltraps>

80106edc <vector87>:
.globl vector87
vector87:
  pushl $0
80106edc:	6a 00                	push   $0x0
  pushl $87
80106ede:	6a 57                	push   $0x57
  jmp alltraps
80106ee0:	e9 7d f6 ff ff       	jmp    80106562 <alltraps>

80106ee5 <vector88>:
.globl vector88
vector88:
  pushl $0
80106ee5:	6a 00                	push   $0x0
  pushl $88
80106ee7:	6a 58                	push   $0x58
  jmp alltraps
80106ee9:	e9 74 f6 ff ff       	jmp    80106562 <alltraps>

80106eee <vector89>:
.globl vector89
vector89:
  pushl $0
80106eee:	6a 00                	push   $0x0
  pushl $89
80106ef0:	6a 59                	push   $0x59
  jmp alltraps
80106ef2:	e9 6b f6 ff ff       	jmp    80106562 <alltraps>

80106ef7 <vector90>:
.globl vector90
vector90:
  pushl $0
80106ef7:	6a 00                	push   $0x0
  pushl $90
80106ef9:	6a 5a                	push   $0x5a
  jmp alltraps
80106efb:	e9 62 f6 ff ff       	jmp    80106562 <alltraps>

80106f00 <vector91>:
.globl vector91
vector91:
  pushl $0
80106f00:	6a 00                	push   $0x0
  pushl $91
80106f02:	6a 5b                	push   $0x5b
  jmp alltraps
80106f04:	e9 59 f6 ff ff       	jmp    80106562 <alltraps>

80106f09 <vector92>:
.globl vector92
vector92:
  pushl $0
80106f09:	6a 00                	push   $0x0
  pushl $92
80106f0b:	6a 5c                	push   $0x5c
  jmp alltraps
80106f0d:	e9 50 f6 ff ff       	jmp    80106562 <alltraps>

80106f12 <vector93>:
.globl vector93
vector93:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $93
80106f14:	6a 5d                	push   $0x5d
  jmp alltraps
80106f16:	e9 47 f6 ff ff       	jmp    80106562 <alltraps>

80106f1b <vector94>:
.globl vector94
vector94:
  pushl $0
80106f1b:	6a 00                	push   $0x0
  pushl $94
80106f1d:	6a 5e                	push   $0x5e
  jmp alltraps
80106f1f:	e9 3e f6 ff ff       	jmp    80106562 <alltraps>

80106f24 <vector95>:
.globl vector95
vector95:
  pushl $0
80106f24:	6a 00                	push   $0x0
  pushl $95
80106f26:	6a 5f                	push   $0x5f
  jmp alltraps
80106f28:	e9 35 f6 ff ff       	jmp    80106562 <alltraps>

80106f2d <vector96>:
.globl vector96
vector96:
  pushl $0
80106f2d:	6a 00                	push   $0x0
  pushl $96
80106f2f:	6a 60                	push   $0x60
  jmp alltraps
80106f31:	e9 2c f6 ff ff       	jmp    80106562 <alltraps>

80106f36 <vector97>:
.globl vector97
vector97:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $97
80106f38:	6a 61                	push   $0x61
  jmp alltraps
80106f3a:	e9 23 f6 ff ff       	jmp    80106562 <alltraps>

80106f3f <vector98>:
.globl vector98
vector98:
  pushl $0
80106f3f:	6a 00                	push   $0x0
  pushl $98
80106f41:	6a 62                	push   $0x62
  jmp alltraps
80106f43:	e9 1a f6 ff ff       	jmp    80106562 <alltraps>

80106f48 <vector99>:
.globl vector99
vector99:
  pushl $0
80106f48:	6a 00                	push   $0x0
  pushl $99
80106f4a:	6a 63                	push   $0x63
  jmp alltraps
80106f4c:	e9 11 f6 ff ff       	jmp    80106562 <alltraps>

80106f51 <vector100>:
.globl vector100
vector100:
  pushl $0
80106f51:	6a 00                	push   $0x0
  pushl $100
80106f53:	6a 64                	push   $0x64
  jmp alltraps
80106f55:	e9 08 f6 ff ff       	jmp    80106562 <alltraps>

80106f5a <vector101>:
.globl vector101
vector101:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $101
80106f5c:	6a 65                	push   $0x65
  jmp alltraps
80106f5e:	e9 ff f5 ff ff       	jmp    80106562 <alltraps>

80106f63 <vector102>:
.globl vector102
vector102:
  pushl $0
80106f63:	6a 00                	push   $0x0
  pushl $102
80106f65:	6a 66                	push   $0x66
  jmp alltraps
80106f67:	e9 f6 f5 ff ff       	jmp    80106562 <alltraps>

80106f6c <vector103>:
.globl vector103
vector103:
  pushl $0
80106f6c:	6a 00                	push   $0x0
  pushl $103
80106f6e:	6a 67                	push   $0x67
  jmp alltraps
80106f70:	e9 ed f5 ff ff       	jmp    80106562 <alltraps>

80106f75 <vector104>:
.globl vector104
vector104:
  pushl $0
80106f75:	6a 00                	push   $0x0
  pushl $104
80106f77:	6a 68                	push   $0x68
  jmp alltraps
80106f79:	e9 e4 f5 ff ff       	jmp    80106562 <alltraps>

80106f7e <vector105>:
.globl vector105
vector105:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $105
80106f80:	6a 69                	push   $0x69
  jmp alltraps
80106f82:	e9 db f5 ff ff       	jmp    80106562 <alltraps>

80106f87 <vector106>:
.globl vector106
vector106:
  pushl $0
80106f87:	6a 00                	push   $0x0
  pushl $106
80106f89:	6a 6a                	push   $0x6a
  jmp alltraps
80106f8b:	e9 d2 f5 ff ff       	jmp    80106562 <alltraps>

80106f90 <vector107>:
.globl vector107
vector107:
  pushl $0
80106f90:	6a 00                	push   $0x0
  pushl $107
80106f92:	6a 6b                	push   $0x6b
  jmp alltraps
80106f94:	e9 c9 f5 ff ff       	jmp    80106562 <alltraps>

80106f99 <vector108>:
.globl vector108
vector108:
  pushl $0
80106f99:	6a 00                	push   $0x0
  pushl $108
80106f9b:	6a 6c                	push   $0x6c
  jmp alltraps
80106f9d:	e9 c0 f5 ff ff       	jmp    80106562 <alltraps>

80106fa2 <vector109>:
.globl vector109
vector109:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $109
80106fa4:	6a 6d                	push   $0x6d
  jmp alltraps
80106fa6:	e9 b7 f5 ff ff       	jmp    80106562 <alltraps>

80106fab <vector110>:
.globl vector110
vector110:
  pushl $0
80106fab:	6a 00                	push   $0x0
  pushl $110
80106fad:	6a 6e                	push   $0x6e
  jmp alltraps
80106faf:	e9 ae f5 ff ff       	jmp    80106562 <alltraps>

80106fb4 <vector111>:
.globl vector111
vector111:
  pushl $0
80106fb4:	6a 00                	push   $0x0
  pushl $111
80106fb6:	6a 6f                	push   $0x6f
  jmp alltraps
80106fb8:	e9 a5 f5 ff ff       	jmp    80106562 <alltraps>

80106fbd <vector112>:
.globl vector112
vector112:
  pushl $0
80106fbd:	6a 00                	push   $0x0
  pushl $112
80106fbf:	6a 70                	push   $0x70
  jmp alltraps
80106fc1:	e9 9c f5 ff ff       	jmp    80106562 <alltraps>

80106fc6 <vector113>:
.globl vector113
vector113:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $113
80106fc8:	6a 71                	push   $0x71
  jmp alltraps
80106fca:	e9 93 f5 ff ff       	jmp    80106562 <alltraps>

80106fcf <vector114>:
.globl vector114
vector114:
  pushl $0
80106fcf:	6a 00                	push   $0x0
  pushl $114
80106fd1:	6a 72                	push   $0x72
  jmp alltraps
80106fd3:	e9 8a f5 ff ff       	jmp    80106562 <alltraps>

80106fd8 <vector115>:
.globl vector115
vector115:
  pushl $0
80106fd8:	6a 00                	push   $0x0
  pushl $115
80106fda:	6a 73                	push   $0x73
  jmp alltraps
80106fdc:	e9 81 f5 ff ff       	jmp    80106562 <alltraps>

80106fe1 <vector116>:
.globl vector116
vector116:
  pushl $0
80106fe1:	6a 00                	push   $0x0
  pushl $116
80106fe3:	6a 74                	push   $0x74
  jmp alltraps
80106fe5:	e9 78 f5 ff ff       	jmp    80106562 <alltraps>

80106fea <vector117>:
.globl vector117
vector117:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $117
80106fec:	6a 75                	push   $0x75
  jmp alltraps
80106fee:	e9 6f f5 ff ff       	jmp    80106562 <alltraps>

80106ff3 <vector118>:
.globl vector118
vector118:
  pushl $0
80106ff3:	6a 00                	push   $0x0
  pushl $118
80106ff5:	6a 76                	push   $0x76
  jmp alltraps
80106ff7:	e9 66 f5 ff ff       	jmp    80106562 <alltraps>

80106ffc <vector119>:
.globl vector119
vector119:
  pushl $0
80106ffc:	6a 00                	push   $0x0
  pushl $119
80106ffe:	6a 77                	push   $0x77
  jmp alltraps
80107000:	e9 5d f5 ff ff       	jmp    80106562 <alltraps>

80107005 <vector120>:
.globl vector120
vector120:
  pushl $0
80107005:	6a 00                	push   $0x0
  pushl $120
80107007:	6a 78                	push   $0x78
  jmp alltraps
80107009:	e9 54 f5 ff ff       	jmp    80106562 <alltraps>

8010700e <vector121>:
.globl vector121
vector121:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $121
80107010:	6a 79                	push   $0x79
  jmp alltraps
80107012:	e9 4b f5 ff ff       	jmp    80106562 <alltraps>

80107017 <vector122>:
.globl vector122
vector122:
  pushl $0
80107017:	6a 00                	push   $0x0
  pushl $122
80107019:	6a 7a                	push   $0x7a
  jmp alltraps
8010701b:	e9 42 f5 ff ff       	jmp    80106562 <alltraps>

80107020 <vector123>:
.globl vector123
vector123:
  pushl $0
80107020:	6a 00                	push   $0x0
  pushl $123
80107022:	6a 7b                	push   $0x7b
  jmp alltraps
80107024:	e9 39 f5 ff ff       	jmp    80106562 <alltraps>

80107029 <vector124>:
.globl vector124
vector124:
  pushl $0
80107029:	6a 00                	push   $0x0
  pushl $124
8010702b:	6a 7c                	push   $0x7c
  jmp alltraps
8010702d:	e9 30 f5 ff ff       	jmp    80106562 <alltraps>

80107032 <vector125>:
.globl vector125
vector125:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $125
80107034:	6a 7d                	push   $0x7d
  jmp alltraps
80107036:	e9 27 f5 ff ff       	jmp    80106562 <alltraps>

8010703b <vector126>:
.globl vector126
vector126:
  pushl $0
8010703b:	6a 00                	push   $0x0
  pushl $126
8010703d:	6a 7e                	push   $0x7e
  jmp alltraps
8010703f:	e9 1e f5 ff ff       	jmp    80106562 <alltraps>

80107044 <vector127>:
.globl vector127
vector127:
  pushl $0
80107044:	6a 00                	push   $0x0
  pushl $127
80107046:	6a 7f                	push   $0x7f
  jmp alltraps
80107048:	e9 15 f5 ff ff       	jmp    80106562 <alltraps>

8010704d <vector128>:
.globl vector128
vector128:
  pushl $0
8010704d:	6a 00                	push   $0x0
  pushl $128
8010704f:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107054:	e9 09 f5 ff ff       	jmp    80106562 <alltraps>

80107059 <vector129>:
.globl vector129
vector129:
  pushl $0
80107059:	6a 00                	push   $0x0
  pushl $129
8010705b:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107060:	e9 fd f4 ff ff       	jmp    80106562 <alltraps>

80107065 <vector130>:
.globl vector130
vector130:
  pushl $0
80107065:	6a 00                	push   $0x0
  pushl $130
80107067:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010706c:	e9 f1 f4 ff ff       	jmp    80106562 <alltraps>

80107071 <vector131>:
.globl vector131
vector131:
  pushl $0
80107071:	6a 00                	push   $0x0
  pushl $131
80107073:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107078:	e9 e5 f4 ff ff       	jmp    80106562 <alltraps>

8010707d <vector132>:
.globl vector132
vector132:
  pushl $0
8010707d:	6a 00                	push   $0x0
  pushl $132
8010707f:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107084:	e9 d9 f4 ff ff       	jmp    80106562 <alltraps>

80107089 <vector133>:
.globl vector133
vector133:
  pushl $0
80107089:	6a 00                	push   $0x0
  pushl $133
8010708b:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107090:	e9 cd f4 ff ff       	jmp    80106562 <alltraps>

80107095 <vector134>:
.globl vector134
vector134:
  pushl $0
80107095:	6a 00                	push   $0x0
  pushl $134
80107097:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010709c:	e9 c1 f4 ff ff       	jmp    80106562 <alltraps>

801070a1 <vector135>:
.globl vector135
vector135:
  pushl $0
801070a1:	6a 00                	push   $0x0
  pushl $135
801070a3:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801070a8:	e9 b5 f4 ff ff       	jmp    80106562 <alltraps>

801070ad <vector136>:
.globl vector136
vector136:
  pushl $0
801070ad:	6a 00                	push   $0x0
  pushl $136
801070af:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801070b4:	e9 a9 f4 ff ff       	jmp    80106562 <alltraps>

801070b9 <vector137>:
.globl vector137
vector137:
  pushl $0
801070b9:	6a 00                	push   $0x0
  pushl $137
801070bb:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801070c0:	e9 9d f4 ff ff       	jmp    80106562 <alltraps>

801070c5 <vector138>:
.globl vector138
vector138:
  pushl $0
801070c5:	6a 00                	push   $0x0
  pushl $138
801070c7:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801070cc:	e9 91 f4 ff ff       	jmp    80106562 <alltraps>

801070d1 <vector139>:
.globl vector139
vector139:
  pushl $0
801070d1:	6a 00                	push   $0x0
  pushl $139
801070d3:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801070d8:	e9 85 f4 ff ff       	jmp    80106562 <alltraps>

801070dd <vector140>:
.globl vector140
vector140:
  pushl $0
801070dd:	6a 00                	push   $0x0
  pushl $140
801070df:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801070e4:	e9 79 f4 ff ff       	jmp    80106562 <alltraps>

801070e9 <vector141>:
.globl vector141
vector141:
  pushl $0
801070e9:	6a 00                	push   $0x0
  pushl $141
801070eb:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801070f0:	e9 6d f4 ff ff       	jmp    80106562 <alltraps>

801070f5 <vector142>:
.globl vector142
vector142:
  pushl $0
801070f5:	6a 00                	push   $0x0
  pushl $142
801070f7:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801070fc:	e9 61 f4 ff ff       	jmp    80106562 <alltraps>

80107101 <vector143>:
.globl vector143
vector143:
  pushl $0
80107101:	6a 00                	push   $0x0
  pushl $143
80107103:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107108:	e9 55 f4 ff ff       	jmp    80106562 <alltraps>

8010710d <vector144>:
.globl vector144
vector144:
  pushl $0
8010710d:	6a 00                	push   $0x0
  pushl $144
8010710f:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107114:	e9 49 f4 ff ff       	jmp    80106562 <alltraps>

80107119 <vector145>:
.globl vector145
vector145:
  pushl $0
80107119:	6a 00                	push   $0x0
  pushl $145
8010711b:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107120:	e9 3d f4 ff ff       	jmp    80106562 <alltraps>

80107125 <vector146>:
.globl vector146
vector146:
  pushl $0
80107125:	6a 00                	push   $0x0
  pushl $146
80107127:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010712c:	e9 31 f4 ff ff       	jmp    80106562 <alltraps>

80107131 <vector147>:
.globl vector147
vector147:
  pushl $0
80107131:	6a 00                	push   $0x0
  pushl $147
80107133:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107138:	e9 25 f4 ff ff       	jmp    80106562 <alltraps>

8010713d <vector148>:
.globl vector148
vector148:
  pushl $0
8010713d:	6a 00                	push   $0x0
  pushl $148
8010713f:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107144:	e9 19 f4 ff ff       	jmp    80106562 <alltraps>

80107149 <vector149>:
.globl vector149
vector149:
  pushl $0
80107149:	6a 00                	push   $0x0
  pushl $149
8010714b:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107150:	e9 0d f4 ff ff       	jmp    80106562 <alltraps>

80107155 <vector150>:
.globl vector150
vector150:
  pushl $0
80107155:	6a 00                	push   $0x0
  pushl $150
80107157:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010715c:	e9 01 f4 ff ff       	jmp    80106562 <alltraps>

80107161 <vector151>:
.globl vector151
vector151:
  pushl $0
80107161:	6a 00                	push   $0x0
  pushl $151
80107163:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107168:	e9 f5 f3 ff ff       	jmp    80106562 <alltraps>

8010716d <vector152>:
.globl vector152
vector152:
  pushl $0
8010716d:	6a 00                	push   $0x0
  pushl $152
8010716f:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107174:	e9 e9 f3 ff ff       	jmp    80106562 <alltraps>

80107179 <vector153>:
.globl vector153
vector153:
  pushl $0
80107179:	6a 00                	push   $0x0
  pushl $153
8010717b:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107180:	e9 dd f3 ff ff       	jmp    80106562 <alltraps>

80107185 <vector154>:
.globl vector154
vector154:
  pushl $0
80107185:	6a 00                	push   $0x0
  pushl $154
80107187:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010718c:	e9 d1 f3 ff ff       	jmp    80106562 <alltraps>

80107191 <vector155>:
.globl vector155
vector155:
  pushl $0
80107191:	6a 00                	push   $0x0
  pushl $155
80107193:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107198:	e9 c5 f3 ff ff       	jmp    80106562 <alltraps>

8010719d <vector156>:
.globl vector156
vector156:
  pushl $0
8010719d:	6a 00                	push   $0x0
  pushl $156
8010719f:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801071a4:	e9 b9 f3 ff ff       	jmp    80106562 <alltraps>

801071a9 <vector157>:
.globl vector157
vector157:
  pushl $0
801071a9:	6a 00                	push   $0x0
  pushl $157
801071ab:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801071b0:	e9 ad f3 ff ff       	jmp    80106562 <alltraps>

801071b5 <vector158>:
.globl vector158
vector158:
  pushl $0
801071b5:	6a 00                	push   $0x0
  pushl $158
801071b7:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801071bc:	e9 a1 f3 ff ff       	jmp    80106562 <alltraps>

801071c1 <vector159>:
.globl vector159
vector159:
  pushl $0
801071c1:	6a 00                	push   $0x0
  pushl $159
801071c3:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801071c8:	e9 95 f3 ff ff       	jmp    80106562 <alltraps>

801071cd <vector160>:
.globl vector160
vector160:
  pushl $0
801071cd:	6a 00                	push   $0x0
  pushl $160
801071cf:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801071d4:	e9 89 f3 ff ff       	jmp    80106562 <alltraps>

801071d9 <vector161>:
.globl vector161
vector161:
  pushl $0
801071d9:	6a 00                	push   $0x0
  pushl $161
801071db:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801071e0:	e9 7d f3 ff ff       	jmp    80106562 <alltraps>

801071e5 <vector162>:
.globl vector162
vector162:
  pushl $0
801071e5:	6a 00                	push   $0x0
  pushl $162
801071e7:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801071ec:	e9 71 f3 ff ff       	jmp    80106562 <alltraps>

801071f1 <vector163>:
.globl vector163
vector163:
  pushl $0
801071f1:	6a 00                	push   $0x0
  pushl $163
801071f3:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801071f8:	e9 65 f3 ff ff       	jmp    80106562 <alltraps>

801071fd <vector164>:
.globl vector164
vector164:
  pushl $0
801071fd:	6a 00                	push   $0x0
  pushl $164
801071ff:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107204:	e9 59 f3 ff ff       	jmp    80106562 <alltraps>

80107209 <vector165>:
.globl vector165
vector165:
  pushl $0
80107209:	6a 00                	push   $0x0
  pushl $165
8010720b:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107210:	e9 4d f3 ff ff       	jmp    80106562 <alltraps>

80107215 <vector166>:
.globl vector166
vector166:
  pushl $0
80107215:	6a 00                	push   $0x0
  pushl $166
80107217:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010721c:	e9 41 f3 ff ff       	jmp    80106562 <alltraps>

80107221 <vector167>:
.globl vector167
vector167:
  pushl $0
80107221:	6a 00                	push   $0x0
  pushl $167
80107223:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107228:	e9 35 f3 ff ff       	jmp    80106562 <alltraps>

8010722d <vector168>:
.globl vector168
vector168:
  pushl $0
8010722d:	6a 00                	push   $0x0
  pushl $168
8010722f:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107234:	e9 29 f3 ff ff       	jmp    80106562 <alltraps>

80107239 <vector169>:
.globl vector169
vector169:
  pushl $0
80107239:	6a 00                	push   $0x0
  pushl $169
8010723b:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107240:	e9 1d f3 ff ff       	jmp    80106562 <alltraps>

80107245 <vector170>:
.globl vector170
vector170:
  pushl $0
80107245:	6a 00                	push   $0x0
  pushl $170
80107247:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010724c:	e9 11 f3 ff ff       	jmp    80106562 <alltraps>

80107251 <vector171>:
.globl vector171
vector171:
  pushl $0
80107251:	6a 00                	push   $0x0
  pushl $171
80107253:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107258:	e9 05 f3 ff ff       	jmp    80106562 <alltraps>

8010725d <vector172>:
.globl vector172
vector172:
  pushl $0
8010725d:	6a 00                	push   $0x0
  pushl $172
8010725f:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107264:	e9 f9 f2 ff ff       	jmp    80106562 <alltraps>

80107269 <vector173>:
.globl vector173
vector173:
  pushl $0
80107269:	6a 00                	push   $0x0
  pushl $173
8010726b:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107270:	e9 ed f2 ff ff       	jmp    80106562 <alltraps>

80107275 <vector174>:
.globl vector174
vector174:
  pushl $0
80107275:	6a 00                	push   $0x0
  pushl $174
80107277:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010727c:	e9 e1 f2 ff ff       	jmp    80106562 <alltraps>

80107281 <vector175>:
.globl vector175
vector175:
  pushl $0
80107281:	6a 00                	push   $0x0
  pushl $175
80107283:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107288:	e9 d5 f2 ff ff       	jmp    80106562 <alltraps>

8010728d <vector176>:
.globl vector176
vector176:
  pushl $0
8010728d:	6a 00                	push   $0x0
  pushl $176
8010728f:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107294:	e9 c9 f2 ff ff       	jmp    80106562 <alltraps>

80107299 <vector177>:
.globl vector177
vector177:
  pushl $0
80107299:	6a 00                	push   $0x0
  pushl $177
8010729b:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801072a0:	e9 bd f2 ff ff       	jmp    80106562 <alltraps>

801072a5 <vector178>:
.globl vector178
vector178:
  pushl $0
801072a5:	6a 00                	push   $0x0
  pushl $178
801072a7:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801072ac:	e9 b1 f2 ff ff       	jmp    80106562 <alltraps>

801072b1 <vector179>:
.globl vector179
vector179:
  pushl $0
801072b1:	6a 00                	push   $0x0
  pushl $179
801072b3:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801072b8:	e9 a5 f2 ff ff       	jmp    80106562 <alltraps>

801072bd <vector180>:
.globl vector180
vector180:
  pushl $0
801072bd:	6a 00                	push   $0x0
  pushl $180
801072bf:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801072c4:	e9 99 f2 ff ff       	jmp    80106562 <alltraps>

801072c9 <vector181>:
.globl vector181
vector181:
  pushl $0
801072c9:	6a 00                	push   $0x0
  pushl $181
801072cb:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801072d0:	e9 8d f2 ff ff       	jmp    80106562 <alltraps>

801072d5 <vector182>:
.globl vector182
vector182:
  pushl $0
801072d5:	6a 00                	push   $0x0
  pushl $182
801072d7:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801072dc:	e9 81 f2 ff ff       	jmp    80106562 <alltraps>

801072e1 <vector183>:
.globl vector183
vector183:
  pushl $0
801072e1:	6a 00                	push   $0x0
  pushl $183
801072e3:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801072e8:	e9 75 f2 ff ff       	jmp    80106562 <alltraps>

801072ed <vector184>:
.globl vector184
vector184:
  pushl $0
801072ed:	6a 00                	push   $0x0
  pushl $184
801072ef:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801072f4:	e9 69 f2 ff ff       	jmp    80106562 <alltraps>

801072f9 <vector185>:
.globl vector185
vector185:
  pushl $0
801072f9:	6a 00                	push   $0x0
  pushl $185
801072fb:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107300:	e9 5d f2 ff ff       	jmp    80106562 <alltraps>

80107305 <vector186>:
.globl vector186
vector186:
  pushl $0
80107305:	6a 00                	push   $0x0
  pushl $186
80107307:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010730c:	e9 51 f2 ff ff       	jmp    80106562 <alltraps>

80107311 <vector187>:
.globl vector187
vector187:
  pushl $0
80107311:	6a 00                	push   $0x0
  pushl $187
80107313:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107318:	e9 45 f2 ff ff       	jmp    80106562 <alltraps>

8010731d <vector188>:
.globl vector188
vector188:
  pushl $0
8010731d:	6a 00                	push   $0x0
  pushl $188
8010731f:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107324:	e9 39 f2 ff ff       	jmp    80106562 <alltraps>

80107329 <vector189>:
.globl vector189
vector189:
  pushl $0
80107329:	6a 00                	push   $0x0
  pushl $189
8010732b:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107330:	e9 2d f2 ff ff       	jmp    80106562 <alltraps>

80107335 <vector190>:
.globl vector190
vector190:
  pushl $0
80107335:	6a 00                	push   $0x0
  pushl $190
80107337:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010733c:	e9 21 f2 ff ff       	jmp    80106562 <alltraps>

80107341 <vector191>:
.globl vector191
vector191:
  pushl $0
80107341:	6a 00                	push   $0x0
  pushl $191
80107343:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107348:	e9 15 f2 ff ff       	jmp    80106562 <alltraps>

8010734d <vector192>:
.globl vector192
vector192:
  pushl $0
8010734d:	6a 00                	push   $0x0
  pushl $192
8010734f:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107354:	e9 09 f2 ff ff       	jmp    80106562 <alltraps>

80107359 <vector193>:
.globl vector193
vector193:
  pushl $0
80107359:	6a 00                	push   $0x0
  pushl $193
8010735b:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107360:	e9 fd f1 ff ff       	jmp    80106562 <alltraps>

80107365 <vector194>:
.globl vector194
vector194:
  pushl $0
80107365:	6a 00                	push   $0x0
  pushl $194
80107367:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010736c:	e9 f1 f1 ff ff       	jmp    80106562 <alltraps>

80107371 <vector195>:
.globl vector195
vector195:
  pushl $0
80107371:	6a 00                	push   $0x0
  pushl $195
80107373:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107378:	e9 e5 f1 ff ff       	jmp    80106562 <alltraps>

8010737d <vector196>:
.globl vector196
vector196:
  pushl $0
8010737d:	6a 00                	push   $0x0
  pushl $196
8010737f:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107384:	e9 d9 f1 ff ff       	jmp    80106562 <alltraps>

80107389 <vector197>:
.globl vector197
vector197:
  pushl $0
80107389:	6a 00                	push   $0x0
  pushl $197
8010738b:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107390:	e9 cd f1 ff ff       	jmp    80106562 <alltraps>

80107395 <vector198>:
.globl vector198
vector198:
  pushl $0
80107395:	6a 00                	push   $0x0
  pushl $198
80107397:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010739c:	e9 c1 f1 ff ff       	jmp    80106562 <alltraps>

801073a1 <vector199>:
.globl vector199
vector199:
  pushl $0
801073a1:	6a 00                	push   $0x0
  pushl $199
801073a3:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801073a8:	e9 b5 f1 ff ff       	jmp    80106562 <alltraps>

801073ad <vector200>:
.globl vector200
vector200:
  pushl $0
801073ad:	6a 00                	push   $0x0
  pushl $200
801073af:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801073b4:	e9 a9 f1 ff ff       	jmp    80106562 <alltraps>

801073b9 <vector201>:
.globl vector201
vector201:
  pushl $0
801073b9:	6a 00                	push   $0x0
  pushl $201
801073bb:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801073c0:	e9 9d f1 ff ff       	jmp    80106562 <alltraps>

801073c5 <vector202>:
.globl vector202
vector202:
  pushl $0
801073c5:	6a 00                	push   $0x0
  pushl $202
801073c7:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801073cc:	e9 91 f1 ff ff       	jmp    80106562 <alltraps>

801073d1 <vector203>:
.globl vector203
vector203:
  pushl $0
801073d1:	6a 00                	push   $0x0
  pushl $203
801073d3:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801073d8:	e9 85 f1 ff ff       	jmp    80106562 <alltraps>

801073dd <vector204>:
.globl vector204
vector204:
  pushl $0
801073dd:	6a 00                	push   $0x0
  pushl $204
801073df:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801073e4:	e9 79 f1 ff ff       	jmp    80106562 <alltraps>

801073e9 <vector205>:
.globl vector205
vector205:
  pushl $0
801073e9:	6a 00                	push   $0x0
  pushl $205
801073eb:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801073f0:	e9 6d f1 ff ff       	jmp    80106562 <alltraps>

801073f5 <vector206>:
.globl vector206
vector206:
  pushl $0
801073f5:	6a 00                	push   $0x0
  pushl $206
801073f7:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801073fc:	e9 61 f1 ff ff       	jmp    80106562 <alltraps>

80107401 <vector207>:
.globl vector207
vector207:
  pushl $0
80107401:	6a 00                	push   $0x0
  pushl $207
80107403:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107408:	e9 55 f1 ff ff       	jmp    80106562 <alltraps>

8010740d <vector208>:
.globl vector208
vector208:
  pushl $0
8010740d:	6a 00                	push   $0x0
  pushl $208
8010740f:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107414:	e9 49 f1 ff ff       	jmp    80106562 <alltraps>

80107419 <vector209>:
.globl vector209
vector209:
  pushl $0
80107419:	6a 00                	push   $0x0
  pushl $209
8010741b:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107420:	e9 3d f1 ff ff       	jmp    80106562 <alltraps>

80107425 <vector210>:
.globl vector210
vector210:
  pushl $0
80107425:	6a 00                	push   $0x0
  pushl $210
80107427:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010742c:	e9 31 f1 ff ff       	jmp    80106562 <alltraps>

80107431 <vector211>:
.globl vector211
vector211:
  pushl $0
80107431:	6a 00                	push   $0x0
  pushl $211
80107433:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107438:	e9 25 f1 ff ff       	jmp    80106562 <alltraps>

8010743d <vector212>:
.globl vector212
vector212:
  pushl $0
8010743d:	6a 00                	push   $0x0
  pushl $212
8010743f:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107444:	e9 19 f1 ff ff       	jmp    80106562 <alltraps>

80107449 <vector213>:
.globl vector213
vector213:
  pushl $0
80107449:	6a 00                	push   $0x0
  pushl $213
8010744b:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107450:	e9 0d f1 ff ff       	jmp    80106562 <alltraps>

80107455 <vector214>:
.globl vector214
vector214:
  pushl $0
80107455:	6a 00                	push   $0x0
  pushl $214
80107457:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010745c:	e9 01 f1 ff ff       	jmp    80106562 <alltraps>

80107461 <vector215>:
.globl vector215
vector215:
  pushl $0
80107461:	6a 00                	push   $0x0
  pushl $215
80107463:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107468:	e9 f5 f0 ff ff       	jmp    80106562 <alltraps>

8010746d <vector216>:
.globl vector216
vector216:
  pushl $0
8010746d:	6a 00                	push   $0x0
  pushl $216
8010746f:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107474:	e9 e9 f0 ff ff       	jmp    80106562 <alltraps>

80107479 <vector217>:
.globl vector217
vector217:
  pushl $0
80107479:	6a 00                	push   $0x0
  pushl $217
8010747b:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107480:	e9 dd f0 ff ff       	jmp    80106562 <alltraps>

80107485 <vector218>:
.globl vector218
vector218:
  pushl $0
80107485:	6a 00                	push   $0x0
  pushl $218
80107487:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010748c:	e9 d1 f0 ff ff       	jmp    80106562 <alltraps>

80107491 <vector219>:
.globl vector219
vector219:
  pushl $0
80107491:	6a 00                	push   $0x0
  pushl $219
80107493:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107498:	e9 c5 f0 ff ff       	jmp    80106562 <alltraps>

8010749d <vector220>:
.globl vector220
vector220:
  pushl $0
8010749d:	6a 00                	push   $0x0
  pushl $220
8010749f:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801074a4:	e9 b9 f0 ff ff       	jmp    80106562 <alltraps>

801074a9 <vector221>:
.globl vector221
vector221:
  pushl $0
801074a9:	6a 00                	push   $0x0
  pushl $221
801074ab:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801074b0:	e9 ad f0 ff ff       	jmp    80106562 <alltraps>

801074b5 <vector222>:
.globl vector222
vector222:
  pushl $0
801074b5:	6a 00                	push   $0x0
  pushl $222
801074b7:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801074bc:	e9 a1 f0 ff ff       	jmp    80106562 <alltraps>

801074c1 <vector223>:
.globl vector223
vector223:
  pushl $0
801074c1:	6a 00                	push   $0x0
  pushl $223
801074c3:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801074c8:	e9 95 f0 ff ff       	jmp    80106562 <alltraps>

801074cd <vector224>:
.globl vector224
vector224:
  pushl $0
801074cd:	6a 00                	push   $0x0
  pushl $224
801074cf:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801074d4:	e9 89 f0 ff ff       	jmp    80106562 <alltraps>

801074d9 <vector225>:
.globl vector225
vector225:
  pushl $0
801074d9:	6a 00                	push   $0x0
  pushl $225
801074db:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801074e0:	e9 7d f0 ff ff       	jmp    80106562 <alltraps>

801074e5 <vector226>:
.globl vector226
vector226:
  pushl $0
801074e5:	6a 00                	push   $0x0
  pushl $226
801074e7:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801074ec:	e9 71 f0 ff ff       	jmp    80106562 <alltraps>

801074f1 <vector227>:
.globl vector227
vector227:
  pushl $0
801074f1:	6a 00                	push   $0x0
  pushl $227
801074f3:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801074f8:	e9 65 f0 ff ff       	jmp    80106562 <alltraps>

801074fd <vector228>:
.globl vector228
vector228:
  pushl $0
801074fd:	6a 00                	push   $0x0
  pushl $228
801074ff:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107504:	e9 59 f0 ff ff       	jmp    80106562 <alltraps>

80107509 <vector229>:
.globl vector229
vector229:
  pushl $0
80107509:	6a 00                	push   $0x0
  pushl $229
8010750b:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107510:	e9 4d f0 ff ff       	jmp    80106562 <alltraps>

80107515 <vector230>:
.globl vector230
vector230:
  pushl $0
80107515:	6a 00                	push   $0x0
  pushl $230
80107517:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010751c:	e9 41 f0 ff ff       	jmp    80106562 <alltraps>

80107521 <vector231>:
.globl vector231
vector231:
  pushl $0
80107521:	6a 00                	push   $0x0
  pushl $231
80107523:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107528:	e9 35 f0 ff ff       	jmp    80106562 <alltraps>

8010752d <vector232>:
.globl vector232
vector232:
  pushl $0
8010752d:	6a 00                	push   $0x0
  pushl $232
8010752f:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107534:	e9 29 f0 ff ff       	jmp    80106562 <alltraps>

80107539 <vector233>:
.globl vector233
vector233:
  pushl $0
80107539:	6a 00                	push   $0x0
  pushl $233
8010753b:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107540:	e9 1d f0 ff ff       	jmp    80106562 <alltraps>

80107545 <vector234>:
.globl vector234
vector234:
  pushl $0
80107545:	6a 00                	push   $0x0
  pushl $234
80107547:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010754c:	e9 11 f0 ff ff       	jmp    80106562 <alltraps>

80107551 <vector235>:
.globl vector235
vector235:
  pushl $0
80107551:	6a 00                	push   $0x0
  pushl $235
80107553:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107558:	e9 05 f0 ff ff       	jmp    80106562 <alltraps>

8010755d <vector236>:
.globl vector236
vector236:
  pushl $0
8010755d:	6a 00                	push   $0x0
  pushl $236
8010755f:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107564:	e9 f9 ef ff ff       	jmp    80106562 <alltraps>

80107569 <vector237>:
.globl vector237
vector237:
  pushl $0
80107569:	6a 00                	push   $0x0
  pushl $237
8010756b:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107570:	e9 ed ef ff ff       	jmp    80106562 <alltraps>

80107575 <vector238>:
.globl vector238
vector238:
  pushl $0
80107575:	6a 00                	push   $0x0
  pushl $238
80107577:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010757c:	e9 e1 ef ff ff       	jmp    80106562 <alltraps>

80107581 <vector239>:
.globl vector239
vector239:
  pushl $0
80107581:	6a 00                	push   $0x0
  pushl $239
80107583:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107588:	e9 d5 ef ff ff       	jmp    80106562 <alltraps>

8010758d <vector240>:
.globl vector240
vector240:
  pushl $0
8010758d:	6a 00                	push   $0x0
  pushl $240
8010758f:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107594:	e9 c9 ef ff ff       	jmp    80106562 <alltraps>

80107599 <vector241>:
.globl vector241
vector241:
  pushl $0
80107599:	6a 00                	push   $0x0
  pushl $241
8010759b:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801075a0:	e9 bd ef ff ff       	jmp    80106562 <alltraps>

801075a5 <vector242>:
.globl vector242
vector242:
  pushl $0
801075a5:	6a 00                	push   $0x0
  pushl $242
801075a7:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801075ac:	e9 b1 ef ff ff       	jmp    80106562 <alltraps>

801075b1 <vector243>:
.globl vector243
vector243:
  pushl $0
801075b1:	6a 00                	push   $0x0
  pushl $243
801075b3:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801075b8:	e9 a5 ef ff ff       	jmp    80106562 <alltraps>

801075bd <vector244>:
.globl vector244
vector244:
  pushl $0
801075bd:	6a 00                	push   $0x0
  pushl $244
801075bf:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801075c4:	e9 99 ef ff ff       	jmp    80106562 <alltraps>

801075c9 <vector245>:
.globl vector245
vector245:
  pushl $0
801075c9:	6a 00                	push   $0x0
  pushl $245
801075cb:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801075d0:	e9 8d ef ff ff       	jmp    80106562 <alltraps>

801075d5 <vector246>:
.globl vector246
vector246:
  pushl $0
801075d5:	6a 00                	push   $0x0
  pushl $246
801075d7:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801075dc:	e9 81 ef ff ff       	jmp    80106562 <alltraps>

801075e1 <vector247>:
.globl vector247
vector247:
  pushl $0
801075e1:	6a 00                	push   $0x0
  pushl $247
801075e3:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801075e8:	e9 75 ef ff ff       	jmp    80106562 <alltraps>

801075ed <vector248>:
.globl vector248
vector248:
  pushl $0
801075ed:	6a 00                	push   $0x0
  pushl $248
801075ef:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801075f4:	e9 69 ef ff ff       	jmp    80106562 <alltraps>

801075f9 <vector249>:
.globl vector249
vector249:
  pushl $0
801075f9:	6a 00                	push   $0x0
  pushl $249
801075fb:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107600:	e9 5d ef ff ff       	jmp    80106562 <alltraps>

80107605 <vector250>:
.globl vector250
vector250:
  pushl $0
80107605:	6a 00                	push   $0x0
  pushl $250
80107607:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010760c:	e9 51 ef ff ff       	jmp    80106562 <alltraps>

80107611 <vector251>:
.globl vector251
vector251:
  pushl $0
80107611:	6a 00                	push   $0x0
  pushl $251
80107613:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107618:	e9 45 ef ff ff       	jmp    80106562 <alltraps>

8010761d <vector252>:
.globl vector252
vector252:
  pushl $0
8010761d:	6a 00                	push   $0x0
  pushl $252
8010761f:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107624:	e9 39 ef ff ff       	jmp    80106562 <alltraps>

80107629 <vector253>:
.globl vector253
vector253:
  pushl $0
80107629:	6a 00                	push   $0x0
  pushl $253
8010762b:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107630:	e9 2d ef ff ff       	jmp    80106562 <alltraps>

80107635 <vector254>:
.globl vector254
vector254:
  pushl $0
80107635:	6a 00                	push   $0x0
  pushl $254
80107637:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010763c:	e9 21 ef ff ff       	jmp    80106562 <alltraps>

80107641 <vector255>:
.globl vector255
vector255:
  pushl $0
80107641:	6a 00                	push   $0x0
  pushl $255
80107643:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107648:	e9 15 ef ff ff       	jmp    80106562 <alltraps>

8010764d <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010764d:	55                   	push   %ebp
8010764e:	89 e5                	mov    %esp,%ebp
80107650:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107653:	8b 45 0c             	mov    0xc(%ebp),%eax
80107656:	83 e8 01             	sub    $0x1,%eax
80107659:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010765d:	8b 45 08             	mov    0x8(%ebp),%eax
80107660:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107664:	8b 45 08             	mov    0x8(%ebp),%eax
80107667:	c1 e8 10             	shr    $0x10,%eax
8010766a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010766e:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107671:	0f 01 10             	lgdtl  (%eax)
}
80107674:	c9                   	leave  
80107675:	c3                   	ret    

80107676 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107676:	55                   	push   %ebp
80107677:	89 e5                	mov    %esp,%ebp
80107679:	83 ec 04             	sub    $0x4,%esp
8010767c:	8b 45 08             	mov    0x8(%ebp),%eax
8010767f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107683:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107687:	0f 00 d8             	ltr    %ax
}
8010768a:	c9                   	leave  
8010768b:	c3                   	ret    

8010768c <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010768c:	55                   	push   %ebp
8010768d:	89 e5                	mov    %esp,%ebp
8010768f:	83 ec 04             	sub    $0x4,%esp
80107692:	8b 45 08             	mov    0x8(%ebp),%eax
80107695:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107699:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010769d:	8e e8                	mov    %eax,%gs
}
8010769f:	c9                   	leave  
801076a0:	c3                   	ret    

801076a1 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801076a1:	55                   	push   %ebp
801076a2:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801076a4:	8b 45 08             	mov    0x8(%ebp),%eax
801076a7:	0f 22 d8             	mov    %eax,%cr3
}
801076aa:	5d                   	pop    %ebp
801076ab:	c3                   	ret    

801076ac <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801076ac:	55                   	push   %ebp
801076ad:	89 e5                	mov    %esp,%ebp
801076af:	8b 45 08             	mov    0x8(%ebp),%eax
801076b2:	05 00 00 00 80       	add    $0x80000000,%eax
801076b7:	5d                   	pop    %ebp
801076b8:	c3                   	ret    

801076b9 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801076b9:	55                   	push   %ebp
801076ba:	89 e5                	mov    %esp,%ebp
801076bc:	8b 45 08             	mov    0x8(%ebp),%eax
801076bf:	05 00 00 00 80       	add    $0x80000000,%eax
801076c4:	5d                   	pop    %ebp
801076c5:	c3                   	ret    

801076c6 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801076c6:	55                   	push   %ebp
801076c7:	89 e5                	mov    %esp,%ebp
801076c9:	53                   	push   %ebx
801076ca:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801076cd:	e8 a6 b7 ff ff       	call   80102e78 <cpunum>
801076d2:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801076d8:	05 60 23 11 80       	add    $0x80112360,%eax
801076dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801076e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e3:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801076e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ec:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801076f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f5:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801076f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fc:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107700:	83 e2 f0             	and    $0xfffffff0,%edx
80107703:	83 ca 0a             	or     $0xa,%edx
80107706:	88 50 7d             	mov    %dl,0x7d(%eax)
80107709:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107710:	83 ca 10             	or     $0x10,%edx
80107713:	88 50 7d             	mov    %dl,0x7d(%eax)
80107716:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107719:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010771d:	83 e2 9f             	and    $0xffffff9f,%edx
80107720:	88 50 7d             	mov    %dl,0x7d(%eax)
80107723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107726:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010772a:	83 ca 80             	or     $0xffffff80,%edx
8010772d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107733:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107737:	83 ca 0f             	or     $0xf,%edx
8010773a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010773d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107740:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107744:	83 e2 ef             	and    $0xffffffef,%edx
80107747:	88 50 7e             	mov    %dl,0x7e(%eax)
8010774a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107751:	83 e2 df             	and    $0xffffffdf,%edx
80107754:	88 50 7e             	mov    %dl,0x7e(%eax)
80107757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010775e:	83 ca 40             	or     $0x40,%edx
80107761:	88 50 7e             	mov    %dl,0x7e(%eax)
80107764:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107767:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010776b:	83 ca 80             	or     $0xffffff80,%edx
8010776e:	88 50 7e             	mov    %dl,0x7e(%eax)
80107771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107774:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107778:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010777b:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107782:	ff ff 
80107784:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107787:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010778e:	00 00 
80107790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107793:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010779a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801077a4:	83 e2 f0             	and    $0xfffffff0,%edx
801077a7:	83 ca 02             	or     $0x2,%edx
801077aa:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801077b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b3:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801077ba:	83 ca 10             	or     $0x10,%edx
801077bd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801077c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801077cd:	83 e2 9f             	and    $0xffffff9f,%edx
801077d0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801077d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801077e0:	83 ca 80             	or     $0xffffff80,%edx
801077e3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801077e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ec:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801077f3:	83 ca 0f             	or     $0xf,%edx
801077f6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801077fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ff:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107806:	83 e2 ef             	and    $0xffffffef,%edx
80107809:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010780f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107812:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107819:	83 e2 df             	and    $0xffffffdf,%edx
8010781c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107825:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010782c:	83 ca 40             	or     $0x40,%edx
8010782f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107838:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010783f:	83 ca 80             	or     $0xffffff80,%edx
80107842:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784b:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107852:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107855:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010785c:	ff ff 
8010785e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107861:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107868:	00 00 
8010786a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786d:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107877:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010787e:	83 e2 f0             	and    $0xfffffff0,%edx
80107881:	83 ca 0a             	or     $0xa,%edx
80107884:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010788a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010788d:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107894:	83 ca 10             	or     $0x10,%edx
80107897:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010789d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801078a7:	83 ca 60             	or     $0x60,%edx
801078aa:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801078b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801078ba:	83 ca 80             	or     $0xffffff80,%edx
801078bd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801078c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c6:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801078cd:	83 ca 0f             	or     $0xf,%edx
801078d0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801078d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801078e0:	83 e2 ef             	and    $0xffffffef,%edx
801078e3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801078e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ec:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801078f3:	83 e2 df             	and    $0xffffffdf,%edx
801078f6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801078fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ff:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107906:	83 ca 40             	or     $0x40,%edx
80107909:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010790f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107912:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107919:	83 ca 80             	or     $0xffffff80,%edx
8010791c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107922:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107925:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010792c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010792f:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107936:	ff ff 
80107938:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793b:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107942:	00 00 
80107944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107947:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010794e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107951:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107958:	83 e2 f0             	and    $0xfffffff0,%edx
8010795b:	83 ca 02             	or     $0x2,%edx
8010795e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107964:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107967:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010796e:	83 ca 10             	or     $0x10,%edx
80107971:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107977:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010797a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107981:	83 ca 60             	or     $0x60,%edx
80107984:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010798a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107994:	83 ca 80             	or     $0xffffff80,%edx
80107997:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010799d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801079a7:	83 ca 0f             	or     $0xf,%edx
801079aa:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801079b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801079ba:	83 e2 ef             	and    $0xffffffef,%edx
801079bd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801079c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801079cd:	83 e2 df             	and    $0xffffffdf,%edx
801079d0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801079d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801079e0:	83 ca 40             	or     $0x40,%edx
801079e3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801079e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ec:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801079f3:	83 ca 80             	or     $0xffffff80,%edx
801079f6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801079fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ff:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a09:	05 b4 00 00 00       	add    $0xb4,%eax
80107a0e:	89 c3                	mov    %eax,%ebx
80107a10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a13:	05 b4 00 00 00       	add    $0xb4,%eax
80107a18:	c1 e8 10             	shr    $0x10,%eax
80107a1b:	89 c1                	mov    %eax,%ecx
80107a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a20:	05 b4 00 00 00       	add    $0xb4,%eax
80107a25:	c1 e8 18             	shr    $0x18,%eax
80107a28:	89 c2                	mov    %eax,%edx
80107a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a2d:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107a34:	00 00 
80107a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a39:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a43:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a53:	83 e1 f0             	and    $0xfffffff0,%ecx
80107a56:	83 c9 02             	or     $0x2,%ecx
80107a59:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a62:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a69:	83 c9 10             	or     $0x10,%ecx
80107a6c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a75:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a7c:	83 e1 9f             	and    $0xffffff9f,%ecx
80107a7f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a88:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107a8f:	83 c9 80             	or     $0xffffff80,%ecx
80107a92:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107aa2:	83 e1 f0             	and    $0xfffffff0,%ecx
80107aa5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aae:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ab5:	83 e1 ef             	and    $0xffffffef,%ecx
80107ab8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ac8:	83 e1 df             	and    $0xffffffdf,%ecx
80107acb:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107adb:	83 c9 40             	or     $0x40,%ecx
80107ade:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107aee:	83 c9 80             	or     $0xffffff80,%ecx
80107af1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afa:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b03:	83 c0 70             	add    $0x70,%eax
80107b06:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107b0d:	00 
80107b0e:	89 04 24             	mov    %eax,(%esp)
80107b11:	e8 37 fb ff ff       	call   8010764d <lgdt>
  loadgs(SEG_KCPU << 3);
80107b16:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107b1d:	e8 6a fb ff ff       	call   8010768c <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b25:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107b2b:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107b32:	00 00 00 00 
}
80107b36:	83 c4 24             	add    $0x24,%esp
80107b39:	5b                   	pop    %ebx
80107b3a:	5d                   	pop    %ebp
80107b3b:	c3                   	ret    

80107b3c <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107b3c:	55                   	push   %ebp
80107b3d:	89 e5                	mov    %esp,%ebp
80107b3f:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107b42:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b45:	c1 e8 16             	shr    $0x16,%eax
80107b48:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107b4f:	8b 45 08             	mov    0x8(%ebp),%eax
80107b52:	01 d0                	add    %edx,%eax
80107b54:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107b57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b5a:	8b 00                	mov    (%eax),%eax
80107b5c:	83 e0 01             	and    $0x1,%eax
80107b5f:	85 c0                	test   %eax,%eax
80107b61:	74 17                	je     80107b7a <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107b63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b66:	8b 00                	mov    (%eax),%eax
80107b68:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b6d:	89 04 24             	mov    %eax,(%esp)
80107b70:	e8 44 fb ff ff       	call   801076b9 <p2v>
80107b75:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107b78:	eb 4b                	jmp    80107bc5 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107b7a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107b7e:	74 0e                	je     80107b8e <walkpgdir+0x52>
80107b80:	e8 5d af ff ff       	call   80102ae2 <kalloc>
80107b85:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107b88:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107b8c:	75 07                	jne    80107b95 <walkpgdir+0x59>
      return 0;
80107b8e:	b8 00 00 00 00       	mov    $0x0,%eax
80107b93:	eb 47                	jmp    80107bdc <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107b95:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107b9c:	00 
80107b9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ba4:	00 
80107ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba8:	89 04 24             	mov    %eax,(%esp)
80107bab:	e8 be d5 ff ff       	call   8010516e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb3:	89 04 24             	mov    %eax,(%esp)
80107bb6:	e8 f1 fa ff ff       	call   801076ac <v2p>
80107bbb:	83 c8 07             	or     $0x7,%eax
80107bbe:	89 c2                	mov    %eax,%edx
80107bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107bc3:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107bc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80107bc8:	c1 e8 0c             	shr    $0xc,%eax
80107bcb:	25 ff 03 00 00       	and    $0x3ff,%eax
80107bd0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bda:	01 d0                	add    %edx,%eax
}
80107bdc:	c9                   	leave  
80107bdd:	c3                   	ret    

80107bde <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107bde:	55                   	push   %ebp
80107bdf:	89 e5                	mov    %esp,%ebp
80107be1:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107be4:	8b 45 0c             	mov    0xc(%ebp),%eax
80107be7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107bec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107bef:	8b 55 0c             	mov    0xc(%ebp),%edx
80107bf2:	8b 45 10             	mov    0x10(%ebp),%eax
80107bf5:	01 d0                	add    %edx,%eax
80107bf7:	83 e8 01             	sub    $0x1,%eax
80107bfa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107bff:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107c02:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107c09:	00 
80107c0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c11:	8b 45 08             	mov    0x8(%ebp),%eax
80107c14:	89 04 24             	mov    %eax,(%esp)
80107c17:	e8 20 ff ff ff       	call   80107b3c <walkpgdir>
80107c1c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107c1f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107c23:	75 07                	jne    80107c2c <mappages+0x4e>
      return -1;
80107c25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107c2a:	eb 48                	jmp    80107c74 <mappages+0x96>
    if(*pte & PTE_P)
80107c2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107c2f:	8b 00                	mov    (%eax),%eax
80107c31:	83 e0 01             	and    $0x1,%eax
80107c34:	85 c0                	test   %eax,%eax
80107c36:	74 0c                	je     80107c44 <mappages+0x66>
      panic("remap");
80107c38:	c7 04 24 9c 8a 10 80 	movl   $0x80108a9c,(%esp)
80107c3f:	e8 f6 88 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107c44:	8b 45 18             	mov    0x18(%ebp),%eax
80107c47:	0b 45 14             	or     0x14(%ebp),%eax
80107c4a:	83 c8 01             	or     $0x1,%eax
80107c4d:	89 c2                	mov    %eax,%edx
80107c4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107c52:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107c54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c57:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107c5a:	75 08                	jne    80107c64 <mappages+0x86>
      break;
80107c5c:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107c5d:	b8 00 00 00 00       	mov    $0x0,%eax
80107c62:	eb 10                	jmp    80107c74 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107c64:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107c6b:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107c72:	eb 8e                	jmp    80107c02 <mappages+0x24>
  return 0;
}
80107c74:	c9                   	leave  
80107c75:	c3                   	ret    

80107c76 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107c76:	55                   	push   %ebp
80107c77:	89 e5                	mov    %esp,%ebp
80107c79:	53                   	push   %ebx
80107c7a:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107c7d:	e8 60 ae ff ff       	call   80102ae2 <kalloc>
80107c82:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107c85:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107c89:	75 0a                	jne    80107c95 <setupkvm+0x1f>
    return 0;
80107c8b:	b8 00 00 00 00       	mov    $0x0,%eax
80107c90:	e9 98 00 00 00       	jmp    80107d2d <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107c95:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c9c:	00 
80107c9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ca4:	00 
80107ca5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ca8:	89 04 24             	mov    %eax,(%esp)
80107cab:	e8 be d4 ff ff       	call   8010516e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107cb0:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107cb7:	e8 fd f9 ff ff       	call   801076b9 <p2v>
80107cbc:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107cc1:	76 0c                	jbe    80107ccf <setupkvm+0x59>
    panic("PHYSTOP too high");
80107cc3:	c7 04 24 a2 8a 10 80 	movl   $0x80108aa2,(%esp)
80107cca:	e8 6b 88 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107ccf:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107cd6:	eb 49                	jmp    80107d21 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cdb:	8b 48 0c             	mov    0xc(%eax),%ecx
80107cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce1:	8b 50 04             	mov    0x4(%eax),%edx
80107ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce7:	8b 58 08             	mov    0x8(%eax),%ebx
80107cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ced:	8b 40 04             	mov    0x4(%eax),%eax
80107cf0:	29 c3                	sub    %eax,%ebx
80107cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf5:	8b 00                	mov    (%eax),%eax
80107cf7:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107cfb:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107cff:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107d03:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d0a:	89 04 24             	mov    %eax,(%esp)
80107d0d:	e8 cc fe ff ff       	call   80107bde <mappages>
80107d12:	85 c0                	test   %eax,%eax
80107d14:	79 07                	jns    80107d1d <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107d16:	b8 00 00 00 00       	mov    $0x0,%eax
80107d1b:	eb 10                	jmp    80107d2d <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107d1d:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107d21:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107d28:	72 ae                	jb     80107cd8 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107d2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107d2d:	83 c4 34             	add    $0x34,%esp
80107d30:	5b                   	pop    %ebx
80107d31:	5d                   	pop    %ebp
80107d32:	c3                   	ret    

80107d33 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107d33:	55                   	push   %ebp
80107d34:	89 e5                	mov    %esp,%ebp
80107d36:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107d39:	e8 38 ff ff ff       	call   80107c76 <setupkvm>
80107d3e:	a3 38 51 11 80       	mov    %eax,0x80115138
  switchkvm();
80107d43:	e8 02 00 00 00       	call   80107d4a <switchkvm>
}
80107d48:	c9                   	leave  
80107d49:	c3                   	ret    

80107d4a <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107d4a:	55                   	push   %ebp
80107d4b:	89 e5                	mov    %esp,%ebp
80107d4d:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107d50:	a1 38 51 11 80       	mov    0x80115138,%eax
80107d55:	89 04 24             	mov    %eax,(%esp)
80107d58:	e8 4f f9 ff ff       	call   801076ac <v2p>
80107d5d:	89 04 24             	mov    %eax,(%esp)
80107d60:	e8 3c f9 ff ff       	call   801076a1 <lcr3>
}
80107d65:	c9                   	leave  
80107d66:	c3                   	ret    

80107d67 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107d67:	55                   	push   %ebp
80107d68:	89 e5                	mov    %esp,%ebp
80107d6a:	53                   	push   %ebx
80107d6b:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107d6e:	e8 fb d2 ff ff       	call   8010506e <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107d73:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107d79:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d80:	83 c2 08             	add    $0x8,%edx
80107d83:	89 d3                	mov    %edx,%ebx
80107d85:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d8c:	83 c2 08             	add    $0x8,%edx
80107d8f:	c1 ea 10             	shr    $0x10,%edx
80107d92:	89 d1                	mov    %edx,%ecx
80107d94:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107d9b:	83 c2 08             	add    $0x8,%edx
80107d9e:	c1 ea 18             	shr    $0x18,%edx
80107da1:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107da8:	67 00 
80107daa:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107db1:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107db7:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107dbe:	83 e1 f0             	and    $0xfffffff0,%ecx
80107dc1:	83 c9 09             	or     $0x9,%ecx
80107dc4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107dca:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107dd1:	83 c9 10             	or     $0x10,%ecx
80107dd4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107dda:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107de1:	83 e1 9f             	and    $0xffffff9f,%ecx
80107de4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107dea:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107df1:	83 c9 80             	or     $0xffffff80,%ecx
80107df4:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107dfa:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107e01:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e04:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107e0a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107e11:	83 e1 ef             	and    $0xffffffef,%ecx
80107e14:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107e1a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107e21:	83 e1 df             	and    $0xffffffdf,%ecx
80107e24:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107e2a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107e31:	83 c9 40             	or     $0x40,%ecx
80107e34:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107e3a:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107e41:	83 e1 7f             	and    $0x7f,%ecx
80107e44:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107e4a:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107e50:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e56:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107e5d:	83 e2 ef             	and    $0xffffffef,%edx
80107e60:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107e66:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e6c:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107e72:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e78:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107e7f:	8b 52 08             	mov    0x8(%edx),%edx
80107e82:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107e88:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107e8b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107e92:	e8 df f7 ff ff       	call   80107676 <ltr>
  if(p->pgdir == 0)
80107e97:	8b 45 08             	mov    0x8(%ebp),%eax
80107e9a:	8b 40 04             	mov    0x4(%eax),%eax
80107e9d:	85 c0                	test   %eax,%eax
80107e9f:	75 0c                	jne    80107ead <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107ea1:	c7 04 24 b3 8a 10 80 	movl   $0x80108ab3,(%esp)
80107ea8:	e8 8d 86 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107ead:	8b 45 08             	mov    0x8(%ebp),%eax
80107eb0:	8b 40 04             	mov    0x4(%eax),%eax
80107eb3:	89 04 24             	mov    %eax,(%esp)
80107eb6:	e8 f1 f7 ff ff       	call   801076ac <v2p>
80107ebb:	89 04 24             	mov    %eax,(%esp)
80107ebe:	e8 de f7 ff ff       	call   801076a1 <lcr3>
  popcli();
80107ec3:	e8 ea d1 ff ff       	call   801050b2 <popcli>
}
80107ec8:	83 c4 14             	add    $0x14,%esp
80107ecb:	5b                   	pop    %ebx
80107ecc:	5d                   	pop    %ebp
80107ecd:	c3                   	ret    

80107ece <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107ece:	55                   	push   %ebp
80107ecf:	89 e5                	mov    %esp,%ebp
80107ed1:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107ed4:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107edb:	76 0c                	jbe    80107ee9 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107edd:	c7 04 24 c7 8a 10 80 	movl   $0x80108ac7,(%esp)
80107ee4:	e8 51 86 ff ff       	call   8010053a <panic>
  mem = kalloc();
80107ee9:	e8 f4 ab ff ff       	call   80102ae2 <kalloc>
80107eee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107ef1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ef8:	00 
80107ef9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f00:	00 
80107f01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f04:	89 04 24             	mov    %eax,(%esp)
80107f07:	e8 62 d2 ff ff       	call   8010516e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0f:	89 04 24             	mov    %eax,(%esp)
80107f12:	e8 95 f7 ff ff       	call   801076ac <v2p>
80107f17:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107f1e:	00 
80107f1f:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107f23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f2a:	00 
80107f2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f32:	00 
80107f33:	8b 45 08             	mov    0x8(%ebp),%eax
80107f36:	89 04 24             	mov    %eax,(%esp)
80107f39:	e8 a0 fc ff ff       	call   80107bde <mappages>
  memmove(mem, init, sz);
80107f3e:	8b 45 10             	mov    0x10(%ebp),%eax
80107f41:	89 44 24 08          	mov    %eax,0x8(%esp)
80107f45:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f48:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f4f:	89 04 24             	mov    %eax,(%esp)
80107f52:	e8 e6 d2 ff ff       	call   8010523d <memmove>
}
80107f57:	c9                   	leave  
80107f58:	c3                   	ret    

80107f59 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107f59:	55                   	push   %ebp
80107f5a:	89 e5                	mov    %esp,%ebp
80107f5c:	53                   	push   %ebx
80107f5d:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107f60:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f63:	25 ff 0f 00 00       	and    $0xfff,%eax
80107f68:	85 c0                	test   %eax,%eax
80107f6a:	74 0c                	je     80107f78 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107f6c:	c7 04 24 e4 8a 10 80 	movl   $0x80108ae4,(%esp)
80107f73:	e8 c2 85 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107f78:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107f7f:	e9 a9 00 00 00       	jmp    8010802d <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107f84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f87:	8b 55 0c             	mov    0xc(%ebp),%edx
80107f8a:	01 d0                	add    %edx,%eax
80107f8c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f93:	00 
80107f94:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f98:	8b 45 08             	mov    0x8(%ebp),%eax
80107f9b:	89 04 24             	mov    %eax,(%esp)
80107f9e:	e8 99 fb ff ff       	call   80107b3c <walkpgdir>
80107fa3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107fa6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107faa:	75 0c                	jne    80107fb8 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107fac:	c7 04 24 07 8b 10 80 	movl   $0x80108b07,(%esp)
80107fb3:	e8 82 85 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80107fb8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107fbb:	8b 00                	mov    (%eax),%eax
80107fbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fc2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107fc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc8:	8b 55 18             	mov    0x18(%ebp),%edx
80107fcb:	29 c2                	sub    %eax,%edx
80107fcd:	89 d0                	mov    %edx,%eax
80107fcf:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107fd4:	77 0f                	ja     80107fe5 <loaduvm+0x8c>
      n = sz - i;
80107fd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fd9:	8b 55 18             	mov    0x18(%ebp),%edx
80107fdc:	29 c2                	sub    %eax,%edx
80107fde:	89 d0                	mov    %edx,%eax
80107fe0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107fe3:	eb 07                	jmp    80107fec <loaduvm+0x93>
    else
      n = PGSIZE;
80107fe5:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fef:	8b 55 14             	mov    0x14(%ebp),%edx
80107ff2:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107ff5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107ff8:	89 04 24             	mov    %eax,(%esp)
80107ffb:	e8 b9 f6 ff ff       	call   801076b9 <p2v>
80108000:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108003:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108007:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010800b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010800f:	8b 45 10             	mov    0x10(%ebp),%eax
80108012:	89 04 24             	mov    %eax,(%esp)
80108015:	e8 4e 9d ff ff       	call   80101d68 <readi>
8010801a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010801d:	74 07                	je     80108026 <loaduvm+0xcd>
      return -1;
8010801f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108024:	eb 18                	jmp    8010803e <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108026:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010802d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108030:	3b 45 18             	cmp    0x18(%ebp),%eax
80108033:	0f 82 4b ff ff ff    	jb     80107f84 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108039:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010803e:	83 c4 24             	add    $0x24,%esp
80108041:	5b                   	pop    %ebx
80108042:	5d                   	pop    %ebp
80108043:	c3                   	ret    

80108044 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108044:	55                   	push   %ebp
80108045:	89 e5                	mov    %esp,%ebp
80108047:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
8010804a:	8b 45 10             	mov    0x10(%ebp),%eax
8010804d:	85 c0                	test   %eax,%eax
8010804f:	79 0a                	jns    8010805b <allocuvm+0x17>
    return 0;
80108051:	b8 00 00 00 00       	mov    $0x0,%eax
80108056:	e9 c1 00 00 00       	jmp    8010811c <allocuvm+0xd8>
  if(newsz < oldsz)
8010805b:	8b 45 10             	mov    0x10(%ebp),%eax
8010805e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108061:	73 08                	jae    8010806b <allocuvm+0x27>
    return oldsz;
80108063:	8b 45 0c             	mov    0xc(%ebp),%eax
80108066:	e9 b1 00 00 00       	jmp    8010811c <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010806b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010806e:	05 ff 0f 00 00       	add    $0xfff,%eax
80108073:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108078:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010807b:	e9 8d 00 00 00       	jmp    8010810d <allocuvm+0xc9>
    mem = kalloc();
80108080:	e8 5d aa ff ff       	call   80102ae2 <kalloc>
80108085:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108088:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010808c:	75 2c                	jne    801080ba <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010808e:	c7 04 24 25 8b 10 80 	movl   $0x80108b25,(%esp)
80108095:	e8 06 83 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010809a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010809d:	89 44 24 08          	mov    %eax,0x8(%esp)
801080a1:	8b 45 10             	mov    0x10(%ebp),%eax
801080a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801080a8:	8b 45 08             	mov    0x8(%ebp),%eax
801080ab:	89 04 24             	mov    %eax,(%esp)
801080ae:	e8 6b 00 00 00       	call   8010811e <deallocuvm>
      return 0;
801080b3:	b8 00 00 00 00       	mov    $0x0,%eax
801080b8:	eb 62                	jmp    8010811c <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801080ba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080c1:	00 
801080c2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801080c9:	00 
801080ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080cd:	89 04 24             	mov    %eax,(%esp)
801080d0:	e8 99 d0 ff ff       	call   8010516e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801080d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080d8:	89 04 24             	mov    %eax,(%esp)
801080db:	e8 cc f5 ff ff       	call   801076ac <v2p>
801080e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801080e3:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801080ea:	00 
801080eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
801080ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080f6:	00 
801080f7:	89 54 24 04          	mov    %edx,0x4(%esp)
801080fb:	8b 45 08             	mov    0x8(%ebp),%eax
801080fe:	89 04 24             	mov    %eax,(%esp)
80108101:	e8 d8 fa ff ff       	call   80107bde <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108106:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010810d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108110:	3b 45 10             	cmp    0x10(%ebp),%eax
80108113:	0f 82 67 ff ff ff    	jb     80108080 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108119:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010811c:	c9                   	leave  
8010811d:	c3                   	ret    

8010811e <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010811e:	55                   	push   %ebp
8010811f:	89 e5                	mov    %esp,%ebp
80108121:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108124:	8b 45 10             	mov    0x10(%ebp),%eax
80108127:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010812a:	72 08                	jb     80108134 <deallocuvm+0x16>
    return oldsz;
8010812c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010812f:	e9 a4 00 00 00       	jmp    801081d8 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108134:	8b 45 10             	mov    0x10(%ebp),%eax
80108137:	05 ff 0f 00 00       	add    $0xfff,%eax
8010813c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108141:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108144:	e9 80 00 00 00       	jmp    801081c9 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108149:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010814c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108153:	00 
80108154:	89 44 24 04          	mov    %eax,0x4(%esp)
80108158:	8b 45 08             	mov    0x8(%ebp),%eax
8010815b:	89 04 24             	mov    %eax,(%esp)
8010815e:	e8 d9 f9 ff ff       	call   80107b3c <walkpgdir>
80108163:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108166:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010816a:	75 09                	jne    80108175 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010816c:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108173:	eb 4d                	jmp    801081c2 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108175:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108178:	8b 00                	mov    (%eax),%eax
8010817a:	83 e0 01             	and    $0x1,%eax
8010817d:	85 c0                	test   %eax,%eax
8010817f:	74 41                	je     801081c2 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108181:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108184:	8b 00                	mov    (%eax),%eax
80108186:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010818b:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
8010818e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108192:	75 0c                	jne    801081a0 <deallocuvm+0x82>
        panic("kfree");
80108194:	c7 04 24 3d 8b 10 80 	movl   $0x80108b3d,(%esp)
8010819b:	e8 9a 83 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
801081a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081a3:	89 04 24             	mov    %eax,(%esp)
801081a6:	e8 0e f5 ff ff       	call   801076b9 <p2v>
801081ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801081ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
801081b1:	89 04 24             	mov    %eax,(%esp)
801081b4:	e8 90 a8 ff ff       	call   80102a49 <kfree>
      *pte = 0;
801081b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801081bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801081c2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801081c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081cc:	3b 45 0c             	cmp    0xc(%ebp),%eax
801081cf:	0f 82 74 ff ff ff    	jb     80108149 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801081d5:	8b 45 10             	mov    0x10(%ebp),%eax
}
801081d8:	c9                   	leave  
801081d9:	c3                   	ret    

801081da <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801081da:	55                   	push   %ebp
801081db:	89 e5                	mov    %esp,%ebp
801081dd:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801081e0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801081e4:	75 0c                	jne    801081f2 <freevm+0x18>
    panic("freevm: no pgdir");
801081e6:	c7 04 24 43 8b 10 80 	movl   $0x80108b43,(%esp)
801081ed:	e8 48 83 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801081f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801081f9:	00 
801081fa:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108201:	80 
80108202:	8b 45 08             	mov    0x8(%ebp),%eax
80108205:	89 04 24             	mov    %eax,(%esp)
80108208:	e8 11 ff ff ff       	call   8010811e <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010820d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108214:	eb 48                	jmp    8010825e <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108219:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108220:	8b 45 08             	mov    0x8(%ebp),%eax
80108223:	01 d0                	add    %edx,%eax
80108225:	8b 00                	mov    (%eax),%eax
80108227:	83 e0 01             	and    $0x1,%eax
8010822a:	85 c0                	test   %eax,%eax
8010822c:	74 2c                	je     8010825a <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010822e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108231:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108238:	8b 45 08             	mov    0x8(%ebp),%eax
8010823b:	01 d0                	add    %edx,%eax
8010823d:	8b 00                	mov    (%eax),%eax
8010823f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108244:	89 04 24             	mov    %eax,(%esp)
80108247:	e8 6d f4 ff ff       	call   801076b9 <p2v>
8010824c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010824f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108252:	89 04 24             	mov    %eax,(%esp)
80108255:	e8 ef a7 ff ff       	call   80102a49 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010825a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010825e:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108265:	76 af                	jbe    80108216 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108267:	8b 45 08             	mov    0x8(%ebp),%eax
8010826a:	89 04 24             	mov    %eax,(%esp)
8010826d:	e8 d7 a7 ff ff       	call   80102a49 <kfree>
}
80108272:	c9                   	leave  
80108273:	c3                   	ret    

80108274 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108274:	55                   	push   %ebp
80108275:	89 e5                	mov    %esp,%ebp
80108277:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010827a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108281:	00 
80108282:	8b 45 0c             	mov    0xc(%ebp),%eax
80108285:	89 44 24 04          	mov    %eax,0x4(%esp)
80108289:	8b 45 08             	mov    0x8(%ebp),%eax
8010828c:	89 04 24             	mov    %eax,(%esp)
8010828f:	e8 a8 f8 ff ff       	call   80107b3c <walkpgdir>
80108294:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108297:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010829b:	75 0c                	jne    801082a9 <clearpteu+0x35>
    panic("clearpteu");
8010829d:	c7 04 24 54 8b 10 80 	movl   $0x80108b54,(%esp)
801082a4:	e8 91 82 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
801082a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ac:	8b 00                	mov    (%eax),%eax
801082ae:	83 e0 fb             	and    $0xfffffffb,%eax
801082b1:	89 c2                	mov    %eax,%edx
801082b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b6:	89 10                	mov    %edx,(%eax)
}
801082b8:	c9                   	leave  
801082b9:	c3                   	ret    

801082ba <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801082ba:	55                   	push   %ebp
801082bb:	89 e5                	mov    %esp,%ebp
801082bd:	53                   	push   %ebx
801082be:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801082c1:	e8 b0 f9 ff ff       	call   80107c76 <setupkvm>
801082c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801082c9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801082cd:	75 0a                	jne    801082d9 <copyuvm+0x1f>
    return 0;
801082cf:	b8 00 00 00 00       	mov    $0x0,%eax
801082d4:	e9 fd 00 00 00       	jmp    801083d6 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
801082d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801082e0:	e9 d0 00 00 00       	jmp    801083b5 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801082e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801082ef:	00 
801082f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801082f4:	8b 45 08             	mov    0x8(%ebp),%eax
801082f7:	89 04 24             	mov    %eax,(%esp)
801082fa:	e8 3d f8 ff ff       	call   80107b3c <walkpgdir>
801082ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108302:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108306:	75 0c                	jne    80108314 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108308:	c7 04 24 5e 8b 10 80 	movl   $0x80108b5e,(%esp)
8010830f:	e8 26 82 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108314:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108317:	8b 00                	mov    (%eax),%eax
80108319:	83 e0 01             	and    $0x1,%eax
8010831c:	85 c0                	test   %eax,%eax
8010831e:	75 0c                	jne    8010832c <copyuvm+0x72>
      panic("copyuvm: page not present");
80108320:	c7 04 24 78 8b 10 80 	movl   $0x80108b78,(%esp)
80108327:	e8 0e 82 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
8010832c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010832f:	8b 00                	mov    (%eax),%eax
80108331:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108336:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108339:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010833c:	8b 00                	mov    (%eax),%eax
8010833e:	25 ff 0f 00 00       	and    $0xfff,%eax
80108343:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108346:	e8 97 a7 ff ff       	call   80102ae2 <kalloc>
8010834b:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010834e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108352:	75 02                	jne    80108356 <copyuvm+0x9c>
      goto bad;
80108354:	eb 70                	jmp    801083c6 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108356:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108359:	89 04 24             	mov    %eax,(%esp)
8010835c:	e8 58 f3 ff ff       	call   801076b9 <p2v>
80108361:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108368:	00 
80108369:	89 44 24 04          	mov    %eax,0x4(%esp)
8010836d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108370:	89 04 24             	mov    %eax,(%esp)
80108373:	e8 c5 ce ff ff       	call   8010523d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108378:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010837b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010837e:	89 04 24             	mov    %eax,(%esp)
80108381:	e8 26 f3 ff ff       	call   801076ac <v2p>
80108386:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108389:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010838d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108391:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108398:	00 
80108399:	89 54 24 04          	mov    %edx,0x4(%esp)
8010839d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801083a0:	89 04 24             	mov    %eax,(%esp)
801083a3:	e8 36 f8 ff ff       	call   80107bde <mappages>
801083a8:	85 c0                	test   %eax,%eax
801083aa:	79 02                	jns    801083ae <copyuvm+0xf4>
      goto bad;
801083ac:	eb 18                	jmp    801083c6 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801083ae:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801083b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801083bb:	0f 82 24 ff ff ff    	jb     801082e5 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
801083c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801083c4:	eb 10                	jmp    801083d6 <copyuvm+0x11c>

bad:
  freevm(d);
801083c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801083c9:	89 04 24             	mov    %eax,(%esp)
801083cc:	e8 09 fe ff ff       	call   801081da <freevm>
  return 0;
801083d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801083d6:	83 c4 44             	add    $0x44,%esp
801083d9:	5b                   	pop    %ebx
801083da:	5d                   	pop    %ebp
801083db:	c3                   	ret    

801083dc <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801083dc:	55                   	push   %ebp
801083dd:	89 e5                	mov    %esp,%ebp
801083df:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801083e2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083e9:	00 
801083ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801083ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801083f1:	8b 45 08             	mov    0x8(%ebp),%eax
801083f4:	89 04 24             	mov    %eax,(%esp)
801083f7:	e8 40 f7 ff ff       	call   80107b3c <walkpgdir>
801083fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801083ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108402:	8b 00                	mov    (%eax),%eax
80108404:	83 e0 01             	and    $0x1,%eax
80108407:	85 c0                	test   %eax,%eax
80108409:	75 07                	jne    80108412 <uva2ka+0x36>
    return 0;
8010840b:	b8 00 00 00 00       	mov    $0x0,%eax
80108410:	eb 25                	jmp    80108437 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108415:	8b 00                	mov    (%eax),%eax
80108417:	83 e0 04             	and    $0x4,%eax
8010841a:	85 c0                	test   %eax,%eax
8010841c:	75 07                	jne    80108425 <uva2ka+0x49>
    return 0;
8010841e:	b8 00 00 00 00       	mov    $0x0,%eax
80108423:	eb 12                	jmp    80108437 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108428:	8b 00                	mov    (%eax),%eax
8010842a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010842f:	89 04 24             	mov    %eax,(%esp)
80108432:	e8 82 f2 ff ff       	call   801076b9 <p2v>
}
80108437:	c9                   	leave  
80108438:	c3                   	ret    

80108439 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108439:	55                   	push   %ebp
8010843a:	89 e5                	mov    %esp,%ebp
8010843c:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010843f:	8b 45 10             	mov    0x10(%ebp),%eax
80108442:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108445:	e9 87 00 00 00       	jmp    801084d1 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010844a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010844d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108452:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108455:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108458:	89 44 24 04          	mov    %eax,0x4(%esp)
8010845c:	8b 45 08             	mov    0x8(%ebp),%eax
8010845f:	89 04 24             	mov    %eax,(%esp)
80108462:	e8 75 ff ff ff       	call   801083dc <uva2ka>
80108467:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010846a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010846e:	75 07                	jne    80108477 <copyout+0x3e>
      return -1;
80108470:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108475:	eb 69                	jmp    801084e0 <copyout+0xa7>
    n = PGSIZE - (va - va0);
80108477:	8b 45 0c             	mov    0xc(%ebp),%eax
8010847a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010847d:	29 c2                	sub    %eax,%edx
8010847f:	89 d0                	mov    %edx,%eax
80108481:	05 00 10 00 00       	add    $0x1000,%eax
80108486:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108489:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010848c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010848f:	76 06                	jbe    80108497 <copyout+0x5e>
      n = len;
80108491:	8b 45 14             	mov    0x14(%ebp),%eax
80108494:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108497:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010849a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010849d:	29 c2                	sub    %eax,%edx
8010849f:	8b 45 e8             	mov    -0x18(%ebp),%eax
801084a2:	01 c2                	add    %eax,%edx
801084a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801084ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801084b2:	89 14 24             	mov    %edx,(%esp)
801084b5:	e8 83 cd ff ff       	call   8010523d <memmove>
    len -= n;
801084ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084bd:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801084c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084c3:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801084c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801084c9:	05 00 10 00 00       	add    $0x1000,%eax
801084ce:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801084d1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801084d5:	0f 85 6f ff ff ff    	jne    8010844a <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801084db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801084e0:	c9                   	leave  
801084e1:	c3                   	ret    
