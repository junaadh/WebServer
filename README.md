## Web Server - TCP server in arm64 asm
 * written in arm64 assembly
 * tested on apple silicon
 * uses unix libc functions
 * enforces stack integrity

### instructions

 * clone and cd into directory
 * compile and run
```shell
as -o server.o server.s
ld -o server server.o
./server
```
 * now server will be listening on port 6969
 * you can visit http://localhost:6969 or http://127.0.01:6969
