"
Provides **debugger-aware tools** to the LLM during an intelligent
debugging session.

Wraps a `ChatPharoDebuggerContext` snapshot and exposes tool functions
such as:
  * `get_error_details`     – the exception class, message, and signaler
  * `get_stack_trace`       – the call chain leading to the error
  * `get_local_variables`   – temps and args in the failing frame
  * `get_receiver_state`    – instance variables of the receiver
  * `get_method_source_in_stack` – source of any method visible in the stack

Combined with the regular `ChatPharoBrowserEnvironment` tools (which
let the LLM browse packages, classes, methods in the live image), this
gives the assistant everything it needs to diagnose bugs autonomously.

**Why** – the old debugger integration sent only a method's source and
asked 'explain this'.  This class turns ChatPharo into an actual
debugging partner that can reason over error context.
"
Class {
	#name : 'ChatPharoDebuggerEnvironment',
	#superclass : 'Object',
	#instVars : [
		'debuggerContext',
		'tools'
	],
	#category : 'AI-ChatPharo-Env-Debugger',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Debugger'
}

{ #category : 'instance creation' }
ChatPharoDebuggerEnvironment class >> forContext: aChatPharoDebuggerContext [

	^ self basicNew
		  initializeWithContext: aChatPharoDebuggerContext;
		  yourself
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> debuggerContext [ 

	^ debuggerContext
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetClassHierarchy [

	^ ChatPharoClient
		  name: 'get_class_hierarchy'
		  description: 'Returns the class hierarchy (superclasses) for a given class, including instance variable names and protocols at each level. Useful for understanding inheritance context when debugging.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'class_name' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The class name to inspect (e.g. OrderedCollection)'))
			   with: 'required' -> #( 'class_name' ))
		  block: [ :arguments |
			  | className theClass hierarchy cls |
			  className := arguments at: 'class_name'.
			  theClass := Smalltalk classNamed: className.
			  theClass ifNil: [
				  ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].
			  hierarchy := OrderedCollection new.
			  cls := theClass.
			  [ cls notNil and: [ hierarchy size < 15 ] ] whileTrue: [
				  hierarchy add: (Dictionary new
					  at: 'name' put: cls name asString;
					  at: 'instanceVariables' put: (cls instVarNames collect: #asString) asArray;
					  at: 'methodCount' put: cls localMethods size;
					  yourself).
				  cls := cls superclass ].
			  Dictionary
				  with: 'class' -> className
				  with: 'hierarchy' -> hierarchy asArray
				  with: 'depth' -> hierarchy size ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetErrorDetails [

	^ ChatPharoClient
		  name: 'get_error_details'
		  description: 'Returns the exception class name, error message, and failing method information from the current debugger session.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  Dictionary new
				  at: 'exception_class' put: (debuggerContext errorClassName ifNil: [ 'Unknown' ]);
				  at: 'error_message' put: (debuggerContext errorMessage ifNil: [ 'No message' ]);
				  at: 'failing_class' put: (debuggerContext failingClassName ifNil: [ 'Unknown' ]);
				  at: 'failing_selector' put: (debuggerContext failingSelector ifNil: [ 'unknown' ]);
				  at: 'failing_package' put: (debuggerContext failingPackageName ifNil: [ 'Unknown' ]);
				  yourself ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetImplementors [

	^ ChatPharoClient
		  name: 'get_implementors'
		  description: 'Returns all classes that implement a given selector. Helps understand which classes provide this method and whether a missing override or wrong dispatch is causing the bug.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The selector to find implementors of (e.g. add:)'))
			   with: 'required' -> #( 'selector' ))
		  block: [ :arguments |
			  | selector implementors maxResults |
			  selector := arguments at: 'selector'.
			  maxResults := 30.
			  implementors := (Smalltalk allClassesAndTraits
				  select: [ :cls | cls includesSelector: selector asSymbol ]
				  thenCollect: [ :cls | cls name asString ]).
			  implementors size > maxResults ifTrue: [
				  implementors := implementors first: maxResults ].
			  Dictionary
				  with: 'selector' -> selector
				  with: 'implementors' -> implementors asArray
				  with: 'count' -> implementors size ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetLocalVariables [

	^ ChatPharoClient
		  name: 'get_local_variables'
		  description: 'Returns all local variable names and their current values from the failing stack frame (arguments and temporaries).'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | vars |
			  vars := debuggerContext localVariables.
			  (vars isNil or: [ vars isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No local variables captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'variables' -> vars
						  with: 'count' -> vars size ] ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetMethodSourceInStack [

	^ ChatPharoClient
		  name: 'get_method_source_in_stack'
		  description: 'Returns the source code of any method visible in the stack trace. Provide the class name and selector.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'class_name' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The class name (e.g. OrderedCollection)')
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The method selector (e.g. add:)'))
			   with: 'required' -> #( 'class_name' 'selector' ))
		  block: [ :arguments |
			  | className selector theClass method |
			  className := arguments at: 'class_name'.
			  selector := arguments at: 'selector'.
			  theClass := Smalltalk classNamed: className.
			  theClass ifNil: [
				  ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].
			  method := theClass lookupSelector: selector asSymbol.
			  method ifNil: [
				  ^ Dictionary with: 'error' -> ('Method not found: ' , className , '>>' , selector) ].
			  Dictionary
				  with: 'class' -> className
				  with: 'selector' -> selector
				  with: 'source' -> method sourceCode
				  with: 'protocol' -> method protocolName ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetReceiverState [

	^ ChatPharoClient
		  name: 'get_receiver_state'
		  description: 'Returns the instance variable names and values of the receiver (self) in the failing stack frame.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | state |
			  state := debuggerContext receiverState.
			  (state isNil or: [ state isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No receiver state captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'receiver_class' -> (debuggerContext receiverClassName ifNil: [ 'Unknown' ])
						  with: 'instance_variables' -> state
						  with: 'count' -> state size ] ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetSenders [

	^ ChatPharoClient
		  name: 'get_senders'
		  description: 'Returns methods that send a given selector. Helps trace how the failing method was called and understand the call chain that led to the bug.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The selector to find senders of (e.g. add:)'))
			   with: 'required' -> #( 'selector' ))
		  block: [ :arguments |
			  | selector senders maxResults |
			  selector := arguments at: 'selector'.
			  maxResults := 30.
			  senders := SystemNavigation default allSendersOf: selector asSymbol.
			  senders := senders collect: [ :ref |
				  ref methodClass name asString , '>>' , ref selector asString ].
			  senders size > maxResults ifTrue: [
				  senders := senders first: maxResults ].
			  Dictionary
				  with: 'selector' -> selector
				  with: 'senders' -> senders asArray
				  with: 'count' -> senders size ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetStackFrameDetails [

	^ ChatPharoClient
		  name: 'get_stack_frame_details'
		  description: 'Returns detailed information for the top stack frames captured from the debugger, including local variable names and values at each frame. More detailed than get_stack_trace.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | details |
			  details := debuggerContext stackFrameDetails.
			  (details isNil or: [ details isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No detailed frame info captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'frames' -> details asArray
						  with: 'count' -> details size ] ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionGetStackTrace [

	^ ChatPharoClient
		  name: 'get_stack_trace'
		  description: 'Returns the full stack trace from the debugger session, showing the call chain that led to the error.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | trace |
			  trace := debuggerContext stackTrace.
			  (trace isNil or: [ trace isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No stack trace captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'frames' -> trace
						  with: 'depth' -> trace size ] ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionRecreateBugRecipe [

	^ ChatPharoClient
		  name: 'build_bug_reproduction_recipe'
		  description: 'Builds a deterministic recipe to reproduce the same bug from the current debugger snapshot, including setup assumptions, trigger steps, and expected failure.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | className selector exception message stack receiver vars lines |
			  className := debuggerContext failingClassName ifNil: [ 'UnknownClass' ].
			  selector := debuggerContext failingSelector ifNil: [ 'unknownSelector' ].
			  exception := debuggerContext errorClassName ifNil: [ 'Error' ].
			  message := debuggerContext errorMessage ifNil: [ 'No message captured' ].
			  stack := debuggerContext stackTrace ifNil: [ #() ].
			  receiver := debuggerContext receiverState ifNil: [ Dictionary new ].
			  vars := debuggerContext localVariables ifNil: [ Dictionary new ].
			  lines := OrderedCollection new.
			  lines add: '1) Open a workspace and load the package containing ' , className , '>>' , selector , '.'.
			  lines add: '2) Ensure the object state matches the debugger snapshot (receiver + temp values shown below).'.
			  lines add: '3) Evaluate the failing send that reaches ' , className , '>>' , selector , '.'.
			  lines add: '4) Confirm the debugger raises ' , exception , ' with message: ' , message , '.'.
			  lines add: '5) Verify the top stack frames match the captured stack trace before changing code.'.
			  Dictionary new
				  at: 'summary' put: 'Recipe generated from debugger snapshot';
				  at: 'failing_method' put: (className , '>>' , selector);
				  at: 'expected_exception' put: exception;
				  at: 'expected_message' put: message;
				  at: 'steps' put: lines asArray;
				  at: 'captured_stack_trace' put: stack;
				  at: 'captured_receiver_state' put: receiver;
				  at: 'captured_local_variables' put: vars;
				  yourself ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> functionSuggestFix [

	^ ChatPharoClient
		  name: 'suggest_fix_code'
		  description: 'After analyzing the error, use this tool to propose a concrete code fix. Provide the class, selector, and corrected Smalltalk source.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'class_name' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The class containing the method to fix')
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The selector of the method to fix')
					    with: 'fixed_source' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The corrected Smalltalk source code for the method'))
			   with: 'required' -> #( 'class_name' 'selector' 'fixed_source' ))
		  block: [ :arguments |
			  "We do NOT auto-apply the fix. We return it for the user to review."
			  Dictionary
				  with: 'status' -> 'fix_proposed'
				  with: 'class' -> (arguments at: 'class_name')
				  with: 'selector' -> (arguments at: 'selector')
				  with: 'proposed_source' -> (arguments at: 'fixed_source')
				  with: 'note' -> 'The fix has been proposed to the user for review. It will NOT be applied automatically.' ]
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> initializeWithContext: aChatPharoDebuggerContext [

	super initialize.
	debuggerContext := aChatPharoDebuggerContext.
	tools := {
		         self functionGetErrorDetails.
		         self functionGetStackTrace.
		self functionGetStackFrameDetails.
		         self functionGetLocalVariables.
		         self functionGetReceiverState.
		 self functionGetClassHierarchy.
		         self functionGetSenders.
		         self functionGetImplementors.
		         self functionGetMethodSourceInStack.
				self functionRecreateBugRecipe.
		         self functionSuggestFix } asOrderedCollection
]

{ #category : 'tools' }
ChatPharoDebuggerEnvironment >> tools [

	^ tools
]
