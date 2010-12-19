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
package org.as3commons.bytecode.proxy {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;

	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.as3commons_bytecode_proxy;
	import org.as3commons.bytecode.emit.IAbcBuilder;
	import org.as3commons.bytecode.emit.IAccessorBuilder;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.emit.IMethodBuilder;
	import org.as3commons.bytecode.emit.IPackageBuilder;
	import org.as3commons.bytecode.emit.impl.AbcBuilder;
	import org.as3commons.bytecode.interception.BasicMethodInvocationInterceptor;
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptor;
	import org.as3commons.bytecode.reflect.ByteCodeAccessor;
	import org.as3commons.bytecode.reflect.ByteCodeMethod;
	import org.as3commons.bytecode.reflect.ByteCodeParameter;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.ByteCodeVariable;
	import org.as3commons.bytecode.util.MultinameUtil;
	import org.as3commons.lang.Assert;
	import org.as3commons.lang.ClassUtils;
	import org.as3commons.reflect.AccessorAccess;

	public class ProxyFactory extends EventDispatcher implements IProxyFactory {

		private static const CHARACTERS:String = "abcdefghijklmnopqrstuvwxys";
		private var _abcBuilder:IAbcBuilder;
		private var _domains:Dictionary;

		use namespace as3commons_bytecode_proxy;

		public function ProxyFactory() {
			super();
			initProxyFactory();
		}


		public function get domains():Dictionary {
			return _domains;
		}

		protected function initProxyFactory():void {
			_abcBuilder = new AbcBuilder();
			_domains = new Dictionary();
		}

		protected function generateSuffix():String {
			var len:int = 20;
			var result:Array = new Array(20);
			while (len--) {
				result[len] = CHARACTERS.charAt(Math.floor(Math.random() * 26));
			}
			return result.join('');
		}

		public function defineProxy(proxiedClass:Class, methodInvocationInterceptorClass:Class = null, applicationDomain:ApplicationDomain = null):ClassProxyInfo {
			methodInvocationInterceptorClass(methodInvocationInterceptorClass != null) ? methodInvocationInterceptorClass : BasicMethodInvocationInterceptor;
			Assert.state(ClassUtils.isImplementationOf(methodInvocationInterceptorClass, IMethodInvocationInterceptor, applicationDomain) == true, "methodInvocationInterceptorClass argument must be a class that implements IMethodInvocationInterceptor");
			applicationDomain = (applicationDomain != null) ? applicationDomain : ApplicationDomain.currentDomain;
			if (_domains[applicationDomain] == null) {
				_domains[applicationDomain] = [];
			}
			var infos:Array = _domains[applicationDomain] as Array;
			var info:ClassProxyInfo = new ClassProxyInfo(proxiedClass, methodInvocationInterceptorClass);
			infos[infos.length] = info;
			return info;
		}

		public function createProxyClasses():IAbcBuilder {
			for (var domain:* in _domains) {
				var infos:Array = _domains[domain] as Array;
				for each (var info:ClassProxyInfo in infos) {
					buildProxy(info, domain);
				}
			}
			return _abcBuilder;
		}

		public function loadProxyClasses(applicationDomain:ApplicationDomain = null):void {
			applicationDomain = (applicationDomain != null) ? applicationDomain : ApplicationDomain.currentDomain;
			_abcBuilder.addEventListener(Event.COMPLETE, redispatch);
			_abcBuilder.addEventListener(IOErrorEvent.IO_ERROR, redispatch);
			_abcBuilder.addEventListener(IOErrorEvent.VERIFY_ERROR, redispatch);
			_abcBuilder.buildAndLoad(applicationDomain);
		}

		public function createProxy(clazz:Class, constructorArgs:Array = null):Object {
			return null;
		}

		protected function redispatch(event:Event):void {
			_abcBuilder.removeEventListener(Event.COMPLETE, redispatch);
			_abcBuilder.removeEventListener(IOErrorEvent.IO_ERROR, redispatch);
			_abcBuilder.removeEventListener(IOErrorEvent.VERIFY_ERROR, redispatch);
			dispatchEvent(event);
		}

		protected function buildProxy(classProxyInfo:ClassProxyInfo, applicationDomain:ApplicationDomain):void {
			var className:String = ClassUtils.getFullyQualifiedName(classProxyInfo.proxiedClass);
			var type:ByteCodeType = ByteCodeType.forName(className, applicationDomain);
			if (classProxyInfo.proxyAll == true) {
				reflectMembers(classProxyInfo, type, applicationDomain);
			}
			var classParts:Array = className.split(MultinameUtil.DOUBLE_COLON);
			var packageBuilder:IPackageBuilder = _abcBuilder.definePackage(classParts[0] + MultinameUtil.PERIOD + generateSuffix());
			var classBuilder:IClassBuilder = packageBuilder.defineClass(classParts[1], className);
			addInterceptorProperty(classBuilder);
			var memberInfo:MemberInfo;
			for each (memberInfo in classProxyInfo.methods) {
				proxyMethod(classBuilder, type, memberInfo);
			}
			for each (memberInfo in classProxyInfo.accessors) {
				proxyAccessor(classBuilder, type, memberInfo);
			}
			for each (memberInfo in classProxyInfo.properties) {
				proxyProperty(classBuilder, type, memberInfo);
			}
		}

		protected function addInterceptorProperty(classBuilder:IClassBuilder):void {

		}

		protected function reflectMembers(classProxyInfo:ClassProxyInfo, type:ByteCodeType, applicationDomain:ApplicationDomain):void {
			var isProtected:Boolean;
			var vsb:NamespaceKind;
			for each (var method:ByteCodeMethod in type.methods) {
				if ((method.isStatic) || (method.isFinal)) {
					continue;
				}
				vsb = method.visibility;
				isProtected = (vsb === NamespaceKind.PROTECTED_NAMESPACE);
				if (!isPublicOrProtected(vsb)) {
					return;
				}
				classProxyInfo.proxyMethod(method.name, method.namespaceURI, isProtected);
			}
			for each (var accessor:ByteCodeAccessor in type.accessors) {
				if ((accessor.isStatic) || (accessor.isFinal)) {
					continue;
				}
				vsb = accessor.visibility;
				isProtected = (vsb === NamespaceKind.PROTECTED_NAMESPACE);
				if (!isPublicOrProtected(vsb)) {
					return;
				}
				classProxyInfo.proxyAccessor(accessor.name, accessor.namespaceURI, isProtected);
			}
			for each (var variable:ByteCodeVariable in type.variables) {
				if ((variable.isStatic) || (variable.isFinal)) {
					continue;
				}
				vsb = variable.visibility;
				isProtected = (vsb === NamespaceKind.PROTECTED_NAMESPACE);
				if (!isPublicOrProtected(vsb)) {
					return;
				}
				classProxyInfo.proxyProperty(variable.name, variable.namespaceURI, isProtected);
			}
		}

		protected function isPublicOrProtected(vsb:NamespaceKind):Boolean {
			return ((vsb !== NamespaceKind.PACKAGE_NAMESPACE) && (vsb !== NamespaceKind.PROTECTED_NAMESPACE));
		}

		protected function proxyMethod(classBuilder:IClassBuilder, type:ByteCodeType, memberInfo:MemberInfo):void {
			var methodBuilder:IMethodBuilder = classBuilder.defineMethod(memberInfo.qName.localName, memberInfo.qName.uri);
			methodBuilder.isOverride = true;
			var method:ByteCodeMethod = type.getMethod(memberInfo.qName.localName, memberInfo.qName.uri) as ByteCodeMethod;
			if (method != null) {
				methodBuilder.returnType = method.returnType.fullName;
				for each (var arg:ByteCodeParameter in method.parameters) {
					methodBuilder.defineArgument(arg.type.fullName, arg.isOptional, arg.defaultValue);
				}
			}
			addMethodBody(methodBuilder);
		}

		protected function proxyAccessor(classBuilder:IClassBuilder, type:ByteCodeType, memberInfo:MemberInfo):void {
			var accessor:ByteCodeAccessor = type.getField(memberInfo.qName.localName, memberInfo.qName.uri) as ByteCodeAccessor;
			var accessorBuilder:IAccessorBuilder = classBuilder.defineAccessor(accessor.name, accessor.type.fullName, accessor.initializedValue);
			accessorBuilder.namespace = memberInfo.qName.uri;
			accessorBuilder.isOverride = true;
			accessorBuilder.access = accessor.access;
			addAccessorBodies(accessorBuilder);
		}

		protected function proxyProperty(classBuilder:IClassBuilder, type:ByteCodeType, memberInfo:MemberInfo):void {
			var variable:ByteCodeVariable = type.getField(memberInfo.qName.localName, memberInfo.qName.uri) as ByteCodeVariable;
			var accessorBuilder:IAccessorBuilder = classBuilder.defineAccessor(variable.name, variable.type.fullName, variable.initializedValue);
			accessorBuilder.namespace = memberInfo.qName.uri;
			accessorBuilder.isOverride = true;
			accessorBuilder.access = AccessorAccess.READ_WRITE;
			addPropertyAccessorBodies(accessorBuilder);
		}

		protected function addMethodBody(methodBuilder:IMethodBuilder):void {
			//TODO: generate the darn opcodes...
		}

		protected function addAccessorBodies(accessorBuilder:IAccessorBuilder):void {
			//TODO: generate the darn opcodes...
		}

		protected function addPropertyAccessorBodies(accessorBuilder:IAccessorBuilder):void {
			//TODO: generate the darn opcodes...
		}

	}
}