volatile unsigned char * const UART_ADDR = (unsigned char*)0x10000000;

void uart_putchar(char c){
	*UART_ADDR = c;
}

int main(){
	char const *s = "Hello RISC-V with C\n";
	char c = '\0';
	while((c = *s++) != '\0'){
		uart_putchar(c);
	}
	return 0;
}
