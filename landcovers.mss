/*
Main contents of this style.
Combined naturals and landuses which imply landcovers
*/

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

  [feature='glacier']{polygon-fill:#BBF;}  

  [feature='bare_rock'],[feature='shingle'],[feature='scree'],[feature='blockfield']{
    polygon-fill:#A0A0A0;
    polygon-pattern-file: url('patterns/rock_overlay.png');
  } 

  [feature='mud']{
    polygon-fill:#777;
    polygon-pattern-file: url('patterns/wetland.png');
  }
  
  [feature='bare_earth']{
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
  [feature='salt_pond']{
    polygon-fill:#e0e0b0;
    polygon-pattern-file: url('patterns/salt_pond.png') 
  }  

  /*=======================================================================================
    == Sparce vegetation, deserts ==
    ======================================================================================= */
  //Notes: fell and tundra are mere synonyms. 
  //all those are not landcovers, but natural zones. 
  [feature='tundra'],[feature='fell']{
    polygon-fill:#afa;
  } 

  [feature='arctic_desert']{
    polygon-fill:#aaf;
  }    

  [feature='desert']{
    polygon-fill:yellow;
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
  [feature='heath']{
    polygon-fill:#90C090;}    

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
  
  [feature='plant_nursery']{
    polygon-fill:#9ab676;
    polygon-pattern-file: url('patterns/plant_nursery.svg');
  }
  
  /*=======================================================================================
    == Trees  ==
    ======================================================================================= */
  [feature='wood']{
     polygon-fill:@forest;
     [zoom>=7]{ polygon-pattern-file: url('patterns/leaftype_unknown.png');}
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
  
  /*=======================================================================================
    == Special:  ==
    ======================================================================================= */
  
  // cemetery, railway and observatory are a special type of man-changed landscapes, 
  // I am not brave enaugh yet to join them with other urban/buid up.
  [feature='cemetery']{
    polygon-fill: #908090;
    polygon-pattern-file: url('patterns/grave_yard_generic.svg'); 
  }
  
  [feature='railway']{
     polygon-fill:#806060;
  }  
  
  [feature='observatory']{
     polygon-fill:#806060;
  }  
  
  
  
}

#waterbodies[zoom<=8]{
    [feature='water']{polygon-fill:@water;}
}
