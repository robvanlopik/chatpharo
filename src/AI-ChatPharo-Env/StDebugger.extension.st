Extension { #name : 'StDebugger' }

{ #category : '*AI-ChatPharo-Env' }
StDebugger class >> chatPharoBrowseCommandWith: aPresenter forRootGroup: aCmCommandsGroup [
<extensionCommands>
	| command stackGroup decoratedGroup |

	command := StAskChatPharoFromDebuggerCommand forSpecContext: aPresenter.

	stackGroup := aCmCommandsGroup / StDebuggerStackCommandTreeBuilder groupName.
	decoratedGroup := stackGroup decoratedGroup.

	decoratedGroup register: command.

	"Force it to be the first visible item"
	decoratedGroup entries remove: command ifAbsent: [ ].
	decoratedGroup entries addFirst: command
]
