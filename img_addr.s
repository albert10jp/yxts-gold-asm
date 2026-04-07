img_man_user	equ	0b000h
img_class_tbl:
	dw	img_man_tbl
	dw	img_street_tbl
	dw	img_road_tbl
	dw	img_rooma_tbl
	dw	img_roomb_tbl
	dw	img_roomc_tbl
	dw	img_npc_tbl
	dw	img_item_tbl
	dw	img_static_tbl
	dw	img_sign_tbl
	dw	img_head_tbl
	dw	img_tail_tbl
	dw	img_exit_tbl
	dw	img_other_tbl
	dw	img_animal_tbl

img_man_tbl:
	dw	img_man_front
	dw	img_man_front
	dw	img_man_behind
	dw	img_man_behind
	dw	img_man_left
	dw	img_man_leftwalk
	dw	img_man_right
	dw	img_man_rightwalk

	dw	img_man2_front
	dw	img_man2_front
	dw	img_man2_behind
	dw	img_man2_behind
	dw	img_man2_left
	dw	img_man2_leftwalk
	dw	img_man2_right
	dw	img_man2_rightwalk

	dw	img_man3_front
	dw	img_man3_front
	dw	img_man3_behind
	dw	img_man3_behind
	dw	img_man3_left
	dw	img_man3_leftwalk
	dw	img_man3_right
	dw	img_man3_rightwalk

	if	0
	;width<=16 height<=16 bytes=(16+1)*2
	;total size: 34*6=204
	dw	img_man_user
	dw	img_man_user
	dw	img_man_user+34
	dw	img_man_user+34
	dw	img_man_user+34*2
	dw	img_man_user+34*3
	dw	img_man_user+34*4
	dw	img_man_user+34*5
	endif

img_street_tbl:
img_rooma_tbl:
;!!img_house10-11 img_hole3 no use
	dw	img_build1
	dw	img_build1
	dw	img_build2
	dw	img_build2
	dw	img_build3
	dw	0		;!!img_build4 no use
	dw	img_castle2
	dw	img_castle3
	dw	img_castle3
	dw	img_castle4
	dw	img_hole2
	dw	img_hole2
	dw	img_house1
	dw	img_house1
	dw	img_house1
	dw	img_house2
	dw	img_house2
	dw	img_house2
	dw	img_house3
	dw	img_house4
	dw	img_house5
	dw	img_house5
	dw	img_house5
	dw	img_house6
	dw	img_house6
	dw	img_house7
	dw	img_house8
	dw	img_shop1
	dw	img_shop2
	dw	img_shop3
	dw	img_shop4
	dw	img_shop5
	dw	img_tower1
	dw	img_tower2
	dw	img_tower3
	dw	img_tower4

img_roomb_tbl:
	dw	img_castle1
	dw	img_hole
	dw	img_hole
	dw	img_hole
	dw	img_hole
	dw	img_hole
	dw	img_wuguan
	dw	img_yamen

img_roomc_tbl:		;!!img_stair4 no use
	dw	img_stair1
	dw	img_stair2
	dw	img_stair1
	dw	img_stair1
	dw	img_stair1
	dw	img_stair1
	dw	img_stair1
	dw	img_stair1
	dw	img_stair3
	dw	img_stair3

img_road_tbl:
	dw	img_road7
	dw	img_road2
	dw	img_road3
	dw	img_road5
	dw	img_road4
	dw	img_road1
	dw	img_road1

img_npc_tbl:			;!!img_boy12 no use
;!!img_boy49-56 img_girl22-24 img_animal1-8 no use
	dw	0
	dw	img_girl9	;aqing
	dw	img_boy14	;boy
	dw	img_boy11	;bukuai
	dw	img_boy26	;caihuad
	dw	img_boy21	;cooker
	dw	img_boy8	;cunzhang
	dw	img_boy13	;daxia
	dw	img_boy26	;dujiaod
	dw	img_girl14	;flower
	dw	img_girl5	;furen
	dw	img_boy17	;gelangtai
	dw	img_boy56	;daode
	dw	img_boy24	;gongzi
	dw	img_boy39	;guanshi1
	dw	img_boy39	;guanshi2
	dw	img_boy7	;guard
	dw	img_boy1	;guest
	dw	img_boy26	;heiyid
	dw	img_girl12	;hetieshou
	dw	img_boy10	;hexi
	dw	img_boy29	;liumang
	dw	img_boy28	;liumangtou
	dw	img_boy19	;whitelee
	dw	img_girl7	;oldlady
	dw	img_boy27	;pingyizhi
	dw	img_boy18	;seller
	dw	img_boy6	;shutong
	dw	img_boy7	;tailor1
	dw	img_boy36	;tailor2
	dw	img_boy8	;teacher
	dw	img_boy2	;tiaofu
	dw	img_boy3	;tuanding
	dw	img_boy3	;tufu
	dw	img_boy20	;waiter
	dw	img_boy22	;xunbu
	dw	img_boy40	;yanshang
	dw	img_boy18	;zahuofan
	dw	img_boy15	;baozhen
	dw	img_boy7	;bjiaotou
	dw	img_girl10	;chunhua
	dw	img_boy3	;huyuan
	dw	img_boy8	;jianjie
	dw	img_boy42	;jianming
	dw	img_boy9	;jianying
	dw	img_girl20	;laotai
	dw	img_boy10	;pingasi
	dw	img_boy34	;weiyang
	dw	img_boy7	;xingkong
	dw	img_boy1	;xu
	dw	img_boy31	;yan
	dw	img_boy2	;zhuangding
	dw	img_girl10	;chahua
	dw	img_girl17	;gongsun
	dw	img_girl11	;hongfu
	dw	img_girl2	;luzhu
	dw	img_girl19	;pingpopo
	dw	img_girl6	;qinghong
	dw	img_girl18	;qingzhao
	dw	img_girl2	;ruhua
	dw	img_girl7	;ruipopo
	dw	img_girl16	;rushi
	dw	img_girl4	;shishi
	dw	img_girl2	;shishu
	dw	img_girl1	;siqi
	dw	img_girl2	;tingqin
	dw	img_girl13	;wangci
	dw	img_girl2	;xiaohong
	dw	img_girl8	;xuetao
	dw	img_girl18	;yinniang
	dw	img_boy24	;baiyijiao
	dw	img_boy45	;chonger
	dw	img_boy41	;chuhongdeng
	dw	img_boy35	;fangzhanglao
	dw	img_boy43	;hanzhanglao
	dw	img_boy24	;heiyijiao
	dw	img_boy24	;hongyijiao
	dw	img_boy24	;lanyijiao
	dw	img_boy4	;qilintian
	dw	img_girl14	;tangsier
	dw	img_boy41	;yuhongru
	dw	img_boy34	;bingwei
	dw	img_boy30	;daxiong
	dw	img_boy46	;huowu
	dw	img_boy32	;langren1
	dw	img_boy32	;langren2
	dw	img_girl5	;muzi
	dw	img_girl16	;meina
	dw	img_boy23	;sun
	dw	img_boy47	;tailang
	dw	img_boy48	;tengwang
	dw	img_boy31	;tianjing
	dw	img_boy7	;yebi
	dw	img_boy16	;youjing
	dw	img_boy34	;zhongyang
	dw	img_boy19	;caiyao
	dw	img_boy23	;cangyue
	dw	img_boy23	;gusong
	dw	img_boy16	;guxu
	dw	img_boy2	;mingyue
	dw	img_boy2	;qingfeng
	dw	img_boy23	;qingxu
	dw	img_boy1	;shaofan
	dw	img_girl10	;taohua
	dw	img_boy29	;tufei1
	dw	img_boy28	;tufei2
	dw	img_girl15	;xiangke
	dw	img_boy1	;yingke
	dw	img_boy22	;zhike
	dw	img_girl3	;axiu
	dw	img_boy33	;bairuide
	dw	img_boy7	;fulai
	dw	img_boy25	;ouyang
	dw	img_boy4	;qiangang
	dw	img_boy3	;qianmeng
	dw	img_girl5	;qianrou
	dw	img_girl20	;shipopo
	dw	img_girl6	;wanhong
	dw	img_boy11	;wanjian
	dw	img_boy5	;wanren
	dw	img_boy9	;wanzhong
	dw	img_boy10	;wanyi
	dw	img_boy44	;xjiaotou
	dw	img_xuebao	;xuebao
	dw	img_boy28	;killer
	dw	img_boy1
	dw	img_girl1
	dw	img_boy56

img_item_tbl:
	dw	img_bed
	dw	img_book
	dw	img_bottle
	dw	img_brick
	dw	img_broom
	dw	img_computer
	dw	img_lake	;img_fish
	dw	img_hill1
	dw	img_hill2
	dw	img_hill3
	dw	img_hill4
	dw	img_mat
	dw	img_pail
	dw	img_stage
	dw	img_sword1
	dw	img_well
	dw	img_wood
	dw	img_tree5
	dw	img_shelf4
	dw	img_magic

img_static_tbl:
	dw	img_bars
	dw	img_bench1
	dw	img_bench2
	dw	img_bench3
	dw	img_bench4
	dw	img_bench5
	dw	img_bench6
	dw	img_counter1
	dw	img_counter2
	dw	img_counter3
	dw	img_counter4
	dw	img_counter5
	dw	img_counter6
	dw	img_counter7
	dw	img_desk1
	dw	img_desk2
	dw	img_desk3
	dw	img_desk4
	dw	img_desk5
	dw	img_desk6
	dw	img_desk7
	dw	img_desk8
	dw	img_desk9
	dw	img_desk10
	dw	img_dwell1
	dw	img_dwell2
	dw	img_dwell3
	dw	img_flower1
	dw	img_flower2
	dw	img_flower3
	dw	img_flower4
	dw	img_flower5
	dw	img_flower6
	dw	img_flower7
	dw	img_flower8
	dw	img_gate
	dw	img_horse
	dw	img_lake
	dw	img_lake2
	dw	img_lamp
	dw	img_leaf
	dw	img_pillar1
	dw	img_pillar2
	dw	img_pillar3
	dw	img_pillar4
	dw	img_plant1
	dw	img_plant2
	dw	img_plant3
	dw	img_plant4
	dw	img_sculpture1
	dw	img_sculpture2
	dw	img_sculpture3
	dw	img_sculpture4
	dw	img_sculpture5
	dw	img_sculpture6
	dw	img_shelf1
	dw	img_shelf2
	dw	img_shelf3
	dw	img_shelf4
	dw	img_shelf5
	dw	img_shelf6
	dw	img_stone1
	dw	img_stone2
	dw	img_stone3
	dw	img_tree1
	dw	img_tree2
	dw	img_tree3
	dw	img_tree4
	dw	img_tree5
	dw	img_tree6
	dw	img_tv1
	dw	img_tv2
	dw	img_wall1
	dw	img_wall2
	dw	img_wall3
	dw	img_wall4
	dw	img_wall5
	
img_sign_tbl:
	dw	img_sign
img_head_tbl:		;16
	dw	img_arrow_up
	dw	img_road2
	dw	img_road6
	dw	img_leaf
	dw	img_road5
	dw	img_road1
	dw	img_road7
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_right
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
img_tail_tbl:
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up	;path
	dw	img_arrow_up
	dw	img_arrow_left
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_up
	dw	img_arrow_left
	dw	img_arrow_up
	dw	img_arrow_up
img_exit_tbl:
	dw	img_arrow_up
	
img_other_tbl:
	dw	img_arrow2
	dw	img_arrow3
	dw	img_arrow4
img_animal_tbl:
	dw	img_animal1
	dw	img_animal2
	dw	img_animal3
	dw	img_animal4
	dw	img_animal5
	dw	img_animal6
	dw	img_animal7
	dw	img_animal8
	include data/image_data
;------------------------------------------------------------------
	end
