package SVGGraph;

use strict;
use warnings;
our $VERSION = '0.01';

sub new()
{
  my $self = shift;
  my $class = ref($self) || $self;
  return bless {}, $class;
}

sub CreateGraph()
{
  ### First element of @_ is a reference to the element that called this subroutine
  my $self = shift;
  ### Second is a reference to a hash with options
  my $options = shift;
  ### The options passed in the anonymous hash are optional so create a default value first
  my $horiUnitDistance = 20;
  if ($$options{'horiUnitDistance'})
  {
    $horiUnitDistance = $$options{'horiUnitDistance'};
  }
  my $graphType = 'spline';
  if ($$options{'graphtype'})
  {
    $graphType = $$options{'graphtype'};
  }
  ### The rest are references to arrays with references to arrays with x and y values
  my @xyArrayRefs = @_;
  ### Declare the $minX as the lowest value of x in the arrays, same for $minY, $maxX and $maxY
  my $minX = $xyArrayRefs[0]->[0]->[0]; ### Equivalent to ${${$xyArrayRefs[0]}[0]}[0];
  my $minY = $xyArrayRefs[0]->[1]->[0];
  my $maxX = $minX;
  my $maxY = $minY;
  ### Then really search for the lowest and highest value of x and y
  for (my $i = 0; $i < @xyArrayRefs; $i++)
  {
    for (my $j = 0; $j < @{$xyArrayRefs[$i]->[0]}; $j++)
    {
      if ($xyArrayRefs[$i]->[0]->[$j] > $maxX)
      {
        $maxX = $xyArrayRefs[$i]->[0]->[$j];
      }
      if ($xyArrayRefs[$i]->[0]->[$j] < $minX)
      {
        $minX = $xyArrayRefs[$i]->[0]->[$j];
      }
      if ($xyArrayRefs[$i]->[1]->[$j] > $maxY)
      {
        $maxY = $xyArrayRefs[$i]->[1]->[$j];
      }
      if ($xyArrayRefs[$i]->[1]->[$j] < $minY)
      {
        $minY = $xyArrayRefs[$i]->[1]->[$j];
      }
    }
  }
  ### Calculate all dimensions neccessary to create the Graph
  ### Height of the total svg image in pixels:
  my $imageHeight = 400;
  ### Distance between the sides of the gris and the sides of the image:
  my $cornerDistance = 50;
  ### Since svg counts from the top left corner of the image, we translate all coordinates vertically in pixels:
  my $vertTranslate = $imageHeight - $cornerDistance;
  ### The width of the grid in pixels:
  my $gridWidth = $horiUnitDistance * ($maxX - $minX);
  ### The height of the grid in pixels:
  my $gridHeight = $imageHeight - 2 * $cornerDistance;
  ### The width of the whole svg image:
  my $imageWidth = $gridWidth + 2 * $cornerDistance;
  ### The horizontal space between vertical gridlines in pixels:
  my $xGridDistance = 20;
  ### The vertical space between horizontal gridlines in pixels:
  my $yGridDistance = 30;

  ### Now initiate the svg graph by declaring some general stuff.
  my $svg .= <<"  EOF";
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20000303 Stylable//EN" "http://www.w3.org/TR/2000/03/WD-SVG-20000303/DTD/svg-20000303-stylable.dtd" >
<svg width="$imageWidth" height="$imageHeight">
<g id="grid" transform="translate($cornerDistance, $vertTranslate)">
  EOF

  ### make x- and y axes
  $svg .= "<path d=\"M0,0H-5 0 V 5 " . (-1 * $gridHeight) . " h -5 10 -5 V 0H" . $gridWidth . " V 5 -5 0 H 0\" style=\"fill: none; stroke: #000000;\"/>\n";

  ### print numbers on y axis and horizontal gridlines
  ### First calculate the width between the gridlines in y-units, not in pixels
  my $deltaYUnits = $self->NaturalRound ($yGridDistance * ($maxY - $minY) / $gridHeight);
  ### Adjust $minX and $maxX so the gridlines and numbers startand end in a whole and nice number.
  $minY = int ($minY / $deltaYUnits - 0.999999999999) * $deltaYUnits;
  $maxY = int ($maxY / $deltaYUnits + 0.999999999999) * $deltaYUnits;
  ### Calculate the number of pixels each units stands for.
  my $yPixelsPerUnit = ($gridHeight / ($maxY - $minY));
  my $deltaYPixels = $deltaYUnits * $yPixelsPerUnit;
  ### Calculate the amount of gridlines and therefore the amount of numbers on the y-axis
  my $yNumberOfNumbers = int ($gridHeight / $deltaYPixels) + 1;
  ### Draw the numbers and the gridlines
  for (my $i = 0; $i < $yNumberOfNumbers; $i++)
  {
    my $YValue = (-1 * $i * $deltaYPixels);
    ### numbers
    $svg .= "<text x=\"-10\" y=\"$YValue\" style=\"text-anchor:middle;font-size:8\" startOffset=\"0\">" . ($minY + $i * $deltaYUnits) . "</text>\n";
    ### gridline
    $svg .= "<line x1=\"0\" y1=\"$YValue\" x2=\"$gridWidth\" y2=\"$YValue\" style=\"stroke: #000000; fill: none; stroke-width: 0.5; stroke-dasharray:4 4;\"/>\n";
  }

  ### print numbers on x axis and vertical gridlines
  my $deltaXUnits = $self->NaturalRound ($xGridDistance * ($maxX - $minX) / $gridWidth);
  my $xPixelsPerUnit = ($gridWidth / ($maxX - $minX));
  my $deltaXPixels = $deltaXUnits * $xPixelsPerUnit;
  my $xNumberOfNumbers = int ($gridWidth / $deltaXPixels) + 1;
  for (my $i = 0; $i < $xNumberOfNumbers; $i++)
  {
    my $XValue = ($i * $deltaXPixels);
    ### numbers
    $svg .= "<text x=\"" . $XValue . "\" y=\"10\" style=\"text-anchor:middle;font-size:8\" startOffset=\"0\">" . ($minX + $i * $deltaXUnits) . "</text>\n";
    ### gridline
    $svg .= "<line x1=\"$XValue\" y1=\"0\" x2=\"$XValue\" y2=\"" . (-1 * $gridHeight) . "\" style=\"stroke:#000000;stroke-width:0.5;stroke-dasharray:4 4;\"/>\n";
  }

  ### print measurepoints (dots) (data) (coordinates)
  ### Spline
  if ($graphType eq 'spline')
  {
    for (my $i = 0; $i < @xyArrayRefs; $i++)
    {
      my $dots;
      $svg .= "<path d=\"M0 0";
      for (my $dotNumber = 0; $dotNumber < @{$xyArrayRefs[$i]->[0]}; $dotNumber++)
      {
        my $dotX = $horiUnitDistance * ($xyArrayRefs[$i]->[0]->[$dotNumber] - $minX);
        my $dotY = -1 * $yPixelsPerUnit * ($xyArrayRefs[$i]->[1]->[$dotNumber] - $minY);
        $dots .= $self->CreateDot($dotX, $dotY, 3, $xyArrayRefs[$i]->[3], $i);
        $svg .= " L$dotX $dotY";
      }
      $svg .= "\" style=\"fill: none; stroke: " . $xyArrayRefs[$i]->[3] . "; stroke-width:2\"/>\n$dots";
    }
  }
  ### Vertical Bars
  elsif ($graphType eq 'verticalbars')
  {
    for (my $dotNumber = 0; $dotNumber < @{$xyArrayRefs[0]->[0]}; $dotNumber++)
    {
      ### The longest bars must be drawn first, so that the shirter bars are drwan on top of the longer.
      ### So we sort $i (the number of the graph) to the length of the bar for each point.
      foreach my $i (sort {$xyArrayRefs[$b]->[1]->[$dotNumber] <=> $xyArrayRefs[$a]->[1]->[$dotNumber]} (0 .. $#xyArrayRefs))
      {
        my $lineX = $horiUnitDistance * ($xyArrayRefs[$i]->[0]->[$dotNumber] - $minX);
        my $lineY1 = 0;
        if (($minY < 0) && ($maxY > 0))
        {
          $lineY1 = $yPixelsPerUnit * $minY;
        }
        elsif ($maxY < 0)
        {
          $lineY1 = -1 * 1;
        }
        my $lineY2 = -1 * $yPixelsPerUnit * ($xyArrayRefs[$i]->[1]->[$dotNumber] - $minY);
        $svg .= "<line x1=\"$lineX\" y1=\"$lineY1\" x2=\"$lineX\" y2=\"$lineY2\" style=\"stroke:" . $xyArrayRefs[$i]->[3] . ";stroke-width:10;\"/>\n";
      }
    }
  }

  ### print Title, Labels and Legend
  ### Title
  if ($$options{'title'})
  {
    $svg .= "<text x=\"" . ($gridWidth / 2) . "\" y=\"" . (-1 * $gridHeight - 20) . "\" style=\"text-anchor:middle;font-size:24\" startOffset=\"0\">$$options{'title'}</text>\n";
  }
  ### x-axis label
  if ($$options{'xlabel'})
  {
    $svg .= "<text x=\"" . ($gridWidth / 2) . "\" y=\"25\" style=\"text-anchor:middle;font-size:16\" startOffset=\"0\">$$options{'xlabel'}</text>\n";
  }
  ### y-axis label
  if ($$options{'ylabel'})
  {
    $svg .= "<text x=\"" . ($gridHeight / 2) . "\" y=\"-20\" style=\"text-anchor:middle;font-size:16\" startOffset=\"0\" transform=\"rotate(-90)\">$$options{'ylabel'}</text>\n";
  }
  ### Legend
  my $legendOffset = "$cornerDistance, $cornerDistance";
  if ($$options{'legendoffset'})
  {
    $legendOffset = $$options{'legendoffset'};
  }
  $svg .= "</g>\n<g id=\"legend\" transform=\"translate($legendOffset)\">\n";
  for (my $i = 0; $i < @xyArrayRefs; $i++)
  {
    if ($xyArrayRefs[$i]->[2])
    {
      if ($graphType eq 'spline')
      {
        ### The line
        $svg .= "<line x1=\"0\" y1=\"" . (16 * $i) . "\" x2=\"16\" y2=\"" . (20 * $i) . "\" style=\"stroke-width:2;stroke:" . $xyArrayRefs[$i]->[3] . "\"/>\n";
        ### The dot
        $svg .= $self->CreateDot(8, 16 * $i, 3, $xyArrayRefs[$i]->[3], $i);
      }
      ### The text
      $svg .= "<text x=\"20\" y=\"" . (4 + 16 * $i) . "\" style=\"font-size:12;stroke:" . $xyArrayRefs[$i]->[3] . "\">" . $xyArrayRefs[$i]->[2] . "</text>\n";
    }
  }
  $svg .= "</g>\n</svg>\n";
  return $svg;
}

### CreateDot is a subroutine that creates the svg code for different
### kinds of dots used in the spline graph type: circles, squares, triangles and more.
sub CreateDot()
{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $r = shift;
  my $color = shift;
  my $dotNumber = shift;
  my $d = 2 * $r;
  my $svg;
  ### Circle
  if ($dotNumber == 0)
  {
    $svg = "<circle cx=\"$x\" cy=\"$y\" r=\"$r\" style=\"fill: $color; stroke: $color;\"/>\n";
  }
  ### Vertical line
  elsif ($dotNumber == 1)
  {
    $svg .= "<path d=\"M $x " . ($y - $r) . " l 0 $d z\" style=\"stroke: $color; stroke-width: 2\"/>\n";
  }
  ### Triangle
  elsif ($dotNumber == 2)
  {
    $svg .= "<path d=\"M " . ($x - $r) . " " . ($y - $r) . " l $d 0 l -$r $d z\" style=\"fill: $color; stroke: $color;\"/>\n";
  }
  ### Square
  else
  {
    $svg .= "<path d=\"M " . ($x - $r) . " " . ($y - $r) . " l $d 0 l 0 $d l -$d 0 z\" style=\"fill: $color; stroke: $color;\"/>\n";
  }
  return $svg;
}

### NaturalRound is a subroutine that round a number to 1, 2, 5 or 10 times its order
### So 110.34 becomes 100
### 3.1234 becomes 2
### 40 becomes 50

sub NaturalRound()
{
  my $self = shift;
  my $numberToRound = shift;
  my $rounded;
  my $order = int (log ($numberToRound) / log (10));
  my $remainder = $numberToRound / 10**$order;
  if ($remainder < 1.4)
  {
    $rounded = 10**$order;
  }
  elsif ($remainder < 3.2)
  {
    $rounded = 2 * 10**$order;
  }
  elsif ($remainder < 7.1)
  {
    $rounded = 5 * 10**$order;
  }
  else
  {
    $rounded = 10 * 10**$order;
  }
}

1;

__END__

=head1 NAME

SVGGraph - Perl extension for creating SVG Graphs.

=head1 SYNOPSIS

  use SVGGraph;

  my @a = (1, 2, 3, 4);
  my @b = (3, 4, 3.5, 6.33);

  print "Content-type: image/svg-xml\n\n";
  print SVGGraph->new(
                        { 'title' => 'Financial Results Q1 2002' },
			[\@a, \@b, 'Staplers', 'red']
		     );

=head1 DESCRIPTION

This module converts sets of arrays with coordinates into
graphs, much like GNUplot would. It creates the graphs in the
SVG (Scalable Vector Graphics) format. It has two styles,
verticalbars and spline. It is designed to be light-weight.

If your internet browser cannot display SVG, try downloading
a plugin at adobe.com.

=head2 EXPORT

None by default.


=head1 AUTHOR

Teun van Eijsden, E<lt>teun@chello.nlE<gt>

=head1 SEE ALSO

L<perl>.

=cut
