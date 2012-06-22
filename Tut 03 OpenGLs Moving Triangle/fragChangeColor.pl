use strictures;

package fragChangeColor;

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
  glUniform1fARB
);
use OpenGL::Shader;

use Moo;

use lib '../framework';

with 'Framework';

has $_ => ( is => 'rw' ) for qw( theProgram elapsedTimeUniform );

has vertexPositions => (
	is      => 'ro',
	default => sub {
		return OpenGL::Array->new_list(
			GL_FLOAT,    #
			0.25,  0.25,  0, 1,
			0.25,  -0.25, 0, 1,
			-0.25, -0.25, 0, 1,
		);
	}
);

has $_ => ( is => 'rw' ) for qw( positionBufferObject vao );

__PACKAGE__->new->main;
exit;

sub InitializeProgram {
	my ( $self ) = @_;
	my @shaderList;

	push @shaderList, $self->LoadShader( GL_VERTEX_SHADER,   "calcOffset.vert" );
	push @shaderList, $self->LoadShader( GL_FRAGMENT_SHADER, "calcColor.frag" );

	$self->theProgram( $self->CreateProgram( @shaderList ) );

	$self->elapsedTimeUniform( glGetUniformLocationARB_p( $self->theProgram, "time" ) );

	my $loopDurationUnf = glGetUniformLocationARB_p( $self->theProgram, "loopDuration" );
	my $fragLoopDurUnf = glGetUniformLocationARB_p( $self->theProgram, "fragLoopDuration" );
	
	glUseProgramObjectARB( $self->theProgram );
	glUniform1fARB( $loopDurationUnf, 5 );
	glUniform1fARB( $fragLoopDurUnf, 5/4 );
	glUseProgramObjectARB( 0 );

	return;
}

sub InitializeVertexBuffer {
	my ( $self ) = @_;

	$self->positionBufferObject( glGenBuffersARB_p( 1 ) );

=head1 insufficient documentation
	glBufferDataARB_c
=cut

	glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
	glBufferDataARB_p( GL_ARRAY_BUFFER, $self->vertexPositions, GL_STATIC_DRAW );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

	return;
}

sub init {
	my ( $self ) = @_;

	$self->InitializeProgram;
	$self->InitializeVertexBuffer;

	$self->vao( glGenVertexArrays_p( 1 ) );
	glBindVertexArray( $self->vao );

	return;
}

sub display {
	my ( $self ) = @_;

	glClearColor( 0, 0, 0, 0 );
	glClear( GL_COLOR_BUFFER_BIT );

	glUseProgramObjectARB( $self->theProgram );

	glUniform1fARB($self->elapsedTimeUniform, glutGet(GLUT_ELAPSED_TIME) / 1000);

	glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
	glEnableVertexAttribArrayARB( 0 );
	glVertexAttribPointerARB_c( 0, 4, GL_FLOAT, GL_FALSE, 0, 0 );

	glDrawArrays( GL_TRIANGLES, 0, 3 );

	glDisableVertexAttribArrayARB( 0 );
	glUseProgramObjectARB( 0 );

	glutSwapBuffers();
	glutPostRedisplay();

	return;
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

sub defaults {
	my ( $self, $displayMode, $width, $height ) = @_;
	return $displayMode;
}
