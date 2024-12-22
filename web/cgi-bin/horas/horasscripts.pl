#!/usr/bin/perl
use utf8;

# Name : Laszlo Kiss
# Date : 01-20-08
# Divine Office
use FindBin qw($Bin);
use lib "$Bin/..";

use DivinumOfficium::LanguageTextTools
  qw(prayer translate omit_regexp suppress_alleluia process_inline_alleluias alleluia_ant ensure_single_alleluia ensure_double_alleluia);
use DivinumOfficium::Date qw(date_to_days days_to_date);

# Defines ScriptFunc and ScriptShortFunc attributes.
use DivinumOfficium::Scripting;
my $precesferiales;
$a = 1;

#*** teDeum($lang)
# returns the text of the hymn
sub teDeum : ScriptFunc {
  my $lang = shift;
  return "\n!Te Deum\n" . prayer('Te Deum', $lang);
}

#*** Deus_in_adjutorium($lang)
# return Ferial, Festal, or Solemn chant
sub Deus_in_adjutorium : ScriptFunc {

  my $lang = shift;

  our ($winner, @dayname);
  my %latwinner = %{setupstring('Latin', $winner)};
  my @latrank = split(';;', $latwinner{Rank});
  my $latname = $latrank[0];
  my $latrank = $latrank[2];

  # Ferial chant for all Little hours and Ferials and Simples
  if ( $lang !~ /gabc/
    || $hora !~ /matutinum|laudes|vespera/i
    || $rank < 2
    || $latname =~ /Feria|Sabbato|Vigilia(?! Epi)/i
    || $latrank < 2)
  {
    our $incipitTone = 'ferial';
    return prayer('Deus in adjutorium', $lang);
  }

  our $chantTone;    # has been filled by setChantTone() @horascommon.pl

  if ($hora !~ /vespera/i || $chantTone !~ /solemnis|resurrectionis/i) {
    our $incipitTone = 'festal';
    return prayer('Deus in adjutorium festivus', $lang);    # Festal tone
  } else {    # Solemn Vespers only
    our $incipitTone = 'solemn';
    return prayer('Deus in adjutorium solemnis', $lang);    # Solemn tone
  }
}

#*** Alleluia($lang)
# return the text Alleluia or Laus tibi
sub Alleluia : ScriptFunc {
  my $lang = shift;
  our (%prayers, $incipitTone);
  my $text = prayer('Alleluia', $lang);

  if ($lang =~ /gabc/i && $incipitTone) {
    $text =
        ($incipitTone =~ /festal/i) ? prayer('Alleluia festivus', $lang)
      : ($incipitTone =~ /solemn/i) ? prayer('Alleluia solemnis', $lang)
      : $text;
  }
  my @text = split("\n", $text);

  if ($dayname[0] =~ /Quad/i && !Septuagesima_vesp()) {
    $text = $text[1];
  } else {
    $text = $text[0];
  }

  #if ($dayname[0] =~ /Pasc/i) {$text = "Alleluia, alleluia, alleluia";}
  return $text;
}

#*** Gloria
# returns the text or the omit notice
sub Gloria : ScriptFunc {
  my $lang = shift;
  if (triduum_gloria_omitted()) { return ""; }
  if ($rule =~ /Requiem gloria/i) { return prayer('Requiem', $lang); }
  return prayer('Gloria', $lang);
}

sub Gloria1 : ScriptFunc {    #* responsories
  my $lang = shift;
  if ($dayname[0] =~ /(Quad5|Quad6)/i && $winner !~ /Sancti/i && $rule !~ /Gloria responsory/i) { return ""; }
  return prayer('Gloria1', $lang);
}

sub Gloria2 : ScriptFunc {    #*Invitatorium
  my $lang = shift;
  if ($dayname[0] =~ /(Quad[56])/i) { return ""; }
  if ($rule =~ /Requiem gloria/i) { return prayer('Requiem', $lang); }
  return prayer('Gloria', $lang);
}

#*** Dominus_vobiscum
#returns the text of the 'Domine exaudi' for non priests
sub Dominus_vobiscum : ScriptFunc {
  my $lang = shift;
  my $text = prayer('Dominus', $lang);
  my @text = split("\n", $text);

  if ($priest) {
    $text = "$text[0]\n$text[1]";
  } else {
    if (!$precesferiales) {
      $text = "$text[2]\n$text[3]";
    } else {
      $text = "$text[4]";
    }
    $precesferiales = 0;
  }
  return $text;
}

sub Dominus_vobiscum1 : ScriptFunc {    #* prima after preces
  my $lang = shift;
  if ((preces('Dominicales et Feriales') || $litaniaflag) && !$priest) { $precesferiales = 1; }
  return Dominus_vobiscum($lang);
}

sub Dominus_vobiscum2 : ScriptFunc {    #* officium defunctorum
  my $lang = shift;
  if (!$priest) { $precesferiales = 1; }
  return Dominus_vobiscum($lang);
}

sub mLitany : ScriptFunc {
  my $lang = shift;
  if (preces('Dominicales')) { return ''; }
  return $lang !~ /gabc/i ? "\$Kyrie\n\$pater secreto" : "\$mLitany2";
}

#*** versiculum_ante_laudes($lang)
# return versiculum ante Laudes used in Ordo Praedicatorum only
sub versiculum_ante_laudes : ScriptFunc {
  my $lang = shift;

  my ($v, $c) = getantvers('Versum', 0, $lang);

  $v;
}

#*** Benedicamus_Domino
# adds Alleluia, alleluia for Pasc0
sub Benedicamus_Domino : ScriptFunc {
  my $lang = shift;
  our (@dayname, $hora, $vespera);
  our $chantTone;    # filled by setChantTone() @horascommon.pl

  my $text = prayer('Benedicamus Domino', $lang);

  if (Septuagesima_vesp()
    || ($dayname[0] =~ /Pasc0/i && $hora =~ /(Laudes|Vespera)/i)
    && ($lang !~ /gabc/i || $chantTone !~ /resurrectionis/i))
  {
    $text =~ ($lang !~ /gabc/i)
      ? s/\.\s*\n/". " . prayer('Alleluia Duplex', $lang) . "\n"/egr
      : prayer('Benedicamus Domino1', $lang);
    return $text;    # Paschal octave (Feria IV - Sabbato)
  } elsif ($lang !~ /gabc/i || $hora !~ /(Matutinum|Laudes|Vespera)/i) {
    return $text;    # Little hours
  }

  my %benedicamus = %{setupstring($lang, 'Psalterium/Benedicamus.txt')};
  return ($benedicamus{"$chantTone$vespera"}) || ($benedicamus{"$chantTone"}) || prayer('Benedicamus Domino', 'Latin');
}

#*** handleverses($ref)
# remove or colorize verse numbers
# parentheses text as rubrics
sub handleverses {
  my $gabc = 0;

  map {
    if ($_[1] && !$gabc && /^(name:|\([cf][1-4]\))/) {
      $gabc = 1;
      s/^/{/;    # append brace, s.t. gabc is recognized by webdia.pl
    }

    if ($_[1]) {

      #if ($line !~ /\S/) { last; }
      s/(\s)_([\^\s*]+)_(\(\))?(\s)/$1\^_$2_\^$3$4/g;    # ensure red digits for chant
      s/(\([cf][1-4]\)|\s?)(\d+\.)(\s\S)/$1\^$2\^$3/g;
    }

    if ($nonumbers) {                                    # remove numbering
      s/^(?:\d+:)?\d+[a-z]?\s*//;
      s/\s*\(\d+[a-z]?\)//;
    } elsif ($noinnumbers) {                             # remove subverse letter & inline numbering
      s/\d\K[a-z]//;
      s/\(\d+[a-z]?\)//;
    }

    unless ($nonumbers || $gabc) {                       # put numbers as rubrics
      s{^(?:\d+:)?\d+[a-z]?}{/:$&:/};
      s{\(\d+[a-z]?\)}{/:$&:/};
    }

    s{(\(.*?\))}{/:$&:/} unless $gabc;                   # text in () as rubrics

    s/†\s*//g if $noflexa;

    s/\s(\+|\^✠\^\(\))\s/ / if $version =~ /cist/i;      # no sign-of the cross in Cistercian

    $_
  } @{$_[0]};
}

#*** psalm($chapter, $lang, $antline)  or
# psalm($chapter, $fromverse, $toverse, $lang, $antline)
# if second arg is 1 omit gloria
# selects the text, attaches the head,
# sets red color for the introductory comments
# returns the visible form
sub psalm : ScriptFunc {
  my $psnum = shift;
  my ($lang, $antline, $nogloria);

  #  limits of the division of the psalm.
  my $v1 = 0;       # first line
  my $v2 = 1000;    # last line
  my $c1;           # subverse in first line if any
  my $c2;           # subverse in last line if any

  if (@_ < 3) {
    $nogloria = shift if $_[0] =~ /^1$/;
    $lang = $_[0];
    $antline = $_[1];
  } else {
    ($v1, $c1) = ($1, $2) if $_[0] =~ /^(\d+)([a-z])?/;
    ($v2, $c2) = ($1, $2) if $_[1] =~ /^(\d+)([a-z])?/;
    $lang = $_[2];
    $antline = $_[3];
  }

  # Tridentine Romanum Laudes: Pss. 62/66 & 148/149/150 under 1 gloria
  # Monastic Vespers: Pss. 115/116 & 148/149/150 under 1 gloria
  if ($psnum =~ s/^-(.*)/$1/ && $version =~ /Trident|Monastic/) {
    $nogloria =
         $psnum == 148
      || $psnum == 149
      || ($psnum == 62 && $version !~ /Monastic/)
      || ($psnum == 115 && $version =~ /Monastic/);
  }

  my $bea = $lang eq 'Latin' && $psalmvar || $lang eq 'Latin-Bea';

  # select right Psalm file
  my $fname = "Psalm$psnum.txt";

  if ($lang =~ /gabc/i) {
    if ($canticaTone && $psnum > 230 && $psnum < 233) { $psnum .= ",$canticaTone"; }
    $fname = ($psnum =~ /,/) ? "$psnum.gabc" : "Psalm$psnum.txt";    # distingiush between chant and text
    $fname =~ s/\:/\./g;
    $fname =~ s/,/-/g;                                               # file name with dash not comma
    $psnum =~ s/\:\:/ \& /g;                                         # Multiple Psalms joined together
    $psnum =~ s/\:/; Part: /;                                        # n-th Part of Psalm
    $psnum =~ s/,,.*?,,//;
    $psnum =~ s/,/; Tone: /;                                         # name Tone in Psalm headline
    $ftone = ($psnum =~ /Tone: (.*)/) ? $1 : '';

    if (!(-e "$datafolder/$lang/Psalterium/Psalmorum/$fname")) {
      $psnum =~ s/;.*//;
      $fname = "Psalm$psnum.txt";
    }
  }

  my @lines = do_read(checkfile($bea ? 'Latin-Bea' : $lang, "Psalterium/Psalmorum/$fname"));
  return "Psalm$psnum not found" unless @lines;

  # Prepare title and source if canticle
  my $title = translate('Psalmus', $lang) . " $psnum";
  $title .= "($v1$c1-$v2$c2)" if $v1;
  my $source;

  if ($psnum > 150 && $psnum < 300 && @lines) {
    if ($fname =~ /\.gabc/) {
      $num =~ s/(;.*)//;
      my $latFile = "$datafolder/Latin/Psalterium/Psalmorum/Psalm$num.txt";
      my (@latlines) = do_read($latFile);
      $latlines[0] =~ s/ \*/; Tone: $ftone */;
      unshift(@lines, $latlines[0]);
    }

    shift(@lines) =~ /\(?(?<title>.*?) \* (?<source>.*?)\)?\s*$/;
    ($title, $source) = ($+{title}, $+{source});
    if ($v1) { $source =~ s/:\K.*/"$v1-$v2"/e; }
  } elsif ($bea) {    # special handling for Bea's psalter

    # remove Title if Psalm section does not start in the beginning
    shift(@lines) if $lines[0] =~ /^\(.*\)\s*$/ && $lines[1] =~ /^\d+\:(\d+)[a-z]?\s/ && $v1 > $1;

    if ($psnum == 9) {
      splice(@lines, 20, 20) if $v2 < 22;    # remove Hebr. Ps 10
      splice(@lines, 0, 20) if $v1 > 21;     # remove Hebr. Ps 9
      shift(@lines) if $v1 > 22;             # remove Title B
    }

    if ($lines[0] =~ /^\(.*\)$/) {
      shift(@lines) =~ /\((?<title>.*?)\)\s*$/;
      $title .= " — $1";
    }
  }

  @lines = grep {    # take only needed lines if boundary given
    (
      /^(?:\d+:)?(?<v>\d+)(?<c>[a-z])?/                # line has numbering
        && ($+{v} == $v1 && (!$c1 || $+{c} ge $c1))    # first line
        || ($+{v} == $v2 && (!$c2 || $+{c} le $c2))    # last line
        || ($+{v} > $v1 && $+{v} < $v2)                # betwean
    )
  } @lines if $v1;

  if ($antline && $psnum != 232) {                     # put dagger if needed
    $lines[0] =~ s/^\d+:\d+[a-z]? \K(.*)/ getantcross($1, $antline) /e;
    if ($lines[0] =~ s{/:\x{2021}:/$}{}) { $lines[1] =~ s{^\d+:\d+[a-z]? \K}{/:\x{2021}:/ }; }
  }

  handleverses(\@lines, $lang =~ /gabc/i);

  # put initial at begin
  $lines[0] =~ s/^(?=\p{Letter})/v. / if ($nonumbers || $psnum == 234);    # 234 - quiqumque has no numbers

  my $output = "!$title";
  $output .= " [" . ($column == 1 ? ++$psalmnum1 : ++$psalmnum2) . "]"
    unless 230 < $psnum && $psnum < 234;                                   # add psalm counter
  $output .= "\n!$source" if $source;                                            # add source
  $output .= "\n" . join("\n", @lines) . ($lines[0] =~ /^\{/ ? "}\n" : "\n");    # end chant with brace for recognition

  if ($version =~ /Monastic/ && $psnum == 129 && $hora eq 'Prima') {

    # Commemoratio Defunctorum ad Primam
    $output .= prayer('Requiem', $lang);
  } elsif ($psnum != 210 && !$nogloria) {
    if ($lines[0] =~ /^\{/ && !triduum_gloria_omitted()) {

      # Add Gloria/Requiem Chant
      my $gloria = $commune !~ /C9/ ? 'gloria' : 'requiem';
      $fname = "Psalterium/Psalmorum/$gloria-$ftone.gabc";
      $fname =~ s/,/-/g;    # file name with dash not comma
      $fname = checkfile($lang, $fname);
      my (@lines) = do_read($fname);

      foreach my $line (@lines) {
        $output =~ s/\}\n$/ \n$line\}\n/;
      }
    } else {
      $output .= "\&Gloria\n";
    }
  }

  $output =~ s/\$ant/Ant. $antline/g if $psnum == 94;
  $output;
}

sub Divinum_auxilium : ScriptFunc {
  my $lang = shift;
  if ($lang =~ /gabc/i) { return prayer("Divinum auxilium", $lang); }
  my @text = split(/\n/, prayer("Divinum auxilium", $lang));
  $text[-2] = "V. $text[-2]";
  $text[-1] =~ s/.*\. // unless ($version =~ /Monastic/i);    # contract resp. "Et cum fratribus… " to "Amen." for Roman
  $text[-1] = "R. $text[-1]";
  join("\n", @text);
}

sub Domine_labia : ScriptFunc {
  my $lang = shift;
  my $text = prayer("Domine labia", $lang);

  if ($version =~ /monastic/i) {                              # triple times with one cross sign
    $text .= "\n$text\n$text";
    $text =~ s/\+\+/$&++/;
    $text =~ s/\+\+ / /g;
  }
  $text;
}

#*** special($name, $lang)
# used for 11-02 office
sub special : ScriptFunc {
  my $name = shift;
  my $lang = shift;
  my $r = '';
  %w = (columnsel($lang)) ? %winner : %winner2;

  if (exists($w{$name})) {

    #$r = "#$name specialis\n" . chompd($w{$name}) . "\n";
    $r = chompd($w{$name}) . "\n";
  } elsif ($name =~ /^\#/) {
    my @scriptum = ();
    push(@scriptum, $name);

    @scriptum = specials(\@scriptum, $lang, 1);
    $r = join("\n", @scriptum);
  } else {
    $r = "$name is missing";
  }
  return $r;
}
