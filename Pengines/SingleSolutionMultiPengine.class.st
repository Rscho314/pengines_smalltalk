Class {
	#name : #SingleSolutionMultiPengine,
	#superclass : #SingleSolutionNondetPengine,
	#instVars : [
		'successFlag'
	],
	#category : #Pengines
}

{ #category : #initialization }
SingleSolutionMultiPengine >> initialize [
	super initialize.
	
	successFlag := false
]

{ #category : #callbacks }
SingleSolutionMultiPengine >> onFailure: someData [
	"Multi predicates must succeed at least once"
	
	successFlag
		ifFalse: [ 	^self error: 'Got failure as first response to a MultiPengine' ]
]

{ #category : #callbacks }
SingleSolutionMultiPengine >> onSuccess: someData [
	"First success is flagged, to allow failure for subsequent responses"
	
	successFlag ifFalse: [ successFlag := true	].
	^true
]
