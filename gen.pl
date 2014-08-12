#!/usr/bin/perl -w

use Board::Generate qw(@landTypes);
use Board::Draw;
use strict;

my(@Options,$DEBUG,$xsize,$ysize,$drawSize,$toFile,
   $numIslands,$numTiles,$pClump,$pTypeClump);
my(%numLand);

setOptions();

my @land;
for my $k (keys %numLand) {
  my $num = $numLand{$k};
  ($num<0) && ($num=0);
  push(@land, ($k) x $num);
}
  
my $b = new Board::Generate(
			    XSIZE => $xsize,
			    YSIZE => $ysize,
			    DEBUG => $DEBUG,
			    NUMISLANDS => $numIslands,
			    NUMTILES => $numTiles,
			    PCLUMP => $pClump,
			    PTYPECLUMP => $pTypeClump,
			    LAND   => [@land],
			   );

$b->autoArrange();

$b->draw(new Board::Draw(SIZE => $drawSize, TOFILE => $toFile));


#----------------------------------------------------------------------
# option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
              {OPT=>"help",      VAR=>\&usage,       DESC=>"This help"},
	      {OPT=>"debug=i",   VAR=>\$DEBUG,  DEFAULT=>1,
	       DESC=>"Debug level"},
	      {OPT=>"xsize=i",   VAR=>\$xsize, DEFAULT=>10,
	       DESC=>"Size of board in x direction"},
	      {OPT=>"ysize=i",   VAR=>\$ysize, DEFAULT=>10,
	       DESC=>"Size of board in y direction"},
	      {OPT=>"drawSize=i",VAR=>\$drawSize, DEFAULT=>20,
	       DESC=>"Size to draw the board"},
	      {OPT=>"toFile=s",  VAR=>\$toFile, DEFAULT=>"screen",
	       DESC=>"File to write to ('screen' is a special case to display the board)"},
	      {OPT=>"numTiles=i",  VAR=>\$numTiles, DEFAULT=>20,
	       DESC=>"Number of land tiles"},
	      {OPT=>"numIslands=i",  VAR=>\$numIslands, DEFAULT=>1,
	       DESC=>"Number of islands"},
	      {OPT=>"pClump=f",  VAR=>\$pClump, DEFAULT=>1,
	       DESC=>"A 'probability' for the clumpiness of the land"},
	      {OPT=>"pTypeClump=f",  VAR=>\$pTypeClump, DEFAULT=>1,
	       DESC=>"A 'probability' for the clumpiness of land types"},
	      {OPT=>"numWood=i", VAR=>\$numLand{WOOD}, DEFAULT=> 4,
	       DESC=>"Number of tiles that are wood"},
	      {OPT=>"numWheat=i", VAR=>\$numLand{WHEAT}, DEFAULT=> 4,
	       DESC=>"Number of tiles that are wheat"},
	      {OPT=>"numSheep=i", VAR=>\$numLand{SHEEP}, DEFAULT=> 4,
	       DESC=>"Number of tiles that are sheep"},
	      {OPT=>"numOre=i", VAR=>\$numLand{ORE}, DEFAULT=> 4,
	       DESC=>"Number of tiles that are ore"},
	      {OPT=>"numBrick=i", VAR=>\$numLand{BRICK}, DEFAULT=> 4,
	       DESC=>"Number of tiles that are brick"},
             );

  #(!@ARGV) && (usage());

  &GetOptions(map {$_->{OPT}, $_->{VAR}} @Options) || usage();

  # Now setup default values.
  foreach (@Options) {
    if (defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
      ${$_->{VAR}} = $_->{DEFAULT};
    }
  }
}

sub usage {
  print "Usage: $0 [options]\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
