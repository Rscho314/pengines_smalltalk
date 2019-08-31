Class {
	#name : #SingleSolutionFailurePengine,
	#superclass : #SingleSolutionNondetPengine,
	#category : #Pengines
}

{ #category : #callbacks }
SingleSolutionFailurePengine >> onSuccess: someData [
	"Failure predicates must always fail, so we error out"
			
	^self error: 'Successful response obtained from a FailurePengine'
]
