// Copyright 2018-present 650 Industries. All rights reserved.

#import <ABI30_0_0EXReactNativeAdapter/ABI30_0_0EXReactFontManager.h>
#import <ABI30_0_0EXFontInterface/ABI30_0_0EXFontProcessorInterface.h>
#import <ReactABI30_0_0/ABI30_0_0RCTFont.h>
#import <ABI30_0_0EXCore/ABI30_0_0EXAppLifecycleService.h>
#import <objc/runtime.h>

static __weak NSArray<id<ABI30_0_0EXFontProcessorInterface>> *currentFontProcessors;

@implementation ABI30_0_0RCTFont (ABI30_0_0EXReactFontManager)

+ (UIFont *)ABI30_0_0EXUpdateFont:(UIFont *)uiFont
              withFamily:(NSString *)family
                    size:(NSNumber *)size
                  weight:(NSString *)weight
                   style:(NSString *)style
                 variant:(NSArray<NSDictionary *> *)variant
         scaleMultiplier:(CGFloat)scaleMultiplier
{
  NSArray<id<ABI30_0_0EXFontProcessorInterface>> *fontProcessors = currentFontProcessors;
  UIFont *font;
  for (id<ABI30_0_0EXFontProcessorInterface> fontProcessor in fontProcessors) {
    font = [fontProcessor updateFont:uiFont withFamily:family size:size weight:weight style:style variant:variant scaleMultiplier:scaleMultiplier];
    if (font) {
      return font;
    }
  }

  return [self ABI30_0_0EXUpdateFont:uiFont withFamily:family size:size weight:weight style:style variant:variant scaleMultiplier:scaleMultiplier];
}

@end

/**
 * This class is responsible for allowing other modules to register as font processors in ReactABI30_0_0 Native.
 *
 * A font processor is an object conforming to ABI30_0_0EXFontProcessorInterface and is capable of
 * providing an instance of UIFont for given (family, size, weight, style, variant, scaleMultiplier).
 *
 * To be able to hook into ReactABI30_0_0 Native's way of processing fonts we:
 *  - add a new class method to ABI30_0_0RCTFont, `ABI30_0_0EXUpdateFont:withFamily:size:weight:style:variant:scaleMultiplier`
 *    with ABI30_0_0EXReactFontManager category.
 *  - add a new static variable `currentFontProcessors` holding an array of... font processors. This variable
 *    is shared between the ABI30_0_0RCTFont's category and ABI30_0_0EXReactFontManager class.
 *  - when ABI30_0_0EXReactFontManager is initialized, we exchange implementations of ABI30_0_0RCTFont.updateFont...
 *    and ABI30_0_0RCTFont.ABI30_0_0EXUpdateFont... After the class initialized, which happens only once, calling `ABI30_0_0RCTFont updateFont`
 *    calls in fact implementation we've defined up here and calling `ABI30_0_0RCTFont ABI30_0_0EXUpdateFont` falls back
 *    to the default implementation. (This is why we call `[self ABI30_0_0EXUpdateFont]` at the end of that function,
 *    though it seems like an endless loop, in fact we dispatch to another implementation.)
 *  - When some module adds a font processor using ABI30_0_0EXFontManagerInterface, ABI30_0_0EXReactFontManager adds it
 *    to fontProcessors array instance variable. The static currentFontProcessors variable should always point
 *    to the fontProcessors array of a foregrounded app/experience (see `- (void)maybeUpdateStaticFontProcessors`).
 *  - Implementation logic of `ABI30_0_0RCTFont.ABI30_0_0EXUpdateFont` uses current value of currentFontProcessors when processing arguments.
 */

@interface ABI30_0_0EXReactFontManager ()

@property (nonatomic, assign) BOOL isForegrounded;
@property (nonatomic, strong) NSMutableArray<id<ABI30_0_0EXFontProcessorInterface>> *fontProcessors;
@property (nonatomic, weak) id<ABI30_0_0EXAppLifecycleService> lifecycleManager;

@end

@implementation ABI30_0_0EXReactFontManager

ABI30_0_0EX_REGISTER_MODULE();

- (instancetype)init
{
  if (self = [super init]) {
    _isForegrounded = true;
    _fontProcessors = [NSMutableArray array];
  }
  return self;
}

+ (const NSArray<Protocol *> *)exportedInterfaces
{
  return @[@protocol(ABI30_0_0EXFontManagerInterface)];
}

+ (void)initialize
{
  Class rtcClass = [ABI30_0_0RCTFont class];
  SEL rtcUpdate = @selector(updateFont:withFamily:size:weight:style:variant:scaleMultiplier:);
  SEL exUpdate = @selector(ABI30_0_0EXUpdateFont:withFamily:size:weight:style:variant:scaleMultiplier:);
  
  method_exchangeImplementations(class_getClassMethod(rtcClass, rtcUpdate),
                                 class_getClassMethod(rtcClass, exUpdate));
}

- (void)setModuleRegistry:(ABI30_0_0EXModuleRegistry *)moduleRegistry
{
  if (_lifecycleManager) {
    [_lifecycleManager unregisterAppLifecycleListener:self];
  }
  
  _lifecycleManager = nil;
  
  if (moduleRegistry) {
    _lifecycleManager = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI30_0_0EXAppLifecycleService)];
  }
  
  if (_lifecycleManager) {
    [_lifecycleManager registerAppLifecycleListener:self];
  }
}

# pragma mark - ABI30_0_0EXFontManager

- (void)onAppBackgrounded {
  _isForegrounded = false;
  [self maybeUpdateStaticFontProcessors];
}

- (void)onAppForegrounded {
  _isForegrounded = true;
  [self maybeUpdateStaticFontProcessors];
}

# pragma mark - ABI30_0_0EXFontManager

- (void)addFontProccessor:(id<ABI30_0_0EXFontProcessorInterface>)processor
{
  [_fontProcessors addObject:processor];
  [self maybeUpdateStaticFontProcessors];
}

# pragma mark - Internals

- (void)maybeUpdateStaticFontProcessors
{
  if (_isForegrounded) {
    currentFontProcessors = _fontProcessors;
  } else if (currentFontProcessors == _fontProcessors) {
    currentFontProcessors = nil;
  }
}

- (void)dealloc
{
  if (_lifecycleManager) {
    [_lifecycleManager unregisterAppLifecycleListener:self];
  }
}

@end
