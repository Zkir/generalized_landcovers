@water: #41418d;//#151F34 ;// dark blue for all water: lake, rivers and streams.
@forest: #A1C672; //#add19e;
@farmland: #a6d0a6;//#eef0d5;//#69B05A;

Map {
  background-color:white;// @water;
}


#land_country_boundaries {
  //polygon-fill: #fff;
  ::outline {
    line-color: #000;
    line-width: 1.4;
    line-join: round;
    line-dasharray: 2, 8, 4; 
  } 
} 

#srhr_{ 
  raster-opacity:1;
  raster-comp-op:multiply; 
  raster-scaling: lanczos;     
}


#landcovers_aggr[zoom<=8][feature!='water'],#landcovers[zoom>8]
{
  line-color: black;
  line-width: 0;
  polygon-fill:black;
  
  
  /*=======================================================================================
    == Water ==
      water is not present in the generalized geometry, but it present in normal landuses
      so we keep it here for the sake of consistency.  
    ======================================================================================= */

  [feature='water'] {
    polygon-fill:@water; 
  }

  /*=======================================================================================
    == Barren, no vegetation  ==
    ======================================================================================= */

  [feature='glacier'],[feature='naled'],[feature='ice']{polygon-fill:#BBF;}  

  [feature='quarry']{polygon-fill:#F0F050;}  

  [feature='bare_rock'],[feature='shingle'],[feature='scree'],[feature='blockfield']{
    polygon-fill:#777;
    polygon-pattern-file: url('patterns/rock_overlay.png');
  } 

  [feature='mud']{
    polygon-fill:#777;
  }
  
  [feature='quarry']{
    //we do not really know what it is. Sand, stone, gravel etc.
    polygon-fill:#DD7;
    polygon-pattern-file: url('patterns/quarry.png');  
  }

  [feature='sand'],[feature='beach']{
    //beach is considered to be sand by default, 
    //but we need to transform it into something based on surface=* maybe. 
    polygon-fill:yellow;
    polygon-pattern-file: url('patterns/beach.png');
  }  

  /*=======================================================================================
    == Sparce vegetation, deserts ==
    ======================================================================================= */


  //transparency will not help, for the obvious reason :( 
  //Notes: fell and tundra are mere synonyms. 
  //all those are not landcovers, but natural zones. 
  [feature='tundra'],[feature='fell']{
    polygon-fill:#afa;
    polygon-opacity:0.5;
  } 

  [feature='arctic_desert']{
    polygon-fill:#aaf;
    polygon-opacity:0.5;
  }    

  [feature='desert']{
    polygon-fill:yellow;
    polygon-opacity:0.5;
    polygon-pattern-file: url('patterns/beach.png');
  } 

  
  /*=======================================================================================
    == Grass ==
    ======================================================================================= */
  [feature='grassland'],[feature='moor']{
    polygon-fill:#90B070;
  }  

  [feature='meadow']{
    polygon-fill:@farmland;
  }
  
  /*=======================================================================================
    == Shrubs  ==
    ======================================================================================= */

  [feature='scrub']{
    polygon-fill:#90C090;
    polygon-pattern-file: url('patterns/scrub.png')
  }    
  //this is dwarf-shrub habitat
  [feature='heath']
    {polygon-fill:#90C090;}    

  /*=======================================================================================
    == special -- Wetlands  ==
    ======================================================================================= */
  [feature='wetland']{ 
    polygon-fill:#70A040;
    polygon-pattern-file: url('patterns/wetland.png');
  }

  [feature='peat_cutting']{
    polygon-fill:#70A040;
    polygon-pattern-file: url('patterns/peat_cutting1.png');
  }


  /*=======================================================================================
    == special - Argiculture  ==
    ======================================================================================= */
  //farmland signifies any type of argiculture (annual crops), 'paddy' is just a rice field
  [feature='farmland'],[feature='paddy']{
    polygon-fill:@farmland;
  }

  [feature='greenhouse_horticulture']{polygon-fill:@farmland;} 

  [feature='farmyard']{polygon-fill:@farmland;} 
   
  [feature='vineyard']{
    polygon-fill: #f0e050;
    polygon-pattern-file: url('patterns/vineyard.png')
  }

  [feature='orchard']{polygon-fill:#9ab676;}

  /*=======================================================================================
    == Trees  ==
    ======================================================================================= */
  [feature='wood']{
     polygon-fill:@forest;
     //polygon-pattern-file: url('patterns/leaftype_unknown.png');
  } 

  [feature='logging']{polygon-fill:#598D4A;}  

  /*=======================================================================================
    == Strange Tags :)    ==
    ==  Those are occuring widely, so we need to do something with them in the future.
    ======================================================================================= */

  /*  
  wellsite  //it's rather industrial=wellsite
  oil_field 
  winter_sports 
  forestry */ 

  /*=======================================================================================
    == Urban/build up ==
    ======================================================================================= */

  //residential,industrial etc (after transformation)
  [feature='built_up']{
    polygon-fill:#F05050;
  }
  [feature='landfill']{
    polygon-fill:#F06050;
  }

  [feature='allotments']{
    polygon-fill:#B0E0A0;
    polygon-pattern-file: url('patterns/allotments.png');
  }  

  
}

#waterbodies[zoom<=7]{
    [feature='water']{polygon-fill:@water;}
}

 #ocean{//[zoom<=7] 
   polygon-fill:@water;
}


#places{    
      [zoom=3][rank<=1],
      [zoom=4][rank<=3],
      [zoom=5][rank<=12], 
      [zoom=6][rank<=48],
      [zoom=7][rank<=120]{
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
