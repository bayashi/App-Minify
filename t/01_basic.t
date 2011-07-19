use strict;
use warnings;
use Test::More 0.88;
use Test::Output;

use App::Minify;

can_ok(
    'App::Minify',
    qw/
        run
        _process _config_read _config_file _temp_directory
        _backup _slurp _write_file _minify
    /
);

stdout_is(
    sub { App::Minify->run('-s' => 'static/style.css'); },
    "#foo{margin:16px;padding:8px;color:#FFFFFF}#bar{color:#999999}\n",
    'minify style.css'
);

stdout_is(
    sub { App::Minify->run('-s' => 'static/base.js'); },
    qq|var foo=123;var bar='hoge';var baz={zigorou:"Toru",hidek:"Hideo",xaicron:null,};\n|,
    'minify base.js'
);

my $minified = 'minified_test.css';
{
    stdout_is(
        sub {
            App::Minify->run(
                '-s' => 'static/style.css',
                '-o' => $minified,
            );
        },
        "#foo{margin:16px;padding:8px;color:#FFFFFF}#bar{color:#999999}\n",
        'minify style.css and output to file'
    );
    is -e $minified, 1, "output file $minified is exists";
    is(
        _slurp($minified),
        "#foo{margin:16px;padding:8px;color:#FFFFFF}#bar{color:#999999}",
        "output file"
    );
    unlink $minified if -e $minified;
}

done_testing;


sub _slurp {
    my $file = shift;

    open my $fh, '<', $file or die "file:$file $!";
    my $lines = do { local $/; <$fh> };
    close $fh;

    return $lines;
}
