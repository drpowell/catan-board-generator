
package Board::Generate;

use Carp;
use Exporter();

use Board::Draw;

@ISA=qw(Exporter);
@EXPORT_OK = qw(@landTypes);

@landTypes = qw(SHEEP WOOD WHEAT ORE BRICK);
@tileTypes = ('UNKNOWN', 'WATER', 'BORDER', @landTypes);

my $probabilisticPlacement = 1;

sub new {
  my($p,%options) = @_;

  
  my $xs           = defined($options{XSIZE})      ? $options{XSIZE} : 10;
  my $ys           = defined($options{YSIZE})      ? $options{YSIZE} : 10;
  my $DEBUG        = defined($options{DEBUG})      ? $options{DEBUG} : 0;
  my $numIslands   = defined($options{NUMISLANDS}) ? $options{NUMISLANDS} : 1;
  my $pClump       = defined($options{PCLUMP})     ? $options{PCLUMP} : 1;
  my $pTypeClump   = defined($options{PTYPECLUMP}) ? $options{PTYPECLUMP} : 1;
  my $numTiles     = defined($options{NUMTILES})   ? $options{NUMTILES} : 20;
  my $landToPlace  = defined($options{LAND})       ? $options{LAND} : [];
  my $numsToPlace  = defined($options{NUMBERS})    ? $options{NUMBERS} : [];

  { # Deal with land to place
    while (@$landToPlace > $numTiles) {
      pop @$landToPlace;
    }
    
    while (@$landToPlace < $numTiles) {
      push @$landToPlace, $landTypes[int(rand @landTypes)];
  }
    
    # randomize LandToPlace
    my @p;
    while (@$landToPlace>0) {
      my $i = int(rand @$landToPlace);
      push(@p, $landToPlace->[$i]);
      splice(@$landToPlace, $i, 1);
    }
    $landToPlace = \@p;
  }
  
  { # Deal with numbers to place
    while (@$numsToPlace > $numTiles) {
      pop @$numsToPlace;
    }
    
    while (@$numsToPlace < $numTiles) {
      my $num = int(rand(10))+2;
      $num += ($num>=7);
      push @$numsToPlace, $num;
    }
    
    # randomize numsToPlace
    my @p;
    while (@$numsToPlace>0) {
      my $i = int(rand @$numsToPlace);
      push(@p, $numsToPlace->[$i]);
      splice(@$numsToPlace, $i, 1);
    }
    $numsToPlace = \@p;
  }
  
  my($s) = {
	    HEX => [],
	    XSIZE       => $xs,
	    YSIZE       => $ys,
	    DEBUG       => $DEBUG,
	    NUMISLANDS  => $numIslands,
	    PCLUMP      => $pClump,
	    PTYPECLUMP  => $pTypeClump,
	    NUMTILES    => $numTiles,
	    LANDTOPLACE => $landToPlace,
	    NUMSTOPLACE => $numsToPlace,
	   };

  for my $i (0..$xs-1) {
    for my $j (0..$ys-1) {
      $s->{HEX}[$i][$j]{TYPE} = 'UNKNOWN';
    }
  }

  return bless $s;
};

sub probOfNum {
  my($num) = @_;
  ($num>7) && ($num = 14-$num);
  ($num-1)/36;
}

sub expectedProduction {
  my($s) = @_;
  my $numTiles = 0;
  
  my %expNum;
  for my $i (0..$s->{XSIZE}-1) {
    for my $j (0..$s->{YSIZE}-1) {
      next if ($s->{HEX}[$i][$j]{TYPE} =~ /UNKNOWN|WATER/);
      $expNum{$s->{HEX}[$i][$j]{TYPE}} += probOfNum($s->{HEX}[$i][$j]{NUM});
    }
  }
  return \%expNum;
}

sub numIslesTouching {
  my($s, $i, $j) = @_;
  my($isleNum) = 0;
  my(@isles) = ();
  for my $n ($s->neighbours($i, $j)) {
    my($nx,$ny) = @$n;
    my $isle = ${$s->at($nx,$ny)}->{ISLENUM};
  
    next unless defined($isle);
    $isles[$isle]++;
    ($isles[$isle]==1) && ($isleNum++);
  }

  return $isleNum;
}

sub scorePosition {
  my($s, $i, $j) = @_;
  my $pClump = $s->{PCLUMP};
  my $coast = ${$s->at($i,$j)}->{COAST};  
  my $maxcoast = ${$s->at($i,$j)}->{MAXCOAST};

  return 0 if ($coast==$maxcoast);   # No new islands
  return 0 if ($s->numIslesTouching($i,$j) > 1);      # Don't join islands
  
  $score = 4**((0.5-2*($coast/6-0.5)*($pClump-0.5))*4);
  
  return $score;
}

sub placeTiles {
  my($s) = @_;
  # Place first seperate islands randomly
  my $tileNum;
  for ($tileNum=1; $tileNum<=$s->{NUMISLANDS}; $tileNum++) {
    my($i,$j) = (int(rand $s->{XSIZE}),int(rand $s->{YSIZE}));
    
    redo if $s->{HEX}[$i][$j]{TYPE} ne 'UNKNOWN';
    my $types = $s->neighbourTypes($i, $j);
    my $set=0;
    for my $l (@landTypes) { $set += $types->{$l} };
    redo if $set !=0;

    $s->placeTile($i,$j, 'PLACED', pop(@{$s->{NUMSTOPLACE}}), $tileNum);
  }

  # Now place the rest of the tiles
  for (;$tileNum<=$s->{NUMTILES}; $tileNum++) {
    print "Placing tile $tileNum\n" if ($s->{DEBUG}>0);

    my $totalScore = 0;
    my @tileScore;
    for my $i (0..$s->{XSIZE}-1) {
      for my $j (0..$s->{YSIZE}-1) {

        if ($s->{HEX}[$i][$j]{TYPE} eq 'UNKNOWN') {
	  $tileScore[$i][$j] = $s->scorePosition( $i, $j );
        } else {
          # Tile already set.  Can't redefine
          $tileScore[$i][$j] = 0;
        }

        $totalScore += $tileScore[$i][$j];
      }
    }

    my ($i, $j) = $s->choosePlace(\@tileScore, $totalScore);

    if (!defined($i) || !defined($j)) { die "Oops ($i,$j) not on board"; }

    $s->placeTile($i, $j, 'PLACED' , pop(@{$s->{NUMSTOPLACE}}));
  }
}

sub scoreType {
  my($s, $type, $types) = @_;
  my($pTypeClump) = $s->{PTYPECLUMP};
  $pTypeClump = ($pTypeClump-0.5)*2;       # Make it between -1 and 1

  my $score;
  $score = 10**($types->{$type} * $pTypeClump);
}

sub allocateLandTypes {
  my($s) = @_;
  print "Allocating resources to placed tiles\n" if ($s->{DEBUG}>0);
  for my $tileToPlace (@{$s->{LANDTOPLACE}}) {
    my $totalScore = 0;
    my @tileScore;
    for my $i (0..$s->{XSIZE}-1) {
      for my $j (0..$s->{YSIZE}-1) {
        if ($s->{HEX}[$i][$j]{TYPE} eq 'PLACED') {
	  $types = $s->neighbourTypes($i, $j);
	  $tileScore[$i][$j] = $s->scoreType( $tileToPlace, $types);
        } else {
          $tileScore[$i][$j] = 0;
        }

        $totalScore += $tileScore[$i][$j];
      }
    }
    
    my ($i, $j) = $s->choosePlace(\@tileScore, $totalScore);
    
    if (!defined($i) || !defined($j)) { die "Oops ($i,$j) not on board"; }

    ${$s->at($i,$j)}->{TYPE} = $tileToPlace;
  }
}

sub autoArrange {
  my($s) = @_;

  $s->genCoastCounts();

  $s->placeTiles();

  $s->allocateLandTypes();

  for my $i (0..$s->{XSIZE}-1) {
    for my $j (0..$s->{YSIZE}-1) {
      next if ($s->{HEX}[$i][$j]{TYPE} =~ /UNKNOWN|WATER/);
      $s->surround($i,$j,[@landTypes],'WATER');
    }
  }
}

sub choosePlace {
  my($s, $tileScore, $totalScore) = @_;
  my $randScore = rand $totalScore;
  $totalScore = 0;
  my($i,$j);

  CHOOSETILE : {
    for my $ic (0..$s->{XSIZE}-1) {
      for my $jc (0..$s->{YSIZE}-1) {
	
	if ($probabilisticPlacement) {
	  $totalScore += $tileScore->[$ic][$jc];
	  if ($totalScore>=$randScore) { 
	    ($i,$j) = ($ic,$jc);
	    last CHOOSETILE; 
	  }
	} else {
	  if ($tileScore->[$ic][$jc]>$totalScore) {
	    $totalScore = $tileScore->[$ic][$jc];
	    ($i,$j) = ($ic,$jc);
	  }
	}
      }
    }
  }
  return ($i,$j);
}

sub placeTile {
  my($s, $i, $j, $type, $num, $setIsleNum) = @_;
  ${$s->at($i,$j)}->{TYPE} = $type;
  ${$s->at($i,$j)}->{NUM} = $num;
  my $isleNum;
  for my $n ($s->neighbours($i, $j)) {
    my($nx,$ny) = @$n;
    ${$s->at($nx,$ny)}->{COAST} -= 1;
    $isleNum ||= ${$s->at($nx,$ny)}->{ISLENUM};
  }

  ($setIsleNum) && ($isleNum = $setIsleNum);

  ${$s->at($i,$j)}->{ISLENUM} = $isleNum;
}

sub genCoastCounts {
  my($s) = @_;
  for my $i (0..$s->{XSIZE}-1) {
    for my $j (0..$s->{YSIZE}-1) {
      my $n = $s->neighbours($i, $j);
      ${$s->at($i,$j)}->{COAST} = @$n;
      ${$s->at($i,$j)}->{MAXCOAST} = @$n;
    }
  }
}

sub neighbourTypes {
  my($s,$x,$y) = @_;
  my $d  = $s->{HEX};

  my %r = map { $_ => 0} @tileTypes;

  for my $n ($s->neighbours($x, $y)) {
    my($nx,$ny) = @$n;
    $r{$d->[$nx][$ny]{TYPE}}++;
  }

  return \%r;
};

# connected - return a list of the indicies of all hexes that
#             have $type and are connected to ($x,$y)
sub connected {
  my($s, $x, $y, $type, $visited) = @_;
  $visited ||= {};
  my $d = $s->{HEX};

  my @res = ();

  return @res if ($visited->{"$x.$y"});
  $visited->{"$x.$y"}=1;
  push(@res, [$x,$y]);

  for my $n ($s->neighbours($x, $y)) {
    my($nx,$ny) = @$n;
    if (checkType($type, $d->[$nx][$ny]{TYPE}) && !$visited->{"$nx.$ny"}) {
      push(@res, $s->connected($nx,$ny, $type, $visited));
    }
  }
  return @res; 
}

sub at {
  my($s,$x,$y) = @_;
  my $d = $s->{HEX};
  if (!$s->onBoard($x,$y)) {
    carp "(x,y)=($x,$y) outside range";
    return undef;
  }
  return \($d->[$x][$y]);
};

sub onBoard($$$) {
  my($s,$x,$y) = @_;
  if ($x>=$s->{XSIZE} || $y>=$s->{YSIZE} || $x<0 || $y<0) {
    return 0;
  }
  return 1;
}

sub checkType($$) {
  my($l,$v) = @_;
  return (grep(/^$v$/, @$l)==1);
}

sub neighbours {
  my($s,$x,$y) = @_;

  my @res;
  for my $ic (0..1) {
    for my $j (-1..1) {
      my $i=$ic;
      ($i==0 && $j==0) && ($i=-1);
      ($j!=0 && $y%2==0) && ($i-=1);
      ($s->onBoard($x+$i, $y+$j)) && push(@res, [$x+$i, $y+$j]);
    }
  }
  return @res;
}

# surround - surround a region of $surround with $type 
sub surround {
  my($s, $x, $y, $surround, $type, $visited) = @_;
  $visited ||= {};
  my $d = $s->{HEX};
  if (!$s->onBoard($x,$y)) {
    carp "(x,y)=($x,$y) outside range";
    return;
  };
  if (!checkType($surround, $d->[$x][$y]{TYPE})) {
    carp "Tile to surround is not one of @$surround";
    return;
  }

  return if ($visited->{"$x.$y"});
  $visited->{"$x.$y"}=1;

  for my $n ($s->neighbours($x, $y)) {
    my($nx,$ny) = @$n;
    if (checkType($surround, $d->[$nx][$ny]{TYPE}) && !$visited->{"$nx.$ny"}) {
      $s->surround($nx,$ny, $surround, $type, $visited);
    } elsif ($d->[$nx][$ny]{TYPE} eq 'UNKNOWN') {
      $d->[$nx][$ny]{TYPE} = $type;
    }
  }
};

sub draw {
  my($s, $draw, $pause) = @_;
  $size ||= 50;
  $pause = 1 if (!defined($pause));
  my($xs,$ys) = ($s->{XSIZE}, $s->{YSIZE});
  my $d = $s->{HEX};

  $draw->init($xs,$ys, [@tileTypes]);

  for my $i (0..$xs-1) {
    for my $j (0..$ys-1) {
      my $t = $d->[$i][$j]{TYPE};
      (!defined($t)) && ($t = 'UNKNOWN');
      if ((grep /^$t$/, @tileTypes)!=1) {
        carp "Unknown type $t";
        next;
      }

      my $n = $d->[$i][$j]{NUM};

      $draw->drawHex($i, $j, $t, $n);
    }
  }

  $draw->display($pause);
}

1;
