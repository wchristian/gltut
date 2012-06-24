use strictures;

package BaseVertexOverlap;

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
  glUniform3fARB
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
  GL_SHORT
  GL_ELEMENT_ARRAY_BUFFER
  GL_UNSIGNED_SHORT
  glDrawElementsBaseVertex_c
  glDrawElements_c
);
use OpenGL::Shader;

use Moo;

use lib '../framework';

$|++;

with 'Framework';

has $_ => ( is => 'rw' ) for qw( theProgram offsetUniform perspectiveMatrixUnif );
has perspectiveMatrix => ( is => 'rw', default => sub { [] } );
has fFrustumScale     => ( is => 'rw', default => sub { 1 } );
has numberOfVertices  => ( is => 'ro', default => sub { 36 } );

use constant RIGHT_EXTENT  => 0.8;
use constant LEFT_EXTENT   => - RIGHT_EXTENT;
use constant TOP_EXTENT    => 0.20;
use constant MIDDLE_EXTENT => 0.0;
use constant BOTTOM_EXTENT => - TOP_EXTENT;
use constant FRONT_EXTENT  => -1.25;
use constant REAR_EXTENT   => -1.75;

use constant GREEN_COLOR => 0.75, 0.75, 1.0, 1.0;
use constant BLUE_COLOR  => 0.0,  0.5,  0.0, 1.0;
use constant RED_COLOR   => 1.0,  0.0,  0.0, 1.0;
use constant GREY_COLOR  => 0.8,  0.8,  0.8, 1.0;
use constant BROWN_COLOR => 0.5,  0.5,  0.0, 1.0;

has vertexData => (
	is      => 'ro',
	default => sub {
		return OpenGL::Array->new_list(
			GL_FLOAT,    #

			#//Object 1 positions
			LEFT_EXTENT,  TOP_EXTENT,    REAR_EXTENT,
			LEFT_EXTENT,  MIDDLE_EXTENT, FRONT_EXTENT,
			RIGHT_EXTENT, MIDDLE_EXTENT, FRONT_EXTENT,
			RIGHT_EXTENT, TOP_EXTENT,    REAR_EXTENT,

			LEFT_EXTENT,  BOTTOM_EXTENT, REAR_EXTENT,
			LEFT_EXTENT,  MIDDLE_EXTENT, FRONT_EXTENT,
			RIGHT_EXTENT, MIDDLE_EXTENT, FRONT_EXTENT,
			RIGHT_EXTENT, BOTTOM_EXTENT, REAR_EXTENT,

			LEFT_EXTENT, TOP_EXTENT,    REAR_EXTENT,
			LEFT_EXTENT, MIDDLE_EXTENT, FRONT_EXTENT,
			LEFT_EXTENT, BOTTOM_EXTENT, REAR_EXTENT,

			RIGHT_EXTENT, TOP_EXTENT,    REAR_EXTENT,
			RIGHT_EXTENT, MIDDLE_EXTENT, FRONT_EXTENT,
			RIGHT_EXTENT, BOTTOM_EXTENT, REAR_EXTENT,

			LEFT_EXTENT,  BOTTOM_EXTENT, REAR_EXTENT,
			LEFT_EXTENT,  TOP_EXTENT,    REAR_EXTENT,
			RIGHT_EXTENT, TOP_EXTENT,    REAR_EXTENT,
			RIGHT_EXTENT, BOTTOM_EXTENT, REAR_EXTENT,

			#//Object 2 positions
			TOP_EXTENT,    RIGHT_EXTENT, REAR_EXTENT,
			MIDDLE_EXTENT, RIGHT_EXTENT, FRONT_EXTENT,
			MIDDLE_EXTENT, LEFT_EXTENT,  FRONT_EXTENT,
			TOP_EXTENT,    LEFT_EXTENT,  REAR_EXTENT,

			BOTTOM_EXTENT, RIGHT_EXTENT, REAR_EXTENT,
			MIDDLE_EXTENT, RIGHT_EXTENT, FRONT_EXTENT,
			MIDDLE_EXTENT, LEFT_EXTENT,  FRONT_EXTENT,
			BOTTOM_EXTENT, LEFT_EXTENT,  REAR_EXTENT,

			TOP_EXTENT,    RIGHT_EXTENT, REAR_EXTENT,
			MIDDLE_EXTENT, RIGHT_EXTENT, FRONT_EXTENT,
			BOTTOM_EXTENT, RIGHT_EXTENT, REAR_EXTENT,

			TOP_EXTENT,    LEFT_EXTENT, REAR_EXTENT,
			MIDDLE_EXTENT, LEFT_EXTENT, FRONT_EXTENT,
			BOTTOM_EXTENT, LEFT_EXTENT, REAR_EXTENT,

			BOTTOM_EXTENT, RIGHT_EXTENT, REAR_EXTENT,
			TOP_EXTENT,    RIGHT_EXTENT, REAR_EXTENT,
			TOP_EXTENT,    LEFT_EXTENT,  REAR_EXTENT,
			BOTTOM_EXTENT, LEFT_EXTENT,  REAR_EXTENT,

			#//Object 1 colors
			GREEN_COLOR,
			GREEN_COLOR,
			GREEN_COLOR,
			GREEN_COLOR,

			BLUE_COLOR,
			BLUE_COLOR,
			BLUE_COLOR,
			BLUE_COLOR,

			RED_COLOR,
			RED_COLOR,
			RED_COLOR,

			GREY_COLOR,
			GREY_COLOR,
			GREY_COLOR,

			BROWN_COLOR,
			BROWN_COLOR,
			BROWN_COLOR,
			BROWN_COLOR,

			#//Object 2 colors
			RED_COLOR,
			RED_COLOR,
			RED_COLOR,
			RED_COLOR,

			BROWN_COLOR,
			BROWN_COLOR,
			BROWN_COLOR,
			BROWN_COLOR,

			BLUE_COLOR,
			BLUE_COLOR,
			BLUE_COLOR,

			GREEN_COLOR,
			GREEN_COLOR,
			GREEN_COLOR,

			GREY_COLOR,
			GREY_COLOR,
			GREY_COLOR,
			GREY_COLOR,
		);
	}
);

has indexData => (
	is      => 'ro',
	default => sub {
		return OpenGL::Array->new_list(
			GL_SHORT,    #

			0, 2, 1,
			3, 2, 0,

			4, 5, 6,
			6, 7, 4,

			8,  9,  10,
			11, 13, 12,

			14, 16, 15,
			17, 16, 14,
		);
	}
);

has $_ => ( is => 'rw' ) for qw( vertexBufferObject indexBufferObject vao );

__PACKAGE__->new->main;
exit;

sub InitializeProgram {
	my ( $self ) = @_;
	my @shaderList;

	push @shaderList, $self->LoadShader( GL_VERTEX_SHADER,   "Standard.vert" );
	push @shaderList, $self->LoadShader( GL_FRAGMENT_SHADER, "Standard.frag" );

	$self->theProgram( $self->CreateProgram( @shaderList ) );

	$self->offsetUniform( glGetUniformLocationARB_p( $self->theProgram, "offset" ) );

	$self->perspectiveMatrixUnif( glGetUniformLocationARB_p( $self->theProgram, "perspectiveMatrix" ) );

	my ( $fzNear, $fzFar ) = ( 1, 3.0 );

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

	glBindBufferARB( GL_ARRAY_BUFFER, $self->vertexBufferObject );
	glBufferDataARB_p( GL_ARRAY_BUFFER, $self->vertexData, GL_STATIC_DRAW );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

	$self->indexBufferObject( glGenBuffersARB_p( 1 ) );

	glBindBufferARB( GL_ARRAY_BUFFER, $self->indexBufferObject );
	glBufferDataARB_p( GL_ARRAY_BUFFER, $self->indexData, GL_STATIC_DRAW );
	glBindBufferARB( GL_ARRAY_BUFFER, 0 );

	return;
}

sub init {
	my ( $self ) = @_;

	$self->InitializeProgram;
	$self->InitializeVertexBuffer;

	$self->vao( glGenVertexArrays_p( 1 ) );
	glBindVertexArray( $self->vao );

	my $colorDataOffset = 4 * 3 * $self->numberOfVertices;
	glBindBufferARB( GL_ARRAY_BUFFER, $self->vertexBufferObject );
	glEnableVertexAttribArrayARB( 0 );
	glEnableVertexAttribArrayARB( 1 );
	glVertexAttribPointerARB_c( 0, 3, GL_FLOAT, GL_FALSE, 0, 0 );
	glVertexAttribPointerARB_c( 1, 4, GL_FLOAT, GL_FALSE, 0, $colorDataOffset );
	glBindBufferARB( GL_ELEMENT_ARRAY_BUFFER, $self->indexBufferObject );

	glBindVertexArray( 0 );

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

	glBindVertexArray( $self->vao );

	glUniform3fARB( $self->offsetUniform, 0, 0, 0 );
	glDrawElements_c( GL_TRIANGLES, $self->indexData->elements, GL_UNSIGNED_SHORT, 0 );

	glUniform3fARB( $self->offsetUniform, 0, 0, -1 );
	glDrawElementsBaseVertex_c( GL_TRIANGLES, $self->indexData->elements,
		GL_UNSIGNED_SHORT, 0, $self->numberOfVertices / 2 );

	glBindVertexArray( 0 );
	glUseProgramObjectARB( 0 );

	glutSwapBuffers();

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
