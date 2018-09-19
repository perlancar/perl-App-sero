package App::sero::Role::Exchange;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               meta
               source_to_canonical_code
               canonical_to_source_code
       );

1;
# ABSTRACT: Role for exchange driver

=head1 DESCRIPTION

This role is for stock exchange driver module.


=head1 REQUIRED METHODS

=head2 meta

Must return metadata hash, e.g.

 {
     code => "IDX",
     eng_name => "Indonesian Stock Exchange",
     local_name => "Bursa Efek Indonesia",
     country_code => "ID",
 }

=head2 sources

Must return list of supported quote sources. This is the name of
C<Finance::QuoteHist::*> module without the prefix. For example:

 ['Yahoo', 'DailyFinance']

=head2 source_to_canonical_code

Usage:

 $se->source_to_canonical_code($source, $stock_code)

Example:

 $se->source_to_canonical_code('Yahoo', 'BBCA.JK');  # => IDX:BBCA
 $se->source_to_canonical_code('Yahoo', 'BBCA');     # => IDX:BBCA (qualify)
 $se->source_to_canonical_code('Yahoo', 'IDX:BBCA'); # => IDX:BBCA (unchanged)

Convert code from source format to canonical format. Must return undef if source
is not supported/recognized or stock code is invalid.

Must return stock code unchanged if given code that is already in canonical
form.

=head2 canonical_to_source_code

Usage:

 $se->canonical_to_source_code($source, $stock_code)

Example:

 $se->canonical_to_source_code('Yahoo', 'IDX:BBCA'); # => BBCA.JK
 $se->source_to_canonical_code('Yahoo', 'BBCA');     # => BBCA.JK (qualify)
 $se->canonical_to_source_code('Yahoo', 'BBCA.JK');  # => BBCA.JK (unchanged)

Convert code from canonical format to source format. Must return undef if source
is not supported/recognized or stock code is invalid.

Must return stock code unchanged if given code that is already in source form.



=head1 INTERNAL NOTES


=head1 SEE ALSO
