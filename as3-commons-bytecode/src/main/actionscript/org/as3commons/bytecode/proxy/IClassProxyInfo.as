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
package org.as3commons.bytecode.proxy {
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptorFactory;

	public interface IClassProxyInfo {

		function get interceptorFactory():IMethodInvocationInterceptorFactory;

		function set interceptorFactory(value:IMethodInvocationInterceptorFactory):void;

		function get proxiedClass():Class;

		function get methodInvocationInterceptorClass():Class;

		function get makeDynamic():Boolean;

		function set makeDynamic(value:Boolean):void;

		function get proxyAll():Boolean;

		function get onlyProxyConstructor():Boolean;

		function set onlyProxyConstructor(value:Boolean):void;

		function get proxyAllMethods():Boolean;

		function set proxyAllMethods(value:Boolean):void;

		function get proxyAllAccessors():Boolean;

		function set proxyAllAccessors(value:Boolean):void;

		function proxyMethod(methodName:String, namespace:String = null):void;

		function proxyAccessor(accessorName:String, namespace:String = null):void;

		function introduce(clazz:Class):void;

		function get methods():Array;

		function get accessors():Array;

		function get introductions():Array;

	}
}