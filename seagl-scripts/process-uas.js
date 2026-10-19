#!/usr/bin/env node

var UAParser = require('ua-parser-js');
var readline = require('readline');

var rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout,
	terminal: false
});

rl.on('line', function(line) {
	line = line.trim();
	if (!line) return;
	if (line.includes(' rows)')) process.exit(0);

	var parser = new UAParser(line);
	var result = parser.getResult();
	console.log(`${result.browser.name || 'unknown'}:${result.os.name.replaceAll(' ', '_') || 'unknown'}`);
});
