"
Debugger command that opens an **intelligent debugging session** in
ChatPharo.  Unlike the basic 'Ask ChatPharo' command (which only sends
the method source), this command:

  1. Extracts the full error context (exception, message, stack trace,
     local variables, receiver instance-variable state).
  2. Registers debugger-specific tools so the LLM can inspect the
     stack, look up method sources, and propose fixes.
  3. Builds a rich diagnostic prompt and opens a ChatPharo chat with
     a system prompt tuned for bug diagnosis.

The command appears in the debugger's stack-frame context menu as
**Intelligent Debug with ChatPharo**.
"
Class {
	#name : 'StIntelligentDebugChatPharoCommand',
	#superclass : 'StDebuggerCommand',
	#category : 'AI-ChatPharo-Env-Debugger',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Debugger'
}

{ #category : 'default' }
StIntelligentDebugChatPharoCommand class >> defaultDescription [


	^ 'Intelligent Debug: capture error context and open ChatPharo with diagnostic tools.'
]

{ #category : 'initialization' }
StIntelligentDebugChatPharoCommand class >> defaultIconName [

	^ #chatPharoIcon
]

{ #category : 'default' }
StIntelligentDebugChatPharoCommand class >> defaultName [

	^ 'Intelligent Debug with ChatPharo'
]

{ #category : 'initialization' }
StIntelligentDebugChatPharoCommand class >> defaultShortcut [

	^ nil
]

{ #category : 'default' }
StIntelligentDebugChatPharoCommand class >> icon [

	^ ChatPharoIcons chatPharoIcon
]

{ #category : 'testing' }
StIntelligentDebugChatPharoCommand >> appliesTo: aDebugger [

	^ ChatPharoSettings default askFeatureEnabled
		and: [ aDebugger selectedContext notNil ]
]

{ #category : 'executing' }
StIntelligentDebugChatPharoCommand >> execute [

	ChatPharo codeAndFixFromDebugger: self debugger
]
