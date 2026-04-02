Class {
	#name : 'ChatPharoDebuggerEnvironmentTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Debugger',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Debugger'
}

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testCreation [

	| ctx env |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	self assert: env debuggerContext identicalTo: ctx.
	self assert: env tools notEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetClassHierarchyToolClassNotFound [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_class_hierarchy' ].
	result := tool applyTo: (Dictionary with: 'class_name' -> 'NonExistentClass12345').
	self assert: (result includesKey: 'error')
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetClassHierarchyToot [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_class_hierarchy' ].
	result := tool applyTo: (Dictionary with: 'class_name' -> 'OrderedCollection').
	self assert: (result at: 'class') equals: 'OrderedCollection'.
	self assert: (result at: 'hierarchy') notEmpty.
	self assert: (result at: 'depth') > 1
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetErrorDetailsToolReturnsErrorInfo [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx errorClassName: 'ZeroDivide'.
	ctx errorMessage: 'division by zero'.
	ctx failingClassName: 'SmallInteger'.
	ctx failingSelector: '/'.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_error_details' ].
	result := tool applyTo: Dictionary new.
	self assert: (result at: 'exception_class') equals: 'ZeroDivide'.
	self assert: (result at: 'error_message') equals: 'division by zero'.
	self assert: (result at: 'failing_class') equals: 'SmallInteger'
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetImplementorsTool [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_implementors' ].
	result := tool applyTo: (Dictionary with: 'selector' -> 'yourself').
	self assert: (result at: 'selector') equals: 'yourself'.
	self assert: (result at: 'count') > 0.
	self assert: (result at: 'implementors') notEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetLocalVariablesToolReturnsVars [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx localVariables: (Dictionary with: 'x' -> '10' with: 'y' -> '20').
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_local_variables' ].
	result := tool applyTo: Dictionary new.
	self assert: (result at: 'count') equals: 2.
	self assert: ((result at: 'variables') at: 'x') equals: '10'
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetLocalVariablesToolWhenEmpty [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx localVariables: Dictionary new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_local_variables' ].
	result := tool applyTo: Dictionary new.
	self assert: (result includesKey: 'info')
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetMethodSourceInStackTool [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_method_source_in_stack' ].
	result := tool applyTo: (Dictionary with: 'class_name' -> 'Object' with: 'selector' -> 'yourself').
	self assert: (result at: 'class') equals: 'Object'.
	self assert: (result at: 'selector') equals: 'yourself'.
	self assert: (result at: 'source') notEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetReceiverStateToolReturnsState [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx receiverClassName: 'OrderedCollection'.
	ctx receiverState: (Dictionary with: 'array' -> '#(1 2 3)' with: 'firstIndex' -> '1').
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_receiver_state' ].
	result := tool applyTo: Dictionary new.
	self assert: (result at: 'receiver_class') equals: 'OrderedCollection'.
	self assert: (result at: 'count') equals: 2
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetSendersTool [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_senders' ].
	result := tool applyTo: (Dictionary with: 'selector' -> 'yourself').
	self assert: (result at: 'selector') equals: 'yourself'.
	self assert: (result at: 'count') > 0
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetStackFrameDetailsTool [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx stackFrameDetails: (OrderedCollection with: (Dictionary
		with: 'method' -> 'MyClass>>foo'
		with: 'locals' -> (Dictionary with: 'x' -> '42')
		with: 'pc' -> 10
		with: 'source' -> 'foo ^ x')).
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_stack_frame_details' ].
	result := tool applyTo: Dictionary new.
	self assert: (result at: 'count') equals: 1.
	self assert: (result at: 'frames') first equals: ctx stackFrameDetails first
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetStackFrameDetailsToolWhenEmpty [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_stack_frame_details' ].
	result := tool applyTo: Dictionary new.
	self assert: (result includesKey: 'info')
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testGetStackTraceToolReturnsTrace [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	ctx stackTrace: #( 'MyClass>>foo' 'Object>>doesNotUnderstand:' 'MyClass>>bar' ).
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'get_stack_trace' ].
	result := tool applyTo: Dictionary new.
	self assert: (result at: 'depth') equals: 3.
	self assert: (result at: 'frames') first equals: 'MyClass>>foo'
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testRegisterClientIsIdempotent [

	| ctx env registry |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	registry := ChatPharoTemporalToolRegistry new.
	env tools do: [ :tool | registry registerClient: tool ].
	env tools do: [ :tool | registry registerClient: tool ].
	self assert: registry size equals: env tools size
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testSuggestFixToolReturnsProposal [

	| ctx env tool result |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	tool := env tools detect: [ :t | t name = 'suggest_fix_code' ].
	result := tool applyTo: (Dictionary
		with: 'class_name' -> 'MyClass'
		with: 'selector' -> 'foo'
		with: 'fixed_source' -> 'foo ^ 42').
	self assert: (result at: 'status') equals: 'fix_proposed'.
	self assert: (result at: 'class') equals: 'MyClass'.
	self assert: (result includesKey: 'note')
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testToolNamesAreUnique [

	| ctx env names |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	names := env tools collect: [ :t | t name ].
	self assert: names asSet size equals: names size
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testToolsCanBeRegisteredAsTemporalTools [

	| ctx env registry |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	registry := ChatPharoTemporalToolRegistry new.
	env tools do: [ :tool | registry registerClient: tool ].
	self assert: registry size equals: env tools size.
	self assert: (registry hasToolNamed: 'get_error_details').
	self assert: (registry hasToolNamed: 'get_stack_trace').
	self assert: (registry hasToolNamed: 'get_stack_frame_details').
	self assert: (registry hasToolNamed: 'get_class_hierarchy').
	self assert: (registry hasToolNamed: 'get_senders').
	self assert: (registry hasToolNamed: 'get_implementors').
	self assert: (registry hasToolNamed: 'suggest_fix_code')
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testToolsCount [

	| ctx env |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	self assert: env tools size equals: 11
]

{ #category : 'tests' }
ChatPharoDebuggerEnvironmentTest >> testToolsHaveOpenAIChatToolFormat [

	| ctx env |
	ctx := ChatPharoDebuggerContext new.
	env := ChatPharoDebuggerEnvironment forContext: ctx.
	env tools do: [ :tool |
		| json |
		json := tool openAIChatTool.
		self assert: (json at: 'type') equals: 'function'.
		self assert: ((json at: 'function') includesKey: 'name').
		self assert: ((json at: 'function') includesKey: 'description').
		self assert: ((json at: 'function') includesKey: 'parameters') ]
]
