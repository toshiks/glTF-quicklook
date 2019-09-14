//
//  SceneGenerator.m
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import "SceneGenerator.h"

#import "TinyGLTFSCN/TinyGLTFSCN.h"
#import "TinyGLTFSCN/GLTFSCNAnimationTargetPair.h"

@implementation SceneGenerator

+ (CFDataRef)sceneDataByURL:(CFURLRef)url {
    return [SceneGenerator archivedScene:[SceneGenerator sceneByURL:url]];
}

+ (SCNScene *)sceneByURL:(CFURLRef)url {
    return [SceneGenerator sceneByNSURL:(__bridge NSURL*)url];
}

+ (SCNScene *)sceneByNSURL:(NSURL*)url {
    TinyGLTFSCN *loader = [[TinyGLTFSCN alloc] init];
    
    if (![loader loadModel:url]) {
        return [SceneGenerator errorScene];
    }
    
    SCNScene *scene = loader.scenes[0];
    [SceneGenerator enableAnimationsToScene:loader.animations];
    
    return scene;
}

+ (CFDataRef) archivedScene: (SCNScene *) scene {
    return (__bridge CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:scene requiringSecureCoding:NO error:nil];
}

+ (SCNScene *) errorScene {
#if DEBUG
    NSLog(@"Error Scene");
#endif
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.ITS.glTF-quicklook"];
    
    NSURL *urlFile =  [bundle URLForResource:@"ErrorSymbol" withExtension:@"scn"];
    
    return [SCNScene sceneWithURL:urlFile options:nil error:nil];
}

+ (void) enableAnimationsToScene:(NSDictionary *)animations {
    if (animations.count == 0) {
        return;
    }
    
    NSString *name = animations.allKeys.firstObject;
#if DEBUG
    NSLog(@"Animation name: %@", name);
#endif
    
    [animations[name] enumerateObjectsUsingBlock:^(GLTFSCNAnimationTargetPair *pair, NSUInteger index, BOOL *stop) {
        pair.animation.usesSceneTimeBase = NO;
        [pair.target addAnimation:pair.animation forKey:nil];
    }];
}



@end
