#include <stdio.h>
int foo(){
	int c = 9;
	int d = c*2;
	return c;
}
int main()
{
	int a;
	int b = foo;
	return 0;
}
