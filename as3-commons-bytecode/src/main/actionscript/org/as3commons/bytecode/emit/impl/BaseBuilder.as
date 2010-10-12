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
package org.as3commons.bytecode.emit.impl {
	import org.as3commons.bytecode.emit.IEmitObject;
	import org.as3commons.bytecode.emit.enum.MemberVisibility;

	public class BaseBuilder implements IEmitObject {

		public function BaseBuilder(name:String = null, visibility:MemberVisibility = null, nameSpace:String = null) {
			super();
			init(name, nameSpace, visibility);
		}

		protected function init(name:String, nameSpace:String, visibility:MemberVisibility):void {
			_name = name;
			_namespace = nameSpace;
			_visiblity = visibility;
		}

		private var _packageName:String;
		private var _name:String;
		private var _namespace:String;
		private var _visiblity:MemberVisibility;
		private var _traits:Array = [];

		public function get packageName():String {
			return _packageName;
		}

		public function set packageName(value:String):void {
			_packageName = value;
		}

		public function get name():String {
			return _name;
		}

		public function set name(value:String):void {
			_name = value;
		}

		public function get namespace():String {
			return _namespace;
		}

		public function set namespace(value:String):void {
			_namespace = value;
		}

		public function get visibility():MemberVisibility {
			return _visiblity;
		}

		public function set visibility(value:MemberVisibility):void {
			_visiblity = value;
		}

		public function get traits():Array {
			return _traits;
		}

		public function set traits(value:Array):void {
			_traits = value;
		}

	}
}