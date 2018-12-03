//
//  GLTFErrorCheckerByScenes.m
//  glTF-qucklook
//
//  Created by Klochkov Anton on 02/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import "GLTFErrorCheckerByScenes.h"

@import GLTF;
@import GLTFSCN;
@import SceneKit;

@implementation GLTFErrorCheckerByScenes

+ (bool)isGoodGLTFByScenes:(NSArray *)scenes {
    for (GLTFScene *scene in scenes){
        if (![GLTFErrorCheckerByScenes checkNodes:scene.nodes])
            return false;
    }
    return true;
}

+ (bool) checkNodes:(NSArray*) nodes {
    if (nodes == nil){
        return true;
    }
    
    if (nodes.count == 0) {
        return true;
    }
    
    for (GLTFNode *node in nodes){
        for (GLTFSubmesh *mesh in node.mesh.submeshes) {
            for (NSString *nameAttrib in mesh.accessorsForAttributes.allKeys) {
                
                GLTFAccessor *accessor = mesh.accessorsForAttributes[nameAttrib];
                if (accessor == nil) {
                    return false;
                }
                
                GLTFBufferView *bufferView = accessor.bufferView;
                if (bufferView == nil) {
                    return false;
                }
                
                id<GLTFBuffer> buffer = bufferView.buffer;
                if (buffer == nil) {
                    return false;
                }
                
                if (buffer.length == 0) {
                    return false;
                }
            }
        }
        
        if (![GLTFErrorCheckerByScenes checkNodes:node.children]){
            return false;
        }
    }
    
    return true;
}


@end
