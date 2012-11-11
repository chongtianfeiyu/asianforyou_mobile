package src
{
	//import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TouchEvent;
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
		
		public function Main():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			if (Capabilities.os.substr(0, 7) == "Windows") {
				screenWidth = 480;
				screenHeight = 800;//用于windows系下调试，不过到了CS6就不用了
			}else if (Capabilities.os.substr(0, 5) == "Linux" || Capabilities.os.substr(0, 6) == "iPhone") {
				screenWidth =  Capabilities.screenResolutionX;
				screenHeight =  Capabilities.screenResolutionY;
			}
			scale = screenWidth / 480;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
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
			//loadImage("http://www.theblackalley.info/hardcore/jasminewang01/jasminewang07.jpg");
			loadImage("http://www.theblackalley.net/asian4you/nudegalleries/chin-si-yee-04a/13.jpg");
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
				pictureContainer.addEventListener(TouchEvent.TOUCH_TAP, onPictureTouchHandler);
				pictureContainer.addEventListener(TouchEvent.TOUCH_BEGIN, onPictureTouchBeginHandler);
				pictureContainer.addEventListener(TouchEvent.TOUCH_END, onPictureTouchEndHandler);
				
			}
		}
		private function initBottomBar():void {
			bottomBar = new BottomBar() as Sprite;
			bottomBar.width = screenWidth;
			bottomBar.height = bottomBar.height * scale;
			bottomBar.x = 0;
			bottomBar.y = screenHeight;
			this.addChild(bottomBar);
			bottomBar.visible = false;
		}
		private var loader:URLLoader;
		private function loadImage(url:String):void {
			loader = new URLLoader();
			showBottomBar(false);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loadingBar.visible = true;
			loadingBar.gotoAndStop(1);
			//loader.addEventListener(Event.INIT, onImageLoadingStartHandler);
			loader.addEventListener(Event.COMPLETE, onImageLoadCompleteHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadErrorHandler);
			loader.load(new URLRequest(url));
		}
		private function onImageLoadCompleteHandler(event:Event):void {
			var _ba:ByteArray = event.target.data as ByteArray;
			var _l:Loader = new Loader();
			_l.contentLoaderInfo.addEventListener (Event.COMPLETE, onBytesLoaded);
            _l.loadBytes(_ba);
            loader.removeEventListener (Event.COMPLETE , onImageLoadCompleteHandler);
			loader.removeEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
            loader = null;
		}
		private function onImageLoadingStartHandler(event:Event):void {
			trace("onImageLoadingStartHandler");
			loadingBar.visible = true;
			loadingBar.gotoAndStop(1);
			loader.removeEventListener(Event.INIT, onImageLoadingStartHandler);
		}
		private function onBytesLoaded(event:Event):void {
			var _bitmap:Bitmap = event.target.content as Bitmap;
			trace(_bitmap.width, _bitmap.height );
			var _scale:Number = screenWidth / _bitmap.width;
			_bitmap.width = screenWidth;
			_bitmap.height = _bitmap.height * _scale;
			trace(_bitmap.width, _bitmap.height );
			pictureContainer.addChild(_bitmap );
			event.target.loader.contentLoaderInfo.removeEventListener (Event.COMPLETE, onBytesLoaded);
			loadingBar.visible = false;
			loadingBar.gotoAndStop(1);
		}
		private function onImageLoadingHandler(event:ProgressEvent):void {
			var loadedPercent:int = event.bytesLoaded / event.bytesTotal * 100;
			loadingBar.gotoAndStop(loadedPercent);
			var txt:TextField = loadingBar.getChildByName("txt") as TextField;
			txt.text = loadedPercent + "%";
		}
		private function onImageLoadErrorHandler(event:IOErrorEvent):void {
			trace("Picture load error:");
			loader.removeEventListener(Event.INIT, onImageLoadingStartHandler);
            loader.removeEventListener(Event.COMPLETE , onImageLoadCompleteHandler);
			loader.removeEventListener(ProgressEvent.PROGRESS, onImageLoadingHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadErrorHandler);
		}
		
		//=====================TOUCH && GESTURE====================
		private var startPoint:Point;
		private function onPictureTouchHandler(event:TouchEvent):void {
			//处理触摸事件
			trace("onPictureTouchHandler");
			showBottomBar(!bottomBar.visible);//如果显示则隐藏，否则则显示
		}
		private function onPictureTouchBeginHandler(event:TouchEvent):void {
			//处理触摸开始事件
			trace("touchBegin");
		}
		private function onPictureTouchEndHandler(event:TouchEvent):void {
			//处理触摸结束事件
			trace("touchEnd");
		}
		
		//=====================功能函数========================
		private function showBottomBar(bl:Boolean):void {
			if (bl && !bottomBar.visible) {
				//显示
				bottomBar.visible = true;
				TweenLite.to(bottomBar, 0.5, { y:screenHeight - bottomBar.height } );
			}else if (bl && bottomBar.visible) {
				//隐藏
				bottomBar.visible = false;
				TweenLite.to(bottomBar, 0.5, { y:0 } );
			}
		}
	}
	
}