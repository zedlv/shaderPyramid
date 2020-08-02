//
//  MyView.m
//  金字塔可编程着色器
//
//  Created by lvAsia on 2020/8/1.
//  Copyright © 2020 yazhou lv. All rights reserved.
//

#import "MyView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>
@interface MyView(){
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
}
@property(nonatomic, strong) CAEAGLLayer  *myEagLayer;
@property(nonatomic, strong) EAGLContext *myContext;
@property(nonatomic, assign) GLuint myColorRenderBuffer;
@property(nonatomic, assign) GLuint myColorFrameBuffer;
@property(nonatomic, assign) GLuint myProgram;
@property(nonatomic, assign) GLuint myVertices;
@end
@implementation MyView
- (void)layoutSubviews {

    [self setUpLayer];
    [self setContext];
    [self deleBuffer];
    [self setUpRenderBuffer];
    [self setUpFrameBuffer];
    [self render];
    
}
//1. 设置图层
- (void)setUpLayer{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    NSDictionary *dict = @{
        kEAGLDrawablePropertyRetainedBacking:@(NO),
        kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
    };
    self.myEagLayer.drawableProperties = dict;
    
}
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

//2. 设置上下文

- (void)setContext{
    
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context){
        NSLog(@"context init error");
        return;
    }
    if (![EAGLContext setCurrentContext:context]){
        NSLog(@"setCurrentContext error");
        return;
    }
    self.myContext = context;
}
//3. 清空缓存区
- (void)deleBuffer{
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}
//4.设置renderBuffer
- (void)setUpRenderBuffer{
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}
//5.设置FrameBuffer
- (void)setUpFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}
//6. 绘制
- (void)render{
    
    //清屏设置颜色
    glClearColor(0.0, 0.0, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //调整视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    //获取顶点着色器程序和片段着色器程序的文件路径
    NSString *shaderVfile = [[NSBundle mainBundle] pathForResource:@"shaderV" ofType:@"vsh"];
    NSString *shaderFfile = [[NSBundle mainBundle] pathForResource:@"shaderF" ofType:@"fsh"];
    //存在清空
    if (self.myProgram){
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    //加载 绑定 链接 使用
//    self.myProgram =  [self loadShader:shaderVfile frag:shaderFfile];
    self.myProgram = [GLESUtils loadProgram:shaderVfile withFragmentShaderFilepath:shaderFfile];
    //链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    //获取链接状态
    
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE){
        GLchar messages[1024];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        
        return ;
    }
    NSLog(@"link success");
    glUseProgram(self.myProgram);
    
    // 创建顶点数组和索引数组
    GLfloat attArr[] = {
       -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0
       0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1
       -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2
       0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3
       0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4
        
    };
    //索引
    GLuint indices[] = {
       0, 3, 2,
       0, 1, 3,
       0, 2, 4,
       0, 4, 1,
       2, 3, 4,
       1, 4, 3,
    };
    
    // 判断顶点缓冲区是否为空,如果为空则申请一个缓冲区标识
    if (self.myVertices == 0){
        glGenBuffers(1, &_myVertices);
    }
    //处理顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attArr), attArr, GL_DYNAMIC_DRAW);
    // 获取文件中position
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    //打开position
    glEnableVertexAttribArray(position);
    //读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, NULL);
    

   // 获取文件中positionColor
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    //打开positionColor
    glEnableVertexAttribArray(positionColor);
    //读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6,(float *)NULL + 3);

    //获取myProgram中的projectionMatrix、modelViewMatrix
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width/height;
    
    ksPerspective(&_projectionMatrix, 30, aspect, 5.0f, 20.f);
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksTranslate(&_modelViewMatrix, 0, 0, -10.0);
    
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0);
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0);
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0);
    
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
    
 //14.开启剔除操作效果
    glEnable(GL_CULL_FACE);

    glEnable(GL_BLEND);
    //2.开启组合函数 计算混合颜色因子
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    
}


#pragma mark -- Shader
-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    //创建2个临时的变量，verShader,fragShader
    GLuint verShader,fragShader;
    //创建一个Program
    GLuint program = glCreateProgram();
    
    //编译文件
    //编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;
    
}

//链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
     //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器源代码编译成目标代码
    glCompileShader(*shader);
    
}

- (IBAction)roteXAction:(UIButton *)sender {
    if (!myTimer){
        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(roteAction) userInfo:nil repeats:YES];
    }
    bX = !bX;
}
- (IBAction)roteYAction:(UIButton *)sender {
    if (!myTimer){
        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(roteAction) userInfo:nil repeats:YES];
    }
    bY = !bY;
}

- (IBAction)roteZAction:(UIButton *)sender {
    if (!myTimer){
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(roteAction) userInfo:nil repeats:YES];
    }
    bZ = !bZ;
}

- (void)roteAction{
    xDegree += bX*5;
    yDegree += bY*5;
    zDegree += bZ*5;
    [self render];
}
/*
 1.使用scheduledTimerWithTimeInterval

 类方法创建计时器和进度上当前运行循环在默认模式（NSDefaultRunLoopMode）

 2.使用timerWithTimerInterval

 类方法创建计时器对象没有调度运行循环（RunLoop）

 在创建它，必须手动添加计时器运行循环，通过调用adddTimer:forMode:方法相应的NSRunLoop对象

 3.使用initWithFireDate

 在创建它，必须手动添加计时器运行循环，通过使用addTimer:forMode:方法相应的NSRunLoop对象
 */
@end
