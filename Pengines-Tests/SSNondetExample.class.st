"
I am an example concrete subclass of the Pengine abstract class.

My only and essential collaborator is a running and reachable Pengines server instance for performing tests.
"
Class {
	#name : #SSNondetExample,
	#superclass : #SingleSolutionNondetPengine,
	#category : #'Pengines-Tests'
}

{ #category : #callbacks }
SSNondetExample >> onCreate: response [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	Transcript cr; show: 'CREATE: ', (response asString); flush.
]

{ #category : #callbacks }
SSNondetExample >> onData: someData [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	Transcript cr; show: 'ON DATA: ', (someData asString); flush.
]

{ #category : #callbacks }
SSNondetExample >> onDestroy: someData [
	"Called when the pengine has been successfully destroyed.
	'id' should point to the id of the pengine having been destroyed."
			
	Transcript cr; show: 'DESTROY: ', (someData asString); flush.
]

{ #category : #callbacks }
SSNondetExample >> onFailure: someData [
	"Called when the pengine fails to find a solution.
	'id' should point to the id of the pengine reporting the failure."
			
	Transcript cr; show: 'FAILURE: ', (someData asString) ; flush.
]

{ #category : #callbacks }
SSNondetExample >> onSuccess: someData [
	"Called when the pengine responds with a successful answer to a query.
	'data' should point to a list of objects each representing a solution to the query.
	'more' should evaluate to a boolean indicating whether more solutions may exist.
	'id' points to the id of the pengine returning the answer."
			
	^true
]
