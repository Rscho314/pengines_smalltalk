"
I am an example concrete subclass of the Pengine abstract class.

My only and essential collaborator is a running and reachable Pengines server instance for performing tests.
"
Class {
	#name : #ExamplePengine,
	#superclass : #Pengine,
	#category : #'Pengines-Tests'
}

{ #category : #callbacks }
ExamplePengine >> onCreate: response [
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
			
	Transcript cr; show: response; flush.
]
