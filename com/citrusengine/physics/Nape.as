package com.citrusengine.physics {

	import com.citrusengine.core.CitrusObject;
	import com.citrusengine.view.ISpriteView;
	import com.citrusengine.view.spriteview.NapeDebugArt;

	import nape.geom.Vec2;
	import nape.space.Space;

	/**
	 * This is a simple wrapper class that allows you to add a Nape space to your game's state.
	 * Add an instance of this class to your State before you create any phyiscs bodies. It will need to 
	 * exist first, or your physics bodies will throw an error when they try to create themselves.
	 */
	public class Nape extends CitrusObject implements ISpriteView {

		private var _visible:Boolean = false;

		private var _space:Space;
		private var _group:Number = 1;
		private var _view:* = NapeDebugArt;

		/**
		 * Creates and initializes a Nape space. 
		 */
		public function Nape(name:String, params:Object = null) {

			super(name, params);

			_space = new Space(new Vec2(0, 0));
		}

		override public function destroy():void {
			
			space.clear();
			
			super.destroy();
		}

		/**
		 * Gets a reference to the actual Nape space object. 
		 */
		public function get space():Space {
			return _space;
		}

		override public function update(timeDelta:Number):void {
			
			super.update(timeDelta);

			_space.step(1 / 20, 8, 8);
		}

		public function get x():Number {
			return 0;
		}

		public function get y():Number {
			return 0;
		}

		public function get parallax():Number {
			return 1;
		}

		public function get rotation():Number {
			return 0;
		}

		public function get group():Number {
			return _group;
		}

		public function set group(value:Number):void {
			_group = value;
		}

		public function get visible():Boolean {
			return _visible;
		}

		public function set visible(value:Boolean):void {
			_visible = value;
		}

		public function get animation():String {
			return "";
		}

		public function get view():* {
			return _view;
		}

		public function set view(value:*):void {
			_view = value;
		}

		public function get inverted():Boolean {
			return false;
		}

		public function get offsetX():Number {
			return 0;
		}

		public function get offsetY():Number {
			return 0;
		}

		public function get registration():String {
			return "topLeft";
		}
	}
}
