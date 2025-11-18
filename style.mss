@water: #41418d;//#151F34 ;// dark blue for all water: lake, rivers and streams.
@forest: #A1C672; //#add19e;
@farmland: #a6d0a6;//#eef0d5;//#69B05A;

Map {
  background-color:white;// @water;
}

// country bondaries are commented out due to well-known circumstances
/*
#admin-110m[zoom<=5],#admin-10m[zoom>5] {
  //polygon-fill: #fff;
  ::outline {
    line-color: #000;
    
    [zoom<=0],[zoom=1]{ line-width: 0.5;}
    [zoom=2],[zoom=3]{ line-width: 0.75;}
    [zoom=4]{ line-width: 1;}
    [zoom>=5]{line-width: 1.4;}
    line-join: round;
    line-dasharray: 2, 8, 4;  
  } 
} 
*/

#srhr_{  
  raster-opacity:1;
  raster-comp-op:multiply; 
  raster-scaling: lanczos;     
}


#ocean_lz{//[zoom<=7] 
   polygon-fill:@water;
}

#rivers_gen {
  line-color: @water;
  line-cap: round;
  line-join: round;
  line-width: 0;

  // Style for high zoom levels
  [zoom=6],[zoom=7],[zoom=8]{
	[width >    0]  { line-width: 0.5; }
	[width >  500]  { line-width: 1; }
	[width > 1000]  { line-width: 2; }
	[width > 2000]  { line-width: 3; }
  }
  // Style for mid zoom levels
  [zoom=4],[zoom=5]{
	[width > 500] { line-width:  0.5; }
	[width > 1000] { line-width: 1.0; }
	[width > 2000] { line-width: 1.5; }
  }
  // Style for low zoom levels - only show major rivers
  [zoom=2],[zoom=3]{
    [width >  500] { line-width: 0.5; }
    [width > 1000] { line-width: 1.0; }
  }
  [zoom=0],[zoom=1] {
    [width > 1000] { line-width: 0.5; }
  }
}



#places_{    
      [zoom=3][rank<=1],
      [zoom=4][rank<=3],
      [zoom=5][rank<=12], 
      [zoom=6][rank<=48],
      [zoom=7][rank<=120],
      [zoom=8][rank<=500]{
        shield-file: url('symbols/place/place-4.svg');
        shield-text-dx: 0;
        shield-text-dy: 0;
        shield-name: '[name]';
        shield-face-name: @book-fonts;
        shield-fill: @placenames;
        shield-size: 12;
        [zoom>=5][admin_leve='2']{shield-size: 14;}
       
              
    
        shield-wrap-width: 30; // 2.7 em
        shield-line-spacing: -1.65; // -0.15 em
        //shield-margin: 7.7; // 0.7 em
        shield-halo-fill: @standard-halo-fill;
        shield-halo-radius: @standard-halo-radius * 1.5;
        //shield-placement-type: simple;
        //shield-placements: 'S,N,E,W';
      }
}

#peaks[ele>800]{
  [zoom=1][score>3000000],
  [zoom=2][score>3000000],
  [zoom=3][score>1500000],
  [zoom=4][score> 600000],
  [zoom=5][score> 300000],
  [zoom>=6][score>150000]
  {
    
    [natural = 'peak'] {
      marker-file: url('symbols/natural/peak.svg');
      //marker-fill: @landform-color;
      marker-fill: #d40000;
      marker-clip: false;
    }

    [natural = 'volcano'] {
      marker-file: url('symbols/natural/peak.svg');
      marker-fill: #d40000;
      marker-clip: false;
    }

    [natural = 'saddle'] { 
      marker-file: url('symbols/natural/saddle.svg');
      marker-fill: @landform-color;
      marker-clip: false;
    }

    [natural = 'mountain_pass'] {
      marker-file: url('symbols/natural/saddle.svg');
      marker-fill: @transportation-icon;
      marker-clip: false;
    }
    

    [natural = 'peak'],
    [natural = 'volcano'],
    [natural = 'saddle'],
    [natural = 'mountain_pass'] {
      ::name{
        text-name: "[name]";
        text-size:  @standard-font-size;
        text-wrap-width: @standard-wrap-width;
        text-line-spacing: @standard-line-spacing-size;
        text-fill: darken(@landform-color, 30%);
        [natural = 'volcano'] { text-fill: #d40000; }
        [natural = 'mountain_pass'] { text-fill: @transportation-text; }
        text-dy: 7;
        text-face-name: @standard-font;
        text-halo-radius: @standard-halo-radius*2;
        text-halo-fill: @standard-halo-fill;}
      
      ::elevation1{
        text-name: "[ele]";
        text-size: @standard-font-size - 1;
        text-wrap-width: @standard-wrap-width;
        text-line-spacing: @standard-line-spacing-size;
        text-fill: darken(@landform-color, 30%);
        text-dy: -7;
        text-face-name: @standard-font;
        text-halo-radius: @standard-halo-radius*1.5;
        text-halo-fill: @standard-halo-fill;
        
        
        }
    }
  }
  
}
