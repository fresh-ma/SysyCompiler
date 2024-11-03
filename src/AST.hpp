#pragma once
#include <string>
#include <memory>
#include <iostream>
#include <vector>
#include <map>
#include <cstring>
#include <typeinfo> 
#include "constants.h"

#define COLOR_RED   "\033[31m" 
#define COLOR_GREEN "\033[32m" 
#define COLOR_YELLOW "\033[33m" 
#define COLOR_BLUE "\033[34m" 
#define COLOR_RESET "\033[0m" 

using namespace std;

class BaseAST;
class Expr;
class Stmt;
class JumpStmt;
class InitVal;

class Symbol {
    public:
        int declType;
        int type;
        int value;
        int ifAlloc = 0;
        int len = 0;
        string name;

        Symbol(int dtp,string n,int tp = TypeInt,int v=0) {
            type = tp;
            declType = dtp;
            value = v;
            name = n;
        }
};

class FuncInfo {
    public:
        int func_type;
        vector<int> param_type;
        FuncInfo(){}
        FuncInfo(int type) {
            func_type = type;
        }
        FuncInfo(int type,vector<int> param) {
            func_type = type;
            param_type = param;
        }
        FuncInfo(const FuncInfo &a) {
            func_type = a.func_type;
            param_type = a.param_type;
        }
};

typedef map<string,Symbol*> SymbolMap;

static int temp_var_range=0;
static int block_range=0;

// 区分不同的 {} 块 
static int now_block_id;
static int jump_stmt_id=0;
static vector<SymbolMap> symbol_table(1);    
static map<string,FuncInfo*> func_table;
static int ifReturn = 0;  
static vector<int> while_stmt_id;
static int genTempVar() {
    return temp_var_range++;
}
static int genBlockId() {
    return block_range++;
}
// if 的 id 
static int genJumpStmtId() {
    return jump_stmt_id++;
}
static void Error(const char *message) {
    cout << "error: " << message << endl;
    exit(0);
}
static inline void genBlock(const char *name,int id)
{
    cout << "%" << name << "_" << id << ":" << endl;
    ifReturn = 0; 
}
static int ifJumpInstr(BaseAST *s);

static void delSymbolMap(SymbolMap &map) {
    for(auto iter = map.begin();iter != map.end();iter++) {
        delete iter->second;
    }
}

// 在符号表中查找变量名字 
static Symbol* findSymbol(string &id) {
    for(int i=symbol_table.size() - 1; i >= 0; i-- ) {
        if(symbol_table[i].count(id))
            return symbol_table[i][id];
    }
    Error("Can't find the symbol in symbol table");
    return NULL;
}

static void printType(int type,vector<int> offset) {
    if(offset.size() == 0) {
        if(type == TypeInt)
            cout << "i32";
    }
    else {
        cout << "[";
        int o = offset[0];
        offset.erase(offset.begin());
        printType(type,offset);
        cout << ", " << o << "]" ;
    }
}


class BlockItems {
    public:
        vector<BaseAST*> vec;
};

class BaseAST {
    public:
        virtual ~BaseAST() = default;
        virtual void print_koopa() = 0;
        virtual int ifNumber(){return 0;};
        virtual void genInstr(int instrType){};
        virtual void output(){};
        virtual int ifBoolean(){return 0;}
        virtual int ifDecls(){return 0;}
        virtual int eval(){return 0;}
        virtual int ifStmt(){return 0;}
        virtual int ifExpr(){return 0;}
        virtual int ifVar(){return 0;}
        virtual int ifBlock(){return 0;}
        virtual int ifEmptyBlock(){return 0;}
        virtual int ifJumpStmt(){return 0;}
        virtual int ifInitVal(){return 0;}
        virtual void load_array(){}
};

// 表示临时变量
class Var : public BaseAST {
    public:
        string id;
        vector<BaseAST*> offset;
        int ptr_id = -1;
        int temp_var = -1;   

        Var(string a) {
            id = a;
        }

        virtual void print_koopa() {  
            Symbol *symbol = findSymbol(id);

            if(symbol->declType == VarDecl) {
                temp_var = genTempVar();
                cout<<"  %"<<temp_var<<" = load "<<symbol->name<<endl;
            }
        }

        virtual void output() {
            Symbol *symbol = findSymbol(id);
            if(symbol->declType == VarDecl) {  
                if(temp_var != -1)
                    cout << "%" << temp_var;    
                else
                    cout << symbol->name;
            }
        }

        virtual int eval() {
            return findSymbol(id) -> value;
        }
        virtual int ifVar(){return 1;}
};

class InitVal : public BaseAST {
    public:
        vector<BaseAST*> inits;
        virtual void print_koopa() {
            for(int i=0;i < inits.size();i++) {
                if(inits[i] == NULL) {
                    continue;
                }
                inits[i]->print_koopa();
            }
        }
        virtual int ifInitVal(){return 1; }
};


class Number : public BaseAST {
    public:
        int num;
        virtual void print_koopa() {};
        virtual void output() {
            cout << num;
        }
        virtual int ifNumber(){ return 1; }
        virtual int eval() {
            return num;
        }
};


// 变量声明 
class DeclareDef : public BaseAST
{
    public:
        string name;
        BaseAST *init;
        int declType=VarDecl;
        int type=TypeInt;
        vector<BaseAST*> offset;

        DeclareDef(string n,BaseAST *e=NULL) {
            name = n;
            init = e;
        }
        virtual void print_koopa() {
            // 这个 symbol 存的是一个变量的信息 
            Symbol *symbol;
            int depth = symbol_table.size() - 1;
            string id = string("@_") + to_string(now_block_id) + name;


            // 变量的声明
            if(declType == VarDecl && offset.size() == 0) {
                symbol = new Symbol(VarDecl, id, type);

                // 如果这个变量还没有分配过内存，那么就分配内存
                if(!(symbol_table[depth].count(name) && symbol_table[depth][name]->ifAlloc)) {
                    cout << "  " << id << " = alloc ";
                    if(type == TypeInt)
                        cout << "i32";
                    cout << endl;
                    symbol -> ifAlloc = 1;
                }
                else {
                    cout << endl; 
                    cout << endl; 

                    // 重复定义，出错!
                    cout << COLOR_GREEN << "ERROR!" << COLOR_RESET << endl; 
                    cout << COLOR_GREEN << "REDECLARATION of VARIABLE" << " " << id << COLOR_RESET << endl; 
                    exit(0); 
                }
                
                if(init != NULL) {

                    // cout << typeid(*init).name() << endl; 
                    // exit(0); 
                    init -> print_koopa();
                    int value = init -> eval();     
                    cout << "  store ";
                    init -> output();
                    cout << ", " << id << endl;  
                    symbol -> value = value;
                }
            }

            // 载入函数的形参 
            // 这里特殊处理一下，不需要查找符号表之类的 
            else if(declType == ParamDecl) {
                symbol = new Symbol(VarDecl,id,type);
                cout<<"  "<<id<<" = alloc ";
                vector<int> temp;
                for(int i=0;i < offset.size();i++)
                    temp.push_back(offset[i]->eval());
                printType(type,temp);
                cout<<endl;
                cout<<"  store @"<<name<<", "<<id<<endl;
            }

            if(symbol_table[depth].count(name)) {
                symbol->ifAlloc = symbol_table[depth][name]->ifAlloc;
                symbol_table[depth][name] = symbol;
            }
            else{
                symbol_table[depth].emplace(name,symbol);
            }
        }
};


// 正常语句：赋值或 return Expr
class Stmt : public BaseAST {
    public:
        BaseAST* expr;
        Var *var;
        int stmt_type;

        Stmt(BaseAST *e,int type,Var *name = NULL){
            expr = e;
            var = name;
            stmt_type = type;
        }

        virtual void print_koopa() {
            if(expr)
                expr->print_koopa();
            genInstr();
        }

        virtual void genInstr(int instrType = NoOperation) {
            if(stmt_type == Other)
                return;
            
            // 返回指令 
            if(stmt_type == Return) {
                ifReturn = 1;
                cout<<"  ret ";
                if(expr)
                    expr->output();
            } else if(stmt_type == Assign) {
                // 这里是变量的赋值语句 
                var->load_array();
                cout<<"  ";
                Symbol* symbol = findSymbol(var->id);
                symbol->value = expr->eval();
                cout<<"store ";
                expr->output();
                cout<<", ";
                var->output();
            }
            cout<<endl;
        }
        virtual int ifStmt(){return 1;}
};


// If 部分
class JumpStmt : public BaseAST {
    public:
        BaseAST *expr;
        BaseAST *then_stmt;
        BaseAST *else_stmt;
        int id;

        JumpStmt(BaseAST *e,BaseAST *s1,BaseAST *s2=NULL)
        {
            expr = e;
            then_stmt = s1;
            else_stmt = s2;
        }
        virtual void print_koopa()
        {   
            id = genJumpStmtId();
            expr->print_koopa();
            int then_block, else_block;   
            if(then_stmt)
                then_block = !then_stmt->ifEmptyBlock();  
            else
                then_block = 0;
            if(else_stmt)
                else_block = !else_stmt->ifEmptyBlock();
            else
                else_block = 0;
            if(!then_block && !else_block)   
                return;
            // 根据表达式断定 
            cout<<"  br ";
            expr->output();
            cout << ", %then_" << id << ", %else_" << id << endl;
            genBlock("then",id);
            // 执行 then_id 里面的语句 (if 成功)
            then_stmt->print_koopa();
            cout<<"  jump %end_"<<id<<endl;
            // else 的情况 
            genBlock("else",id);
            else_stmt->print_koopa();
            cout<<"  jump %end_"<<id<<endl;
            genBlock("end",id);
        }
        virtual int ifJumpStmt(){return 1;}
};

class WhileStmt : public BaseAST {
    public:
        BaseAST *expr;
        BaseAST *stmt;
        int id;
        WhileStmt(BaseAST *e,BaseAST *s=NULL) {
            expr = e;
            stmt = s;
        }

        virtual void print_koopa() {   

            id = genBlockId();
            while_stmt_id.push_back(id);

            cout<<"  jump %while_"<<id<<endl;

            genBlock("while",id);

            expr->print_koopa();

            cout<<"  br ";
            expr->output();   
            cout<<", %stmt_"<<id<<", %break_"<<id<<endl;

            // --------------------------- 上面做的事情是计算出 while 循环的条件和断定语句------------ 

            genBlock("stmt", id);

            if(stmt) {
                stmt->print_koopa();
                if(!ifJumpInstr(stmt) && !ifReturn)
                    cout << "  jump %while_" << id << endl;
            }
            else
                cout << "  jump %while_" << id << endl;

            genBlock("break",id);
            while_stmt_id.pop_back();
        }
};



// 计算表达式用的

class Expr : public BaseAST {
    public:
        BaseAST* left_expr;
        BaseAST* right_expr;
        int operation;
        int var=-1;


        Expr(BaseAST *right,BaseAST *left = NULL,int oper = NoOperation) {
            left_expr = left;
            right_expr = right;
            operation = oper;
        }

        virtual void print_koopa() { 
            var = genTempVar();
            if(left_expr){
                left_expr->print_koopa();
            }
            if(right_expr) {
                right_expr->print_koopa();  
            }
            genInstr(operation);
        }

        void putChildExpr() {
            left_expr  -> output();
            cout << ", ";
            right_expr -> output();
        }

        virtual int ifExpr(){
            return 1;
        }

        virtual void genInstr(int instrType) {  

            if(instrType == NoOperation)
                return;

            cout<<"  ";
            output();
            cout<<" = ";
            if(instrType == EqualZero){
                cout<<"eq ";
                right_expr->output();
                cout<<", 0";
            }else if(instrType == Invert){
                cout<<"sub 0, ";
                right_expr->output();
            }else if(instrType == NotEqualZero){
                cout<<"ne ";
                right_expr->output();
                cout<<", 0";
            } 

            if(instrType == Add){
                cout<<"add ";
            }else if(instrType == Sub){
                cout<<"sub ";
            }else if(instrType == Mul){
                cout<<"mul ";
            }else if(instrType == Div){
                cout<<"div ";
            }else if(instrType == Mod){
                cout<<"mod ";
            }else if(instrType == Less){
                cout<<"lt ";
            }else if(instrType == LessEq){
                cout<<"le ";
            }else if(instrType == Greater){
                cout<<"gt ";
            }else if(instrType == GreaterEq){
                cout<<"ge ";
            }else if(instrType == Equal){
                cout<<"eq ";
            }else if(instrType == NotEqual){
                cout<<"ne ";
            }else if(instrType == And){
                cout<<"and ";
            }else if(instrType == Or){
                cout<<"or ";
            }

            if(instrType >= Add && instrType <= Or) { 
                left_expr->output();
                cout<<", ";
                right_expr->output();
            }
            cout<<endl;
        }

        virtual void output() {
            cout<<"%"<<var;
        }

        virtual int ifBoolean() {
            if(operation >= Less && operation <= NotEqualZero) {
                return 1;
            }
            return 0;
        }

        virtual int eval() {
            // exit(0); 
            if(operation >= Add && operation <= Or) {
                int temp1 = left_expr->eval();
                int temp2 = right_expr->eval();
                if(operation == Add)
                    return temp1 + temp2;
                else if(operation == Sub)
                    return temp1 - temp2;
                else if(operation == Mul)
                    return temp1 * temp2;
                else if(operation == Div)
                {
                    if(temp2 == 0)  return 0;
                    return temp1 / temp2;
                }
                else if(operation == Mod)
                {
                    if(temp2 == 0)  return 0;
                    return temp1 % temp2;
                }
                else if(operation == Less)
                    return temp1 < temp2;
                else if(operation == Greater)
                    return temp1 > temp2;
                else if(operation == LessEq)
                    return temp1 <= temp2;
                else if(operation == GreaterEq)
                    return temp1 >= temp2;
                else if(operation == Equal)
                    return temp1 == temp2;
                else if(operation == NotEqual)
                    return temp1 != temp2;
                else if(operation == And)
                    return temp1 & temp2;
                else if(operation == Or)
                    return temp1 | temp2;
            }
            int temp = right_expr->eval();
            if(operation == NoOperation)
                return temp;
            else if(operation == Invert)
                return -temp;
            else if(operation == EqualZero)
                return temp == 0;
            else if(operation == NotEqualZero)
                return temp != 0;
            return 0;
        }
};



class Decls : public BaseAST {
    public:
        vector<DeclareDef*> defs;
        int type;
        Decls(int t=TypeInt) {
            type = t;
        }
        virtual int ifDecls(){return 1;}
        virtual void print_koopa() {}
};


// 大容器，来存储花括号里的代码 
class Block : public BaseAST
{
    public:
        vector<BaseAST*> stmts;
        virtual void print_koopa() {
            SymbolMap new_map;
            symbol_table.push_back(new_map);    
            int block_id = genBlockId();
            for(int i = 0;i < stmts.size();i++) {
                now_block_id = block_id;
                if(ifReturn)
                    break;   
                stmts[i]->print_koopa();    
            }
            delSymbolMap(*(symbol_table.rbegin()));
            symbol_table.pop_back();
        }
        virtual int ifBlock(){return 1;}
        virtual int ifEmptyBlock() {
            return stmts.size() == 0;
        }
};


// 输出一个函数中间代码（比如说 main 函数，func 函数等） 
class FuncDef : public BaseAST {
    public:
        int func_type;
        string id;

        // 这个 block 就是进入函数后的函数体 
        BaseAST* block;
        vector<DeclareDef*> params;

        virtual void print_koopa() {
            FuncInfo *func_info = new FuncInfo();
            func_info->func_type = func_type;

            ifReturn = 0;
            // 函数声明
            cout<<"fun @";
            cout<<id<<"(";

            // 函数的参数 
            for(int i=0;i < int(params.size());i++) {
                func_info->param_type.push_back(params[i]->type);

                vector<int> vec;
                cout<<"@"<<params[i]->name<<": ";
                for(int j=0;j < params[i]->offset.size();j++)
                    vec.push_back(params[i]->offset[j]->eval());   
                printType(params[i]->type, vec);
                if(i != int(params.size())-1)
                    cout<<", ";
            }
            cout<<")";

            // 全局函数表加入这个函数 
            func_table.emplace(id, func_info);
            if(func_type == TypeInt)
                cout<<": i32";  

            // 函数体
            cout<<" {\n%"<<"entry:\n";
            for(int i=params.size()-1;i >= 0;i--) {     
                // params[i] 的类型是 DeclareDef  

                // 把形参实例化，加入到函数 block 里面 
                ((Block*)block)->stmts.insert(((Block*)block)->stmts.begin(), params[i]);
            }
            // 处理没有返回语句的情况
            if(func_type==TypeInt)
            {
                Number *num = new Number();
                num->num = 0;
                Stmt *stmt = new Stmt((BaseAST*)num,Return);
                ((Block*)block)->stmts.push_back((BaseAST*)stmt);
            }
            else if(func_type == TypeVoid) {
                Stmt *stmt = new Stmt(NULL,Return);
                ((Block*)block)->stmts.push_back((BaseAST*)stmt);
            }

            block->print_koopa();
            cout<<"}\n\n";
        }
};

class Program : public BaseAST {
    public:
        vector<BaseAST*> units;
        virtual void print_koopa() {
            for(int i=0;i < units.size();i++) {
                units[i]->print_koopa();   
            }
        }
};


// 函数调用部分，这里来调用函数 
class FuncCall : public BaseAST {
    public:
        string name;
        vector<BaseAST*> params;
        int temp_var;

        virtual void print_koopa() {
            FuncInfo *func_info = func_table[name];
            int return_type = func_info->func_type;
            temp_var = genTempVar();
            // 先加载每个param
            for(int i = 0;i < params.size(); ++ i)  {
                switch (func_info->param_type[i]) {
                    case TypeInt:
                        params[i]->print_koopa();
                        break;
                }
            }
            cout << "  "; 
            if(return_type == TypeInt)
            {   
                cout<<"%"<<temp_var<<" = ";
            }
            cout<<"call @"<<name<<"(";
            for(int i=0;i < int(params.size())-1;i++)
            {
                params[i]->output();
                cout<<",";
            }
            if(params.size() != 0)
                (*params.rbegin())->output();
            cout<<")"<<endl;
        }

        virtual void output() {
            cout<<"%"<<temp_var;
        }
};


// 返回0表示需要生成jump语句
// 返回1表示基本块的最后是ret语句或其他不需要再生成jump的语句
static int ifJumpInstr(BaseAST *s) { 
    if(s->ifStmt()) {
        Stmt *stmt = (Stmt*)s;
        if(stmt->stmt_type == Return)
            return 1;
        if(stmt->stmt_type == Break || stmt->stmt_type == Continue)
            return 1;
    }
    else if(s->ifBlock()) {
        Block *block = (Block*)s;
        if(block->ifEmptyBlock()) return 0;
        return ifJumpInstr(*((block->stmts).rbegin()));
    }
    else if(s->ifJumpStmt()) {
        JumpStmt *stmt = (JumpStmt*)s;
        int ret1=0,ret2=0;
        if(stmt->then_stmt)
            ret1 = ifJumpInstr(stmt->then_stmt);
        if(stmt->else_stmt)
            ret2 = ifJumpInstr(stmt->else_stmt);
        return ret1 && ret2;
    }
    return 0;
}
