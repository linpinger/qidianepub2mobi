verDate := "2017-2-20"
	SrcFilePath = %1% ; 命令行

	isSelfUse := 0  ; 是否自用版本
	notSelfUse := ! isSelfUse

	if ( isSelfUse ) {
		chooseNum := 2
		FontName := "Zfull-GB"
		CoverName := "D:\etc\fox\foxbookCover.jpg"
	} else {
		chooseNum := 1
	}

	; 依赖 7za kindlegen
	EnvGet, oldPATH, PATH
	EnvSet, PATH, %A_scriptdir%\bin32`;%A_scriptdir%`;C:\bin\bin32`;D:\bin\bin32`;%oldPATH%

	if ( "" != SrcFilePath ) {
		isGUI := false
		if ( ! InStr(SrcFilePath, ":\") )
			SrcFilePath := A_ScriptDir . "\" . SrcFilePath
		gosub, unzipAndShowList
		gosub, ToMobi
		ExitApp
	} else {
		isGUI := true
		Gosub, GuiInit
	}
return

GuiInit:
	Gui,Add,Button,x394 y20 w70 h60 vBtnStart gToMobi,转Mobi(&S)

	Gui,Add,Groupbox,x4 y10 w380 h80 cGreen, 书籍封面图片及字体设置(非必要，可拖文件至此):
	Gui,Add,Checkbox,x14 y30 w80 h20 cGreen vCKFont gCKFont Checked%isSelfUse%, 字体(&F):
	Gui,Add,ComboBox,x94 y30 w280 choose%chooseNum% vFontName Disabled%notSelfUse%, 无|Zfull-GB|FZLanTingHei-R-GBK|FZLanTingHei-DB-GBK|D:\etc\Font\lantinghei.ttf
	Gui,Add,Checkbox,x14 y60 w80 h20 cGreen vCKCover gCKCover Checked%isSelfUse%, 封面(&C):
	Gui,Add,ComboBox,x94 y60 w280 choose%chooseNum% vCoverName Disabled%notSelfUse%, 无|D:\etc\fox\foxbookCover.jpg

	Gui,Add,Groupbox,x4 y100 w460 h320 cBlue, 将起点Epub文件拖动到下面，双击第一行或按转Mobi按钮:
	Gui,Add, Button,x334 y100 w120 h20 gChooseFile, 选择Epub文件(&F)

	Gui,Add,ListView,x14 y120 w440 h290 vFoxLV NoSortHdr -Multi gToMobi, 章节名|文件名
		LV_ModifyCol(1, 260), LV_ModifyCol(2, 150)

	Gui, Add, StatusBar, , 版本: %verDate%   作者:爱尔兰之狐  作品页: http://linpinger.github.io
	Gui,Show, w471 h440 , 起点 Epub 转 Mobi
return

CKFont:
	GuiControlGet, CKFont
	if ( 1 == CKFont ) {
		GuiControl, Enable, FontName
		GuiControlGet, FontName
		if ( "无" = FontName ) {
			FileSelectFile, FontName, 3
			if ( "" != FontName )
				GuiControl, text, FontName, %FontName%
		}
		if ( InStr(FontName, ":") ) {
			IfNotExist, %FontName%
			{
				FileSelectFile, FontName, 3
				if ( "" != FontName )
					GuiControl, text, FontName, %FontName%
			}
		}
		GuiControlGet, FontName
;		TrayTip, 提示:, % FontName
	} else {
		GuiControl, Disable, FontName
	}
return

CKCover:
	GuiControlGet, CKCover
	if ( 1 == CKCover ) {
		GuiControl, Enable, CoverName
		GuiControlGet, CoverName
		if ( "无" = CoverName ) {
			FileSelectFile, CoverName, 3
			if ( "" != CoverName )
				GuiControl, text, CoverName, %CoverName%
		} else {
			IfNotExist, %CoverName%
			{
				FileSelectFile, CoverName, 3
				if ( "" != CoverName )
					GuiControl, text, CoverName, %CoverName%
			}
		}
		GuiControlGet, CoverName
;		TrayTip, 提示:, % CoverName
	} else {
		GuiControl, Disable, CoverName
	}
return

GuiDropFiles:	; 拖动事件
	SrcFilePath := A_GuiEvent , FileCount := A_EventInfo

	If ( A_GuiControl = "FoxLV" ) {
		gosub, unzipAndShowList
		return
	} else if ( A_GuiControl = "FontName" ) {
		GuiControl, , CKFont, 1
		GuiControl, Enable, FontName
		GuiControl, text, FontName, %SrcFilePath%
	} else if ( A_GuiControl = "CoverName" ) {
		GuiControl, , CKCover, 1
		GuiControl, Enable, CoverName
		GuiControl, text, CoverName, %SrcFilePath%
	} else {
		TrayTip, 拖动提示:, 起点Epub拖到: 最大的列表框中`n字体或封面拖到: 下拉框中
		return
	}

	If ( FileCount != 1 ) {
		TrayTip, 提示:, 一次处理一个文件
		return
	}
	TrayTip, 提示:, %SrcFilePath%
return

ChooseFile: ; 选择epub文件
	FileSelectFile, SrcFilePath, 3
	if ( "" != SrcFilePath )
		gosub, unzipAndShowList
return

unzipAndShowList:
	SplitPath, SrcFilePath, EpubFileName, EpubDir, EpubExt, EpubNameNoExt, EpubDrive

	; 是否epub文件
	if ( "epub" != EpubExt ) {
		tip("错误: 后缀名不是.epub : " . EpubFileName)
		return
	}
	tip("解压获取信息: " . SrcFilePath)

	wDir := EpubDir . "\epub_" . A_TickCount ; 临时目录，全局变量

	FileCreateDir, %wDir%\src
	runwait, 7za x -r "%SrcFilePath%", %wDir%\src, min

	IfNotExist, %wDir%\src\title.xhtml
	{
		tip("错误: 貌似不是起点的epub")
		FileRemoveDir, %wDir%, 1
		return
	}

	; 获取书籍信息
	FileRead, html, *P65001 %wDir%\src\title.xhtml
	RegExMatch(html, "smUi)<li><b>书名</b>：<a href=""http://([0-9]*).qidian.com[^>]*?>([^<]*?)</a>.*<li><b>作者</b>：<a[^>]*?>([^<]*?)</a>.*<li><b>主题</b>：([^<]*?)<.*<li><b>简介</b>：<pre>(.*)</pre>", ff_)
	qidianid := ff_1
	bookname := ff_2
	bookauthor := ff_3
	booktype := ff_4
	bookinfo := ff_5

if ( isGUI ) {
	; 设置LV标题为书名
	LV_ModifyCol(1, "", "章节名 in: " . bookname . "  作者: " . bookauthor)

	; 获取章节列表
	LV_Delete()
	FileRead, html, *P65001 %wDir%\src\catalog.html
	loop, parse, html, `n, `r
	{
		if ( ! InStr(A_loopfield, "href=""content"))
			continue
		ff_1 := "" , ff_2 := ""
		RegExMatch(A_loopfield, "Ui)href=""([^""]+)"">([^<]+)</a>", ff_)

		LV_Add("", FF_2, FF_1)
	}
}
	tip( EpubFileName . ": 书名: " . bookname . "  作者: " . bookauthor . "  类型: " . booktype)
return

ToMobi:
if ( isGUI ) {
	if ( "FoxLV" = A_GuiControl ) { ; 跳过的章节
		startPos := LV_GetNext(0)
	} else if ( "BtnStart" = A_GuiControl) {
		startPos := 1
	}
} else {
	startPos := 1
}

	IfNotExist, %wDir%
		gosub, unzipAndShowList

	oEpub := New FoxEpub(bookname, wDir . "\mobi")
	oEpub.BookCreator := bookauthor

if ( isGUI ) {
	GuiControlGet, CKFont
	if ( CKFont ) {
		GuiControlGet, FontName
		if ( "无" != FontName )
			oEpub.SetBodyFont(FontName)
	}

	GuiControlGet, CKCover
	if ( CKCover ) {
		GuiControlGet, CoverName
		if ( "无" != CoverName )
			IfExist, %CoverName%
				oEpub.SetCover(CoverName) ; 设置封面
	}
} else {
	if ( isSelfUse ) {
		oEpub.SetBodyFont(FontName)
		oEpub.SetCover(CoverName) ; 设置封面
	}
}
	tip("转mobi中: " . EpubFileName . " -> " . qidianid . "_" . bookname . ".mobi")

	; 获取章节列表
	FileRead, html, *P65001 %wDir%\src\catalog.html

	nowCount := 0
	loop, parse, html, `n, `r
	{
		if ( ! InStr(A_loopfield, "href=""content"))
			continue
		++ nowCount
		if ( nowCount < startPos) ; 跳过的章节
			continue
		ff_1 := "" , ff_2 := ""
		RegExMatch(A_loopfield, "Ui)href=""([^""]+)"">([^<]+)</a>", ff_)

		FileRead, pageHtml, *P65001 %wDir%\src\%ff_1%
		pageHtml := getQiDianEpubPage(pageHtml)
		oEpub.AddChapter(ff_2, pageHtml)
	}

	oEpub.SaveTo(EpubDir . "\" . qidianid . "_" . bookname . ".mobi")
	tip("已完成转换mobi: " . EpubFileName . " -> " . qidianid . "_" . bookname . ".mobi")

	loop, 3 { ; 有时候在命令行模式下会出现删除错误的情况
		FileRemoveDir, %wDir%, 1
		if ErrorLevel
			sleep 1000
	}
return

GuiClose:
	IfExist, %wDir%
		FileRemoveDir, %wDir%, 1
	ExitApp
return

#NoEnv
#include <FoxEpub_Class>

tip(msg="") {
	global isGUI
	if ( isGUI )
		SB_SetText(msg)
	else
		FileAppend, %msg%, *
}

getQiDianEpubPage(html) {
	RegExMatch(html, "smUi)<div class=""content"">(.*)</div>", xx_)
	html := xx_1
	StringReplace, html, html, <p>手机用户请到m.qidian.com阅读。</p>, , A
	StringReplace, html, html, <p>手机阅读器、看书更方便。【<a href="http://download.qidian.com/apk/QDReader.apk?k=e" target="_blank">安卓版</a>】</p>, , A
	StringReplace, html, html, `r, , A
	StringReplace, html, html, `n, , A
	StringReplace, html, html, <p>, 　　, A
	StringReplace, html, html, </p>, <br/>`n, A
	return html
}


