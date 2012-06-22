use strictures;

package AspectRatio;

use lib '../framework';
use OpenGL::Debug qw(
  GL_COLOR_BUFFER_BIT GL_ARRAY_BUFFER GL_FLOAT GL_FALSE GL_TRIANGLES
  GL_VERTEX_SHADER  GL_FRAGMENT_SHADER
  GL_STATIC_DRAW
  glGenBuffersARB_p
  glBindBufferARB
  glBufferDataARB_p
  glGenVertexArrays_p
  glBindVertexArray
  glViewport
  glClearColor
  glClear
  glUseProgramObjectARB
  glEnableVertexAttribArrayARB
  glVertexAttribPointerARB_c
  glDrawArrays
  glDisableVertexAttribArrayARB
  glutSwapBuffers
  glutPostRedisplay
  GLUT_ELAPSED_TIME
  glutGet
  glGetUniformLocationARB_p
  glUniform2fARB
  GL_CULL_FACE
  GL_BACK
  GL_CW
  glEnable
  glCullFace
  glFrontFace
  glUniform1fARB
  glUniformMatrix4fvARB_p
  glGetUniformfvARB_p
  glGetError
  gluErrorString
);
use OpenGL::Shader;

use Moo;

use lib '../framework';

with 'Framework';

has $_ => ( is => 'rw' ) for qw( theProgram offsetUniform perspectiveMatrixUnif );
has perspectiveMatrix => ( is => 'rw', default => sub { [] } );
has fFrustumScale     => ( is => 'rw', default => sub { 1 } );

has vertexData => (
	is      => 'ro',
	default => sub {
		return OpenGL::Array->new_list(
			GL_FLOAT,    #
			0.25,  0.25,  -1.25, 1.0,
			0.25,  -0.25, -1.25, 1.0,
			-0.25, 0.25,  -1.25, 1.0,

			0.25,  -0.25, -1.25, 1.0,
			-0.25, -0.25, -1.25, 1.0,
			-0.25, 0.25,  -1.25, 1.0,

			0.25,  0.25,  -2.75, 1.0,
			-0.25, 0.25,  -2.75, 1.0,
			0.25,  -0.25, -2.75, 1.0,

			0.25,  -0.25, -2.75, 1.0,
			-0.25, 0.25,  -2.75, 1.0,
			-0.25, -0.25, -2.75, 1.0,

			-0.25, 0.25,  -1.25, 1.0,
			-0.25, -0.25, -1.25, 1.0,
			-0.25, -0.25, -2.75, 1.0,

			-0.25, 0.25,  -1.25, 1.0,
			-0.25, -0.25, -2.75, 1.0,
			-0.25, 0.25,  -2.75, 1.0,

			0.25, 0.25,  -1.25, 1.0,
			0.25, -0.25, -2.75, 1.0,
			0.25, -0.25, -1.25, 1.0,

			0.25, 0.25,  -1.25, 1.0,
			0.25, 0.25,  -2.75, 1.0,
			0.25, -0.25, -2.75, 1.0,

			0.25,  0.25, -2.75, 1.0,
			0.25,  0.25, -1.25, 1.0,
			-0.25, 0.25, -1.25, 1.0,

			0.25,  0.25, -2.75, 1.0,
			-0.25, 0.25, -1.25, 1.0,
			-0.25, 0.25, -2.75, 1.0,

			0.25,  -0.25, -2.75, 1.0,
			-0.25, -0.25, -1.25, 1.0,
			0.25,  -0.25, -1.25, 1.0,

			0.25,  -0.25, -2.75, 1.0,
			-0.25, -0.25, -2.75, 1.0,
			-0.25, -0.25, -1.25, 1.0,

			0.0, 0.0, 1.0, 1.0,
			0.0, 0.0, 1.0, 1.0,
			0.0, 0.0, 1.0, 1.0,

			0.0, 0.0, 1.0, 1.0,
			0.0, 0.0, 1.0, 1.0,
			0.0, 0.0, 1.0, 1.0,

			0.8, 0.8, 0.8, 1.0,
			0.8, 0.8, 0.8, 1.0,
			0.8, 0.8, 0.8, 1.0,

			0.8, 0.8, 0.8, 1.0,
			0.8, 0.8, 0.8, 1.0,
			0.8, 0.8, 0.8, 1.0,

			0.0, 1.0, 0.0, 1.0,
			0.0, 1.0, 0.0, 1.0,
			0.0, 1.0, 0.0, 1.0,

			0.0, 1.0, 0.0, 1.0,
			0.0, 1.0, 0.0, 1.0,
			0.0, 1.0, 0.0, 1.0,

			0.5, 0.5, 0.0, 1.0,
			0.5, 0.5, 0.0, 1.0,
			0.5, 0.5, 0.0, 1.0,

			0.5, 0.5, 0.0, 1.0,
			0.5, 0.5, 0.0, 1.0,
			0.5, 0.5, 0.0, 1.0,

			1.0, 0.0, 0.0, 1.0,
			1.0, 0.0, 0.0, 1.0,
			1.0, 0.0, 0.0, 1.0,

			1.0, 0.0, 0.0, 1.0,
			1.0, 0.0, 0.0, 1.0,
			1.0, 0.0, 0.0, 1.0,

			0.0, 1.0, 1.0, 1.0,
			0.0, 1.0, 1.0, 1.0,
			0.0, 1.0, 1.0, 1.0,

			0.0, 1.0, 1.0, 1.0,
			0.0, 1.0, 1.0, 1.0,
			0.0, 1.0, 1.0, 1.0,
		);
	}
);

has $_ => ( is => 'rw' ) for qw( vertexBufferObject vao );

__PACKAGE__->new->main;
exit;

sub InitializeProgram {
	my ( $self ) = @_;
	my @shaderList;

	push @shaderList, $self->LoadShader( GL_VERTEX_SHADER,   "MatrixPerspective.vert" );
	push @shaderList, $self->LoadShader( GL_FRAGMENT_SHADER, "StandardColors.frag" );

	$self->theProgram( $self->CreateProgram( @shaderList ) );

	$self->offsetUniform( glGetUniformLocationARB_p( $self->theProgram, "offset" ) );

	$self->perspectiveMatrixUnif( glGetUniformLocationARB_p( $self->theProgram, "perspectiveMatrix" ) );

	my ( $fzNear, $fzFar ) = ( 0.5, 3.0 );

	$self->perspectiveMatrix->[$_] = 0 for 0 .. 16;

	$self->perspectiveMatrix->[0]  = $self->fFrustumScale;
	$self->perspectiveMatrix->[5]  = $self->fFrustumScale;
	$self->perspectiveMatrix->[10] = ( $fzFar + $fzNear ) / ( $fzNear - $fzFar );
	$self->perspectiveMatrix->[14] = ( 2 * $fzFar * $fzNear ) / ( $fzNear - $fzFar );
	$self->perspectiveMatrix->[11] = -1.0;

	glUseProgramObjectARB( $self->theProgram );

	glUniformMatrix4fvARB_p( $self->perspectiveMatrixUnif, GL_FALSE, @{ $self->perspectiveMatrix } );

	glUseProgramObjectARB( 0 );

	return;
}

sub InitializeVertexBuffer {
	my ( $self ) = @_;

	$self->vertexBufferObject( glGenBuffersARB_p( 1 ) );

=head1 insufficient documentation
	glBufferDataARB_c
=cut

	glBindBufferARB( GL_ARRAY_BUFFER, $self->vertexBufferObject );
	glBufferDataARB_p( GL_ARRAY_BUFFER, $self->vertexData, GL_STATIC_DRAW );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

	return;
}

sub init {
	my ( $self ) = @_;

	$self->InitializeProgram;
	$self->InitializeVertexBuffer;

	$self->vao( glGenVertexArrays_p( 1 ) );
	glBindVertexArray( $self->vao );

	glEnable( GL_CULL_FACE );
	glCullFace( GL_BACK );
	glFrontFace( GL_CW );

	return;
}

sub display {
	my ( $self ) = @_;

	glClearColor( 0, 0, 0, 0 );
	glClear( GL_COLOR_BUFFER_BIT );

	glUseProgramObjectARB( $self->theProgram );

	glUniform2fARB( $self->offsetUniform, 1.5, 0.5 );

	my $colorData = $self->vertexData->elements / 2 * 4;
	glBindBufferARB( GL_ARRAY_BUFFER, $self->vertexBufferObject );
	glEnableVertexAttribArrayARB( 0 );
	glEnableVertexAttribArrayARB( 1 );
	glVertexAttribPointerARB_c( 0, 4, GL_FLOAT, GL_FALSE, 0, 0 );
	glVertexAttribPointerARB_c( 1, 4, GL_FLOAT, GL_FALSE, 0, $colorData );

	glDrawArrays( GL_TRIANGLES, 0, 36 );

	glDisableVertexAttribArrayARB( 0 );
	glDisableVertexAttribArrayARB( 1 );
	glUseProgramObjectARB( 0 );

	glutSwapBuffers();
	glutPostRedisplay();

	return;
}

sub reshape {
	my ( $self, $w, $h ) = @_;

	$self->perspectiveMatrix->[0] = $self->fFrustumScale / ( $w / $h );
	$self->perspectiveMatrix->[5] = $self->fFrustumScale;

	glUseProgramObjectARB( $self->theProgram );
	glUniformMatrix4fvARB_p( $self->perspectiveMatrixUnif, GL_FALSE, @{ $self->perspectiveMatrix } );
	glUseProgramObjectARB( 0 );

	glViewport( 0, 0, $w, $h );
	return;
}

sub keyboard {
	my ( $key, $x, $y ) = @_;

	glutLeaveMainLoop() if $key == 27;

	return;
}

sub defaults {
	my ( $self, $displayMode, $width, $height ) = @_;
	return $displayMode;
}
