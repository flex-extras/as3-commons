/*
 * Copyright (c) 2007-2009-2010 the original author or authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package org.as3commons.emit.reflect {

	import flash.system.ApplicationDomain;

	import org.as3commons.emit.SWFConstant;
	import org.as3commons.emit.bytecode.QualifiedName;
	import org.as3commons.lang.Assert;
	import org.as3commons.reflect.Constant;
	import org.as3commons.reflect.Type;
	import org.as3commons.reflect.as3commons_reflect;

	public class EmitConstant extends Constant implements IEmitMember {

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------

		/**
		 * Constructor.
		 */
		public function EmitConstant(declaringType:EmitType, name:String, fullName:String, type:EmitType, visibility:uint, isStatic:Boolean, isOverride:Boolean, applicationDomain:ApplicationDomain, metaData:Array = null, ns:String = null) {
			super(name, type.name, declaringType.name, isStatic, applicationDomain);
			initEmitConstant(visibility, isOverride, declaringType, type, ns, fullName, name);
		}

		protected function initEmitConstant(visibility:uint, isOverride:Boolean, declaringType:EmitType, type:EmitType, ns:String, fullName:String, name:String):void {
			Assert.notNull(declaringType, "declaringType argument must not be null");
			Assert.notNull(type, "type argument must not be null");
			Assert.notNull(fullName, "fullName argument must not be null");
			Assert.notNull(name, "name argument must not be null");
			_visibility = visibility;
			as3commons_reflect::setIsOverride(isOverride);
			as3commons_reflect::setDeclaringType(declaringType);
			as3commons_reflect::setType(type);
			as3commons_reflect::setNamespaceURI(ns || SWFConstant.EMPTY_STRING);
			_qname = EmitReflectionUtils.getMemberQualifiedName(this);
			_fullName = (fullName || EmitReflectionUtils.getMemberFullName(declaringType.fullName, name, applicationDomain));
		}


		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------

		//----------------------------------
		//  declaringType
		//----------------------------------

		public function set declaringType(value:Type):void {
			as3commons_reflect::setDeclaringType(value);
		}

		//----------------------------------
		//  fullName
		//----------------------------------

		private var _fullName:String;

		public function get fullName():String {
			return _fullName;
		}

		public function set fullName(value:String):void {
			_fullName = value;
		}

		//----------------------------------
		//  isStatic
		//----------------------------------

		public function set isStatic(value:Boolean):void {
			as3commons_reflect::setIsStatic(value);
		}

		//----------------------------------
		//  name
		//----------------------------------

		public function set name(value:String):void {
			as3commons_reflect::setName(value);
		}

		//----------------------------------
		//  namespaceURI
		//----------------------------------

		public function set namespaceURI(value:String):void {
			as3commons_reflect::setNamespaceURI(value);
		}

		//----------------------------------
		//  type
		//----------------------------------

		public function set type(value:Type):void {
			as3commons_reflect::setType(value);
		}

		//----------------------------------
		//  visibility
		//----------------------------------

		private var _visibility:uint;

		public function get visibility():uint {
			return _visibility;
		}

		public function set visibility(value:uint):void {
			_visibility = value;
		}

		//----------------------------------
		//  qname
		//----------------------------------

		private var _qname:QualifiedName;

		public function get qname():QualifiedName {
			return _qname;
		}

		public function set qname(value:QualifiedName):void {
			_qname = value;
		}
	}
}