Class {
	#name : #ExamplePengineTest,
	#superclass : #TestCase,
	#instVars : [
		'pengine'
	],
	#category : #'Pengines-Tests'
}

{ #category : #running }
ExamplePengineTest >> setUp [
	"Hooks that subclasses may override to define the fixture of test."
	super setUp.
	pengine := ExamplePengine new.
]

{ #category : #tests }
ExamplePengineTest >> testInitializationWithOptions [
	"comment stating purpose of instance-side message"

	"scope: class-variables  &  instance-variables"

	ExamplePengine initializeWithOptions: {} asDictionary
]
