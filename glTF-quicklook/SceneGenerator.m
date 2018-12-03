//
//  SceneGenerator.m
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import "SceneGenerator.h"

#import "GLTFErrorCheckerByJSON.h"
#import "GLTFErrorCheckerByScenes.h"

@import GLTF;
@import GLTFSCN;

@implementation SceneGenerator

+ (CFDataRef)sceneDataByURL:(CFURLRef)url {
    return [SceneGenerator archivedScene:[SceneGenerator sceneByURL:url]];
}

+ (SCNScene *)sceneByURL:(CFURLRef)url {
    return [SceneGenerator sceneByNSURL:(__bridge NSURL*)url];
}

+ (SCNScene *)sceneByNSURL:(NSURL*)url {
    SCNScene *scene = nil;
    
    if (![GR isGoodGLTFByName:url.path.UTF8String]) {
        return [SceneGenerator errorScene];
    }
    
    id<GLTFBufferAllocator> bufferAllocator = [[GLTFDefaultBufferAllocator alloc] init];
    GLTFAsset *asset = [[GLTFAsset alloc] initWithURL:url bufferAllocator:bufferAllocator];
    
    if (asset == nil || ![GLTFErrorCheckerByScenes isGoodGLTFByScenes:asset.scenes]) {
        return [SceneGenerator errorScene];
    }
    
    GLTFSCNAsset *scnAsset = [SCNScene assetFromGLTFAsset:asset options:@{}];
    scene = scnAsset.defaultScene;
    [SceneGenerator setAnimationsToScene:scene scnAsset:scnAsset];
    
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

+ (void) setAnimationsToScene: (SCNScene*) scene scnAsset:(GLTFSCNAsset *)scnAsset {
    NSDictionary *animations = scnAsset.animations;
    
    if (animations.count != 0) {
        NSString *name = scnAsset.animations.allKeys.firstObject;
#if DEBUG
        NSLog(@"Animation name: %@", name);
#endif
        
        [animations[name] enumerateObjectsUsingBlock:^(GLTFSCNAnimationTargetPair *pair, NSUInteger index, BOOL *stop) {
            pair.animation.usesSceneTimeBase = NO;
            [pair.target addAnimation:pair.animation forKey:nil];
        }];
    }
}



@end
