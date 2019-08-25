"
I am an abstract class bridge to SWI-Prolog.

I communicate with the SWI-Prolog pengines server (https://pengines.swi-prolog.org/docs/index.html) through HTTP, by allowing to write prolog code directly within the Pharo source code. I know how to communicate with the server through callbacks, similar to the existing Javascript API (https://github.com/SWI-Prolog/packages-pengines/blob/master/web/js/pengines.js).

My main collaborators are ZincHTTP and STON. I use their methods for HTTP and JSON operations.
"
Class {
	#name : #Pengine,
	#superclass : #Object,
	#instVars : [
		'options',
		'id',
		'pingId',
		'src',
		'aborted',
		'detached',
		'died'
	],
	#classVars : [
		'Alive',
		'DefaultOptions'
	],
	#classInstVars : [
		'options'
	],
	#category : #Pengines
}

{ #category : #copying }
Pengine class >> copyOptionsFrom: anOrigin [
	"comment stating purpose of class-side message"
	"scope: class-variables  &  class-instance-variables"	
	
	^anOrigin copy.
	
]

{ #category : #initialization }
Pengine class >> initializeWithOptions: someOptions [
	"comment stating purpose of class-side message"
	"scope: class-variables  &  class-instance-variables"	
	
	someOptions isDictionary 
		ifTrue:  [ options := someOptions ]
		ifFalse: [ ^self error: 'options must be an instance of Dictionary' ].
			
	^self new
]

{ #category : #serialization }
Pengine class >> stringifyData: someData withOptions: someOptions [
	
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

{ #category : #'initialize-destroy' }
Pengine >> destroyAll [
	"comment stating purpose of class-side message"
	"scope: class-variables  &  class-instance-variables"	

	| url response |
			
	
	Alive do:
		[ :i | url := ZnUrl new 
							scheme: #http;
							host: 'localhost';
							port: 3030;
							addPathSegment: ( options at: #server );
							addPathSegment: 'destroy_all';
							queryAt: 'ids' put: i;
							queryAt: 'format' add: ( options at: #format ).
	
						response := ZnClient new.
						response
							url: url;
							post.
	
						response isSuccess ifFalse: [ ^self error: 'destroy_all POST failed.' ] ]
]

{ #category : #initialization }
Pengine >> initialize [

	super initialize.
	
	DefaultOptions := Dictionary new.
	DefaultOptions 
		add: #host 					-> 'localhost';
		add: #port 					-> 3030;
		add: #format      	-> 'json';
		add: #destroy     	-> true;
		add: #chunk       	-> 1;	
		add: #application 	-> 'pengine_sandbox';
		add: #server      	-> 'pengine'.
	Alive := Set new.
	
	options
		ifNil: 		[ options := DefaultOptions copy ]
		ifNotNil: [ DefaultOptions keysAndValuesDo: [ :k :v |
									( options includes: k )
										ifFalse: [ options add: k -> v ] ] ].
	( options includes: #id )
		ifTrue:  [ Alive add: ( options at: #id ). ^self pullResponse ]
		ifFalse: [ ^self sendCreate ]	
]

{ #category : #callbacks }
Pengine >> onAbort: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onCreate: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onDebug: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onDestroy: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onDetach: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onError: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onFailure: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onOutput: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onPing: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onPrompt: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #'event processing' }
Pengine >> onResponse: anEvent withValue: aResponse [
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
Pengine >> onStop: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #callbacks }
Pengine >> onSuccess: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self subclassResponsibility
]

{ #category : #private }
Pengine >> optionsToList: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| opts |
	
	opts := '['.
	options keysAndValuesDo: [ :k :v | ( opts ~~'[' ) ifTrue: [opts := opts, ','].
																						v ifNotNil: [ opts := k, '(', v, ')' ] ].
	^opts, ']'
]

{ #category : #'event processing' }
Pengine >> processResponse: aResponse [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	| obj |
	
	obj := aResponse isString
		ifTrue: [ STON fromString: aResponse ]
		ifFalse: [ aResponse ].
	^( self onResponse: ( obj at: #event ) withValue: obj ) value.
]

{ #category : #'event processing' }
Pengine >> pullResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| url response contents |
	
	url := ZnUrl new 
						scheme: #http;
						host: 'localhost';
						port: 3030;
						addPathSegment: ( options at: #server );
						addPathSegment: 'pull_response';
						queryAt: 'id' put: id;
						queryAt: 'format' add: ( options at: #format ).
						
	response := ZnClient new.
	response 
		url: url;
		get.
	
	contents := STON fromStream: ( response contents readStream ).
	( contents at: #event ~~ 'died' )
		ifTrue: [ ^self processResponse: contents ]
		ifFalse: [ ^self error: 'tried to pull response from dying pengine' ]
]

{ #category : #receiving }
Pengine >> receiveAbort: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	aborted := true.
	^self onAbort: aResponse
]

{ #category : #receiving }
Pengine >> receiveCreate: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	id := aResponse at: #id.
	Alive add: id.
	( Alive size > ( aResponse at: #slave_limit ) )
		ifTrue: [ self sendDestroy.
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
Pengine >> receiveDebug: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	( ( self onDebug: aResponse ) == 'not implemented' )
		ifTrue: [ ^self error: ( aResponse at: #data ) asString ]
]

{ #category : #receiving }
Pengine >> receiveDestroy: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	self unregisterPengine.
	( aResponse at: #data ) ifNotNil: [ self processResponse: ( aResponse at: #data ) ].
	^self onDestroy: aResponse
]

{ #category : #receiving }
Pengine >> receiveDetached: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	detached := true.
	self unregisterPengine.
	^self onDetach: aResponse
]

{ #category : #receiving }
Pengine >> receiveDied: aResponse [
	self unregisterPengine.
	aborted
		ifTrue: [ ^ self ].
	aResponse
		at: #data put: 'Pengine has died';
		at: #code put: 'died'.
	(self onError: aResponse)
		ifFalse: [ ^ self error: (aResponse at: #data) asString ]
]

{ #category : #receiving }
Pengine >> receiveError: aResponse [
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
Pengine >> receiveFailure: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onFailure: aResponse
]

{ #category : #receiving }
Pengine >> receiveOutput: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	id ifNil: [ id := ( aResponse at: #id ) ].
	self onOutput: aResponse;
				pullResponse
]

{ #category : #receiving }
Pengine >> receivePing: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onPing: aResponse
]

{ #category : #receiving }
Pengine >> receivePrompt: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onPrompt: aResponse
]

{ #category : #receiving }
Pengine >> receiveStop: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self onStop: aResponse
]

{ #category : #receiving }
Pengine >> receiveSuccess: aResponse [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	( ( self onSuccess: aResponse ) and: [ options includesKey: #onData ] )
		ifTrue: [ ( aResponse at: #data)
									do: [ :d | self perform: ( options at: #onData ) withArguments: d ] ].
		( aResponse at: #more)
			ifNotNil: [ aResponse at: #pengine next "this block probably wrong" ]
]

{ #category : #data }
Pengine >> scriptSources: source [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	src := source.
]

{ #category : #sending }
Pengine >> send: anEvent [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| response url |
	response := ZnClient new.
	url := ZnUrl new 
		scheme: #http;
		host: 'localhost';
		port: 3030;
		addPathSegment: ( options at: #server );
		addPathSegment: 'send';
		queryAt: 'format' put: ( options at: #format );
		queryAt: 'id' add: id;
		yourself.
	response
		url: url;
		contents: anEvent, ' .\n';
		contentType: 'application/x-prolog; charset=UTF-8';
		post.
	response isSuccess 
		ifTrue: 
			[ ^self processResponse: response contents ]
		ifFalse:
			[ ^self error: 'Method failure: ''send'' with response: ', response contents asString ]
]

{ #category : #sending }
Pengine >> sendAbort [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	| url response |
	
	url := ZnUrl new
						scheme: #http;
						host: 'localhost';
						port: 3030;
						addPathSegment: ( options at: #server );
						addPathSegment: 'abort';
						queryAt: 'id' put: ( options at: #id );
						queryAt: 'format' add: ( options at: #format ).
	
	response := ZnClient new.
	response 
		url: url;
		get.
	response isSuccess 
		ifFalse: [ ^self error: 'pengine abortion failure' ]
]

{ #category : #sending }
Pengine >> sendAsk: aQuery withOptions: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self send: 'ask((', aQuery, '), ', ( someOptions values ), ')'
]

{ #category : #sending }
Pengine >> sendCreate [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| response |
			
	response := ZnClient new.
	response
		http;
		host: ( options at: #host );
		port: ( options at: #port );
		addPath: ( options at: #server );
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
Pengine >> sendDestroy [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	died ifFalse: [ died := true ].
	^self send: 'destroy'
]

{ #category : #sending }
Pengine >> sendDetach: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| url response |
			
	self sendPing: 0.
	url := ZnUrl new 
						scheme: #http;
						host: 'localhost';
						port: 3030;
						addPathSegment: ( options at: #server );
						addPathSegment: 'detach';
						queryAt: 'id' put: ( options at: #id );
						queryAt: 'format' add: ( options at: #format ).
	
	response := ZnClient new.
	response
		url: url;
		contents: ( STON fromString: someData );
		contentType: ZnMimeType applicationJson;
		post.
	
	response isSuccess ifFalse: [ ^self error: 'POST with data: ', ( someData asString ), ' failed.' ]
]

{ #category : #sending }
Pengine >> sendNext [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	^self send: 'next'
]

{ #category : #sending }
Pengine >> sendNext: aNext [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	^self send: 'next(' , aNext , ')'
]

{ #category : #sending }
Pengine >> sendPing: anInterval [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| url response |
	
	anInterval 
		ifNil:
			[ id ifNotNil:
					[ url := ZnUrl new 
											scheme: #http;
											host: 'localhost';
											port: 3030;
											addPathSegment: ( options at: #server );
											addPathSegment: 'ping';
											queryAt: 'id' put: id;
											queryAt: 'format' add: ( options at: #format ).
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

{ #category : #sending }
Pengine >> sendResponse: anInput [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self send: 'input((', anInput, '))' 
]

{ #category : #sending }
Pengine >> sendStop [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self send: 'stop'
]

{ #category : #private }
Pengine >> unregisterPengine [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	pingId := nil.
	Alive := Alive remove: id. "does not handle id absence" 
	detached ifFalse: [ died := true ].
]
