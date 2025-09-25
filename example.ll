; advanced.ll — LLVM IR equivalent of your SysY program (runtime-aligned)
; Features: sum / count_gt_even / sort(bubble+early-exit) / read / main
; Runtime decls: getarray, getint, putf, putarray, putch, starttime, stoptime (wrapped)

target triple = "x86_64-pc-linux-gnu"

; -------- SysY runtime functions (as in your sylib.so) --------
declare i32 @getarray(i32*)
declare i32 @getint()
declare void @putarray(i32, i32*)
declare void @putch(i32)
declare void @putf(i8*, ...)

; real symbols in your sylib.so:
declare void @_sysy_starttime()
declare void @_sysy_stoptime()

; compatibility wrappers to keep your original calls unchanged
define void @starttime() {
entry:
  call void @_sysy_starttime()
  ret void
}
define void @stoptime() {
entry:
  call void @_sysy_stoptime()
  ret void
}

; -------- constants (ASCII only) --------
@MAXN              = internal constant i32 100

@.fmt_invalid2     = private unnamed_addr constant [15 x i8] c"invalid n: %d\0A\00"
@.fmt_trunc        = private unnamed_addr constant [34 x i8] c"n=%d exceeds %d, truncated to %d\0A\00"
@.fmt_avg          = private unnamed_addr constant [10 x i8] c"avg = %f\0A\00"
@.fmt_mode_prompt  = private unnamed_addr constant [42 x i8] c"mode (1=max,2=median,3=count >t & even): \00"
@.fmt_max          = private unnamed_addr constant [10 x i8] c"max = %d\0A\00"
@.fmt_median       = private unnamed_addr constant [13 x i8] c"median = %f\0A\00"
@.fmt_t_prompt     = private unnamed_addr constant [4 x i8]  c"t: \00"
@.fmt_cnt          = private unnamed_addr constant [27 x i8] c"count(> %d and even) = %d\0A\00"
@.fmt_undef        = private unnamed_addr constant [26 x i8] c"mode %d undefined, exit.\0A\00"
@.fmt_head         = private unnamed_addr constant [27 x i8] c"array now (maybe sorted):\0A\00"
@.fmt_no_data      = private unnamed_addr constant [22 x i8] c"no valid data, exit.\0A\00"

; ======================================================
; int sum(int n, int a[])
; ======================================================
define i32 @sum(i32 %n, i32* %a) {
entry:
  %s = alloca i32
  %i = alloca i32
  store i32 0, i32* %s
  store i32 0, i32* %i
  br label %loop

loop:
  %iv = load i32, i32* %i
  %cond = icmp slt i32 %iv, %n
  br i1 %cond, label %body, label %exit

body:
  %p   = getelementptr inbounds i32, i32* %a, i32 %iv
  %val = load i32, i32* %p
  %acc = load i32, i32* %s
  %sum = add i32 %acc, %val
  store i32 %sum, i32* %s
  %inext = add i32 %iv, 1
  store i32 %inext, i32* %i
  br label %loop

exit:
  %ret = load i32, i32* %s
  ret i32 %ret
}

; ======================================================
; int count_gt_even(int n, int a[], int t)
; ======================================================
define i32 @count_gt_even(i32 %n, i32* %a, i32 %t) {
entry:
  %i = alloca i32
  %cnt = alloca i32
  store i32 0, i32* %i
  store i32 0, i32* %cnt
  br label %loop

loop:
  %iv = load i32, i32* %i
  %cond = icmp slt i32 %iv, %n
  br i1 %cond, label %body, label %exit

body:
  %p   = getelementptr inbounds i32, i32* %a, i32 %iv
  %v   = load i32, i32* %p
  %gt  = icmp sgt i32 %v, %t
  br i1 %gt, label %chk_even, label %next   ; short-circuit

chk_even:
  %m2   = srem i32 %v, 2
  %isev = icmp eq i32 %m2, 0
  br i1 %isev, label %inc, label %next

inc:
  %c    = load i32, i32* %cnt
  %c1   = add i32 %c, 1
  store i32 %c1, i32* %cnt
  br label %next

next:
  %inext = add i32 %iv, 1
  store i32 %inext, i32* %i
  br label %loop

exit:
  %ret = load i32, i32* %cnt
  ret i32 %ret
}

; ======================================================
; void sort(int n, int a[]) — bubble with early exit
; ======================================================
define void @sort(i32 %n, i32* %a) {
entry:
  %i  = alloca i32
  %j  = alloca i32
  %sw = alloca i32
  %tmp= alloca i32
  store i32 0, i32* %i
  br label %outer

outer:
  %iv   = load i32, i32* %i
  %n1   = add i32 %n, -1
  %ocnd = icmp slt i32 %iv, %n1
  br i1 %ocnd, label %outer_body, label %ret

outer_body:
  store i32 0, i32* %sw
  store i32 0, i32* %j
  br label %inner

inner:
  %jv    = load i32, i32* %j
  %limit = sub i32 %n1, %iv
  %icnd  = icmp slt i32 %jv, %limit
  br i1 %icnd, label %inner_body, label %after_inner

inner_body:
  %p0  = getelementptr inbounds i32, i32* %a, i32 %jv
  %j1  = add i32 %jv, 1
  %p1  = getelementptr inbounds i32, i32* %a, i32 %j1
  %v0  = load i32, i32* %p0
  %v1  = load i32, i32* %p1
  %ok  = icmp sle i32 %v0, %v1
  br i1 %ok, label %cont, label %swap

swap:
  store i32 %v0, i32* %tmp
  store i32 %v1, i32* %p0
  %tv = load i32, i32* %tmp
  store i32 %tv, i32* %p1
  store i32 1, i32* %sw
  br label %cont

cont:
  %jnext = add i32 %jv, 1
  store i32 %jnext, i32* %j
  br label %inner

after_inner:
  %swv = load i32, i32* %sw
  %is0 = icmp eq i32 %swv, 0
  br i1 %is0, label %ret, label %outer_next

outer_next:
  %inext = add i32 %iv, 1
  store i32 %inext, i32* %i
  br label %outer

ret:
  ret void
}

; ======================================================
; int read(int arr[])
; ======================================================
define i32 @read(i32* %arr) {
entry:
  %n  = alloca i32
  %mx = load i32, i32* @MAXN
  %rv = call i32 @getarray(i32* %arr)
  store i32 %rv, i32* %n
  %le0 = icmp sle i32 %rv, 0
  br i1 %le0, label %bad, label %chk_trunc

bad:
  %p_invalid = getelementptr inbounds [15 x i8], [15 x i8]* @.fmt_invalid2, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_invalid, i32 %rv)
  ret i32 0

chk_trunc:
  %gt  = icmp sgt i32 %rv, %mx
  br i1 %gt, label %do_trunc, label %ok

do_trunc:
  %p_trunc = getelementptr inbounds [34 x i8], [34 x i8]* @.fmt_trunc, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_trunc, i32 %rv, i32 %mx, i32 %mx)
  store i32 %mx, i32* %n
  br label %ok

ok:
  %ret = load i32, i32* %n
  ret i32 %ret
}

; ======================================================
; int main()
; ======================================================
define i32 @main() {
entry:
  %arr = alloca [100 x i32]
  %arrp = getelementptr inbounds [100 x i32], [100 x i32]* %arr, i64 0, i64 0

  ; n = read(arr)
  %n = call i32 @read(i32* %arrp)
  %is0 = icmp eq i32 %n, 0
  br i1 %is0, label %no_data, label %cont1

no_data:
  %p_no = getelementptr inbounds [22 x i8], [22 x i8]* @.fmt_no_data, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_no)
  ret i32 0

cont1:
  ; s = sum(n, arr)
  %s  = call i32 @sum(i32 %n, i32* %arrp)

  ; avg = (double)s / (double)n
  %sd = sitofp i32 %s to double
  %nd = sitofp i32 %n to double
  %avg = fdiv double %sd, %nd
  %p_avg = getelementptr inbounds [10 x i8], [10 x i8]* @.fmt_avg, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_avg, double %avg)

  ; prompt mode
  %p_mp = getelementptr inbounds [42 x i8], [42 x i8]* @.fmt_mode_prompt, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_mp)
  %mode = call i32 @getint()

  ; if (mode==1) max / else if (mode==2) median / else if (mode==3) count / else
  %is1 = icmp eq i32 %mode, 1
  br i1 %is1, label %do_max, label %chk2

do_max:
  %i = alloca i32
  %mx = alloca i32
  store i32 0, i32* %i
  ; mx = arr[0]
  %p0 = getelementptr inbounds i32, i32* %arrp, i32 0
  %v0 = load i32, i32* %p0
  store i32 %v0, i32* %mx
  br label %mloop

mloop:
  %iv = load i32, i32* %i
  %cond = icmp slt i32 %iv, %n
  br i1 %cond, label %mbody, label %mexit

mbody:
  %p   = getelementptr inbounds i32, i32* %arrp, i32 %iv
  %v   = load i32, i32* %p
  %cur = load i32, i32* %mx
  %gt  = icmp sgt i32 %v, %cur
  %sel = select i1 %gt, i32 %v, i32 %cur
  store i32 %sel, i32* %mx
  %inext = add i32 %iv, 1
  store i32 %inext, i32* %i
  br label %mloop

mexit:
  %mres = load i32, i32* %mx
  %p_max = getelementptr inbounds [10 x i8], [10 x i8]* @.fmt_max, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_max, i32 %mres)
  br label %after_mode

chk2:
  %is2 = icmp eq i32 %mode, 2
  br i1 %is2, label %do_median, label %chk3

do_median:
  call void @starttime()
  call void @sort(i32 %n, i32* %arrp)
  call void @stoptime()
  ; odd or even
  %odd = and i32 %n, 1
  %isodd = icmp eq i32 %odd, 1
  br i1 %isodd, label %odd_branch, label %even_branch

odd_branch:
  %mid = sdiv i32 %n, 2
  %pm  = getelementptr inbounds i32, i32* %arrp, i32 %mid
  %vm  = load i32, i32* %pm
  %vmd = sitofp i32 %vm to double
  %p_med = getelementptr inbounds [13 x i8], [13 x i8]* @.fmt_median, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_med, double %vmd)
  br label %after_mode

even_branch:
  %mid2 = sdiv i32 %n, 2
  %li   = add i32 %mid2, -1
  %pl   = getelementptr inbounds i32, i32* %arrp, i32 %li
  %pr   = getelementptr inbounds i32, i32* %arrp, i32 %mid2
  %vl   = load i32, i32* %pl
  %vr   = load i32, i32* %pr
  %sum2 = add i32 %vl, %vr
  %sum2d = sitofp i32 %sum2 to double
  %med  = fmul double %sum2d, 5.000000e-01
  %p_med2 = getelementptr inbounds [13 x i8], [13 x i8]* @.fmt_median, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_med2, double %med)
  br label %after_mode

chk3:
  %is3 = icmp eq i32 %mode, 3
  br i1 %is3, label %do_count, label %undef_mode

do_count:
  %p_t = getelementptr inbounds [4 x i8], [4 x i8]* @.fmt_t_prompt, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_t)
  %t = call i32 @getint()
  %cnt = call i32 @count_gt_even(i32 %n, i32* %arrp, i32 %t)
  %p_cnt = getelementptr inbounds [27 x i8], [27 x i8]* @.fmt_cnt, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_cnt, i32 %t, i32 %cnt)
  br label %after_mode

undef_mode:
  %p_udf = getelementptr inbounds [26 x i8], [26 x i8]* @.fmt_undef, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_udf, i32 %mode)
  br label %after_mode

after_mode:
  %p_head = getelementptr inbounds [27 x i8], [27 x i8]* @.fmt_head, i64 0, i64 0
  call void (i8*, ...) @putf(i8* %p_head)
  call void @putarray(i32 %n, i32* %arrp)
  call void @putch(i32 10)
  ret i32 0
}
