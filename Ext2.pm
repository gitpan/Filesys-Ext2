package FileSys::Ext2;
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(chattr lsattr stat lstat calcSymMask);
use strict;
my $VERSION = '0.04';

#You may need to change this if you installed e2fsprogs in a weird location;
local $ENV{PATH} = '/usr/bin/';

=pod

=head1 NAME

FileSys::Ext2 - Interface to e2fs filesystem attributes

=head1 SYNOPSIS

        use FileSys::Ext2 qw(chattr lsattr);
        $mode = lsattr("/etc/passwd");
        chattr($mode+0003, "/etc/passwd");

=head1 DESCRIPTION


=over 8

=item C<chattr($mask, @files)>

Change the mode of C<@files> to match C<$mask>.
C<$mask> may be a symbolic mode or a bitmask.

=item C<lsattr($file)>

In list context it returns a list containing symbols
representing the symbolic mode of C<$file>.
In scalar context it returns a bitmask.

=item C<lstat($file)>

Same as CORE::lstat, but appends the numerical attribute bitmask.

=item C<stat($file)>

Same as CORE::stat, but appends the numerical attribute bitmask.

=item C<calcSymMask>

Accepts a bitmask and returns the symbolic mode.
In list context it returns a symbol list like lsattr,
in scalar mode it returns a string that matches the
-------- region of lsattr
(akin to that of ls -l e.g. drwxr-x---)

=back

=head1 SEE ALSO

chattr(1), lsattr(1)

=head1 NOTES

Of course, this would be more efficient if it were an XSUB.

The bit mappings for attributes, from ext2_fs.h

        s #define EXT2_SECRM_FL           0x00000001 /* Secure deletion */
        u #define EXT2_UNRM_FL            0x00000002 /* Undelete */
        c #define EXT2_COMPR_FL           0x00000004 /* Compress file */
        S #define EXT2_SYNC_FL            0x00000008 /* Synchronous updates */
        i #define EXT2_IMMUTABLE_FL       0x00000010 /* Immutable file */
        a #define EXT2_APPEND_FL          0x00000020 /* writes to file may only append */
        d #define EXT2_NODUMP_FL          0x00000040 /* do not dump file */
        A #define EXT2_NOATIME_FL         0x00000080 /* do not update atime */

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>, <webmaster@pthbb.org>

=cut

sub chattr($$;@){
    my($mask, @files) = @_;
    my @mask = $mask =~ /^\d+/ ?
	_calcSymMask($mask) : split(/(?:\s+)|(?=[+-])/, $mask);
    return system("chattr", @mask, @files);
}

sub lsattr($) {
    my($file,$mode) = @_;
    my $dir = -d $file ? '-d' : '';
    open(IN, "lsattr $dir $file |") || return("$!");
    local $_ = <IN>;
    my $mask = _calcBitMask((split(/\s+/, $_))[0]);
    return wantarray ? _calcSymMask($mask) : $mask;
}

sub stat($) {
    return stat($_[0]), scalar lsattr($_[0]);
}

sub lstat($) {
    return lstat($_[0]), scalar lsattr($_[0]);
}

sub _calcBitMask($) {
    my $mask = shift();
    my $bitmask;
    $bitmask += ($mask =~ /s/) * 0x0001;
    $bitmask += ($mask =~ /u/) * 0x0002;
    $bitmask += ($mask =~ /c/) * 0x0004;
    $bitmask += ($mask =~ /S/) * 0x0008;
    $bitmask += ($mask =~ /i/) * 0x0010;
    $bitmask += ($mask =~ /a/) * 0x0020;
    $bitmask += ($mask =~ /d/) * 0x0040;
    $bitmask += ($mask =~ /A/) * 0x0080;
}

sub _calcSymMask($) {
    my $bitmask = shift();
    my @mask;
    printf "Bitmask %s %o\n", $bitmask, $bitmask;
    push @mask, $bitmask & 0x0001 ? '+s' : '-s';
    push @mask, $bitmask & 0x0002 ? '+u' : '-u';
    push @mask, $bitmask & 0x0004 ? '+c' : '-c';
    push @mask, $bitmask & 0x0008 ? '+S' : '-S';
    push @mask, $bitmask & 0x0010 ? '+i' : '-i';
    push @mask, $bitmask & 0x0020 ? '+a' : '-a';
    push @mask, $bitmask & 0x0040 ? '+d' : '-d';
    push @mask, $bitmask & 0x0080 ? '+A' : '-A';
    return @mask;
}

sub calcSymMask($) {
    my @F;
    @F = _calcSymMask($_[0]);
    if( wantarray ){
        local $_;
	$_ = join('', @F);
	s/-./-/g;
	tr/+//d; }
    return @F;
}

1;
