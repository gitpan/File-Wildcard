use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'File::Wildcard',
    VERSION_FROM => 'lib/File/Wildcard.pm', # finds $VERSION
    AUTHOR       => 'I. Williams (ivorw-file-wildcard@xemaps.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Params::Validate' => 0,
                    },
);
