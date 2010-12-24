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

	import org.as3commons.bytecode.abc.LNamespace;
	import org.as3commons.bytecode.abc.Multiname;
	import org.as3commons.bytecode.abc.MultinameL;
	import org.as3commons.bytecode.abc.NamespaceSet;
	import org.as3commons.bytecode.abc.Op;
	import org.as3commons.bytecode.abc.QualifiedName;
	import org.as3commons.bytecode.abc.RuntimeQualifiedName;
	import org.as3commons.bytecode.abc.SlotOrConstantTrait;
	import org.as3commons.bytecode.abc.enum.BuiltIns;
	import org.as3commons.bytecode.abc.enum.MultinameKind;
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.abc.enum.Opcode;
	import org.as3commons.bytecode.as3commons_bytecode_proxy;
	import org.as3commons.bytecode.emit.IAbcBuilder;
	import org.as3commons.bytecode.emit.IAccessorBuilder;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.emit.ICtorBuilder;
	import org.as3commons.bytecode.emit.IMethodBuilder;
	import org.as3commons.bytecode.emit.IPackageBuilder;
	import org.as3commons.bytecode.emit.IPropertyBuilder;
	import org.as3commons.bytecode.emit.enum.MemberVisibility;
	import org.as3commons.bytecode.emit.impl.AbcBuilder;
	import org.as3commons.bytecode.emit.impl.MethodBuilder;
	import org.as3commons.bytecode.interception.BasicMethodInvocationInterceptor;
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptor;
	import org.as3commons.bytecode.proxy.error.ProxyError;
	import org.as3commons.bytecode.reflect.ByteCodeAccessor;
	import org.as3commons.bytecode.reflect.ByteCodeMethod;
	import org.as3commons.bytecode.reflect.ByteCodeParameter;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.util.MultinameUtil;
	import org.as3commons.lang.Assert;
	import org.as3commons.lang.ClassUtils;
	import org.as3commons.lang.StringUtils;
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.AccessorAccess;
	import org.as3commons.reflect.Method;

	/**
	 * Dispatched when the proxy factory has finished loading the SWF/ABC bytecode in the Flash Player/AVM.
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type="flash.events.Event")]
	/**
	 * Dispatched when the proxy factory has encountered an IO related error.
	 * @eventType flash.events.IOErrorEvent.IO_ERROR
	 */
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	/**
	 * Dispatched when the proxy factory has encountered a SWF verification error.
	 * @eventType flash.events.IOErrorEvent.VERIFY_ERROR
	 */
	[Event(name="verifyError", type="flash.events.IOErrorEvent")]
	/**
	 *
	 * @author Roland Zwaga
	 */
	public class ProxyFactory extends EventDispatcher implements IProxyFactory {

		//used namespaces
		use namespace as3commons_bytecode_proxy;

		//private static constants
		private static const CHARACTERS:String = "abcdefghijklmnopqrstuvwxys";
		private static const INTERCEPTOR_PROPERTYNAME:String = "methodInvocationInterceptor";
		private static const NS_FILENAME_SUFFIX:String = '.as$666';
		private static const MULTINAME_NAME:String = "intercept";
		private static const AS3COMMONSBYTECODEPROXY:String = "as3commons_bytecode_proxy";
		private static const ORGAS3COMMONSBYTECODE:String = "org.as3commons.bytecode";
		private static const CONSTRUCTOR:String = "constructor";

		//private variables
		private var _classProxyLookup:Dictionary;
		private var _abcBuilder:IAbcBuilder;
		private var _domains:Dictionary;
		private var _namespaceQualifiedName:QualifiedName = new QualifiedName("Namespace", LNamespace.PUBLIC, MultinameKind.QNAME);
		private var _arrayQualifiedName:QualifiedName = new QualifiedName("Array", LNamespace.PUBLIC, MultinameKind.QNAME);
		private var _invocationKindQualifiedName:QualifiedName = new QualifiedName("InvocationKind", new LNamespace(NamespaceKind.PACKAGE_NAMESPACE, "org.as3commons.bytecode.interception"), MultinameKind.QNAME);
		private var _interceptorRTQName:RuntimeQualifiedName = new RuntimeQualifiedName("methodInvocationInterceptor", MultinameKind.RTQNAME);
		private var _interceptQName:QualifiedName = new QualifiedName("intercept", new LNamespace(NamespaceKind.NAMESPACE, "org.as3commons.bytecode.interception:IMethodInvocationInterceptor"));
		private var _methodInvocationInterceptorFunction:Function;
		private var _ConstructorKindQName:QualifiedName = new QualifiedName("CONSTRUCTOR", LNamespace.PUBLIC);
		private var _MethodKindQName:QualifiedName = new QualifiedName("METHOD", LNamespace.PUBLIC);
		private var _GetterKindQName:QualifiedName = new QualifiedName("GETTER", LNamespace.PUBLIC);
		private var _SetterKindQName:QualifiedName = new QualifiedName("SETTER", LNamespace.PUBLIC);
		private var _qnameQname:QualifiedName = new QualifiedName("QName", LNamespace.PUBLIC);

		public function get methodInvocationInterceptorFunction():Function {
			return _methodInvocationInterceptorFunction;
		}

		public function set methodInvocationInterceptorFunction(value:Function):void {
			_methodInvocationInterceptorFunction = value;
		}

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
			_classProxyLookup = new Dictionary();
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
			methodInvocationInterceptorClass = (methodInvocationInterceptorClass != null) ? methodInvocationInterceptorClass : BasicMethodInvocationInterceptor;
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
					var proxyInfo:ProxyInfo = buildProxy(info, domain);
					_classProxyLookup[info.proxiedClass] = proxyInfo;
					proxyInfo.methodInvocationInterceptorClass = info.methodInvocationInterceptorClass;
				}
			}
			_domains = new Dictionary();
			return _abcBuilder;
		}

		public function loadProxyClasses(applicationDomain:ApplicationDomain = null):void {
			applicationDomain = (applicationDomain != null) ? applicationDomain : ApplicationDomain.currentDomain;
			for (var cls:* in _classProxyLookup) {
				ProxyInfo(_classProxyLookup[cls]).applicationDomain = applicationDomain;
			}
			_abcBuilder.addEventListener(Event.COMPLETE, redispatch);
			_abcBuilder.addEventListener(IOErrorEvent.IO_ERROR, redispatch);
			_abcBuilder.addEventListener(IOErrorEvent.VERIFY_ERROR, redispatch);
			_abcBuilder.buildAndLoad(applicationDomain);
		}

		public function createProxy(clazz:Class, constructorArgs:Array = null):Object {
			var proxyInfo:ProxyInfo = _classProxyLookup[clazz] as ProxyInfo;
			if (proxyInfo != null) {
				var cls:Class = proxyInfo.applicationDomain.getDefinition(proxyInfo.proxyClassName) as Class;
				var interceptorInstance:IMethodInvocationInterceptor;
				if (_methodInvocationInterceptorFunction == null) {
					interceptorInstance = new proxyInfo.methodInvocationInterceptorClass();
				} else {
					interceptorInstance = IMethodInvocationInterceptor(_methodInvocationInterceptorFunction(clazz, constructorArgs, proxyInfo.methodInvocationInterceptorClass));
				}
				constructorArgs = (constructorArgs != null) ? [interceptorInstance].concat(constructorArgs) : [interceptorInstance];
				return ClassUtils.newInstance(cls, constructorArgs);
			}
			return null;
		}

		protected function redispatch(event:Event):void {
			_abcBuilder.removeEventListener(Event.COMPLETE, redispatch);
			_abcBuilder.removeEventListener(IOErrorEvent.IO_ERROR, redispatch);
			_abcBuilder.removeEventListener(IOErrorEvent.VERIFY_ERROR, redispatch);
			dispatchEvent(event);
		}

		protected function buildProxy(classProxyInfo:ClassProxyInfo, applicationDomain:ApplicationDomain):ProxyInfo {
			var className:String = ClassUtils.getFullyQualifiedName(classProxyInfo.proxiedClass);
			var type:ByteCodeType = ByteCodeType.forName(className.replace(MultinameUtil.DOUBLE_COLON, MultinameUtil.PERIOD), applicationDomain);
			if (type.isFinal) {
				throw new ProxyError(ProxyError.FINAL_CLASS_ERROR, className);
			}
			var classParts:Array = className.split(MultinameUtil.DOUBLE_COLON);
			var packageName:String = classParts[0] + MultinameUtil.PERIOD + generateSuffix();
			var packageBuilder:IPackageBuilder = _abcBuilder.definePackage(packageName);
			var classBuilder:IClassBuilder = packageBuilder.defineClass(classParts[1], className);
			classBuilder.isDynamic = classProxyInfo.makeDynamic;
			classBuilder.isFinal = true;
			var proxyClassName:String = packageName + MultinameUtil.SINGLE_COLON + classParts[1];
			var nsMultiname:Multiname = createMultiname(proxyClassName, classParts.join(MultinameUtil.SINGLE_COLON), type.extendsClasses);
			var bytecodeQname:QualifiedName = addInterceptorProperty(classBuilder);
			var ctorBuilder:ICtorBuilder = addConstructor(classBuilder, type, classProxyInfo, nsMultiname);
			addConstructorBody(ctorBuilder, bytecodeQname, nsMultiname);
			var accessorBuilder:IAccessorBuilder;
			if ((classProxyInfo.proxyAll == true) && (classProxyInfo.onlyProxyConstructor == false)) {
				reflectMembers(classProxyInfo, type, applicationDomain);
			}
			var memberInfo:MemberInfo;
			for each (memberInfo in classProxyInfo.methods) {
				var methodBuilder:IMethodBuilder = proxyMethod(classBuilder, type, memberInfo);
				addMethodBody(methodBuilder, nsMultiname, bytecodeQname);
			}
			for each (memberInfo in classProxyInfo.accessors) {
				accessorBuilder = proxyAccessor(classBuilder, type, memberInfo, nsMultiname, bytecodeQname);
			}
			return new ProxyInfo(proxyClassName.split(MultinameUtil.SINGLE_COLON).join(MultinameUtil.PERIOD));
		}

		protected function createMultiname(generatedClassName:String, proxiedClassName:String, extendedClasses:Array):Multiname {
			var classNameParts:Array = generatedClassName.split(MultinameUtil.SINGLE_COLON);
			var className:String = String(classNameParts[1]);
			var nsa:Array = [];
			nsa[nsa.length] = new LNamespace(NamespaceKind.PRIVATE_NAMESPACE, generatedClassName);
			nsa[nsa.length] = LNamespace.PUBLIC;
			nsa[nsa.length] = new LNamespace(NamespaceKind.PRIVATE_NAMESPACE, className + NS_FILENAME_SUFFIX);
			nsa[nsa.length] = new LNamespace(NamespaceKind.PACKAGE_NAMESPACE, String(classNameParts[0]));
			nsa[nsa.length] = new LNamespace(NamespaceKind.PACKAGE_INTERNAL_NAMESPACE, String(classNameParts[0]));
			nsa[nsa.length] = LNamespace.BUILTIN;
			nsa[nsa.length] = new LNamespace(NamespaceKind.PROTECTED_NAMESPACE, generatedClassName);
			nsa[nsa.length] = new LNamespace(NamespaceKind.STATIC_PROTECTED_NAMESPACE, generatedClassName);
			nsa[nsa.length] = new LNamespace(NamespaceKind.STATIC_PROTECTED_NAMESPACE, proxiedClassName);
			for each (var name:String in extendedClasses) {
				nsa[nsa.length] = new LNamespace(NamespaceKind.STATIC_PROTECTED_NAMESPACE, name);
			}
			//nsa[nsa.length] = new LNamespace(NamespaceKind.STATIC_PROTECTED_NAMESPACE, BuiltIns.OBJECT.name);
			var nss:NamespaceSet = new NamespaceSet(nsa);
			return new Multiname(MULTINAME_NAME, nss, MultinameKind.MULTINAME);
		}

		protected function addInterceptorProperty(classBuilder:IClassBuilder):QualifiedName {
			Assert.notNull(classBuilder, "classBuilder argument must not be null");
			var className:String = ClassUtils.getFullyQualifiedName(IMethodInvocationInterceptor);
			var propertyBuilder:IPropertyBuilder = classBuilder.defineProperty(INTERCEPTOR_PROPERTYNAME, className);
			propertyBuilder.namespace = as3commons_bytecode_proxy;
			return new QualifiedName(AS3COMMONSBYTECODEPROXY, new LNamespace(NamespaceKind.PACKAGE_NAMESPACE, ORGAS3COMMONSBYTECODE));
		}

		protected function addConstructor(classBuilder:IClassBuilder, type:ByteCodeType, classProxyInfo:ClassProxyInfo, nsMultiname:Multiname):ICtorBuilder {
			var ctorBuilder:ICtorBuilder = classBuilder.defineConstructor();
			var interceptorClassName:String = ClassUtils.getFullyQualifiedName(classProxyInfo.methodInvocationInterceptorClass);
			ctorBuilder.defineArgument(interceptorClassName);
			for each (var param:ByteCodeParameter in type.constructor.parameters) {
				ctorBuilder.defineArgument(param.type.fullName, param.isOptional, param.defaultValue);
			}
			return ctorBuilder;
		}

		protected function addConstructorBody(ctorBuilder:ICtorBuilder, bytecodeQname:QualifiedName, multiName:Multiname):void {
			var len:int = ctorBuilder.arguments.length;
			var paramLocal:int = len;
			ctorBuilder.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.pushscope) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.findpropstrict, [_interceptorRTQName]) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.getlocal_1) //
				.addOpcode(Opcode.setproperty, [_interceptorRTQName]);
			if (len > 1) {
				for (var i:int = 1; i < len; ++i) {
					ctorBuilder.addOpcode(Opcode.getlocal, [(i + 1)]);
				}
				ctorBuilder.addOpcode(Opcode.newarray, [len - 1]) //
					.addOpcode(Opcode.coerce, [_arrayQualifiedName]) //
					.addOpcode(Opcode.setlocal, [paramLocal]) //
					.addOpcode(Opcode.getlocal_1) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.findpropstrict, [_invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [_invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [_ConstructorKindQName]) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.getlocal, [paramLocal]) //
					.addOpcode(Opcode.callproperty, [multiName, 4]) //
					.addOpcode(Opcode.pop) //
					.addOpcode(Opcode.getlocal_0);
				for (i = 0; i < len - 1; ++i) {
					ctorBuilder.addOpcode(Opcode.getlocal, [paramLocal]) //
						.addOpcode(Opcode.pushbyte, [i]) //
						.addOpcode(Opcode.getproperty, [new MultinameL(multiName.namespaceSet)]) //
				}
				ctorBuilder.addOpcode(Opcode.constructsuper, [len - 1]) //
					.addOpcode(Opcode.returnvoid);
			} else {
				ctorBuilder.addOpcode(Opcode.getlocal_1) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.findpropstrict, [_invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [_invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [_ConstructorKindQName]) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.callproperty, [_interceptQName, 4]) //
					.addOpcode(Opcode.pop) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.constructsuper, [0]) //
					.addOpcode(Opcode.returnvoid); //
			}
		}

		protected function reflectMembers(classProxyInfo:ClassProxyInfo, type:ByteCodeType, applicationDomain:ApplicationDomain):void {
			Assert.notNull(classProxyInfo, "classProxyInfo argument must not be null");
			Assert.notNull(type, "type argument must not be null");
			Assert.notNull(applicationDomain, "applicationDomain argument must not be null");
			var isProtected:Boolean;
			var vsb:NamespaceKind;
			for each (var method:Method in type.methods) {
				var byteCodeMethod:ByteCodeMethod = method as ByteCodeMethod;
				if (byteCodeMethod != null) {
					if ((byteCodeMethod.isStatic) || (byteCodeMethod.isFinal)) {
						continue;
					}
					vsb = byteCodeMethod.visibility;
					isProtected = (vsb === NamespaceKind.PROTECTED_NAMESPACE);
					if (!isPublicOrProtectedOrCustom(vsb)) {
						return;
					}
					classProxyInfo.proxyMethod(byteCodeMethod.name, byteCodeMethod.namespaceURI);
				}
			}
			for each (var accessor:Accessor in type.accessors) {
				var byteCodeAccessor:ByteCodeAccessor = accessor as ByteCodeAccessor;
				if (byteCodeAccessor != null) {
					if ((byteCodeAccessor.isStatic) || (byteCodeAccessor.isFinal)) {
						continue;
					}
					vsb = byteCodeAccessor.visibility;
					isProtected = (vsb === NamespaceKind.PROTECTED_NAMESPACE);
					if (!isPublicOrProtectedOrCustom(vsb)) {
						return;
					}
					classProxyInfo.proxyAccessor(byteCodeAccessor.name, byteCodeAccessor.namespaceURI);
				}
			}
		}

		protected function isPublicOrProtectedOrCustom(namespaceKind:NamespaceKind):Boolean {
			Assert.notNull(namespaceKind, "namespaceKind argument must not be null");
			return ((namespaceKind === NamespaceKind.PACKAGE_NAMESPACE) || (namespaceKind === NamespaceKind.PROTECTED_NAMESPACE) || (namespaceKind === NamespaceKind.NAMESPACE));
		}

		protected function proxyMethod(classBuilder:IClassBuilder, type:ByteCodeType, memberInfo:MemberInfo):IMethodBuilder {
			Assert.notNull(classBuilder, "classBuilder argument must not be null");
			Assert.notNull(type, "type argument must not be null");
			Assert.notNull(memberInfo, "memberInfo argument must not be null");
			var methodBuilder:IMethodBuilder = classBuilder.defineMethod(memberInfo.qName.localName, memberInfo.qName.uri);
			methodBuilder.isOverride = true;
			var method:ByteCodeMethod = type.getMethod(memberInfo.qName.localName, memberInfo.qName.uri) as ByteCodeMethod;
			if (method.isFinal) {
				throw new ProxyError(ProxyError.FINAL_METHOD_ERROR, method.name);
			}
			methodBuilder.visibility = (method.visibility === NamespaceKind.PACKAGE_NAMESPACE) ? MemberVisibility.PUBLIC : MemberVisibility.PROTECTED;
			if (method != null) {
				methodBuilder.returnType = method.returnType.fullName;
				for each (var arg:ByteCodeParameter in method.parameters) {
					methodBuilder.defineArgument(arg.type.fullName, arg.isOptional, arg.defaultValue);
				}
			}
			return methodBuilder;
		}

		protected function proxyAccessor(classBuilder:IClassBuilder, type:ByteCodeType, memberInfo:MemberInfo, multiName:Multiname, bytecodeQname:QualifiedName):IAccessorBuilder {
			Assert.notNull(classBuilder, "classBuilder argument must not be null");
			Assert.notNull(type, "type argument must not be null");
			Assert.notNull(memberInfo, "memberInfo argument must not be null");
			var accessor:ByteCodeAccessor = type.getField(memberInfo.qName.localName, memberInfo.qName.uri) as ByteCodeAccessor;
			if (accessor.isFinal) {
				throw new ProxyError(ProxyError.FINAL_ACCESSOR_ERROR, accessor.name);
			}
			var accessorBuilder:IAccessorBuilder = classBuilder.defineAccessor(accessor.name, accessor.type.fullName, accessor.initializedValue);
			accessorBuilder.namespace = memberInfo.qName.uri;
			accessorBuilder.isOverride = true;
			accessorBuilder.access = accessor.access;
			accessorBuilder.createPrivateProperty = false;
			accessorBuilder.createGetterFunction = function(accessorBuilder:IAccessorBuilder, trait:SlotOrConstantTrait):IMethodBuilder {
				return createGetter(accessorBuilder, multiName, bytecodeQname);
			}
			accessorBuilder.createSetterFunction = function(accessorBuilder:IAccessorBuilder, trait:SlotOrConstantTrait):IMethodBuilder {
				return createSetter(accessorBuilder, multiName, bytecodeQname);
			}
			return accessorBuilder;
		}

		protected function addMethodBody(methodBuilder:IMethodBuilder, multiName:Multiname, bytecodeQname:QualifiedName):void {
			Assert.notNull(methodBuilder, "methodBuilder argument must not be null");
			var len:int = methodBuilder.arguments.length;
			var methodQName:QualifiedName = createMethodQName(methodBuilder);
			methodBuilder.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.pushscope) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.findpropstrict, [_interceptorRTQName]) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_interceptorRTQName]) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.findpropstrict, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_MethodKindQName]) //
				.addOpcode(Opcode.findpropstrict, [_qnameQname]) //
				.addOpcode(Opcode.pushstring, [StringUtils.hasText(methodBuilder.namespace) ? methodBuilder.namespace : ""]) //
				.addOpcode(Opcode.pushstring, [methodBuilder.name]) //
				.addOpcode(Opcode.constructprop, [_qnameQname, 2]) //
			if (len > 0) {
				for (var i:int = 0; i < len; ++i) {
					methodBuilder.addOpcode(Opcode.getlocal, [(i + 1)]);
				}
				methodBuilder.addOpcode(Opcode.newarray, [len - 1]) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.getsuper, [methodQName]) //
					.addOpcode(Opcode.callproperty, [multiName, 5]);
			} else {
				methodBuilder.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.getsuper, [methodQName]) //
					.addOpcode(Opcode.callproperty, [multiName, 5]);
			}
			if (methodBuilder.returnType == BuiltIns.VOID.fullName) {
				methodBuilder.addOpcode(Opcode.pop).addOpcode(Opcode.returnvoid);
			} else {
				methodBuilder.addOpcode(Opcode.returnvalue);
			}
		}

		protected function createMethod(accessorBuilder:IAccessorBuilder):IMethodBuilder {
			var mb:MethodBuilder = new MethodBuilder();
			mb.name = accessorBuilder.name;
			mb.namespace = accessorBuilder.namespace;
			mb.isFinal = accessorBuilder.isFinal;
			mb.isOverride = accessorBuilder.isOverride;
			mb.packageName = accessorBuilder.packageName;
			return mb;
		}

		protected function createGetter(accessorBuilder:IAccessorBuilder, multiName:Multiname, bytecodeQname:QualifiedName):IMethodBuilder {
			var mb:IMethodBuilder = createMethod(accessorBuilder);
			mb.isOverride = true;
			mb.returnType = accessorBuilder.type;
			addGetterBody(mb, multiName, bytecodeQname);
			return mb;
		}

		protected function createSetter(accessorBuilder:IAccessorBuilder, multiName:Multiname, bytecodeQname:QualifiedName):IMethodBuilder {
			var mb:IMethodBuilder = createMethod(accessorBuilder);
			mb.isOverride = true;
			mb.returnType = BuiltIns.VOID.fullName;
			mb.defineArgument(accessorBuilder.type);
			addSetterBody(mb, accessorBuilder, multiName, bytecodeQname);
			return mb;
		}

		protected function addGetterBody(methodBuilder:IMethodBuilder, multiName:Multiname, bytecodeQname:QualifiedName):void {
			Assert.notNull(methodBuilder, "methodBuilder argument must not be null");
			var methodQName:QualifiedName = createMethodQName(methodBuilder);
			methodBuilder.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.pushscope) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.findpropstrict, [_interceptorRTQName]) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_interceptorRTQName]) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.findpropstrict, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_GetterKindQName]) //
				.addOpcode(Opcode.findpropstrict, [_qnameQname]) //
				.addOpcode(Opcode.pushstring, [StringUtils.hasText(methodBuilder.namespace) ? methodBuilder.namespace : ""]) //
				.addOpcode(Opcode.pushstring, [methodBuilder.name]) //
				.addOpcode(Opcode.constructprop, [_qnameQname, 2]) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.getsuper, [createMethodQName(methodBuilder)]) //
				.addOpcode(Opcode.newarray, [1]) //
				.addOpcode(Opcode.callproperty, [multiName, 4]) //
				.addOpcode(Opcode.returnvalue);
		}

		protected function addSetterBody(methodBuilder:IMethodBuilder, accessorBuilder:IAccessorBuilder, multiName:Multiname, bytecodeQname:QualifiedName):void {
			Assert.notNull(methodBuilder, "methodBuilder argument must not be null");
			var methodQName:QualifiedName = createMethodQName(methodBuilder);
			var argLen:int = 1;
			var superSetter:QualifiedName = createMethodQName(methodBuilder);
			methodBuilder.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.pushscope) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.findpropstrict, [_interceptorRTQName]) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [_namespaceQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_interceptorRTQName]) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.findpropstrict, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_invocationKindQualifiedName]) //
				.addOpcode(Opcode.getproperty, [_SetterKindQName]) //
				.addOpcode(Opcode.findpropstrict, [_qnameQname]) //
				.addOpcode(Opcode.pushstring, [StringUtils.hasText(methodBuilder.namespace) ? methodBuilder.namespace : ""]) //
				.addOpcode(Opcode.pushstring, [methodBuilder.name]) //
				.addOpcode(Opcode.constructprop, [_qnameQname, 2]) //
				.addOpcode(Opcode.getlocal_1);
			if (accessorBuilder.access === AccessorAccess.READ_WRITE) {
				methodBuilder.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.getsuper, [superSetter]);
				argLen = 2;
			}
			methodBuilder.addOpcode(Opcode.newarray, [argLen]) //
				.addOpcode(Opcode.callproperty, [multiName, 4]) //
				.addOpcode(Opcode.setsuper, [superSetter]) //
				.addOpcode(Opcode.returnvoid);
		}

		protected function createMethodQName(methodBuilder:IMethodBuilder):QualifiedName {
			var ns:LNamespace = (methodBuilder.visibility == MemberVisibility.PUBLIC) ? LNamespace.PUBLIC : new LNamespace(NamespaceKind.PROTECTED_NAMESPACE, "");
			return new QualifiedName(methodBuilder.name, ns);
		}

	}
}