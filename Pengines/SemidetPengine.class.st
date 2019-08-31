Class {
	#name : #SemidetPengine,
	#superclass : #NondetPengine,
	#category : #Pengines
}

{ #category : #API }
SemidetPengine >> next [

"A semidet predicate should succeed or fail only once, so we error out"

	^self error: '''next'' was called in a SemidetPengine'
]

{ #category : #API }
SemidetPengine >> next: aNext [

"A semidet predicate should succeed or fail only once, so we error out"

	^self error: '''next:'' was called in a SemidetPengine'
]
