Class {
	#name : #MultiPengine,
	#superclass : #NondetPengine,
	#instVars : [
		'successFlag'
	],
	#category : #Pengines
}

{ #category : #initialization }
MultiPengine >> initialize [
	super initialize.
	
	successFlag := false
]

{ #category : #callbacks }
MultiPengine >> onFailure: someData [
	"Multi predicates must succeed at least once"
	
	successFlag
		ifFalse: [ 	^self error: 'Got failure as first response to a MultiPengine' ]
]

{ #category : #callbacks }
MultiPengine >> onSuccess: someData [
	"First success is flagged, to allow failure for subsequent responses"
	
	successFlag ifFalse: [ successFlag := true	].
	^true
]
