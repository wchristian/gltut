use strictures;

package cpuPositionOffset;

use lib '../framework';
use OpenGL::Debug qw(
  GL_COLOR_BUFFER_BIT GL_ARRAY_BUFFER GL_FLOAT GL_FALSE GL_TRIANGLES
  GL_VERTEX_SHADER  GL_FRAGMENT_SHADER
  GL_STREAM_DRAW
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
  glBufferSubDataARB_p
);
use OpenGL::Shader;
use POSIX qw(fmod);

use Moo;

use lib '../framework';

with 'Framework';

has $_ => ( is => 'rw' ) for qw( vao theProgram positionBufferObject );

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

__PACKAGE__->new->main;
exit;

sub display {
	my ( $self ) = @_;

	my ( $fXOffset, $fYOffset ) = ( 0, 0 );
	$self->ComputePositionOffsets( \$fXOffset, \$fYOffset );
	$self->AdjustVertexData( $fXOffset, $fYOffset );

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
	glutPostRedisplay();

	return;
}

sub ComputePositionOffsets {
	my ( $self, $fXOffset, $fYOffset ) = @_;

	my $fLoopDuration = 5;
	my $fScale        = 3.14159 * 2.0 / $fLoopDuration;

	my $fElapsedTime = glutGet( GLUT_ELAPSED_TIME ) / 1000;

	my $fCurrTimeThroughLoop = fmod( $fElapsedTime, $fLoopDuration );

	${$fXOffset} = cos( $fCurrTimeThroughLoop * $fScale ) * 0.5;
	${$fYOffset} = sin( $fCurrTimeThroughLoop * $fScale ) * 0.5;

	return;
}

sub AdjustVertexData {
	my ( $self, $fXOffset, $fYOffset ) = @_;

	my @vertices = $self->vertexPositions->retrieve( 0, $self->vertexPositions->elements );

	for ( my $i = 0 ; $i < scalar @vertices ; $i += 4 ) {
		$vertices[$i] += $fXOffset;
		$vertices[ $i + 1 ] += $fYOffset;
	}

	my $new_data = OpenGL::Array->new_list( GL_FLOAT, @vertices );

	glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
	glBufferSubDataARB_p( GL_ARRAY_BUFFER, 0, $new_data );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

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

	push @shaderList, $self->LoadShader( GL_VERTEX_SHADER,   "standard.vert" );
	push @shaderList, $self->LoadShader( GL_FRAGMENT_SHADER, "standard.frag" );

	$self->theProgram( $self->CreateProgram( @shaderList ) );

	return;
}

sub InitializeVertexBuffer {
	my ( $self ) = @_;

	$self->positionBufferObject( glGenBuffersARB_p( 1 ) );

=head1 insufficient documentation
	glBufferDataARB_c
=cut

	glBindBufferARB( GL_ARRAY_BUFFER, $self->positionBufferObject );
	glBufferDataARB_p( GL_ARRAY_BUFFER, $self->vertexPositions, GL_STREAM_DRAW );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

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
