/**
 * @file index.tsx
 * @author LiuToki
 * @date 2021-07-14
 * 
 * Copyright 2021 杜若.
 * 
 */
import React from "react"
import ReactDom from "react-dom"
import App from "./App"
import { runEvalScript, getExtensionRoot } from "./helper";

/**
 * @description Load jsx files.
 * @note Load JSX file into the scripting context of the product. All the jsx files in \
 * folder [ExtensionRoot]/host will be loaded. 
 */
const loadJSX = () => {
	let extensionRoot: string = getExtensionRoot() + "/host/";
	const script: string = "_ext.evalFiles(\"" + extensionRoot + "\")";
	runEvalScript(script)
	.then(() => {
		window.alert("success to load all other jsx files.");
	})
	.catch((e) => {
		window.alert(e);
	});
}

/**
 * @description Do somthing at load timing.
 */
window.addEventListener("load", (e) => {
	loadJSX();
})

/**
 * @description Render to root at index.html.
 */
ReactDom.render(
	<App />,
	document.getElementById("root")
)
