/****************************************************************************
Copyright (c) 2010 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

/*
 * Idea of subclassing NSOpenGLView was taken from  "TextureUpload" Apple's sample
 */

#import <Availability.h>

#import "EAGLView.h"
#import "CCEGLView.h"
#import <OpenGL/gl.h>
#import "CCDirector.h"
#import "ccConfig.h"
#import "CCSet.h"
#import "CCTouch.h"
#import "CCIMEDispatcher.h"
#import "CCWindow.h"
#import "CCEventDispatcher.h"
#import "CCEGLView.h"
#import "CCKeyboard.h"
#import "CCIMEDispatcher.h"
#import "CCKeypadDispatcher.h"

//USING_NS_CC;
static EAGLView *view;

@implementation EAGLView

@synthesize eventDelegate = eventDelegate_, isFullScreen = isFullScreen_, frameZoomFactor=frameZoomFactor_;

+(id) sharedEGLView
{
	return view;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}

- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context
{
    NSOpenGLPixelFormatAttribute attribs[] =
    {
//		NSOpenGLPFAAccelerated,
//		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		0
    };
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
	if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");
	
	if( (self = [super initWithFrame:frameRect pixelFormat:[pixelFormat autorelease]]) ) {
		
		if( context )
			[self setOpenGLContext:context];

		// event delegate
		eventDelegate_ = [CCEventDispatcher sharedDispatcher];
	}
    
    cocos2d::CCEGLView::sharedOpenGLView()->setFrameSize(cocos2d::CCSize(frameRect.size.width,frameRect.size.height));
    
    frameZoomFactor_ = 1.0f;
	
	view = self;
	return self;
}

- (id) initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format{
    // event delegate
    eventDelegate_ = [CCEventDispatcher sharedDispatcher];
    
    cocos2d::CCEGLView::sharedOpenGLView()->setFrameSize(cocos2d::CCSize(frameRect.size.width,frameRect.size.height));
    
    frameZoomFactor_ = 1.0f;
	
	view = self;
    
    [super initWithFrame:frameRect pixelFormat:format];

    return self;
}

- (void) update
{
	// XXX: Should I do something here ?
	[super update];
}

- (void) prepareOpenGL
{
	// XXX: Initialize OpenGL context

	[super prepareOpenGL];
	
	// Make this openGL context current to the thread
	// (i.e. all openGL on this thread calls will go to this context)
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];	

//	GLint order = -1;
//	[[self openGLContext] setValues:&order forParameter:NSOpenGLCPSurfaceOrder];
}

- (NSUInteger) depthFormat
{
	return 24;
}

- (void) setFrameZoomFactor:(float)frameZoomFactor
{
    frameZoomFactor_ = frameZoomFactor;
    
    NSRect winRect = [[self window] frame];
    NSRect viewRect = [self frame];
    
    // compute the margin width and margin height
    float diffX = winRect.size.width - viewRect.size.width;
    float diffY = winRect.size.height - viewRect.size.height;
    
    // new window width and height
    float newWindowWidth = (int)(viewRect.size.width * frameZoomFactor + diffX);
    float newWindowHeight = (int)(viewRect.size.height * frameZoomFactor + diffY);
    
    // display window in the center of the screen
    NSRect screenRect = [[NSScreen mainScreen] frame];
    float originX = (screenRect.size.width - newWindowWidth) / 2;
    float originY = (screenRect.size.height - newWindowHeight) / 2;
    
    [[self window] setFrame:NSMakeRect(originX, originY, newWindowWidth, newWindowHeight) display:true];
}

- (void) reshape
{
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing

	[self lockOpenGLContext];
	
//	NSRect rect = [self bounds];
	
	cocos2d::CCDirector *director = cocos2d::CCDirector::sharedDirector();
//	CGSize size = NSSizeToCGSize(rect.size);
//	cocos2d::CCSize ccsize = cocos2d::CCSizeMake(size.width, size.height);
	//director->reshapeProjection(ccsize);
	
	// avoid flicker
	director->drawScene();
//	[self setNeedsDisplay:YES];
	
	[self unlockOpenGLContext];
}

-(void) lockOpenGLContext
{
	NSOpenGLContext *glContext = [self openGLContext];
	NSAssert( glContext, @"FATAL: could not get openGL context");

	[glContext makeCurrentContext];
	CGLLockContext((CGLContextObj)[glContext CGLContextObj]);
}

-(void) unlockOpenGLContext
{
	NSOpenGLContext *glContext = [self openGLContext];
	NSAssert( glContext, @"FATAL: could not get openGL context");

	CGLUnlockContext((CGLContextObj)[glContext CGLContextObj]);
}

- (void) dealloc
{
	CCLOGINFO(@"cocos2d: deallocing EAGLView %@", self);
	[super dealloc];
}
	
-(int) getWidth
{
	NSSize bound = [self bounds].size;
	return bound.width;
}

-(int) getHeight
{
	NSSize bound = [self bounds].size;
	return bound.height;
}

-(void) swapBuffers
{ }

//
// setFullScreen code taken from GLFullScreen example by Apple
//
- (void) goFullScreen
{
	// Mac OS X 10.6 and later offer a simplified mechanism to create full-screen contexts
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5

    if (isFullScreen_)
		return;

	EAGLView *openGLview = [[self class] sharedEGLView];

    originalWinRect_ = [openGLview frame];

	// Cache normal window and superview of openGLView
	if (!windowGLView_) windowGLView_ = [[openGLview window] retain];

	[superViewGLView_ release];
	superViewGLView_ = [[openGLview superview] retain];

	// Get screen size
	NSRect displayRect = [[NSScreen mainScreen] frame];

	// Create a screen-sized window on the display you want to take over
	fullScreenWindow_ = [[CCWindow alloc] initWithFrame:displayRect fullscreen:YES];

	// Remove glView from window
	[openGLview removeFromSuperview];

	// Set new frame
	[openGLview initWithFrame:displayRect];

	// Attach glView to fullscreen window
	[fullScreenWindow_ setContentView:openGLview];

	// Show the fullscreen window
	[fullScreenWindow_ makeKeyAndOrderFront:self];
	[fullScreenWindow_ makeMainWindow];
	//[fullScreenWindow_ setNextResponder:superViewGLView_];
		
	// issue #1189
	[windowGLView_ makeFirstResponder:openGLview];

    isFullScreen_ = true;

    [openGLview setNeedsDisplay:YES];
#else
	#error Full screen is not supported for Mac OS 10.5 or older yet
	#error If you don't want FullScreen support, you can safely remove these 2 lines
#endif
}

- (void) closeAllWindows
{
	[[self window] close];
	[windowGLView_ close];
	[fullScreenWindow_ close];
}

#pragma mark EAGLView - Mouse events

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;
	
    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = (int)[theEvent eventNumber];
	xs[0] = x / frameZoomFactor_;
	ys[0] = y / frameZoomFactor_;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesBegin(1, ids, xs, ys);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[super mouseMoved:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;

    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = (int)[theEvent eventNumber];
	xs[0] = x / frameZoomFactor_;
	ys[0] = y / frameZoomFactor_;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesMove(1, ids, xs, ys);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;

    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = (int)[theEvent eventNumber];
	xs[0] = x / frameZoomFactor_;
	ys[0] = y / frameZoomFactor_;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesEnd(1, ids, xs, ys);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	// pass the event along to the next responder (like your NSWindow subclass)
	[super rightMouseDown:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[super rightMouseDragged:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[super rightMouseUp:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	[super otherMouseDown:theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[super otherMouseDragged:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	[super otherMouseUp:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[super mouseExited:theEvent];
}

-(void) scrollWheel:(NSEvent *)theEvent
{
	[super scrollWheel:theEvent];
}

#pragma mark EAGLView - Key events

-(BOOL) becomeFirstResponder
{
	return YES;
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}

-(BOOL) resignFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
  	NSString* characters = [theEvent characters];
  	if ([characters length])
	{
		unichar ch = [characters characterAtIndex:0];
		char key = (char)(0xff & ch);
		if (ch == u'\r')
		{
			cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchInsertText("\n", 1);
		}
		else if (key == 0x7F)
		{
			cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchDeleteBackward();
		}
		else if (ch < 0xF780)
		{
			cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchInsertText((const char*)&key, 1);
		}
		else
		{
			const char* chars = [characters cStringUsingEncoding: NSUTF8StringEncoding];
			cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchInsertText(chars, (int)strlen(chars));
		}
		cocos2d::CCKeyboard::sharedKeyboard()->updateKey((char)(0xFF & ch), true);
	}
	// pass the event along to the next responder (like your NSWindow subclass)
	//[super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
  	NSString* characters = [theEvent characters];
  	if ([characters length])
	{
		unichar ch = [characters characterAtIndex:0];
		char key = (char)(0xff & ch);
		cocos2d::CCKeyboard::sharedKeyboard()->updateKey(key, false);
		if (key == 0x1B)
		{
			cocos2d::CCDirector::sharedDirector()->
				getKeypadDispatcher()->
				dispatchKeypadMSG(cocos2d::CCKeypad::Back);
		}
		else if (ch == NSF1FunctionKey)
		{
			cocos2d::CCDirector::sharedDirector()->
				getKeypadDispatcher()->
				dispatchKeypadMSG(cocos2d::CCKeypad::Menu);
		}
	}
	// pass the event along to the next responder (like your NSWindow subclass)
	//[super keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[super flagsChanged:theEvent];
}

#pragma mark EAGLView - Touch events
- (void)touchesBeganWithEvent:(NSEvent *)theEvent
{
	[super touchesBeganWithEvent:theEvent];
}

- (void)touchesMovedWithEvent:(NSEvent *)theEvent
{
	[super touchesMovedWithEvent:theEvent];
}

- (void)touchesEndedWithEvent:(NSEvent *)theEvent
{
	[super touchesEndedWithEvent:theEvent];
}

- (void)touchesCancelledWithEvent:(NSEvent *)theEvent
{
	[super touchesCancelledWithEvent:theEvent];
}
@end
