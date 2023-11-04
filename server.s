        .equ    SYS_WRITE,   4
        .equ    SYS_EXIT,    1
        .equ    SYS_SOCKET,  97
        .equ    SYS_BIND,    104
        .equ    SYS_LISTEN,  106
        .equ    SYS_ACCEPT,  30
        .equ    SYS_CLOSE,   6

        .equ    STDOUT,      1
        .equ    STDERR,      2

        .equ    PF_INET,     2
        .equ    SOCK_STREAM, 1 
        /* port number 6969 in lil endian */
        .equ    PORT,        14619
        .equ    INADDR_ANY,  0
        .equ    BACKLOG,     5

.macro  write  fd,  buf, count
        mov    x0,  \fd
        adrp   x1,  \buf@page
        add    x1,  x1,  \buf@pageoff
        mov    x2,  \count
        mov    x16, SYS_WRITE
        svc    #0x80

        mov    x0,  \fd
        mov    x1,  xzr
        mov    x2,  xzr
        mov    x16, SYS_WRITE
        svc    #0x80
.endm

.macro  exit   code
        mov    x0,  \code
        mov    x16, SYS_EXIT
        svc    #0x80
.endm
  
.global _start
.align 2

_start:
        write  STDOUT, start, start_len
        sub    sp,  sp,  #80

        stp    x29, x30, [sp,  #64]
        add    x29, sp,  #64

        adrp   x8,  ___stack_chk_guard@gotpage
        ldr    x8,  [x8,  ___stack_chk_guard@gotpageoff]
        ldr    x8,  [x8]
        stur   x8,  [x29,  #-8]

        write  STDOUT, socket_trace, socket_trace_len
        str    wzr, [sp,  #20]
        mov    w2,  #0
        mov    w1,  SOCK_STREAM
        mov    w0,  PF_INET
        bl     _socket
        str    w0,  [sp,  #16]
        ldr    w8,  [sp,  #16]
        adds   w8,  w8,  #1
        cmp    w8,  #0
        beq    error_any
        write  STDOUT, ok, ok_len

        write  STDOUT, bind_trace, bind_trace_len
        sub    x1,  x29,  #24
        stur   xzr, [x29,  #-24]
        stur   xzr, [x29,  #-16]
        mov    w8,  PF_INET
        sturb  w8,  [x29,  #-23]
        stur   wzr, [x29,  #-20]
        mov    w8,  PORT
        sturh  w8,  [x29,  #-22]
        ldr    w0,  [sp,   #16] 
        mov    w2,  #16
        bl     _bind
        subs   w8, w0, #0
        cset   w8, eq
        tbnz   w8, #0, pass
        b      error_any
pass:
        write  STDOUT, ok, ok_len

        write  STDOUT, listen_trace, listen_trace_len
        ldr    w0, [sp, #16]
        mov    w1, BACKLOG
        bl     _listen
        adds   w8, w0, #1
        cmp    w8, #0
        beq    error_any
        write  STDOUT, ok, ok_len

next_req:
        write  STDOUT, accept_trace, accept_trace_len
        add    x2,  sp,  #8
        mov    w8,  #16
        str    w8,  [sp, #8]
        ldr    w0,  [sp, #16]
        add    x1,  sp,  #24
        bl     _accept
        str    w0,  [sp, #12]
        ldr    w8,  [sp, #12]
        adds   w8,  w8,  #1
        cmp    w8,  #0
        beq    error_any

        ldr    w0, [sp,  #12]
        write  x0, response, response_len

        write  STDOUT, ok, ok_len
        b      next_req

        ldr    w0,  [sp, #16]
        bl     _close
        ldr    w0,  [sp, #12]
        bl     _close
        
        exit  0

error_any:
        write  STDERR, error_msg, error_msg_len

        ldr    w0,  [sp, #16]
        bl     _close
        ldr    w0,  [sp, #12]
        bl     _close
        
        exit  1

.data
start:         .asciz  "INFO: Starting Web Server!\n"
.equ           start_len,  . - start
socket_trace:  .asciz  "INFO: Creating a socket..."
.equ           socket_trace_len, . - socket_trace
bind_trace:    .asciz  "INFO: Binding to socket..."
.equ           bind_trace_len,  . - bind_trace
listen_trace:  .asciz  "INFO: Listening to socket..."
.equ           listen_trace_len,  . - listen_trace
accept_trace:  .asciz  "INFO: Waiting for clients..."
.equ           accept_trace_len,  . - accept_trace
ok:            .asciz  "...[OK]\n"
.equ           ok_len,  . - ok
error_msg:     .asciz  "...[FAILED]\n"
.equ           error_msg_len,  . - error_msg

response:       
        .ascii  "HTTP/1.1 200 OK\r\n"
        .ascii  "Content-Type: text/html; charset=utf-8\r\n"
        .ascii  "Connection: close\r\n\r\n"
        .ascii  "<html>\n"
        .ascii  "  <head>\n"
        .ascii  "    <title>Assembly Server</title>\n"
        .ascii  "    <style>\n"
        .ascii  "      body {\n"
        .ascii  "        background-color: #000000;\n"
        .ascii  "        display: flex;\n"
        .ascii  "        justify-content: center;\n"
        .ascii  "      }\n"
        .ascii  "      h1 {\n"
        .ascii  "        color: #ffffff;\n"
        .ascii  "      }\n"
        .ascii  "    </style>\n"
        .ascii  "  </head>\n"
        .ascii  "  <body>\n"
        .ascii  "    <h1>Hello from Arm64 Assemly Server</h1>\n"
        .ascii  "  </body>\n"
        .ascii  "</html>\n"

.equ    response_len,  . - response
