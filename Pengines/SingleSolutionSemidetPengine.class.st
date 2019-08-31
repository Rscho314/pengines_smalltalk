Class {
	#name : #SingleSolutionSemidetPengine,
	#superclass : #SingleSolutionNondetPengine,
	#category : #Pengines
}

{ #category : #API }
SingleSolutionSemidetPengine >> next [

"A semidet predicate should succeed or fail only once, so we error out"

	^self error: '''next'' was called in a SemidetPengine'
]

{ #category : #API }
SingleSolutionSemidetPengine >> next: aNext [

"A semidet predicate should succeed or fail only once, so we error out"

	^self error: '''next:'' was called in a SemidetPengine'
]
