use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Sledge::Plugin::CSRFDefender',
    'VERSION_FROM' => 'lib/Sledge/Plugin/CSRFDefender.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Test::More => 0.32,
    },
);
