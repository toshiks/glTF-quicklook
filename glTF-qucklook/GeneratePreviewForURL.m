#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <SceneKit/SceneKit.h>

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

bool checkNodes(NSArray* nds) {
    if (nds == nil){
        return true;
    }
    
    if (nds.count == 0) {
        return true;
    }
    
    for (GLTFNode *node in nds){
        for (GLTFSubmesh *mesh in node.mesh.submeshes) {
            for (NSString *nameAttrib in mesh.accessorsForAttributes.allKeys) {
                
                if (mesh.accessorsForAttributes[nameAttrib] == nil) {
                    return false;
                }
                
                if (mesh.accessorsForAttributes[nameAttrib].bufferView == nil) {
                    return false;
                }
                
                if (mesh.accessorsForAttributes[nameAttrib].bufferView.buffer == nil) {
                    return false;
                }
                
                if (mesh.accessorsForAttributes[nameAttrib].bufferView.buffer.length == 0) {
                    return false;
                }
            }
        }
        
        if (!checkNodes(node.children)){
            return false;
        }
    }
    
    return true;
}

bool checkScenes (NSArray* scns) {
    for (GLTFScene *scene in scns){
        if (!checkNodes(scene.nodes))
            return false;
    }
    return true;
}


CFDataRef sceneByURL(NSURL* url) {
    SCNScene *scene = nil;
    
    id<GLTFBufferAllocator> bufferAllocator = [[GLTFDefaultBufferAllocator alloc] init];
    GLTFAsset *asset = [[GLTFAsset alloc] initWithURL:url bufferAllocator:bufferAllocator];
    if (!checkScenes(asset.scenes)) {
        scene = [SCNScene scene];
        setErrorScene(scene);
    } else {
        GLTFSCNAsset *scnAsset = [SCNScene assetFromGLTFAsset:asset options:@{}];
        scene = scnAsset.defaultScene;
        setAnimations(scene, scnAsset);
    }
        
#if DEBUG
        NSLog(@"%@", scene);
#endif
    setCompanyLogo(scene);

#if DEBUG
    NSLog(@"Finish create Scene");
#endif
    
    return archivedScene(scene);
}

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    @autoreleasepool {
#if DEBUG
        NSLog(@"Start");
#endif
        
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
