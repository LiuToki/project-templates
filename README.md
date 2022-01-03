<h1 align="center">siv3d-windows</h1>

<div align="center">
    <strong>A C++ Project Template for using Siv3d</strong>
</div>

<br/>

<div align="center">
    <sub>
        This template using siv3d.<br>
		For windows only.
    </sub>
</div>

<br/>

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
	- [Getting sources](#getting-sources)
	- [Rename files](#rename-files)
	- [Library settings](#library-settings)
- [Features](#features)
- [Author](#author)
- [License](#license)

## Installation
### Getting sources
    $ git clone -b siv3d-windows https://github.com/LiuToki/project-templates.git

or

    $ wget https://github.com/LiuToki/project-templates/archive/refs/heads/siv3d-windows.zip
    $ unzip siv3d-windows.zip

### Rename files
ファイルのいたるところにある名前を使用するところのプロジェクト名に合わせて変更します。  
ソリューションファイルもいますが、削除して新しいソリューションに入れ込む形で良いと思います。
まずは、下記のファイルのsiv3d-windows を変更しましょう。  

	siv3d-windows.vcxproj
	siv3d-windows.vcxproj.filters

つぎにwiv3d-windows.vcxproj を開いて、RootNamespace をプロジェクト名に合わせて変更します(スネークケース)。

### Library settings
[SDK](https://siv3d.jp/downloads/Siv3D/manual/0.6.3/OpenSiv3D_SDK_0.6.3.zip)を展開し、include ディレクトリとlib ディレクトリをLibrary\Siv3D にコピーします。

## Features
- C++
- [Siv3d(0.6.3)](https://github.com/Siv3D/OpenSiv3D)

## Author
[LiuToki](https://github.com/LiuToki)

## License
[MIT](./LICENCE)
