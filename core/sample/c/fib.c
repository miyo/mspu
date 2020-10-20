volatile unsigned char * const UART_ADDR = (unsigned char*)0x10000000;
volatile unsigned char * const MEM_ADDR = (unsigned char*)0x20000000;

void uart_putchar(char c){
	*UART_ADDR = c;
}

void print_digit(int n){
	char mesg[10];
	int i = 0;
	while(1){
		int x = n % 10;
		mesg[i] = (char)('0' + x);
		n /= 10;
		if(n == 0) break;
		i++;
	}	
	uart_putchar(mesg[i]);
	while(i > 0){
		i--;
		uart_putchar(mesg[i]);
        }
	return ;
}

int fib(int n){
	if(n == 0){
		return 1;
	}else if(n == 1){
		return 1;
	}else{
		return fib(n-1) + fib(n-2);
	}
}

int test(int a){
	int n = fib(a);
	int i = 0;
	uart_putchar('f');
	uart_putchar('i');
	uart_putchar('b');
	uart_putchar('(');
	print_digit(a);
	uart_putchar(')');
	uart_putchar('=');
	print_digit(n);
	uart_putchar('\n');
	return 0;
}

int main(){
	int i;
	for(i = 0; i <= 10; i++){
		test(i);
	}
}
