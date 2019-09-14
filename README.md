# glTF-quicklook

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/eecaeefcb3854e6181403bea06e0dbcd)](https://www.codacy.com/app/toshiks/glTF-quicklook?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=toshiks/glTF-quicklook&amp;utm_campaign=Badge_Grade)
![status](https://img.shields.io/badge/glTF-2%2E0-green.svg?style=flat)
[![License](http://img.shields.io/:license-mit-blue.svg)](https://github.com/toshiks/glTF-quicklook/blob/master/LICENSE)

Simple QuickLook plugin for previewing gltf-files on macOS.

## Status

v1.1 release(14 Sep, 2019)

## Features
* glTF specification v2.0.0
* Draco compression format
* Animations (not for Draco compression format)
* Textures

## Examples 

![](examples/brainstem.gif)
![](examples/scifihelmet.gif)

## System Requirements

- macOS 10.13 (High Sierra) or later
- installed [Draco compression library](https://github.com/google/draco)

## Install

### Manually

1. In terminal run command: ```brew install draco```
2. Download **glTF-qucklook_vX.X.zip** from [Releases](https://github.com/toshiks/glTF-quicklook/releases/latest).
3. Put **glTF-qucklook.qlgenerator** from zip file into 
    1. `/Library/QuickLook` - for all users;
    2. `~/Library/QuickLook` - only for the logged-in user.
4. Run `qlmanage -r` command to reload QuickLook plugins.


## Licenses

glTF-qucklook is licensed under MIT license.

## Third party licenses
* [tiny-gltf](https://github.com/syoyo/tinygltf) - Copyright (c) 2017 Syoyo Fujita, Aurélien Chatelain
* [GLTFKIT](https://github.com/warrenm/GLTFKit) - Copyright (c) 2017 Warren Moore