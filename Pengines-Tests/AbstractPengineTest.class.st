Class {
	#name : #AbstractPengineTest,
	#superclass : #TestCase,
	#category : #'Pengines-Tests'
}

{ #category : #running }
AbstractPengineTest >> setUp [ 
	"comment stating purpose of instance-side message"
	"scope: class-variables  &  instance-variables"	
	
	super setUp.
]

{ #category : #tests }
AbstractPengineTest >> testInstantiation [
			
	self should: [ Pengine new ] raise: Error.
]

{ #category : #tests }
AbstractPengineTest >> testInstantiationWithOptions [
			
	self should: [ Pengine initializeWithOptions: { } asDictionary ]
				raise: Error.
	self should: [ Pengine initializeWithOptions: nil ]
				raise: Error.
]
