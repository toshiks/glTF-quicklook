#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "GLTFErrorCheckerByJSON.h"
#import "GLTFErrorCheckerByScenes.h"

@import SceneKit;
@import GLTF;
@import GLTFSCN;

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

CFDataRef archivedScene(const SCNScene *scene) {
    return (__bridge CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:scene requiringSecureCoding:NO error:nil];
}

void setAnimations(SCNScene *scene, GLTFSCNAsset *scnAsset) {
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

void setErrorScene(SCNScene *scene) {
#if DEBUG
    NSLog(@"Error Scene");
#endif
    SCNBox *geometry = [[SCNBox alloc] init];
    geometry.firstMaterial.diffuse.contents = [NSColor redColor];
    
    SCNNode *node = [[SCNNode alloc] init];
    [node setGeometry:geometry];
    
    [scene.rootNode addChildNode:node];
    
#if DEBUG
    NSLog(@"Error scene %@", scene);
#endif
}

void setCompanyLogo(SCNScene *scene) {
    
}


CFDataRef sceneByURL(NSURL* url) {
    SCNScene *scene = nil;
    
    if (![GR isGoodGLTFByName:url.path.UTF8String]) {
        scene = [SCNScene scene];
        setErrorScene(scene);
        setCompanyLogo(scene);
        
        return archivedScene(scene);
    }
    
    
    id<GLTFBufferAllocator> bufferAllocator = [[GLTFDefaultBufferAllocator alloc] init];
    GLTFAsset *asset = [[GLTFAsset alloc] initWithURL:url bufferAllocator:bufferAllocator];
    
    if (asset == nil || ![GLTFErrorCheckerByScenes isGoodGLTFByScenes:asset.scenes]) {
        scene = [SCNScene scene];
        setErrorScene(scene);
    } else {
        GLTFSCNAsset *scnAsset = [SCNScene assetFromGLTFAsset:asset options:@{}];
        scene = scnAsset.defaultScene;
        setAnimations(scene, scnAsset);
    }
    
    setCompanyLogo(scene);
    
    return archivedScene(scene);
}

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    @autoreleasepool {
        
        if(QLPreviewRequestIsCancelled(preview)){
            return noErr;
        }
        
        if(QLPreviewRequestIsCancelled(preview)){
            return noErr;
        }
        
        QLPreviewRequestSetDataRepresentation(preview, sceneByURL((__bridge NSURL*)url), kUTType3DContent, options);
        
        return noErr;
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
