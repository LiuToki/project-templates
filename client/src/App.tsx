/**
 * @file App.tsx
 * @author LiuToki
 * @date 2021-07-14
 * 
 * Copyright 2020 杜若.
 * 
 */
import React from "react";
import { runEvalScript } from "./helper";

/**
 * @description Application Root.
 * @returns DOM.
 */
const App: React.FC<{}> = () => {
	const handleOnClick = () => {
		runEvalScript("premiere.messageHello()")
		.then(() => {
			window.alert("success");
		})
		.catch((e) => {
			window.alert(e);
		});

		runEvalScript("badFunctionCall()")
		.then(() => {
			window.alert("success");
		})
		.catch((e) => {
			window.alert("Error message for bad function call is: " + e);
		});	
	}

	return (
		<div>
			<div>
				<p style={{color:"#FFFFFF"}}>Hello world. Click Following Button!</p>
			</div>
			<div>
				<button onClick={() => handleOnClick()}>Hello</button>
			</div>
		</div>
	);
}

export default App;
