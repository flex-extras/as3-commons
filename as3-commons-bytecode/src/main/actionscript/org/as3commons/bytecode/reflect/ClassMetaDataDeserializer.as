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
package org.as3commons.bytecode.reflect {
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	import org.as3commons.bytecode.abc.BaseMultiname;
	import org.as3commons.bytecode.abc.ConstantPool;
	import org.as3commons.bytecode.abc.QualifiedName;
	import org.as3commons.bytecode.abc.enum.ClassConstant;
	import org.as3commons.bytecode.abc.enum.MethodFlag;
	import org.as3commons.bytecode.abc.enum.TraitAttributes;
	import org.as3commons.bytecode.abc.enum.TraitKind;
	import org.as3commons.bytecode.util.AbcDeserializerBase;
	import org.as3commons.reflect.MetaData;
	import org.as3commons.reflect.as3commons_reflect;

	public class ClassMetaDataDeserializer extends ReflectionDeserializer {

		public function ClassMetaDataDeserializer() {
			super();
		}

		override public function readMethods(input:ByteArray, constantPool:ConstantPool, applicationDomain:ApplicationDomain):Array {
			var methodCount:int = readU30();

			for (var methodIndex:int = 0; methodIndex < methodCount; methodIndex++) {
				var paramCount:uint = readU30(); //paramcount;

				readU30(); //returnTypeQName

				for (var argumentIndex:int = 0; argumentIndex < paramCount; argumentIndex++) {
					readU30(); //paramQName
				}

				readU30(); //methodNameIndex
				var flags:uint = readU8();
				if (MethodFlag.flagPresent(flags, MethodFlag.HAS_OPTIONAL) == true) {
					var optionInfoCount:int = readU30();
					for (var optionInfoIndex:int = 0; optionInfoIndex < optionInfoCount; optionInfoIndex++) {
						readU30(); //valueIndexInConstantconstantPool
						readU8(); //optionalValueKind
					}
				}

				if (MethodFlag.flagPresent(flags, MethodFlag.HAS_PARAM_NAMES) == true) {
					for (var nameIndex:uint = 0; nameIndex < paramCount; nameIndex++) {
						readU30(); //paramName
					}
				}
			}
			return null;
		}

		override public function readTypes(input:ByteArray, constantPool:ConstantPool, applicationDomain:ApplicationDomain, methods:Array, metadatas:Array, typeCache:ByteCodeTypeCache):void {
			var classCount:int = readU30();
			var classNames:Array = [];
			for (var instanceIndex:int = 0; instanceIndex < classCount; instanceIndex++) {
				var classMultiname:BaseMultiname = constantPool.multinamePool[readU30()];
				var qualifiedName:QualifiedName = convertToQualifiedName(classMultiname);
				classNames[classNames.length] = qualifiedName.fullName;

				readU30(); //superName
				var instanceInfoFlags:uint = readU8(); //instanceInfoFlags
				if (ClassConstant.PROTECTED_NAMESPACE.present(instanceInfoFlags)) {
					readU30(); //protectedNamespace
				}
				var interfaceCount:int = readU30();
				for (var interfaceIndex:int = 0; interfaceIndex < interfaceCount; interfaceIndex++) {
					readU30(); //BaseMultiname
				}
				readU30(); //constructorIndex
				gatherMetaData(classNames, constantPool, methods, metadatas, false, typeCache);
			}

			for (var classIndex:int = 0; classIndex < classCount; classIndex++) {
				// class_info  
				// { 
				//  u30 cinit 
				//  u30 trait_count 
				//  traits_info traits[trait_count] 
				// }
				var className:String = classNames[classIndex];
				readU30(); //StaticConstructor
				gatherMetaData(classNames, constantPool, methods, metadatas, true, typeCache);
			}

			var scriptCount:int = readU30();
			for (var scriptIndex:int = 0; scriptIndex < scriptCount; scriptIndex++) {
				readU30();
				gatherMetaData(classNames, constantPool, methods, metadatas, true, typeCache);
			}

		}

		public function gatherMetaData(classNames:Array, pool:ConstantPool, methodInfos:Array, metadata:Array, isStatic:Boolean, typeCache:ByteCodeTypeCache):void {
			var traitCount:int = readU30();
			for (var traitIndex:int = 0; traitIndex < traitCount; traitIndex++) {
				var className:String = null;
				// traits_info  
				// { 
				//  u30 name 
				//  u8  kind 
				//  u8  data[] 
				//  u30 metadata_count 
				//  u30 metadata[metadata_count] 
				// }
				readU30(); //traitName
				var traitKindValue:int = readU8();
				var traitKind:TraitKind = TraitKind.determineKind(traitKindValue);
				var vindex:uint = 0;
				switch (traitKind) {
					case TraitKind.SLOT:
						readU30();
						readU30(); //namedMultiname
						vindex = readU30();
						if (vindex != 0) {
							readU8(); //vkind
						}
						break;
					case TraitKind.CONST:
						// trait_slot 
						// { 
						//  u30 slot_id 
						//  u30 type_name 
						//  u30 vindex 
						//  u8  vkind  
						// }
						readU30();
						readU30(); //namedMultiname
						vindex = readU30();
						if (vindex != 0) {
							readU8(); //vkind
						}
						break;

					case TraitKind.METHOD:
					case TraitKind.FUNCTION:
						readU30(); //skip disp_id
						readU30(); //method
						break;
					case TraitKind.GETTER:
					case TraitKind.SETTER:
						// trait_method 
						// { 
						//  u30 disp_id 
						//  u30 method 
						// }
						readU30(); //skip disp_id
						readU30(); //accessorMethod
						break;

					case TraitKind.CLASS:
						// trait_class 
						// { 
						//  u30 slot_id 
						//  u30 classi 
						// }
						readU30();
						className = classNames[readU30()];
						break;
				}

				// (as listed at the top of this switch statement)
				// traits_info
				// {
				//  ...
				//  u30 metadata_count 
				//  u30 metadata[metadata_count]
				// }
				// AVM2 overview, page 29
				// "These fields are present only if ATTR_Metadata is present in the upper four bits of the kind field. 
				// The value of the metadata_count field is the number of entries in the metadata array. That array 
				// contains indices into the metadata array of the abcFile." 
				if (traitKindValue & (TraitAttributes.METADATA.bitMask << 4)) {
					addMetaData(metadata, className, typeCache);
				}
			}
		}

		private function addMetaData(metadata:Array, className:String, typeCache:ByteCodeTypeCache):void {
			var numberOfTraitMetadataItems:int = readU30();
			for (var traitMetadataIndex:int = 0; traitMetadataIndex < numberOfTraitMetadataItems; traitMetadataIndex++) {
				var md:MetaData = metadata[readU30()];
				if (className != null) {
					typeCache.as3commons_reflect::addToMetaDataCache(md.name, className);
				}
			}
		}

	}
}