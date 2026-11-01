//
//  XBCurlView.m
//  XBPageCurl
//
//  Created by xiss burg on 8/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "XBCurlView.h"
#import "CGPointAdditions.h"
#import <QuartzCore/QuartzCore.h>

#define kCylinderPositionAnimationName @"cylinderPosition"
#define kCylinderDirectionAnimationName @"cylinderDirection"
#define kCylinderRadiusAnimationName @"cylinderRadius"

typedef struct _Vertex
{
    GLfloat x, y, z;
    GLfloat u, v;
} Vertex;

void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far);
void ImageProviderReleaseData(void *info, const void *data, size_t size);

@interface XBCurlView () {
@private
    //OpenGL buffers.
    GLuint framebuffer;
    GLuint colorRenderbuffer;
    GLuint sampleFramebuffer;
    GLuint sampleColorRenderbuffer;
    
    //Texture size for all possible textures (front of page, back of page, nextPage).
    GLuint textureWidth, textureHeight;
    
    //Texture projected onto the front of the curling mesh.
    GLuint frontTexture;
    
    //Texture projected onto the back of the curling mesh for double-sided pages.
    GLuint backTexture;
    GLuint backGradientTexture;
    
    //GPU program for the curling mesh.
    GLuint frontProgram;
    GLuint backProgram;
    
    //Vertex and index buffer for the curling mesh.
    GLuint vertexBuffer;
    GLuint indexBuffer;
    GLuint elementCount; //Number of entries in the index buffer
    
    //Vertex Array Objects
    GLuint backVAO;
    GLuint frontVAO;
    GLuint nextPageVAO;
    
    //Handles for the curl shader uniforms.
    GLuint frontMvpHandle, frontSamplerHandle;
    GLuint frontCylinderPositionHandle, frontCylinderDirectionHandle, frontCylinderRadiusHandle;
    
    GLuint backMvpHandle, backSamplerHandle, backGradientSamplerHandle;
    GLuint backCylinderPositionHandle, backCylinderDirectionHandle, backCylinderRadiusHandle;
    
    //Texture projected onto the two-triangle rectangle of the nextPage.
    GLuint nextPageTexture;
    
    //GPU program for the nextPage.
    GLuint nextPageProgram;
    
    //Vertex buffer for the two-triangle rectangle of the nextPage.
    //No need for an index buffer. It is drawn as a triangle-strip.
    GLuint nextPageVertexBuffer;
    
    //Handles for the nextPageProgram uniforms.
    GLuint nextPageMvpHandle, nextPageSamplerHandle;
    GLuint nextPageCylinderPositionHandle, nextPageCylinderDirectionHandle, nextPageCylinderRadiusHandle;
    
    //Viewport/view/screen size.
    GLint viewportWidth, viewportHeight;
    
    //Model-View-Proj matrix.
    GLfloat mvp[16];
}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) XBAnimationManager *animationManager;
@property (nonatomic, weak) UIView *curlingView; //UIView being curled only used in curlView: and uncurlAnimatedWithDuration: methods
@property (nonatomic, readonly) CGFloat screenScale;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@property (nonatomic, assign) BOOL wasAnimating;

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)createVertexBufferWithXRes:(GLuint)xRes yRes:(GLuint)yRes;
- (void)destroyVertexBuffer;
- (void)createNextPageVertexBuffer;
- (void)destroyNextPageVertexBuffer;
- (void)destroyNextPageTexture;
- (void)destroyNextPageShader;
- (void)destroyBackTexture;
- (BOOL)setupShaders;
- (void)destroyShaders;
- (void)setupMVP;
- (GLuint)generateTexture;
- (void)destroyTextures;

- (void)drawImage:(UIImage *)image onTexture:(GLuint)texture;
- (void)drawImage:(UIImage *)image onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal;
- (void)drawView:(UIView *)view onTexture:(GLuint)texture;
- (void)drawView:(UIView *)view onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal;
- (void)drawOnTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height drawBlock:(void (^)(CGContextRef context))drawBlock;

- (void)draw:(CADisplayLink *)sender;

@end


@implementation XBCurlView

- (BOOL)initialize
{
    //Setup scale before everything
    _screenScale = [[UIScreen mainScreen] scale];
    [self setContentScaleFactor:self.screenScale];
    
    self.pageOpaque = YES;
    self.opaque = YES;
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.opaque = YES;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (self.context == nil || [EAGLContext setCurrentContext:self.context] == NO) {
        return NO;
    }
    
    self.animationManager = [[XBAnimationManager alloc] init];

    self.cylinderPosition = CGPointMake(self.bounds.size.width, self.bounds.size.height/2);
    self.cylinderAngle = M_PI_2;
    self.cylinderRadius = 32;
    
    framebuffer = colorRenderbuffer = 0;
    sampleFramebuffer = sampleColorRenderbuffer = 0;
    vertexBuffer = indexBuffer = elementCount = 0;
    frontTexture = backTexture = nextPageTexture = 0;
    
    if (![self createFramebuffer]) {
        return NO;
    }
    
    [self createVertexBufferWithXRes:(GLuint)self.horizontalResolution yRes:(GLuint)self.verticalResolution];
    [self createNextPageVertexBuffer];
    
    if (![self setupShaders]) {
        return NO;
    }
    
    textureWidth = (GLuint)(self.frame.size.width*self.screenScale);
    textureHeight = (GLuint)(self.frame.size.height*self.screenScale);
    frontTexture = [self generateTexture];
    
    [self createBackGradientTexture];
    [self setupMVP];
    
    [self createBackVAO];
    [self createFrontVAO];
    [self createNextPageVAO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    return YES;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame antialiasing:NO];
}

- (id)initWithFrame:(CGRect)frame antialiasing:(BOOL)antialiasing;
{
    return [self initWithFrame:frame horizontalResolution:(NSUInteger)(frame.size.width/10) verticalResolution:(NSUInteger)(frame.size.height/10) antialiasing:antialiasing];
}

- (id)initWithFrame:(CGRect)frame horizontalResolution:(NSUInteger)horizontalResolution verticalResolution:(NSUInteger)verticalResolution antialiasing:(BOOL)antialiasing
{
    self = [super initWithFrame:frame];
    if (self) {
        _antialiasing = antialiasing;
        _horizontalResolution = horizontalResolution;
        _verticalResolution = verticalResolution;
        
        if (![self initialize]) {
            return nil;
        }
        
        [self setupInitialGLState];
    }
    return self;
}

- (void)dealloc
{
    [EAGLContext setCurrentContext:self.context];
    [self.displayLink invalidate];
    self.displayLink = nil;
    [self destroyTextures];
    [self destroyVertexBuffer];
    [self destroyNextPageVertexBuffer];
    [self destroyShaders];
    [self destroyVAOs];
    [self destroyFramebuffer];
    //Keep this last one as the last one
    self.context = nil;
    [EAGLContext setCurrentContext:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Overrides

+ (Class)layerClass 
{
    return [CAEAGLLayer class];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.frame, point)) {
        CGPoint v = CGPointMake(-sinf(self.cylinderAngle), cosf(self.cylinderAngle));
        CGPoint w = CGPointSub(point, CGPointSub(self.cylinderPosition, CGPointMul(v, self.cylinderRadius)));
        CGFloat dot = CGPointDot(v, w);
        return dot > 0;
    }
    
    return NO;
}

#pragma mark - Properties

- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration
{
    [self setCylinderPosition:cylinderPosition animatedWithDuration:duration completion:nil];
}

- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    [self setCylinderPosition:cylinderPosition animatedWithDuration:duration interpolator:XBAnimationInterpolatorEaseInOut completion:completion];
}

- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion
{
    CGPoint p0 = self.cylinderPosition;
    __weak XBCurlView *weakSelf = self;
    XBAnimation *animation = [XBAnimation animationWithName:kCylinderPositionAnimationName duration:duration update:^(double t) {
        weakSelf.cylinderPosition = CGPointMake((1 - t)*p0.x + t*cylinderPosition.x, (1 - t)*p0.y + t*cylinderPosition.y);
    } completion:completion interpolator:interpolator];
    [self.animationManager runAnimation:animation];
}

- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration
{
    [self setCylinderAngle:cylinderAngle animatedWithDuration:duration completion:nil];
}

- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    [self setCylinderAngle:cylinderAngle animatedWithDuration:duration interpolator:XBAnimationInterpolatorEaseInOut completion:completion];
}

- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion
{
    double a0 = _cylinderAngle;
    double a1 = cylinderAngle;
    __weak XBCurlView *weakSelf = self;
    XBAnimation *animation = [XBAnimation animationWithName:kCylinderDirectionAnimationName duration:duration update:^(double t) {
        weakSelf.cylinderAngle = (1 - t)*a0 + t*a1;
    } completion:completion interpolator:interpolator];
    [self.animationManager runAnimation:animation];
}

- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration
{
    [self setCylinderRadius:cylinderRadius animatedWithDuration:duration completion:nil];
}

- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    [self setCylinderRadius:cylinderRadius animatedWithDuration:duration interpolator:XBAnimationInterpolatorEaseInOut completion:completion];
}

- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion
{
    CGFloat r = self.cylinderRadius;
    __weak XBCurlView *weakSelf = self;
    XBAnimation *animation = [XBAnimation animationWithName:kCylinderRadiusAnimationName duration:duration update:^(double t) {
        weakSelf.cylinderRadius = (1 - t)*r + t*cylinderRadius;
    } completion:completion interpolator:interpolator];
    [self.animationManager runAnimation:animation];
}

- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration
{
    [self setCylinderPosition:cylinderPosition animatedWithDuration:duration];
    [self setCylinderAngle:cylinderAngle animatedWithDuration:duration];
    [self setCylinderRadius:cylinderRadius animatedWithDuration:duration];
}

- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    [self setCylinderPosition:cylinderPosition animatedWithDuration:duration];
    [self setCylinderAngle:cylinderAngle animatedWithDuration:duration];
    [self setCylinderRadius:cylinderRadius animatedWithDuration:duration completion:completion];
}

- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double))interpolator completion:(void (^)(void))completion
{
    [self setCylinderPosition:cylinderPosition animatedWithDuration:duration interpolator:interpolator completion:nil];
    [self setCylinderAngle:cylinderAngle animatedWithDuration:duration interpolator:interpolator completion:nil];
    [self setCylinderRadius:cylinderRadius animatedWithDuration:duration interpolator:interpolator completion:completion];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    const CGFloat *color = CGColorGetComponents(self.backgroundColor.CGColor);
    if (color == NULL) {
        color = (CGFloat[]){1, 1, 1};
    }
    [EAGLContext setCurrentContext:self.context];
    glClearColor(color[0], color[1], color[2], self.opaque? 1.0: 0.0);
}

- (void)setOpaque:(BOOL)opaque
{
    [super setOpaque:opaque];
    self.backgroundColor = self.backgroundColor;
}

#pragma mark - Notifications

- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
    self.wasAnimating = self.displayLink != nil;
    [self stopAnimating];
    
    if (self.context) {
        [EAGLContext setCurrentContext:self.context];
        glFinish();
    }
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    if (self.wasAnimating) {
        [self startAnimating];
    }
}

#pragma mark - Framebuffer

- (BOOL)createFramebuffer
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyFramebuffer];
    
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewportWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewportHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to create framebuffer: 0x%X", status);
        return NO;
    }
    
    //Create multisampling buffers
    if (self.antialiasing) {
        glGenFramebuffers(1, &sampleFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, sampleFramebuffer);
        
        glGenRenderbuffers(1, &sampleColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, sampleColorRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, viewportWidth, viewportHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, sampleColorRenderbuffer);
        
        status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Failed to create multisamping framebuffer: 0x%X", status);
            return NO;
        }
        
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
    
    return YES;
}

- (void)destroyFramebuffer
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteFramebuffers(1, &framebuffer);
    framebuffer = 0;
    
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    colorRenderbuffer = 0;
    
    glDeleteFramebuffers(1, &sampleFramebuffer);
    sampleFramebuffer = 0;
    
    glDeleteRenderbuffers(1, &sampleColorRenderbuffer);
    sampleColorRenderbuffer = 0;
}

- (void)setupInitialGLState
{
    [EAGLContext setCurrentContext:self.context];
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glViewport(0, 0, viewportWidth, viewportHeight);
    self.backgroundColor = [UIColor clearColor];
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glUseProgram(frontProgram);
    glUniformMatrix4fv(frontMvpHandle, 1, GL_FALSE, mvp);
    glUniform1i(frontSamplerHandle, 0);
    
    glUseProgram(backProgram);
    glUniformMatrix4fv(backMvpHandle, 1, GL_FALSE, mvp);
    glUniform1i(backSamplerHandle, 0);
    glUniform1i(backGradientSamplerHandle, 1);
    
    glUseProgram(nextPageProgram);
    glUniformMatrix4fv(nextPageMvpHandle, 1, GL_FALSE, mvp);
    glUniform1i(nextPageSamplerHandle, 0);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, frontTexture);
}

- (UIImage *)imageFromFramebuffer
{
    return [self imageFromFramebufferWithBackgroundView:nil];
}

- (UIImage *)imageFromFramebufferWithBackgroundView:(UIView *)backgroundView
{
    [EAGLContext setCurrentContext:self.context];
    GLuint rttFramebuffer;
    glGenFramebuffers(1, &rttFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, rttFramebuffer);
    GLuint rttTexture;
    glGenTextures(1, &rttTexture);
    glBindTexture(GL_TEXTURE_2D, rttTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, viewportWidth, viewportHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rttTexture, 0);
    glBindTexture(GL_TEXTURE_2D, frontTexture);
    [self draw:self.displayLink];
    
    size_t size = viewportHeight * viewportWidth * 4;
    GLvoid *pixels = malloc(size);
    glReadPixels(0, 0, viewportWidth, viewportHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    
    // Restore the original framebuffer binding
    glBindFramebuffer(GL_FRAMEBUFFER, self.antialiasing? sampleFramebuffer: framebuffer);
    glDeleteFramebuffers(1, &rttFramebuffer);
    glDeleteTextures(1, &rttTexture);
    
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = viewportWidth * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixels, size, ImageProviderReleaseData);
    CGImageRef cgImage = CGImageCreate(viewportWidth, viewportHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.contentScaleFactor orientation:UIImageOrientationDownMirrored];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    if (backgroundView != nil) {
        UIGraphicsBeginImageContextWithOptions(image.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [backgroundView.layer renderInContext:context];
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

#pragma mark - Vertexbuffers

- (void)createVertexBufferWithXRes:(GLuint)xRes yRes:(GLuint)yRes
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyVertexBuffer];
    
    GLsizeiptr verticesSize = (xRes+1)*(yRes+1)*sizeof(Vertex);
    Vertex *vertices = malloc(verticesSize);
    
    for (int y=0; y<yRes+1; ++y) {
        GLfloat tv = (GLfloat)y/yRes;
        GLfloat vy = tv*viewportHeight;
        for (int x=0; x<xRes+1; ++x) {
            Vertex *v = &vertices[y*(xRes+1) + x];
            v->u = (GLfloat)x/xRes;
            v->v = tv;
            v->x = v->u*viewportWidth;
            v->y = vy;
            v->z = 0;
        }
    }
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, verticesSize, (GLvoid *)vertices, GL_STATIC_DRAW);
    free(vertices);
    
    elementCount = xRes*yRes*2*3;
    assert(elementCount);
    
    GLsizeiptr indicesSize = elementCount*sizeof(GLushort);//Two triangles per square, 3 indices per triangle
    GLushort *indices = malloc(indicesSize);
    
    for (int y=0; y<yRes; ++y) {
        for (int x=0; x<xRes; ++x) {
            int i = y*(xRes+1) + x;
            int idx = y*xRes + x;
            assert(i < elementCount*3-1);
            indices[idx*6+0] = i;
            indices[idx*6+1] = i + 1;
            indices[idx*6+2] = i + xRes + 1;
            indices[idx*6+3] = i + 1;
            indices[idx*6+4] = i + xRes + 2;
            indices[idx*6+5] = i + xRes + 1;
        }
    }
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesSize, (GLvoid *)indices, GL_STATIC_DRAW);
    free(indices);
}

- (void)destroyVertexBuffer
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &indexBuffer);
    vertexBuffer = indexBuffer = 0;
}

- (void)createNextPageVertexBuffer
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyNextPageVertexBuffer];
    
    GLsizeiptr verticesSize = 4*sizeof(Vertex);
    Vertex *vertices = malloc(verticesSize);
    
    vertices[0].x = 0;
    vertices[0].y = 0;
    vertices[0].z = -1;
    vertices[0].u = 0;
    vertices[0].v = 0;
    
    vertices[1].x = viewportWidth;
    vertices[1].y = 0;
    vertices[1].z = -1;
    vertices[1].u = 1;
    vertices[1].v = 0;
    
    vertices[2].x = 0;
    vertices[2].y = viewportHeight;
    vertices[2].z = -1;
    vertices[2].u = 0;
    vertices[2].v = 1;
    
    vertices[3].x = viewportWidth;
    vertices[3].y = viewportHeight;
    vertices[3].z = -1;
    vertices[3].u = 1;
    vertices[3].v = 1;
    
    glGenBuffers(1, &nextPageVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, nextPageVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, verticesSize, (GLvoid *)vertices, GL_STATIC_DRAW);
    
    free(vertices);
}

- (void)destroyNextPageVertexBuffer
{
    glDeleteBuffers(1, &nextPageVertexBuffer);
}

- (void)createBackVAO
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyBackVAO];
    glGenVertexArraysOES(1, &backVAO);
    glBindVertexArrayOES(backVAO);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, x));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, u));
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBindVertexArrayOES(0);
}

- (void)destroyBackVAO
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteVertexArraysOES(1, &backVAO);
    backVAO = 0;
}

- (void)createFrontVAO
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyFrontVAO];
    glGenVertexArraysOES(1, &frontVAO);
    glBindVertexArrayOES(frontVAO);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, x));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, u));
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBindVertexArrayOES(0);
}

- (void)destroyFrontVAO
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteVertexArraysOES(1, &frontVAO);
    frontVAO = 0;
}

- (void)createNextPageVAO
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyNextPageVAO];
    glGenVertexArraysOES(1, &nextPageVAO);
    glBindVertexArrayOES(nextPageVAO);
    glBindBuffer(GL_ARRAY_BUFFER, nextPageVertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, x));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, u));
    glBindVertexArrayOES(0);
}

- (void)destroyNextPageVAO
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteVertexArraysOES(1, &nextPageVAO);
    nextPageVAO = 0;
}

- (void)destroyVAOs
{
    [self destroyNextPageVAO];
    [self destroyFrontVAO];
    [self destroyBackVAO];
}

- (void)setupMVP
{
    [EAGLContext setCurrentContext:self.context];
    OrthoM4x4(mvp, 0.f, viewportWidth, 0.f, viewportHeight, -1000.f, 1000.f);
    glUseProgram(nextPageProgram);
    glUniformMatrix4fv(nextPageMvpHandle, 1, GL_FALSE, mvp);
    glUseProgram(frontProgram);
    glUniformMatrix4fv(frontMvpHandle, 1, GL_FALSE, mvp);
    glUseProgram(backProgram);
    glUniformMatrix4fv(backMvpHandle, 1, GL_FALSE, mvp);
}

#pragma mark - Shaders

- (GLuint)loadShader:(NSString *)filename type:(GLenum)type 
{
    [EAGLContext setCurrentContext:self.context];
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        return 0;
    }
    
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    NSString *shaderString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    const GLchar *shaderSource = [shaderString cStringUsingEncoding:NSUTF8StringEncoding];
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if (success == 0) {
        char errorMsg[2048];
        glGetShaderInfoLog(shader, sizeof(errorMsg), NULL, errorMsg);
        NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
        NSLog(@"Failed to compile %@: %@", filename, errorString);
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (GLuint)createProgramWithVertexShader:(NSString *)vertexShaderFilename fragmentShader:(NSString *)fragmentShaderFilename
{
    [EAGLContext setCurrentContext:self.context];
    GLuint vertexShader = [self loadShader:vertexShaderFilename type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self loadShader:fragmentShaderFilename type:GL_FRAGMENT_SHADER];
    GLuint prog = glCreateProgram();
    
    glAttachShader(prog, vertexShader);
    glAttachShader(prog, fragmentShader);
    glLinkProgram(prog);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    GLint linked = 0;
    glGetProgramiv(prog, GL_LINK_STATUS, &linked);
    if (linked == 0) {
        glDeleteProgram(prog);
        return 0;
    }
    
    return prog;
}

- (BOOL)setupCurlShader
{
    if ((frontProgram = [self createProgramWithVertexShader:@"FrontVertexShader.glsl" fragmentShader:@"FrontFragmentShader.glsl"]) != 0 &&
        (backProgram = [self createProgramWithVertexShader:@"BackVertexShader.glsl" fragmentShader:@"BackFragmentShader.glsl"]) != 0) {
        glBindAttribLocation(frontProgram, 0, "a_position");
        glBindAttribLocation(frontProgram, 1, "a_texCoord");
        frontMvpHandle               = glGetUniformLocation(frontProgram, "u_mvpMatrix");
        frontSamplerHandle           = glGetUniformLocation(frontProgram, "s_tex");
        frontCylinderPositionHandle  = glGetUniformLocation(frontProgram, "u_cylinderPosition");
        frontCylinderDirectionHandle = glGetUniformLocation(frontProgram, "u_cylinderDirection");
        frontCylinderRadiusHandle    = glGetUniformLocation(frontProgram, "u_cylinderRadius");
        
        glBindAttribLocation(backProgram, 0, "a_position");
        glBindAttribLocation(backProgram, 1, "a_texCoord");
        backMvpHandle               = glGetUniformLocation(backProgram, "u_mvpMatrix");
        backSamplerHandle           = glGetUniformLocation(backProgram, "s_tex");
        backGradientSamplerHandle   = glGetUniformLocation(backProgram, "s_gradient");
        backCylinderPositionHandle  = glGetUniformLocation(backProgram, "u_cylinderPosition");
        backCylinderDirectionHandle = glGetUniformLocation(backProgram, "u_cylinderDirection");
        backCylinderRadiusHandle    = glGetUniformLocation(backProgram, "u_cylinderRadius");
        
        return YES;
    }
    
    return NO;
}

- (void)destroyCurlShader
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteProgram(frontProgram);
    frontProgram = 0;
    glDeleteProgram(backProgram);
    backProgram = 0;
}

- (BOOL)setupNextPageShader
{
    [self destroyNextPageShader];
    
    NSString *vsFilename = nextPageTexture != 0? @"NextPageVertexShader.glsl": @"NextPageNoTextureVertexShader.glsl";
    NSString *fsFilename = nextPageTexture != 0? @"NextPageFragmentShader.glsl": @"NextPageNoTextureFragmentShader.glsl";
    
    if ((nextPageProgram = [self createProgramWithVertexShader:vsFilename fragmentShader:fsFilename]) != 0) {
        glBindAttribLocation(nextPageProgram, 0, "a_position");
        glBindAttribLocation(nextPageProgram, 1, "a_texCoord");
        nextPageMvpHandle               = glGetUniformLocation(nextPageProgram, "u_mvpMatrix");
        nextPageSamplerHandle           = glGetUniformLocation(nextPageProgram, "s_tex");
        nextPageCylinderPositionHandle  = glGetUniformLocation(nextPageProgram, "u_cylinderPosition");
        nextPageCylinderDirectionHandle = glGetUniformLocation(nextPageProgram, "u_cylinderDirection");
        nextPageCylinderRadiusHandle    = glGetUniformLocation(nextPageProgram, "u_cylinderRadius");
        
        return YES;
    }
    
    return NO;
}

- (void)destroyNextPageShader
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteProgram(nextPageProgram);
    nextPageProgram = 0;
}

- (BOOL)setupShaders
{
    if ([self setupCurlShader] && [self setupNextPageShader]) {
        return YES;
    }
    
    return NO;
}

- (void)destroyShaders
{
    [self destroyCurlShader];
    [self destroyNextPageShader];
}

#pragma mark - Textures

- (GLuint)generateTexture
{
    [EAGLContext setCurrentContext:self.context];
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return tex;
}

- (void)drawOnTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height drawBlock:(void (^)(CGContextRef context))drawBlock
{
    [EAGLContext setCurrentContext:self.context];
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = textureWidth * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, textureWidth, textureHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect r = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, r);
    CGContextSaveGState(context);
    
    drawBlock(context);
    
    CGContextRestoreGState(context);
    
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, frontTexture); // Keep the frontTexture bound
    
    CGContextRelease(context);
}

- (void)drawImage:(UIImage *)image onTexture:(GLuint)texture
{
    [self drawImage:image onTexture:texture flipHorizontal:NO];
}

- (void)drawImage:(UIImage *)image onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    [self drawOnTexture:texture width:width height:height drawBlock:^(CGContextRef context) {
        if (flipHorizontal) {
            CGContextTranslateCTM(context, width, height);
            CGContextScaleCTM(context, -1, -1);
        }
        else {
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, 1, -1);
        }
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    }];
}

- (void)drawView:(UIView *)view onTexture:(GLuint)texture
{
    [self drawView:view onTexture:texture flipHorizontal:NO];
}

- (void)drawView:(UIView *)view onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal
{
    [self drawOnTexture:texture width:view.bounds.size.width height:view.bounds.size.height drawBlock:^(CGContextRef context) {
        if (flipHorizontal) {
            CGContextTranslateCTM(context, view.bounds.size.width*self.screenScale, 0);
            CGContextScaleCTM(context, -self.screenScale, self.screenScale);
        }
        else {
            CGContextScaleCTM(context, self.screenScale, self.screenScale);
        }
        CGFloat horizontalScale =   sqrtl(view.transform.a*view.transform.a + view.transform.b*view.transform.b);
        CGFloat verticalScale =     sqrtl(view.transform.c*view.transform.c + view.transform.d*view.transform.d);
        CGContextScaleCTM(context, horizontalScale, verticalScale);
        
        [view.layer renderInContext:context];
        
    }];
}

- (void)drawImageOnFrontOfPage:(UIImage *)image
{
    [EAGLContext setCurrentContext:self.context];
    [self drawImage:image onTexture:frontTexture];
    
    //Force a redraw to avoid glitches
    [self draw:self.displayLink];
}

- (void)drawViewOnFrontOfPage:(UIView *)view
{
    [EAGLContext setCurrentContext:self.context];
    [self drawView:view onTexture:frontTexture];
    
    //Force a redraw to avoid glitches
    [self draw:self.displayLink];
}

- (void)drawImageOnBackOfPage:(UIImage *)image
{
    [EAGLContext setCurrentContext:self.context];
    
    if (image == nil) {
        [self destroyBackTexture];
        return;
    }
    
    if (backTexture == 0) {
       backTexture = [self generateTexture];
    }
    
    [self drawImage:image onTexture:backTexture flipHorizontal:YES];
}

- (void)drawViewOnBackOfPage:(UIView *)view
{
    [EAGLContext setCurrentContext:self.context];

    if (view == nil) {
        [self destroyBackTexture];
        return;
    }
    
    if (backTexture == 0) {
        backTexture = [self generateTexture];
    }
    
    [self drawView:view onTexture:backTexture flipHorizontal:YES];
}

- (void)destroyBackTexture
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteTextures(1, &backTexture);
    backTexture = 0;
}

- (void)drawImageOnNextPage:(UIImage *)image
{
    [EAGLContext setCurrentContext:self.context];
    
    if (image == nil) {
        if (nextPageTexture != 0) {
            [self destroyNextPageTexture];
            [self setupNextPageShader];
        }
        return;
    }

    if (nextPageTexture == 0) {
        nextPageTexture = [self generateTexture];
        [self setupNextPageShader];
    }
    
    [self drawImage:image onTexture:nextPageTexture];
}

- (void)drawViewOnNextPage:(UIView *)view
{
    [EAGLContext setCurrentContext:self.context];
    
    if (view == nil) {
        if (nextPageTexture != 0) {
            [self destroyNextPageTexture];
            [self setupNextPageShader];
        }
        return;
    }
    
    if (nextPageTexture == 0) {
        nextPageTexture = [self generateTexture];
        [self setupNextPageShader];
    }
    
    [self drawView:view onTexture:nextPageTexture];
}
         
- (void)destroyNextPageTexture
{
    glDeleteTextures(1, &nextPageTexture);
    nextPageTexture = 0;
}

- (void)destroyTextures
{
    glDeleteTextures(1, &frontTexture);
    frontTexture = 0;
    
    glDeleteTextures(1, &backGradientTexture);
    backGradientTexture = 0;
    
    [self destroyNextPageTexture];
    [self destroyBackTexture];
}

- (void)createBackGradientTexture
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"BackPageGradient" ofType:@"png"];
    UIImage *backPageImage = [[UIImage alloc] initWithContentsOfFile:path];
    backGradientTexture = [self generateTexture];
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, backGradientTexture);
    
    size_t width = CGImageGetWidth(backPageImage.CGImage);
    size_t height = CGImageGetHeight(backPageImage.CGImage);
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGRect r = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, r);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, width, 0);
    CGContextScaleCTM(context, -1, 1);
    CGContextDrawImage(context, r, backPageImage.CGImage);
    CGContextRestoreGState(context);  
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    CGContextRelease(context);
}


#pragma mark - View Curling Utils

- (void)curlView:(UIView *)view cylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration
{
    self.curlingView = view;
    CGRect frame = self.frame;
    
    //Reset cylinder properties, positioning it on the right side, oriented vertically
    self.cylinderPosition = CGPointMake(frame.size.width, frame.size.height/2);
    self.cylinderAngle = M_PI_2;
    self.cylinderRadius = 20;
    
    //Update the view drawn on the front of the curling page
    [self drawViewOnFrontOfPage:self.curlingView];
    
    //Start the cylinder animation
    __weak XBCurlView *weakSelf = self;
    [self setCylinderPosition:cylinderPosition cylinderAngle:cylinderAngle cylinderRadius:cylinderRadius animatedWithDuration:duration completion:^{
        [weakSelf stopAnimating];
    }];
    
    //Setup the view hierarchy properly
    [self.curlingView.superview addSubview:self];
    self.curlingView.hidden = YES;
    
    //Start the rendering loop
    [self startAnimating];
}

- (void)uncurlAnimatedWithDuration:(NSTimeInterval)duration
{
    [self uncurlAnimatedWithDuration:duration completion:nil];
}

- (void)uncurlAnimatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    CGRect frame = self.frame;
    
    //Animate the cylinder back to its start position at the right side of the screen, oriented vertically
    __weak XBCurlView *weakSelf = self;
    [self setCylinderPosition:CGPointMake(frame.size.width, frame.size.height/2) cylinderAngle:M_PI_2 cylinderRadius:20 animatedWithDuration:duration completion:^{
        //Setup the view hierarchy properly after the animation is finished
        weakSelf.curlingView.hidden = NO;
        [weakSelf removeFromSuperview];
        //Stop the rendering loop since the curlView was removed from its superview and hence won't appear
        [weakSelf stopAnimating];
        if (completion) {
            completion();
        }
    }];
    
    [self startAnimating];
}

#pragma mark - Animation and updating

- (void)startAnimating
{
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAnimating
{
    self.lastTimestamp = 0;
    [self.animationManager stopAllAnimations];
    CADisplayLink *displayLink = self.displayLink;
    self.displayLink = nil;
    // WARNING: self might be deallocated at this point, because the displayLink retains self and since it is released right above,
    // its retainCount might reach zero and in this case it will be deallocated and will also release its target (which is self),
    // which might also get deallocated if it is not retained by anything else like a superview. Therefore, don't touch self after
    // this line.
    [displayLink invalidate];
}

- (void)draw:(CADisplayLink *)sender
{
    [EAGLContext setCurrentContext:self.context];
    
    /* Clear framebuffer */
    glClear(GL_COLOR_BUFFER_BIT);
    
    /* Enable culling. First lets render the front facing triangles. */
    glCullFace(GL_BACK);
    
    /* If the page is not opaque (the curled mesh) enable alpha blending. The glBlendFunc is
     * setup that way bacause the texture has got pre-multiplied alpha. */
    if (!self.pageOpaque) {
        glEnable(GL_BLEND);
    }
    
    /* Draw the nextPage */
    glUseProgram(nextPageProgram);
    
    CGPoint glCylinderPosition = CGPointMake(self.cylinderPosition.x*self.screenScale, (self.bounds.size.height - self.cylinderPosition.y)*self.screenScale);
    CGFloat glCylinderAngle = M_PI - self.cylinderAngle;
    CGFloat glCylinderRadius = self.cylinderRadius*self.screenScale;
    
    glUniform2f(nextPageCylinderPositionHandle, glCylinderPosition.x, glCylinderPosition.y);
    glUniform2f(nextPageCylinderDirectionHandle, cosf(glCylinderAngle), sinf(glCylinderAngle));
    glUniform1f(nextPageCylinderRadiusHandle, glCylinderRadius);
    
    //If it's got a texture, set it. Otherwise it will be drawn transparently but will still cast shadows.
    if (nextPageTexture != 0) {
        glBindTexture(GL_TEXTURE_2D, nextPageTexture);
    }
     
    glBindVertexArrayOES(nextPageVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    /* Draw the previousPage if any */
    /* TODO */
    
    /* Draw the front facing triangles of the curled mesh (GL_BACK was set above, hence backfaces will be culled here) */
    glUseProgram(frontProgram);
    
    glUniform2f(frontCylinderPositionHandle, glCylinderPosition.x, glCylinderPosition.y);
    glUniform2f(frontCylinderDirectionHandle, cosf(glCylinderAngle), sinf(glCylinderAngle));
    glUniform1f(frontCylinderRadiusHandle, glCylinderRadius);
    
    if (backTexture != 0 || nextPageTexture != 0) { // In this case the frontTexture should already be bound, since it's the only texture around
        glBindTexture(GL_TEXTURE_2D, frontTexture);
    }
    
    glBindVertexArrayOES(frontVAO);
    glDrawElements(GL_TRIANGLES, elementCount, GL_UNSIGNED_SHORT, (void *)0);
    
    /* Next draw the back faces (the vertex buffer is already bound) */
    glCullFace(GL_FRONT);
    
    glUseProgram(backProgram);
    
    glUniform2f(backCylinderPositionHandle, glCylinderPosition.x, glCylinderPosition.y);
    glUniform2f(backCylinderDirectionHandle, cosf(glCylinderAngle), sinf(glCylinderAngle));
    glUniform1f(backCylinderRadiusHandle, glCylinderRadius);
    
    if (backTexture != 0) {
        glBindTexture(GL_TEXTURE_2D, backTexture);
    }
    
    glBindVertexArrayOES(backVAO);
    glDrawElements(GL_TRIANGLES, elementCount, GL_UNSIGNED_SHORT, (void *)0);
    
    glBindVertexArrayOES(0);
    
    //Disable blending for now
    if (!self.pageOpaque) {
        glDisable(GL_BLEND);
    }
    
    /* If antialiasing is enabled, draw on the multisampling buffers */
    if (self.antialiasing) {
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, framebuffer);
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, sampleFramebuffer);
        glResolveMultisampleFramebufferAPPLE();
        
        GLenum attachments[] = {GL_COLOR_ATTACHMENT0};
        glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
        
        glBindFramebuffer(GL_FRAMEBUFFER, sampleFramebuffer);
    }
    
    /* Finally, present, swap buffers, whatever */
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    /* Update all animations */
    NSTimeInterval dt = sender.duration;
    dt = MAX(0, MIN(dt, 0.2));
    [self.animationManager update:dt];
    // WARNING: self might be deallocated at this point, because the animations that finish invoke their completion blocks which might in
    // turn do anything such as releasing this instance and subsequently deallocating it. Hence, do not touch self after this line.
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"OpenGL error: 0x%X", error);
    }
#endif
}

@end

#pragma mark - Functions

void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far)
{
    out[0] = 2.f/(right-left); out[4] = 0.f; out[8] = 0.f; out[12] = -(right+left)/(right-left);
    out[1] = 0.f; out[5] = 2.f/(top-bottom); out[9] = 0.f; out[13] = -(top+bottom)/(top-bottom);
    out[2] = 0.f; out[6] = 0.f; out[10] = -2.f/(far-near); out[14] = -(far+near)/(far-near);
    out[3] = 0.f; out[7] = 0.f; out[11] = 0.f; out[15] = 1.f;
}

void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}
