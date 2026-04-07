#include <stdio.h>

main (int argc, char *argv[])
{
  FILE *fp;
  unsigned char c1, c2;
  int len;

  fp = fopen (argv[1], "r");

  fseek (fp, 32, SEEK_SET);
  c1 = fgetc (fp);	//width
  fseek (fp, 36, SEEK_SET);
  c2 = fgetc (fp);	//height
  printf ("\tdb\t0%xh,0%xh\n", c1, c2);

  fseek (fp, 48, SEEK_SET);
  while (!feof (fp))
    {
      c1 = fgetc (fp);
      c2 = fgetc (fp);
      printf ("\tdb\t0%xh,0%xh\n", c1, c2);
    }

  fclose (fp);
}
