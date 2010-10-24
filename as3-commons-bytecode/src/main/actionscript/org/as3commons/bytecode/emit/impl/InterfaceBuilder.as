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
	import flash.errors.IllegalOperationError;
	import flash.system.ApplicationDomain;

	import org.as3commons.bytecode.emit.ICtorBuilder;
	import org.as3commons.bytecode.emit.IInterfaceBuilder;
	import org.as3commons.bytecode.emit.IVariableBuilder;

	public class InterfaceBuilder extends ClassBuilder implements IInterfaceBuilder {

		private static const INTERFACE_CONSTRUCTOR_ERROR:String = "Interfaces can't have constructors";
		private static const INTERFACE_PROPERTIES_ERROR:String = "Interfaces can't have properties. (Only getters and/or setters)";

		public function InterfaceBuilder() {
			super();
		}

		override public function defineConstructor():ICtorBuilder {
			throw new IllegalOperationError(INTERFACE_CONSTRUCTOR_ERROR);
		}

		override public function defineVariable(name:String = null, type:String = null, initialValue:* = undefined):IVariableBuilder {
			throw new IllegalOperationError(INTERFACE_PROPERTIES_ERROR);
		}

		override public function build(applicationDomain:ApplicationDomain):Array {
			return [];
		}

	}
}