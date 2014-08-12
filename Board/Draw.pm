
package Board::Draw;

use Carp;
use GD;
use strict;

use constant PI => 3.14159;

sub new {
  my($p, %options) = @_;

  my $size = $options{SIZE} || 50;
  my $toFile = $options{TOFILE} || "screen";

  my $s = {
	   SIZE => $size,
	   TOFILE => $toFile,
	  };
 
  return bless $s;
};

sub init {
  my($s, $xs, $ys, $tileTypes) = @_;
  $s->{XSIZE} = $xs;
  $s->{YSIZE} = $ys;

  my $im = new GD::Image(($xs*2+1)*$s->{SIZE}*cosD(30)+5,
                         ($ys*1.5 + 0.5) * $s->{SIZE}+5);

  my %cols = (BLACK     =>$im->colorAllocate(0,0,0),
              BLACK2    =>$im->colorAllocate(0,0,0),
              WHITE     =>$im->colorAllocate(255,255,255),
              BLUE      =>$im->colorAllocate(90,90,255),
              GREEN     =>$im->colorAllocate(0,255,0),
              DARKGREEN =>$im->colorAllocate(0,100,0),
              YELLOW    =>$im->colorAllocate(255,255,0),
              GREY      =>$im->colorAllocate(128,128,128),
              BROWN     =>$im->colorAllocate(180, 120, 60),
              RED       =>$im->colorAllocate(255, 0, 0),
             );
  $s->{COLS} = \%cols;
  $s->{IMAGE} = $im;

  my %hcol = (SHEEP => 'GREEN',
              WOOD  => 'DARKGREEN',
              WHEAT => 'YELLOW',
              ORE   => 'GREY',
              BRICK => 'BROWN',
              UNKNOWN => 'BLACK',
              WATER => 'BLUE',
              BORDER => 'WHITE',
             );

  my %h;
  for my $c (keys %hcol) { $h{$c} = $cols{$hcol{$c}}; } 

  $s->{HCOLS} = \%h;

  $im->fill(1,1, $s->{COLS}{WHITE});
}

sub drawHex {
  my($s, $i, $j, $type, $num) = @_;
  my $size = $s->{SIZE};
  my $x = 2+$size*cosD(30) + $i*2*$size*cosD(30) + ($j&1 ? $size*cosD(30) : 0);
  my $y = 2+$size + $j*$size*(1+sinD(30));
  my $im = $s->{IMAGE};

  (defined($s->{HCOLS}{$type})) || do {carp "Unknown type $type."; return};

  $im->polygon(hexagon(rint($x),rint($y), $size), $s->{COLS}{BLACK2});
  $im->fill($x,$y, $s->{HCOLS}{$type});

  if (defined($num)) {
    my($ix,$iy) = (rint($x-6), rint($y-6));
    ($num<10) && ($ix += 2);
    my $font = ($num==6 || $num==8) ? gdMediumBoldFont : gdSmallFont;
    $im->string($font, $ix, $iy, "$num",$s->{COLS}{BLACK});
  }

#  $im->string(gdSmallFont, $x-15, $y-6, "($i,$j)", $s->{COLS}{BLACK});
}

sub display {
  my($s, $pause) = @_;
  $pause = 1 if (!defined($pause));
  my $im = $s->{IMAGE};

  if ($s->{TOFILE} ne 'screen') {
    open(F, "> $s->{TOFILE}") || die "Can't open $s->{TOFILE} to write";
    print F $im->png;
    close(F);
    return;
  }

  my $pid;
  pipe(RD,WR);
  $SIG{CHLD} = sub { exit; };
  if ($pid=fork()) {
    print WR $im->png;
    close(WR);
    close(RD);
    if ($pause) {
      <>;
      $SIG{CHLD} = sub {};
      kill 'TERM', $pid;
    }
  } else {
    close(WR);
    open(STDIN, "<&RD") || die "can't dup stdin";
    exec("xv -");
  }
}

sub cosD { cos($_[0]*PI/180) };
sub sinD { sin($_[0]*PI/180) };

sub hexagon {
  my($ox,$oy,$size) = @_;
  my @pts;
  for my $a (0..5) {
    my $x = $size*cosD($a*60+30)+$ox;
    my $y = $size*sinD($a*60+30)+$oy;
    push(@pts, rint($x),rint($y));
  }
  return poly(@pts);
}

sub poly {
  my(@pts) = @_;
  my $p = new GD::Polygon;
  while (@pts) {
    $p->addPt(shift(@pts), shift(@pts));
  }
  return $p;
}

sub rint { int($_[0]+0.5); };

1;
