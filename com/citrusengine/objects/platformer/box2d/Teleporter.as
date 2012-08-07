package com.citrusengine.objects.platformer.box2d {	import Box2DAS.Dynamics.ContactEvent;	import com.citrusengine.objects.Box2DPhysicsObject;	import flash.utils.clearTimeout;	import flash.utils.setTimeout; 	/**	 * A Teleporter, moves an object to a destination. The waiting time is more or less long.	 * It is a Sensor which can be activate after a contact.	 * Properties:	 * endX : the object's x destination after teleportation.	 * endY : the object's y destination after teleportation.	 * object : the PhysicsObject teleported.	 * waitingTime : how many time before teleportation, master ?	 * teleport : set it to true to teleport your object.	 */	public class Teleporter extends Sensor { 				/**		 * the object's x destination after teleportation.		 */		[Inspectable(defaultValue="0")]		public var endX:Number = 0;				/**		 * the object's y destination after teleportation.		 */		[Inspectable(defaultValue="0")]		public var endY:Number = 0;				/**		 * the PhysicsObject teleported.		 */		[Inspectable(defaultValue="",type="String")]		public var object:Box2DPhysicsObject; 				/**		 * how many time before teleportation, master ?		 */ 		[Inspectable(defaultValue="0")]		public var waitingTime:Number = 0;				/**		 * set it to true to teleport your object.		 */		public var teleport:Boolean = false; 		protected var _teleporting:Boolean = false; 		protected var _teleportTimeoutID:uint; 		public function Teleporter(name:String, params:Object = null) {			super(name, params);		} 		override public function destroy():void { 			clearTimeout(_teleportTimeoutID); 			super.destroy();		} 		override public function update(timeDelta:Number):void { 			super.update(timeDelta); 			if (teleport) { 				_teleporting = true; 				_teleportTimeoutID = setTimeout(_teleport, waitingTime); 				teleport = false;			} 			_updateAnimation();		}				override protected function handleBeginContact(e:ContactEvent):void {						onBeginContact.dispatch(e);						teleport = true;		} 		protected function _teleport():void { 			_teleporting = false; 			object.x = endX;			object.y = endY; 			clearTimeout(_teleportTimeoutID);		} 		protected function _updateAnimation():void { 			if (_teleporting) {				_animation = "teleport";			} else {				_animation = "normal";			}		}	}}