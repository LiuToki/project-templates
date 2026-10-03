<h1 align="center">cpp-vcpkg</h1>

<div align="center">
    <strong>A minimam starter for cpp + vcpkg</strong>
</div>

<br/>

<div align="center">
    <sub>
        This template using C++ with vcpkg.
    </sub>
</div>

<br/>

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Initialize](#initialize)
- [Build](#build)
- [Author](#author)
- [License](#license)

## Requirements
cpp-vcpkgでは下記のパッケージが必要になります。
- C++
- CMake >= 3.14
- vcpkg

## Installation
- clone  
```  
    $ git clone -b cpp-vcpkg https://github.com/LiuToki/project-templates.git  
```

- zip  
```
    $ wget https://github.com/LiuToki/project-templates/archive/refs/heads/cpp-vcpkg.zip  
    $ unzip cpp-vcpkg.zip
```
## Initialize
- clone
```
$ git submodule init
$ git submodule update
```
- zip  
```
$ git init
$ git submodule init
$ git submodule add https://github.com/microsoft/vcpkg.git libs/vcpkg
```

## Build
- CMake >= 3.21
```
$ cmake --build --preset <preset_name>
```

- otherwise
```
$ cmake --preset <preset_name>
$ cmake --build --preset <preset_name>
```

## Author
[LiuToki](https://github.com/LiuToki)

## License
[MIT](./LICENCE)

# 開発者向け
## フォルダ分けについて
ルートディレクトリにプロジェクトごとにフォルダを作るようにしました