#pragma once

#define KOOPA_MODE 0
#define RISCV_MODE 1

#define NoOperation 0
#define Invert 1
#define EqualZero 2
#define Add 3
#define Sub 4
#define Mul 5
#define Div 6
#define Mod 7
#define Less 8
#define Greater 9
#define LessEq 10
#define GreaterEq 11
#define Equal 12
#define NotEqual 13
#define And 14
#define Or 15
#define NotEqualZero 16

// 声明类型
#define VarDecl 0
#define ConstDecl 1
#define ParamDecl 2
#define ArrayDecl 3

// 变量类型,如int或string等
#define TypeInt 0
#define TypeVoid 1

// 语句类型
#define Assign 0
#define Return 1
#define Break 2
#define Continue 3
#define Other 4