/*
 * Copyright 2007-2010 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.as3commons.eventbus.impl {

	import flash.events.Event;
	import flash.utils.Dictionary;

	import org.as3commons.eventbus.IEventBusListener;
	import org.as3commons.logging.ILogger;
	import org.as3commons.logging.LoggerFactory;
	import org.as3commons.reflect.MethodInvoker;

	/**
	 * The <code>EventBus</code> is used as a publish/subscribe event mechanism that lets objects communicate
	 * with eachother in a loosely coupled way.
	 *
	 * <p>Objects interested in receiving events can either implement the <code>IEventBusListener</code> interface
	 * and add themselves as listeners for all events on the event bus via the <code>EventBus.addListener()</code> method,
	 * if they are only interested in some events, they can add a specific event handler via the
	 * <code>EventBus.addEventListener()</code> method. The last option is too subscribe to events of a specific Class, use the</p>
	 * <code>EventBus.addEventClassListener()</code> for this purpose.
	 * <p>To dispatch an event, invoke the <code>EventBus.dispatchEvent()</code> or <code>EventBus.dispatch()</code> method.</p>
	 *
	 * @author Christophe Herreman
	 * @author Roland Zwaga
	 */
	public class EventBus {

		private static var LOGGER:ILogger = LoggerFactory.getClassLogger(EventBus);

		// --------------------------------------------------------------------
		//
		// Private Static Variables
		//
		// --------------------------------------------------------------------

		/** The <code>Dictionary&lt;Class,Function[]&gt;</code> that holds a mapping between event classes and a list of listener functions */
		protected var _classListeners:Dictionary = new Dictionary();

		/** The <code>Dictionary&lt;Class,MethodInvoker[]&gt;</code> that holds a mapping between event classes and a list of listener proxies */
		protected var _classProxyListeners:Dictionary = new Dictionary();

		/** The IEventBusListener objects that listen to all events on the event bus. */
		protected var _listeners:ListenerCollection = new ListenerCollection();

		/** A map of event types/names with there corresponding handler functions. */
		protected var _eventListeners:Object /* <String, ListenerCollection> */ = {};

		/** A map of event types/names with there corresponding proxied handler functions. */
		protected var _eventListenerProxies:Object /* <String, ListenerCollection> */ = {};

		// --------------------------------------------------------------------
		//
		// Constructor
		//
		// --------------------------------------------------------------------

		public function EventBus() {
			super();
		}

		// --------------------------------------------------------------------
		//
		// Public Methods
		//
		// --------------------------------------------------------------------

		/**
		 * Adds the given listener object as a listener to all events send via the event bus.
		 */
		public function addListener(listener:IEventBusListener, useWeakReference:Boolean = false):void {
			if (!listener || (_listeners.indexOf(listener) > -1)) {
				return;
			}
			_listeners.add(listener, useWeakReference);
			LOGGER.debug("Added IEventBusListener " + listener);
		}

		/**
		 * Removes the given listener from the event bus.
		 * @param listener
		 */
		public function removeListener(listener:IEventBusListener):void {
			_listeners.remove(listener);
			LOGGER.debug("Removed IEventBusListener " + listener);
		}

		/**
		 * Adds the given listener function as an event handler to the given event type.
		 * @param type the type of event to listen to
		 * @param listener the event handler function
		 */
		public function addEventListener(type:String, listener:Function, useWeakReference:Boolean = false):void {
			var eventListeners:ListenerCollection = getEventListenersForEventType(type);
			if (eventListeners.indexOf(listener) == -1) {
				eventListeners.add(listener, useWeakReference);
				LOGGER.debug("Added eventbus listener " + listener + " for type " + type);
			}
		}

		/**
		 * Removes the given listener function as an event handler from the given event type.
		 * @param type
		 * @param listener
		 */
		public function removeEventListener(type:String, listener:Function):void {
			var eventListeners:ListenerCollection = getEventListenersForEventType(type);
			eventListeners.remove(listener);
			LOGGER.debug("Removed eventbus listener " + listener + " for type " + type);
		}

		/**
		 * Adds a proxied event handler as a listener to the specified event type.
		 * @param type the type of event to listen to
		 * @param proxy a proxy method invoker for the event handler
		 */
		public function addEventListenerProxy(type:String, proxy:MethodInvoker, useWeakReference:Boolean = false):void {
			var eventListenerProxies:ListenerCollection = getEventListenerProxiesForEventType(type);
			if (eventListenerProxies.indexOf(proxy) == -1) {
				eventListenerProxies.add(proxy, useWeakReference);
				LOGGER.debug("Added eventbus listenerproxy " + proxy + " for type " + type);
			}
		}

		/**
		 * Removes a proxied event handler as a listener from the specified event type.
		 */
		public function removeEventListenerProxy(type:String, proxy:MethodInvoker):void {
			var eventListenerProxies:ListenerCollection = getEventListenerProxiesForEventType(type);
			eventListenerProxies.remove(proxy);
			LOGGER.debug("Removed eventbus listenerproxy " + proxy + " for type " + type);
		}

		/**
		 * Adds a listener function for events of a specific <code>Class</code>.
		 * @param eventClass The specified <code>Class</code>.
		 * @param listener The specified listener function.
		 */
		public function addEventClassListener(eventClass:Class, listener:Function, useWeakReference:Boolean = false):void {
			var listeners:ListenerCollection = (_classListeners[eventClass] == null) ? new ListenerCollection() : _classListeners[eventClass] as ListenerCollection;
			if (listeners.indexOf(listener) < 0) {
				listeners.add(listener, useWeakReference);
				_classListeners[eventClass] = listeners;
				LOGGER.debug("Added eventbus classlistener " + listener + " for class " + eventClass);
			}
		}

		/**
		 * Removes a listener function for events of a specific Class.
		 * @param eventClass The specified <code>Class</code>.
		 * @param listener The specified listener function.
		 */
		public function removeEventClassListener(eventClass:Class, listener:Function):void {
			var listeners:ListenerCollection = _classListeners[eventClass] as ListenerCollection;
			if (listeners != null) {
				listeners.remove(listener);
				if (listeners.length < 1) {
					delete _classListeners[eventClass];
				}
				LOGGER.debug("Removed eventbus classlistener " + listener + " for class " + eventClass);
			}
		}

		/**
		 * Adds a proxied event handler as a listener for events of a specific <code>Class</code>.
		 * @param eventClass The specified <code>Class</code>.
		 * @param proxy The specified listener function.
		 */
		public function addEventClassListenerProxy(eventClass:Class, proxy:MethodInvoker, useWeakReference:Boolean = false):void {
			var proxies:ListenerCollection = (_classProxyListeners[eventClass] == null) ? new ListenerCollection() : _classProxyListeners[eventClass] as ListenerCollection;
			if (proxies.indexOf(proxy) < 0) {
				proxies.add(proxy, useWeakReference);
				_classProxyListeners[eventClass] = proxies;
				LOGGER.debug("Added eventbus classlistener proxy " + proxy + " for class " + eventClass);
			}
		}

		/**
		 * Removes a proxied event handler as a listener for events of a specific <code>Class</code>.
		 * @param eventClass The specified <code>Class</code>.
		 * @param proxy The specified listener function.
		 */
		public function removeEventClassListenerProxy(eventClass:Class, proxy:MethodInvoker):void {
			var proxies:ListenerCollection = _classProxyListeners[eventClass] as ListenerCollection;
			if (proxies != null) {
				proxies.remove(proxy);
				if (proxies.length < 1) {
					delete _classProxyListeners[eventClass];
				}
				LOGGER.debug("Removed eventbus classlistener proxy " + proxy + " for class " + eventClass);
			}
		}

		/**
		 * Clears the entire <code>EventBus</code> by removing all types of listeners.
		 */
		public function removeAll():void {
			_classListeners = new Dictionary();
			_classProxyListeners = new Dictionary();
			_listeners = new ListenerCollection();
			_eventListeners = {};
			_eventListenerProxies = {};
			LOGGER.debug("Eventbus was cleared entirely");
		}

		/**
		 * Dispatches the specified <code>Event</code> on the event bus.
		 * @param event The specified <code>Event</code>.
		 */
		public function dispatchEvent(event:Event):void {
			if (!event) {
				return;
			}

			notifyEventBusListeners(event);

			notifySpecificEventListeners(event);

			notifyProxies(event);

			var eventClass:Class = Object(event).constructor as Class;

			notifySpecificClassListeners(eventClass, event);

			notifySpecificClassListenerProxies(eventClass, event);
		}

		protected function notifySpecificClassListenerProxies(eventClass:Class, event:Event):void {
			// notify proxies for a specific event Class
			var cls:Class;
			var obj:Object;
			for (obj in _classProxyListeners) {
				cls = Class(obj);
				if (eventClass === cls) {
					var proxies:ListenerCollection = _classProxyListeners[obj];
					if (proxies != null) {
						var len:uint = proxies.length;
						for (var i:uint = 0; i < len; i++) {
							var proxy:MethodInvoker = proxies.get(i) as MethodInvoker;
							if (proxy != null) {
								proxy.arguments = [event];
								proxy.invoke();
								LOGGER.debug("Notified class listenerproxy " + proxy + " of event " + event);
							}
						}
					}
					break;
				}
			}
		}


		protected function notifySpecificClassListeners(eventClass:Class, event:Event):Class {
			// notify listeners for a specific event Class
			var cls:Class;
			var obj:Object;
			if (eventClass != null) {
				for (obj in _classListeners) {
					cls = Class(obj);
					if (eventClass === cls) {
						var funcs:ListenerCollection = _classListeners[obj];
						if (funcs != null) {
							for (var i:uint = 0; i < funcs.length; i++) {
								var func:Function = funcs.get(i) as Function;
								if (func != null) {
									func.apply(null, [event]);
									LOGGER.debug("Notified class listener " + func + " of event " + event);
								}
							}
						}
						break;
					}
				}
			}
			return eventClass;
		}


		protected function notifyProxies(event:Event):void {
			// notify all proxies
			var eventListenerProxies:ListenerCollection = _eventListenerProxies[event.type];
			if (eventListenerProxies != null) {
				var len:uint = eventListenerProxies.length;
				for (var i:uint = 0; i < len; i++) {
					var proxy:MethodInvoker = eventListenerProxies.get(i) as MethodInvoker;
					if (proxy != null) {
						proxy.arguments = [event];
						proxy.invoke();
						LOGGER.debug("Notified proxy " + proxy + " of event " + event);
					}
				}
			}
		}


		protected function notifySpecificEventListeners(event:Event):void {
			// notify all specific event listeners
			var eventListeners:ListenerCollection = _eventListeners[event.type];
			if (eventListeners != null) {
				var len:uint = eventListeners.length;
				for (var i:uint = 0; i < len; i++) {
					var eventListener:Function = eventListeners.get(i) as Function;
					if (eventListener != null) {
						eventListener.apply(null, [event]);
						LOGGER.debug("Notified listener " + eventListener + " of event " + event);
					}
				}
			}
		}

		protected function notifyEventBusListeners(event:Event):void {
			// notify all event bus listeners
			var len:uint = _listeners.length;
			for (var i:uint = 0; i < len; i++) {
				var listener:IEventBusListener = _listeners.get(i) as IEventBusListener;
				if (listener != null) {
					listener.onEvent(event);
					LOGGER.debug("Notified eventbus listener " + listener + " of event " + event);
				}
			}
		}


		/**
		 * Convenience method for dispatching an event. This will create an Event instance with the given
		 * type and call dispatchEvent() on the event bus.
		 * @param type the type of the event to dispatch
		 */
		public function dispatch(type:String):void {
			dispatchEvent(new Event(type));
		}

		// --------------------------------------------------------------------
		//
		// Private Static Methods
		//
		// --------------------------------------------------------------------

		private function getEventListenersForEventType(eventType:String):ListenerCollection {
			if (!_eventListeners[eventType]) {
				_eventListeners[eventType] = new ListenerCollection();
			}
			return _eventListeners[eventType];
		}

		private function getEventListenerProxiesForEventType(eventType:String):ListenerCollection {
			if (!_eventListenerProxies[eventType]) {
				_eventListenerProxies[eventType] = new ListenerCollection();
			}
			return _eventListenerProxies[eventType];
		}

	}

}