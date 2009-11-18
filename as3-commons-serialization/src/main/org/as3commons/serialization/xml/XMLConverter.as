package org.as3commons.serialization.xml
{
	import flash.net.getClassByAlias;
	
	import org.as3commons.lang.Priority;
	import org.as3commons.serialization.xml.converters.basic.*;
	import org.as3commons.serialization.xml.converters.extended.ByteArrayConverter;
	import org.as3commons.serialization.xml.core.*;
	
	public class XMLConverter
	{
		//identifier prepended to class alias identifier prevent any possible conflict with AMF types registered with same name as XML node
		public static const X2A:String="X2A_";
		
		/**
		 * 
		 * @param nodeName Name of XML node. For example, for <book/> node, use "book". Case sensitive.
		 * @param type Class to map XML values to. Be sure to register Aliases for all child types.
		 * 
		 */		
		public static function register(nodeName:String,type:Class):void{
			flash.net.registerClassAlias(X2A+nodeName,type);
		}
		
		public static function getClassByAlias(alias:String):Class{		
			
			try {
				return flash.net.getClassByAlias( X2A+alias);
			} catch (e:Error){
				//TODO: Remove try/catch
			}
			
			return null;
		}
		
		public function XMLConverter()
		{	
			
			//Register native type converters
			ConverterRegistery.registerConverter(ArrayConverter,"Array",Priority.MEDIUM);
			ConverterRegistery.registerConverter(BooleanConverter,"Boolean",Priority.MEDIUM);
			ConverterRegistery.registerConverter(IntConverter,"int",Priority.MEDIUM);
			ConverterRegistery.registerConverter(NumberConverter,"Number",Priority.MEDIUM);
			ConverterRegistery.registerConverter(StringConverter,"String",Priority.MEDIUM);
			ConverterRegistery.registerConverter(UintConverter,"uint",Priority.MEDIUM);
			
			//Register reflective converters
			ConverterRegistery.registerConverter(ReflectionConverter,"*",Priority.LOW);
			
			//Register extended types
			ConverterRegistery.registerConverter(ByteArrayConverter,"flash.utils.ByteArray",Priority.MEDIUM);
			
		}
		
		public function fromXML(xml:XML,returnType:Class=null):*{		
			return XMLToAS.objectFromXML(xml,xml,returnType);		
		}
		
		public function toXML(obj:Object):XML{			
			return ASToXML.xmlFromObject(obj);
		}
		
		public function arrayToXML(array:Array,nodeName:String):XML{
			return ASToXML.xmlFromArray(array,nodeName);
		}
		
		public function alias(nodeName:String,type:Class):void{
			XMLConverter.register(nodeName,type);
		}	

	}
}