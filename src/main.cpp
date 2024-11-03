// cd /root/build && cmake ../compiler && make && cd /root/build && ./compiler -koopa
#include "AST.hpp"
#include <memory>
#include <string.h>
#include <stdio.h>

extern FILE *yyin;
extern int yyparse(Program **program);
extern void yyerror(Program **program,const char*);

int main(int argc,char* argv[]) {
    char *in_file = (char*)"input.txt";
    char *out_file = (char*)"output3.txt";
    int omode = RISCV_MODE;
    for(int i=1;i < argc;i++) {
        printf("%d %s\n",i,argv[i]);
        if(!memcmp(argv[i],"-koopa",6)) omode = KOOPA_MODE;
        else if(!memcmp(argv[i],"-riscv",6)) omode = RISCV_MODE;
    }
    freopen(in_file, "r", stdin);
    Program * answer;
    yyparse(&answer);
    if(omode == KOOPA_MODE) {
        answer->print_koopa();
    }
    return 0; 
}


/*
fun @func(@x: i32): i32 {
%entry:
  @_0x = alloc i32
  store @x, @_0x
  %1 = load @_0x
  %2 = load @_0x
  %0 = mul %1, %2
  ret %0
}

fun @main(): i32 {
%entry:
  @_1x = alloc i32
  store 0, @_1x
  @_1y = alloc i32
  store 1, @_1y
  @_1z = alloc i32
  %4 = load @_1x
  %6 = load @_1y
  %5 = mul %6, 2
  %3 = add %4, %5
  store %3, @_1z
  jump %while_2
%while_2:
  %8 = load @_1x
  %7 = le %8, 10
  br %7, %stmt_2, %break_2
%stmt_2:
  %10 = load @_1x
  %9 = add %10, 1
  store %9, @_1x
  jump %while_2
%break_2:
  %12 = load @_1x
  %11 = gt %12, 20
  br %11, %then_0, %else_0
%then_0:
  store 23, @_1y
  jump %end_0
%else_0:
  store 50, @_1y
  jump %end_0
%end_0:
  @_6x = alloc i32
  store 1, @_6x
  @_1yy = alloc i32
  %15 = load @_1x
  %14 = call @func(%15)
  %16 = load @_1x
  %13 = add %14, %16
  store %13, @_1yy
  ret 0
}
*/