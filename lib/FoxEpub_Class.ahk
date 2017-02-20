/*
C:\FoxEpubTemp:
mimetype
META-INF\container.xml
xxxx.opf
xxxx.ncx
xxxx.htm
html:
101.html
102.html
p23_1.png



; -----��ע:
^esc::reload
+esc::Edit
!esc::ExitApp
F1::
	sTime := A_TickCount
	oMobi := new FoxEpub("͵��")
;	oMobi.SetCover("c:\cover.jpg") ; ���÷���
	oMobi.AddChapter("��1��", "<p>�����㵰������</p>`n<p>�Ǻ�</p>")
	oMobi.AddChapter("��2��", "<p>xx�����㵰������</p>`n<p>xx�Ǻ�</p>")
	oMobi.AddChapter("��3��", "<p>cc�����㵰������</p>`n<p>cc�Ǻ�</p>")
	oMobi.SaveTo("C:\etc\FoxTesting.mobi")
	
	eTime := A_TickCount - sTime
	TrayTip, ��ʱ:, %eTime% ms
return
*/
; 2013-5-7: mobigen���ɵ�mobi��ʽ��Kindle PaperWhite�ϣ���תĿ¼��ʾΪ���룬��ʹ��kindlegen
Class FoxEpub {
	EpubMod := "epub" ; epub|mobi
;	TmpDir := ""

	BookUUID := ""
	BookName := "����֮��"
	BookCreator := "������֮��"
	DefNameNoExt := "FoxMake"  ; Ĭ���ļ���
	ImageExt := "png"
	ImageMetaType := "image/png"
	CoverImgNameNoExt := "FoxCover"   ; ����ͼƬ·��
	CoverImgExt := "png"
	nFontType := 0   ; 0=������, 1=�Ķ���fontĿ¼��������, 2=Ƕ��mobi����
	BodyFont:= ""

	Chapter := []     ; �½ڽṹ:1:ID 2:Title 3:level
	ChapterCount := 0 ; �½���
	ChapterID := 100  ; �½�ID

	__New(iBookName, TmpDir="C:\FoxEpubTemp") {
		This.BookUUID := General_UUID()
		This.BookName := iBookName

		; ������ʱĿ¼�ṹ
		ifexist, %Tmpdir%
			FileRemoveDir, %Tmpdir%, 1
		FileCreateDir, %Tmpdir%\html
		ifNotExist, %TmpDir%\html
			msgbox, Epub����: �޷�������ʱĿ¼��C���Ƿ񲻿�д�أ�
		This.Tmpdir := Tmpdir
	}
	SetBodyFont(iFontNameOrPath="FZLanTingHei-R-GBK") {
		if iFontNameOrPath contains .ttf,.ttc,.otf
		{
			This.nFontType := 2
			SplitPath, iFontNameOrPath, OutFileName
			This.BodyFont := "../" . OutFileName
			FileCopy, %iFontNameOrPath%, % This.Tmpdir . "\" . OutFileName, 1
		} else {
			This.nFontType := 1
			This.BodyFont := iFontNameOrPath
		}
	}
	SetCover(ImgPath) { ; ���÷���ͼƬ
		SplitPath, ImgPath, OutFileName, OutDir, OutExt, OutNameNoExt, OutDrive
		This.CoverImgExt := OutExt
		IfExist, %ImgPath%
			filecopy, %ImgPath%, % This.Tmpdir . "\" . this.CoverImgNameNoExt . "." . OutExt, 1
	}
	AddChapter(Title="�½ڱ���", Content="�½�����", iPageID="", iLevel=1) {
		++This.ChapterCount
		if ( iPageID = "" ) {
			++This.ChapterID
			This.Chapter[This.ChapterCount,1] := This.ChapterID
		} else
			This.Chapter[This.ChapterCount,1] := iPageID
		This.Chapter[This.ChapterCount,2] := Title
		This.Chapter[This.ChapterCount,3] := iLevel
		This._CreateChapterHTML(Title, Content, This.Chapter[This.ChapterCount,1]) ; д���ļ�
	}
	SaveTo(EpubSavePath) {
		SplitPath, EpubSavePath, OutFileName, OutDir, OutExt, OutNameNoExt, OutDrive
		This.EpubMod := OutExt

		NowEpubMod := This.EpubMod
		NowTmpDir := This.Tmpdir

		NowOPFPre := NowTmpDir . "\" . This.DefNameNoExt
		NowOPFPath := NowOPFPre . ".opf"

		This._CreateIndexHTM()
		This._CreateNCX()
		This._CreateOPF()
		This._CreateEpubMiscFiles()

		if ( NowEpubMod = "mobi" ) {
sPathList =
(Ltrim Join`n
D:\bin\bin32\kindlegen.exe
C:\bin\bin32\kindlegen.exe
%A_scriptdir%\bin32\kindlegen.exe
%A_scriptdir%\kindlegen.exe
)
		loop, parse, sPathList, `n, `r
			IfExist, %A_loopfield%
				NowMobigenName := A_loopfield

			runwait, "%NowMobigenName%" "%NowOPFPath%", %NowTmpDir%, Hide
			filemove, %NowOPFPre%.mobi, %EpubSavePath%, 1
		}
		if ( NowEpubMod = "epub" ) {
sPathList =
(Ltrim Join`n
D:\bin\bin32\zip.exe
C:\bin\bin32\zip.exe
%A_scriptdir%\bin32\zip.exe
%A_scriptdir%\zip.exe
)
		loop, parse, sPathList, `n, `r
			IfExist, %A_loopfield%
				NowExeZip := A_loopfield

			envget, bWine, DISPLAY ; linux�����²�Ϊ�գ�����Ϊ :0
			if ( bWine = "" )
				runwait, "%NowExeZip%" -0Xq "%EpubSavePath%" mimetype, %NowTmpDir%, hide
			runwait, "%NowExeZip%" -Xr9Dq "%EpubSavePath%" *, %NowTmpDir%, hide
			; EPUB �淶�� OEBPS Container Format ������ EPUB �� ZIP������Ҫ�ļ����ǣ������еĵ�һ���ļ������� mimetype �ļ���mimetype �ļ����ܱ�ѹ���������� ZIP ���߾��ܴ� EPUB ���ĵ� 30 ���ֽڿ�ʼ��ȡԭʼ�ֽڣ��Ӷ����� mimetype�� ZIP �������ܼ��ܡ�EPUB ֧�ּ��ܣ��������� ZIP �ļ���һ���ϡ�
		}
		FileGetSize, NowFileSize, %EpubSavePath%, K
		If ( NowFileSize > 0 )
			FileRemoveDir, %NowTmpDir%, 1
	}
	_CreateNCX() {  ; ����NCX�ļ�
		NowTmpDir := This.TmpDir . "\html"
		NowDefName := This.DefNameNoExt
		NCXPath := This.TmpDir . "\" . NowDefName . ".ncx"
		NowBookName := This.BookName
		NowUUID := This.BookUUID
		NowCreator := This.BookCreator
		
		DisOrder := 1  ; ��ʼ ˳��, ���������playOrder����
		pageCount := This.Chapter.MaxIndex()
		loop, %pageCount% {
			++ DisOrder
			nowLevel  := This.Chapter[A_index, 3]
			if ( pageCount == A_index ) { ; ���һ��
				nextLevel := nowLevel - 1
			} else {
				nextLevel := This.Chapter[ 1 + A_index, 3]
			}
			if ( nowLevel < nextLevel ) {
				NCXList .= "`t<navPoint id=""" . This.Chapter[A_index,1] . """ playOrder=""" . DisOrder . """><navLabel><text>" . This.Chapter[A_index,2]
						. "</text></navLabel><content src=""html/" . This.Chapter[A_index,1] . ".html"" />`n"
			} else if ( nextLevel = nowLevel ) {
				NCXList .= "`t`t<navPoint id=""" . This.Chapter[A_index,1] . """ playOrder=""" . DisOrder . """><navLabel><text>" . This.Chapter[A_index,2]
						. "</text></navLabel><content src=""html/" . This.Chapter[A_index,1] . ".html"" /></navPoint>`n"
			} else if ( nowLevel > nextLevel ) {
				NCXList .= "`t`t<navPoint id=""" . This.Chapter[A_index,1] . """ playOrder=""" . DisOrder . """><navLabel><text>" . This.Chapter[A_index,2]
						. "</text></navLabel><content src=""html/" . This.Chapter[A_index,1] . ".html"" /></navPoint>`n`t</navPoint>`n"
			}
		}
		NCXXML =
		(join`n Ltrim
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
		<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="zh-cn">
		<head>
		<meta name="dtb:uid" content="%NowUUID%"/>
		<meta name="dtb:depth" content="1"/>
		<meta name="dtb:totalPageCount" content="0"/>
		<meta name="dtb:maxPageNumber" content="0"/>
		<meta name="dtb:generator" content="%NowCreator%"/>
		</head>
		<docTitle><text>%NowBookName%</text></docTitle>
		<docAuthor><text>%NowCreator%</text></docAuthor>
		<navMap>
			`t<navPoint id="toc" playOrder="1"><navLabel><text>Ŀ¼:%NowBookName%</text></navLabel><content src="%NowDefName%.htm"/></navPoint>
			%NCXList%
		</navMap></ncx>
		)
		Fileappend, %NCXXML%, %NCXPath%, UTF-8
	}
	_CreateOPF() {  ; ����OPF�ļ�
		NowTmpDir := This.TmpDir . "\html"
		NowDefName := This.DefNameNoExt
		OPFPath := This.TmpDir . "\" . NowDefName . ".opf"
		NowBookName := This.BookName
		NowUUID := This.BookUUID
		NowEpubMod := This.EpubMod
		NowCreator := This.BookCreator
		
		; ����ͼƬ
		IfExist, % This.TmpDir . "\" .  This.CoverImgNameNoExt . "." . This.CoverImgExt
		{
			MetaImg := "<meta name=""cover"" content=""FoxCover"" />"
			If ( This.CoverImgExt = "jpg" or This.CoverImgExt = "jpeg" )
				ManiImg := "<item id=""FoxCover"" media-type=""image/jpeg"" href=""" . This.CoverImgNameNoExt . "." . This.CoverImgExt . """/>"
			If ( This.CoverImgExt = "png" )
				ManiImg := "<item id=""FoxCover"" media-type=""image/png"" href=""" . This.CoverImgNameNoExt . "." . This.CoverImgExt . """/>"
			If ( This.CoverImgExt = "gif" )
				ManiImg := "<item id=""FoxCover"" media-type=""image/gif"" href=""" . This.CoverImgNameNoExt . "." . This.CoverImgExt . """/>"
		}

		FirstPath := "html/" . This.Chapter[1,1] . ".html"
		loop, % This.Chapter.MaxIndex()
			NowHTMLMenifest .= "`t<item id=""page" . This.Chapter[A_index,1] . """ media-type=""application/xhtml+xml"" href=""html/" . This.Chapter[A_index,1] . ".html"" />`n"
,			NowHTMLSpine .= "`t<itemref idref=""page" . This.Chapter[A_index,1] . """ />`n"

		NowImgExt := This.ImageExt
		ImgID := 100
		loop, %NowTmpDir%\*.%NowImgExt%, 0, 0  ; ����ͼƬ
			++ImgID
,			NowImgMenifest .= "`t<item id=""img" . ImgID . """ media-type=""" . This.ImageMetaType . """ href=""html/" . A_LoopFileName . """ />`n"

		if ( NowEpubMod = "mobi" )
			AddXMetaData := "<x-metadata><output encoding=""utf-8""></output></x-metadata>"
		OPFXML =
		(Join`n Ltrim C
		<?xml version="1.0" encoding="utf-8"?>
		<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="FoxUUID">
		<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
			`t<dc:title>%NowBookName%</dc:title>
			`t<dc:identifier opf:scheme="uuid" id="FoxUUID">%NowUUID%</dc:identifier>
			`t<dc:creator>%NowCreator%</dc:creator>
			`t<dc:publisher>%NowCreator%</dc:publisher>
;			`t<dc:contributor>������֮��</dc:contributor>
;			`t<dc:description>������֮���������ɣ���ʱ������</dc:description>
			`t<dc:language>zh-cn</dc:language>
			`t%MetaImg%
			`t%AddXMetaData%
		</metadata>`n`n
		<manifest>
			`t<item id="FoxNCX" media-type="application/x-dtbncx+xml" href="%NowDefName%.ncx" />
			`t<item id="FoxIDX" media-type="application/xhtml+xml" href="%NowDefName%.htm" />
			`t%ManiImg%`n
			%NowHTMLMenifest%`n`n
			%NowImgMenifest%
		</manifest>`n`n
		<spine toc="FoxNCX">
			`t<itemref idref="FoxIDX"/>`n`n
			%NowHTMLSpine%
		</spine>`n`n
		<guide>
			`t<reference type="text" title="����" href="%FirstPath%"/>
			`t<reference type="toc" title="Ŀ¼" href="%NowDefName%.htm"/>
		</guide>`n`n</package>`n`n
		)
		Fileappend, %OPFXML%, %OPFPath%, UTF-8
	}
	_CreateEpubMiscFiles() { ;  ���� epub �����ļ� mimetype, container.xml
		TmpOPFFilePath := This.DefNameNoExt . ".opf"
		TmpDirLocal := This.Tmpdir
		epubcontainer =
		(join`n Ltrim
		<?xml version="1.0"?>
		<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
		`t<rootfiles>
		`t`t<rootfile full-path="%TmpOPFFilePath%" media-type="application/oebps-package+xml"/>
		`t</rootfiles>
		</container>
		)
		fileappend, application/epub+zip, %TmpDirLocal%\mimetype
		FileCreateDir, %TmpDirLocal%\META-INF
		Fileappend, %epubcontainer%, %TmpDirLocal%\META-INF\container.xml, UTF-8
	}
	_CreateChapterHTML(Title="�½ڱ���", Content="�½�����", iPageID="") { ; �����½�ҳ��
		HTMLPath := This.TmpDir . "\html\" . iPageID . ".html"
		if ( 0 == This.nFontType ) {
			fontCSS := ""
		} else if ( 1 == This.nFontType ) {
			fontCSS := "`t`t@font-face { font-family: ""hei""; src: local(""" . This.BodyFont . """); }`n`t`t.content { font-family: ""hei""; }"
		} else if ( 2 == This.nFontType ) {
			fontCSS := "`t`t@font-face { font-family: ""hei""; src: url(""" . This.BodyFont . """); }`n`t`t.content { font-family: ""hei""; }"
		}
;		`t`tp { text-indent: 2em; line-height: 0.5em; }
		HTML =
		(Join`n Ltrim
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-CN">
		<head>
		`t<title>%Title%</title>
		`t<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		`t<style type="text/css">
		`t`th2,h3,h4{text-align:center;}
		%fontCSS%
		`t</style>
		</head>`n<body>
		<h3>%Title%</h3>
		<div class="content">
		`n`n
		%Content%
		`n`n
		</div>`n</body>`n</html>`n
		)
		Fileappend, %HTML%, %HTMLPath%, UTF-8
	}
	_CreateIndexHTM() { ; ��������ҳ
		HTMLPath := This.TmpDir . "\" . This.DefNameNoExt . ".htm"
		NowBookName := This.BookName
		loop, % This.Chapter.MaxIndex()
			NowTOC .= "<div><a href=""html/" . This.Chapter[A_index,1] . ".html"">" . This.Chapter[A_index,2] . "</a></div>`n"

		HTML =
		(Join`n Ltrim
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-CN">
		<head>
		`t<title>%NowBookName%</title>
		`t<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		`t<style type="text/css">h2,h3,h4{text-align:center;}</style>
		</head>`n<body>
		<h2>%NowBookName%</h2>
		<div class="toc">
		`n`n
		%NowTOC%
		`n`n
		</div>`n</body>`n</html>`n
		)
		Fileappend, %HTML%, %HTMLPath%, UTF-8
	}
}

