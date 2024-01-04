//==missing standards
//@book-fonts: "Arial Regular";//"Arial Regular";

@standard-halo-radius: 1;
@standard-halo-fill: rgba(255,255,255,0.6);

@standard-font-size: 10;
@standard-wrap-width: 30; // 3 em
@standard-line-spacing-size: -1.5; // -0.15 em
@standard-font: @book-fonts;

@landform-color: #d08f55;
@transportation-icon: #0092da;
@transportation-text: #0066ff;

//============ 
@placenames: #222;
@placenames-light: #777777;
@country-labels: darken(@admin-boundaries-narrow, 10%);
@state-labels: desaturate(@admin-boundaries-narrow, 5%);
@county-labels: darken(@admin-boundaries-wide, 5%);


#places{
  [zoom=3][rank<=1],
  [zoom=4][rank<=3],
  [zoom=5][rank<=12], 
  [zoom=6][rank<=48],
  [zoom=7][rank<=120],
  [zoom=8][rank<=500]{
    //Capitals of the states/countries
    [admin_leve='2']{
      shield-file: url('symbols/place/place-capital-6.svg');
      shield-text-dx: 6;
      shield-text-dy: 6;
      shield-name: '[name]';
      shield-face-name: @book-fonts;
      shield-fill: @placenames;
      shield-size: 13;
      shield-wrap-width: 60; // 2.7 em
      shield-line-spacing: -0.6; // -0.15 em
      shield-margin: 8.4; // 0.7 em
      shield-halo-fill: @standard-halo-fill;
      shield-halo-radius: @standard-halo-radius * 1.5;
      shield-placement-type: simple;
      shield-placements: 'S,N,E,W';
      //[dir = 1] {
      //  shield-placements: 'N,S,E,W';
      //}
      shield-unlock-image: true;

      [zoom >= 5] {
        shield-wrap-width: 45; // 4.1 em
        shield-line-spacing: -1.1; // -0.10 em
      }
      [zoom >= 6] {
        shield-size: 13;
        shield-wrap-width: 60; // 5.0 em
        shield-line-spacing: -0.6; // -0.05 em
        shield-margin: 8.4; // 0.7 em
      }
      [zoom >= 7] {
        shield-file: url('symbols/place/place-capital-8.svg');
        shield-text-dx: 7;
        shield-text-dy: 7;
      }
    }
  
    //big cities, 1M+
    [admin_leve!='2'][population>=1000000] {
      shield-file: url('symbols/place/place-4.svg');
      shield-text-dx: 4;
      shield-text-dy: 4;
      shield-name: '[name]';
      shield-face-name: @book-fonts;
      shield-fill: @placenames;
      shield-size: 12;
      shield-wrap-width: 30; // 2.7 em
      shield-line-spacing: -1.65; // -0.15 em
      shield-margin: 7.7; // 0.7 em
      shield-halo-fill: @standard-halo-fill;
      shield-halo-radius: @standard-halo-radius * 1.5;
      shield-placement-type: simple;
      shield-placements: 'S,N,E,W';
      //[dir = 1] {
      //  shield-placements: 'N,S,E,W';
      //}
      shield-unlock-image: true;
     
    }

    //cities 100K-1M   
    [admin_leve!='2'][population>=100000][population<1000000] {
      shield-file: url('symbols/place/place-4.svg');
      shield-text-dx: 4;
      shield-text-dy: 4;
      shield-name: "[name]";
      shield-size: 11;
      shield-fill: @placenames;
      shield-face-name: @book-fonts;
      shield-halo-fill: @standard-halo-fill;
      shield-halo-radius: @standard-halo-radius * 1.5;
      shield-wrap-width: 30; // 3.0 em
      shield-line-spacing: -1.5; // -0.15 em
      shield-margin: 7.0; // 0.7 em
      shield-placement-type: simple;
      shield-placements: 'S,N,E,W';
      //[dir = 1] {
      //  shield-placements: 'N,S,E,W';
      //}
      shield-unlock-image: true;
    }
    
    //Smaller cities and towns below 100K population  
    [admin_leve!='2'][population<100000] {
      shield-file: url('symbols/place/place-4.svg');
      shield-text-dx: 4;
      shield-text-dy: 4;
      shield-name: "[name]";
      shield-size: 10;
      shield-fill: @placenames;
      shield-face-name: @book-fonts;
      shield-halo-fill: @standard-halo-fill;
      shield-halo-radius: @standard-halo-radius * 1.5;
      shield-wrap-width: 30; // 3.0 em
      shield-line-spacing: -1.5; // -0.15 em
      shield-margin: 7.0; // 0.7 em
      shield-placement-type: simple;
      shield-placements: 'S,N,E,W';
      //[dir = 1] {
      //  shield-placements: 'N,S,E,W';
      //}
      shield-unlock-image: true;
    }
  }
}