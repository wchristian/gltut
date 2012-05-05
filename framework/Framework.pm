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
  GL_COMPILE_STATUS
  GL_FALSE
  glGetShaderiv_p
  glGetShaderInfoLog_p
  GL_LINK_STATUS
  glCreateShaderObjectARB
  glShaderSourceARB_p
  glCompileShaderARB
  glCreateProgramObjectARB
  glAttachShader
  glLinkProgramARB
  glGetProgramivARB_p
  glGetInfoLogARB_p
  glDetachObjectARB
);
use version 0.77;
use File::Slurp 'read_file';

use Moo::Role;

sub LoadShader {
    my ( $self, $eShaderType, $strShaderFilename ) = @_;

    my $strShaderFile = read_file( "data/$strShaderFilename" );

    my $shader = glCreateShaderObjectARB( $eShaderType );

=head1 insufficient documentation
    glShaderSourceARB_c
=cut

    glShaderSourceARB_p( $shader, $strShaderFile );
    glCompileShaderARB( $shader );

    my $status = glGetShaderiv_p( $shader, GL_COMPILE_STATUS );
    if ( $status == GL_FALSE ) {
        my $stat = glGetShaderInfoLog_p( $shader );
        die "Shader compile log: $stat" if $stat;
    }

    return $shader;
}

sub CreateProgram {
    my ( $self, @shaderList ) = @_;

    my $program = glCreateProgramObjectARB();

    glAttachShader( $program, $_ ) for @shaderList;

    glLinkProgramARB( $program );

    my $status = glGetProgramivARB_p( $program, GL_LINK_STATUS );
    if ( $status == GL_FALSE ) {
        my $stat = glGetInfoLogARB_p( $program );
        die "Shader link log: $stat" if $stat;
    }

    glDetachObjectARB( $program, $_ ) for @shaderList;

    return $program;
}

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
