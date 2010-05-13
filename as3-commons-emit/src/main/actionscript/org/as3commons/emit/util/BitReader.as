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
package org.as3commons.emit.util {

	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	public class BitReader {
		private var _input:IDataInput;

		private var _currentByte:uint;
		private var _bitIndex:uint = 8;

		private var _dataBuffer:ByteArray;

		public function BitReader(input:IDataInput) {
			if (input == null) {
				throw new ArgumentError("input must be specified");
			}

			this._input = input;
			this._dataBuffer = new ByteArray();
			this._dataBuffer.endian = input.endian;
		}

		private function ensureBits(numBits:uint):void {
			if (bitsAvailable < numBits) {
				throw new IllegalOperationError("Unexpected EOF");
			}

			if (_bitIndex == 8) {
				_currentByte = _input.readUnsignedByte();
				_bitIndex = 0;
			}
		}

		public function readUnsignedInteger(bits:uint):uint {
			var bitsRemaining:uint = bits;
			var outputValue:int = 0;

			while (bitsRemaining > 0) {
				ensureBits(bitsRemaining);

				var bitsToRead:uint = (bitsRemaining > (8 - _bitIndex)) ? 8 - _bitIndex : bitsRemaining;

				outputValue = (outputValue << bitsToRead) | (((_currentByte << _bitIndex) & 0xFF) >> (8 - bitsToRead));

				_bitIndex += bitsToRead;

				bitsRemaining -= bitsToRead;
			}

			return uint(outputValue);
		}

		public function readInteger(bits:uint):int {
			var bitsRemaining:uint = bits;
			var outputValue:int = 0;

			while (bitsRemaining > 0) {
				ensureBits(bitsRemaining);

				var bitsToRead:uint = (bitsRemaining > (8 - _bitIndex)) ? 8 - _bitIndex : bitsRemaining;

				outputValue = (outputValue << bitsToRead) | (((_currentByte << _bitIndex) & 0xFF) >> (8 - bitsToRead));

				_bitIndex += bitsToRead;

				bitsRemaining -= bitsToRead;
			}

			return outputValue;
		}

		public function get bitsAvailable():uint {
			return (_input.bytesAvailable * 8) + (8 - _bitIndex);
		}

		public function get endian():String {
			return _input.endian;
		}

		public function set endian(value:String):void {
			_input.endian = value;
			_dataBuffer.endian = value;
		}
	}
}