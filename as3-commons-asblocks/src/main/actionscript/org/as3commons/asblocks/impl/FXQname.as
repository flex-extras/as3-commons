////////////////////////////////////////////////////////////////////////////////
// Copyright 2011 Michael Schmalle - Teoti Graphix, LLC
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
// 
// Author: Michael Schmalle, Principal Architect
// mschmalle at teotigraphix dot com
////////////////////////////////////////////////////////////////////////////////

package org.as3commons.asblocks.impl
{

import flash.filesystem.File;
import org.as3commons.asblocks.dom.ASQName;

/**
 * @author Michael Schmalle
 * @copyright Teoti Graphix, LLC
 * @productversion 1.0
 */
public class FXQname extends ASQName
{
	private var classPath:File;

	public function getClassPath():File
	{
		return classPath;
	}

	public function setClassPath(classPath:File):void
	{
		this.classPath = classPath;
	}
	
	public function FXQname(qname:String, classPath:File = null)
	{
		super(qname);
		
		this.classPath = classPath;
	}

}
}