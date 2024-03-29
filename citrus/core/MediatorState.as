package citrus.core {

	import citrus.datastructures.PoolObject;
	import citrus.objects.APhysicsObject;
	import citrus.system.Entity;
	import citrus.system.components.ViewComponent;
	import citrus.view.ACitrusView;

	/**
	 * The MediatorState class is very important. It usually contains the logic for a particular state the game is in.
	 * You should never instanciate/extend this class by your own. It's used via a wrapper: State or StarlingState or Away3DState.
	 * There can only ever be one state running at a time. You should extend the State class
	 * to create logic and scripts for your levels. You can build one state for each level, or
	 * create a state that represents all your levels. You can get and set the reference to your active
	 * state via the CitrusEngine class.
	 */
	final public class MediatorState {

		private var _objects:Vector.<CitrusObject> = new Vector.<CitrusObject>();
		private var _poolObjects:Vector.<PoolObject> = new Vector.<PoolObject>();
		private var _view:ACitrusView;

		public function MediatorState() {
		}

		/**
		 * Called by the Citrus Engine.
		 */
		public function destroy():void {
			// Call destroy on all objects, and remove all art from the stage.
			var n:uint = _objects.length;
			for (var i:int = n - 1; i >= 0; --i) {
				var object:CitrusObject = _objects[i];
				object.destroy();

				_view.removeArt(object);
			}
			_objects.length = 0;

			for each (var poolObject:PoolObject in _poolObjects)
				poolObject.destroy();

			_poolObjects.length = 0;

			_view.destroy();
		}

		/**
		 * Gets a reference to this state's view manager. Take a look at the class definition for more information about this. 
		 */
		public function get view():ACitrusView {
			return _view;
		}

		public function set view(value:ACitrusView):void {
			
			_view = value;
		}

		/**
		 * This method calls update on all the CitrusObjects that are attached to this state.
		 * The update method also checks for CitrusObjects that are ready to be destroyed and kills them.
		 * Finally, this method updates the View manager. 
		 */
		public function update(timeDelta:Number):void {

			// Search objects to destroy
			var garbage:Array = [];
			var n:uint = _objects.length;

			for (var i:uint = 0; i < n; ++i) {

				var object:CitrusObject = _objects[i];

				if (object.kill)
					garbage.push(object);
				else if (object.updateCallEnabled)
					object.update(timeDelta);
			}

			// Destroy all objects marked for destroy
			// TODO There might be a limit on the number of Box2D bodies that you can destroy in one tick?
			n = garbage.length;
			for (i = 0; i < n; ++i) {
				var garbageObject:CitrusObject = garbage[i];
				_objects.splice(_objects.indexOf(garbageObject), 1);

				if (garbageObject is Entity)
					_view.removeArt((garbageObject as Entity).components["view"]);
				else
					_view.removeArt(garbageObject);

				garbageObject.destroy();
			}

			for each (var poolObject:PoolObject in _poolObjects)
				poolObject.updatePhysics(timeDelta);

			// Update the state's view
			_view.update(timeDelta);
		}

		/**
		 * Call this method to add a CitrusObject to this state. All visible game objects and physics objects
		 * will need to be created and added via this method so that they can be properly created, managed, updated, and destroyed. 
		 * @return The CitrusObject that you passed in. Useful for linking commands together.
		 */
		public function add(object:CitrusObject):CitrusObject {
			
			if (object is Entity)
				throw new Error("Object named: " + object.name + " is an entity and should be added to the state via addEntity method.");
			
			for each (var objectAdded:CitrusObject in objects) 
				if (object == objectAdded)
					throw new Error(object.name + " is already added to the state.");
			
			if (object is APhysicsObject)
				(object as APhysicsObject).addPhysics();
			
			_objects.push(object);
			_view.addArt(object);
			
			return object;
		}

		/**
		 * Call this method to add an Entity to this state. All entities will need to be created
		 * and added via this method so that they can be properly created, managed, updated, and destroyed.
		 * @param view an Entity is designed for complex objects, most of the time they have a view component.
		 * @return The Entity that you passed in. Useful for linking commands together.
		 */
		public function addEntity(entity:Entity, view:ViewComponent = null):Entity {
			
			for each (var objectAdded:CitrusObject in objects)
				if (entity == objectAdded)
					throw new Error(entity.name + " is already added to the state.");
			
			_objects.push(entity);
			_view.addArt(view);
			return entity;
		}

		/**
		 * Call this method to add a PoolObject to this state. All pool objects and  will need to be created 
		 * and added via this method so that they can be properly created, managed, updated, and destroyed.
		 * @param poolObject The PoolObject isCitrusObjectPool's value must be true to be render through the State.
		 * @return The PoolObject that you passed in. Useful for linking commands together.
		 */
		public function addPoolObject(poolObject:PoolObject):PoolObject {

			if (poolObject.isCitrusObjectPool) {

				_poolObjects.push(poolObject);

				return poolObject;

			} else return null;
		}

		/**
		 * When you are ready to remove an object from getting updated, viewed, and generally being existent, call this method.
		 * Alternatively, you can just set the object's kill property to true. That's all this method does at the moment. 
		 */
		public function remove(object:CitrusObject):void {
			object.kill = true;
		}

		/**
		 * Gets a reference to a CitrusObject by passing that object's name in.
		 * Often the name property will be set via a level editor such as the Flash IDE. 
		 * @param name The name property of the object you want to get a reference to.
		 */
		public function getObjectByName(name:String):CitrusObject {

			for each (var object:CitrusObject in _objects) {
				if (object.name == name)
					return object;
			}
			
			if (_poolObjects.length > 0)
			{
				var poolObject:PoolObject;
				var found:Boolean = false;
				for each(poolObject in _poolObjects)
				{
					poolObject.foreachRecycled(function(pobject:*):Boolean
					{
						if (pobject is CitrusObject && pobject["name"] == name)
						{
							object = pobject;
							return found = true;
						}
						return false;
					});
					
					if (found)
						return object;
				}
			}

			return null;
		}

		/**
		 * This returns a vector of all objects of a particular name. This is useful for adding an event handler
		 * to objects that aren't similar but have the same name. For instance, you can track the collection of 
		 * coins plus enemies that you've named exactly the same. Then you'd loop through the returned vector to change properties or whatever you want.
		 * @param name The name property of the object you want to get a reference to.
		 */
		public function getObjectsByName(name:String):Vector.<CitrusObject> {

			var objects:Vector.<CitrusObject> = new Vector.<CitrusObject>();
			var object:CitrusObject;
			
			for each (object in _objects) {
				if (object.name == name)
					objects.push(object);
			}
			
			if (_poolObjects.length > 0)
			{
				var poolObject:PoolObject;
				for each(poolObject in _poolObjects)
				{
					poolObject.foreachRecycled(function(pobject:*):Boolean
					{
						if (pobject is CitrusObject && pobject["name"] == name)
							objects.push(pobject as CitrusObject);
						return false;
					});
				}
			}

			return objects;
		}

		/**
		 * Returns the first instance of a CitrusObject that is of the class that you pass in. 
		 * This is useful if you know that there is only one object of a certain time in your state (such as a "Hero").
		 * @param type The class of the object you want to get a reference to.
		 */
		public function getFirstObjectByType(type:Class):CitrusObject {
			var object:CitrusObject;
			
			for each (object in _objects) {
				if (object is type)
					return object;
			}
			
			if (_poolObjects.length > 0)
			{
				var poolObject:PoolObject;
				var found:Boolean = false;
				for each(poolObject in _poolObjects)
				{
					poolObject.foreachRecycled(function(pobject:*):Boolean
					{
						if (pobject is type)
						{
							object = pobject;
							return found = true;
						}
						return false;
					});
					
					if (found)
						return object;
				}
			}

			return null;
		}

		/**
		 * This returns a vector of all objects of a particular type. This is useful for adding an event handler
		 * to all similar objects. For instance, if you want to track the collection of coins, you can get all objects
		 * of type "Coin" via this method. Then you'd loop through the returned array to add your listener to the coins' event.
		 * @param type The class of the object you want to get a reference to.
		 */
		public function getObjectsByType(type:Class):Vector.<CitrusObject> {

			var objects:Vector.<CitrusObject> = new Vector.<CitrusObject>();
			var object:CitrusObject;
			
			for each (object in _objects) {
				if (object is type) {
					objects.push(object);
				}
			}
			
			if (_poolObjects.length > 0)
			{
				var poolObject:PoolObject;
				for each(poolObject in _poolObjects)
				{
					poolObject.foreachRecycled(function(pobject:*):Boolean
					{
						if (pobject is type)
							objects.push(pobject as CitrusObject);
						return false;
					});
				}
			}

			return objects;
		}

		/**
		 * Destroy all the objects added to the State and not already killed.
		 * @param except CitrusObjects you want to save.
		 */
		public function killAllObjects(except:Array):void {

			for each (var objectToKill:CitrusObject in _objects) {

				objectToKill.kill = true;

				for each (var objectToPreserve:CitrusObject in except) {

					if (objectToKill == objectToPreserve) {

						objectToPreserve.kill = false;
						except.splice(except.indexOf(objectToPreserve), 1);
						break;
					}
				}
			}
		}

		/**
		 * Contains all the objects added to the State and not killed.
		 */
		public function get objects():Vector.<CitrusObject> {
			return _objects;
		}
	}
}