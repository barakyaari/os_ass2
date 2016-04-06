
_test:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "types.h"
#include "user.h"

int
main(int argc, char *argv[]){
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 10             	sub    $0x10,%esp
    printf(1, "     Welcome to Testing File!!!\n");
   9:	c7 44 24 04 ec 07 00 	movl   $0x7ec,0x4(%esp)
  10:	00 
  11:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  18:	e8 01 04 00 00       	call   41e <printf>
    printf(1, "*************************************\n");
  1d:	c7 44 24 04 10 08 00 	movl   $0x810,0x4(%esp)
  24:	00 
  25:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  2c:	e8 ed 03 00 00       	call   41e <printf>

    exit();
  31:	e8 68 02 00 00       	call   29e <exit>

00000036 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  36:	55                   	push   %ebp
  37:	89 e5                	mov    %esp,%ebp
  39:	57                   	push   %edi
  3a:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  3e:	8b 55 10             	mov    0x10(%ebp),%edx
  41:	8b 45 0c             	mov    0xc(%ebp),%eax
  44:	89 cb                	mov    %ecx,%ebx
  46:	89 df                	mov    %ebx,%edi
  48:	89 d1                	mov    %edx,%ecx
  4a:	fc                   	cld    
  4b:	f3 aa                	rep stos %al,%es:(%edi)
  4d:	89 ca                	mov    %ecx,%edx
  4f:	89 fb                	mov    %edi,%ebx
  51:	89 5d 08             	mov    %ebx,0x8(%ebp)
  54:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  57:	5b                   	pop    %ebx
  58:	5f                   	pop    %edi
  59:	5d                   	pop    %ebp
  5a:	c3                   	ret    

0000005b <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  5b:	55                   	push   %ebp
  5c:	89 e5                	mov    %esp,%ebp
  5e:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  61:	8b 45 08             	mov    0x8(%ebp),%eax
  64:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  67:	90                   	nop
  68:	8b 45 08             	mov    0x8(%ebp),%eax
  6b:	8d 50 01             	lea    0x1(%eax),%edx
  6e:	89 55 08             	mov    %edx,0x8(%ebp)
  71:	8b 55 0c             	mov    0xc(%ebp),%edx
  74:	8d 4a 01             	lea    0x1(%edx),%ecx
  77:	89 4d 0c             	mov    %ecx,0xc(%ebp)
  7a:	0f b6 12             	movzbl (%edx),%edx
  7d:	88 10                	mov    %dl,(%eax)
  7f:	0f b6 00             	movzbl (%eax),%eax
  82:	84 c0                	test   %al,%al
  84:	75 e2                	jne    68 <strcpy+0xd>
    ;
  return os;
  86:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  89:	c9                   	leave  
  8a:	c3                   	ret    

0000008b <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8b:	55                   	push   %ebp
  8c:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  8e:	eb 08                	jmp    98 <strcmp+0xd>
    p++, q++;
  90:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  94:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  98:	8b 45 08             	mov    0x8(%ebp),%eax
  9b:	0f b6 00             	movzbl (%eax),%eax
  9e:	84 c0                	test   %al,%al
  a0:	74 10                	je     b2 <strcmp+0x27>
  a2:	8b 45 08             	mov    0x8(%ebp),%eax
  a5:	0f b6 10             	movzbl (%eax),%edx
  a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  ab:	0f b6 00             	movzbl (%eax),%eax
  ae:	38 c2                	cmp    %al,%dl
  b0:	74 de                	je     90 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  b2:	8b 45 08             	mov    0x8(%ebp),%eax
  b5:	0f b6 00             	movzbl (%eax),%eax
  b8:	0f b6 d0             	movzbl %al,%edx
  bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  be:	0f b6 00             	movzbl (%eax),%eax
  c1:	0f b6 c0             	movzbl %al,%eax
  c4:	29 c2                	sub    %eax,%edx
  c6:	89 d0                	mov    %edx,%eax
}
  c8:	5d                   	pop    %ebp
  c9:	c3                   	ret    

000000ca <strlen>:

uint
strlen(char *s)
{
  ca:	55                   	push   %ebp
  cb:	89 e5                	mov    %esp,%ebp
  cd:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
  d0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  d7:	eb 04                	jmp    dd <strlen+0x13>
  d9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  dd:	8b 55 fc             	mov    -0x4(%ebp),%edx
  e0:	8b 45 08             	mov    0x8(%ebp),%eax
  e3:	01 d0                	add    %edx,%eax
  e5:	0f b6 00             	movzbl (%eax),%eax
  e8:	84 c0                	test   %al,%al
  ea:	75 ed                	jne    d9 <strlen+0xf>
    ;
  return n;
  ec:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  ef:	c9                   	leave  
  f0:	c3                   	ret    

000000f1 <memset>:

void*
memset(void *dst, int c, uint n)
{
  f1:	55                   	push   %ebp
  f2:	89 e5                	mov    %esp,%ebp
  f4:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
  f7:	8b 45 10             	mov    0x10(%ebp),%eax
  fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  fe:	8b 45 0c             	mov    0xc(%ebp),%eax
 101:	89 44 24 04          	mov    %eax,0x4(%esp)
 105:	8b 45 08             	mov    0x8(%ebp),%eax
 108:	89 04 24             	mov    %eax,(%esp)
 10b:	e8 26 ff ff ff       	call   36 <stosb>
  return dst;
 110:	8b 45 08             	mov    0x8(%ebp),%eax
}
 113:	c9                   	leave  
 114:	c3                   	ret    

00000115 <strchr>:

char*
strchr(const char *s, char c)
{
 115:	55                   	push   %ebp
 116:	89 e5                	mov    %esp,%ebp
 118:	83 ec 04             	sub    $0x4,%esp
 11b:	8b 45 0c             	mov    0xc(%ebp),%eax
 11e:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 121:	eb 14                	jmp    137 <strchr+0x22>
    if(*s == c)
 123:	8b 45 08             	mov    0x8(%ebp),%eax
 126:	0f b6 00             	movzbl (%eax),%eax
 129:	3a 45 fc             	cmp    -0x4(%ebp),%al
 12c:	75 05                	jne    133 <strchr+0x1e>
      return (char*)s;
 12e:	8b 45 08             	mov    0x8(%ebp),%eax
 131:	eb 13                	jmp    146 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 133:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 137:	8b 45 08             	mov    0x8(%ebp),%eax
 13a:	0f b6 00             	movzbl (%eax),%eax
 13d:	84 c0                	test   %al,%al
 13f:	75 e2                	jne    123 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 141:	b8 00 00 00 00       	mov    $0x0,%eax
}
 146:	c9                   	leave  
 147:	c3                   	ret    

00000148 <gets>:

char*
gets(char *buf, int max)
{
 148:	55                   	push   %ebp
 149:	89 e5                	mov    %esp,%ebp
 14b:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 155:	eb 4c                	jmp    1a3 <gets+0x5b>
    cc = read(0, &c, 1);
 157:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 15e:	00 
 15f:	8d 45 ef             	lea    -0x11(%ebp),%eax
 162:	89 44 24 04          	mov    %eax,0x4(%esp)
 166:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 16d:	e8 44 01 00 00       	call   2b6 <read>
 172:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 175:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 179:	7f 02                	jg     17d <gets+0x35>
      break;
 17b:	eb 31                	jmp    1ae <gets+0x66>
    buf[i++] = c;
 17d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 180:	8d 50 01             	lea    0x1(%eax),%edx
 183:	89 55 f4             	mov    %edx,-0xc(%ebp)
 186:	89 c2                	mov    %eax,%edx
 188:	8b 45 08             	mov    0x8(%ebp),%eax
 18b:	01 c2                	add    %eax,%edx
 18d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 191:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 193:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 197:	3c 0a                	cmp    $0xa,%al
 199:	74 13                	je     1ae <gets+0x66>
 19b:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 19f:	3c 0d                	cmp    $0xd,%al
 1a1:	74 0b                	je     1ae <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1a6:	83 c0 01             	add    $0x1,%eax
 1a9:	3b 45 0c             	cmp    0xc(%ebp),%eax
 1ac:	7c a9                	jl     157 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 1ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
 1b1:	8b 45 08             	mov    0x8(%ebp),%eax
 1b4:	01 d0                	add    %edx,%eax
 1b6:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1b9:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1bc:	c9                   	leave  
 1bd:	c3                   	ret    

000001be <stat>:

int
stat(char *n, struct stat *st)
{
 1be:	55                   	push   %ebp
 1bf:	89 e5                	mov    %esp,%ebp
 1c1:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1cb:	00 
 1cc:	8b 45 08             	mov    0x8(%ebp),%eax
 1cf:	89 04 24             	mov    %eax,(%esp)
 1d2:	e8 07 01 00 00       	call   2de <open>
 1d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 1da:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 1de:	79 07                	jns    1e7 <stat+0x29>
    return -1;
 1e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 1e5:	eb 23                	jmp    20a <stat+0x4c>
  r = fstat(fd, st);
 1e7:	8b 45 0c             	mov    0xc(%ebp),%eax
 1ea:	89 44 24 04          	mov    %eax,0x4(%esp)
 1ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1f1:	89 04 24             	mov    %eax,(%esp)
 1f4:	e8 fd 00 00 00       	call   2f6 <fstat>
 1f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 1fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1ff:	89 04 24             	mov    %eax,(%esp)
 202:	e8 bf 00 00 00       	call   2c6 <close>
  return r;
 207:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 20a:	c9                   	leave  
 20b:	c3                   	ret    

0000020c <atoi>:

int
atoi(const char *s)
{
 20c:	55                   	push   %ebp
 20d:	89 e5                	mov    %esp,%ebp
 20f:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 212:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 219:	eb 25                	jmp    240 <atoi+0x34>
    n = n*10 + *s++ - '0';
 21b:	8b 55 fc             	mov    -0x4(%ebp),%edx
 21e:	89 d0                	mov    %edx,%eax
 220:	c1 e0 02             	shl    $0x2,%eax
 223:	01 d0                	add    %edx,%eax
 225:	01 c0                	add    %eax,%eax
 227:	89 c1                	mov    %eax,%ecx
 229:	8b 45 08             	mov    0x8(%ebp),%eax
 22c:	8d 50 01             	lea    0x1(%eax),%edx
 22f:	89 55 08             	mov    %edx,0x8(%ebp)
 232:	0f b6 00             	movzbl (%eax),%eax
 235:	0f be c0             	movsbl %al,%eax
 238:	01 c8                	add    %ecx,%eax
 23a:	83 e8 30             	sub    $0x30,%eax
 23d:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 240:	8b 45 08             	mov    0x8(%ebp),%eax
 243:	0f b6 00             	movzbl (%eax),%eax
 246:	3c 2f                	cmp    $0x2f,%al
 248:	7e 0a                	jle    254 <atoi+0x48>
 24a:	8b 45 08             	mov    0x8(%ebp),%eax
 24d:	0f b6 00             	movzbl (%eax),%eax
 250:	3c 39                	cmp    $0x39,%al
 252:	7e c7                	jle    21b <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 254:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 257:	c9                   	leave  
 258:	c3                   	ret    

00000259 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 259:	55                   	push   %ebp
 25a:	89 e5                	mov    %esp,%ebp
 25c:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 25f:	8b 45 08             	mov    0x8(%ebp),%eax
 262:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 265:	8b 45 0c             	mov    0xc(%ebp),%eax
 268:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 26b:	eb 17                	jmp    284 <memmove+0x2b>
    *dst++ = *src++;
 26d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 270:	8d 50 01             	lea    0x1(%eax),%edx
 273:	89 55 fc             	mov    %edx,-0x4(%ebp)
 276:	8b 55 f8             	mov    -0x8(%ebp),%edx
 279:	8d 4a 01             	lea    0x1(%edx),%ecx
 27c:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 27f:	0f b6 12             	movzbl (%edx),%edx
 282:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 284:	8b 45 10             	mov    0x10(%ebp),%eax
 287:	8d 50 ff             	lea    -0x1(%eax),%edx
 28a:	89 55 10             	mov    %edx,0x10(%ebp)
 28d:	85 c0                	test   %eax,%eax
 28f:	7f dc                	jg     26d <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 291:	8b 45 08             	mov    0x8(%ebp),%eax
}
 294:	c9                   	leave  
 295:	c3                   	ret    

00000296 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 296:	b8 01 00 00 00       	mov    $0x1,%eax
 29b:	cd 40                	int    $0x40
 29d:	c3                   	ret    

0000029e <exit>:
SYSCALL(exit)
 29e:	b8 02 00 00 00       	mov    $0x2,%eax
 2a3:	cd 40                	int    $0x40
 2a5:	c3                   	ret    

000002a6 <wait>:
SYSCALL(wait)
 2a6:	b8 03 00 00 00       	mov    $0x3,%eax
 2ab:	cd 40                	int    $0x40
 2ad:	c3                   	ret    

000002ae <pipe>:
SYSCALL(pipe)
 2ae:	b8 04 00 00 00       	mov    $0x4,%eax
 2b3:	cd 40                	int    $0x40
 2b5:	c3                   	ret    

000002b6 <read>:
SYSCALL(read)
 2b6:	b8 05 00 00 00       	mov    $0x5,%eax
 2bb:	cd 40                	int    $0x40
 2bd:	c3                   	ret    

000002be <write>:
SYSCALL(write)
 2be:	b8 10 00 00 00       	mov    $0x10,%eax
 2c3:	cd 40                	int    $0x40
 2c5:	c3                   	ret    

000002c6 <close>:
SYSCALL(close)
 2c6:	b8 15 00 00 00       	mov    $0x15,%eax
 2cb:	cd 40                	int    $0x40
 2cd:	c3                   	ret    

000002ce <kill>:
SYSCALL(kill)
 2ce:	b8 06 00 00 00       	mov    $0x6,%eax
 2d3:	cd 40                	int    $0x40
 2d5:	c3                   	ret    

000002d6 <exec>:
SYSCALL(exec)
 2d6:	b8 07 00 00 00       	mov    $0x7,%eax
 2db:	cd 40                	int    $0x40
 2dd:	c3                   	ret    

000002de <open>:
SYSCALL(open)
 2de:	b8 0f 00 00 00       	mov    $0xf,%eax
 2e3:	cd 40                	int    $0x40
 2e5:	c3                   	ret    

000002e6 <mknod>:
SYSCALL(mknod)
 2e6:	b8 11 00 00 00       	mov    $0x11,%eax
 2eb:	cd 40                	int    $0x40
 2ed:	c3                   	ret    

000002ee <unlink>:
SYSCALL(unlink)
 2ee:	b8 12 00 00 00       	mov    $0x12,%eax
 2f3:	cd 40                	int    $0x40
 2f5:	c3                   	ret    

000002f6 <fstat>:
SYSCALL(fstat)
 2f6:	b8 08 00 00 00       	mov    $0x8,%eax
 2fb:	cd 40                	int    $0x40
 2fd:	c3                   	ret    

000002fe <link>:
SYSCALL(link)
 2fe:	b8 13 00 00 00       	mov    $0x13,%eax
 303:	cd 40                	int    $0x40
 305:	c3                   	ret    

00000306 <mkdir>:
SYSCALL(mkdir)
 306:	b8 14 00 00 00       	mov    $0x14,%eax
 30b:	cd 40                	int    $0x40
 30d:	c3                   	ret    

0000030e <chdir>:
SYSCALL(chdir)
 30e:	b8 09 00 00 00       	mov    $0x9,%eax
 313:	cd 40                	int    $0x40
 315:	c3                   	ret    

00000316 <dup>:
SYSCALL(dup)
 316:	b8 0a 00 00 00       	mov    $0xa,%eax
 31b:	cd 40                	int    $0x40
 31d:	c3                   	ret    

0000031e <getpid>:
SYSCALL(getpid)
 31e:	b8 0b 00 00 00       	mov    $0xb,%eax
 323:	cd 40                	int    $0x40
 325:	c3                   	ret    

00000326 <sbrk>:
SYSCALL(sbrk)
 326:	b8 0c 00 00 00       	mov    $0xc,%eax
 32b:	cd 40                	int    $0x40
 32d:	c3                   	ret    

0000032e <sleep>:
SYSCALL(sleep)
 32e:	b8 0d 00 00 00       	mov    $0xd,%eax
 333:	cd 40                	int    $0x40
 335:	c3                   	ret    

00000336 <uptime>:
SYSCALL(uptime)
 336:	b8 0e 00 00 00       	mov    $0xe,%eax
 33b:	cd 40                	int    $0x40
 33d:	c3                   	ret    

0000033e <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 33e:	55                   	push   %ebp
 33f:	89 e5                	mov    %esp,%ebp
 341:	83 ec 18             	sub    $0x18,%esp
 344:	8b 45 0c             	mov    0xc(%ebp),%eax
 347:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 34a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 351:	00 
 352:	8d 45 f4             	lea    -0xc(%ebp),%eax
 355:	89 44 24 04          	mov    %eax,0x4(%esp)
 359:	8b 45 08             	mov    0x8(%ebp),%eax
 35c:	89 04 24             	mov    %eax,(%esp)
 35f:	e8 5a ff ff ff       	call   2be <write>
}
 364:	c9                   	leave  
 365:	c3                   	ret    

00000366 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 366:	55                   	push   %ebp
 367:	89 e5                	mov    %esp,%ebp
 369:	56                   	push   %esi
 36a:	53                   	push   %ebx
 36b:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 36e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 375:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 379:	74 17                	je     392 <printint+0x2c>
 37b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 37f:	79 11                	jns    392 <printint+0x2c>
    neg = 1;
 381:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 388:	8b 45 0c             	mov    0xc(%ebp),%eax
 38b:	f7 d8                	neg    %eax
 38d:	89 45 ec             	mov    %eax,-0x14(%ebp)
 390:	eb 06                	jmp    398 <printint+0x32>
  } else {
    x = xx;
 392:	8b 45 0c             	mov    0xc(%ebp),%eax
 395:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 398:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 39f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 3a2:	8d 41 01             	lea    0x1(%ecx),%eax
 3a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
 3a8:	8b 5d 10             	mov    0x10(%ebp),%ebx
 3ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3ae:	ba 00 00 00 00       	mov    $0x0,%edx
 3b3:	f7 f3                	div    %ebx
 3b5:	89 d0                	mov    %edx,%eax
 3b7:	0f b6 80 84 0a 00 00 	movzbl 0xa84(%eax),%eax
 3be:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 3c2:	8b 75 10             	mov    0x10(%ebp),%esi
 3c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3c8:	ba 00 00 00 00       	mov    $0x0,%edx
 3cd:	f7 f6                	div    %esi
 3cf:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3d2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 3d6:	75 c7                	jne    39f <printint+0x39>
  if(neg)
 3d8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 3dc:	74 10                	je     3ee <printint+0x88>
    buf[i++] = '-';
 3de:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3e1:	8d 50 01             	lea    0x1(%eax),%edx
 3e4:	89 55 f4             	mov    %edx,-0xc(%ebp)
 3e7:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 3ec:	eb 1f                	jmp    40d <printint+0xa7>
 3ee:	eb 1d                	jmp    40d <printint+0xa7>
    putc(fd, buf[i]);
 3f0:	8d 55 dc             	lea    -0x24(%ebp),%edx
 3f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 3f6:	01 d0                	add    %edx,%eax
 3f8:	0f b6 00             	movzbl (%eax),%eax
 3fb:	0f be c0             	movsbl %al,%eax
 3fe:	89 44 24 04          	mov    %eax,0x4(%esp)
 402:	8b 45 08             	mov    0x8(%ebp),%eax
 405:	89 04 24             	mov    %eax,(%esp)
 408:	e8 31 ff ff ff       	call   33e <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 40d:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 411:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 415:	79 d9                	jns    3f0 <printint+0x8a>
    putc(fd, buf[i]);
}
 417:	83 c4 30             	add    $0x30,%esp
 41a:	5b                   	pop    %ebx
 41b:	5e                   	pop    %esi
 41c:	5d                   	pop    %ebp
 41d:	c3                   	ret    

0000041e <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 41e:	55                   	push   %ebp
 41f:	89 e5                	mov    %esp,%ebp
 421:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 424:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 42b:	8d 45 0c             	lea    0xc(%ebp),%eax
 42e:	83 c0 04             	add    $0x4,%eax
 431:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 434:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 43b:	e9 7c 01 00 00       	jmp    5bc <printf+0x19e>
    c = fmt[i] & 0xff;
 440:	8b 55 0c             	mov    0xc(%ebp),%edx
 443:	8b 45 f0             	mov    -0x10(%ebp),%eax
 446:	01 d0                	add    %edx,%eax
 448:	0f b6 00             	movzbl (%eax),%eax
 44b:	0f be c0             	movsbl %al,%eax
 44e:	25 ff 00 00 00       	and    $0xff,%eax
 453:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 456:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 45a:	75 2c                	jne    488 <printf+0x6a>
      if(c == '%'){
 45c:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 460:	75 0c                	jne    46e <printf+0x50>
        state = '%';
 462:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 469:	e9 4a 01 00 00       	jmp    5b8 <printf+0x19a>
      } else {
        putc(fd, c);
 46e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 471:	0f be c0             	movsbl %al,%eax
 474:	89 44 24 04          	mov    %eax,0x4(%esp)
 478:	8b 45 08             	mov    0x8(%ebp),%eax
 47b:	89 04 24             	mov    %eax,(%esp)
 47e:	e8 bb fe ff ff       	call   33e <putc>
 483:	e9 30 01 00 00       	jmp    5b8 <printf+0x19a>
      }
    } else if(state == '%'){
 488:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 48c:	0f 85 26 01 00 00    	jne    5b8 <printf+0x19a>
      if(c == 'd'){
 492:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 496:	75 2d                	jne    4c5 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 498:	8b 45 e8             	mov    -0x18(%ebp),%eax
 49b:	8b 00                	mov    (%eax),%eax
 49d:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 4a4:	00 
 4a5:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 4ac:	00 
 4ad:	89 44 24 04          	mov    %eax,0x4(%esp)
 4b1:	8b 45 08             	mov    0x8(%ebp),%eax
 4b4:	89 04 24             	mov    %eax,(%esp)
 4b7:	e8 aa fe ff ff       	call   366 <printint>
        ap++;
 4bc:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4c0:	e9 ec 00 00 00       	jmp    5b1 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 4c5:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4c9:	74 06                	je     4d1 <printf+0xb3>
 4cb:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4cf:	75 2d                	jne    4fe <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4d1:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4d4:	8b 00                	mov    (%eax),%eax
 4d6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 4dd:	00 
 4de:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 4e5:	00 
 4e6:	89 44 24 04          	mov    %eax,0x4(%esp)
 4ea:	8b 45 08             	mov    0x8(%ebp),%eax
 4ed:	89 04 24             	mov    %eax,(%esp)
 4f0:	e8 71 fe ff ff       	call   366 <printint>
        ap++;
 4f5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4f9:	e9 b3 00 00 00       	jmp    5b1 <printf+0x193>
      } else if(c == 's'){
 4fe:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 502:	75 45                	jne    549 <printf+0x12b>
        s = (char*)*ap;
 504:	8b 45 e8             	mov    -0x18(%ebp),%eax
 507:	8b 00                	mov    (%eax),%eax
 509:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 50c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 510:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 514:	75 09                	jne    51f <printf+0x101>
          s = "(null)";
 516:	c7 45 f4 37 08 00 00 	movl   $0x837,-0xc(%ebp)
        while(*s != 0){
 51d:	eb 1e                	jmp    53d <printf+0x11f>
 51f:	eb 1c                	jmp    53d <printf+0x11f>
          putc(fd, *s);
 521:	8b 45 f4             	mov    -0xc(%ebp),%eax
 524:	0f b6 00             	movzbl (%eax),%eax
 527:	0f be c0             	movsbl %al,%eax
 52a:	89 44 24 04          	mov    %eax,0x4(%esp)
 52e:	8b 45 08             	mov    0x8(%ebp),%eax
 531:	89 04 24             	mov    %eax,(%esp)
 534:	e8 05 fe ff ff       	call   33e <putc>
          s++;
 539:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 53d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 540:	0f b6 00             	movzbl (%eax),%eax
 543:	84 c0                	test   %al,%al
 545:	75 da                	jne    521 <printf+0x103>
 547:	eb 68                	jmp    5b1 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 549:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 54d:	75 1d                	jne    56c <printf+0x14e>
        putc(fd, *ap);
 54f:	8b 45 e8             	mov    -0x18(%ebp),%eax
 552:	8b 00                	mov    (%eax),%eax
 554:	0f be c0             	movsbl %al,%eax
 557:	89 44 24 04          	mov    %eax,0x4(%esp)
 55b:	8b 45 08             	mov    0x8(%ebp),%eax
 55e:	89 04 24             	mov    %eax,(%esp)
 561:	e8 d8 fd ff ff       	call   33e <putc>
        ap++;
 566:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 56a:	eb 45                	jmp    5b1 <printf+0x193>
      } else if(c == '%'){
 56c:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 570:	75 17                	jne    589 <printf+0x16b>
        putc(fd, c);
 572:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 575:	0f be c0             	movsbl %al,%eax
 578:	89 44 24 04          	mov    %eax,0x4(%esp)
 57c:	8b 45 08             	mov    0x8(%ebp),%eax
 57f:	89 04 24             	mov    %eax,(%esp)
 582:	e8 b7 fd ff ff       	call   33e <putc>
 587:	eb 28                	jmp    5b1 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 589:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 590:	00 
 591:	8b 45 08             	mov    0x8(%ebp),%eax
 594:	89 04 24             	mov    %eax,(%esp)
 597:	e8 a2 fd ff ff       	call   33e <putc>
        putc(fd, c);
 59c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 59f:	0f be c0             	movsbl %al,%eax
 5a2:	89 44 24 04          	mov    %eax,0x4(%esp)
 5a6:	8b 45 08             	mov    0x8(%ebp),%eax
 5a9:	89 04 24             	mov    %eax,(%esp)
 5ac:	e8 8d fd ff ff       	call   33e <putc>
      }
      state = 0;
 5b1:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5b8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5bc:	8b 55 0c             	mov    0xc(%ebp),%edx
 5bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5c2:	01 d0                	add    %edx,%eax
 5c4:	0f b6 00             	movzbl (%eax),%eax
 5c7:	84 c0                	test   %al,%al
 5c9:	0f 85 71 fe ff ff    	jne    440 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5cf:	c9                   	leave  
 5d0:	c3                   	ret    

000005d1 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5d1:	55                   	push   %ebp
 5d2:	89 e5                	mov    %esp,%ebp
 5d4:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5d7:	8b 45 08             	mov    0x8(%ebp),%eax
 5da:	83 e8 08             	sub    $0x8,%eax
 5dd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5e0:	a1 a0 0a 00 00       	mov    0xaa0,%eax
 5e5:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5e8:	eb 24                	jmp    60e <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5ed:	8b 00                	mov    (%eax),%eax
 5ef:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5f2:	77 12                	ja     606 <free+0x35>
 5f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5f7:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5fa:	77 24                	ja     620 <free+0x4f>
 5fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5ff:	8b 00                	mov    (%eax),%eax
 601:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 604:	77 1a                	ja     620 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 606:	8b 45 fc             	mov    -0x4(%ebp),%eax
 609:	8b 00                	mov    (%eax),%eax
 60b:	89 45 fc             	mov    %eax,-0x4(%ebp)
 60e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 611:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 614:	76 d4                	jbe    5ea <free+0x19>
 616:	8b 45 fc             	mov    -0x4(%ebp),%eax
 619:	8b 00                	mov    (%eax),%eax
 61b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 61e:	76 ca                	jbe    5ea <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 620:	8b 45 f8             	mov    -0x8(%ebp),%eax
 623:	8b 40 04             	mov    0x4(%eax),%eax
 626:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 62d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 630:	01 c2                	add    %eax,%edx
 632:	8b 45 fc             	mov    -0x4(%ebp),%eax
 635:	8b 00                	mov    (%eax),%eax
 637:	39 c2                	cmp    %eax,%edx
 639:	75 24                	jne    65f <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 63b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 63e:	8b 50 04             	mov    0x4(%eax),%edx
 641:	8b 45 fc             	mov    -0x4(%ebp),%eax
 644:	8b 00                	mov    (%eax),%eax
 646:	8b 40 04             	mov    0x4(%eax),%eax
 649:	01 c2                	add    %eax,%edx
 64b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 64e:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 651:	8b 45 fc             	mov    -0x4(%ebp),%eax
 654:	8b 00                	mov    (%eax),%eax
 656:	8b 10                	mov    (%eax),%edx
 658:	8b 45 f8             	mov    -0x8(%ebp),%eax
 65b:	89 10                	mov    %edx,(%eax)
 65d:	eb 0a                	jmp    669 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 65f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 662:	8b 10                	mov    (%eax),%edx
 664:	8b 45 f8             	mov    -0x8(%ebp),%eax
 667:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 669:	8b 45 fc             	mov    -0x4(%ebp),%eax
 66c:	8b 40 04             	mov    0x4(%eax),%eax
 66f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 676:	8b 45 fc             	mov    -0x4(%ebp),%eax
 679:	01 d0                	add    %edx,%eax
 67b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 67e:	75 20                	jne    6a0 <free+0xcf>
    p->s.size += bp->s.size;
 680:	8b 45 fc             	mov    -0x4(%ebp),%eax
 683:	8b 50 04             	mov    0x4(%eax),%edx
 686:	8b 45 f8             	mov    -0x8(%ebp),%eax
 689:	8b 40 04             	mov    0x4(%eax),%eax
 68c:	01 c2                	add    %eax,%edx
 68e:	8b 45 fc             	mov    -0x4(%ebp),%eax
 691:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 694:	8b 45 f8             	mov    -0x8(%ebp),%eax
 697:	8b 10                	mov    (%eax),%edx
 699:	8b 45 fc             	mov    -0x4(%ebp),%eax
 69c:	89 10                	mov    %edx,(%eax)
 69e:	eb 08                	jmp    6a8 <free+0xd7>
  } else
    p->s.ptr = bp;
 6a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a3:	8b 55 f8             	mov    -0x8(%ebp),%edx
 6a6:	89 10                	mov    %edx,(%eax)
  freep = p;
 6a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ab:	a3 a0 0a 00 00       	mov    %eax,0xaa0
}
 6b0:	c9                   	leave  
 6b1:	c3                   	ret    

000006b2 <morecore>:

static Header*
morecore(uint nu)
{
 6b2:	55                   	push   %ebp
 6b3:	89 e5                	mov    %esp,%ebp
 6b5:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 6b8:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6bf:	77 07                	ja     6c8 <morecore+0x16>
    nu = 4096;
 6c1:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6c8:	8b 45 08             	mov    0x8(%ebp),%eax
 6cb:	c1 e0 03             	shl    $0x3,%eax
 6ce:	89 04 24             	mov    %eax,(%esp)
 6d1:	e8 50 fc ff ff       	call   326 <sbrk>
 6d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 6d9:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 6dd:	75 07                	jne    6e6 <morecore+0x34>
    return 0;
 6df:	b8 00 00 00 00       	mov    $0x0,%eax
 6e4:	eb 22                	jmp    708 <morecore+0x56>
  hp = (Header*)p;
 6e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 6ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6ef:	8b 55 08             	mov    0x8(%ebp),%edx
 6f2:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 6f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6f8:	83 c0 08             	add    $0x8,%eax
 6fb:	89 04 24             	mov    %eax,(%esp)
 6fe:	e8 ce fe ff ff       	call   5d1 <free>
  return freep;
 703:	a1 a0 0a 00 00       	mov    0xaa0,%eax
}
 708:	c9                   	leave  
 709:	c3                   	ret    

0000070a <malloc>:

void*
malloc(uint nbytes)
{
 70a:	55                   	push   %ebp
 70b:	89 e5                	mov    %esp,%ebp
 70d:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 710:	8b 45 08             	mov    0x8(%ebp),%eax
 713:	83 c0 07             	add    $0x7,%eax
 716:	c1 e8 03             	shr    $0x3,%eax
 719:	83 c0 01             	add    $0x1,%eax
 71c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 71f:	a1 a0 0a 00 00       	mov    0xaa0,%eax
 724:	89 45 f0             	mov    %eax,-0x10(%ebp)
 727:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 72b:	75 23                	jne    750 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 72d:	c7 45 f0 98 0a 00 00 	movl   $0xa98,-0x10(%ebp)
 734:	8b 45 f0             	mov    -0x10(%ebp),%eax
 737:	a3 a0 0a 00 00       	mov    %eax,0xaa0
 73c:	a1 a0 0a 00 00       	mov    0xaa0,%eax
 741:	a3 98 0a 00 00       	mov    %eax,0xa98
    base.s.size = 0;
 746:	c7 05 9c 0a 00 00 00 	movl   $0x0,0xa9c
 74d:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 750:	8b 45 f0             	mov    -0x10(%ebp),%eax
 753:	8b 00                	mov    (%eax),%eax
 755:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 758:	8b 45 f4             	mov    -0xc(%ebp),%eax
 75b:	8b 40 04             	mov    0x4(%eax),%eax
 75e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 761:	72 4d                	jb     7b0 <malloc+0xa6>
      if(p->s.size == nunits)
 763:	8b 45 f4             	mov    -0xc(%ebp),%eax
 766:	8b 40 04             	mov    0x4(%eax),%eax
 769:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 76c:	75 0c                	jne    77a <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 76e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 771:	8b 10                	mov    (%eax),%edx
 773:	8b 45 f0             	mov    -0x10(%ebp),%eax
 776:	89 10                	mov    %edx,(%eax)
 778:	eb 26                	jmp    7a0 <malloc+0x96>
      else {
        p->s.size -= nunits;
 77a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 77d:	8b 40 04             	mov    0x4(%eax),%eax
 780:	2b 45 ec             	sub    -0x14(%ebp),%eax
 783:	89 c2                	mov    %eax,%edx
 785:	8b 45 f4             	mov    -0xc(%ebp),%eax
 788:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 78b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 78e:	8b 40 04             	mov    0x4(%eax),%eax
 791:	c1 e0 03             	shl    $0x3,%eax
 794:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 797:	8b 45 f4             	mov    -0xc(%ebp),%eax
 79a:	8b 55 ec             	mov    -0x14(%ebp),%edx
 79d:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 7a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7a3:	a3 a0 0a 00 00       	mov    %eax,0xaa0
      return (void*)(p + 1);
 7a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7ab:	83 c0 08             	add    $0x8,%eax
 7ae:	eb 38                	jmp    7e8 <malloc+0xde>
    }
    if(p == freep)
 7b0:	a1 a0 0a 00 00       	mov    0xaa0,%eax
 7b5:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 7b8:	75 1b                	jne    7d5 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 7ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7bd:	89 04 24             	mov    %eax,(%esp)
 7c0:	e8 ed fe ff ff       	call   6b2 <morecore>
 7c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7c8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7cc:	75 07                	jne    7d5 <malloc+0xcb>
        return 0;
 7ce:	b8 00 00 00 00       	mov    $0x0,%eax
 7d3:	eb 13                	jmp    7e8 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7db:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7de:	8b 00                	mov    (%eax),%eax
 7e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 7e3:	e9 70 ff ff ff       	jmp    758 <malloc+0x4e>
}
 7e8:	c9                   	leave  
 7e9:	c3                   	ret    
