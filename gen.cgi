#!/usr/bin/perl -w

use strict;
use CGI;

my $q = new CGI;

print
  $q->header,
  $q->start_html("Catan board generator"),
  $q->h1("Settlers of Catan board generator"),
  ;

my($xsize,$ysize,$numIslands,$numTiles,
   $pClump, $pTypeClump, $drawSize) = (
				       $q->param('xsize'), $q->param('ysize'),
				       $q->param('numIslands'), $q->param('numTiles'),
				       $q->param('pClump'), $q->param('pTypeClump'),
				       $q->param('drawSize'),
				      );

my(%numLand);
($numLand{WOOD}, $numLand{WHEAT}, $numLand{SHEEP},
 $numLand{ORE}, $numLand{BRICK}) = (
				    $q->param('numWood'), $q->param('numWheat'),
				    $q->param('numSheep'), $q->param('numOre'),
				    $q->param('numBrick'),
				   );

my $gotPost = 0;
if (defined($xsize) && defined($ysize)) {
  ($xsize<1) && ($xsize=1);
  ($xsize>40) && ($xsize=40);
  ($ysize<1) && ($ysize=1);
  ($xsize>40) && ($xsize=40);
  
  ($numIslands<1) && ($numIslands=1);
  ($numTiles<1) && ($numTiles=1);
  
  ($pClump<0) && ($pClump=0);
  ($pClump>1) && ($pClump=1);

  ($pTypeClump<0) && ($pTypeClump=0);
  ($pTypeClump>1) && ($pTypeClump=1);
  
  ($drawSize<5) && ($drawSize=5);
  ($drawSize>100) && ($drawSize=100);
  $gotPost = 1;
} else {
  $xsize = 10;
  $ysize = 10;
  $numIslands = 1;
  $numTiles = 20;
  $pClump = 0.9;
  $pTypeClump = 0.9;
  $drawSize = 30;
  for my $k (keys %numLand) {
    $numLand{$k} = 4;
  }
}

print
  $q->hr, $q->br, "\n",
  $q->start_form, "\n",
  "<TABLE BORDER=1>\n",
  "<TR><TD>X-size of board ", $q->textfield(-name => 'xsize',
					    -value => $xsize,
					    -size => 5,
					   ), $q->br,"\n",
  "<TD>Y-size of board ", $q->textfield(-name => 'ysize',
					    -value => $ysize,
					    -size => 5,
					   ), $q->br,"\n",
  "<TD>Draw size ", $q->textfield(-name => 'drawSize',
				      -value => $drawSize,
				      -size => 5,
				     ), $q->br,"\n",
  "<TR><TD>Number of Islands ", $q->textfield(-name => 'numIslands',
					      -value => $numIslands,
					      -size => 5,
					     ), $q->br,"\n",
  "<TD>Number of Tiles ", $q->textfield(-name => 'numTiles',
					    -value => $numTiles,
					    -size => 5,
					   ), $q->br, "\n",
  "<TR>\n",
  "<TR><TD>Land Clumpiness (0-1) ", $q->textfield(-name => 'pClump',
						  -value => $pClump,
						  -size => 5,
						 ), $q->br,"\n",
  "<TD>Land Type Clumpiness (0-1) ", $q->textfield(-name => 'pTypeClump',
						   -value => $pTypeClump,
						   -size => 5,
						  ), $q->br,"\n",
  "<TR>\n",
  "<TR><TD>Number of Wood ", $q->textfield(-name => 'numWood',
					   -value => $numLand{WOOD},
					   -size => 5,
					  ), $q->br, "\n",
  "<TD>Number of Wheat ", $q->textfield(-name => 'numWheat',
					    -value => $numLand{WHEAT},
					    -size => 5,
					   ), $q->br, "\n",
  "<TR><TD>Number of Sheep ", $q->textfield(-name => 'numSheep',
					    -value => $numLand{SHEEP},
					    -size => 5,
					   ), $q->br, "\n",
  "<TD>Number of Ore ", $q->textfield(-name => 'numOre',
					  -value => $numLand{ORE},
					  -size => 5,
					 ), $q->br, "\n",
  "<TR><TD>Number of Brick ", $q->textfield(-name => 'numBrick',
					    -value => $numLand{BRICK},
					    -size => 5,
					   ), $q->br, "\n",
  "<TR><TD>",$q->submit("Generate"), $q->br,"\n",
  "</TABLE>\n",
  $q->hr, "\n",
  ;

if ($gotPost) {
  my $tmpFile = "board$$.png";

  use Board::Generate qw(@landTypes);
  use Board::Draw;
  my @land;
  for my $k (keys %numLand) {
    my $num = $numLand{$k};
    ($num<0) && ($num=0);
    push(@land, ($k) x $num);
  }
  
  my $b = new Board::Generate(
			      XSIZE => $xsize,
			      YSIZE => $ysize,
			      DEBUG => 0,
			      NUMISLANDS => $numIslands,
			      NUMTILES => $numTiles,
			      PCLUMP => $pClump,
			      PTYPECLUMP => $pTypeClump,
			      LAND   => [@land],
			     );

  $b->autoArrange();
  
  $b->draw(new Board::Draw(SIZE => $drawSize, TOFILE => $tmpFile));  
  
  my $expProd = $b->expectedProduction();
  print "<TABLE BORDER=1>\n";
  print "<TH COLSPAN=2>Expected production after 36 rolls</TH>\n";
  for my $k (sort keys %$expProd) {
    print "<TR><TD>",ucfirst(lc($k));
    printf "<TD>%d",$expProd->{$k}*36;
    print "</TR>\n";
  }
  print $q->end_table,"\n";

  print "<IMG SRC=disp.cgi?$$>\n";
}

print $q->end_html,"\n";
