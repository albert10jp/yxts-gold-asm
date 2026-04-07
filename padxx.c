#include <stdio.h>
#include <stdlib.h>

long my16to2(char *p)
{
	long ret;
	char c;

	ret=0;
	while (c=*p++) {
		if (c>='0' && c<='9')
			ret=ret*16+c-'0';
		else if (c>='A' && c<='F')
			ret=ret*16+c-'A'+10;
		else if (c>='a' && c<='f')
			ret=ret*16+c-'a'+10;
		else
			break;
	}
	return ret;
}

main(int argc,char *argv[])
{
	FILE *input,*output;
	long i,len;
	int c;

	if (argc<4)
		exit(1);
	if ((input=fopen(argv[1],"rb"))==NULL)
		exit(1);
	if ((output=fopen(argv[2],"wb"))==NULL)
		exit(1);
	len=my16to2(argv[3]);
	
	i=0;
	while ((c=getc(input))!=EOF) {
		putc(c,output);
		i++;
		if (i>=len)
			break;
	}
	while (i<len) {
		putc(random()^0xff,output);
		i++;
	}
	fclose(input);
	fclose(output);
	exit(0);
}
		








	
	
