use v6;

module JSON::OptIn {
    role OptedInAttribute {
    }


    multi sub trait_mod:<is>(Attribute $a, :$json!) is export(:DEFAULT){
        $a does OptedInAttribute;
    }

}
# vim: expandtab shiftwidth=4 ft=raku
