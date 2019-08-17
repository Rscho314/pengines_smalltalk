Class {
	#name : #Pengine,
	#superclass : #Object,
	#instVars : [
		'options',
		'id',
		'src'
	],
	#classVars : [
		'defaultOptions'
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
Pengine class >> fillDefaultOptions: someOptions [
	"fillDefaultOptions"
	"scope: class-variables  &  class-instance-variables"
	"API: https://pengines.swi-prolog.org/docs/documentation.html"		
	
		defaultOptions := IdentityDictionary new.
		defaultOptions 	add: #format      -> 'json';
											add: #server      -> '/pengine';
											add: #id          -> nil;
											add: #src_text    -> nil;
											add: #application -> nil;
											add: #ask         -> nil;
											add: #template    -> nil;
											add: #solutions   -> nil;
											add: #chunk       -> nil;
											add: #destroy     -> nil.
	 ^self new
			initializePengine: someOptions;
			yourself
]

{ #category : #'instance initalization' }
Pengine >> initializePengine: someOptions [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	| validOptions tempOptions |
	tempOptions := someOptions.
	validOptions := Dictionary new.
	[ defaultOptions keysDo: [ :k | ( tempOptions includesKey: k )
			ifTrue: [ validOptions add: k -> ( tempOptions at: k ) ]
			ifFalse: [ validOptions add: k -> ( defaultOptions at: k ) ] ] ]
	on: MessageNotUnderstood
		do:[ self error: 'Pengine ''options'' argument must be addressable by key-value pairs.' ].
	options := validOptions.
	( options at: #id )
		ifNotNil: [ id:= options at: #id.
									"self pull_response." ]
		ifNil: [ ZnClient new 
								http;
								host: 'localhost';
								port: 3030;
								addPath: 'pengine';
								addPath: 'create';
								enforceHttpSuccess: true;
								accept: ZnMimeType applicationJson;
								contentWriter: [ :object | 
        ZnEntity 
            with: (String streamContents: [ :stream |
                        STON jsonWriter on: stream; nextPut: object ])
            type: ZnMimeType applicationJson ];
			contentReader: [ :entity | Transcript cr; show: entity contents ];
    "contentReader: [ :entity |
        STON fromString: entity contents ];"
contents: ( options reject: [ :v | v isNil ] );
post ].
]
