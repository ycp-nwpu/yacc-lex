#include <stdio.h>
int main()
{
	int a=3;
	int b=10;
	int c = 0;
	if(a!=b){
		c = a+b;
		if(a>b){
			c = a-b;
		}
		else{
			printf("a smaller than b");
			c = b-a;
		}
	}
	else{
		c = b/a;
	}
	return 0;
}
