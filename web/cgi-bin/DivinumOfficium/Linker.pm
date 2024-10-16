package DivinumOfficium::Linker;
# use strict;
# use warnings;

use DivinumOfficium::FileIO qw(do_read);

BEGIN {
  require Exporter;
  our $VERSION = 1.00;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(linker);
}


#*** gettext($fname, $section)
# gets text from $section in $fname
# or just $fname content
sub gettext {
  my ($fname, $section) = split(/#/, shift, 2);
  my $lang = shift;
  if (!$section) {
    my @a = do_read(main::checkfile($lang, $fname));
    join("\n", @a);
  } else {
    $fname =~ s/\.txt$//;
    my %h = %{main::setupstring($lang, "$fname.txt")};
    $h{$section} =~ s/\n\n//r;
  }
}

#*** linker($ref_to_specials_output, $lang)
# digest output of specials() array of chunks
# chunk cases                          replaced by
# string @filename#section             section from filename
# string @filename                     contents of filename
# string other                         leave intact
# array [string, func]                 'sources' ammended by 'func'
#    string can contain multiple 
#    'sources' divided by ";;" (in form 
#    as two first cases but without @)
#    'func' is called with 'sources' and lang
sub linker {
  my(@list) = @{$_[0]};
  my($lang) = $_[1];

  [ map {
    if (ref($_) eq 'ARRAY') {
      my @texts = map { gettext($_, $lang) } split(/;;/, $$_[0]);
      if (exists($$_[1])) {
        &{$$_[1]}(@texts, $lang);
      } else {
        $text
      }
    } else { # string
      if (substr($_, 0, 1) eq '@') {
        gettext(substr($_, 1), $lang)
      } else {
        $_
      }
    }
  } @list ];
}

1;
