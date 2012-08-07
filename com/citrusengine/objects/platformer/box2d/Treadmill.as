﻿package com.citrusengine.objects.platformer.box2d { 	import Box2DAS.Dynamics.b2Body; 	import com.citrusengine.objects.platformer.box2d.MovingPlatform; 	/**	 * A Treadmill is a MovingPlatform with some new options.	 * Properties:	 * speedTread : the speed of the tread.	 * startingDirection : the tread's direction.	 * enableTreadmill : activate it or not.	 */	public class Treadmill extends MovingPlatform { 				/**		 * The speed of the tread.		 */ 		[Inspectable(defaultValue="3")]		public var speedTread:Number = 3;				/**		 * The tread's direction.		 */		[Inspectable(defaultValue="right",enumeration="right,left")]		public var startingDirection:String = "right";  		/** 		 * Activate it or not. 		 */ 		[Inspectable(defaultValue="true")]		public var enableTreadmill:Boolean = true; 		public function Treadmill(name:String, params:Object = null) {						super(name, params); 			if (startingDirection == "left") {				_inverted = true;			}		} 		override public function destroy():void { 			super.destroy();		} 		override public function update(timeDelta:Number):void { 			super.update(timeDelta); 			if (enableTreadmill) { 				for each (var passengers:b2Body in _passengers) { 					if (startingDirection == "right") {						passengers.GetUserData().x += speedTread;					} else {						passengers.GetUserData().x -= speedTread;					} 				}			} 			_updateAnimation();		} 		protected function _updateAnimation():void { 			if (enableTreadmill) {				_animation = "move";			} else {				_animation = "normal";			}		}	}}