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
package org.as3commons.bytecode.proxy.impl {
	import org.as3commons.bytecode.abc.Multiname;
	import org.as3commons.bytecode.abc.MultinameL;
	import org.as3commons.bytecode.abc.QualifiedName;
	import org.as3commons.bytecode.abc.enum.Opcode;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.emit.ICtorBuilder;
	import org.as3commons.bytecode.proxy.IClassProxyInfo;
	import org.as3commons.bytecode.reflect.ByteCodeParameter;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.logging.ILogger;
	import org.as3commons.logging.LoggerFactory;

	public class ConstructorProxyFactory extends AbstractMethodBodyFactory {

		private static const LOGGER:ILogger = LoggerFactory.getClassLogger(ConstructorProxyFactory);

		public function ConstructorProxyFactory() {
			super();
		}

		/**
		 * Defines a constructor on the specified <code>IClassBuilder</code> with the same arguments as the proxied class
		 * plus one extra argument that represents the <code>IMethodInvocationInterceptor</code> which will be injected into
		 * the proxy instance.
		 * @param classBuilder The specified <code>IClassBuilder</code>.
		 * @param type The <code>ByteCodeType</code> instance used to retrieve the constructor argument information.
		 * @param classProxyInfo The <code>ClassProxyInfo</code> that specified the <code>IMethodInvocationInterceptor</code> class.
		 * @return A <code>ICtorBuilder</code> instance that represents the generated constructor.
		 */
		public function addConstructor(classBuilder:IClassBuilder, type:ByteCodeType, classProxyInfo:IClassProxyInfo):ICtorBuilder {
			var ctorBuilder:ICtorBuilder = classBuilder.defineConstructor();
			//var interceptorClassName:String = ClassUtils.getFullyQualifiedName(IMethodInvocationInterceptor);
			//ctorBuilder.defineArgument(interceptorClassName);
			for each (var param:ByteCodeParameter in type.constructor.parameters) {
				ctorBuilder.defineArgument(param.type.fullName, param.isOptional, param.defaultValue);
			}
			return ctorBuilder;
		}

		/**
		 * Creates the necessary opcodes that represent the constructor's method body. It assigns the first parameter (the <code>IMethodInvocationInterceptor</code> instance)
		 * to the <code>methodInvocationInterceptor</code> property generated by the <code>addInterceptorProperty()</code> method, then it invokes the <code>intercept()</code>
		 * method on the <code>IMethodInvocationInterceptor</code> instance and passes the current instance, <code>InvocationKind.CONSTRUCTOR</code>, null and an <code>Array</code>
		 * that holds the constructor arguments to it.
		 * <p>The actionscript for such a constructor would look like this:</p>
		 * <listing version="3.0">
		 * public function ProxySubClass(interceptor:IMethodInvocationInterceptor, target:IEventDispatcher = null, somethingElse:Object = null) {
		 * 	as3commons_bytecode_proxy::methodInvocationInterceptor = interceptor;
		 * 	var params:Array = [target, somethingElse];
		 * 	interceptor.intercept(this, InvocationKind.CONSTRUCTOR, null, params);
		 * 	super(params[0], params[1]);
		 * }
		 * </listing>
		 * <p>This allows the constructor arguments to be potentially changed by an <code>IInterceptor</code> instance.</p>
		 * @param ctorBuilder The specified <code>ICtorBuilder</code> instance that will receieve the generated method body.
		 * @param bytecodeQname The <code>QualifiedName</code> instance which is used for the <code>Opcode.findpropstrict</code> and <code>Opcode.getproperty</code> to retrieve the <code>as3commons_bytecode_proxy</code> namespace.
		 * @param multiName The <code>Multiname</code> instance used as the parameter for the <code>Opcode.callproperty</code> opcode.
		 */
		public function addConstructorBody(ctorBuilder:ICtorBuilder, bytecodeQname:QualifiedName, multiName:Multiname):void {
			var len:int = ctorBuilder.arguments.length;
			var paramLocal:int = len + 1;
			var eventLocal:int = paramLocal++;
			ctorBuilder.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.pushscope) //
				.addOpcode(Opcode.findpropstrict, [proxyEventQName]) //
				.addOpcode(Opcode.findpropstrict, [proxyEventQName]) //
				.addOpcode(Opcode.getproperty, [proxyEventQName]) //
				.addOpcode(Opcode.getproperty, [proxyEventTypeQName]) //
				.addOpcode(Opcode.getlocal_0) //
				.addOpcode(Opcode.constructprop, [proxyEventQName, 2]) //
				.addOpcode(Opcode.coerce, [proxyEventQName]) //
				.addOpcode(Opcode.setlocal, [eventLocal]) //
				.addOpcode(Opcode.findpropstrict, [proxyFactoryQName]) //
				.addOpcode(Opcode.getproperty, [proxyFactoryQName]) //
				.addOpcode(Opcode.getproperty, [proxyCreationDispatcherQName]) //
				.addOpcode(Opcode.getlocal, [eventLocal]) //
				.addOpcode(Opcode.callproperty, [dispatchEventQName, 1]) //
				.addOpcode(Opcode.pop) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [namespaceQualifiedName]) //
				.addOpcode(Opcode.findpropstrict, [interceptorRTQName]) //
				.addOpcode(Opcode.findpropstrict, [bytecodeQname]) //
				.addOpcode(Opcode.getproperty, [bytecodeQname]) //
				.addOpcode(Opcode.coerce, [namespaceQualifiedName]) //
				.addOpcode(Opcode.getlocal, [eventLocal]) //
				.addOpcode(Opcode.getproperty, [interceptorQName]) //
				.addOpcode(Opcode.setproperty, [interceptorRTQName]);
			if (len > 0) {
				for (var i:int = 0; i < len; ++i) {
					var idx:int = i + 1;
					switch (idx) {
						case 1:
							ctorBuilder.addOpcode(Opcode.getlocal_1);
							break;
						case 2:
							ctorBuilder.addOpcode(Opcode.getlocal_2);
							break;
						case 3:
							ctorBuilder.addOpcode(Opcode.getlocal_3);
							break;
						default:
							ctorBuilder.addOpcode(Opcode.getlocal, [idx]);
							break;
					}
				}
				ctorBuilder.addOpcode(Opcode.newarray, [len]) //
					.addOpcode(Opcode.coerce, [arrayQualifiedName]) //
					.addOpcode(Opcode.setlocal, [paramLocal]) //
					.addOpcode(Opcode.getlocal, [eventLocal]) //
					.addOpcode(Opcode.getproperty, [interceptorQName]) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.findpropstrict, [invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [ConstructorKindQName]) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.getlocal, [paramLocal]) //
					.addOpcode(Opcode.callproperty, [interceptQName, 4]) //
					.addOpcode(Opcode.pop) //
					.addOpcode(Opcode.getlocal_0);
				for (i = 0; i < len; ++i) {
					ctorBuilder.addOpcode(Opcode.getlocal, [paramLocal]) //
						.addOpcode(Opcode.pushbyte, [i]) //
						.addOpcode(Opcode.getproperty, [new MultinameL(multiName.namespaceSet)]) //
				}
			} else {
				ctorBuilder.addOpcode(Opcode.getlocal_1) //
					.addOpcode(Opcode.getproperty, [interceptorQName]) //
					.addOpcode(Opcode.getlocal_0) //
					.addOpcode(Opcode.findpropstrict, [invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [invocationKindQualifiedName]) //
					.addOpcode(Opcode.getproperty, [ConstructorKindQName]) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.pushnull) //
					.addOpcode(Opcode.callproperty, [interceptQName, 4]) //
					.addOpcode(Opcode.pop) //
					.addOpcode(Opcode.getlocal_0); //
			}
			ctorBuilder.addOpcode(Opcode.constructsuper, [len]) //
				.addOpcode(Opcode.returnvoid);
			LOGGER.debug("Constructor generated");
		}

	}
}