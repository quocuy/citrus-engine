package com.citrusengine.objects.platformer.nape {

	import com.citrusengine.objects.NapePhysicsObject;
	import nape.callbacks.PreCallback;
	import nape.callbacks.PreListener;
	import nape.geom.Vec2;
	
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionType;
	import nape.callbacks.CbType;
	import nape.callbacks.PreFlag;
	import nape.phys.BodyType;

	/**
	 * @author Aymeric / Nick
	 */
	public class Platform extends NapePhysicsObject {
		
		public static const ONEWAY_PLATFORM:CbType = new CbType();
		
		
		private var _oneWay:Boolean = false;
		private var _preListener:PreListener;

		public function Platform(name:String, params:Object = null) {
			
			super(name, params);
		}
		
		override public function destroy():void {
			if (_body.cbTypes.length > 0) {
				_body.cbTypes.clear();
			}
			if (_oneWay) {
				if (_preListener) {
					_preListener.space = null;
				}
				_body.cbTypes.remove(ONEWAY_PLATFORM);
			}
			_preListener = null;
			
			super.destroy();
		}
		
		public function get oneWay():Boolean
		{
			return _oneWay;
		}
		
		[Property(value = "false")]
		public function set oneWay(value:Boolean):void
		{
			if (_oneWay == value)
				return;
			
			_oneWay = value;
			
			if (_oneWay)
			{
				_preListener = new PreListener(InteractionType.ANY, Platform.ONEWAY_PLATFORM, CbType.ANY_BODY, handlePreContact)
				_body.space.listeners.add(_preListener);
				_body.cbTypes.add(ONEWAY_PLATFORM);
			}
			else
			{
				if (_preListener) {
					_preListener.space = null;
				}
				_body.cbTypes.remove(ONEWAY_PLATFORM);
			}
		}
		
		override public function update(timeDelta:Number):void {
			
			super.update(timeDelta);
		}
		
		override protected function defineBody():void {
			_bodyType = BodyType.STATIC;
			
			if (_oneWay) {
				_preListener = new PreListener(InteractionType.COLLISION, ONEWAY_PLATFORM, CbType.ANY_BODY, this.handlePreContact);
			}
		}
		
		override protected function createBody():void 
		{
			super.createBody();
			if (_oneWay) {
				_body.cbTypes.add(ONEWAY_PLATFORM);
			}
		}
		
		override protected function createConstraint():void {
			super.createConstraint();
			
			if (_preListener) {
				_body.space.listeners.add(_preListener);
			}
		}
		
		override public function handlePreContact(callback:PreCallback):PreFlag
		{
			var dir:Vec2 = new Vec2(0, callback.swapped ? 1 : -1);
			
			if (dir.dot(callback.arbiter.collisionArbiter.normal) >= 0) {
				return null;
			} else {
				return PreFlag.IGNORE;
			}
		}
	}
}
