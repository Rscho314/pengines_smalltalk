"
I am an abstract class bridge to SWI-Prolog.

I communicate with the SWI-Prolog pengines server (https://pengines.swi-prolog.org/docs/index.html) through HTTP, by allowing to write prolog code directly within the Pharo source code. I know how to communicate with the server through callbacks, similar to the existing Javascript API (https://github.com/SWI-Prolog/packages-pengines/blob/master/web/js/pengines.js).

My main collaborators are ZincHTTP and STON. I use their methods for HTTP and JSON operations.
"
Class {
	#name : #SingleSolutionNondetPengine,
	#superclass : #Object,
	#traits : 'TSingleSolution',
	#classTraits : 'TSingleSolution classTrait',
	#instVars : [
		'server',
		'application',
		'ask',
		'chunk',
		'destroy',
		'src_text',
		'src_url',
		'format',
		'id',
		'pingId',
		'aborted',
		'detached',
		'died',
		'host',
		'port'
	],
	#classVars : [
		'Alive'
	],
	#classInstVars : [
		'options'
	],
	#category : #Pengines
}

{ #category : #copying }
SingleSolutionNondetPengine class >> copyOptionsFrom: anOrigin [
	"comment stating purpose of class-side message"
	"scope: class-variables  &  class-instance-variables"	
	
	^anOrigin copy.
	
]

{ #category : #'instance creation' }
SingleSolutionNondetPengine class >> new [
	"Instance creation respecting Seaside guidelines:
		https://github.com/SeasideSt/Seaside/wiki/Object-Initialization"
			
	^self basicNew
					initialize;
					yourself
]

{ #category : #serialization }
SingleSolutionNondetPengine class >> stringifyData: someData withOptions: someOptions [
	
	| msg |

	self
		flag: 'Improve by adding asPrologString methods to the tested classes'.

	someData isNumber
		ifTrue: [ ^ someData asNumber ].
	someData isString
		ifTrue: [ (someOptions at: #string) == 'atom'
				ifTrue: [ ^ '''' , someData , '''' ]
				ifFalse: [ ^ '"' , someData , '"' ] ].
	someData
		ifTrue: [ ^ '''true''' ].
	someData
		ifFalse: [ ^ '''false''' ].
	someData ifNil: [ ^ '''null''' ].
	someData isArray
		ifTrue: [ msg := String
				streamContents: [ :s | 
					someData
						do: [ :each | 
							s nextPutAll: each asString;
								nextPutAll: ',' ] ].
			msg at: msg size put: $].
			^ '[' , msg ].
	someData isDictionary
		ifFalse: [ ^ self ].
	msg := ''.
	someData
		keysAndValuesDo: [ :k :v | msg := msg , k asString , ':' , v asString , ',' ].
	msg at: msg size put: $}.
	msg := 'js{' , msg.
	^ msg
]

{ #category : #API }
SingleSolutionNondetPengine >> abort [
	"Terminates the running query by force"
			
	| url response |
	
	url := ZnUrl new
						scheme: #http;
						host: host;
						port: port;
						addPathSegment: server;
						addPathSegment: 'abort';
						queryAt: 'id' put: id;
						queryAt: 'format' add: format.
	
	response := ZnClient new.
	response 
		url: url;
		get.
	response isSuccess 
		ifFalse: [ ^self error: 'pengine abortion failure' ]
]

{ #category : #settings }
SingleSolutionNondetPengine >> application: anApplication [
	"The name of the application in which the pengine is to be run. Default is 'pengine_sandbox'."
	
	application := anApplication
]

{ #category : #settings }
SingleSolutionNondetPengine >> ask: anAsk [
	"The query passed to the pengine immediately after its creation. By default no query is passed. 
	Using this option will typically save one network roundtrip and thus using it with a deterministic query will result in just one roundtrip being made."
	
	ask := anAsk
]

{ #category : #API }
SingleSolutionNondetPengine >> ask: aQuery withOptions: someOptions [
	"Runs query in search for the first solution.
	Throws an error if the query is syntactically or semantically malformed or if running it could compromise the safety of the server.
	someOptions is a dictionary contaning zero or more of 'template' or 'chunk' keys."
			
	^self send: 'ask((', aQuery, '), ', ( self optionsToList: someOptions ), ')'
]

{ #category : #initialization }
SingleSolutionNondetPengine >> attach [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	id ifNotNil: 		
		[ Alive add: id.
			^self pullResponse ]
			ifNil: 
		[ ^self error: 'tried to attach without providing a pengines instance ID' ]
]

{ #category : #initialization }
SingleSolutionNondetPengine >> attach: anId [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	id ifNil: 
		[ id := anId.
			Alive add: anId.
			^self pullResponse ]
			ifNotNil: 
		[ ^self error: 'tried to attach a pengines instance with an already attached client' ]
]

{ #category : #settings }
SingleSolutionNondetPengine >> chunk: aChunk [
	"The maximum number of solutions to retrieve in one chunk. 1 means no chunking (default)."

	chunk := aChunk
]

{ #category : #initialization }
SingleSolutionNondetPengine >> create [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	id ifNil: 
				[ ^self sendCreate ]
		 ifNotNil: 		
				[ ^self error: 'attempted to create a pengines instance with an already attached client' ]
]

{ #category : #API }
SingleSolutionNondetPengine >> destroy [
	"Destroys the pengine."

	died
		ifTrue: [ ^ self ].
	died := true.
	^ self send: 'destroy'
]

{ #category : #settings }
SingleSolutionNondetPengine >> destroy: aBool [
	"Determines if the pengine is to destroy itself after having run a query to completion. Defaults to true."

	destroy := aBool
]

{ #category : #cleanup }
SingleSolutionNondetPengine >> destroyAll [
	"destroys all pengine server instances associated with the running program"
	"scope: Alive (so destroys server instance even if created by another client instance)"	

	| url response |
			
	Alive do:
		[ :i | url := ZnUrl new 
							scheme: #http;
							host: host;
							port: port;
							addPathSegment: server;
							addPathSegment: 'destroy_all';
							queryAt: 'ids' put: i;
							queryAt: 'format' add: format.
	
						response := ZnClient new.
						response
							url: url;
							post.
	
						response isSuccess ifFalse: [ ^self error: 'destroy_all POST failed.' ] ]
]

{ #category : #settings }
SingleSolutionNondetPengine >> format: aFormat [
	"Determines the format of event responses. Format is a string, either json (default), or any string"
	format := aFormat
]

{ #category : #settings }
SingleSolutionNondetPengine >> host: aHost [
	"A string describing the host of the Pengines server on which to create the pengine.
	Default is localhost."

	host := aHost
]

{ #category : #API }
SingleSolutionNondetPengine >> id [
	"Evaluates to the id of the pengine (a string).
	Note that the pengine must have been created before this field will have a non-null value, i.e. 'onCreate' must have been called."
			
	^id
]

{ #category : #settings }
SingleSolutionNondetPengine >> id: anId [
	"Assigns to the id of the pengine (a string)."
	
	id := anId
]

{ #category : #initialization }
SingleSolutionNondetPengine >> initialize [
	
	super initialize.
	
	"custom add-ons to the original API"
	host := 'localhost'.
	port := 3030.
	
	"original API"
	detached := true.
	died := false.
	server := 'pengine'.
	application := 'pengine_sandbox'.
	chunk := 1.
	destroy := true.
	format := 'json'.
	Alive := Set new.
]

{ #category : #API }
SingleSolutionNondetPengine >> next [
	"Triggers a search for the next solution"
			
	self send: 'next'
]

{ #category : #API }
SingleSolutionNondetPengine >> next: aChunkSize [
	"Triggers a search for the next solution, with a specified chunk size for the next solution"	
			
	self send: 'next(', aChunkSize, ')'
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onAbort: someData [
	"Called when a running query has been successfully aborted.
	'id' should point to the id of the pengine having been aborted."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onCreate: someData [
	"called when a pengine server instance has been created.
	'id' should point to the id of the pengine."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onData: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onDebug: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onDestroy: someData [
	"Called when the pengine has been successfully destroyed.
	'id' should point to the id of the pengine having been destroyed."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onDetach: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onError: someData [
	"Called when the pengine throws an error.
	'data' should evaluate to an error message in the form of a string.
	'id' should point to the id of the pengine returning the error."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onFailure: someData [
	"Called when the pengine fails to find a solution.
	'id' should point to the id of the pengine reporting the failure."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onOutput: someData [
	"Called when the pengine has evaluated the built in pengine_output/1 predicate.
	'data' should evaluate to a string or a dictionary.
	'id' should point to the id of the pengine generating the output."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onPing: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onPrompt: someData [
	"Called when the pengine evaluates the pengine_input/2 predicate.
	'data' should evaluate to a prompt in the form of a string or a dictionary.
	'id' should point to the id of the pengine producing the prompt."
			
	^self subclassResponsibility
]

{ #category : #'event processing' }
SingleSolutionNondetPengine >> onResponse: anEvent withValue: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"
	
	| response |
			
	response := Dictionary new.
	response
		add: 'create' 		-> [ self receiveCreate: 			aResponse ];
		add: 'stop' 			-> [ self receiveStop: 				aResponse ];
		add: 'failure' 		-> [ self receiveFailure: 		aResponse	];
		add: 'prompt' 		-> [ self receivePrompt: 			aResponse	];
		add: 'success' 		-> [ self receiveSuccess: 		aResponse	];
		add: 'error' 			-> [ self receiveError: 			aResponse	];
		add: 'output' 		-> [ self receiveOutput: 			aResponse	];
		add: 'ping' 			-> [ self receivePing: 				aResponse	];
		add: 'debug' 			-> [ self receiveDebug: 			aResponse	];
		add: 'abort' 			-> [ self receiveAbort: 			aResponse	];
		add: 'detached' 	-> [ self receiveDetached: 	aResponse ];
		add: 'destroy' 		-> [ self receiveDestroy: 		aResponse	];
		add: 'died' 			-> [ self receiveDied: 				aResponse	].
	^response at: anEvent
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onStop: someData [
	"Called when a running query has been successfully stopped.
	'id' should point to the id of the pengine having been stopped."
			
	^self subclassResponsibility
]

{ #category : #callbacks }
SingleSolutionNondetPengine >> onSuccess: someData [
	"Called when the pengine responds with a successful answer to a query.
	'data' should point to a list of objects each representing a solution to the query.
	'more' should evaluate to a boolean indicating whether more solutions may exist.
	'id' points to the id of the pengine returning the answer."
			
	^self subclassResponsibility
]

{ #category : #private }
SingleSolutionNondetPengine >> optionsToList: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| opts |
	opts := '['.
	someOptions ifNotNil: 
		[ someOptions keysAndValuesDo:
			[ :k :v | ( opts ~~'[' ) ifTrue: [opts := opts, ', '].
									v ifNotNil: [ opts := opts, k asString , '(', v asString , ')' ] ] ].
	^opts, ']'
]

{ #category : #settings }
SingleSolutionNondetPengine >> port: aPort [
	"An Integer describing the port of the Pengines server on which to connect.
	Default is 3030."

	port := aPort
]

{ #category : #'event processing' }
SingleSolutionNondetPengine >> processResponse: aResponse [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	aResponse isString
		ifTrue: [ STON fromString: aResponse ]
		ifFalse: [ aResponse ].
	^( self onResponse: ( aResponse at: #event ) withValue: aResponse ) value.
]

{ #category : #'event processing' }
SingleSolutionNondetPengine >> pullResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| url response contents |
	
	url := ZnUrl new 
						scheme: #http;
						host: host;
						port: port;
						addPathSegment: server;
						addPathSegment: 'pull_response';
						queryAt: 'id' put: id;
						queryAt: 'format' add: format.
						
	response := ZnClient new.
	response 
		url: url;
		get.
	
	contents := STON fromStream: ( response contents readStream ).
	( ( contents at: #event ) ~= 'died' )
		ifTrue: [ ^self processResponse: contents ]
		ifFalse: [ ^self error: 'tried to pull response from dying pengine' ]
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveAbort: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	aborted := true.
	^self onAbort: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveCreate: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	detached := false.		
	id := aResponse at: #id.
	Alive add: id.
	( Alive size > ( aResponse at: #slave_limit ) )
		ifTrue: [ self destroy.
								aResponse
									add: #data -> 'Attempt to create too many pengines. The limit is: ',
																		(aResponse at: #slave_limit);
									add: #code -> 'too many pengines'.
								^self error: ( aResponse at: #data ) ]
		ifFalse: [ 	self onCreate: aResponse.
									(aResponse includesKey: #answer) ifTrue:
										[ ^self processResponse: (aResponse at: #answer) ] ]
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveDebug: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	( ( self onDebug: aResponse ) == 'not implemented' )
		ifTrue: [ ^self error: ( aResponse at: #data ) asString ]
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveDestroy: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	

	self unregisterPengine.
	( aResponse includesKey: #data )
		ifTrue: [ self processResponse: ( aResponse at: #data ) ].
	^self onDestroy: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveDetached: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	detached := true.
	self unregisterPengine.
	^self onDetach: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveDied: aResponse [
	self unregisterPengine.
	aborted
		ifTrue: [ ^self ].
	aResponse
		at: #data put: 'Pengine has died';
		at: #code put: 'died'.
	(self onError: aResponse)
		ifFalse: [ ^self error: (aResponse at: #data) asString ]
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveError: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	( 	( aResponse at: #code == 'existence error' )
			and: [ [ aResponse at: #arg1 == 'pengine' ]
			and: [ aResponse at: #arg2  == id ] ] )
			ifTrue: [ self unregisterPengine ].
			( ( self onError: aResponse ) == 'not implemented' )
				ifTrue: [ ^self error: ( aResponse at: #data ) asString ]
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveFailure: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onFailure: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveOutput: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	id ifNil: [ id := ( aResponse at: #id ) ].
	self onOutput: aResponse;
				pullResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receivePing: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onPing: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receivePrompt: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onPrompt: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveStop: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onStop: aResponse
]

{ #category : #receiving }
SingleSolutionNondetPengine >> receiveSuccess: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	

	( self onSuccess: aResponse )
		ifTrue: [ self processData: ( aResponse at: #data ) ].
	( aResponse at: #more)
		ifTrue: [ ^self next ]
]

{ #category : #API }
SingleSolutionNondetPengine >> respond: anInput [
	"Inputs a term in response to a prompt from an invocation of pengine_input/2 that is now waiting to receive data from the outside.
	Throws an error if 'anInput' string cannot be parsed as a Prolog term or if 'anInput' dictionary cannot be serialised into JSON."
			
	^self send: 'input((', anInput, '))' 
]

{ #category : #sending }
SingleSolutionNondetPengine >> send: anEvent [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| response url |

	response := ZnClient new.
	url := ZnUrl new 
		scheme: #http;
		host: host;
		port: port;
		addPathSegment: server;
		addPathSegment: 'send';
		queryAt: 'format' put: format;
		queryAt: 'id' add: id;
		yourself.
	response
		url: url;
		contents: anEvent, '.', String cr;
		contentType: 'application/x-prolog; charset=UTF-8';
		post.
	response isSuccess 
		ifTrue: 
			[ ^self processResponse: response contents ]
		ifFalse:
			[ ^self error: 'Method failure: ''send'' with response: ', response contents asString ]
]

{ #category : #sending }
SingleSolutionNondetPengine >> sendCreate [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| response options |
	
	options := self buildOptions.
	response := ZnClient new.
	response
		http;
		host: host;
		port: port;
		addPath: server;
		addPath: 'create';
		enforceAcceptContentType: true;
		accept: ZnMimeType applicationJson;
		contentWriter: [ :object | ZnEntity 
            												with: (String streamContents: [ :stream |
																					STON jsonWriter on: stream; nextPut: object ])
            												type: ZnMimeType applicationJson ];
   contentReader: [ :entity | STON fromStream: ( entity contents readStream ) ];
																			contents: ( options reject: [ :v | v isNil ] );
																			post.
	response isSuccess
							ifTrue: 		[ ^self processResponse: response contents ]
							ifFalse: 	[ ^self error: 'POST request with value ',
														( options asString ), ' failed.' ]
]

{ #category : #sending }
SingleSolutionNondetPengine >> sendDetach: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| url response |
			
	self sendPing: 0.
	url := ZnUrl new 
						scheme: #http;
						host: host;
						port: port;
						addPathSegment: server;
						addPathSegment: 'detach';
						queryAt: 'id' put: id;
						queryAt: 'format' add: format.
	
	response := ZnClient new.
	response
		url: url;
		contents: ( STON fromString: someData );
		contentType: ZnMimeType applicationJson;
		post.
	
	response isSuccess ifFalse: [ ^self error: 'POST with data: ', ( someData asString ), ' failed.' ]
]

{ #category : #sending }
SingleSolutionNondetPengine >> sendPing: anInterval [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| url response |
	
	anInterval 
		ifNil:
			[ id ifNotNil:
					[ url := ZnUrl new 
											scheme: #http;
											host: host;
											port: port;
											addPathSegment: server;
											addPathSegment: 'ping';
											queryAt: 'id' put: id;
											queryAt: 'format' add: format.
						response := ZnClient new.
						response
							url: url;
							get.
						response isSuccess 
							ifTrue: [ ^self processResponse: response contents ]
							ifFalse: [ ^self error: 'Pinging the server failed' ] ] ]
		ifNotNil:
			[ ( anInterval > 0 )
					ifTrue: [ pingId := [ [ true ] whileTrue: 
																											[ ( Delay forSeconds: anInterval ) wait.
																												^self sendPing: nil ] ] fork ]
					ifFalse: [ pingId terminate ] ]
]

{ #category : #settings }
SingleSolutionNondetPengine >> server: aServer [
	"A string pointing to the Pengines server on which to create the pengine.
	Default is 'pengine'.
	Unlike the existing JS API, setting the connection server with 'server:' only changes the server path, not the host or port.
	Contacting an entirely different server requires at least the 'host:' and 'server:' messages"

	server := aServer
]

{ #category : #settings }
SingleSolutionNondetPengine >> src_text: aSrc [
	"Prolog source code to be injected in the pengine before attempting to solve any queries."
	
	src_text := aSrc
]

{ #category : #settings }
SingleSolutionNondetPengine >> src_url: aUrl [
	"A URL resolving to a file containing Prolog source code to be injected in the pengine before attempting to solve any queries."

	src_url := aUrl
]

{ #category : #API }
SingleSolutionNondetPengine >> stop [
	"Stops searching for solutions. Terminates the running query gracefully"
			
	^self send: 'stop'
]

{ #category : #private }
SingleSolutionNondetPengine >> unregisterPengine [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	pingId := nil.
	Alive := Alive remove: id. "does not handle id absence" 
	detached ifFalse: [ died := true ]
]
