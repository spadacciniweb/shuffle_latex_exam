#!/usr/bin/env perl

use strict;
use warnings;
use List::Util qw/shuffle/;
use POSIX qw(ceil);
no if ($] >= 5.018), 'warnings' => 'experimental';

my ($source, $n_totali, $modulo, $footer) = @ARGV;
 
if (not defined $source) {
    print "$0 src_exam.tex [tot] [mod] [global_footer]";
    print "\nsrc_exam.tex: original exam text written in TeX (sample in test_source_sample.tex)";
    print "\ntot: total exam tests (default 15)";
    print "\nmod: shuffle to be carried out (default 3, it is set as the modulus of the number of total exam tests)";
    print "\nglobal_footer: 0 or 1 (default 1)";
    print "\n";
    exit 1;
} elsif (not -r $source ) {
    printf "source exam is not readable";
    exit 2;
}

if (not defined $n_totali
    or
    $n_totali !~ /^\d+$/
    or
    $n_totali < 1
) {
    printf "tot is not valid so it is equal to 15\n";
    $n_totali = 15;
}

if (not defined $modulo
    or
    $modulo !~ /^\d+$/
    or
    $modulo < 1
    or
    $modulo > $n_totali
) {
    printf "mod is not valid so it is equal to 3\n";
    $modulo = 3;
}

if (not defined $footer
    or
    $footer !~ /^[01]$/
) {
    printf "footer is not valid so it is equal to 1\n";
    $footer = 1;
}
print "\n";

my $file_out_esame = 'full_exam.pdf';
my $spool = 'spool/';

printf "Reading source exam...";
open RH, "<:utf8", $source or die "Can't open < $source: $!";

my %part;
my %bool;
my @questions;

$bool{head} = 1;
while (my $line = <RH>) {
    if ($bool{head}) {
        $part{head} .= $line;
        if ($line =~ /^\\begin\{questions\}/) {
            $bool{head} = 0;
            $bool{questions} = 1;
        }
    } elsif ($bool{questions}) {
        if ($line =~ /^\\question/) {
            $questions[ scalar @questions ] = $line;
        } elsif ($line =~ /^\\end\{questions\}/) {
            $part{end} = $line;
            $bool{questions} = 0;
            $bool{end} = 1;
        } elsif (scalar @questions) {
            $questions[ $#questions ] .= $line;
        } else {
            # Why here?
        }
    } elsif ($bool{end}) {
        $part{end} .= $line;
    } else {
        printf "Why here?";
        exit 1;
    }
}

my $members = ceil ($n_totali / $modulo);
my $group = 0;
chdir $spool;
my $file_out = 'out.tex';
foreach my $i (0..($n_totali-1)) {
    if ($i % $members == 0) {
        @questions = shuffle @questions;
        open WH, ">:utf8", $file_out or die "Can't open > $file_out: $!";
        print WH $part{head};
        foreach my $q (@questions) {
            print WH $q;
        }
        print WH $part{end};
    }
    system(sprintf "pdflatex %s", $file_out);
    system(sprintf "cp out.pdf out_%s.pdf", $i);
}

# join pdf

my $input_files = join ' ', map { sprintf 'out_%d.pdf', $_ }
                            0..($n_totali-1);
system( sprintf "pdftk %s cat output %s", $input_files, $file_out_esame);

if ($footer) {
    print "Writing the footer...\n";
    my $cmd = sprintf "pdftk %s dump_data | grep NumberOfPages", $file_out_esame;
    my $total_pages = `$cmd`;
    $total_pages =~ s/.+ (\d+)\n$/$1/;
    my $page_numbers_template = '../template/page_number.tex';
    my $out_page_number = 'page_number.tex';
    open(my $rh, "<", $page_numbers_template) or die "Can't open < $page_numbers_template: $!";
    open(my $wh, ">", $out_page_number) or die "Can't open > $out_page_number: $!";
    while (my $line = <$rh>) {
        $line =~ s/%TOTAL_PAGE_NUMBER/$total_pages/
            if $line =~ /%TOTAL_PAGE_NUMBER/;
        print $wh $line;
    }
    close $rh;
    close $wh;
    foreach (0..1) {
        system(sprintf "pdflatex %s", $out_page_number);
    }
    $out_page_number =~ s/.tex$/.pdf/;
    system( sprintf "pdftk %s multistamp %s output ../%s", $file_out_esame, $out_page_number, $file_out_esame );
} else {
    system( sprintf "cp %s ../", $file_out_esame);
}

chdir '../';

print "\nCleanup...";
system("rm -f spool/*");
print " done\n";

print "You find full pdf in full_exam.pdf\n";
