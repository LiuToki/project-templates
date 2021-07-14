/**
 * @file Premiere.tsx
 * @author LiuToki
 * @date 2021-07-14
 * 
 * Copyright 2021 杜若.
 * 
 */

$.global.premiere = {
	messageHello : function () {
		const homeDir = new File("~/");
		let userName: string = homeDir.displayName;
		alert("Hello " + userName + ", This Premiere Pro Version is " + String(app.version));
	}
}
