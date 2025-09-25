    // AArch64 (ARM64) assembly equivalent of the given SysY program
    // GNU ELF syntax (aarch64-linux-gnu toolchain friendly)
    // Functions: sum, count_gt_even, sort (bubble + early exit), read, main
    // Runtime used: getarray, getint, putf, putarray, putch, _sysy_starttime, _sysy_stoptime

    .text
    .align  2

    // ==== extern runtime symbols ====
    .extern  getarray
    .extern  getint
    .extern  putf
    .extern  putarray
    .extern  putch
    .extern  _sysy_starttime
    .extern  _sysy_stoptime

// ------------------------------------------------------------
// int sum(int n, int a[])
//   w0 = n, x1 = a ; return w0 = sum
// ------------------------------------------------------------
    .global sum
sum:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp
    // locals in registers:
    // w2 = i, w3 = s
    mov     w2, #0
    mov     w3, #0
1:  // while (i < n)
    cmp     w2, w0
    b.ge    2f
    // s += a[i]
    sxtw    x3, w2
    ldr     w4, [x1, x3, lsl #2]
    add     w3, w3, w4
    add     w2, w2, #1
    b       1b
2:
    mov     w0, w3
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// int count_gt_even(int n, int a[], int t)
//   w0=n, x1=a, w2=t ; return w0=cnt
// ------------------------------------------------------------
    .global count_gt_even
count_gt_even:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp
    mov     w3, #0          // i
    mov     w4, #0          // cnt
3:  // while (i < n)
    cmp     w3, w0
    b.ge    4f
    // v = a[i]
    sxtw    x5, w3
    ldr     w6, [x1, x5, lsl #2]
    // if (v > t) and (v % 2 == 0)
    cmp     w6, w2
    b.le    5f              // short-circuit: !(v>t)
    and     w7, w6, #1
    cbnz    w7, 5f          // odd -> skip
    add     w4, w4, #1
5:  add     w3, w3, #1
    b       3b
4:
    mov     w0, w4
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// void sort(int n, int a[])  // bubble sort with early-exit
//   w0=n, x1=a
// ------------------------------------------------------------
    .global sort
sort:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp
    mov     w2, #0              // i
    sub     w8, w0, #1          // n1 = n-1
10: // outer: while (i < n-1)
    cmp     w2, w8
    b.ge    19f
    mov     w3, #0              // swapped = 0
    mov     w4, #0              // j = 0
11: // inner: while (j < n-1-i)
    sub     w9, w8, w2          // limit = n-1-i
    cmp     w4, w9
    b.ge    16f
    // load a[j], a[j+1]
    sxtw    x5, w4
    add     w10, w4, #1
    sxtw    x6, w10
    ldr     w6, [x1, x5, lsl #2]    // v0
    ldr     w7, [x1, x6, lsl #2]    // v1
    // if (a[j] <= a[j+1]) continue;
    cmp     w6, w7
    ble     15f
    // swap
    str     w7, [x1, x5, lsl #2]
    str     w6, [x1, x6, lsl #2]
    mov     w3, #1
15: add     w4, w4, #1
    b       11b
16: // after_inner
    cbz     w3, 19f             // if (swapped==0) break;
    add     w2, w2, #1
    b       10b
19:
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// int read(int arr[])
//   x0=arr ; returns n (possibly truncated to 100)
//   prints errors with putf
// ------------------------------------------------------------
    .global read
read:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp
    // call getarray(arr)
    bl      getarray
    // rv in w0
    mov     w2, w0             // n = rv
    // if (rv <= 0) { putf(fmt_invalid2, rv); return 0; }
    cmp     w0, #0
    bgt     21f
    adrp    x0, .LC_invalid2
    add     x0, x0, :lo12:.LC_invalid2
    // variadic putf(fmt, int) : x0=fmt, x1=rv
    sxtw    x1, w2
    bl      putf
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
21:
    // if (rv > 100) { putf(fmt_trunc, rv, 100, 100); n = 100; }
    mov     w3, #100
    cmp     w2, w3
    ble     22f
    adrp    x0, .LC_trunc
    add     x0, x0, :lo12:.LC_trunc
    sxtw    x1, w2     // rv
    mov     w4, #100
    sxtw    x2, w4     // 100
    sxtw    x3, w4     // 100
    bl      putf
    mov     w2, #100
22:
    mov     w0, w2
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// int main()
//   local int arr[100];  // 400 bytes on stack
//   follows the same control flow as SysY source
// ------------------------------------------------------------
    .global main
main:
    // Frame layout (16-byte aligned):
    // [sp-512 .. sp) : frame (we use 512 to keep alignment and leave room)
    // arr at sp+16 (after saving fp/lr) -> use x19 as arr base
    stp     x29, x30, [sp, -16]!
    mov     x29, sp
    sub     sp, sp, #512
    // For simplicity, place arr at sp+128 (16B aligned)
    add     x19, sp, #128

    // n = read(arr)
    mov     x0, x19
    bl      read
    mov     w20, w0            // n in w20
    cbnz    w20, 30f
    // no data path: putf(.LC_no_data)
    adrp    x0, .LC_no_data
    add     x0, x0, :lo12:.LC_no_data
    bl      putf
    mov     w0, #0
    add     sp, sp, #512
    ldp     x29, x30, [sp], #16
    ret

30: // s = sum(n, arr)
    mov     w0, w20
    mov     x1, x19
    bl      sum
    mov     w21, w0            // s

    // avg = (double)s / (double)n ; putf("avg = %f\n", avg)
    scvtf   d0, w21
    scvtf   d1, w20
    fdiv    d0, d0, d1
    adrp    x0, .LC_avg
    add     x0, x0, :lo12:.LC_avg
    // AArch64 variadic ABI: double in v0 (d0), format in x0
    bl      putf

    // prompt mode
    adrp    x0, .LC_mode
    add     x0, x0, :lo12:.LC_mode
    bl      putf
    bl      getint
    mov     w22, w0            // mode

    // if (mode == 1) -> max
    cmp     w22, #1
    b.ne    40f
    // i=0; mx=arr[0]
    mov     w23, #0
    ldr     w24, [x19]         // arr[0]
31: // while (i < n)
    cmp     w23, w20
    b.ge    33f
    sxtw    x0, w23
    ldr     w1, [x19, x0, lsl #2]
    cmp     w1, w24
    csel    w24, w1, w24, gt
    add     w23, w23, #1
    b       31b
33: // putf("max = %d\n", mx)
    adrp    x0, .LC_max
    add     x0, x0, :lo12:.LC_max
    sxtw    x1, w24
    bl      putf
    b       60f

40: // else if (mode == 2) -> median with sort + time
    cmp     w22, #2
    b.ne    50f
    // starttime(); sort(n,arr); stoptime();
    bl      _sysy_starttime
    mov     w0, w20
    mov     x1, x19
    bl      sort
    bl      _sysy_stoptime
    // if (n % 2 == 1) -> odd
    and     w0, w20, #1
    cbz     w0, 45f
    // odd: mid = n/2 ; med = (double)arr[mid]
    mov     w9, #2
    sdiv    w0, w20, w9
    sxtw    x0, w0
    ldr     w1, [x19, x0, lsl #2]
    scvtf   d0, w1
    adrp    x0, .LC_median
    add     x0, x0, :lo12:.LC_median
    bl      putf
    b       60f
45: // even: med = 0.5*(arr[n/2-1]+arr[n/2])
    mov     w9, #2
    sdiv    w0, w20, w9
    sxtw    x0, w0
    add     w1, w0, #-1
    sxtw    x1, w1
    ldr     w2, [x19, x1, lsl #2]
    ldr     w3, [x19, x0, lsl #2]
    add     w2, w2, w3
    scvtf   d0, w2
    fmov    d1, #0.5
    fmul    d0, d0, d1
    adrp    x0, .LC_median
    add     x0, x0, :lo12:.LC_median
    bl      putf
    b       60f

50: // else if (mode == 3) -> count >t and even
    cmp     w22, #3
    b.ne    55f
    adrp    x0, .LC_t
    add     x0, x0, :lo12:.LC_t
    bl      putf
    bl      getint
    mov     w23, w0       // t
    mov     w0, w20
    mov     x1, x19
    mov     w2, w23
    bl      count_gt_even
    mov     w24, w0       // cnt
    adrp    x0, .LC_cnt
    add     x0, x0, :lo12:.LC_cnt
    sxtw    x1, w23       // t
    sxtw    x2, w24       // cnt
    bl      putf
    b       60f

55: // else: undefined mode
    adrp    x0, .LC_undef
    add     x0, x0, :lo12:.LC_undef
    sxtw    x1, w22
    bl      putf

60: // print head + putarray(n,arr) + putch(10)
    adrp    x0, .LC_head
    add     x0, x0, :lo12:.LC_head
    bl      putf
    mov     w0, w20
    mov     x1, x19
    bl      putarray
    mov     w0, #10
    bl      putch

    mov     w0, #0
    add     sp, sp, #512
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------------------
// Read-only data: format strings (ASCII)
// ------------------------------------------------------------
    .section .rodata
    .align  3
.LC_invalid2:
    .asciz  "invalid n: %d\n"
.LC_trunc:
    .asciz  "n=%d exceeds %d, truncated to %d\n"
.LC_avg:
    .asciz  "avg = %f\n"
.LC_mode:
    .asciz  "mode (1=max,2=median,3=count >t & even): "
.LC_max:
    .asciz  "max = %d\n"
.LC_median:
    .asciz  "median = %f\n"
.LC_t:
    .asciz  "t: "
.LC_cnt:
    .asciz  "count(> %d and even) = %d\n"
.LC_undef:
    .asciz  "mode %d undefined, exit.\n"
.LC_head:
    .asciz  "array now (maybe sorted):\n"
.LC_no_data:
    .asciz  "no valid data, exit.\n"
