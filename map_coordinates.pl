#!/usr/bin/env perl -w
use warnings;
use IO::File;
use Bio::EnsEMBL::Registry;

###############################################################
# test4.pl:
#  This is the program that takes in the coordintes in one assembly build and
#  converts it to the latest assembly (GRCh38)
#
# usage:
# 	perl test4.pl infile.txt
#
#
# contact : guruanth.katagi@gmail.com
# 26th Jan 2020
#  ################################################################
my $ensembl_genomes; 
my $species = "human"; 

my $filename = $ARGV[0];
chomp($filename);

my $registry = 'Bio::EnsEMBL::Registry';

my $host = 'ensembldb.ensembl.org';
my $port = 3306;
my $user = 'anonymous';

if ($ensembl_genomes) {
  $host = 'mysql-eg-publicsql.ebi.ac.uk';
  $port = 4157;
}

$registry->load_registry_from_db( '-host' => $host,
                                  '-port' => $port,
                                  '-user' => $user );

my $slice_adaptor = $registry->get_adaptor( $species, 'Core', 'Slice' );

open INFILE1, "< ./$filename" or die;

while ( my $line = <INFILE1>) {
  chomp($line);
  $line =~ s/\s*#.*$//;
  if ( $line =~ /^\s*$/ ) { next }
  	$line =~ s/^\s+|\s+$//;

  	# Check location string is correctly formatted
  	my $number_seps_regex = qr/\s+|,/;
  	my $separator_regex = qr/(?:-|[.]{2}|\:|_)?/;
  	my $number_regex = qr/[0-9, E]+/xms;
  	my $strand_regex = qr/[+-1]|-1/xms;

  	my $regex = qr/^(\w+) $separator_regex (\w+) $separator_regex ((?:\w|\.|_|-)+) \s* :? \s* ($number_regex)? $separator_regex ($number_regex)? $separator_regex ($strand_regex)? $/xms;

  	my ( $old_cs_name, $old_version, $old_sr_name, $old_start, $old_end, $old_strand );

  	if ( ($old_cs_name, $old_version, $old_sr_name, $old_start, $old_end, $old_strand) = $line =~ $regex) {
  	} else {
    	printf( "Malformed line:\n%s\n", $line );
    	next;
  }

  	# Get a slice for the old region (the region in the input file).
 	 my $old_slice = $slice_adaptor->fetch_by_region(
                                $old_cs_name, $old_sr_name, $old_start,
                                $old_end,  $old_strand,  $old_version);

  	# Complete possibly missing info.
  	$old_cs_name ||= $old_slice->coord_system_name();
  	$old_sr_name ||= $old_slice->seq_region_name();
  	$old_start   ||= $old_slice->start();
  	$old_end     ||= $old_slice->end();
  	$old_strand  ||= $old_slice->strand();
  	$old_version ||= $old_slice->coord_system()->version();

  	printf( "# %s\n", $old_slice->name() );

  	foreach my $segment ( @{ $old_slice->project('chromosome') } ) {
    	printf( "%s:%s:%s:%d:%d:%d,%s\n",
            $old_cs_name,
            $old_version,
            $old_sr_name,
            $old_start + $segment->from_start() - 1,
            $old_start + $segment->from_end() - 1,
            $old_strand,
            $segment->to_Slice()->name() );
  	}
  	print("\n");

} 
