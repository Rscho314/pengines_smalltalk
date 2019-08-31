Class {
	#name : #SSNondetTests,
	#superclass : #TestCase,
	#instVars : [
		'pengine'
	],
	#category : #'Pengines-Tests'
}

{ #category : #running }
SSNondetTests >> setUp [
	"Hooks that subclasses may override to define the fixture of test."
	super setUp.
	pengine := SSNondetExample new.
]
