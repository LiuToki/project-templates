/**
 * @file helper.tsx
 * @author LiuToki
 * @date 2021-07-14
 * 
 * Copyright 2021 杜若.
 * 
 */
import { CSInterface, SystemPath } from "ts-csinterface";

const csInterface = new CSInterface();

// Error Message.
const EVAL_SCRIPT_ERROR_STRING: string = "EvalScript error.";

/**
 * @description Helper for evalScript call.
 * @param script EvalScript string.
 * @returns Promise.
 */
export const runEvalScript = (script: string) => {
	return new Promise<string>((resolve, reject) => {
		csInterface.evalScript(script, (result) => {
			if (EVAL_SCRIPT_ERROR_STRING == result) {
				reject(result);
			}
			resolve(result);
		});
	})
}

/**
 * @description Get extension root path.
 * @returns Path to extension directory.
 */
export const getExtensionRoot = () => {
	return csInterface.getSystemPath(SystemPath.EXTENSION);
}
