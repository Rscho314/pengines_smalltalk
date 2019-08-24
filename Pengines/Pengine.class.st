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

{ #category : #communication }
Pengine >> abort [
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

{ #category : #communication }
Pengine >> ask: aQuery options: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self send: 'ask((', aQuery, '), ', ( someOptions values ), ')'
]

{ #category : #'dispatching-callback' }
Pengine >> callback: aFunction withArgument: anArgument [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	self flag: 'are callbacks really needed with an abstract class?'.
			
	( options includes: aFunction )
		ifTrue: [ ^self perform: aFunction asSymbol withArguments: ( Array with: anArgument ) ]
		ifFalse: [ ^self error: 'method ''', aFunction, ''' not found' ]
]

{ #category : #communication }
Pengine >> create [
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

{ #category : #communication }
Pengine >> destroy [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	died ifFalse: [ died := true ].
	^self send: 'destroy'
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

{ #category : #communication }
Pengine >> detach: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| url response |
			
	self ping: 0.
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
		ifFalse: [ ^self create ]	
]

{ #category : #communication }
Pengine >> next: aNext [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	aNext
		ifNil: [ ^self send: 'next' ]
		ifNotNil: [ ^self send: 'next(' , aNext , ')' ]
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
Pengine >> onResponse: anEvent [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"
	
	| response |
	
	self flag: 'refactor as shorter & less indirections'.
			
	response := IdentityDictionary new.
	response
		add: #create ->
			[ :o | id := o at: #id.
							Alive add: id.
							( Alive size > ( o at: #slave_limit ) )
								ifTrue: [ self destroy.
														o
															add: #data ->
																'Attempt to create too many pengines. The limit is: ', (o at: #slave_limit);
															add: #code -> 'too many pengines'.
														[ ^self error: (o at: #data) ] ]
								ifFalse: [ self onCreate: o.
															(o includesKey: #answer)
																ifTrue: [ ^self processResponse: (o at: #answer) ] ] ];
		add: #stop -> [ :o | self callback: ( options at: #onStop ) withArgument: o ];
		add: #failure -> [ :o | self callback: ( options at: #onFailure ) withArgument: o ];
		add: #prompt -> [ :o | self callback: ( options at: #onPrompt ) withArgument: o ];
		add: #success -> [ :o | ( ( self callback: ( options at: #onSuccess ) withArgument: o )
																	and: [ options includesKey: #onData ] )
																	ifTrue:
																		[ ( o at: #data)
																			do: [ :d | self perform: ( options at: #onData ) withArguments: d ] ].
																( o at: #more) ifNotNil: [ o at: #pengine next "this block probably wrong" ] ];
		add: #error -> [ :o | ( ( o at: #code == 'existence error' )
																	and: [ [ o at: #arg1 == 'pengine' ]
																	and: [ o at: #arg2  == id ] ] )
																		ifTrue: [ self unregisterPengine ].
															( ( self callback: ( options at: #onError ) withArgument: o ) == 'not implemented' )
																ifTrue:
																	[ ^self error: ( o at: #data ) asString ] ];
		add: #output -> [ :o | id ifNil: [ id := ( o at: #id ) ].
																self callback: ( options at: #onOutput ) withArgument: o;
																			pullResponse ];
		add: #ping -> [ :o | self callback: ( options at: #onPing ) withArgument: o ];
		add: #debug -> [ :o | ( ( self callback: ( options at: #onDebug ) withArgument: o ) == 'not implemented' )
															ifTrue: [ ^self error: ( o at: #data ) asString ] ];
		add: #abort -> [ :o | aborted := true.
															self callback: ( options at: #onAbort ) withArgument: o ];
		add: #detached -> [ :o | detached := true.
																	self unregisterPengine.
																	self callback: ( options at: #onDetach ) withArgument: o ];
		add: #destroy -> [ :o | self unregisterPengine.
																	( o at: #data ) ifNotNil: [ self processResponse: ( o at: #data ) ].
																	self callback: ( options at: #onDestroy ) withArgument: o ];
		add: #died -> [ :o | self unregisterPengine.
															aborted ifFalse: [ o at: #data put: 'Pengine has died';
																												at: #code put: 'died'.
																										( self callback: ( options at: #onError ) withArgument: o )
																											ifFalse: [ ^self error: ( o at: #data ) asString ] ] ].
^response at: anEvent asSymbol
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

{ #category : #communication }
Pengine >> ping: anInterval [
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
																												^self ping: nil ] ] fork ]
					ifFalse: [ pingId terminate ] ]
]

{ #category : #'event processing' }
Pengine >> processResponse: aResponse [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	| obj |
	
	obj := aResponse isString
		ifTrue: [ STON fromString: aResponse ]
		ifFalse: [ aResponse ].
	^( self onResponse: ( obj at: #event ) asSymbol ) value: obj.
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

{ #category : #communication }
Pengine >> respond: anInput [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	^self send: 'input((', anInput, '))' 
]

{ #category : #data }
Pengine >> scriptSources: source [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	src := source.
]

{ #category : #communication }
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
			[ ^self error: 'Method failure: sendToPengine', response contents asString ]
]

{ #category : #communication }
Pengine >> stop [
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
