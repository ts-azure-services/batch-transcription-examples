//This can work with the raw payload coming out of batch transcription
const fs = require('fs');

// Load the JSON file
const data = JSON.parse(fs.readFileSync('./file_11.txt', 'utf8'));

// Initialize an object to store lexical phrases for each speaker
const speakerPhrases = {};


// Initialize an array to store the ordered statements with speaker information
const orderedStatements = [];

// Function to process the JSON data
const processData = (entry) => {
	const speaker = entry.speaker;
	if (entry.nBest && entry.nBest.length > 0) {
		const lexical = entry.nBest[0].lexical;
		orderedStatements.push({ speaker, lexical });
	} else {
		console.log(`No nBest data for speaker ${speaker}`);
	}
};

// Check if recognizedPhrases is an array
if (Array.isArray(data.recognizedPhrases)) {
	data.recognizedPhrases.forEach(processData);
} else {
	console.log('No recognizedPhrases data found');
}

// Consolidate statements for each speaker
const consolidatedStatements = [];
let currentSpeaker = null;
let currentStatement = '';

orderedStatements.forEach(statement => {
	if (statement.speaker !== currentSpeaker) {
		if (currentSpeaker !== null) {
			consolidatedStatements.push({ speaker: currentSpeaker, lexical: currentStatement.trim() });
		}
		currentSpeaker = statement.speaker;
		currentStatement = statement.lexical;
	} else {
		currentStatement += ` ${statement.lexical}`;
	}
});

// Push the last statement
if (currentSpeaker !== null) {
	consolidatedStatements.push({ speaker: currentSpeaker, lexical: currentStatement.trim() });
}


// Create a JSON object for the final output
const finalOutput = consolidatedStatements.map(statement => ({
	[`Speaker ${statement.speaker}`]: statement.lexical
}));

// Write the final output to a JSON file
fs.writeFileSync('output.json', JSON.stringify(finalOutput, null, 2), 'utf8');

console.log('Output written to output.json');

// // Output the results in the desired format
// consolidatedStatements.forEach(statement => {
// 	console.log(`Speaker ${statement.speaker}: ${statement.lexical}`);
// });
//
