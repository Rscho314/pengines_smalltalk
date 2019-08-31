Class {
	#name : #FailurePengine,
	#superclass : #NondetPengine,
	#category : #Pengines
}

{ #category : #callbacks }
FailurePengine >> onSuccess: someData [
	"Failure predicates must always fail, so we error out"
			
	^self error: 'Successful response obtained from a FailurePengine'
]
