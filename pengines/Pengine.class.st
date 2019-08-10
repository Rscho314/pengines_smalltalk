Class {
	#name : #Pengine,
	#superclass : #Object,
	#instVars : [
		'options',
		'id'
	],
	#classVars : [
		'defaultOptions'
	],
	#category : #pengines
}

{ #category : #'instance creation' }
Pengine class >> fillDefaultOptions: someOptions id: someId [
	"fillDefaultOptions"
	"scope: class-variables  &  class-instance-variables"		
	
		defaultOptions := IdentityDictionary new.
		defaultOptions 	add: #format -> 'json';
											add: #server -> '/pengine'.
	 ^self new
			initializePengine: someOptions id: someId;
			yourself
]

{ #category : #'instance initalization' }
Pengine >> initializePengine: someOptions id: someId [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	| validOptions tempOptions|
	tempOptions := someOptions.
	validOptions := IdentityDictionary new.
	[ tempOptions keysAndValuesDo: [ :k :v | defaultOptions at: k ifAbsent:
			[ self error: '''',k asString, ''' is an invalid option.' ].
			v 	ifNotNil: [ validOptions add: k -> v ]
					ifNil: [ validOptions add: k -> ( defaultOptions at: k ) ] ] ]
		on: MessageNotUnderstood
				do:[ self error: 'Pengine ''options'' argument must understand ''keysAndValuesDo''.' ].
	options := validOptions.
	id      := someId.
]
