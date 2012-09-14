package com.citrusengine.utils {

	import com.citrusengine.core.CitrusEngine;

	import flash.display.Stage;
	import flash.system.Capabilities;

	/**
	 * This class provides mobile devices informations.
	 */
	public class Mobile {
		
		static private var _STAGE:Stage;
		
		static private const _IOS_MARGIN:uint = 40;
		
		static private const _IPHONE_RETINA_WIDTH:uint = 640;
		static private const _IPHONE_RETINA_HEIGHT:uint = 960;
		static private const _IPHONE5_RETINA_HEIGHT:uint = 1136;
		
		static private const _IPAD_WIDTH:uint = 768;
		static private const _IPAD_HEIGHT:uint = 1024;
		static private const _IPAD_RETINA_WIDTH:uint = 1536;
		static private const _IPAD_RETINA_HEIGHT:uint = 2048;

		public function Mobile() {

		}

		static public function isIOS():Boolean {
			return (Capabilities.version.substr(0, 3) == "IOS");
		}

		static public function isAndroid():Boolean {
			return (Capabilities.version.substr(0, 3) == "AND");
		}

		static public function isLandscapeMode():Boolean {
			
			if (!_STAGE)
				_STAGE = CitrusEngine.getInstance().stage;

			return _STAGE.fullScreenWidth > _STAGE.fullScreenHeight ? true : false;
		}
		
		static public function isRetina():Boolean {
			
			if (Mobile.isIOS()) {
				
				if (!_STAGE)
					_STAGE = CitrusEngine.getInstance().stage;
				
				if (isLandscapeMode())
					return (_STAGE.fullScreenWidth == _IPHONE_RETINA_HEIGHT || _STAGE.fullScreenWidth == _IPHONE5_RETINA_HEIGHT || _STAGE.fullScreenWidth == _IPAD_RETINA_HEIGHT || _STAGE.fullScreenHeight == _IPHONE_RETINA_HEIGHT || _STAGE.fullScreenHeight == _IPHONE5_RETINA_HEIGHT || _STAGE.fullScreenHeight == _IPAD_RETINA_HEIGHT);
				else
					return (_STAGE.fullScreenWidth == _IPHONE_RETINA_WIDTH ||  _STAGE.fullScreenWidth == _IPAD_RETINA_WIDTH || _STAGE.fullScreenHeight == _IPHONE_RETINA_WIDTH || _STAGE.fullScreenHeight == _IPAD_RETINA_WIDTH);
				
			} else 
				return false;
		}

		static public function isIpad():Boolean {

			if (Mobile.isIOS()) {
				
				if (!_STAGE)
					_STAGE = CitrusEngine.getInstance().stage;
					
					if (isLandscapeMode())
						return (_STAGE.fullScreenWidth == _IPAD_HEIGHT || _STAGE.fullScreenWidth == _IPAD_RETINA_HEIGHT || _STAGE.fullScreenHeight == _IPAD_HEIGHT || _STAGE.fullScreenHeight == _IPAD_RETINA_HEIGHT);
					else
						return (_STAGE.fullScreenWidth == _IPAD_WIDTH || _STAGE.fullScreenWidth == _IPAD_RETINA_WIDTH || _STAGE.fullScreenHeight == _IPAD_WIDTH || _STAGE.fullScreenHeight == _IPAD_RETINA_WIDTH);

			} else
				return false;
		}
		
		static public function isIphone5():Boolean {
			
			if (Mobile.isIOS()) {
				
				if (!_STAGE)
					_STAGE = CitrusEngine.getInstance().stage;
				
				return (_STAGE.fullScreenHeight == _IPHONE5_RETINA_HEIGHT || _STAGE.fullScreenHeight == Mobile._IPHONE5_RETINA_HEIGHT - _IOS_MARGIN);
				
			} else
				return false;
		}
	}
}
