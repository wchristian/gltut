use strictures;

package tut1;

use OpenGL qw(
  GL_COLOR_BUFFER_BIT GL_ARRAY_BUFFER GL_FLOAT GL_FALSE GL_TRIANGLES
  GL_VERTEX_SHADER  GL_FRAGMENT_SHADER
  glCreateShaderObjectARB
  glShaderSourceARB_p
  glCompileShaderARB
  glGetInfoLogARB_p
  GL_LINK_STATUS
  glCreateProgramObjectARB
  glAttachObjectARB
  glLinkProgramARB
  glGetProgramivARB_p
  glDetachObjectARB
  glDeleteObjectARB
  GL_STATIC_DRAW
  glGenBuffersARB_p
  glBindBufferARB
  glBufferDataARB_p
  glViewport
  glClearColor
  glClear
  glUseProgramObjectARB
  glEnableVertexAttribArrayARB
  glVertexAttribPointerARB_c
  glDrawArrays
  glDisableVertexAttribArrayARB
  glutSwapBuffers
  glGenVertexArrays_p
  glBindVertexArray
  glAttachShader
  glDeleteShader
  GL_COMPILE_STATUS
  glGetShaderiv_p
  glGetShaderInfoLog_p
);
use OpenGL::Shader;

use Moo;

use lib '../framework';

with 'Framework';

has $_ => ( is => 'rw' ) for qw( vao theProgram positionBufferObject );

has strVertexShader => (
    is      => 'ro',
    default => sub {
        "
            #version 330
            layout(location = 0) in vec4 position;
            void main()
            {
               gl_Position = position;
            }
        ";
    }
);

has strFragmentShader => (
    is      => 'ro',
    default => sub {
        "
            #version 330
            out vec4 outputColor;
            void main()
            {
                outputColor = vec4( 1.0f, 1.0f, 1.0f, 1.0f );
            }
        ";
    }
);

has vertexPositions => (
    is      => 'ro',
    default => sub {
        return OpenGL::Array->new_list(
            GL_FLOAT,    #
            0.75,  0.75,  0, 1,
            0.75,  -0.75, 0, 1,
            -0.75, -0.75, 0, 1
        );
    }
);

__PACKAGE__->new->main;
exit;

sub display {
    my ( $self ) = @_;

    glClearColor( 0, 0, 0, 0 );
    glClear( GL_COLOR_BUFFER_BIT );

    glUseProgramObjectARB( $self->theProgram );

    glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
    glEnableVertexAttribArrayARB( 0 );
    glVertexAttribPointerARB_c( 0, 4, GL_FLOAT, GL_FALSE, 0, 0 );

    glDrawArrays( GL_TRIANGLES, 0, 3 );

    glDisableVertexAttribArrayARB( 0 );
    glUseProgramObjectARB( 0 );

    glutSwapBuffers();

    return;
}

sub defaults {
    my ( $self, $displayMode, $width, $height ) = @_;
    return $displayMode;
}

sub init {
    my ( $self ) = @_;

    $self->InitializeProgram;
    $self->InitializeVertexBuffer;

    $self->vao( glGenVertexArrays_p( 1 ) );
    glBindVertexArray( $self->vao );

    return;
}

sub InitializeProgram {
    my ( $self ) = @_;
    my @shaderList;

    push @shaderList, $self->CreateShader( GL_VERTEX_SHADER,   $self->strVertexShader );
    push @shaderList, $self->CreateShader( GL_FRAGMENT_SHADER, $self->strFragmentShader );

    my $theProgram = $self->CreateProgram( @shaderList );
    $self->theProgram( $theProgram );

    glDeleteShader( $_ ) for @shaderList;

    return;
}

sub InitializeVertexBuffer {
    my ( $self ) = @_;

    my $positionBufferObject = glGenBuffersARB_p( 1 );
    $self->positionBufferObject( $positionBufferObject );

=head1 insufficient documentation
    glBufferDataARB_c
=cut

    glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
    glBufferDataARB_p( GL_ARRAY_BUFFER, $self->vertexPositions, GL_STATIC_DRAW );
    glBindBufferARB( GL_ARRAY_BUFFER, 0 );

    return;
}

sub CreateShader {
    my ( $self, $eShaderType, $strShaderFile ) = @_;

    my $shader = glCreateShaderObjectARB( $eShaderType );

=head1 insufficient documentation
    glShaderSourceARB_c
=cut

    glShaderSourceARB_p( $shader, $strShaderFile );

    glCompileShaderARB( $shader );

    my $status = glGetShaderiv_p( $shader, GL_COMPILE_STATUS );
    if ( $status == GL_FALSE ) {
        my $stat = glGetShaderInfoLog_p( $shader );
        die "Shader link log: $stat" if $stat;
    }

    my $stat = glGetInfoLogARB_p( $shader );
    die "Shader compile log: $stat" if $stat;

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

sub reshape {
    my ( $self, $w, $h ) = @_;
    glViewport( 0, 0, $w, $h );
    return;
}

sub keyboard {
    my ( $key, $x, $y ) = @_;

    glutLeaveMainLoop() if $key == 27;

    return;
}
