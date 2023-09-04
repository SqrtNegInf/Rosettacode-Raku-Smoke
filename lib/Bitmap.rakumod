unit module Bitmap;

# from ../Bitmap_Read_a_PPM_file
# 2018-03-30

class Pixel { has UInt ($.R, $.G, $.B) }
class Bitmap {
    has UInt ($.width, $.height);
    has Pixel @.data;
}
 
role PGM {
    has @.GS;
    method P5 returns Blob {
	"P5\n{self.width} {self.height}\n255\n".encode('ascii')
	~ Blob.new: self.GS
    }
}
 
sub load-ppm ( $ppm ) {
    my $fh    = $ppm.IO.open( :enc('ISO-8859-1') );
    my $type  = $fh.get;
    my ($width, $height) = $fh.get.split: ' ';
    my $depth = $fh.get;
    Bitmap.new( width => $width.Int, height => $height.Int,
      data => ( $fh.slurp.ords.rotor(3).map:
        { Pixel.new(R => .[0], G => .[1], B => .[2]) } )
    )
}
 
