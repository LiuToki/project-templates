<h1 align="center">rp2040-cpp-dev</h1>

<div align="center">
    <strong>A C++ dev starter for RP2040</strong>
</div>

<br/>

<div align="center">
    <sub>
        This template is intended for development for the RP2040 on the Raspberry Pi.
    </sub>
</div>

<br/>

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [How to Build](#how-to-build)
- [Features](#features)
- [Author](#author)
- [LICENSE](#license)

## Requirements
```
$ sudo apt install git cmake gcc-arm-none-eabi gcc g++ libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib build-essential ninja-build
```

## Installation
### Clone source code.
    $ git clone -b rp2040-cpp-dev https://github.com/LiuToki/project-templates.git
    $ git submodule update
    $ cd libs/pico-sdk
    $ git submodule update --init

### Download zip.
    $ wget https://github.com/LiuToki/project-templates/archive/refs/heads/rp2040-cpp-dev.zip
    $ unzip rp2040-cpp-dev.zip

clone or copy [pico-sdk](https://github.com/raspberrypi/pico-sdk) into libs as pico-sdk.

## How to Build
```
$ mkdir build
$ cd build
$ cmake -G Ninja ..
$ ninja
```

## Features
- RP2040

## Author
[LiuToki](https://github.com/LiuToki)

## License
[MIT](./LICENCE)