"
Iceberg commit comment panel extension that adds a button to generate commit messages with ChatPharo.

It reuses the standard comment panel and injects a prompt tailored to the configured commit template.
"
Class {
	#name : 'ChatPharoIceTipCommentPanel',
	#superclass : 'IceTipCommentPanel',
	#instVars : [
		'generateButton'
	],
	#category : 'AI-ChatPharo-Env-Iceberg',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Iceberg'
}

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> commitMessageSystemPrompt [

	^ String streamContents: [ :stream |
		stream
			<< 'You are a Pharo developer generating an Iceberg commit message based on a diff.';
			<< String lf;
			<< 'Follow this commit template format and return ONLY the final commit message line:';
			<< String lf;
			<< ChatPharoSettings default commitMessageTemplate;
			<< String lf;
			<< 'Pick one prefix (#feat:, #fix:, #refactor:, #chore:, #comment:) and write an imperative concise message.' ]
]

{ #category : 'layout' }
ChatPharoIceTipCommentPanel >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: commentText;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 5;
				   add: generateButton;
				   addLast: optionsButton;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'private' }
ChatPharoIceTipCommentPanel >> generateCommitMessage [
		
	self chatpharo
]

{ #category : 'initialization' }
ChatPharoIceTipCommentPanel >> initializePresenters [

	super initializePresenters.
	generateButton := self newButton
			 icon: (self application iconNamed: #smallLeftFlush);
			 label: 'Generate commit message';
			 help: 'Generate the commit message based on the work';
			 action: [ self generateCommitMessage ];
			 yourself
]
