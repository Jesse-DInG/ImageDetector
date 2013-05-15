package com.dxj.ImageDetector.core
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	/**
	 * 基于LBP的图像相似度检测 
	 * @author DInG
	 * 
	 */
	public class ImageDetector
	{
		private static var _instance:ImageDetector;
		private var _checkList:Dictionary;
		private var _hasList:Boolean;
		public static function get instance():ImageDetector
		{
			if(!_instance)
			{
				_instance = new ImageDetector();
			}
			return _instance;
		}
		private var _mapping:Vector.<int>;
		public function setup(samples:int,url:String=""):void
		{
			_mapping = initMapping(samples);
			if(url.length > 0)
			{
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE,__complete);
				loader.load(new URLRequest(url));
			}
		}
		
		protected function __complete(event:Event):void
		{
			// TODO Auto-generated method stub
			var loader:URLLoader = event.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE,__complete);
			var xml:XML = XML(loader.data);
			var items:XMLList = xml..item;
			if(items.length()>0)
			{
				_checkList = new Dictionary();
				for(var i:int = 0;i<items.length();i++)
				{
					if(!_checkList[int(items[i].@num)])
					{
						_checkList[int(items[i].@num)] = [];
					}
					_checkList[int(items[i].@num)].push(str2vector(items[i].@values));
				}
			}
			_hasList = true;
		}
		
		public function get checkList():Dictionary
		{
			
			return _hasList?_checkList:null;
		}
		
		public function check(data:Vector.<int>,list:Array):String
		{
			if(!_hasList)return "";
			var dic:Dictionary = new Dictionary();
			for each(var i:int in list)
			{
				var p:Number=0;
				for each(var temp:Vector.<int> in _checkList[i])
				{
					var p0:Number =	chitest(data,temp,1);
					if(1-p0 < 0.0001)
					{
						p=p0;
						break;
					}
					else if(p<p0)
						p=p0;
				}
				dic[i]=p;
			}
			var maxNum:int = -1;
			var maxP:Number = 0;
			for (var key:String in dic)
			{
				if(dic[key] > maxP)
				{
					maxP = dic[key];
					maxNum = int(key);
				}
			}
			list.splice(list.indexOf(maxNum),1);
//			trace("num:" + maxNum + "   p:" + maxP);
			return maxNum == 10?".":String(maxNum);
		}
		
		private function str2vector(str:String):Vector.<int>
		{
			var arr:Array = str.split(",");
			var res:Vector.<int> = new Vector.<int>();
			for each(var num:int in arr)
			{
				res.push(num);
			}
			return res;
		}
		
		/**
		 * 检测两张图片的相似度 
		 * @param bm1
		 * @param bm2
		 * @param r
		 * @return 
		 * 
		 */
		public function test(bm1:BitmapData,bm2:BitmapData,r:int):Number
		{
			if(bm1.width != bm2.width || bm1.height != bm2.height)
			{
				return -1;
			}
			var sum:int = getSum(bm1,r);
			var lbp1:Vector.<int> = getLBP(bm1,r,_mapping);
			var lbp2:Vector.<int> = getLBP(bm2,r,_mapping);
//			trace(lbp1);
//			trace(lbp2);
			return chitest(lbp1,lbp2,sum);
		}
		/**
		 * 求特点采样点数所需的码表 
		 * @param samples 码表长度
		 * @return 
		 * 
		 */
		private function initMapping(samples:int):Vector.<int>
		{
			var length:int = 1<<samples;//码表长度
			var mapping:Vector.<int> = new Vector.<int>();
			var newMax:int = samples*(samples-1)+3;
			var index:int = 0;
			var i:int;
			var j:int;
			var k:int;
			for(i = 0;i<length;i++)
			{
				var tp1:int=i>>(samples-1)&1;
				//左移一位后，给第一位置
				if(tp1>0)
					j=i<<1|1;
				else
					j=j<<i;
				var tp2:int=i^j;
				var sum:int = 0;
				for(k=0;k<samples;k++)
				{
					sum+=tp2>>k&1;
				}
				if(sum<=2)
				{
					mapping.push(index);
					index++;
				}
				else
				{
					mapping.push(newMax-1);
				}
			}
			return mapping;
		}
		
		public function getLBP(bm:BitmapData,r:int = 1,mapping:Vector.<int> = null):Vector.<int>
		{
			var i:int;
			var j:int;
			var lv:int;
			var rows:int = bm.height;
			var cols:int = bm.width;
			var result:Vector.<int> = new Vector.<int>();
			
			var map:Vector.<int> = mapping?mapping:_mapping;
			
			for(i=0;i<59;i++)
			{
				result.push(0);
			}
			
			for(i=r;i<rows-r;i++)
			{
				for(j=r;j<cols-r;j++)
				{
					lv = 0;
					var value:int = bm.getPixel(i,j);
					lv+=(bm.getPixel(i-r,j-r)>value?1:0)<<0;
					lv+=(bm.getPixel(i-r,j)>value?1:0)<<1;
					lv+=(bm.getPixel(i-r,j+r)>value?1:0)<<2;
					lv+=(bm.getPixel(i,j-r)>value?1:0)<<3;
					lv+=(bm.getPixel(i,j+r)>value?1:0)<<4;
					lv+=(bm.getPixel(i+r,j-r)>value?1:0)<<5;
					lv+=(bm.getPixel(i+r,j)>value?1:0)<<6;
					lv+=(bm.getPixel(i+r,j+r)>value?1:0)<<7;
					result[map[lv]]++;
				}
			}
			return result;
		}
		
		/**
		 * 进行卡方检验 
		 * @param lbp1
		 * @param lbp2
		 * @param pixSum
		 * @return 
		 * 
		 */
		public function chitest(lbp1:Vector.<int>,lbp2:Vector.<int>,pixSum:int):Number
		{
			var result:Number = 0;
			var length:int = Math.min(lbp1.length,lbp2.length);
			for(var i:int = 0;i<length;i++)
			{
				if(lbp1[i]+lbp2[i]==0)
					continue;
				result +=(lbp1[i]-lbp2[i])*(lbp1[i]-lbp2[i])/(lbp1[i]+lbp2[i]);
			}
			return 1-result/pixSum;
		}
		
		/**
		 * 获取 样本点总数
		 * @param bm
		 * @return 
		 * 
		 */
		private function getSum(bm:BitmapData,r:int):int
		{
			return (bm.width-r)*(bm.height-r);
		}
	}
}