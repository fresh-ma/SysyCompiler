# 编译原理课程设计 SysyCompiler

一个能够将SysY2022语言编译出汇编指令RISK-V的编译器



## 创建 Docker
```
docker run -it --rm -v .\sysy-compiler-master:/root/compiler -v .\build:/root/build maxxing/compiler-dev bash
```



## test case 

Simple case: 
```cpp
int main() {
	int x = 2; 
	int y = 3; 
	while(x <= 10) {
		x = x + 1; 
		y = y + x; 
	}
	return 0; 
}
```

Hard Case: 
```cpp
int func(int x) {
	return x * x; 
}
int main() {
	int x = 0; 
	int y = 1; 
	int z = x + y; 
	while(x <= 10) {
		x = x + 1; 
	}
    if(x > 20) {
        y = 23; 
    }
    else {
        y = 50;
    }

	int yy = func(x) + x; 

	return 0; 
}
```

compile configure
```c++ 

编译：
cd /root/build && cmake ../compiler && make

运行：
cd /root/build && ./compiler -koopa

编译 & 运行：
cd /root/build && cmake ../compiler && make && cd /root/build && ./compiler -koopa
```
