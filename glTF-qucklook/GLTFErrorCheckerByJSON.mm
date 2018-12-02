//
//  GLTFErrorChecker.cpp
//  glTF-qucklook
//
//  Created by Klochkov Anton on 02/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//


#include "GLTFErrorCheckerByJSON.h"

#define TINYGLTF_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define TINYGLTF_NO_STB_IMAGE_WRITE

#import "stb_image.h"
#import "tiny_gltf.h"

using namespace tinygltf;

@interface GR ()

bool privateIsGoodGLTF(const char *name);

@end


@implementation GR

+ (bool)isGoodGLTFByName:(const char *)name {
    return privateIsGoodGLTF(name);
}


bool privateIsGoodGLTF(const char *name) {
    Model model;
    TinyGLTF loader;
    std::string err;
    std::string warn;
    
    std::string nameS(name);
    bool ret;
    
    
    try {
        if (nameS[nameS.size() - 1] == 'b') {
            ret = loader.LoadBinaryFromFile(&model, &err, &warn, nameS); // for binary glTF(.glb)
        } else {
            ret = loader.LoadASCIIFromFile(&model, &err, &warn, nameS);
        }
    } catch (...) {
        return false;
    }
    
    if (!warn.empty()) {
#if DEBUG
        NSLog(@"Warn: %s\n", warn.c_str());
#endif
    }
    
    if (!err.empty()) {
#if DEBUG
        NSLog(@"Err: %s\n", err.c_str());
#endif
        return false;
    }
    
    if (!ret) {
#if DEBUG
        NSLog(@"Failed to parse glTF\n");
#endif
        return false;
    }
    
    return true;
}

@end
