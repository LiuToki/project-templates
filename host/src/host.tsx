/**
 * @file host.tsx
 * @author LiuToki
 * @date 2021-07-14
 * 
 * Copyright 2021 杜若.
 * 
 */

$.global._ext = {
	//Evaluate a file and catch the exception.
	evalFile : function (path: File | Folder) {
		try {
			if (path instanceof File) {
				$.evalFile(path);
			}
		} catch (e) {
			alert("Exception:" + e);
		}
	},
	// Evaluate all the files in the given folder 
	evalFiles : function (jsxFolderPath: string) {
		const folder = new Folder(jsxFolderPath);
		if (folder.exists) {
			const jsxFiles = folder.getFiles("*.jsx");
			for (let i = 0; i < jsxFiles.length; i++) {
				const jsxFile = jsxFiles[i];
				$.global._ext.evalFile(jsxFile);
			}
		}
	}
};

