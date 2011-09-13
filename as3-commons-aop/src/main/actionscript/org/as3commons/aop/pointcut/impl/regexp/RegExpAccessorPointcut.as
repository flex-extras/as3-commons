/*
* Copyright 2007-2011 the original author or authors.
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
package org.as3commons.aop.pointcut.impl.regexp {
	import org.as3commons.aop.pointcut.IAccessorPointcut;
	import org.as3commons.lang.ClassUtils;
	import org.as3commons.reflect.Accessor;

	/**
	 * Regular expression pointcut to match accessors.
	 *
	 * @author Christophe Herreman
	 */
	public class RegExpAccessorPointcut extends AbstractRegExpPointcut implements IAccessorPointcut {

		// --------------------------------------------------------------------
		//
		// Constructor
		//
		// --------------------------------------------------------------------

		public function RegExpAccessorPointcut() {
		}

		// --------------------------------------------------------------------
		//
		// Public Methods
		//
		// --------------------------------------------------------------------

		public function matchesAccessor(accessor:Accessor):Boolean {
			var className:String = ClassUtils.getFullyQualifiedName(accessor.declaringType.clazz, true);
			var fullName:String = className + "." + accessor.name;
			return match(fullName);
		}

	}
}
