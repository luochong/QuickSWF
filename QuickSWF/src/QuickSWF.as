package 
{
	import adobe.utils.CustomActions;
	import com.bit101.components.ComboBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.ScrollPane;
	import com.bit101.components.TextArea;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	import flash.system.Capabilities;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import export.PNGEncoder;
	import export.JPGEncoder;
	import export.Util;
	
	/**
	 * QuickSWF
	 * @author leoluo
	 */	
	[SWF(width="800",height="600")]
	public class QuickSWF extends Sprite
	{
		
		private var exportDir:String = "";//图片输入路径
		private var exportTarget:String = "";//输出目标
		
		private var swfPathLabel:Label;//swf地址
		private var swfPathInput:InputText;
		private var chooseFileBtn:PushButton;
		
		private var exportPathLabel:Label;//输出地址
		private var exportPathInput:InputText;
		private var chooseExportPathBtn:PushButton;
		
		private var layoutFileNameLabel:Label;//layout.info的名字
		private var layoutFileNameInput:InputText;
		
		private var exportScale:Number = 1;
		private var exportScaleLabel:Label;
		private var exportScaleNumStep:NumericStepper;
		
		private var uiExportBtn:PushButton;
		private var exportStateLable:Label;
		
		private var animationPanel:ScrollPane;
		
		private var showX:Number = 0;
		private var showY:Number = 0;
		
		private var origin:Point = new Point(0, 480);
		
		private var appDomain:ApplicationDomain;//当前导出文档的信息
		private var clazzKeys:Vector.<String>;
		
		private var oldLayoutsData:Object;
		private var layoutFileName:String = "";//布局文件的名字
		private var exportImages:Dictionary;//需要输出的图片
		private var exportImagesData:Object;//需要输出的图片的信息，主要是记录注册点
		private var exportUiLayouts:Dictionary;//需要输出的ui布局
		private var exportUiLayoutsData:Object;//需要输出的ui布局信息
		
		private var tempContent:Sprite = new Sprite();
		
		// 打开输出文件夹的按钮
		private var openResourceBtn:PushButton;
		// 存储上次目录
		private var so:SharedObject;
		// 将所有图片添加到此Sprite中，用于图片导出
		private var combineSprite:Sprite = new Sprite();
		// TextureAltas的名字
		private var textureAltasName:InputText;
		private var textureAltasNameLab:Label;
		private var logTextArea:TextArea;
		private var colorComboBox:ComboBox;
		
		public function QuickSWF()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			swfPathLabel = new Label(this,17,12,"swf地址：");
			swfPathInput = new InputText(this,72,12);
			swfPathInput.enabled = false;
			swfPathInput.height = 20;
			swfPathInput.width = 600;
			so = SharedObject.getLocal("UIExport/swfPath");
			
			chooseFileBtn = new PushButton(this,680,12,"选择文件swf",onSelectSwfBtn);
			
			exportPathLabel = new Label(this,12,36,"输出地址：");
			exportPathInput = new InputText(this,72,36);
			exportPathInput.enabled = false;
			exportPathInput.height = 20;
			exportPathInput.width = 600;
			
			chooseExportPathBtn = new PushButton(this,680,36,"选择输出路径",onSelectExportPathBtn);
			
			layoutFileNameLabel = new Label(this,12,80,"布局文件：");
			layoutFileNameInput = new InputText(this,72,80,"layout.info");
			layoutFileNameInput.height = 20;
			
			if (so.data.swfPath)
			{
				layoutFileNameInput.text = getName(so.data.swfPath) + ".info";
				swfPathInput.text = so.data.swfPath;
				exportPathInput.text = so.data.outPath;
			}
			
			exportScaleLabel = new Label(this,12,60,"输出倍数：");
			exportScaleNumStep = new NumericStepper(this,72,60);
			exportScaleNumStep.step = 0.5;
			exportScaleNumStep.minimum = 0.5;
			exportScaleNumStep.maximum = 10;
			exportScaleNumStep.value = 1;	// 输出倍数
			exportScaleNumStep.width = 60;
			
			
			var colorComboBoxLabel:Label = new Label(this,184,60,"选择像素格式：");
			colorComboBox = new ComboBox(this, 268, 60);
			
			colorComboBox.addItem("RGBA4444");
			colorComboBox.addItem("RGBA8888");
			colorComboBox.selectedIndex = 0;
			
			uiExportBtn = new PushButton(this,680,70,"输出UI",onExportUiBtn);
			uiExportBtn.width = 100;
			
			openResourceBtn = new PushButton(this, 680, 94, "打开输出文件夹", onOpenResourceBtn);
			openResourceBtn.height = 30;
			
			exportStateLable = new Label(this,12,108,"等待输出");
			
			logTextArea = new TextArea(this, 0, 132);
			logTextArea.width = 800;
			logTextArea.height = 200;
			
			animationPanel = new ScrollPane(this,0,132 + 200);
			animationPanel.width = 800;
			animationPanel.height = 400 - 132;
			animationPanel.dragContent = false;
			animationPanel.autoHideScrollBar = true;
			addChild(animationPanel);
			
			tempContent.y = 900;
			addChild(tempContent);
		}
		
		private function log(log:String):void
		{
			logTextArea.text += log + "\n";
			logTextArea.scrollToEnd();
		}
		
		/**
		 * 打开输出文件夹
		 * @param	e
		 */
		private function onOpenResourceBtn(e:Event):void 
		{
			if (exportPathInput.text == "")
				return;
			var file:File = new File(exportPathInput.text);
			file.openWithDefaultApplication();
		}
		
		private function onSelectSwfBtn(e:Event):void{
			var file:File = new File();
			file.browse([new FileFilter("Flash","*.swf")]);
			file.addEventListener(Event.SELECT,selectSwfOK);
		}
		private function selectSwfOK(e:Event):void{
			var file:File = e.target as File;
			file.removeEventListener(Event.SELECT,selectSwfOK);
			swfPathInput.text = file.url;
			layoutFileNameInput.text = getName(file.url) + ".info";
			so.data.swfPath = file.url;
			so.flush();
		}
		
		private function onSelectExportPathBtn(e:Event):void{
			var file:File = new File();
			file.browseForDirectory("输出路径");
			file.addEventListener(Event.SELECT,selectExportPathOK);
		}
		private function selectExportPathOK(e:Event):void{
			var file:File = e.target as File;
			file.removeEventListener(Event.SELECT,selectExportPathOK);
			exportPathInput.text = file.url + "/";
			so.data.outPath = exportPathInput.text;
			so.flush();
		}
		
		private function onExportUiBtn(e:MouseEvent):void {
			logTextArea.text = "";
			exportTarget = swfPathInput.text;
			exportDir = exportPathInput.text;
			layoutFileName = layoutFileNameInput.text;
			
			if(exportDir=="" || exportTarget=="") return;
			if(layoutFileName == null || layoutFileName == "") return;
			
			layoutFileName = layoutFileName.split(".")[0] + ".info"
			exportScale = exportScaleNumStep.value;
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadComplete);
			loader.load(new URLRequest(exportTarget));
			
			exportStateLable.text = "开始输出...";
			
			if(animationPanel.content.numChildren > 0){
				animationPanel.content.removeChildren(0,animationPanel.content.numChildren-1);
			}
			showX = 0;
			showY = 0;
		}
		
		private function loadComplete(e:Event):void{
			
			var file:File = new File(exportDir + layoutFileName);
			if(file.exists){
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
				urlLoader.load(new URLRequest(exportDir + layoutFileName));
				urlLoader.addEventListener(Event.COMPLETE,loadOk);
				
				function loadOk(e:Event):void{
					urlLoader.removeEventListener(Event.COMPLETE,loadOk);
					oldLayoutsData = JSON.parse(urlLoader.data as String)["layout"];
					export();
				}
			}else{
				export();
			}
			
			function export():void{
				var loaderInfo:LoaderInfo = e.target as LoaderInfo;
				loaderInfo.removeEventListener(Event.COMPLETE,loadComplete);
				
				appDomain = loaderInfo.content.loaderInfo.applicationDomain;
				clazzKeys = appDomain.getQualifiedDefinitionNames();
				
				parseExportTarget();
				exportImageToDisk();
				exportUiLayoutToDisk();
				createTextureAltas();
				loaderInfo.loader.unloadAndStop();
			}
			
			
			exportStateLable.text = "正在生成大图...";
		}
		
		/**
		 * 获取应该输入的图片和ui布局的对象
		 * */
		private function parseExportTarget():void{
			exportImages = new Dictionary();
			exportUiLayouts = new Dictionary();
			
			var clazz:Class;
			var mc:MovieClip;
			var length:int = clazzKeys.length;
			for (var i:int = 0; i < length; i++) {
				clazz = appDomain.getDefinition(clazzKeys[i]) as Class;
				try 
				{
					mc = new clazz() as MovieClip;
				}
				catch (err:Error)
				{
					mc = null;
				}
				if(mc == null){
					continue;
				}
				// 如果存在标签，就是布局，否则当Image处理
				if (mc.currentLabels.length == 0)
				{					
					exportImages[getQualifiedClassName(mc)] = mc;
				}
				else
				{
					exportUiLayouts[getQualifiedClassName(mc)] = mc;
				}
			}
		}
		
		/**
		 * 输出图片到硬盘
		 * */
		private function exportImageToDisk():void{
			exportImagesData = new Object();
			
			var k:String;
			var mc:MovieClip;
			var rect:Rectangle;
			var bitmapdata:BitmapData;
			var imageData:ByteArray;
			var file:File;
			var fs:FileStream;
			var imgPostionData:Object;
			var index:String = "";
			for (k in exportImages) {
				log("name:"+ k);
				mc = exportImages[k];
				var totolFrames:int = mc.totalFrames;
				for (var i:int = 1; i <= totolFrames; i++) 
				{
					//pos前缀只用来记录坐标信息，不导出成图片
					if ( k.indexOf("pos_") == 0)					
							continue;
					try 
					{
						
						if (totolFrames > 1 || k.indexOf("btnS_") != -1)
							index = String(i);
						else
							index = "";
						// 图片保存到assets下
						var picPath:String = exportDir + "assets/";
						
						
						mc.gotoAndStop(i);
						mc.scaleX = mc.scaleY = exportScale;
						addMcToTempContent(mc);
						
						rect = mc.getRect(tempContent);
						mc.x = -rect.x;
						mc.y = -rect.y;
						
						bitmapdata = new BitmapData(rect.width,rect.height,true,0);
						bitmapdata.draw(tempContent);
						
						if ( k.indexOf("pub_") != 0)
						{
							imageData = PNGEncoder.encode(bitmapdata);
							file = new File(picPath + k + index + ".png");
						}
						else
						{
							var jpgEncoder:JPGEncoder = new JPGEncoder(80);
							imageData = jpgEncoder.encode(bitmapdata);
							file = new File(exportDir + "public/" + k + index + ".jpg");
						}

						fs = new FileStream();
						fs.open(file,FileMode.WRITE);
						fs.writeBytes(imageData);
						fs.close();
					} 
					catch (err:Error) 
					{
						log("movieClassName:" + getQualifiedClassName(mc) + "currentFrame:"+ i);
						var errStr:String = "异常：" + err + ",movieClassName:" + getQualifiedClassName(mc) + ",currentFrame:" + i;
						log(errStr);
						exportStateLable.textField.textColor = 0xFF0000;
						exportStateLable.text = errStr;
						//return;
					}
				}	
				mc.scaleX = mc.scaleY = 1;
				addMovieClip(mc);
				
				imgPostionData = {x:formatNumber(rect.x / exportScale) ,y:formatNumber(rect.y / exportScale)};
				
				if(k.indexOf("s9_") == 0){
					imgPostionData.s9gw = formatNumber(rect.width / exportScale * 0.25);//9宫格的x，y
				}
				exportImagesData[k] = imgPostionData;
				
				if (imgPostionData.x  != 0 || imgPostionData.y != 0)
				{
					log("注意:"+ k +"图片坐标不为 (0,0)");
				}
			}
		}
		
		
		/**
		 * 输入出布局信息到硬盘
		 * */
		private function exportUiLayoutToDisk():void{
			exportUiLayoutsData = new Object();
			var layoutInfo:Object = new Object();
			
			var k:String;
			var mc:MovieClip;
			var length:int;
			
			var child:DisplayObject;
			var childName:String;
			var oldChildInfos:Array;
			var childInfos:Array;
			var childInfo:Object;
			var rect:Rectangle;
			
			for (k in exportUiLayouts) {
				mc = exportUiLayouts[k];
				addMcToTempContent(mc);
				
				length = mc.numChildren;
				if(oldLayoutsData) oldChildInfos = oldLayoutsData[k];
				childInfos = [];
				var j:int = 0;
				for (var i:int = 0; i < length; i++) {
					child = mc.getChildAt(i) as DisplayObject;
					childName = getQualifiedClassName(child);
		
					rect = child.getBounds(mc);	
					var child_y:Number;
					var child_x:Number
					if (child.parent.parent)
					{
						var center_point:Point = new Point(child.parent.x + (child.parent.width >> 1) , child.parent.y + (child.parent.height >> 1));
						center_point = child.parent.parent.localToGlobal(center_point);						
						center_point = child.parent.globalToLocal(center_point);
						child_y = center_point.y - (child.y + (child.height >> 1)); 
						child_x = (child.x + (child.width >> 1)) - center_point.x;
					}
					else
					{
						var left_bottom_point:Point = new Point(child.parent.x, child.parent.y + child.parent.height);	
						left_bottom_point = child.parent.globalToLocal(left_bottom_point);
						child_y = left_bottom_point.y - (child.y + (child.height >> 1)); 
						child_x = (child.x + (child.width >> 1)) - left_bottom_point.x;
					}
					
					childInfo = {
						cname:childName,
						x:formatNumber(child_x),
						y:formatNumber(child_y),
						w:formatNumber(child.width),
						h:formatNumber(child.height),
						sx:formatNumber(child.scaleX),
						sy:formatNumber(child.scaleY),
						
//						r:formatNumber(child.rotation),
						skx:MatrixUtil.getSkewX(child.transform.matrix),
						sky:MatrixUtil.getSkewY(child.transform.matrix)
					};
					
					if(child.name.indexOf("instance") == -1){
						childInfo.name = child.name;
					}
					
					
					if(childName.indexOf("s9_") == 0){//目标为9宫格
						childInfo.type = "s9image";
					}else if(childName.indexOf("btn_") == 0){
						childInfo.type = "btn";						
					}
					else if (childName.indexOf("btnS_") == 0){	// added 2013/7/8 by Yokia
						childInfo.type = "btnS";
					}
					else if (childName.indexOf("mov_") == 0){ // added 2013/7/8 by Yokia
						childInfo.type = "movie";
						childInfo.len = (child as MovieClip).totalFrames;
					}
					else if(childName == "flash.text::TextField"){
						childInfo.type = "text";
						childInfo.font = (child as TextField).defaultTextFormat.font;
						childInfo.color = (child as TextField).defaultTextFormat.color;
						childInfo.size = (child as TextField).defaultTextFormat.size;
						childInfo.align = (child as TextField).defaultTextFormat.align;
						childInfo.italic = (child as TextField).defaultTextFormat.italic;
						childInfo.bold = (child as TextField).defaultTextFormat.bold;
						childInfo.text = (child as TextField).text;
					}
					else if (childName.indexOf("_") > 0)
					{
						childInfo.type = childName.substring(0,childName.indexOf("_"));
					}
					else if(exportUiLayouts[childName] != null){//目标为子布局
						childInfo.type = "sprite";
					}
					
					else{
						childInfo.type = "image";
					}
					childInfos[j] = childInfo;
					j++;
					if (childName.indexOf("pos_") == 0)
					{
						childInfo.cname = childName.slice(String("pos_").length);
					}
				}
				layoutInfo[k] = childInfos;
			}
			exportUiLayoutsData["layout"] = layoutInfo;
			
			var file:File = new File(exportDir+layoutFileName);
			var fs:FileStream = new FileStream();
			var data:ByteArray = new ByteArray();
			data.writeUTFBytes(JSON.stringify(exportUiLayoutsData));
			var timer:Timer = new Timer(100, 1);
			// 延后生成info和bat文件
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function ():void
			{
				fs.open(file, FileMode.WRITE);
				fs.writeBytes(data);
				fs.close();				
				timer.stop();
			});
			timer.start();
			
		}
		
		/**
		 * 那对象添加到临时容器
		 * */
		private function addMcToTempContent(display:DisplayObject):void{
			while(tempContent.numChildren > 0){
				tempContent.removeChildAt(0);
			}
			tempContent.addChild(display);
		}
		
		private function addMovieClip(mc:DisplayObject):void{
			tempContent.addChild(mc);
			var rect:Rectangle = Util.getPivotAndMaxRect(mc);
			mc.x = rect.x + showX;
			mc.y = rect.y + showY;
			
			showX += rect.width;
			if(showX > 800){
				showX = rect.width;
				showY = animationPanel.content.height;
				mc.x = rect.x;
				mc.y = rect.y + showY;
			}
			animationPanel.content.addChild(mc);
			animationPanel.update();
		}
		
		/**
		 * 保留两位小数
		 */		
		private function formatNumber(_num:Number):Number{
			return Math.round(_num * (0 || 100)) / 100;
		}
		
		private function getName(rawAsset:Object):String
		{
			var matches:Array;
			var name:String;
			
			if (rawAsset is String || rawAsset is FileReference)
			{
				name = rawAsset is String ? rawAsset as String : (rawAsset as FileReference).name;
				name = name.replace(/%20/g, " "); // URLs use '%20' for spaces
				matches = /(.*[\\\/])?([\w\s\-]+)(\.[\w]{1,4})?/.exec(name);
				
				if (matches && matches.length == 4) return matches[2];
				else throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
			}
			else
			{
				name = getQualifiedClassName(rawAsset);
				throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
			}
		}
		/**
		 * 生成创建TextureAtlas的bat文件
		 */
		private function createTextureAltas():void
		{
			var file:File = new File(exportDir + "createTextureAltas.bat");
			var fs:FileStream = new FileStream();
			var name:String = getName(layoutFileNameInput.text);
			var batString:String = "if not exist 1x  md 1x \n if not exist 0.5x md 0.5x \n TexturePacker --data "+ "1x\\" +name +".plist" +" --format cocos2d --sheet "+ "1x\\" +name +".png" +" --dither-fs-alpha --opt "+ colorComboBox.selectedItem +" --max-size 2048 assets/ \n TexturePacker --scale 0.5 --data "+ "0.5x\\" +name +".plist" +" --format cocos2d --sheet "+ "0.5x\\" +name +".png" +" --dither-fs-alpha --opt "+ colorComboBox.selectedItem +" --max-size 2048 assets/ \n exit";
			if(Capabilities.os.indexOf("Mac") != -1)
			{
				batString = "mkdir 1x \n mkdir 0.5x \n /usr/local/bin/TexturePacker --data "+ "1x/" +name +".plist" +" --format cocos2d --sheet "+ "1x/" +name +".png" +" --dither-fs-alpha --opt "+ colorComboBox.selectedItem +" --max-size 2048 assets/ \n /usr/local/bin/TexturePacker --scale 0.5 --data "+ "0.5x/" +name +".plist" +" --format cocos2d --sheet "+ "0.5x/" +name +".png" +" --dither-fs-alpha --opt "+ colorComboBox.selectedItem +" --max-size 2048 assets/ \n exit";
			}
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(batString);
			fs.close();
			var timer:Timer = new Timer(200, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function ():void
			{
				runBatAndRemoveAsset(file);
			});
			timer.start();
		}
		
		private function runBatAndRemoveAsset(batFile:File):void
		{
			var workingDirectory:File = batFile.parent;
			var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			processStartupInfo.workingDirectory = workingDirectory;
			var cmdfile:File;
			if(Capabilities.os.indexOf("Mac") != -1)
			{
				cmdfile = new File("/bin/bash");
			}
			else
			{
				cmdfile = new File("C:\\WINDOWS\\system32\\cmd.exe");
			}
			
			if (!cmdfile.exists)
			{
				log("错误:cmd.exe 不存在,需要手动执行bat 文件来生成大图");
				return complete();
			}
			processStartupInfo.executable = cmdfile;
			var processArguments:Vector.<String> = new Vector.<String>();
			if(Capabilities.os.indexOf("Mac") != -1)
			{	
				processArguments[0] =  batFile.nativePath;	
			}
			else
			{
				processArguments[0] = "/c";
				processArguments[1] =  batFile.nativePath;
			}
			processStartupInfo.arguments = processArguments;
			var nativeProcess:NativeProcess = new NativeProcess();
			nativeProcess.addEventListener(NativeProcessExitEvent.EXIT,onExit);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onData);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA,onError);
			nativeProcess.start(processStartupInfo);
			
			
			function onExit(e:NativeProcessExitEvent):void
			{
				log("createTextureAltas OK");
				var file:File = new File(exportDir + "assets");
				file.deleteDirectory(true);
				batFile.deleteFile();
				complete();
			}

			function onData(e:ProgressEvent):void
			{
				log(nativeProcess.standardOutput.readMultiByte(nativeProcess.standardOutput.bytesAvailable, "GBK"));
			}

			function onError(e:ProgressEvent):void
			{
				var error:String = nativeProcess.standardError.readMultiByte(nativeProcess.standardError.bytesAvailable, "GBK")
				log("错误:" + error);
			}
		}
		
		private function complete():void
		{
			var file:File = new File(exportDir + "1x/" + getName(layoutFileNameInput.text) +".png");
			if (file.exists)
			{
				exportStateLable.text = "导出成功！";
			}
			else
			{
				exportStateLable.text = "导出失败，请查看日志！";
			}
			// 输出完毕，自动打开文件夹
			onOpenResourceBtn(null);
		}
		
	}
}