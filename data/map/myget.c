#include <stdio.h>
/*
 * 处理地图文件,从中提取数据并转化成6502的数据定义格式
 *
 */

main (int argc, char *argv[])
{
  FILE *fp;
  unsigned char c1, c2;
  int i,len;
  int map_num=2;

  fp = fopen (argv[1], "r");

  c1=fgetc(fp);c2=fgetc(fp);
  printf("\tdb\t0%xh,0%xh\t;地图总数\n",c1,c2);
  c1=fgetc(fp);c2=fgetc(fp);
  printf("\tdb\t0%xh,0%xh\t;门的总数\n",c1,c2);
  printf("\tdb\t0%xh\t;主角所在地图号\n",fgetc(fp));
  printf("\tdb\t0%xh\t;主角X坐标\n",fgetc(fp));
  printf("\tdb\t0%xh\t;主角Y坐标\n",fgetc(fp));
  c1=fgetc(fp);c2=fgetc(fp);
  printf("\tdb\t0%xh,0%xh\t;门的地址\n",c1,c2);
  c1=fgetc(fp);c2=fgetc(fp);
  printf("\tdb\t0%xh,0%xh\t;NPC的地址\n",c1,c2);

  len=ftell(fp);
  for(i=0;i<map_num;i++)
  {
  	c1=fgetc(fp);c2=fgetc(fp);
 	printf("\tdb\t0%xh,0%xh\t;map%d的地址\n",c1,c2,i);
  }
 
  printf("\n\t;地图数据\n");
  while (!feof (fp))
    {
      c1 = fgetc (fp);
      c2 = fgetc (fp);
      printf ("\tdb\t0%xh,0%xh\n", c1, c2);
    }

  fclose (fp);
}
