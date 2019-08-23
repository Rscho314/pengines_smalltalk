"
I am an abstract class bridge to SWI-Prolog.

I communicate with the SWI-Prolog pengines server (https://pengines.swi-prolog.org/docs/index.html) through HTTP, by allowing to write prolog code directly within the Pharo source code. I know how to communicate with the server through callbacks, similar to the existing Javascript API (https://github.com/SWI-Prolog/packages-pengines/blob/master/web/js/pengines.js).

My main collaborators are ZincHTTP and STON. I use their methods for HTTP and JSON operations.

instance creation:

myPengine := Pengine withOptions: {} asDictionary.
, where '{ }' must define the required callbacks as values of keys in the 'options' class variable.
"
Class {
	#name : #Pengine,
	#superclass : #Object,
	#instVars : [
		'options',
		'alive',
		'id',
		'onResponse',
		'pingId',
		'src',
		'aborted',
		'detached',
		'died'
	],
	#classVars : [
		'DecToUnicode',
		'DefaultOptions',
		'Serialize',
		'SerializeKey',
		'StringEscape'
	],
	#category : #pengines
}

{ #category : #copying }
Pengine class >> copyOptionsFrom: anOrigin [
	"comment stating purpose of class-side message"
	"scope: class-variables  &  class-instance-variables"	
	
	^anOrigin copy.
	
]

{ #category : #'instance creation' }
Pengine class >> withOptions: someOptions [
	"fillDefaultOptions"
	"scope: class-variables  &  class-instance-variables"
	"API: https://pengines.swi-prolog.org/docs/documentation.html"		
	
	DefaultOptions := IdentityDictionary new.
	DefaultOptions 	add: #format      -> 'json';
										add: #ask         -> nil;
										add: #destroy     -> true;
										add: #chunk       -> 1;	
										add: #application -> 'pengine_sandbox';
										add: #onCreate    -> nil;
										add: #onSuccess   -> nil;
										add: #onData      -> nil;
										add: #onFailure   -> nil;
										add: #onError     -> nil;
										add: #onPrompt    -> nil;
										add: #onOutput    -> nil;
										add: #onDebug     -> nil;
										add: #onPing      -> nil;
										add: #onAbort     -> nil;
										add: #onDetach    -> nil;
										add: #onDestroy   -> nil;
											"should those exist?"
										add: #server      -> 'pengine';
										add: #id          -> nil;
										add: #src_text    -> nil;
										add: #template    -> nil;
										add: #solutions   -> nil.
	Serialize := nil.
	StringEscape := nil.
	DecToUnicode := nil.
	^self new
			initializePengine: someOptions;
			yourself
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
Pengine >> destroy [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	died ifFalse: [ died := true ].
	^self send: 'destroy'
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

{ #category : #'instance initalization' }
Pengine >> initializePengine: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	| validOptions response |
	
	alive := Set new.
	validOptions := Dictionary new.
	[ DefaultOptions keysDo: [ :k | ( someOptions includesKey: k )
			ifTrue: [ validOptions add: k -> ( someOptions at: k ) ]
			ifFalse: [ validOptions add: k -> ( DefaultOptions at: k ) ] ] ]
	on: MessageNotUnderstood
		do:[ self error: 'Pengine ''options'' argument must be addressable by key-value pairs.' ].
	options := validOptions.
	( options at: #id )
		ifNotNil: [ alive add: ( options at: #id ).
									"self pull_response" ]
		ifNil: [ response := ZnClient new.
								response
								http;
								host: 'localhost';
								port: 3030;
								addPath: ( options at: #server );
								addPath: 'create';
								enforceAcceptContentType: true;
								accept: ZnMimeType applicationJson;
								contentWriter: [ :object | 
        					ZnEntity 
            			with: (String streamContents: [ :stream | STON jsonWriter on: stream; nextPut: object ])
            			type: ZnMimeType applicationJson ];
    						contentReader: [ :entity | STON fromStream: ( entity contents readStream ) ];
								contents: ( options reject: [ :v | v isNil ] );
								post.
						response isSuccess
							ifTrue:
								[ self processResponse: response contents ]
							ifFalse:
								[ self error: 'POST request with value ', ( options asString ), ' failed.' ] ]
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
							alive add: id.
							( alive size > ( o at: #slave_limit ) )
								ifTrue: [ self destroy.
														o
															add: #data ->
																'Attempt to create too many pengines. The limit is: ', (o at: #slave_limit);
															add: #code -> 'too many pengines'.
														[ ^self error: (o at: #data) ] ]
								ifFalse: [ self callback: ( options at: #onCreate ) withArgument: o.
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
																	self unregisterPengine..
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
Pengine >> stringifyData: someData withOptions: someOptions [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	| msg |
	self flag: 'Improve by adding asPrologString methods to the tested classes (SmallTalk way)'.
	
	( someData isNumber ) ifTrue: [ ^someData asNumber  ]	.
	( someData isString ) ifTrue: 
		[ ( ( someOptions at: #string ) == 'atom' )
				ifTrue: [ ^'''', someData, '''' ] ifFalse: [ ^'"', someData, '"' ] ].
	someData ifTrue: [ ^'''true''' ].
	someData ifFalse: [ ^'''false''' ].
	someData ifNil: [ ^'''null''' ].
	( someData isArray ) ifTrue: [ msg:= '[' .
																			 someData do: [ :e | msg := e asString, ',' ].
																			 msg := msg asOrderedCollection removeLast asString.
																			 ^msg, ']' ].
	( someData isDictionary ) ifTrue: [  ].
		
	"Serialize := [ :data | 
	StringEscape := [ :aString :aQuery | 
	DecToUnicode := [ :aNumber | 
	((0 to: 15) includes: aNumber)
		ifTrue: [ ^ '\\u000' , (aNumber radix: 16) ].
	((16 to: 255) includes: aNumber)
		ifTrue: [ ^ '\\u00' , (aNumber radix: 16) ].
	((256 to: 4095) includes: aNumber)
		ifTrue: [ ^ '\\u0' , (aNumber radix: 16) ].
	((4096 to: 65535) includes: aNumber)
		ifTrue: [ ^ '\\u' , (aNumber radix: 16) ] ].
	result := aQuery.
	aString
		do: [ :c | 
			(c isAlphaNumeric or: c == ' ')
				ifTrue: [ c == '\\'
						ifTrue: [ result := result , '\\\\' ].
					(c == aQuery)
						ifTrue: [ result := result , '\\' , aQuery ];
						ifFalse: [ result := result , c ] ]
				ifFalse: [ c == '\n'
						ifTrue: [ result := result , '\\n' ].
					c == '\r'
						ifTrue: [ result := result , '\\r' ].
					c == '\t'
						ifTrue: [ result := result , '\\t' ].
					c == '\b'
						ifTrue: [ result := result , '\\b' ].
					(c == '\f')
						ifTrue: [ result := result , '\\f' ];
						ifFalse: [ result := result , self decToUnicode: c codePoint ] ] ].
	^ result , aQuery ].
	SerializeKey := [ :k | 
	msg := (k matchesRegex: '/^\d+$/')
		ifTrue: [ msg , k ]
		ifFalse: [ msg , StringEscape value: k value: '''' ].
	^ true ].
	( ( data == true ) or: ( data == false ) )
		ifTrue: [ msg := msg, 'true' ] ifFalse: [ msg := msg, 'false' ].
	data ifNil: [ msg := msg, 'null' ].
	( data isNumber ) ifTrue: [ msg := msg, data ].
	( data isString ) ifTrue: [ msg := msg, StringEscape value: data value: strq ].
	( data isArray )
		ifTrue: [ msg := msg, '['.
								data do: [ :e | ( Serialize value: e ) ifTrue: [ msg := msg, ', '] ].
								msg := msg asOrderedCollection removeLast asString, ']' ].
	( data isDictionary ) ifTrue: [ msg := msg, 'js{'.
																				data keysAndValuesDo: [ :k :v | 
																					( Serialize value: v )
																						ifTrue: [ msg := msg, k asString, ':'  ] ] ]
	]."
]

{ #category : #private }
Pengine >> unregisterPengine [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	pingId := nil.
	alive := alive remove: id. "does not handle id absence" 
	detached ifFalse: [ died := true ].
]
