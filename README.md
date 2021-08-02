<h1 align="center">ppro-ext-cep-typescript-react</h1>

<div align="center">
    <strong>A Typescript React Project Template for Adobe Premiere Pro Extension.</strong>
</div>

<br/>

<div align="center">
    <sub>
        This template using Typescript and React.
    </sub>
</div>

<br/>

## Table of Contents
- [Installation](#installation)
- [Features](#features)
- [Requirements](#requirements)
- [Distribution](#distribution)
- [Debug](#debug)
- [Release](#release)
- [Author](#author)
- [LICENSE](#license)

## Installation
    $ git clone -b ppro-ext-cep-typescript-react https://github.com/LiuToki/project-templates.git

or

    $ wget https://github.com/LiuToki/project-templates/archive/refs/heads/ppro-ext-cep-typescript-react.zip
    $ unzip ppro-ext-cep-typescript-react.zip

## Features
- Typescript
- React
- babel
- webpack
- Adobe CEP for Premiere Pro

## Requirements
- nodejs and npm.

## Distribution
Distribution directory structure.

    dist
    ├client
    │ ├client.js
    │ └index.html
    ├CSXS
    │ └manifest.xml
    └host
       ├host.jsx
       └Premiere.jsx

if you copy this folder to [extensions directory](https://github.com/Adobe-CEP/Samples/tree/master/TypeScript/PProPanel-vscode#3-put-panel-into-extensions-directory), you can check this extension's action.

## Debug
    npm run build-dev

## Release
    npm run build-release

## Author
[LiuToki](https://github.com/LiuToki)

## License
[MIT](./LICENCE)
