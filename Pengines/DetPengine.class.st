Class {
	#name : #DetPengine,
	#superclass : #NondetPengine,
	#category : #Pengines
}

{ #category : #API }
DetPengine >> next [
"Since the answer is det, there cannot be a next, so we error out"

	^self error: '''next'' was called with a DetPengine'
]

{ #category : #API }
DetPengine >> next: aNext [
"Since the answer is det, there cannot be a next, so we error out"

	^self error: '''next:'' was called with a DetPengine'
]

{ #category : #callbacks }
DetPengine >> onFailure: someData [
	"Det predicates must succeed, so we error out on failure"
			
	^self error: 'Got a failure response using a DetPengine'
]
