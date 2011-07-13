use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Minify',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/Minify.pm',
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'Carp' => 0,
    },
    add_to_cleanup      => [ 'App-Minify-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-Minify'
      }
    },
);

$builder->create_build_script();
