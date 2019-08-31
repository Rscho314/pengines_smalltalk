Class {
	#name : #SingleSolutionDetPengine,
	#superclass : #SingleSolutionNondetPengine,
	#category : #Pengines
}

{ #category : #API }
SingleSolutionDetPengine >> next [
"Since the answer is det, there cannot be a next, so we error out"

	^self error: '''next'' was called with a DetPengine'
]

{ #category : #API }
SingleSolutionDetPengine >> next: aNext [
"Since the answer is det, there cannot be a next, so we error out"

	^self error: '''next:'' was called with a DetPengine'
]

{ #category : #callbacks }
SingleSolutionDetPengine >> onFailure: someData [
	"Det predicates must succeed, so we error out on failure"
			
	^self error: 'Got a failure response using a DetPengine'
]
