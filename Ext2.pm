package Filesys::Ext2;
require 5;
use strict;
use vars q($VERSION);
$VERSION = 0.11;
local($_);

#XXX You may want to change this default if you installed
#XXX e2fsprogs in a non-standard location
local $ENV{PATH} = '/usr/bin/';

sub import{
  no strict 'refs';
  my $caller = caller(1);
  shift;

  @_ = map { $_ eq ':all' ? qw(chattr lsattr stat lstat calcSymMask) : $_ } @_;
  foreach( @_ ){
    if(ref($_) eq 'HASH'){
      if(exists($_->{PATH})){
	$ENV{PATH} = $_->{PATH};
      }
    }
    else{
     *{$caller."::$_"} = \&{'Filesys::Ext2::'.$_};
    }
  }
}

sub chattr($$;@){
    my($mask, @files) = @_;
    my @mask = $mask =~ /^\d+/ ?
	_calcSymMask($mask) : split(/\s+|(?=[+-])/, $mask);
    return system("chattr", @mask, @files);
}

sub lsattr($) {
    my($file,$mode) = @_;
    my $dir = -d $file ? '-d' : '';
    open(my $IN, "lsattr $dir $file |") || return 0;
    my $mask = _calcBitMask((split(/\s+/, readline($IN)))[0]);
    return wantarray ? _calcSymMask($mask) : $mask;
}

sub stat($) {
    my $lsattr = scalar lsattr($_[0]);
    my $stat = CORE::stat($_[0]);
    return wantarray ? (CORE::stat(_), $lsattr) : $stat && ($lsattr ? 1 : 0);
}

sub lstat($) {
    my $lsattr = scalar lsattr($_[0]);
    my $stat = CORE::lstat($_[0]);
    return wantarray ? (CORE::lstat(_), $lsattr) : $stat && ($lsattr ? 1 : 0);
}

sub _calcBitMask($) {
    my $bitmask;
    $bitmask += (index($_[0], 's')>=0) * 0x0001;
    $bitmask += (index($_[0], 'u')>=0) * 0x0002;
    $bitmask += (index($_[0], 'c')>=0) * 0x0004;
    $bitmask += (index($_[0], 'S')>=0) * 0x0008;
    $bitmask += (index($_[0], 'i')>=0) * 0x0010;
    $bitmask += (index($_[0], 'a')>=0) * 0x0020;
    $bitmask += (index($_[0], 'd')>=0) * 0x0040;
    $bitmask += (index($_[0], 'A')>=0) * 0x0080;
}

sub _calcSymMask($) {
    my @mask;
    push @mask, $_[0] & 0x0001 ? '+s' : '-s';
    push @mask, $_[0] & 0x0002 ? '+u' : '-u';
    push @mask, $_[0] & 0x0004 ? '+c' : '-c';
    push @mask, $_[0] & 0x0008 ? '+S' : '-S';
    push @mask, $_[0] & 0x0010 ? '+i' : '-i';
    push @mask, $_[0] & 0x0020 ? '+a' : '-a';
    push @mask, $_[0] & 0x0040 ? '+d' : '-d';
    push @mask, $_[0] & 0x0080 ? '+A' : '-A';
    return @mask;
}

sub calcSymMask($) {
    my @F = _calcSymMask($_[0]);
    return @F if wantarray;
    
    $_ = join('', @F);
    y/+//d;
    s/(?<=-)[sucSiadA]//g;
    return $_;
}

1;
__END__
=pod

=head1 NAME

Filesys::Ext2 - Interface to e2fs filesystem attributes

=head1 SYNOPSIS

  use Filesys::Ext2 qw(:all);
  $mode = lsattr("/etc/passwd");
  chattr("+aud", "/etc/passwd");
  #or equivalently
  #chattr($mode|0x0062, "/etc/passwd");

=head1 DESCRIPTION

You may specify the path of the e2fsprogs upon use

  use Filesys::Ext2 {PATH=>'/path/to/binaries'};

Otherwise the module will use the default path /usr/bin/

=over 8

=item chattr($mask, @files)

Change the mode of I<@files> to match I<$mask>.
I<$mask> may be a symbolic mode or a bitmask.

Returns 0 upon failure, check $?.

=item lsattr($file)

In list context it returns a list containing symbols
representing the symbolic mode of I<$file>.
In scalar context it returns a bitmask.

Returns 0 upon failure, check $?.

=item lstat($file)

Same as C<CORE::lstat>, but appends the numerical attribute bitmask.

Returns 0 upon failure, check $?.

=item stat($file)

Same as C<CORE::stat>, but appends the numerical attribute bitmask.

Returns 0 upon failure, check $?.

=item calcSymMask($mask)

Accepts a bitmask and returns the symbolic mode.
In list context it returns a symbol list like lsattr,
in scalar context it returns a string that matches the
-------- region of B<lsattr(1)>
(akin to that of B<ls -l> e.g. drwxr-x---)

=back

=head1 SEE ALSO

B<chattr(1)>, B<lsattr(1)>

=head1 NOTES

Of course, this would be more efficient if it were an XSUB.

The bit mappings for attributes, from ext2_fs.h

=over

=item 0x0001 == s

Secure deletion

=item 0x0002 == u

Undelete

=item 0x0004 == c

Compress file

=item 0x0008 == S

Synchronous updates

=item 0x0010 == i

Immutable file

=item 0x0020 == a

Writes to file may only append

=item 0x0040 == d

Do not dump file

=item 0x0080 == A

Do not update atime

=back

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=cut
