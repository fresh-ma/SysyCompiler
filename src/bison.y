%code requires{
#include <memory>
#include <string>
#include "AST.hpp"
}

%{
#include "AST.hpp"
#include <memory>
#include <string>
#include <iostream>
#include <cstdio>
#define VIS_AST             // 可视化AST
using namespace std;

extern int yylex();
extern void yyerror(Program **program, const char *s);

char *ast_out_file = (char*)"handle_out_file.txt";
%}


// 用于存储解析过程中产生的不同类型的数据
%union{
    string *str_val;
    int int_val;
    BaseAST* ast_val;
    DeclareDef *def_val;
    BlockItems *items_val;
    Decls *decl_val;
    Program *pro_val;
    Var *var_val;
}


%parse-param {Program **program}
%token T_Int T_Ret T_Logic_And T_Logic_Or T_If T_Else T_While
%token T_Void
%token <str_val> T_Ident
%token <int_val> T_Int_Const

%type <ast_val> FuncDef Block Stmt Number Expr AtomExpr AndExpr AddSubExpr MulDivExpr EqualExpr CompareExpr UnaryExpr
%type <ast_val> BlockItem MS UMS IfExpr FuncRealParams CompUnit
%type <ast_val> InitVal InitVals
%type <int_val> UnaryOp AddSubOp MulDivOp CompareOp EqualOp 
%type <int_val> VarType
%type <def_val> VarDef FuncParam
%type <items_val> BlockItems 
%type <decl_val> VarDecl Decl FuncParams
%type <pro_val> CompUnits
%type <var_val> Var

%%

// 开始符
Program
    :   CompUnits
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"CompUnits -> Program"<<endl;
        fclose(stdout);
        freopen("/dev/tty", "a", stdout);
        #endif
        *program = $1;
    }

// 编译单元集合
CompUnits
    :   CompUnit
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"CompUnit -> CompUnits"<<endl;
        fclose(stdout);
        #endif
        Program *pro = new Program();
        pro->units.push_back($1);
        $$ = pro;
    }
    |   CompUnits CompUnit
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"CompUnits CompUnit -> CompUnits"<<endl;
        fclose(stdout);
        #endif
        ($1->units).push_back($2);
        $$ = $1;
    }

// 编译单元
CompUnit
    :   Decl            // 声明语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Decl -> CompUnit"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   FuncDef         // 函数
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"FuncDef -> CompUnit"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }

// 函数
FuncDef
    :   VarType T_Ident '(' ')' Block       // 无参函数
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarType T_Ident ( ) Block -> FuncDef"<<endl;
        fclose(stdout);
        #endif

        FuncDef* ast = new FuncDef();
        ast->func_type = $1;
        ast->id = *($2);
        delete $2;
        ast->block = $5;
        $$ = (BaseAST*)ast;
    }
    |   VarType T_Ident '(' FuncParams ')' Block        // 有参函数
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarType T_Ident ( FuncParams ) Block -> FuncDef"<<endl;
        fclose(stdout);
        #endif

        FuncDef* ast = new FuncDef();
        ast->func_type = $1;
        ast->id = *($2);
        delete $2;
        ast->block = $6;
        ast->params = $4->defs;
        $$ = (BaseAST*)ast;
    }

// 函数的所有参数
FuncParams
    :   FuncParam           // 一个参数
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"FuncParam -> FuncParams"<<endl;
        fclose(stdout);
        #endif

        Decls *decl = new Decls();
        (decl->defs).push_back($1);
        $$ = decl;
    }
    |   FuncParams ',' FuncParam        // 多个参数
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"FuncParams , FuncParam -> FuncParams"<<endl;
        fclose(stdout);
        #endif
        ($1->defs).push_back($3);
        $$ = $1;
    }

// 一个参数
FuncParam
    :   VarType T_Ident
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarType T_Ident -> FuncParam"<<endl;
        fclose(stdout);
        #endif
        DeclareDef *def = new DeclareDef(*($2));
        def->declType = ParamDecl;
        delete $2;
        $$ = def;
    }
// 调用时的实参
FuncRealParams
    :   Expr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Expr -> FuncRealParams" << endl;
        fclose(stdout);
        #endif
        FuncCall *call = new FuncCall();
        (call->params).push_back($1);
        $$ = (BaseAST*)call;
    }
    |   FuncRealParams ',' Expr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "FuncRealParams , Expr -> FuncRealParams" << endl;
        fclose(stdout);
        #endif
        (((FuncCall*)$1)->params).push_back($3);
        $$ = $1;
    }
// 变量类型
VarType
    :   T_Int
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "T_Int -> VarType" << endl;
        fclose(stdout);
        #endif
        $$ = TypeInt;
    }
    |   T_Void
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "T_Void -> VarType" << endl;
        fclose(stdout);
        #endif
        $$ = TypeVoid;
    }
// 大括号中的东西
Block
    :   '{' BlockItems '}'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "{ BlockItems } -> Block" << endl;
        fclose(stdout);
        #endif
        Block* ast = new Block();
        ast->stmts = $2->vec;
        delete $2;
        $$ = (BaseAST*)ast;
        //printf("block\n");
    };
// 语句集合
BlockItems
    :   BlockItems BlockItem
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "BlockItems BlockItem -> Block" << endl;
        fclose(stdout);
        #endif
        //BaseAST *ast = $1->vec[($1->vec).size()-1];
        if($2 != NULL)
        {
            if($2->ifDecls())
            {
                Decls *decl = (Decls*)$2;
                for(int i=0;i < decl->defs.size();i++)
                {
                    ($1->vec).insert(($1->vec).end(),(BaseAST*)decl->defs[i]);
                }
            }
            else
                ($1->vec).insert(($1->vec).end(),$2);
        }
        $$ = $1;
    }
    |
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Empty -> Block" << endl;
        fclose(stdout);
        #endif
        BlockItems *bt = new BlockItems();
        $$ = bt;
    }
// 一条语句
BlockItem
    :   Decl    // 声明语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Decl -> BlockItem" << endl;
        fclose(stdout);
        #endif
        $$ = (BaseAST*)$1;
    }
    |   Stmt
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Stmt -> BlockItem" << endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
// 声明语句
Decl
    : VarDecl ';'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarDecl ; -> Decl"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }

// 变量声明
VarDecl
    :   VarType VarDef
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarType VarDef -> VarDecl"<<endl;
        fclose(stdout);
        #endif

        Decls *decl = new Decls($1);
        $2->type = $1;
        $2->declType = VarDecl;
        decl->defs.insert((decl->defs).end(),$2);
        $$ = decl;
    }
    |   VarDecl ',' VarDef //一下子声明多个同类型的变量
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"VarDecl , VarDef -> VarDecl"<<endl;
        fclose(stdout);
        #endif

        $3->type = $1->type;
        $3->declType = VarDecl;
        ($1->defs).insert(($1->defs).end(),$3);
        $$ = $1;
    }
// 单独一个变量 or 有初始赋值的变量
VarDef
    :   Var
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Var -> VarDef"<<endl;
        fclose(stdout);
        #endif

        DeclareDef *def = new DeclareDef($1->id);
        def->offset = $1->offset;
        delete $1;
        $$ = def;
    }
    |   Var '=' InitVal
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Var = InitVal -> VarDef"<<endl;
        fclose(stdout);
        #endif

        DeclareDef *def = new DeclareDef($1->id,$3);
        def->offset = $1->offset;
        delete $1;
        $$ = def;
    }
// 初始值
InitVals
    :   InitVal
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"InitVal -> InitVals"<<endl;
        fclose(stdout);
        #endif
        InitVal *init = new InitVal();
        init->inits.push_back($1);
        $$ = init;

    }
    |   InitVals ',' InitVal
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"InitVals , InitVal -> InitVals"<<endl;
        fclose(stdout);
        #endif
        ((InitVal*)$1)->inits.push_back($3);
        $$ = $1;
    }

// 初始值
InitVal
    :   Expr //用表达式当作初始值
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Expr -> InitVal"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   '{' InitVals '}'//为数组等元素赋初值
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"{ InitVals } -> InitVal"<<endl;
        fclose(stdout);
        #endif
        $$ = $2;
    }
    |   '{' '}'//用default为数组赋初值
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"{ } -> InitVal"<<endl;
        fclose(stdout);
        #endif
        $$ = NULL;
    }
// 变量
Var
    :   T_Ident
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_Ident -> Var"<<endl;
        fclose(stdout);
        #endif
        Var *var = new Var(*($1));
        delete $1;
        $$ = var;
    }
// 
Stmt
    :   MS //语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"MS -> Stmt"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   UMS
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"UMS -> Stmt"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
// 语句
MS
    :   T_Ret Expr ';'      // return语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_Ret Expr ; -> MS"<<endl;
        fclose(stdout);
        #endif
        Stmt* ast = new Stmt($2,Return);
        $$ = (BaseAST*)ast;
    }
    |   T_Ret ';'           // return;
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_Ret ; -> MS"<<endl;
        fclose(stdout);
        #endif
        Stmt* ast = new Stmt(NULL,Return);
        $$ = (BaseAST*)ast;
    }
    |   Var '=' Expr ';'   // 赋值语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Var = Expr ; -> MS"<<endl;
        fclose(stdout);
        #endif
        Stmt *ast = new Stmt($3,Assign,(Var*)$1);
        $$ = (BaseAST*)ast;
    }
    |   Block               // 大括号
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Block -> MS"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   Expr ';'            // 表达式
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Expr ; -> MS"<<endl;
        fclose(stdout);
        #endif
        Stmt *ast = new Stmt($1,Other);
        $$ = (BaseAST*)ast;
    }
    |   ';'                 // 空语句
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"; -> MS"<<endl;
        fclose(stdout);
        #endif
        $$ = NULL;
    }
    |   IfExpr MS T_Else MS         // if else结构
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"IfExpr MS T_Else MS -> MS"<<endl;
        fclose(stdout);
        #endif
        JumpStmt *ast = new JumpStmt($1,$2,$4);
        $$ = (BaseAST*)ast;
    }
    |   T_While '(' Expr ')' Stmt   // while结构
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_While ( Expr ) Stmt -> MS"<<endl;
        fclose(stdout);
        #endif
        WhileStmt *stmt = new WhileStmt($3,$5);
        $$ = (BaseAST*)stmt;
    }
// 为了递归if
UMS
    :   IfExpr Stmt
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"IfExpr Stmt -> UMS"<<endl;
        fclose(stdout);
        #endif
        JumpStmt *ast = new JumpStmt($1,$2);
        $$ = (BaseAST*)ast;
    }
    |   IfExpr MS T_Else UMS
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"IfExpr MS T_Else UMS -> UMS"<<endl;
        fclose(stdout);
        #endif
        JumpStmt *ast = new JumpStmt($1,$2,$4);
        $$ = (BaseAST*)ast;
    }
// if 语句
IfExpr
    :   T_If '(' Expr ')'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_If ( Expr ) -> IfExpr"<<endl;
        fclose(stdout);
        #endif
        $$ = $3;
    }
// 表达式
Expr
    :   AndExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"AndExpr -> Expr"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   Expr T_Logic_Or AndExpr    //最低的运算符优先级: ||
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"Expr T_Logic_Or AndExpr -> Expr"<<endl;
        fclose(stdout);
        #endif
        BaseAST *ast1,*ast2;
        if(!($1->ifBoolean()))
            ast1 = (BaseAST*)new Expr($1,NULL,NotEqualZero);
        else
            ast1 = $1;
        if(!($3->ifBoolean()))
            ast2 = (BaseAST*)new Expr($3,NULL,NotEqualZero);
        else
            ast2 = $3;
        Expr *ast = new Expr(ast2,ast1,Or);
        $$ = (BaseAST*)ast;
    }
// &&递归
AndExpr
    :   EqualExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"EqualExpr -> AndExpr"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   AndExpr T_Logic_And EqualExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"AndExpr T_Logic_And EqualExpr -> AndExpr"<<endl;
        fclose(stdout);
        #endif
        BaseAST *ast1,*ast2;
        if(!($1->ifBoolean()))
            ast1 = (BaseAST*)new Expr($1,NULL,NotEqualZero);
        else
            ast1 = $1;
        if(!($3->ifBoolean()))
            ast2 = (BaseAST*)new Expr($3,NULL,NotEqualZero);
        else
            ast2 = $3;
        Expr *ast = new Expr(ast2,ast1,And);
        $$ = (BaseAST*)ast;
    }
// 表达式 == 表达式
EqualExpr
    :   CompareExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"CompareExpr -> EqualExpr"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   EqualExpr EqualOp CompareExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"EqualExpr EqualOp CompareExpr -> EqualExpr"<<endl;
        fclose(stdout);
        #endif
        Expr *ast = new Expr($3,$1,$2);
        $$ = (BaseAST*)ast;
    }
// 表达式 < 表达式
CompareExpr
    :   AddSubExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"AddSubExpr -> CompareExpr"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   CompareExpr CompareOp AddSubExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"CompareExpr CompareOp AddSubExpr -> CompareExpr"<<endl;
        fclose(stdout);
        #endif
        Expr *ast = new Expr($3,$1,$2);
        $$ = (BaseAST*)ast;
    }
// 表达式 +- 表达式
AddSubExpr
    :   MulDivExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"MulDivExpr -> AddSubExpr"<<endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   AddSubExpr AddSubOp MulDivExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"AddSubExpr AddSubOp MulDivExpr -> AddSubExpr"<<endl;
        fclose(stdout);
        
        #endif
        Expr *ast = new Expr($3,$1,$2);
        $$ = (BaseAST*)ast;
    }
// 表达式 */ 表达式
MulDivExpr
    :   UnaryExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "UnaryExpr -> MulDivExpr" << endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   MulDivExpr MulDivOp UnaryExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "MulDivExpr MulDivOp UnaryExpr -> MulDivExpr" << endl;
        fclose(stdout);
        #endif
        Expr *ast = new Expr($3,$1,$2);
        $$ = (BaseAST*)ast;
    };
// 
UnaryExpr
    :   AtomExpr
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "AtomExpr -> UnaryExpr" << endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   UnaryOp UnaryExpr       // 一元操作符前缀
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "UnaryOp UnaryExpr -> UnaryExpr" << endl;
        fclose(stdout);
        #endif
        if($1 == NoOperation)
            $$ = $2;
        else
        {
            Expr* ast = new Expr($2,NULL,$1);
            $$ = (BaseAST*)ast;
        }
    }
// 表达式原子
AtomExpr
    :   '(' Expr ')'    //表达式
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "( Expr ) -> AtomExpr" << endl;
        fclose(stdout);
        #endif
        $$ = $2;
    }
    |   Number  //常量
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Number -> AtomExpr" << endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   Var     // 变量
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "Var -> AtomExpr" << endl;
        fclose(stdout);
        #endif
        $$ = $1;
    }
    |   T_Ident '(' FuncRealParams ')'      // 有参函数调用
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "T_Ident ( FuncRealParams ) -> AtomExpr" << endl;
        fclose(stdout);
        #endif
        ((FuncCall*)$3)->name = *($1);
        delete $1;
        $$ = $3;
    }
    |   T_Ident '(' ')'                     // 无参函数调用
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout << "(  ) -> AtomExpr" << endl;
        fclose(stdout);
        #endif
        FuncCall *call = new FuncCall();
        call->name = *($1);
        delete $1;
        $$ = (BaseAST*)call;
    }
// 终极符，正负非（一元操作符）
UnaryOp
    :   '+'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"+ -> UnaryOp"<<endl;
        fclose(stdout);
        #endif
        $$ = NoOperation;
    }
    |   '-'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"- -> UnaryOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Invert;
    }
    |   '!'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"! -> UnaryOp"<<endl;
        fclose(stdout);
        #endif
        $$ = EqualZero;
    };
// 终极符 + -
AddSubOp
    :   '+'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"+ -> AddSubOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Add;
    }
    |   '-'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"- -> AddSubOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Sub;
    };
// 终极符 * / %
MulDivOp
    :   '*'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"* -> MulDivOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Mul;
    }
    |   '/'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"/ -> MulDivOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Div;
    }
    |   '%'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"% -> MulDivOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Mod;
    }
// 终极符 <= < > >=
CompareOp
    :   '<' '='
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"< = -> CompareOp"<<endl;
        fclose(stdout);
        #endif
        $$ = LessEq;
    }
    |   '<'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"< -> CompareOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Less;
    }
    |   '>'
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"> -> CompareOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Greater;
    }
    |   '>' '='
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"> = -> CompareOp"<<endl;
        fclose(stdout);
        #endif
        $$ = GreaterEq;
    }
// 终极符 == !=
EqualOp
    :   '=' '='
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"= = -> EqualOp"<<endl;
        fclose(stdout);
        #endif
        $$ = Equal;
    }
    |   '!' '='
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"! = -> EqualOp"<<endl;
        fclose(stdout);
        #endif
        $$ = NotEqual;
    }
// 常数
Number
    :   T_Int_Const
    {
        #ifdef VIS_AST
        freopen(ast_out_file, "a", stdout);
        cout<<"T_Int_Const -> Number"<<endl;
        fclose(stdout);
        #endif
        Number* ast = new Number();
        ast->num = $1;
        $$ = (BaseAST*)ast;
    };
%%

extern void yyerror(Program **program,const char* s)
{
    cout<<"error: "<<s<<endl;
}