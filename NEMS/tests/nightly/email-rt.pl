#! /usr/bin/env perl

use Sys::Hostname qw{hostname};
use strict;
use warnings;
use POSIX qw{ctime};
use Getopt::Std qw{getopts};

########################################################################

# Default values for options so that usage() can print them.

my $max_age_in_hours=72;
my $email_list='';
my $test_description='NEMS Nightly Test';
my $test_url='http://www.emc.ncep.noaa.gov/projects/rt';

########################################################################

sub usage {
    my $why=shift @_;
    print STDERR "Format: $0 [options] -e email\@place,email2\@anotherplace,... /path/to/app/platform/regtest.txt [...]\n";
    print STDERR "  /path/to/app/platform/regtest.txt [...]\n";
    print STDERR "    One or more regtest.txt files, which must be inside a particular directory structure:\n";
    print STDERR "        AppName/PlatformName/regtest.txt\n";
    print STDERR "  -e email\@place,email2\@anotherplace,...\n";
    print STDERR "    Mandatory.  List of email addresses separated by commas.\n";
    print STDERR "  -t what\n";
    print STDERR "    Why is this test being run?  Default: $test_description\n";
    print STDERR "  -m 999\n";
    print STDERR "    Tests older than this number of hours are considered \"old\".\n";
    print STDERR "  -a\n";
    print STDERR "    Always send an email.  By default, an email is only sent if there are failed or old tests.\n";
    print STDERR "  -u $test_url\n";
    print STDERR "    The url for detailed test results.\n";
    if($why) {
        print(STDERR "\n$why\n");
        exit(1);
    }
    exit(0);
};

sub HELP_MESSAGE {
    usage();
};
sub VERSION_MESSAGE {
    print "email-rt.pl 1.0.0\n";
};

########################################################################

# Argument parsing

my %opts;
$Getopt::Std::STANDARD_HELP_VERSION=1;
getopts('m:e:at:',\%opts);

usage("ABORT: specify at least one regtest.txt file") unless $#ARGV>=0;

$email_list=join(" ",split( /,/ , "$opts{e}" )) if($opts{e});
usage("ABORT: specify the email list in the \"-e\" option") unless $email_list;

$test_description="$opts{t}" if defined($opts{t});
$max_age_in_hours=1*$opts{m} if defined($opts{m});
$test_url="$opts{u}" if defined($opts{u});

########################################################################

# Main execution loop

my $failed=undef;
my $old=undef;

my @top;
my @body;
my @fail;
my @pass;
my @oldpass;

foreach my $file (@ARGV) {
    if( $file!~ m:.*/(\S+)/(\S+)/(\S+)$: ) {
        warn("$file: cannot parse filename.  I do not know the platform or app.  Ignoring this file.");
        next;
    }
    my $app=$1;
    my $platform=$2;
    my $content='';
    my @lines=();
    do {
        open(my $fh,"<",$file) or die "$file: cannot open: $!";
        @lines=<$fh>;
        close($fh);
    };

    my $start=0;
    my $end=0;
    my $result="(**unspecified**)";
    my @repo=();
    my @log=();
    my $mode="";
    my $dir="";

    foreach (@lines) {
        chomp;

        if($dir eq "" && $_ =~ m:(/\S+rtgen.\d+):) {
            $dir=$1;
        }

        if($mode =~ /^REPO/) {
            if(/^===!REGTEST/) {
                $mode="";
            }
            if($mode eq "REPO") {
                $mode="REPO1";
            } elsif($mode eq "REPO1") {
                $mode="REPO2";
                push @repo,$_;
            }
            next;
        }



        if($mode eq "LOG") {
            if(/^===!REGTEST/) {
                $mode="";
            } elsif($_ =~ /^(build|test|workflow|regression)/i || $_ =~ /^\s+Test /) {
                push @log,$_;
            }
            next;
        }

        if(/^===!REGTEST BEGIN \+(\d+)/) {
            $start=$1;
        } elsif(/^===!REGTEST END \+(\d+)/) {
            $end=$1;
        } elsif(/^===!REGTEST REPO BEGIN/) {
            $mode="REPO";
        } elsif(/^===!REGTEST LOG BEGIN/) {
            $mode="LOG";
        } elsif(/^===!REGTEST RESULT (\S+)/) {
            $result=$1;
        }
    } # end loop over lines in regtest.txt for this app+platform

    my $age_in_hours=sprintf("%.2f",(time()-$end)/3600.0);
    if($result eq "PASS") {
        if($age_in_hours>$max_age_in_hours) {
            push @oldpass, "$app on $platform passed $age_in_hours hours ago.";
        } else {
            push @pass, "$app on $platform passed $age_in_hours hours ago.";
        }
    } else {
        push @fail, "$app on $platform run $age_in_hours hours ago had result: $result";
        push(@fail,"      --> in $dir") if $dir;
    }

    push @body, "$app on $platform run $age_in_hours hours ago had result: $result";
    push(@body,"      --> in $dir") if $dir;
    push @body, "Repo info: ".join("\n",@repo);
    push @body, join("\n",@log);
    push @body, "\n\n";

    $failed=1 if($result ne "PASS");
    $old=1 if($age_in_hours > $max_age_in_hours);
} # end loop over all regtest.txt files

########################################################################

# Generate email content:

my $ctime=POSIX::ctime(time());
chomp $ctime;
my $subject="$test_description at $ctime";

$subject="OLD $subject" if $old;
$subject="FAILED $subject" if $failed;

if(@fail) {
    push @top,"Failed tests:\n";
    push @top,@fail;
    push @top,'';
}
if(@oldpass) {
    push @top,"OLD Test Results:\n";
    push @top,@oldpass;
    push @top,'';
}
if(@pass) {
    push @top,"Tests that passed recently:\n";
    push @top,@pass;
    push @top,'';
}

my $hostname=hostname();
my $contents="Results of the $test_description at $ctime, emailed to you from $ENV{USER}\@$hostname.  For detailed information, go to the $test_description site at:\n\n    $test_url\n\n".join("\n",@top)."\n\nDetails:\n\n".join("\n",@body)."\n\nSincerely,\nYour dear and loyal friend, the $test_description\n";

########################################################################

# Send email (or not)

if(!$opts{a} && !$old && !$failed) {
    print("All tests passed recently.  Will not send an email unless -a is specified.\n");
    exit(0);
}

my $mail_command="mail -s '$subject' $email_list";
print("Mail command is $mail_command <<EOT\n");
print($contents."\nEOT\n");

open(MAIL,"|$mail_command") or die "Cannot run $mail_command: $!";
print MAIL $contents;
close(MAIL) or die "Command returned non-zero status: $mail_command: $? $!";
