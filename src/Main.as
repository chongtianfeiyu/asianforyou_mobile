package src
{
	//import flash.desktop.NativeApplication;
	import com.adobe.crypto.MD5;
	import com.adobe.images.JPGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TouchEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.ByteArray;
	
	import gs.TweenLite;
	
	/**
	 * ...
	 * @author JackyGu
	 */
	public class Main extends Sprite 
	{
		private var pictureContainer:Sprite;
		private var activeBar:Sprite;
		private var bottomBar:Sprite;
		private var screenWidth:int;
		private var screenHeight:int;
		private var scale:Number;
		private var md5FileName:String;
		private var orgFileName:String;
		private var localDir:String;
		private var loadFromLocal:Boolean;//从本次下载
		private var pictureArray:Array = ["http://www.theblackalley.info/hardcore/jasminewang01/jasminewang07.jpg",
										   "http://www.theblackalley.net/asian4you/nudegalleries/chin-si-yee-04a/13.jpg",
										   "http://www.theblackalley.biz/models/irenefah01/06.jpg",
										   "http://www.theblackalley.biz/models/irenefah01/b2.jpg",
										   "http://www.theblackalley.biz/models/irenefah01/12.jpg",
										   "http://www.theblackalley.biz/models/marinajang04/04.jpg",
										   "http://www.theblackalley.biz/models/marinajang04/b2.jpg",
										   "http://www.theblackalley.biz/models/marinajang04/12.jpg",
										   "http://www.theblackalley.biz/models/kathyramos01/08.jpg",
										   "http://www.theblackalley.biz/models/kathyramos01/f1.jpg",
										   "http://www.theblackalley.biz/models/minnierose01/11.jpg",
										   "http://www.theblackalley.biz/models/minnierose01/07.jpg"
											];
		
		private var picId:int = 0;
		public function Main():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			if (Capabilities.os.substr(0, 7) == "Windows") {
				screenWidth = 480;
				screenHeight = 800;//用于windows系下调试，不过到了CS6就不用了
				localDir = Config.localDir_windows;
			}else if (Capabilities.os.substr(0, 5) == "Linux"){
				screenWidth =  Capabilities.screenResolutionX;
				screenHeight =  Capabilities.screenResolutionY;
				localDir = Config.localDir_android;
			}else if(Capabilities.os.substr(0, 6) == "iPhone"){
				screenWidth =  Capabilities.screenResolutionX;
				screenHeight =  Capabilities.screenResolutionY;
				localDir = Config.localDir_ios;
			}
			scale = screenWidth / 480;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			//Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			init();
			// entry point
		}
		private var loadingBar:MovieClip;
		private function deactivate(e:Event):void 
		{
			// auto-close
			//NativeApplication.nativeApplication.exit();
		}
		private function init():void {
			initActiveBar();
			initPictureContainer();
			initBottomBar();
			initLoadingMc();
			loadLocalImage(pictureArray[picId]);
		}
		private function initActiveBar():void {
			activeBar = new ActiveBar() as Sprite;
			activeBar.width = screenWidth;
			activeBar.height = activeBar.height * scale;
			this.addChild(activeBar);
		}
		private function initLoadingMc():void {
			loadingBar = new Loading() as MovieClip;
			loadingBar.width = screenWidth;
			loadingBar.height = loadingBar.height * scale;
			this.addChild(loadingBar);
			loadingBar.visible = false;
		}
		private function initPictureContainer():void {
			pictureContainer = new Container() as Sprite;
			pictureContainer.x = 0;
			pictureContainer.y = activeBar.height;
			this.addChild(pictureContainer);
			initPictureTouchEvent(true);
		}
		private function initPictureTouchEvent(bl:Boolean = true):void {
			if (bl) {
				pictureContainer.addEventListener(MouseEvent.MOUSE_DOWN, onPictureTouchHandler);
				//pictureContainer.addEventListener(TouchEvent.TOUCH_TAP, onPictureTouchHandler);
				//pictureContainer.addEventListener(TouchEvent.TOUCH_BEGIN, onPictureTouchBeginHandler);
				//pictureContainer.addEventListener(TouchEvent.TOUCH_END, onPictureTouchEndHandler);
				
			}
		}
		private function initBottomBar():void {
			bottomBar = new BottomBar() as Sprite;
			bottomBar.width = screenWidth;
			bottomBar.height = bottomBar.height * scale;
			bottomBar.x = 0;
			bottomBar.y = screenHeight;
			this.addChild(bottomBar);
			MovieClip(bottomBar.getChildByName("btnPrevious")).addEventListener(MouseEvent.MOUSE_DOWN, onPreviousButtonPressHandler);
			MovieClip(bottomBar.getChildByName("btnNext")).addEventListener(MouseEvent.MOUSE_DOWN, onNextButtonPressHandler);
			MovieClip(bottomBar.getChildByName("btnZoomIn")).addEventListener(MouseEvent.MOUSE_DOWN, onZoomInButtonPressHandler);
			MovieClip(bottomBar.getChildByName("btnZoomOut")).addEventListener(MouseEvent.MOUSE_DOWN, onZoomOutButtonPressHandler);
			
			//bottomBar.visible = false;
		}
		private var loader:URLLoader;
		private function loadLocalImage(url:String):void{
			//调用本地文件
			//在本地检验是否已经有相同文件，如果是，则直接本地载入，否则，上网载入
			loadFromLocal = true;
			md5FileName = MD5.hash(url);
			orgFileName = url;
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loadingBar.visible = true;
			loadingBar.gotoAndStop(1);
			loader.addEventListener(Event.COMPLETE, onImageLoadCompleteHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLocalImageLoadErrorHandler);
			trace("搜索本地：" + localDir + md5FileName);
			loader.load(new URLRequest(localDir + md5FileName));
		}
		private function loadImage(url:String):void {
			loader = new URLLoader();
			showBottomBar(false);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loadingBar.visible = true;
			loadingBar.gotoAndStop(1);
			loader.addEventListener(Event.COMPLETE, onImageLoadCompleteHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadErrorHandler);
			loader.load(new URLRequest(url));
		}
		private function onImageLoadCompleteHandler(event:Event):void {
			//无论是本地下载还是在线下载都是用这个函数
			var _ba:ByteArray = event.target.data as ByteArray;
			var _l:Loader = new Loader();
			_l.contentLoaderInfo.addEventListener (Event.COMPLETE, onBytesLoaded);
            _l.loadBytes(_ba);
            loader.removeEventListener (Event.COMPLETE , onImageLoadCompleteHandler);
			loader.removeEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
            loader = null;
			showBottomBar(true);
		}
		private function onBytesLoaded(event:Event):void {
			var _bitmap:Bitmap = event.target.content as Bitmap;
			//trace(_bitmap.width, _bitmap.height );
			var _scale:Number = screenWidth / _bitmap.width;
			_bitmap.width = screenWidth;
			_bitmap.height = _bitmap.height * _scale;
			//trace(_bitmap.width, _bitmap.height );
			pictureContainer.addChild(_bitmap );
			event.target.loader.contentLoaderInfo.removeEventListener (Event.COMPLETE, onBytesLoaded);
			loadingBar.visible = false;
			loadingBar.gotoAndStop(1);
			if(!loadFromLocal && Config.saveLocal) saveBitmap(md5FileName, _bitmap.bitmapData);//如果是从网络上下载的，则保存本次
		}
		private function onImageLoadingHandler(event:ProgressEvent):void {
			var loadedPercent:int = event.bytesLoaded / event.bytesTotal * 100;
			loadingBar.gotoAndStop(loadedPercent);
			var txt:TextField = loadingBar.getChildByName("txt") as TextField;
			txt.text = loadedPercent + "%";
		}
		private function onImageLoadErrorHandler(event:IOErrorEvent):void {
			trace("Picture load error:");
			showBottomBar(true);
            loader.removeEventListener(Event.COMPLETE , onImageLoadCompleteHandler);
			loader.removeEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadErrorHandler);
		}
		
		private function onLocalImageLoadErrorHandler(event:IOErrorEvent):void{
			trace("找不到本地文件，开始网络下载");
			loader.removeEventListener(Event.COMPLETE, onImageLoadCompleteHandler);
			loader.removeEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onLocalImageLoadErrorHandler);
			loadFromLocal = false;
			loadImage(orgFileName);
		}
		//=====================TOUCH && GESTURE====================
		private var startPoint:Point;
		private function onPictureTouchHandler(event:MouseEvent):void {
			//处理触摸事件
			trace("onPictureTouchHandler");
			showBottomBar(!bottomBarVisible);//如果显示则隐藏，否则则显示
		}
		private function onPictureTouchBeginHandler(event:TouchEvent):void {
			//处理触摸开始事件
			trace("touchBegin");
		}
		private function onPictureTouchEndHandler(event:TouchEvent):void {
			//处理触摸结束事件
			trace("touchEnd");
		}
		private function onPreviousButtonPressHandler(event:MouseEvent):void{
			if(picId > 0) picId--;
			else picId = pictureArray.length - 1;
			MemoryCleaner.cleanMc(pictureContainer);
			loadLocalImage(pictureArray[picId]);
		}
		private function onNextButtonPressHandler(event:MouseEvent):void{
			if(picId < pictureArray.length - 1){
				picId++;
			}else{
				picId = 0;
			}
			MemoryCleaner.cleanMc(pictureContainer);
			loadLocalImage(pictureArray[picId]);
		}
		private function onZoomInButtonPressHandler(event:MouseEvent):void{
			
		}
		private function onZoomOutButtonPressHandler(event:MouseEvent):void{
			
		}
		//=====================功能函数========================
		private var bottomBarVisible:Boolean = false;
		private function showBottomBar(bl:Boolean):void {
			bottomBarVisible = bl;
			if (bl) {
				//显示
				TweenLite.to(bottomBar, 0.5, { y:screenHeight - bottomBar.height } );
			}else{
				//隐藏
				TweenLite.to(bottomBar, 0.5, { y:screenHeight } );
			}
		}
		private function saveBitmap(fileName:String, bitmapData:BitmapData):void{
			var jpgenc:JPGEncoder = new JPGEncoder(80);
			var imgByteArray:ByteArray = jpgenc.encode(bitmapData);
			var fl:File = File.desktopDirectory.resolvePath(localDir + fileName); 
			trace("保存图片: " + localDir + fileName);
			var fs:FileStream = new FileStream();
			try{
				//open file in write mode
				fs.open(fl, FileMode.WRITE);
				//write bytes from the byte array
				fs.writeBytes(imgByteArray);
				//close the file
				fs.close();
			}catch(e:Error){
				trace(e.message);
			}			
		}
		private function getLocalDir():String{
			var currSwfUrl:String = "";
			//写网络相关的项目时,就可以通过这个自动选择调用的服务器端程序了 
			var doMain:String = this.stage.loaderInfo.url; 
			var doMainArray:Array = doMain.split("/" ); 
				
			showActiveBarName(doMain);
			if (doMainArray[0] == "file:" ) { 
				//为处理本地系统返回的路径由“/”或“\”两种间隔组成的不同情况，而分别处理 
				if (doMainArray.length<= 3 ){ 
					currSwfUrl = doMainArray[2 ]; 
					currSwfUrl = currSwfUrl.substring(0 ,currSwfUrl.lastIndexOf(currSwfUrl.charAt( 2 ))); 
				}else { 
					currSwfUrl = doMain; 
					currSwfUrl = currSwfUrl.substring(0 ,currSwfUrl.lastIndexOf( "/" )); 
				} 
			}else { 
				currSwfUrl = doMain; 
				currSwfUrl = currSwfUrl.substring(0 ,currSwfUrl.lastIndexOf( "/" )); 
			} 
			currSwfUrl = currSwfUrl + "/" ;
			return currSwfUrl;
			
		}
		private function showActiveBarName(str:String):void{
			trace(str);
			TextField(activeBar.getChildByName("txt")).text = str;
		}
	}
	
}