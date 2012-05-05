use strictures;

package Framework;

use 5.010;

use OpenGL qw(
  glutInit
  GLUT_DOUBLE  GLUT_ALPHA  GLUT_DEPTH  GLUT_STENCIL
  glutInitDisplayMode  glutInitWindowSize  glutInitWindowPosition  glutCreateWindow
  glutSetOption
  GLUT_ACTION_ON_WINDOW_CLOSE  GLUT_ACTION_CONTINUE_EXECUTION
  glGetString  GL_VERSION
  glutDestroyWindow
  glutDisplayFunc
  glutReshapeFunc
  glutKeyboardFunc
  glutMainLoop
  glutInitContextVersion
  GLUT_CORE_PROFILE
  GLUT_DEBUG
  glutInitContextProfile
  glutInitContextFlags
);
use version 0.77;

use Moo::Role;

sub main {
    my ( $self ) = @_;
    glutInit();

    my ( $width, $height ) = ( 500, 500 );
    my $displayMode = GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH | GLUT_STENCIL;
    $displayMode = $self->defaults( $displayMode, \$width, \$height );

    glutInitDisplayMode( $displayMode );

    glutInitContextVersion( 3, 3 );
    glutInitContextProfile( GLUT_CORE_PROFILE );
    glutInitContextFlags( GLUT_DEBUG );

    glutInitWindowSize( $width, $height );
    glutInitWindowPosition( 300, 200 );

    my $window = glutCreateWindow( $0 );

    glutSetOption( GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_CONTINUE_EXECUTION );

    my $version = version->parse( glGetString( GL_VERSION ) );
    if ( $version < 3.003 ) {
        say "Your OpenGL version is $version. You must have at least OpenGL 3.3 to run this tutorial.";
        glutDestroyWindow( $window );
        return;
    }

=head1 unsupported
    if(glext_ARB_debug_output)
    {
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB);
        glDebugMessageCallbackARB(DebugFunc, (void*)15);
    }
=cut

    $self->init;

    glutDisplayFunc( sub  { $self->display( @_ ) } );
    glutReshapeFunc( sub  { $self->reshape( @_ ) } );
    glutKeyboardFunc( sub { $self->keyboard( @_ ) } );
    glutMainLoop();

    return;
}

1;
