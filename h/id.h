;cLass
__base	equ	0
	define	1,MAN_CLASS
	define	1,STREET_CLASS
	define	1,ROAD_CLASS
	define	1,ROOMA_CLASS
	define	1,ROOMB_CLASS
	define	1,ROOMC_CLASS
	define	1,NPC_CLASS
	define	1,ITEM_CLASS
	define	1,STATIC_CLASS
	define	1,SIGN_CLASS
	define	1,HEAD_CLASS
	define	1,TAIL_CLASS
	define	1,EXIT_CLASS
	define	1,OTHER_CLASS
	define	1,ANIMAL_CLASS

;man
__base	equ	0
	define	1,MAN_FRONT_ID
	define	1,MAN_FRONTWALK_ID
	define	1,MAN_BEHIND_ID
	define	1,MAN_BEHINDWALK_ID
	define	1,MAN_LEFT_ID
	define	1,MAN_LEFTWALK_ID
	define	1,MAN_RIGHT_ID
	define	1,MAN_RIGHTWALK_ID

;npc
__base	equ	0
	define	1,NONE_NPC
	define	1,AQING_NPC
	define	1,BOY_NPC
	define	1,BUKUAI_NPC
	define	1,CAIHUAD_NPC
	define	1,COOKER_NPC
	define	1,CUNZHANG_NPC
	define	1,DAXIA_NPC
	define	1,DUJIAOD_NPC
	define	1,FLOWER_NPC
	define	1,FUREN_NPC
	define	1,GELANGTAI_NPC
	define	1,DAODE_NPC
	define	1,GONGZI_NPC
	define	1,GUANSHI1_NPC
	define	1,GUANSHI2_NPC
	define	1,GUARD_NPC
	define	1,GUEST_NPC
	define	1,HEIYID_NPC
	define	1,HETIESHOU_NPC
	define	1,HEXI_NPC
	define	1,LIUMANG_NPC
	define	1,LIUMANGTOU_NPC
	define	1,MAO17_NPC
	define	1,LIBAI_NPC
	define	1,OLDLADY_NPC
	define	1,PINGYIZHI_NPC
	define	1,SELLER_NPC
	define	1,SHUTONG_NPC
	define	1,TAILOR1_NPC
	define	1,TAILOR2_NPC
	define	1,TEACHER_NPC
	define	1,TIAOFU_NPC
	define	1,TUANDING_NPC
	define	1,TUFU_NPC
	define	1,WAITER_NPC
	define	1,XUNBU_NPC
	define	1,YANSHANG_NPC
	define	1,ZAHUOFAN_NPC
	define	1,BAOZHEN_NPC
	define	1,BJIAOTOU_NPC
	define	1,CHUNHUA_NPC
	define	1,HUYUAN_NPC
	define	1,JIANJIE_NPC
	define	1,JIANMING_NPC
	define	1,JIANYING_NPC
	define	1,LAOTAI_NPC
	define	1,PINGASI_NPC
	define	1,WEIYANG_NPC
	define	1,XINGKONG_NPC
	define	1,XU_NPC
	define	1,YAN_NPC
	define	1,ZHUANGDING_NPC
	define	1,CHAHUA_NPC
	define	1,GONGSUN_NPC
	define	1,HONGFU_NPC
	define	1,LUZHU_NPC
	define	1,PINGPOPO_NPC
	define	1,QINGHONG_NPC
	define	1,QINGZHAO_NPC
	define	1,RUHUA_NPC
	define	1,RUIPOPO_NPC
	define	1,RUSHI_NPC
	define	1,SHISHI_NPC
	define	1,SHISHU_NPC
	define	1,SIQI_NPC
	define	1,TINGQIN_NPC
	define	1,WANGCI_NPC
	define	1,XIAOHONG_NPC
	define	1,XUETAO_NPC
	define	1,YINNIANG_NPC
	define	1,BAIYIJIAO_NPC
	define	1,CHONGER_NPC
	define	1,CHUHONGDENG_NPC
	define	1,FANGZHANGLAO_NPC
	define	1,HANZHANGLAO_NPC
	define	1,HEIYIJIAO_NPC
	define	1,HONGYIJIAO_NPC
	define	1,LANYIJIAO_NPC
	define	1,QILINTIAN_NPC
	define	1,TANGSIER_NPC
	define	1,YUHONGRU_NPC
	define	1,BINGWEI_NPC
	define	1,DAXIONG_NPC
	define	1,HUOWU_NPC
	define	1,LANGREN1_NPC
	define	1,LANGREN2_NPC
	define	1,MUZI_NPC
	define	1,MEINA_NPC
	define	1,SUN_NPC
	define	1,TAILANG_NPC
	define	1,TENGWANG_NPC
	define	1,TIANJING_NPC
	define	1,YEBI_NPC
	define	1,YOUJING_NPC
	define	1,ZHONGYANG_NPC
	define	1,CAIYAO_NPC
	define	1,CANGYUE_NPC
	define	1,GUSONG_NPC
	define	1,GUXU_NPC
	define	1,MINGYUE_NPC
	define	1,QINGFENG_NPC
	define	1,QINGXU_NPC
	define	1,SHAOFAN_NPC
	define	1,TAOHUA_NPC
	define	1,TUFEI1_NPC
	define	1,TUFEI2_NPC
	define	1,XIANGKE_NPC
	define	1,YINGKE_NPC
	define	1,ZHIKE_NPC
	define	1,AXIU_NPC
	define	1,BAIRUIDE_NPC
	define	1,FULAI_NPC
	define	1,OUYANG_NPC
	define	1,QIANGANG_NPC
	define	1,QIANMENG_NPC
	define	1,QIANROU_NPC
	define	1,SHIPOPO_NPC
	define	1,WANHONG_NPC
	define	1,WANJIAN_NPC
	define	1,WANREN_NPC
	define	1,WANZHONG_NPC
	define	1,WANYI_NPC
	define	1,XJIAOTOU_NPC
	define	1,XUEBAO_NPC
	define	1,KILLER_NPC	;124
NPC_NUM		equ	__base
	define	1,BOSS1_NPC
	define	1,BOSS2_NPC
	define	1,BOSS3_NPC

;item
__base	equ	0
	define	1,BED_ID
	define	1,BOOK_ID
	define	1,BOTTLE_ID
	define	1,BRICK_ID
	define	1,BROOM_ID
	define	1,COMPUTER_ID
	define	1,FISH_ID
	define	1,HILL1_ID
	define	1,HILL2_ID
	define	1,HILL3_ID
	define	1,HILL4_ID
	define	1,MAT_ID
	define	1,PAIL_ID
	define	1,STAGE_ID
	define	1,SWORD1_ID
	define	1,WELL_ID
	define	1,WOOD_ID
	define	1,SUICIDE_ID
	define	1,BOARD_ID
	define	1,MAGIC_ID

;sign
__base	equ	0
	define	1,STREET_SIGN
	define	1,BAGUA_SIGN
	define	1,FLOWER_SIGN
	define	1,HONGLIAN_SIGN
	define	1,NAJA_SIGN
	define	1,TAIJI_SIGN
	define	1,XUESHAN_SIGN

;---------------------------------------------------------------
;text:
__base	equ	0
	define	1,NPC_NAME
	define	1,NPC_DATA
	define	1,KF_TEXT
	define	1,OTHER_TEXT
	define	1,NPC_ID
	define	1,NPC_QUEST
	define	1,NPC_EXP
	define	1,PERFORM_TEXT
	define	1,GOODS_DESC

;other_text
__base	equ	0
	define	1,THEME_TEXT

;---------------------------------------------------------------
;goods_type
__base	equ	0
	define	1,FOOD_WU
	define	1,DRUG_WU
	define	1,WEAPON_WU
	define	1,EQUIP_WU
	define	1,BOOK_WU
	define	1,OTHER_WU

;goods_id	76+1
__base	equ	0
	define	1,NONE_GOODS
	define	1,CHICKEN
	define	1,BAOZI
	define	1,BUTTER_TEA
	define	1,GREEN_DOUFU
	define	1,MEAT
	define	1,TANG_HULU
	define	1,WHITE_DOUFU
	define	1,YAO
	define	1,SHENGJI
	define	1,DAN
	define	1,BLADE
	define	1,KITCHEN_KNIFE
	define	1,DAGGER
	define	1,FAN
	define	1,HOCK
	define	1,KNIFE
	define	1,LONG_SWORD
	define	1,NEEDLE
	define	1,ROPE
	define	1,SCISSORS
	define	1,STAFF
	define	1,WHIP
	define	1,GUI_BLADE
	define	1,GOLD_BLADE
	define	1,FLOWER_WHIP
	define	1,FUCHEN
	define	1,LBLADE
	define	1,RED_FUCHEN
	define	1,XIAO
	define	1,FLOWER_FAN
	define	1,HETUN_BLADE
	define	1,GANG_ZHANG
	define	1,QINGFENG_SWORD
	define	1,TIE_GUAI
	define	1,TIE_SWORD
	define	1,CHUFEI_SWORD
	define	1,NINGBI_SWORD
	define	1,XI_JIAN
	define	1,BLACK_CLOTH
	define	1,GLASSES
	define	1,GREEN_FLOWER
	define	1,CLOTH
	define	1,FINE_CLOTH
	define	1,BEIXIN
	define	1,PINK_CLOTH
	define	1,RED_FLOWER
	define	1,SHOES
	define	1,WHITE_ROSE
	define	1,TEA_FLOWER
	define	1,FCLOTH
	define	1,FSHOES
	define	1,SILK_CLOTH
	define	1,NIGHT_CLOTH
	define	1,FANCY_SKIRT
	define	1,SKIRT
	define	1,EYE_PATCH
	define	1,PIFENG
	define	1,MARTIAL_CLOTH
	define	1,TAOIST_CLOTH
	define	1,BAIPAO
	define	1,CHOUPAO
	define	1,GOLD_ARMOR
	define	1,XIANGMO_PAO
	define	1,NIHONG_YUYI
	define	1,SNOW_BAIPAO
	define	1,SILVER_ARMOR
	define	1,BAOPI
	define	1,HAND_BOOK
	define	1,YELLOW_PAPER
	define	1,BLADE_BOOK
	define	1,FORCE_BOOK
	define	1,BRUSH
	define	1,DIAOGAN
	define	1,FISH
	define	1,SKIN_BELT
	define	1,YULOU
	define	1,SANJIAO
	define	1,MEIJIU
	define	1,TULONG
	define	1,XIUHUA
	define	1,BAODIAN
;-----goods_id ²¹¶¡--------------------
LONGSWORD	equ	LONG_SWORD
CHA_FLOWER	equ	TEA_FLOWER
TIEGUAI		equ	TIE_GUAI
GANGZHANG	equ	STAFF
LUOYI		equ	FANCY_SKIRT
TIEJIAN		equ	TIE_SWORD
XIANGPAO	equ	BAIPAO
XUESHAN_PAO	equ	SNOW_BAIPAO
XIJIAN		equ	XI_JIAN
;-----goods_id ²¹¶¡--------------------

;weapon_type
__base	equ	0
	define	1,AXE_QI	;Ã¬
	define	1,BLADE_QI	;µ¶
	define	1,CLUB_QI	;¹÷°ô
	define	1,DAGGER_QI	;¸«
	define	1,FORK_QI	;²æ
	define	1,HAMMER_QI	;´¸
	define	1,SWORD_QI	;½£
	define	1,STAFF_QI	;ÕÈ¸Ë
	define	1,THROW_QI	;°µÆ÷
	define	1,WHIP_QI	;±Þ

;armor_type
__base	equ	0
	define	1,HEAD_ARM
	define	1,NECK_ARM
	define	1,CLOTH_ARM
	define	1,ARMOR_ARM
	define	1,SURCOAT_ARM
	define	1,WAIST_ARM
	define	1,WRISTS_ARM
	define	1,SHIELD_ARM
	define	1,FINGER_ARM
	define	1,HANDS_ARM
	define	1,BOOTS_ARM

;kf:
;------------------------------------------------------------
;kf_type
__base	equ	0
	define	1,HAND_KF
	define	1,WEAPON_KF
	define	1,DODGE_KF
	define	1,FORCE_KF
	define	1,PARRY_KF
	define	1,LEARN_KF

;kf_id	40+7
__base	equ	0
	;9
	define	1,BASIC_FORCE_KF
	define	1,BASIC_BARE_KF
	define	1,BASIC_SWORD_KF
	define	1,BASIC_BLADE_KF
	define	1,BASIC_CLUB_KF
	define	1,BASIC_STAFF_KF
	define	1,BASIC_WHIP_KF
	define	1,BASIC_DODGE_KF
	define	1,BASIC_PARRY_KF
BASIC_KF_NUM	equ	__base
	;2
	define	1,LITERATE_KF
	define	1,LOOKS_KF
NONE_PAI_KF	equ	__base
	;29
	define	1,BAGUAD_KF
	define	1,BAGUAZ_KF
	define	1,BAZHEN_KF
	define	1,HUNYUAN_KF
	define	1,YOULONG_KF

	define	1,HUAFEI_KF
	define	1,HUATUAN_KF
	define	1,LIU_KF
	define	1,MEIHUA_KF
	define	1,SANHUA_KF

	define	1,HEXIANG_KF
	define	1,JIAOYI_KF
	define	1,PIFENG_KF
	define	1,TAIZU_KF
	define	1,TONGJI_KF

	define	1,RENSHU_KF
	define	1,WUFA_KF
	define	1,WUYING_KF
	define	1,YIDAO_KF

	define	1,TAIJIJ_KF
	define	1,TAIJIQ_KF
	define	1,TAIJIG_KF
	define	1,WANLIU_KF
	define	1,XUANXU_KF

	define	1,TAXUE_KF
	define	1,XUESHANG_KF
	define	1,XUESHAN0_KF
	define	1,XUESHANJ_KF
	define	1,XUEYING_KF

	define	1,MENGHU_KF
	define	1,XI_KF

KF_NUM		equ	__base

;pf_id	24
__base	equ	0
	define	1,DAOYING1_PF
	define	1,DAOYING2_PF
	define	1,ZHANGDAO1_PF
	define	1,ZHANGDAO2_PF
	define	1,LUOYING_PF
	define	1,LIULANG_PF
	define	1,SANHUA_PF
	define	1,FEIZHI_PF
	define	1,HONGLIAN_PF
	define	1,LEIDONG_PF
	define	1,FENSHEN_PF
	define	1,YIANMU_PF
	define	1,LIANZHAN_PF
	define	1,YIDAOZHAN_PF
	define	1,CHAN_PF
	define	1,LIAN_PF
	define	1,SANHUAN_PF
	define	1,JI_PF
	define	1,LUANHUAN_PF
	define	1,YINYANG_PF
	define	1,ZHEN_PF
	define	1,BINGXIN_PF
	define	1,LIUCHU_PF
	define	1,QINNA_PF

;pai:
;---------------------------------------------------------------
TRADE_PAI	equ	0ffh
__base	equ	0
	define	1,NONE_PAI
	define	1,BAGUA_PAI
	define	1,FLOWER_PAI
	define	1,HONGLIAN_PAI
	define	1,NAJA_PAI
	define	1,TAIJI_PAI
	define	1,XUESHAN_PAI
	define	1,XIAOYAO_PAI
	define	1,BOSS_PAI

;---------------------------------------------------------------
;menu_type
__base	equ	0
	define	1,NORMAL_MENU
	define	1,ARROW_MENU
	define	1,BOX_MENU
	define	1,RADIO_MENU
	define	1,ICON_MENU
	define	1,ICON_MENU1
	define	1,CHECK_MENU
	define	1,CHECK_MENU1
	define	1,GRAPH_MENU

;---------------------------------------------------------------
;fight_off
__base	equ	0
	define	9,NAME_OFF
	define	1,BUSY_OFF
	define	1,PAI_OFF
	define	1,GENDER_OFF
	define	1,AGE_OFF
	define	1,DAODE_OFF
	define	1,ATTACK_OFF
	define	1,DEFENSE_OFF
	define	1,DAMAGE_OFF
	define	1,ARMOR_OFF
	define	4,EXP_OFF
	define	2,FORCE_OFF
	define	1,STR_OFF
	define	1,DEX_OFF
	define	1,INT_OFF
	define	1,CON_OFF
	define	1,PER_OFF
	define	1,KAR_OFF
	define	2,HP_OFF
	define	2,MAXHP_OFF
	define	2,FP_OFF
	define	2,MAXFP_OFF
	define	2,EFFHP_OFF
	define	1,WEAPON_OFF

;---------------------------------------------------------------
;func_off
__base	equ	0
	define	3,FIND_FUNC
	define	3,QUERY_FUNC

;task
;----------------------------------
__base		equ	0
	define	1,QUEST_NPC
	define	1,QUEST_GOODS
	define	1,QUEST_KILL
	define	1,QUEST_GHOST
	define	1,QUEST_HOME
	define	1,QUEST_BRICK
