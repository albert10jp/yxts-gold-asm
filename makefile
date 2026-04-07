
all: gmud_data.bin obj.bin

tar: /tmp/gmud.tar

GA=ga6502
GL=gl

SRC2= end.s

SRC_GAME= org3800.s goods.dat skill.dat \
	  org4000.s a.s unr_sys.s pyh_quest.s \
	  lee1.s game.s gmud.s task.s \
	  skill.s goods.s npc_quest.s qlist.s \
	  stringx.s aux.s talk.s npc.s pyh.s inputx.s tools.s null.s \
	  orga100.s aux2.s lee3.s math.s draw.s mxxtbl.s lcd.s font.s system.s menu.s digit.s \
	  s_read.s bank2.s lee_block.s null2.s orgc000.s
SRC_GAME2= org3800.s goods.dat skill.dat \
	   org4000.s a2.s unr_sys.s lee2.s fight.s \
 	   string.s skilly.s goodsx.s \
	   string2.s perform.s hello.s input.s netengine.s null.s\
	   orga100.s aux2.s lee3.s math.s draw.s mxxtbl.s lcd.s font.s system.s menu.s digit.s \
	   s_read.s bank2.s lee_block.s null2.s orgc000.s
SRC_GAME3= org3800.s goods.dat skill.dat \
	   org4000.s a3.s unr_sys.s serve.s scroll.s save.s panyan.s \
	   stringy.s rank.s null.s \
	   orga100.s aux2.s lee3.s math.s draw.s mxxtbl.s lcd.s font.s system.s menu.s digit.s \
	   s_read.s bank2.s lee_block.s null2.s orgc000.s
SRC_GAME4= org3800.s goods.dat skill.dat \
	   org4000.s a4.s unr_sys.s cheat.s stringy.s \
	   orga100.s aux2.s lee3.s math.s draw.s mxxtbl.s lcd.s font.s system.s menu.s digit.s \
	   s_read.s bank2.s lee_block.s null2.s orgc000.s
SRC_IMG= org0000.s img_addr.s
SRC_TEXT= org0000.s unr_sys.s text_addr.s npc_quest.txt null.s \
	  orga600.s
SRC_OTHER= h/gmud.h h/id.h h/mud_funcs.h h/func.mac h/rom.h \
	   data/*.h data/*_data nf.s a.s a_down2.s makefile

obj.bin: # $(SRC_GAME) 		#1 bank
	$(GA) -oo -c../common.s $(SRC_GAME) 2>junk
	$(GL) -do -mmap1 -otmp  $(SRC_GAME) 2>junk2
	cutbin tmp 0x800 /dev/null obj.bin
	cat gmud_rom.bin >>obj.bin	#做成下载的四个bank
	rm -rf gmud_rom.bin

	xor4c obj.bin junk
	mv junk obj.bin
	cp obj.bin ../../nandsysdata/in/hero.bin

	$(GA) -oo -c../common.s a_down.s 2>junk
	$(GL) -do -a16384 -oobj a_down.s 2>junk2
	
	cat obj obj.bin >down.bin
	putlen down.bin
	jm down.bin
	rm -f down.bin
	cp jm.obj hero.bin

	rm -f junk* tmp

gmud_data.bin: prog2.bin text.bin img.bin #3 bank
	cat prog2.bin text.bin img.bin > gmud_rom.bin
	rm prog2.bin text.bin img.bin

prog2.bin: $(SRC_GAME2) 		#1 bank
	$(GA) -oo -c../common.s $(SRC_GAME2)  2>junk
	$(GL) -do -mmap2 -otmp $(SRC_GAME2)  2>junk2
	cutbin tmp 0x800 /dev/null tmp1
	padxx tmp1 obj1 6100

	$(GA) -oo -c../common.s $(SRC_GAME4)  2>junk
	$(GL) -do -mmap4 -otmp $(SRC_GAME4)  2>junk2
	cutbin tmp 0x800 /dev/null tmp1
	padxx tmp1 obj2 1f00
	cat obj1 obj2 > prog2.bin
	rm junk* obj1 obj2 tmp*

img.bin:
	cp data/img/gmud_img.bin obj1
	cp data/map/gmud.map obj2
	padxx obj2 obj3 8000
	cat obj1 obj3 > img.bin
	rm obj*

text.bin: $(SRC_TEXT) $(SRC2)	#1 bank
	$(GA) -oo -c../common.s org2000.s player.s org3200.s 2>junk
	$(GL) -do -mmap7 -oobjx org2000.s player.s org3200.s 2>junk2

	$(GA) -oo -c../common.s $(SRC_GAME3) 2>junk
	$(GL) -do -mmap3 -otmp $(SRC_GAME3) 2>junk2
	padxx tmp objxx 4800

	$(GA) -oo -c../common.s $(SRC_TEXT)  2>junk
	$(GL) -do -mmap5 -oobj $(SRC_TEXT) 2>junk2
	rm -f text.bin
	cat obj objx objxx >>text.bin
	rm -f obj objx objxx tmp
	rm junk*

del:	
	$(GA) -oo -c../common.s org4000.s a.s unr_sys.s del.s 2>junk
	$(GL) -do -odel.bin org4000.s a.s unr_sys.s del.s 2>junk2

	#cp del.bin ../../nandsysdata_f/in/del.bin
	
	$(GA) -oo -c../common.s a_down2.s 2>junk
	$(GL) -do -a16384 -oobj a_down2.s 2>junk2
	
	cat obj del.bin >down.bin
	putlen down.bin
	jm down.bin
	rm -f down.bin
	cp jm.obj del.bin

	rm -f junk* 
	
#**************************************************************

/tmp/gmud.tar: $(SRC_GAME) $(SRC_IMG) $(SRC_TEXT) $(SRC_OTHER) $(SRC_GAME2)
	tar -cf $@ $(SRC_GAME) $(SRC_IMG) $(SRC_TEXT) $(SRC_OTHER) $(SRC_GAME2)

line:
	wc -l $(SRC_GAME) $(SRC_GAME2)

allline:
	wc -l $(SRC_GAME) $(SRC_IMG) $(SRC_TEXT) $(SRC_OTHER) $(SRC_GAME2)

zpmap:
	$(GA) -c../common.s -s -f h/gmud.h > .zpmap
clean cleanall:
	rm -f o/*.o obj map map1 map2 map3 core *.bin junk* jm.obj
