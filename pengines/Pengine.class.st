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
	validOptions := IdentityDictionary new.
	[ defaultOptions keysDo: [ :k | ( tempOptions includesKey: k )
			ifTrue: [ validOptions add: k -> ( tempOptions at: k ) ]
			ifFalse: [ validOptions add: k -> ( defaultOptions at: k ) ] ] ]
	on: MessageNotUnderstood
		do:[ self error: 'Pengine ''options'' argument must be addressable by key-value pairs.' ].
	options := validOptions.
	( options at: #id )
		ifNotNil: [ id:= options at: #id.
									"self pull_response." ]
		ifNil: [	 Transcript show: (ZnClient new
										beOneShot;
										url: ( 'http://localhost:3030', (options at: #server), '/create' );
										entity: (ZnEntity 
									        			with: ( STON toString: ( ( options reject: [:v | v isNil] ) asDictionary ) )
        												type: ZnMimeType applicationJson);
										method: #POST;
										curl)].
]
