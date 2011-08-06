package App::Minify;
use strict;
use warnings;
use Carp qw/carp croak/;
use JavaScript::Minifier::XS qw//;
use CSS::Minifier::XS qw//;
use Getopt::Long qw/GetOptionsFromArray/;
use Pod::Usage;
use Path::Class qw/dir file/;
use File::Spec;
use File::Basename qw/basename/;

our $VERSION = '0.02';

sub run {
    my ($class, @argv) = @_;

    my %config = $class->_process(@argv);

    if (!$config{out} && $config{quiet}) {
        carp "[WARN] No output, No run.";
    }
    else {
        $class->_minify(%config);
    }

    return 1;
}

sub _process {
    my ($self, @argv) = @_;

    my %config = $self->_config_read;

    $config{backup_dir} = $self->_temp_directory() unless $config{backup_dir};

    pod2usage(2) unless @argv;

    GetOptionsFromArray(
        \@argv,
        's|src-file=s@'  => \$config{src},
        'css'            => \$config{css},
        'js|javascript'  => \$config{js},
        'o|out-file=s'   => \$config{out},
        'b|backup'       => \$config{backup},
        'q|quiet'        => \$config{quiet},
        'h|help'         => sub {
            pod2usage(1);
        },
        'v|version'     => sub {
            require App::Minify;
            print "minify v$App::Minify::VERSION\n";
            exit 1;
        },
    ) or pod2usage(2);

    push @{$config{src}}, @argv;

    croak "[ERROR] specify src file" unless @{$config{src}};

    return %config;
}

sub _config_read {
    my $self = shift;

    my $filename = $self->_config_file;

    return unless -e $filename;

    open my $fh, '<', $filename
        or croak "[ERROR] couldn't open config file $filename: $!\n";

    my %config;
    while (<$fh>) {
        chomp;
        next if /\A\s*\Z/sm;
        if (/\A(\w+):\s*(.+)\Z/sm) { $config{$1} = $2; }
    }

    return %config;
}

sub _config_file {
    my $self = shift;

    my $configdir = $ENV{'MINIFY_DIR'} || '';

    if ( !$configdir && $ENV{'HOME'} ) {
        $configdir = dir( $ENV{'HOME'}, '.minify' );
    }

    return file( $configdir, 'config' );
}

sub _temp_directory {
    my $self = shift;

    my $tmpdir = File::Spec->tmpdir or croak '[ERROR] No tmpdir on this system';
    return $tmpdir;
}

sub _backup {
    my ($self, $src_file, $backup_dir) = @_;

    my $lines = $self->_slurp($src_file);
    my $backup_file = file(
        $backup_dir,
        time. '_'.  file($src_file)->basename,
    );
    $self->_write_file($backup_file, $lines);

    return $backup_file;
}

sub _slurp {
    my ($self, $file) = @_;

    open my $fh, '<', $file or croak "[ERROR] file:$file $!";
    my $lines = do { local $/; <$fh> };
    close $fh;

    return $lines;
}

sub _write_file {
    my ($self, $file, $line) = @_;

    open my $fh, '>', $file or croak "[ERROR] file:$file $!";
    print $fh $line;
    close $fh;
}

sub _minify {
    my ($self, %config) = @_;

    if ($config{backup} && $config{out} && -e $config{out}) {
        $self->_backup($config{out}, $config{backup_dir});
    }

    my $lf = '';
    my $minified = '';
    for my $file (@{$config{src}}) {
        my $lines = $self->_slurp($file);
        $minified .= $lf if $minified;
        if ($config{css}) {
            $minified .= CSS::Minifier::XS::minify($lines);
        }
        elsif ($config{js}) {
            $minified .= JavaScript::Minifier::XS::minify($lines);
        }
        elsif ($file =~ m!\.css$!) {
            $minified .= CSS::Minifier::XS::minify($lines);
        }
        elsif ($file =~ m!\.js$!) {
            $minified .= JavaScript::Minifier::XS::minify($lines);
        }
        else {
            carp "[WARN] cuold not detect $file. so did not minify it.".
                    "specify what kind of file css or js. check help for detail.";
            $minified .= $lines;
        }
        $lf = "\n";
    }

    $self->_write_file($config{out}, $minified) if $config{out};

    print "$minified\n" unless $config{quiet};
}

1;

__END__

=head1 NAME

App::Minify - the minifier for JavaScript and CSS


=head1 SYNOPSIS

    use App::Minify;
    App::Minify->run(@ARGV);

=head1 DESCRIPTION

App::Minify is the minifier for JavaScript and CSS.


=head1 REPOSITORY

App::Minify is hosted on github
<http://github.com/bayashi/App-Minify>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<minify>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
