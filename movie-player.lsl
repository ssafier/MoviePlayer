#ifndef debug
#define debug(x) 
#endif

#ifndef PRIM_FACE
#define PRIM_FACE 2
#endif

list frames;
integer frame_count;
integer current_frame;
integer prior_frame;

integer movieActive;
integer cache;

integer loaded = FALSE;

#define SPEED 6.4
#define SCALE 0.125
#define getFrame(f) (string) frames[f]
#define SetFaceTexture(t, f) llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_TEXTURE,f, t,<1.0,1.0,0.0>,ZERO_VECTOR,0.0]);
#define SetLastTexture(t, f) llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_TEXTURE,f, t,<SCALE, SCALE, 0.0>,<SCALE, SCALE, SCALE>,0.0]);

#define START_MOVIE 2272025
#define STOP_MOVIE -2272025

preload() {
  integer face = PRIM_FACE;
  integer frame = current_frame;
  integer l;
  integer stop = 6;
  if (frame_count < 6) stop = frame_count;
  for (l = 0; l < stop; ++l) {
    SetFaceTexture(getFrame(frame), face);
    if (++face > 6) face = 0;
    if (++frame >= frame_count) frame = 0;
  }
  cache = 3;
}

loadFrames() {
  frames=[];
  integer i = llGetInventoryNumber(INVENTORY_TEXTURE);
  integer length = 0;
  while(i) {
      --i;
      frames += [llGetInventoryName(INVENTORY_TEXTURE,i)];
      ++length;
    }
  debug((string)length+" pictures loaded");
  frames = llListSort(frames, 1, TRUE ); // put them in order
  frame_count = length;
  loaded = TRUE;
}

default  {
  on_rez(integer x) {
    if (x == 0) return;
    loadFrames();
  }
  
  state_entry() {
    if (!loaded) loadFrames();
    llSetLinkColor(LINK_THIS, <0,0,0>, ALL_SIDES );
    llSetLinkColor(LINK_THIS, <1,1,1>, PRIM_FACE ); // Slides displayed on this face are visible.  All other faces are colored black
    prior_frame = current_frame = 0;
    movieActive = FALSE;
    preload();
  }

  changed( integer ch ) {
    if( ch & CHANGED_INVENTORY ) {
      llSetTimerEvent(0);
      movieActive = FALSE;
      loadFrames();
    }
  }

  touch_start(integer num) {
#ifndef NO_TOUCH
    if (movieActive) {
      llSetTimerEvent(0);
      movieActive = FALSE;
      llSetTextureAnim(0, PRIM_FACE, 8, 8, 0.0, 64.0, 6.4 );
      SetLastTexture(getFrame(prior_frame),PRIM_FACE);
    } else {
#else
    if (movieActive == 0) {
#endif
      movieActive = TRUE;
      preload();
      debug("on");
      llSetTextureAnim( ANIM_ON , PRIM_FACE, 8, 8, 0.0, 64.0, SPEED );
      prior_frame = current_frame;
      if (++current_frame >= frame_count) current_frame = 0;
      llSetTimerEvent(64.0 / SPEED - 0.125);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch (chan) {
    case START_MOVIE: {
      if (movieActive) return;
      movieActive = TRUE;
      if (prior_frame != 0 || current_frame != 0) {
	prior_frame = current_frame = 0;
	preload();
      }
      debug("on");
      llSetTextureAnim( ANIM_ON , PRIM_FACE, 8, 8, 0.1, 64.0, SPEED );
      if (++current_frame >= frame_count) current_frame = 0;
      llSetTimerEvent(64.0 / SPEED - 0.125);
      break;
    }
    case STOP_MOVIE: {
      llSetTimerEvent(0);
      movieActive = FALSE;
      llSetTextureAnim(0, PRIM_FACE, 8, 8, 0.0, 64.0, 6.4 );
      SetLastTexture(getFrame(prior_frame),PRIM_FACE);
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTextureAnim(0, PRIM_FACE, 8, 8, 0.0, 64.0, 6.4 );
    SetLastTexture(getFrame(prior_frame),PRIM_FACE);
    SetFaceTexture(getFrame(current_frame), PRIM_FACE);
    llSetTextureAnim( ANIM_ON , PRIM_FACE, 8, 8, 0.0, 64.0, 6.4 );
    debug("swap");
    prior_frame = current_frame;
    if (++current_frame >= frame_count) {
#ifdef NO_LOOP
      llSetTimerEvent(0);
      movieActive = FALSE;
#endif
      current_frame = 0;
    }
    SetFaceTexture(getFrame(current_frame), cache);
    if (++cache >= 6) cache = 0; else if (cache == PRIM_FACE) cache = PRIM_FACE + 1;
  }
}
