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
