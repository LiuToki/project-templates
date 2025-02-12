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
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Features](#features)
- [Initialize](#initialize)
- [Build](#build)
- [Author](#author)
- [License](#license)

## Installation
    $ git clone -b cpp-vcpkg https://github.com/LiuToki/project-templates.git

or

    $ wget https://github.com/LiuToki/project-templates/archive/refs/heads/cpp-vcpkg.zip
    $ unzip cpp-vcpkg.zip

## Features
- x86_64
- C++
- CMake
- vcpkg

## Initialize
```
$ git submodule init
$ git submodule update
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