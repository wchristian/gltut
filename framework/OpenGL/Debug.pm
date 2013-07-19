use strictures;

package OpenGL::Debug;

use Sub::Install 'install_sub';
use OpenGL qw( GL_NO_ERROR glGetError gluErrorString );
use Carp 'confess';
use Sub::Name 'subname';
use Carp::Always;

my $is_in_Begin;

sub import {
    my ( $class, @imports ) = @_;

    my @tags = grep { /^:/ } @imports;
    $_ =~ s/^:// for @tags;
    @imports = grep { !/^:/ } @imports;
    push @imports, map @{ $OpenGL::EXPORT_TAGS{$_} }, @tags;

    my %uniq_imports = map { $_ => 1 } @imports;

    my %all_consts = map { $_ => 1 } map { @{ $OpenGL::EXPORT_TAGS{$_} } } grep { /const/ } keys %OpenGL::EXPORT_TAGS;

    my $glut_init_skips = "glut(MainLoop|Init(|DisplayMode|Context(Version|Profile|Flags)|Window(Size|Position)))";

    my @non_debugs = grep { $all_consts{$_} or /^($glut_init_skips|glutCreateWindow)$/ } keys %uniq_imports;
    my @functions = grep { !$all_consts{$_} and !/^($glut_init_skips|glutCreateWindow)$/ } keys %uniq_imports;

    my @caller = caller;
    install_sub( { code => \&{"OpenGL::$_"},   into => $caller[0], as => $_ } ) for @non_debugs;
    install_sub( { code => make_wrapped( $_ ), into => $caller[0], as => $_ } ) for @functions;

    return;
}

sub make_wrapped {
    my ( $function ) = @_;

    my $code = \&{"OpenGL::$function"};

    return subname $function, sub {
        my $entry_error = ( !$is_in_Begin ) ? glGetError() : 0;
        confess formatted_error( "entry", $entry_error ) if $entry_error != GL_NO_ERROR;

        my $wantarray = wantarray;

        my @ret;
        if ( $wantarray ) {
            @ret = $code->( @_ );
        }
        elsif ( defined $wantarray ) {
            $ret[0] = $code->( @_ );
        }
        else {
            $code->( @_ );
        }
        $is_in_Begin = 1 if $function eq 'glBegin';
        $is_in_Begin = 0 if $function eq 'glEnd';

        my $exit_error = ( !$is_in_Begin ) ? glGetError() : 0;
        confess formatted_error( "exit", $exit_error ) if $exit_error != GL_NO_ERROR;

        return $wantarray ? @ret : $ret[0];
    };
}

sub formatted_error {
    my ( $where, $e ) = @_;
    my $error_string = gluErrorString( $e );
    return "GL ERROR at $where: '$error_string'";
}

1;
