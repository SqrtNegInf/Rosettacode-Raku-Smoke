unit module Descriptive::CentralTendency;

sub mean(@data) is export {
  my $number_of_elements=@data.elems;
  die "Data is Empty, provide data values." if $number_of_elements == 0;
  if $number_of_elements == 1 {
      @data[0]
    } else {
      sum(@data)/$number_of_elements
}
}

# sub mean(@data) {
#   my $number_of_elements=@data.elems;
#   die "Data is Empty, provide data values." if $number_of_elements == 0;
#   my $mean = @data[0];
#   for 1..($number_of_elements-1) {
#     my $x = @data[$_];
#     my $old_mean = $mean;
#     $mean = $old_mean + ($x-$old_mean)/($_+1);
#     }
#   return $mean
# }



# Geometric mean
# geometric_mean



# Harmonic mean
# harmonic_mean


# Median 
# sorting the array 
# if odd: middle element is the median
# if even: average of the middle two numbers 

sub median(@nums) is export {
    my @sorted_nums = sort(@nums);
    my $half = @nums.elems div 2;
    if @nums.elems %% 2 {
        return (@sorted_nums[$half - 1] + @sorted_nums[$half])/2
    } else {
        return @sorted_nums[$half]
    }
}


# median_low




# median_high




# median_grouped



# Mode





# multimode



# Quantiles 

