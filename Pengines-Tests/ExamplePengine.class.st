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
