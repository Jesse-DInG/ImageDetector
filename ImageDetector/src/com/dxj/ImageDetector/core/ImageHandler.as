package com.dxj.ImageDetector.core
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;

	public class ImageHandler
	{
		
		public static function rolate(bm:BitmapData,alpha:Number):BitmapData
		{
			var sprite:Sprite = new Sprite();
			var length:int = Math.max(bm.width,bm.height);
			sprite.rotation = alpha;
			var m:Matrix = new Matrix();
			m.tx -= length*0.5;
			m.ty -= length*0.5;
			m.rotate(Math.PI/180*alpha);
			m.tx += length*0.75;
			m.ty += length*0.75;
//			m.tx = -length/2;
//			m.ty = -length/2;
			var res:BitmapData = new BitmapData(length*1.5,length*1.5);
			res.draw(bm,m,null,null,null,true);
			return res;
		}
	}
}