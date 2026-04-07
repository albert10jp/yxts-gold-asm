
all: gmud_img.bin

GA=ga6502
GL=gl

SRC_DATA1= data1.s
SRC_DATA2= data2.s
SRC_DATA3= data3.s
SRC_DATA4= data4.s

gmud_img.bin: data1.bin data2.bin data3.bin data4.bin 

	cat data1.bin data2.bin data3.bin data4.bin >gmud_img.bin
	#down /home/pyh/GP162/obj.bin data.bin 180 4	#174=80h+46+6
	rm -f data*.bin junk obj* map*

data1.bin: $(SRC_DATA1)

	$(GA) -oo -c../../../common.s $(SRC_DATA1) 2>junk
	$(GL) -do -a16384 -mmap -oobj $(SRC_DATA1) 2>junk
	rm -f data1.bin
	padff obj data1.bin 8000
	swap4000 data1.bin

data2.bin: $(SRC_DATA2)

	$(GA) -oo -c../../../common.s $(SRC_DATA2) 2>junk
	$(GL) -do -a16384 -mmap -oobj $(SRC_DATA2) 2>junk
	rm -f data2.bin
	padff obj data2.bin 8000
	swap4000 data2.bin

data3.bin: $(SRC_DATA3)

	$(GA) -oo -c../../../common.s $(SRC_DATA3) 2>junk
	$(GL) -do -a16384 -mmap -oobj $(SRC_DATA3) 2>junk
	rm -f data3.bin
	padff obj data3.bin 8000
	swap4000 data3.bin

data4.bin: $(SRC_DATA3)

	$(GA) -oo -c../../../common.s $(SRC_DATA4) 2>junk
	$(GL) -do -a16384 -mmap -oobj $(SRC_DATA4) 2>junk
	rm -f data4.bin
	padff obj data4.bin 8000
	swap4000 data4.bin

#**************************************************************
clean cleanall:
	rm -f *.bin
