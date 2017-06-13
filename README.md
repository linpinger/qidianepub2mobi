QidianEpub2Mobi(起点epub转mobi)
-----------------------------------------
**声明:** 本程序调用了 amazon 的 kindlegen，还有 7za.exe等，版权归各被调用程序及库的所有者

**名称:** QidianEpub2Mobi

**功能:** 将起点epub电子书转换为mobi电子书(Kindel电子书),可以设置字体及封面

**作者:** 爱尔兰之狐(linpinger)

**邮箱:** [linpinger@gmail.com](mailto:linpinger@gmail.com)

**主页:** <http://linpinger.github.io?s=Atc_QidianEpub2Mobi>

**缘起:** 2017年起点改版后，原txt格式不提供下载，目前只提供epub下载

**原理:** 解压epub，然后读取内容重新生成html，然后调用kindlegen转为mobi格式

**下载:**
- 程序: [所有项目下载工具](http://linpinger.qiniudn.com/FoxDownloadCenter.ZIP)
- 源代码: [QidianEpub2Mobi.ahkL](QidianEpub2Mobi.ahkL)

**最简单的使用方法:**将epub文件拖动到列表框(窗口中最大的那个框)中, 按顶部右边的 转Mobi 按钮，然后就会生成mobi文件(mobi在epub文件所在文件夹)

**说明:**
- 字体分两种:
  - 一种是在kindle根目录下创建font文件夹，将字体复制到其中，然后在下拉框中输入想要的字体的真名，例如: Zfull-GB
  - 一种是将字体文件拖动到字体下拉框中，可以将该字体包含进mobi文件中
- 封面图片: 起点epub中的图片尺寸太小，要在Kindle 8或以上版本中收藏夹中显示封面，需制作一大封面，我使用的尺寸是580*800
- 可以双击正文第一章开始转换，这样前面的章节就不会包含在mobi中

**更新日志:**

- 2017-6-13: 起点epub正文格式有变动
- 2017-2-20: 第一版

