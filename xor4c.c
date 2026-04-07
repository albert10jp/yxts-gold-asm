#include <stdio.h>
#include <stdlib.h>

main(int argc,char *argv[])
{
	FILE *input,*output;
	long i,len;
	int c;

	if (argc<3)
		exit(1);
	if ((input=fopen(argv[1],"rb"))==NULL)
		exit(1);
	if ((output=fopen(argv[2],"wb"))==NULL)
		exit(1);
	
	i=0;
	while ((c=getc(input))!=EOF) {
		if (i<32768)
			putc(c,output);
		else
			putc(c^0xaa,output);
		i++;
	}
	fclose(input);
	fclose(output);
	exit(0);
}
		








	
	
